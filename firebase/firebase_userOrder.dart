import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:web_app/model/food.dart';
import 'package:web_app/model/user_order.dart';

//*****************************************************************************
//   Create Food Item Order
//*****************************************************************************

Future<bool?> createOrder({required UserOrder userOrder}) async {
  final collection = FirebaseFirestore.instance.collection("userOrders");

  final getDoctItem = collection.doc();
  userOrder.userid = getDoctItem.id;
  final setJson = userOrder.toJson();

//  print("${setJson}");
  return getDoctItem.set(setJson).then((value) {
    //   print("Order send success !");
    return true;
  }).catchError((error) {
    //   print("Oder Error");
    return false;
  });
}

//*****************************************************************************
//   Read User Food Order
//*****************************************************************************
Stream<List<UserOrder>> readUserOrders() {
  final firestoreUserOrders = FirebaseFirestore.instance
      .collection("userOrders")
      .orderBy('timeStamp')
      .snapshots();

  return firestoreUserOrders.map((snapshot) =>
      snapshot.docs.map((doc) => UserOrder.fromMap(doc.data())).toList());
}

//*****************************************************************************
//   Update Customer And Delivery Details In An Existing Order
//   Saves customer fields and the per-order delivery fee without closing editor.
//*****************************************************************************
Future<bool> updateOrderCustomerDetails({
  required String orderID,
  required String userName,
  required int userPhoneNumber,
  required int userPostalCode,
  required String userAddress,
  required int deliveryCharge,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection("userOrders")
        .doc(orderID)
        .update({
      "userName": userName,
      "userPhoneNumber": userPhoneNumber,
      "userPostalCode": userPostalCode,
      "userAddruss": userAddress,
      "deliveryCharge": deliveryCharge,
    });
    return true;
  } catch (_) {
    return false;
  }
}

//*****************************************************************************
//   Update Items In An Existing Order
//   Replaces the item list and stores a total calculated from the saved units.
//*****************************************************************************
Future<bool> updateOrderItems({
  required String orderID,
  required List<FoodItem> orders,
}) async {
  try {
    final totalPrice = orders.fold<int>(
      0,
      (total, item) => total + item.itemPrice,
    );

    await FirebaseFirestore.instance
        .collection("userOrders")
        .doc(orderID)
        .update({
      "userOrders": orders.map((item) {
        final itemData = item.toJson();
        itemData["timeStamp"] = item.timestamp;
        return itemData;
      }).toList(),
      "userTotalPrice": totalPrice,
    });
    return true;
  } catch (_) {
    return false;
  }
}

//*****************************************************************************
//   Read Of Delete User Order
//*****************************************************************************
Stream<List<UserOrder>> readDeleteHistoryOrders() {
  final firestoreUserOrders = FirebaseFirestore.instance
      .collection("removeOrders")
      .orderBy('timeStamp', descending: true)
      .snapshots();

  return firestoreUserOrders.map((snapshot) =>
      snapshot.docs.map((doc) => UserOrder.fromMap(doc.data())).toList());
}

Future<bool> completeOrderAndUpdateStock({
  required String orderID,
  required String orderCollectionPath,
  bool archiveOrderToHistory = true,
  void Function(String reason)? onFailure,
}) async {
  final firestore = FirebaseFirestore.instance;
  final orderRef = firestore.collection(orderCollectionPath).doc(orderID);
  final archiveRef = firestore.collection("removeOrders").doc();
  String? failureReason;

  try {
    final orderSnapshot = await orderRef.get();
    final orderData = orderSnapshot.data();
    if (!orderSnapshot.exists || orderData == null) {
      failureReason = "The order no longer exists in $orderCollectionPath.";
      return false;
    }

    final order = UserOrder.fromMap(orderData);
    late final Map<String, _StockDeduction> deductions;
    try {
      deductions = _groupStockDeductions(order.userOrders);
    } catch (error) {
      failureReason =
          "The order has an invalid item name or collection path: $error";
      return false;
    }
    final inventoryRefs = <String, DocumentReference<Map<String, dynamic>>>{};

    for (final entry in deductions.entries) {
      final deduction = entry.value;
      if (deduction.itemId.isNotEmpty) {
        inventoryRefs[entry.key] = firestore
            .collection(deduction.collectionPath)
            .doc(deduction.itemId);
      } else {
        // Older orders may not have a saved inventory document ID.
        final matchingItems = await firestore
            .collection(deduction.collectionPath)
            .where("itemName", isEqualTo: deduction.itemName)
            .limit(2)
            .get();
        if (matchingItems.docs.length != 1) {
          failureReason = matchingItems.docs.isEmpty
              ? "No item named '${deduction.itemName}' was found in '${deduction.collectionPath}'."
              : "More than one item named '${deduction.itemName}' exists in '${deduction.collectionPath}'. Add the inventory item ID to this order to resolve it.";
          return false;
        }
        inventoryRefs[entry.key] = matchingItems.docs.single.reference;
      }
    }

    final completed = await firestore.runTransaction<bool>((transaction) async {
      final currentOrderSnapshot = await transaction.get(orderRef);
      final currentOrderData = currentOrderSnapshot.data();
      if (!currentOrderSnapshot.exists || currentOrderData == null) {
        failureReason = "The order was removed before stock could be updated.";
        return false;
      }

      final currentOrder = UserOrder.fromMap(currentOrderData);
      late final Map<String, _StockDeduction> currentDeductions;
      try {
        currentDeductions = _groupStockDeductions(currentOrder.userOrders);
      } catch (error) {
        failureReason = "The order item data is invalid: $error";
        return false;
      }
      if (!_sameStockDeductions(deductions, currentDeductions)) {
        failureReason =
            "The order items changed while the operation was running.";
        return false;
      }

      final inventorySnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in inventoryRefs.entries) {
        inventorySnapshots[entry.key] = await transaction.get(entry.value);
      }

      for (final entry in deductions.entries) {
        final inventoryData = inventorySnapshots[entry.key]?.data();
        if (inventoryData == null) {
          failureReason =
              "Inventory item '${entry.value.itemName}' (ID: ${entry.value.itemId.isEmpty ? 'not saved' : entry.value.itemId}) was not found in '${entry.value.collectionPath}'.";
          return false;
        }
        final currentCount = inventoryData["itemCount"];
        if (currentCount is! num || currentCount < entry.value.quantity) {
          failureReason = currentCount is! num
              ? "The stock count for '${entry.value.itemName}' is missing or invalid."
              : "Not enough stock for '${entry.value.itemName}': "
                  "${currentCount.toInt()} available, ${entry.value.quantity} required.";
          return false;
        }
      }

      for (final entry in deductions.entries) {
        final currentCount =
            inventorySnapshots[entry.key]!.data()!["itemCount"] as num;
        transaction.update(inventoryRefs[entry.key]!, {
          "itemCount": currentCount.toInt() - entry.value.quantity,
        });
      }

      if (archiveOrderToHistory) {
        final archivedOrder = Map<String, dynamic>.from(currentOrderData)
          ..["userid"] = archiveRef.id;
        transaction.set(archiveRef, archivedOrder);
      }
      transaction.delete(orderRef);
      return true;
    });
    if (!completed) {
      failureReason ??=
          "The order could not be completed because its data changed.";
    }
    return completed;
  } catch (error, stackTrace) {
    failureReason = "Firestore operation failed: $error";
    debugPrint("Order stock update failed: $error\n$stackTrace");
    return false;
  } finally {
    if (failureReason != null) {
      debugPrint("Order stock update details: $failureReason");
      onFailure?.call(failureReason!);
    }
  }
}

Map<String, _StockDeduction> _groupStockDeductions(List<FoodItem> items) {
  final deductions = <String, _StockDeduction>{};
  for (var index = 0; index < items.length; index++) {
    final item = items[index];
    final collectionPath = item.collectionPath?.trim() ?? "";
    final itemName = item.itemName.trim();
    if (collectionPath.isEmpty || itemName.isEmpty) {
      throw StateError(
        "Item ${index + 1} is missing its collection path or item name.",
      );
    }

    final itemId = item.id.trim();
    final identity = itemId.isNotEmpty ? "id:$itemId" : "name:$itemName";
    final key = "$collectionPath\u0000$identity";
    final existing = deductions[key];
    if (existing == null) {
      deductions[key] = _StockDeduction(
        collectionPath: collectionPath,
        itemId: itemId,
        itemName: itemName,
        quantity: 1,
      );
    } else {
      existing.quantity++;
    }
  }
  return deductions;
}

bool _sameStockDeductions(
  Map<String, _StockDeduction> first,
  Map<String, _StockDeduction> second,
) {
  if (first.length != second.length) return false;
  for (final entry in first.entries) {
    if (second[entry.key]?.quantity != entry.value.quantity) return false;
  }
  return true;
}

class _StockDeduction {
  _StockDeduction({
    required this.collectionPath,
    required this.itemId,
    required this.itemName,
    required this.quantity,
  });

  final String collectionPath;
  final String itemId;
  final String itemName;
  int quantity;
}

//*****************************************************************************
//   Delete Food Item Order
//*****************************************************************************
Future<bool?> deleteOrder(
    {required String collectionPath, required String orderID}) async {
  final orderDelete =
      FirebaseFirestore.instance.collection(collectionPath).doc(orderID);

/////////               History User Order Delete                //////////
  if (collectionPath == "removeOrders") {
    // print("history delete   ${collectionPath}");
    return orderDelete
        .delete()
        .then((value) => true)
        .catchError((err) => false);
  }

  // /////////       History User Cooking Order Delete          /////////////
  // if (collectionPath == "removeCookingOrders") {
  //   // print("history delete   ${collectionPath}");
  //   return orderDelete
  //       .delete()
  //       .then((value) => true)
  //       .catchError((err) => false);
  // }

  final DocumentSnapshot snapshot = await orderDelete.get();
  final getOrder = snapshot.data() as Map<String, dynamic>;
  UserOrder getUserOrder = UserOrder.fromMap(getOrder);

// //////////////    Cooking Order Classifier Database         //////////////
//   if (collectionPath == "CookingItems") {
//     print(collectionPath + " path ++");
//     final removeCookingItemsCollection =
//         FirebaseFirestore.instance.collection("removeCookingOrders").doc();
//     getUserOrder.userid = removeCookingItemsCollection.id;

//     final json = getUserOrder.toJson();
//     return removeCookingItemsCollection.set(json).then((value) {
//       return orderDelete
//           .delete()
//           .then((value) => true)
//           .catchError((err) => false);

//       //   print("Order send success !");
//     }).catchError((error) {
//       //   print("Oder Error");
//       return false;
//     });
//   }

/////////    remove Order Collection and Creating Delete History    //////////
  final removeCollection =
      FirebaseFirestore.instance.collection("removeOrders").doc();
  getUserOrder.userid = removeCollection.id;

  final json = getUserOrder.toJson();
  print({"order path :: $orderDelete.path"});
  return removeCollection.set(json).then((value) {
    return orderDelete
        .delete()
        .then((value) => true)
        .catchError((err) => false);
  }).catchError((error) {
    return false;
  });
}

Future<bool> deleteOrderPermanently({
  required String collectionPath,
  required String orderID,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(orderID)
        .delete();
    return true;
  } catch (_) {
    return false;
  }
}
