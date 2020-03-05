import 'dart:convert';
import 'dart:io';

import 'package:isohttpd/isohttpd.dart';
import 'package:emodebug/emodebug.dart';

import 'command/model.dart';

const _ = EmoDebug();

Future<HttpResponse> cmdSendHandler(HttpRequest request, IsoLogger log) async {
  final content = await utf8.decoder.bind(request).join();
  final dynamic c = json.decode(content);
  final NodeCommand cmd = NodeCommand.fromJson(c);
  //_.input(c, "request cmd");
  //log.push("Command ${command.name} received: ${command.payload}");
  log.push(cmd);
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}

Future<HttpResponse> cmdResponseHandler(
    HttpRequest request, IsoLogger log) async {
  final content = await utf8.decoder.bind(request).join();
  final dynamic c = json.decode(content);
  final NodeCommand cmd = NodeCommand.fromJson(c);
  //_.input(c, "response cmd");
  //log.push("Responded to command $command: ${command.payload}");
  log.push(cmd);
  //command.info();
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}
