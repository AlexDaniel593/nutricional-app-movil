import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudinaryDatasource {
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dcsgpp4ol', // cloud name
    'nutricional', // upload preset
    cache: false,
  );

  // Credenciales de Cloudinary para eliminación
  final String _apiKey = '551169827944418';
  final String _apiSecret = 'c-wkK1hhYSORrSNPyuis4ihr5oM';
  final String _cloudName = 'dcsgpp4ol';

  // Subir imagen a Cloudinary
  Future<String> uploadImage(File imageFile) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'recipes',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: ${e.toString()}');
    }
  }

  // Eliminar imagen de Cloudinary usando el public_id
  Future<void> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Crear la firma para autenticar la solicitud
      final signature = _generateSignature(publicId, timestamp);
      
      // URL de la API de Cloudinary para eliminar
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'
      );

      // Hacer la solicitud POST
      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'signature': signature,
          'api_key': _apiKey,
          'timestamp': timestamp,
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('Error al eliminar imagen: ${errorData['error']?['message'] ?? 'Error desconocido'}');
      }

      final responseData = json.decode(response.body);
      if (responseData['result'] != 'ok' && responseData['result'] != 'not found') {
        throw Exception('La imagen no se pudo eliminar: ${responseData['result']}');
      }
    } catch (e) {
      throw Exception('Error al eliminar imagen: ${e.toString()}');
    }
  }

  // Generar firma SHA-1 para autenticar la solicitud de eliminación
  String _generateSignature(String publicId, String timestamp) {
    final stringToSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Extraer public_id de una URL de Cloudinary
  String? extractPublicIdFromUrl(String url) {
    try {
      // URL típica: https://res.cloudinary.com/dcsgpp4ol/image/upload/v123456789/recipes/abc123.jpg
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Buscar el índice de 'upload'
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) {
        return null;
      }
      
      // Los segmentos después de 'upload' y el número de versión forman el public_id
      // Saltar el segmento de versión (v123456789)
      var startIndex = uploadIndex + 1;
      if (pathSegments[startIndex].startsWith('v')) {
        startIndex++;
      }
      
      // Unir los segmentos restantes
      final publicIdSegments = pathSegments.sublist(startIndex);
      var publicId = publicIdSegments.join('/');
      
      // Remover la extensión del archivo
      final lastDotIndex = publicId.lastIndexOf('.');
      if (lastDotIndex != -1) {
        publicId = publicId.substring(0, lastDotIndex);
      }
      
      return publicId;
    } catch (e) {
      return null;
    }
  }

  // Eliminar imagen usando su URL completa
  Future<void> deleteImageByUrl(String url) async {
    final publicId = extractPublicIdFromUrl(url);
    if (publicId == null) {
      throw Exception('No se pudo extraer el public_id de la URL');
    }
    await deleteImage(publicId);
  }

}
