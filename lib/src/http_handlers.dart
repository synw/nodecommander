import 'dart:io';
import 'dart:convert';
import 'package:isohttpd/isohttpd.dart';
import 'command/model.dart';

Future<HttpResponse> cmdSendHandler(HttpRequest request, IsoLogger log) async {
  final content = await request.transform(const Utf8Decoder()).join();
  final dynamic c = json.decode(content);
  final NodeCommand command = NodeCommand.fromJson(c);
  log.data(command);
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}

Future<HttpResponse> cmdResponseHandler(
    HttpRequest request, IsoLogger log) async {
  final content = await request.transform(const Utf8Decoder()).join();
  final dynamic c = json.decode(content);
  final NodeCommand command = NodeCommand.fromJson(c);
  log.data(command);
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}
