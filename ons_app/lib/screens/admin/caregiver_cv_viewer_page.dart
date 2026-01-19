import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class CaregiverCvViewerPage extends StatefulWidget {
  final String caregiverId;
  final String caregiverName;

  const CaregiverCvViewerPage({
    super.key,
    required this.caregiverId,
    required this.caregiverName,
  });

  @override
  State<CaregiverCvViewerPage> createState() => _CaregiverCvViewerPageState();
}

class _CaregiverCvViewerPageState extends State<CaregiverCvViewerPage> {
  final AdminApi _api = AdminApi();

  bool _loading = true;
  String? _error;

  PdfControllerPinch? _pdfCtrl;

  @override
  void dispose() {
    _pdfCtrl?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    final Uint8List bytes = await _api.getCaregiverCvBytes(widget.caregiverId);

    _pdfCtrl?.dispose();
    _pdfCtrl = PdfControllerPinch(
      document: PdfDocument.openData(bytes),
    );

    if (!mounted) return;
    setState(() => _loading = false);
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _error = e.toString();
      _loading = false;
    });
  }
}


  @override
Widget build(BuildContext context) {
  return AdminLayout(
    title: 'CV - ${widget.caregiverName}',
    child: _loading
        ? const Center(child: CircularProgressIndicator())
        : (_error != null)
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to approvals'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PdfViewPinch(
                      controller: _pdfCtrl!,
                      onDocumentError: (err) {},
                    ),
                  ),
                ],
              ),
  );
}



  
}
