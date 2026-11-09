import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:universal_html/universal_html.dart' as html;
import 'package:web_app/Utils/colors.dart';
import 'package:web_app/Utils/timedate_conventer.dart';
import 'package:web_app/model/food.dart';
import 'package:animated_expandable_fab/animated_expandable_fab.dart';

//import 'package:pdfx/pdfx.dart';

class InvoiceView extends StatelessWidget {
  const InvoiceView({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenshotController screenshotController = ScreenshotController();

    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final int userTelNumber = args["telephoneNum"];
    final int orderPrice = args["orderPrice"];
    final String userName = args["userName"];
    final String userAddress = args["userAddrass"];
    final bool isDeliver = args["isDeliver"];
    // Older invoice routes may not provide a saved fee, so retain the old rate.
    final int deliveryCharge =
        (args["deliveryCharge"] as num?)?.toInt() ?? (isDeliver ? 200 : 0);
    final Timestamp timeOfOrder = args["timeOfOrder"];
    final List<FoodItem> orderItem = args["orders"];

    final int totalAmount = orderPrice + deliveryCharge;

    Future<bool> _runWithProcessing(Future<bool> Function() action) async {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: const Color(0xFFFFFEFA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Creating invoice...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Please wait while the file is prepared.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Allow the dialog to paint before the file generation starts.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      try {
        return await action();
      } finally {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }

    // Capture the invoice widget and download the resulting PNG in the browser.
    Future<void> _downloadInvoicePng() async {
      final success = await _runWithProcessing(() async {
        try {
          final invoicePng = await screenshotController.capture(pixelRatio: 2);
          if (invoicePng == null) return false;

          final now = DateTime.now();
          final customerName = userName
              .trim()
              .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '-');
          final year = (now.year % 100).toString().padLeft(2, '0');
          final month = now.month.toString().padLeft(2, '0');
          final day = now.day.toString().padLeft(2, '0');
          final hour = now.hour.toString().padLeft(2, '0');
          final minute = now.minute.toString().padLeft(2, '0');
          final second = now.second.toString().padLeft(2, '0');
          // Replace filename-invalid slashes and colons with hyphens.
          final fileName =
              '${customerName}_date($year-$month-$day)_time($hour-$minute-$second).png';
          final blob = html.Blob([invoicePng], 'image/png');
          final objectUrl = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: objectUrl)
            ..download = fileName
            ..click();
          Future<void>.delayed(const Duration(seconds: 1), () {
            html.Url.revokeObjectUrl(objectUrl);
          });
          return true;
        } catch (error) {
          debugPrint('Invoice PNG download failed: $error');
          return false;
        }
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Invoice PNG downloaded.'
                : 'Could not download the invoice PNG.',
          ),
        ),
      );
    }

    // Capture the rendered invoice and place it on a PDF page at its original size.
    Future<void> _downloadInvoicePdf() async {
      final success = await _runWithProcessing(() async {
        try {
          final invoicePng = await screenshotController.capture(pixelRatio: 2);
          if (invoicePng == null) return false;

          final imageCodec = await ui.instantiateImageCodec(invoicePng);
          final imageFrame = await imageCodec.getNextFrame();
          final invoiceImage = imageFrame.image;
          final pageFormat = PdfPageFormat(
            invoiceImage.width / 2,
            invoiceImage.height / 2,
            marginAll: 0,
          );
          imageCodec.dispose();
          invoiceImage.dispose();

          final pdfDocument = pw.Document();
          pdfDocument.addPage(
            pw.Page(
              pageFormat: pageFormat,
              margin: pw.EdgeInsets.zero,
              build: (_) => pw.Image(
                pw.MemoryImage(invoicePng),
                width: pageFormat.width,
                height: pageFormat.height,
                fit: pw.BoxFit.fill,
              ),
            ),
          );
          final pdfBytes = await pdfDocument.save();

          final now = DateTime.now();
          final customerName = userName
              .trim()
              .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '-');
          final year = (now.year % 100).toString().padLeft(2, '0');
          final month = now.month.toString().padLeft(2, '0');
          final day = now.day.toString().padLeft(2, '0');
          final hour = now.hour.toString().padLeft(2, '0');
          final minute = now.minute.toString().padLeft(2, '0');
          final second = now.second.toString().padLeft(2, '0');
          final fileName =
              '${customerName}_date($year-$month-$day)_time($hour-$minute-$second).pdf';
          final blob = html.Blob([pdfBytes], 'application/pdf');
          final objectUrl = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: objectUrl)
            ..download = fileName
            ..click();
          Future<void>.delayed(const Duration(seconds: 1), () {
            html.Url.revokeObjectUrl(objectUrl);
          });
          return true;
        } catch (error) {
          debugPrint('Invoice PDF download failed: $error');
          return false;
        }
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Invoice PDF downloaded.'
                : 'Could not download the invoice PDF.',
          ),
        ),
      );
    }

/* ***************************************************************
 ##################         Invoice       #######################*/
    return Scaffold(
      floatingActionButton: ExpandableFab(
        distance: 100,
        openIcon: Icon(Icons.add),
        closeIcon: Icon(Icons.close),
        children: [
          ActionButton(
            text: const Text("Invoice PNG"),
            onPressed: _downloadInvoicePng,
            icon: const Icon(Icons.image_outlined),
          ),
          ActionButton(
            text: const Text("Invoice PDF"),
            onPressed: _downloadInvoicePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          ActionButton(
            text: Text("Go Home "),
            onPressed: () {
              Navigator.pushNamed(context, '/home');
            },
            icon: Icon(Icons.home),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width < 440
                ? MediaQuery.of(context).size.width
                : 440,
            child: Screenshot(
              controller: screenshotController,
              // Keep the invoice readable when it is printed or downloaded.
              child: Theme(
                data: ThemeData.light(useMaterial3: true),
                child: Container(
                  color: MyColor.invoicePaper,
                  padding: const EdgeInsets.all(16),
                  child: invoiceBody(
                    userName,
                    userAddress,
                    userTelNumber,
                    timeOfOrder,
                    orderItem,
                    orderPrice,
                    deliveryCharge,
                    totalAmount,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget invoiceBody(
      String userName,
      String userAddress,
      int userTelNumber,
      Timestamp timeOfOrder,
      List<FoodItem> orderItem,
      int orderPrice,
      int deliveryCharge,
      int totalAmount) {
    const ink = Color(0xFF24352B);
    const mutedInk = Color(0xFF7A817A);
    const paper = Color(0xFFFFFEFA);
    const line = Color(0xFFE8E5DC);
    final orderDate = timeOfOrder.toDate();
    final formattedDate =
        '${orderDate.year}/${orderDate.month.toString().padLeft(2, '0')}/${orderDate.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: const BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFEFA),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/iconLogo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INVOICE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Thank you for your order',
                        style: TextStyle(color: Color(0xFFD6DCCF), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.receipt_long, color: Color(0xFFF2B544), size: 27),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _invoiceInfoBlock(
                        label: 'BILLED TO',
                        value: userName,
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _invoiceInfoBlock(
                        label: 'ORDER DATE',
                        value: formattedDate,
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _invoiceDetailLine(
                  icon: Icons.phone_outlined,
                  text: '0$userTelNumber',
                ),
                if (userAddress.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _invoiceDetailLine(
                    icon: Icons.location_on_outlined,
                    text: userAddress,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ORDER SUMMARY',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E8CB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${orderItem.length} items',
                        style: const TextStyle(
                          color: ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Text('ITEM', style: _invoiceTableHeading),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('QTY', textAlign: TextAlign.center, style: _invoiceTableHeading),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('PRICE', textAlign: TextAlign.right, style: _invoiceTableHeading),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                ...orderItem.asMap().entries.map((entry) {
                  final item = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                    decoration: BoxDecoration(
                      color: entry.key.isEven
                          ? const Color(0xFFFFFEFA)
                          : const Color(0xFFFAF9F4),
                      border: const Border(
                        bottom: BorderSide(color: line, width: 0.7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Text(
                            item.itemName,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            '1',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: mutedInk, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${item.itemPrice} 円',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),
                _invoiceAmountLine('Subtotal', '$orderPrice 円'),
                const SizedBox(height: 9),
                _invoiceAmountLine('Delivery', '$deliveryCharge 円'),
                const SizedBox(height: 14),
                Container(height: 1, color: line),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'TOTAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Text(
                        '$totalAmount 円',
                        style: const TextStyle(
                          color: Color(0xFFF2B544),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/LogoFooter.png', height: 45),
                      const SizedBox(height: 8),
                      const Text(
                        'ありがとうございました',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'We hope to serve you again soon.',
                        style: TextStyle(color: mutedInk, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _invoiceTableHeading = TextStyle(
  color: Color(0xFF647066),
  fontSize: 10,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.8,
);

Widget _invoiceInfoBlock({
  required String label,
  required String value,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F7F1),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFEAE7DD)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF75836F)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF758078),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF24352B),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

Widget _invoiceDetailLine({required IconData icon, required String text}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: const Color(0xFF75836F)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF626A63), fontSize: 11),
        ),
      ),
    ],
  );
}

Widget _invoiceAmountLine(String label, String amount) {
  return Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF687168), fontSize: 12),
        ),
      ),
      Text(
        amount,
        style: const TextStyle(
          color: Color(0xFF24352B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class Footer extends StatefulWidget {
  const Footer();

  @override
  _Footer createState() => _Footer();
}

class _Footer extends State {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
        ),
      ],
    );
  }
}


// class PdfViewScreen extends StatelessWidget {
//   const PdfViewScreen({
//     super.key,
//   });
//   @override
//   Widget build(BuildContext context) {
//     final Map<String, dynamic>? args =
//         ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
//     final Uint8List getPdfData = args!["pdfData"];

//     return Scaffold(
//         body: getPdfData.isNotEmpty
//             ? Container(
//                 child: PdfPreview(
//                     maxPageWidth: 600,
//                     allowPrinting: true,
//                     allowSharing: false,
//                     canChangeOrientation: false,
//                     canChangePageFormat: false,
//                     canDebug: false,
//                     build: ((format) => getPdfData)))
//             : Container(
//                 child: Text("Data is not"),
//               ));
//   }
// }

// class PdfViewScreen extends StatelessWidget {
//   const PdfViewScreen({super.key, required this.pdfData});
//   final Uint8List pdfData;
//   @override
//   Widget build(BuildContext context) {
//     final pdfController =
//         PdfController(document: PdfDocument.openData(pdfData));
//     return Container(
//       child: PdfView(controller: pdfController),
//     );
//   }
// }
