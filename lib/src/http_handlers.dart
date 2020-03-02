import 'dart:convert';
import 'dart:io';

import 'package:isohttpd/isohttpd.dart';

import 'command/model.dart';

Future<HttpResponse> cmdSendHandler(
    HttpRequest request, IsoLogger logger) async {
  //final content = await request.transform<dynamic>(Utf8Decoder()).join();
  final content = await utf8.decoder.bind(request).join();
  final dynamic c = json.decode(content);
  final NodeCommand command = NodeCommand.fromJson(c);
  logger.data(IsoServerLog(
      message: "Command ${command.name} received", payload: command));
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}

Future<HttpResponse> cmdResponseHandler(
    HttpRequest request, IsoLogger logger) async {
  final content = await utf8.decoder.bind(request).join();
  final dynamic c = json.decode(content);
  final NodeCommand command = NodeCommand.fromJson(c);
  logger.data(
      IsoServerLog(message: "Responded to command $command", payload: command));
  command.info();
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}
