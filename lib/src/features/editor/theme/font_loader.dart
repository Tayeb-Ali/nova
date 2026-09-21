import "dart:io";
import "dart:typed_data";

import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";
import "package:path_provider/path_provider.dart";

import "editor_fonts.dart";

class EditorFontLoader {
  EditorFontLoader._();

  /// Ids downloaded successfully during this run (in-memory only).
  static final Set<String> _loadedIds = <String>{};

  static const int _minBytes = 100 * 1024;


  static bool isLoaded(String familyId) {
    final font = _byId(familyId);
    if (font == null) return false;
    if (font.url != null) return _loadedIds.contains(familyId);
    if (font.bundled || font.googleName == null) return true;
    return _loadedIds.contains(familyId);
  }
   static Future<bool> ensureLoaded(String familyId) async {
    final font = _byId(familyId);
    if (font == null) return false;
    if (font.url != null) return _ensureUrlLoaded(font);
    final googleName = font.googleName;
    if (font.bundled || googleName == null) return true;
    if (_loadedIds.contains(familyId)) return true;
    try {
      GoogleFonts.getFont(googleName);
      await GoogleFonts.pendingFonts();
      _loadedIds.add(familyId);
      return true;
    } catch (_) {
      return false;
    }
  }


  static Future<void> warmupFromDisk() async {
    for (final font in editorFonts) {
      if (font.url == null || _loadedIds.contains(font.id)) continue;
      try {
        final file = await _cacheFile(font.id);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        if (bytes.length < _minBytes) {
          await _deleteQuietly(file);
          continue;
        }
        final family = font.family;
        if (family == null) continue;
        await _registerFamily(family, bytes);
        _loadedIds.add(font.id);
      } catch (_) {
        // One bad cache file must not break the rest.
      }
    }
  }

  static Future<bool> _ensureUrlLoaded(EditorFont font) async {
    final family = font.family;
    final url = font.url;
    if (family == null || url == null) return false;
    if (_loadedIds.contains(font.id)) return true;
    try {
      final file = await _cacheFile(font.id);
      if (await file.exists()) {
        try {
          final cached = await file.readAsBytes();
          if (cached.length < _minBytes) {
            await _deleteQuietly(file);
          } else {
            await _registerFamily(family, cached);
            _loadedIds.add(font.id);
            return true;
          }
        } catch (_) {
          await _deleteQuietly(file);
        }
      }
      final bytes = await _download(url);
      if (bytes == null || bytes.length < _minBytes) return false;
      try {
        await file.writeAsBytes(bytes, flush: true);
      } catch (_) {
        return false;
      }
      try {
        await _registerFamily(family, bytes);
      } catch (_) {
        await _deleteQuietly(file);
        return false;
      }
      _loadedIds.add(font.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List?> _download(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      final response =
          await request.close().timeout(const Duration(seconds: 60));
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return null;
      }
      final builder = BytesBuilder();
      await for (final chunk
          in response.timeout(const Duration(seconds: 60))) {
        builder.add(chunk);
      }
      return builder.toBytes();
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> _registerFamily(String family, Uint8List bytes) async {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  static Future<File> _cacheFile(String id) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory("${docs.path}/fonts");
    if (!await dir.exists()) await dir.create(recursive: true);
    return File("${dir.path}/$id.ttf");
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort: a stale partial must not throw.
    }
  }

  static EditorFont? _byId(String id) {
    for (final font in editorFonts) {
      if (font.id == id) return font;
    }
    return null;
  }
}
