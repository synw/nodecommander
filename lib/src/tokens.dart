import 'dart:convert';
import 'dart:math';

import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:meta/meta.dart';

class Tokens {
  Tokens({@required this.key}) : _signer = JWTHmacSha256Signer(key);

  final String key;

  final JWTHmacSha256Signer _signer;

  static final Random _random = Random.secure();

  static String generateKey([int length = 32]) {
    final values = List<int>.generate(length, (i) => _random.nextInt(256));
    return base64Url.encode(values);
  }

  String encode({String iss = "nodecommander"}) {
    final builder = JWTBuilder();
    final token = builder
      ..issuer = iss
      //..expiresAt = DateTime.now().add(const Duration(minutes: 3))
      //..setClaim('data', {'userId': 836})
      ..getToken();
    final signedToken = token.getSignedToken(_signer);
    return signedToken.toString();
  }

  bool verify(String token) {
    final decodedToken = JWT.parse(token);
    return decodedToken.verify(_signer);
  }
}
