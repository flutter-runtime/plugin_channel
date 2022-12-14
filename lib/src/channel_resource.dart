import 'dart:convert';
import 'dart:io';
import 'package:darty_json_safe/darty_json_safe.dart';
import 'package:plugin_channel/plugin_channel.dart';
import 'package:plugin_channel/src/channel_identifier.dart';

/// 负责管理通道的资源
class ChannelResource {
  /// 通过 [ChannelIdentifier] 构造一个
  /// [channelIdentifier] ChannelIdentifier
  ChannelResource(this.channelIdentifier);

  /// 通过一个通道ID构造
  /// [channelIdentifier] 通道的唯一ID
  ChannelResource.fromIdentifier(String channelIdentifier)
      : channelIdentifier = ChannelIdentifier(channelIdentifier);

  /// 通道标识符
  final ChannelIdentifier channelIdentifier;

  /// 初始化
  /// 初始化插件缓存目录
  /// 初始化插件请求缓存目录
  /// 初始化插件返回缓存目录
  Future<void> _setup() async {
    if (!await Directory(_cachePath).exists()) {
      throw '$_cachePath does not exist';
    }
    if (!await Directory(_idePluginChannelPath).exists()) {
      await Directory(_idePluginChannelPath).create();
    }
    if (!await Directory(_requestResourcePath).exists()) {
      await Directory(_requestResourcePath).create();
    }
    if (!await Directory(_responseResourcePath).exists()) {
      await Directory(_responseResourcePath).create();
    }
  }

  /// 保存请求资源
  /// [resource] 资源
  Future<void> saveRequestResource(ChannelResponse resource) async {
    await _saveResourceInFile(resource, File(_requestResourceFilePath));
  }

  /// 保存返回资源
  /// [resources] 资源
  Future<void> saveResponseResource(ChannelResponse resources) async {
    await _saveResourceInFile(resources, File(_responseResourceFilePath));
  }

  Future<void> _saveResourceInFile(ChannelResponse resource, File file) async {
    await _setup();
    if (await file.exists()) {
      throw '${file.path} already exists';
    }
    final jsonText = JsonEncoder.withIndent(' ').convert(resource.toJson());
    await file.writeAsString(jsonText);
  }

  /// 读取请求资源
  Future<ChannelResponse> readRequestResource() async {
    return _readResource(File(_requestResourceFilePath));
  }

  /// 读取返回资源
  Future<ChannelResponse> readResponseResource() async {
    return _readResource(File(_responseResourceFilePath));
  }

  Future<ChannelResponse> _readResource(File file) async {
    await _setup();
    if (!await file.exists()) {
      throw '${file.path} does not exist';
    }
    final jsonText = await file.readAsString();
    var json = jsonDecode(jsonText);
    if (json is! Map) {
      throw '${file.path} 必需是一个 Map JSON';
    }
    final jsonObject = json.map((key, value) {
      return MapEntry<String, dynamic>(key.toString(), value);
    });
    return ChannelResponse.fromJson(jsonObject);
  }

  /// 删除请求资源
  Future<void> removeRequestResource() async {
    await _setup();
    await File(_requestResourceFilePath).delete();
  }

  /// 删除返回资源
  Future<void> removeResponseResource() async {
    await _setup();
    await File(_responseResourceFilePath).delete();
  }

  /// 是否存在请求资源
  Future<bool> isExitRequestResource() async {
    return await File(_requestResourceFilePath).exists();
  }

  /// 是否存在返回资源
  Future<bool> isExitResponseResource() async {
    return await File(_responseResourceFilePath).exists();
  }

  String get _homePath {
    final home = Platform.environment['HOME'];
    if (home == null) {
      throw 'PWD does not exist';
    }
    return home;
  }

  String get _cachePath {
    return _homePath +
        Platform.pathSeparator +
        'Library' +
        Platform.pathSeparator +
        'Caches';
  }

  String get _idePluginChannelPath {
    return _cachePath + Platform.pathSeparator + 'ide_plugin_channel';
  }

  String get _requestResourcePath {
    return _idePluginChannelPath + Platform.pathSeparator + 'request';
  }

  String get _responseResourcePath {
    return _idePluginChannelPath + Platform.pathSeparator + 'response';
  }

  String get _requestResourceFilePath {
    return _requestResourcePath +
        Platform.pathSeparator +
        channelIdentifier.identifier +
        '.json';
  }

  String get _responseResourceFilePath {
    return _responseResourcePath +
        Platform.pathSeparator +
        channelIdentifier.identifier +
        '.json';
  }
}

class ChannelResponse {
  final int code;
  final String message;
  final bool success;
  final dynamic data;

  ChannelResponse.success([this.data, this.message = ''])
      : code = 0,
        success = true;

  ChannelResponse.failure(this.message, [this.code = 1])
      : success = false,
        data = null;

  factory ChannelResponse.fromJson(Map<String, dynamic> json) {
    final success = JSON(json)['success'].boolValue;
    final message = JSON(json)['message'].stringValue;
    final code = JSON(json)['code'].intValue;
    final data = json['data'];
    if (success) {
      return ChannelResponse.success(data, message);
    } else {
      return ChannelResponse.failure(message, code);
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      'code': code,
      'message': message,
      'success': success,
    };
    if (data != null) {
      map['data'] = data;
    }
    return map;
  }
}
