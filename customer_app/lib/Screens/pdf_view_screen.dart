import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class ViewOrderInvoiceScreen extends StatefulWidget {
  const ViewOrderInvoiceScreen({super.key});

  @override
  State<ViewOrderInvoiceScreen> createState() => _ViewOrderInvoiceScreenState();
}

class _ViewOrderInvoiceScreenState extends State<ViewOrderInvoiceScreen> {
  late PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(document: PdfDocument.openAsset('Assets/123446789.pdf'));
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: PdfView(
        controller: _pdfController,
        scrollDirection: Axis.horizontal,
      ),
    );
  }
}
