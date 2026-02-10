import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../domain/entities/user.dart';

class AuthApiDatasource {
  static const String _baseUrl = 'https://isteremplea.ldcruminahui.com/api/valida';
  static const Duration _timeout = Duration(seconds: 10);

  /// Valida las credenciales del usuario mediante API externa
  /// Retorna un [User] si las credenciales son válidas
  /// Lanza una excepción si las credenciales son inválidas o hay un error
  Future<User> loginWithApi(String email, String password) async {
    try {
      // Construir URL con email y password
      final url = Uri.parse('$_baseUrl/$email/$password');
      final response = await http.get(url).timeout(
        _timeout,
        onTimeout: () {
          throw Exception('Tiempo de espera agotado al conectar con el servidor');
        },
      );

      // Verificar estado
      if (response.statusCode == 200) {
        // decodificar la respuesta
        final data = json.decode(response.body);
        
        // Verificar la estructura de respuesta
        if (data is Map && data.containsKey('status')) {
          final status = data['status'];
          final message = data['data']?.toString() ?? '';
          
          // Status 100 indica usuario válido
          if (status == 100) {
            return User(
              id: email, // Usar email como ID
              username: email.split('@')[0], // Extraer nombre del email
              email: email,
            );
          } 
          // Status 400 indica credenciales incorrectas
          else if (status == 400) {
            throw Exception('Credenciales incorrectas');
          } 
          // Cualquier otro status
          else {
            throw Exception(message.isNotEmpty ? message : 'Error desconocido');
          }
        } else {
          throw Exception('Respuesta del servidor con formato inválido');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Credenciales inválidas');
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on HandshakeException catch (e) {
      // Error específico de certificado SSL
      throw Exception('Error de certificado SSL. Intentando método alternativo...');
    } on SocketException catch (e) {
      // Error de conexión
      throw Exception('No se pudo conectar al servidor. Verifica tu conexión a Internet.');
    } on TimeoutException catch (e) {
      // Error de timeout
      throw Exception('Tiempo de espera agotado. Intenta nuevamente.');
    } catch (e) {
      if (e.toString().contains('Credenciales inválidas') || 
          e.toString().contains('Usuario no encontrado') ||
          e.toString().contains('Credenciales incorrectas')) {
        rethrow;
      }
      throw Exception('Error al conectar con el servidor: ${e.toString()}');
    }
  }
}
