import 'dart:convert';
import 'dart:io';

import 'package:isohttpd/isohttpd.dart';

import 'command/model.dart';

Future<HttpResponse> cmdSendHandler(HttpRequest request, IsoLogger log) async {
  final content = await utf8.decoder.bind(request).join();
  final dynamic c = json.decode(content);
  final NodeCommand cmd = NodeCommand.fromJson(c);
  log.push(cmd);
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}

Future<HttpResponse> cmdResponseHandler(
    HttpRequest request, IsoLogger log) async {
  final content = await utf8.decoder.bind(request).join();
  final dynamic c = json.decode(content);
  final NodeCommand cmd = NodeCommand.fromJson(c);
  log.push(cmd);
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}
