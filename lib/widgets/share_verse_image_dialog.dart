import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database.dart';
import '../utils/note_colors.dart';

Future<void> showShareVerseImageDialog(
    BuildContext context, Verse verse) async {
  final repaintKey = GlobalKey();
  final highlight = parseNoteColor(verse.noteColor);

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      contentPadding: const EdgeInsets.all(16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: repaintKey,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: highlight ?? Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFF4E342E), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${verse.book} ${verse.chapter}:${verse.verse}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF4E342E),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    verse.textContent,
                    style: GoogleFonts.lora(
                        fontSize: 15, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'MyOwnBible',
                      style: GoogleFonts.lora(
                          fontSize: 11,
                          color: const Color(0xFF4E342E),
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Partager'),
                onPressed: () async {
                  // Important : capturer l'image AVANT de fermer le dialog,
                  // sinon le RepaintBoundary est démonté et currentContext
                  // devient null.
                  try {
                    final boundary = repaintKey.currentContext
                        ?.findRenderObject() as RenderRepaintBoundary?;
                    if (boundary == null) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      return;
                    }
                    final image = await boundary.toImage(pixelRatio: 3.0);
                    final byteData = await image
                        .toByteData(format: ui.ImageByteFormat.png);
                    if (byteData == null) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      return;
                    }
                    final bytes = byteData.buffer.asUint8List();
                    if (ctx.mounted) Navigator.pop(ctx);
                    // XFile.fromData : compatible Web (pas de filesystem)
                    // ET mobile/desktop (share_plus écrit un temp file).
                    final filename =
                        'verset_${verse.book}_${verse.chapter}_${verse.verse}.png';
                    await SharePlus.instance.share(ShareParams(
                      files: [
                        XFile.fromData(
                          bytes,
                          mimeType: 'image/png',
                          name: filename,
                        ),
                      ],
                      text: '${verse.book} ${verse.chapter}:${verse.verse}',
                    ));
                  } catch (e) {
                    debugPrint('Erreur partage image: $e');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
