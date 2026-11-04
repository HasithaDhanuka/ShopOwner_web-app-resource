import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web_app/Utils/colors.dart';
import 'package:web_app/model/food.dart';
import 'package:web_app/model/user_order.dart';
import 'package:web_app/screen/order_edit_view.dart';
import 'package:web_app/screen/food_update_view.dart';
import 'package:web_app/widgets/custom_button.dart';
import 'package:web_app/widgets/network_image_render.dart';
import 'package:web_app/widgets/reusable_widget.dart';
import 'package:web_app/widgets/text_field_module.dart';
import 'package:web_app/provider_function/logic_function.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/userOrderCart.dart';
//import 'package:web_app/invoice_pdf/pdf_view_screen.dart';

// ***************************************************************//
// ####################   PopUp Item    ##########################//
Future<bool?> popUpItem(BuildContext context,
        {required String itemUrl, required bool canOrder}) =>
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: MyColor.myBlack,
        shadowColor: MyColor.myGreen,
        content: Container(
          height: 300,
          width: 300,
          decoration: BoxDecoration(
            border: Border.all(color: MyColor.myGreen),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: netImageView(
              imgURL: itemUrl,
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              canOrder
                  ? buttonOfPopUp(context,
                      isOrder: true,
                      borderSideColor: MyColor.myGreen,
                      buttonName: "Order")
                  : Container(),
              buttonOfPopUp(context,
                  isOrder: false,
                  borderSideColor: MyColor.myRed,
                  buttonName: "Cancel"),
            ],
          )
        ],
      ),
    );

Widget buttonOfPopUp(BuildContext context,
    {required bool isOrder,
    required Color borderSideColor,
    required String buttonName}) {
  return reUsableButton(
    onPressed: () {
      Navigator.of(context).pop(isOrder);
    },
    buttonName: buttonName,
    borderSideColor: borderSideColor,
  );
}

// *********************************************************************//
// ####################   Update Item View    ##########################//
Future<bool?> updateItem(
  BuildContext context, {
  required FoodItem foodItem,
}) =>
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: MyColor.myBlack,
        shadowColor: MyColor.myGreen,
        content: Container(
          height: 300,
          width: 300,
          decoration: BoxDecoration(
            border: Border.all(color: MyColor.myGreen),
            borderRadius: BorderRadius.circular(20),
          ),
          child: FoodUpdateView(foodItem: foodItem),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              cancelButton(context,
                  borderSideColor: MyColor.myOrange,
                  buttonName: "Back item view")
            ],
          )
        ],
      ),
    );

Widget cancelButton(BuildContext context,
    {required Color borderSideColor, required String buttonName}) {
  return reUsableButton(
    onPressed: () {
      Navigator.of(context).pop();
    },
    buttonName: buttonName,
    borderSideColor: borderSideColor,
  );
}

// ****************************************************************//
// ####################   PopUp Order    ##########################//
Future<bool?> popupOrder({
  required BuildContext context,
  required TextEditingController userNameEditingController,
  required TextEditingController userPhoneNunberEditingController,
  required TextEditingController userPostalCodeEditingController,
  required TextEditingController userAddrassEditingController,
}) =>
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              insetPadding: const EdgeInsets.all(10),
              backgroundColor: MyColor.myBlack,
              content: SizedBox(
                width: 400,
                child: Consumer<TextFieldChanger>(
                    builder: (context, value, chaild) {
                  return Column(
                    children: <Widget>[
                      customInputField(
                          inputFieldName: "Your Name",
                          inputEditingController: userNameEditingController,
                          isNumberTypeKeybord: false,
                          isValidate: value.getUserNameValidate,
                          keyBordType: TextInputType.name),
                      customInputField(
                          inputFieldName: "Telephone Number",
                          inputEditingController:
                              userPhoneNunberEditingController,
                          isNumberTypeKeybord: true,
                          isValidate: value.getUserTelNumberValidate,
                          keyBordType: TextInputType.number),
                      customInputField(
                          inputFieldName: "Postal Code",
                          inputEditingController:
                              userPostalCodeEditingController,
                          isNumberTypeKeybord: true,
                          isValidate: value.getUserPostalCodeValidate,
                          keyBordType: TextInputType.number),
                      customInputField(
                          inputFieldName: "your Address",
                          inputEditingController: userAddrassEditingController,
                          isNumberTypeKeybord: false,
                          isValidate: value.getUserAddressValidate,
                          keyBordType: TextInputType.multiline,
                          maxLine: 5),
                      reUsableButton(
                          onPressed: () {
                            value.orderSendScreen(
                                bUserNameValidate:
                                    userNameEditingController.text.isEmpty,
                                bUserTelNumberValidate:
                                    userPhoneNunberEditingController
                                        .text.isEmpty,
                                bUserPostalCodeValidate:
                                    userPostalCodeEditingController
                                        .text.isEmpty,
                                bUserAddressValidate:
                                    userAddrassEditingController.text.isEmpty);

                            if (userNameEditingController.text.isEmpty ||
                                userPhoneNunberEditingController.text.isEmpty ||
                                userPostalCodeEditingController.text.isEmpty ||
                                userAddrassEditingController.text.isEmpty) {
                              return;
                            }

                            Navigator.of(context).pop(true);
                          },
                          buttonName: "Send",
                          borderSideColor: MyColor.myGreen)
                    ],
                  );
                }),
              ),
            ));

// *********************************************************************//
// ####################   Owner Order View    ##########################//

Future orderDetails({
  required BuildContext context,
  required Widget itemViewr,
  required Widget nameWidget,
  required Widget telPhoneWidget,
  required Widget addressWidget,
  required TextEditingController textEditingController,
  required String userID,
  required String userName,
  required int userTelephoneNumber,
  required int userPostalCode,
  required String userAddress,
  required int orderPrice,
  required Timestamp timeOfOrder,
  required List<FoodItem> orders,
  required UserOrder userOrder,
  required int indexNumber,
}) =>
    showDialog(
      context: context,
      builder: (dialogContext) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          backgroundColor: MyColor.myBlack,
          content: Column(
            children: [
              SizedBox(
                width: 400,
                height: 300,
                child: itemViewr,
              ),
              nameWidget,
              InkWell(
                  onTap: () async {
                    final snackBar = SnackBar(
                      content: Text(
                        'Phone Number Copy Success !',
                        style: TextStyle(color: MyColor.myGreen),
                      ),
                    );
                    Clipboard.setData(
                            ClipboardData(text: "0${userTelephoneNumber}"))
                        .then((value) => ScaffoldMessenger.of(context)
                            .showSnackBar(snackBar));
                  },
                  child: telPhoneWidget),
              InkWell(
                  onTap: () {
                    MapsLauncher.launchQuery(userAddress);
                  },
                  onLongPress: () {
                    final snackBar = SnackBar(
                      content: Text(
                        'Address Copy Success !',
                        style: TextStyle(color: MyColor.myGreen),
                      ),
                    );

                    Clipboard.setData(ClipboardData(text: "${userAddress}"))
                        .then((value) => ScaffoldMessenger.of(context)
                            .showSnackBar(snackBar));
                  },
                  child: addressWidget),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    reUsableButton(
                      onPressed: () async {
                        final isOrderFinished = await orderFinished(
                          context: context,
                          userPhoneNumber: userTelephoneNumber,
                          textEditingController: textEditingController,
                        );

                        if (isOrderFinished == true) {
                          Navigator.of(dialogContext).pop(isOrderFinished);
                        }
                      },
                      buttonName: "Order Finished",
                      borderSideColor: MyColor.myGreen,
                    ),
                    reUsableButton(
                      onPressed: () async {
                        // Close the details dialog, then open the editor with
                        // the complete order for customer and item changes.
                        Navigator.of(dialogContext).pop();
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => OrderEditScreen(order: userOrder),
                          ),
                        );
                      },
                      buttonName: "Edit Order",
                      borderSideColor: MyColor.myOrange,
                    ),
                    reUsableButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      buttonName: "Back To Menu",
                      borderSideColor: MyColor.myYellow,
                    ),
                  ],
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.only(top: 20),
              //   child: reUsableButton(
              //       onPressed: () {
              //         Navigator.pushNamed(context, '/pdf');
              //       },
              //       buttonName: "Invoice",
              //       borderSideColor: MyColor.myRed),
              // ),
            ],
          ),
        ),
      ),
    );

// *********************************************************************//
// ####################   Order Finished View    ##########################//

Future<bool?> orderFinished(
        {required BuildContext context,
        required int userPhoneNumber,
        required TextEditingController textEditingController}) =>
    showDialog(
        context: context,
        builder: (_) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: AlertDialog(
                insetPadding: const EdgeInsets.only(
                  bottom: 200,
                  top: 200,
                ),
                backgroundColor: MyColor.myBlack,
                content: SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                      titleSubtitle(
                          title: "User Phone Number",
                          subTitle: "$userPhoneNumber",
                          icon: const Icon(Icons.phone)),
                      customInputField(
                          inputFieldName: "Enter The Order Finished Code",
                          inputEditingController: textEditingController,
                          isNumberTypeKeybord: true,
                          isValidate: true,
                          keyBordType: TextInputType.number),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Builder(builder: (context) {
                              return reUsableButton(
                                  onPressed: () {
                                    // ####################### Is Text Field Empty    #####################//
                                    if (textEditingController.text.isEmpty) {
                                      isSuccessPopup(
                                        context: context,
                                        title: "ERROR",
                                        msg: "Please enter your mobile phone",
                                        isSuccess: false,
                                        function: () {},
                                      );
                                    }
                                    // ####################### Is Text Field Match    #####################//
                                    if (userPhoneNumber ==
                                            int.parse(
                                                textEditingController.text) ||
                                        888 ==
                                            int.parse(
                                                textEditingController.text)) {
                                      textEditingController.clear();
                                      Navigator.of(context).pop(true);
                                    }
                                    // ####################### Is Text Field Not Match    #####################//
                                    else {
                                      isSuccessPopup(
                                          context: context,
                                          title: "ERROR",
                                          msg:
                                              " Phone numbers do not match. Please enter again !",
                                          isSuccess: false,
                                          function: () {});
                                    }
                                  },
                                  buttonName: "Order Finished",
                                  borderSideColor: MyColor.myGreen);
                            }),
                            const SizedBox(
                              width: 50,
                            ),
                            Builder(builder: (context) {
                              return reUsableButton(
                                  onPressed: () {
                                    textEditingController.clear();
                                    Navigator.of(context).pop();
                                  },
                                  buttonName: "Back To Menu",
                                  borderSideColor: MyColor.myRed);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ));

// *********************************************************************//
// ####################   Error Popup    ###############################//
Future isSuccessPopup({
  required BuildContext? context,
  required String title,
  required String msg,
  required VoidCallback? function,
  required bool isSuccess,
}) {
  if (isSuccess) {
    return AwesomeDialog(
      context: context!,
      animType: AnimType.leftSlide,
      headerAnimationLoop: false,
      dialogType: DialogType.success,
      showCloseIcon: false,
      title: title,
      desc: msg,
      btnOkOnPress: function,
      btnOkIcon: Icons.check_circle,
    ).show();
  } else {
    return AwesomeDialog(
      context: context!,
      dialogType: DialogType.error,
      animType: AnimType.rightSlide,
      headerAnimationLoop: false,
      title: title,
      desc: msg,
      btnOkOnPress: function,
      btnOkIcon: Icons.cancel,
      btnOkColor: MyColor.myRed,
    ).show();
  }
}

// // *********************************************************************//
// // ####################   Error Popup    ###############################//
// Future errorPopup({
//   required BuildContext context,
//   required String title,
//   required String msg,
//   required VoidCallback function,
// }) {
//   return AwesomeDialog(
//     context: context,
//     dialogType: DialogType.error,
//     animType: AnimType.rightSlide,
//     headerAnimationLoop: false,
//     title: title,
//     desc: msg,
//     btnOkOnPress: function,
//     btnOkIcon: Icons.cancel,
//     btnOkColor: Colors.red,
//   ).show();
// }

// // *********************************************************************//
// // ####################   Success Popup    #############################//
// Future successPopup({
//   required BuildContext context,
//   required String title,
//   required String msg,
//   required VoidCallback function,
// }) =>
//     AwesomeDialog(
//       context: context,
//       animType: AnimType.leftSlide,
//       headerAnimationLoop: false,
//       dialogType: DialogType.error,
//       showCloseIcon: false,
//       title: title,
//       desc: msg,
//       btnOkOnPress: function,
//       btnOkIcon: Icons.check_circle,
//       onDismissCallback: (type) {
//         debugPrint('Dialog Dissmiss from callback $type');
//       },
//     ).show();
