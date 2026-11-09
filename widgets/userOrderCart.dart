// ignore_for_file: use_build_context_synchronously
import 'package:auto_size_text/auto_size_text.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:web_app/Utils/colors.dart';
import 'package:web_app/Utils/timedate_conventer.dart';
import 'package:web_app/Utils/view_wrapper.dart';
import 'package:web_app/firebase/firebase_userOrder.dart';
//import 'package:web_app/invoice_pdf/pdf_view_screen.dart';
import 'package:web_app/model/food.dart';
import 'package:web_app/model/user_order.dart';
import 'package:web_app/provider_function/logic_function.dart';
import 'package:web_app/screen/foodItems_view.dart';
import 'package:web_app/screen/popup_view.dart';
import 'package:web_app/widgets/reusable_widget.dart';
import 'package:web_app/widgets/rounded_border.dart';

class UserOrderCarts extends StatefulWidget {
  const UserOrderCarts({
    super.key,
    required this.tittleName,
    required this.streamer,
    required this.collectionPath,
    required this.isRequiredCount,
  });
  final bool isRequiredCount;
  final String tittleName;
  final String collectionPath;
  final Stream<List<UserOrder>> streamer;
  @override
  State<UserOrderCarts> createState() => _UserOrderCartsState();
}

class _UserOrderCartsState extends State<UserOrderCarts> {
  final userPhoneNunberEditingController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    userPhoneNunberEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserOrder>>(
        stream: widget.streamer,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator.adaptive(
              strokeWidth: 4,
              semanticsLabel: "Lording",
            );
          }

          if (snapshot.hasError) {
            debugPrint("orders snapshot err :: ${snapshot.hasError}");
            return Center(
                child: Text(
              "is error founded:: ${snapshot.hasError}",
              style: TextStyle(color: MyColor.myRed),
            ));
          } else if (snapshot.hasData) {
            final userOrdersData = snapshot.data!;

            widget.isRequiredCount
                ? context
                    .read<UserOrdersFind>()
                    .getUserOrder(ordersLength: userOrdersData.length)
                : null;

            return ViewWrapper(
                desktopView: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: roundedBorder(
                      height: 500,
                      widget: orderViewSelection(
                          isSlideView: false, userOrdersData: userOrdersData),
                      title: widget.tittleName),
                ),
                mobileView: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: roundedBorder(
                      height: 500,
                      widget: orderViewSelection(
                          isSlideView: true, userOrdersData: userOrdersData),
                      title: widget.tittleName),
                ));
          } else {
            return isItemOrder();
          }
        });
  }

// ***************************************************************//
// ####################   Order View Selection    ##########################//
  Widget orderViewSelection(
      {required bool isSlideView, required List<UserOrder> userOrdersData}) {
    return isSlideView
        ? CarouselSlider.builder(
            itemCount: userOrdersData.length,
            options: CarouselOptions(
              enableInfiniteScroll: false,
              height: 400,
              enlargeCenterPage: true,
              enlargeStrategy: CenterPageEnlargeStrategy.zoom,
              autoPlay: false,
              scrollDirection: Axis.vertical,
              // autoPlayInterval: Duration(seconds: timeDuration!),
              aspectRatio: 4 / 3,
              viewportFraction: 0.3,
            ),
            itemBuilder: (context, index, realIndex) {
              final orderDetails = userOrdersData[index];

              return orderCart(
                // Pass the full order so its details dialog can open the editor
                // with all customer fields and purchased items.
                userOrder: orderDetails,
                isDeliver: orderDetails.isDelivery ?? false,
                userID: orderDetails.userid,
                userName: orderDetails.userName,
                userTelephoneNumber: orderDetails.userPhoneNumber,
                userPostalCode: orderDetails.userPostalCode,
                userAddress: orderDetails.userAddruss,
                orderPrice: orderDetails.userTotalPrice,
                deliveryCharge: orderDetails.deliveryCharge,
                timeOfOrder: orderDetails.timestamp!,
                orders: orderDetails.userOrders,
                indexNumber: index,
              );
            })
        : ListView.builder(
            shrinkWrap: true,
            physics: const ScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: userOrdersData.length,
            itemBuilder: (BuildContext context, int index) {
              final orderDetails = userOrdersData[index];

              return orderCart(
                userOrder: orderDetails,
                isDeliver: orderDetails.isDelivery ?? false,
                userID: orderDetails.userid,
                userName: orderDetails.userName,
                userTelephoneNumber: orderDetails.userPhoneNumber,
                userPostalCode: orderDetails.userPostalCode,
                userAddress: orderDetails.userAddruss,
                orderPrice: orderDetails.userTotalPrice,
                deliveryCharge: orderDetails.deliveryCharge,
                timeOfOrder: orderDetails.timestamp!,
                orders: orderDetails.userOrders,
                indexNumber: index,
              );
            });
  }

// ***************************************************************//
// ####################   Order Cart    ##########################//

  Widget isItemOrder() {
    return SizedBox(
      height: 500,
      child: Card(
        color: MyColor.myTransparent,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Lottie.asset("assets/wating.json",
                  height: 200, width: 200, fit: BoxFit.cover)),
          Text(
            "Data is Not allow",
            style: TextStyle(color: MyColor.myRed),
          ),
        ]),
      ),
    );
  }

// ***************************************************************//
// ####################   Order Cart    ##########################//
  Widget orderCart({
    required UserOrder userOrder,
    required String userID,
    required String userName,
    required int userTelephoneNumber,
    required int userPostalCode,
    required String userAddress,
    required int orderPrice,
    required int deliveryCharge,
    required Timestamp timeOfOrder,
    required List<FoodItem> orders,
    required int indexNumber,
    required bool isDeliver,
  }) {
// ***************************************************************//
// ###################   Tap ON CART    ##########################//
    return InkWell(
      onTap: () async {
        final isOrderFinished = await orderDetails(
          userPostalCode: userPostalCode,
          indexNumber: indexNumber,
          userTelephoneNumber: userTelephoneNumber,
          orderPrice: orderPrice,
          userID: userID,
          userName: userName,
          userAddress: userAddress,
          timeOfOrder: timeOfOrder,
          orders: orders,
          userOrder: userOrder,
          context: context,
          itemViewr: gridItemViewr(
            crossAxisItemsCount: 3,
            scrollDirectionAxis: Axis.vertical,
            itemLength: orders,
            isUserOrder: true,
          ),
          nameWidget: titleSubtitle(
              title: "Name",
              subTitle: userName,
              icon: const Icon(Icons.account_circle)),
          telPhoneWidget: titleSubtitle(
              title: "Phone Number",
              subTitle: "$userTelephoneNumber",
              icon: const Icon(Icons.phone)),
          addressWidget: titleSubtitle(
              title: "Address",
              subTitle: "$userPostalCode \n $userAddress",
              icon: const Icon(Icons.location_on)),
          textEditingController: userPhoneNunberEditingController,
        );
        if (isOrderFinished == true) {
          // print("order is finished :: $isOrderFinished");
          String? failureReason;

          final removeDatabase = await _runWithProcessing<bool?>(
            context: context,
            message: widget.collectionPath == "userOrders"
                ? "Completing order and updating item stock..."
                : "Deleting history record...",
            task: () => widget.collectionPath == "userOrders"
                ? completeOrderAndUpdateStock(
                    orderID: userID,
                    orderCollectionPath: widget.collectionPath,
                    onFailure: (reason) => failureReason = reason,
                  )
                : deleteOrder(
                    orderID: userID,
                    collectionPath: widget.collectionPath,
                  ),
          );

          if (removeDatabase == true) {
            isSuccessPopup(
                context: context,
                title: "Order Completed",
                msg: "The order was archived and item stock was updated.",
                function: () {},
                isSuccess: true);

            debugPrint("Order is finished :: $isOrderFinished");
          } else {
            isSuccessPopup(
                context: context,
                title: "ERROR",
                msg: failureReason ??
                    "The order could not be completed. Check the debug log for details.",
                function: () {},
                isSuccess: false);
          }
        }
      },
      // ***************************************************************//
      // ##################   Design of Order Cart  ####################//
      child: Slidable(
        key: ValueKey(indexNumber),
        startActionPane: ActionPane(motion: const ScrollMotion(), children: [
          SlidableAction(
            onPressed: ((context) async {
              // final getPdf = await PdfApi.genarateInvoice(
              //   indexNumber: indexNumber,
              //   userTelephoneNumber: userTelephoneNumber,
              //   orderPrice: orderPrice,
              //   userName: userName,
              //   userID: userID,
              //   userAddrass: userAddress,
              //   timeOfOrder: timeOfOrder,
              //   orders: orders,
              // );

              // final b = await PdfApi.saveDocument(
              //     pdfBytes: getPdf, userName: userName);
              // if (b) {
              //   Navigator.pushNamed(context, '/pdf', arguments: {
              //     "userName": userName,
              //     "userAddrass": userAddress,
              //     "telephoneNum": userTelephoneNumber,
              //     "orderPrice": orderPrice,
              //     "timeOfOrder": timeOfOrder,
              //     "orders": orders,
              //     "isDeliver": isDeliver,
              //   });
              // }
              Navigator.pushNamed(context, '/pdf', arguments: {
                "userName": userName,
                "userAddrass": userAddress,
                "telephoneNum": userTelephoneNumber,
                "orderPrice": orderPrice,
                "deliveryCharge": deliveryCharge,
                "timeOfOrder": timeOfOrder,
                "orders": orders,
                "isDeliver": isDeliver,
              });
            }),
            backgroundColor: MyColor.secondary,
            foregroundColor: MyColor.onSecondary,
            icon: Icons.receipt_long,
            label: 'Invoice',
          ),

          ///*************************************************************************************** */
        ]),
        endActionPane: ActionPane(
            motion: ScrollMotion(),
            dismissible: DismissiblePane(onDismissed: () {}),
            children: [
              SlidableAction(
                onPressed: (_) async {
                  await onTapDrag(
                    this.context,
                    userTelephoneNumber: userTelephoneNumber,
                    userPhoneNunberEditingController:
                        userPhoneNunberEditingController,
                    userID: userID,
                    collectionPath: widget.collectionPath,
                    indexNumber: indexNumber,
                  );
                },
                backgroundColor: MyColor.myRed,
                foregroundColor: MyColor.onPrimary,
                icon: Icons.delete,
                label: 'Delete',
              )
            ]),
        child: SizedBox(
          height: 300,
          child: Card(
            color: MyColor.myTransparent,
            child: Row(
              //  mainAxisAlignment: MainAxisAlignment.spaceAround,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AutoSizeText(
                          maxLines: 2,
                          maxFontSize: 15,
                          minFontSize: 8,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          "Name : $userName",
                          style:
                              TextStyle(color: MyColor.myGreen, fontSize: 15),
                        ),
                        AutoSizeText(
                          maxLines: 1,
                          maxFontSize: 15,
                          minFontSize: 8,
                          "TP    : $userTelephoneNumber",
                          style:
                              TextStyle(color: MyColor.myGreen, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    AutoSizeText(
                      textAlign: TextAlign.left,
                      maxFontSize: 15,
                      minFontSize: 8,
                      "Date - ${TimeDateConventor().date(timeStamp: timeOfOrder)}\nTime - ${TimeDateConventor().time(timeStamp: timeOfOrder)}\n$orderPrice 円",
                      style: TextStyle(
                          color: isDeliver ? MyColor.myRed : MyColor.myGreen,
                          fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// // ***************************************************************//
// // ###################   Get Invoice    ##########################//
// Future<void> getInvoice(
//   BuildContext context, {
//   required int indexNumber,
//   required int userTelephoneNumber,
//   required int orderPrice,
//   required String userName,
//   required String userID,
//   required String userAddrass,
//   required Timestamp timeOfOrder,
//   required List<FoodItem> orders,
// }) async {
//   print('#######  1  #######');

//   final getPdf = await PdfApi.genarateInvoice(
//     indexNumber: indexNumber,
//     userTelephoneNumber: userTelephoneNumber,
//     orderPrice: orderPrice,
//     userName: userName,
//     userID: userID,
//     userAddrass: userAddrass,
//     timeOfOrder: timeOfOrder,
//     orders: orders,
//   );
//   print('#######  2  #######');

// //  Navigator.of(context).pop();

//   print('#######  3  #######');

//   // PdfApi.saveDocument(pdfBytes: getPdf, userName: userName);

//   // Navigator.pushNamed(context, '/pdf');
//   // print('#######  4  #######');
// }

// ***************************************************************//
// ###################   Delete Order    ##########################//
Future<void> onTapDrag(
  BuildContext context, {
  required int userTelephoneNumber,
  required TextEditingController userPhoneNunberEditingController,
  required String userID,
  required String collectionPath,
  required int indexNumber,
}) async {
  var isDirectDelete = false;
  final isOrderFinished = await orderFinished(
      context: context,
      userPhoneNumber: userTelephoneNumber,
      textEditingController: userPhoneNunberEditingController,
      onDirectDeleteCode: () => isDirectDelete = true);

  if (isOrderFinished == true) {
    String? failureReason;
    final removalResult = await _runWithProcessing<bool?>(
      context: context,
      message: isDirectDelete
          ? collectionPath == "userOrders"
              ? "Deleting order and updating item stock..."
              : "Deleting order..."
          : collectionPath == "userOrders"
              ? "Completing order and updating item stock..."
              : "Deleting history record...",
      task: () => isDirectDelete
          ? collectionPath == "userOrders"
              ? completeOrderAndUpdateStock(
                  orderID: userID,
                  orderCollectionPath: collectionPath,
                  archiveOrderToHistory: false,
                  onFailure: (reason) => failureReason = reason,
                )
              : deleteOrderPermanently(
                  orderID: userID,
                  collectionPath: collectionPath,
                )
          : collectionPath == "userOrders"
              ? completeOrderAndUpdateStock(
                  orderID: userID,
                  orderCollectionPath: collectionPath,
                  onFailure: (reason) => failureReason = reason,
                )
              : deleteOrder(
                  orderID: userID,
                  collectionPath: collectionPath,
                ),
    );
    final removeDatabase = removalResult == true;

    if (!context.mounted) return;
    await isSuccessPopup(
      context: context,
      title: removeDatabase
          ? (isDirectDelete ? "Debug Delete Success" : "Order Completed")
          : "ERROR",
      msg: removeDatabase
          ? (isDirectDelete
              ? collectionPath == "userOrders"
                  ? "The order was deleted without history and item stock was updated."
                  : "The order was permanently deleted without archiving."
              : collectionPath == "userOrders"
                  ? "The order was archived and item stock was updated."
                  : "The history record was deleted.")
          : failureReason ??
              "The operation failed. Check the debug log for details.",
      function: () {},
      isSuccess: removeDatabase,
    );
  }
}

Future<T> _runWithProcessing<T>({
  required BuildContext context,
  required String message,
  required Future<T> Function() task,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final startedAt = DateTime.now();
  final processingDialog = showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 18),
            Flexible(child: Text(message)),
          ],
        ),
      ),
    ),
  );

  try {
    await WidgetsBinding.instance.endOfFrame;
    final result = await task();
    const minimumDisplayTime = Duration(milliseconds: 350);
    final remainingTime =
        minimumDisplayTime - DateTime.now().difference(startedAt);
    if (remainingTime > Duration.zero) {
      await Future<void>.delayed(remainingTime);
    }
    return result;
  } finally {
    if (navigator.mounted && navigator.canPop()) {
      navigator.pop();
    }
    await processingDialog;
  }
}

// ***************************************************************//
// ###################   Total Price    ##########################//
// Widget totalPrice(
//     {required OrderFoodItems value, required VoidCallback onPressed}) {
//   return SizedBox(
//     height: 100,
//     child: Card(
//       color: Colors.transparent,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           Text(
//             "Total Price ",
//             style: TextStyle(color: MyColor.myOrange, fontSize: 30),
//           ),
//           Text(
//             "${value.getTotalPrice} 円",
//             style: TextStyle(color: MyColor.myGreen, fontSize: 30),
//           ),
//           reUsableButton(
//               onPressed: onPressed,
//               buttonName: "Order",
//               borderSideColor: MyColor.myRed),
//         ],
//       ),
//     ),
//   );
// }
