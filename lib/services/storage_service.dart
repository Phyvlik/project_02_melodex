import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Cache a Spotify album art URL to Firebase Storage
  // Returns the Firebase Storage download URL for later retrieval
  Future<String?> cacheAlbumArt(String spotifyId, String imageUrl) async {
    try {
      final ref = _storage.ref('album_art/$spotifyId.jpg');

      // Check if it already exists to avoid redundant uploads
      try {
        return await ref.getDownloadURL();
      } catch (_) {
        // Not cached yet, proceed with download and upload
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;

      await ref.putData(
        response.bodyBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await ref.getDownloadURL();
    } catch (e) {
      // Gracefully degrade to the original Spotify URL if Storage fails
      return null;
    }
  }

  Future<String?> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      final ref = _storage.ref('profile_photos/$userId.jpg');
      final task = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteProfilePhoto(String userId) async {
    try {
      await _storage.ref('profile_photos/$userId.jpg').delete();
    } catch (_) {}
  }

  // Download an image to the device cache directory for offline access
  Future<File?> downloadToCache(String url, String filename) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      if (await file.exists()) return file;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (_) {
      return null;
    }
  }
}
