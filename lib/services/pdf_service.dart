import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndPrintBill(Bill bill, {Map<String, dynamic>? companyProfile}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text((companyProfile?['name'] ?? 'BILLER PRO').toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ),
              if (companyProfile?['address'] != null)
                pw.Center(child: pw.Text(companyProfile!['address'], style: const pw.TextStyle(fontSize: 8))),
              pw.SizedBox(height: 10),
              pw.Text('Date: ${DateFormat('dd-MM-yyyy HH:mm').format(bill.createdAt ?? DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Bill No: ${bill.billNumber ?? "PROVISIONAL"}', style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Item', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Qty', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Amt', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(thickness: 0.5),
              ...bill.items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 9))),
                    pw.Text('${item.quantity.toInt()}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(' ${item.totalAmount.toInt()}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              )),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('₹${bill.grandTotal}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Text('PAYMENTS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ...bill.payments.map((p) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${p.mode}:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('₹${p.amount}', style: const pw.TextStyle(fontSize: 8)),
                ],
              )),
              
              if (companyProfile?['enableQrPayments'] == true && companyProfile?['upiId'] != null && bill.balanceAmount > 0)
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.SizedBox(height: 10),
                      pw.Text('SCAN TO PAY BALANCE DUE: ₹${bill.balanceAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'upi://pay?pa=${companyProfile?['upiId']}&pn=${Uri.encodeComponent(companyProfile?['upiName'] ?? companyProfile?['name'])}&am=${bill.balanceAmount.toStringAsFixed(2)}&cu=INR',
                        width: 60,
                        height: 60,
                      ),
                      pw.Text(companyProfile?['upiId'] ?? '', style: const pw.TextStyle(fontSize: 6)),
                    ],
                  ),
                ),

              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('THANK YOU!', style: const pw.TextStyle(fontSize: 8))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
