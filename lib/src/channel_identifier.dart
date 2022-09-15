import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 通道的唯一标识符
class ChannelIdentifier {
  /// 通过一个插件名称构造一个通道标识符
  /// [pluginName] 插件的名称 插件名称必须唯一
  ChannelIdentifier.fromPluginName(String pluginName)
      : identifier = _generateIdentifier(pluginName);

  /// 根据已经存在通道ID构造一个通道标识符
  /// [identifier] 已经存在的通道ID
  ChannelIdentifier(this.identifier);

  /// 唯一的 ID
  final String identifier;
}

/// 生成一个唯一ID
/// [pluginName] 插件的名称
String _generateIdentifier(String pluginName) {
  final time = DateTime.now().millisecondsSinceEpoch.toString();
  final id = pluginName + '_' + time;
  return md5.convert(utf8.encode(id)).toString();
}
