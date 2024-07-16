import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

Future<void> generateAndPreviewPdf(
  Map<String, List<Map<String, String>>> data,
  dynamic frontCoverImage, // Accept dynamic type to handle both File and Uint8List
  dynamic backCoverImage,  // Accept dynamic type to handle both File and Uint8List
  dynamic designImage,     // Accept dynamic type to handle both File and Uint8List
  String companyName,
  dynamic companyLogo,     // Accept dynamic type to handle both File and Uint8List
  String frontTitle,
  String frontDetails,
  String backDetails,
  String? selectedFont,
  Color selectedColor,     // New parameter for selected color
) async {
  final pdf = pw.Document();
  final fontData = selectedFont != null ? await rootBundle.load(selectedFont) : await rootBundle.load("assets/fonts/default.ttf");
  final ttf = pw.Font.ttf(fontData);
  final pdfColor = PdfColor.fromInt(selectedColor.value); // Convert Flutter color to PDF color

  Uint8List? getBytes(dynamic image) {
    if (image is File) {
      return image.readAsBytesSync();
    } else if (image is Uint8List) {
      return image;
    }
    return null;
  }

  pw.Widget fullPageImage(pw.ImageProvider image) {
    return pw.Container(
      width: PdfPageFormat.a4.width,
      height: PdfPageFormat.a4.height,
      child: pw.Image(image, fit: pw.BoxFit.cover),
    );
  }

  if (frontCoverImage != null || companyName.isNotEmpty || frontTitle.isNotEmpty || frontDetails.isNotEmpty) {
    final frontImage = frontCoverImage != null ? pw.MemoryImage(getBytes(frontCoverImage)!) : null;
    final logoImage = companyLogo != null ? pw.MemoryImage(getBytes(companyLogo)!) : null;
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              if (frontImage != null) fullPageImage(frontImage),
              pw.Center(
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Image(logoImage, height: 100, width: 100),
                    if (companyName.isNotEmpty)
                      pw.Text(companyName, style: pw.TextStyle(font: ttf, fontSize: 36, color: pdfColor)),
                    if (frontTitle.isNotEmpty)
                      pw.Text(frontTitle, style: pw.TextStyle(font: ttf, fontSize: 24, color: pdfColor)),
                    if (frontDetails.isNotEmpty)
                      pw.Text(frontDetails, style: pw.TextStyle(font: ttf, fontSize: 18, color: pdfColor)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void addContentPages() {
    List<pw.Widget> contentWidgets = [];
    double totalHeight = 0;
    final maxHeight = PdfPageFormat.a4.height - 80;

    void addContentWidget(pw.Widget widget, double height) {
      if (totalHeight + height > maxHeight) {
        pdf.addPage(
          pw.Page(
            margin: pw.EdgeInsets.zero,
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  if (designImage != null) fullPageImage(pw.MemoryImage(getBytes(designImage)!)),
                  pw.Padding(
                    padding: pw.EdgeInsets.all(16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: List<pw.Widget>.from(contentWidgets),
                    ),
                  ),
                ],
              );
            },
          ),
        );
        contentWidgets.clear();
        totalHeight = 0;
      }
      contentWidgets.add(widget);
      totalHeight += height;
    }

    addContentWidget(pw.Text('MENU GENERATOR', style: pw.TextStyle(font: ttf, fontSize: 36, color: pdfColor)), 40);
    for (var entry in data.entries) {
      addContentWidget(pw.SizedBox(height: 20), 20);
      addContentWidget(pw.Text(entry.key, style: pw.TextStyle(font: ttf, fontSize: 28, color: pdfColor)), 30);
      addContentWidget(pw.SizedBox(height: 10), 10);

      for (var item in entry.value) {
        addContentWidget(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(item['name'] ?? '', style: pw.TextStyle(font: ttf, fontSize: 18, color: pdfColor)),
                  pw.Text(item['price'] ?? '', style: pw.TextStyle(font: ttf, fontSize: 18, color: pdfColor)),
                ],
              ),
              pw.Text(item['description'] ?? '', style: pw.TextStyle(font: ttf, fontSize: 14, color: pdfColor)),
              pw.SizedBox(height: 10),
            ],
          ),
          40,
        );
      }

      addContentWidget(pw.SizedBox(height: 20), 20);
    }

    if (contentWidgets.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          margin: pw.EdgeInsets.zero,
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                if (designImage != null) fullPageImage(pw.MemoryImage(getBytes(designImage)!)),
                pw.Padding(
                  padding: pw.EdgeInsets.all(16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: contentWidgets,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  addContentPages();

  if (backCoverImage != null || backDetails.isNotEmpty) {
    final backImage = backCoverImage != null ? pw.MemoryImage(getBytes(backCoverImage)!) : null;
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              if (backImage != null) fullPageImage(backImage),
              pw.Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: pw.Center(
                  child: pw.Text(
                    backDetails,
                    style: pw.TextStyle(font: ttf, fontSize: 18, color: pdfColor),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}
