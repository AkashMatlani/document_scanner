import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:io';

import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_api_availability/google_api_availability.dart';

import '../../providers/app_providers.dart';

class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ML kit Document Scanner is currently Android-only. Use OCR from Image or Live Camera OCR on iOS.',
          ),
        ),
      );
      return;
    }

    // Check for Google Play Services availability
    final availability = await GoogleApiAvailability.instance
        .checkGooglePlayServicesAvailability();
    if (availability != GooglePlayServicesAvailability.success) {
      if (context.mounted) {
        await GoogleApiAvailability.instance.makeGooglePlayServicesAvailable();
      }
      return;
    }

    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: 20,
        isGalleryImport: true,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      final path = result.images?.isNotEmpty == true
          ? result.images!.first
          : null;
      if (path == null || !context.mounted) return;
      final success = await ref
          .read(scanControllerProvider.notifier)
          .recognize(path);
      if (!context.mounted)return;
      if (success) {
        context.push('/ocr');
      } else {
        final error = ref.read(scanControllerProvider).error;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error ?? 'OCR failed',
            ),
          ),
        );
      }
    } on PlatformException catch (e, stack) {
      debugPrint('=== DOCUMENT SCANNER PLATFORM EXCEPTION ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('details: ${e.details}');
      debugPrint('$stack');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scanner error\nCode: ${e.code}\nMessage: ${e.message}',
            ),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('=== DOCUMENT SCANNER EXCEPTION ===');
      debugPrint('$e');
      debugPrint('$stack');

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Scanner error: $e')));
      }
    } finally {
      scanner.close();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Document Scanner')),
    body: Center(
      child: FilledButton.icon(
        onPressed: () => _scan(context, ref),
        icon: const Icon(Icons.document_scanner),
        label: const Text('Start scanner'),
      ),
    ),
  );
}
