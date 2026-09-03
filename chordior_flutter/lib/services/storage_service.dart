import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局用户偏好与乐理状态持久化服务
/// 支持在浏览器刷新或应用重启后，自动完整恢复用户的所有配置与选中的和弦/调式音符
class StorageService {
  static const String _kPrefsKey = 'chordior_user_preferences_v2';
  static SharedPreferences? _prefs;

  /// 初始化 SharedPreferences 实例
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[StorageService] 初始化失败: $e');
    }
  }

  /// 保存所有配置为 JSON 字典
  static Future<void> savePreferences(Map<String, dynamic> data) async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      final jsonStr = jsonEncode(data);
      await _prefs?.setString(_kPrefsKey, jsonStr);
    } catch (e) {
      debugPrint('[StorageService] 保存用户配置失败: $e');
    }
  }

  /// 读取已保存的偏好配置
  static Future<Map<String, dynamic>?> loadPreferences() async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      final jsonStr = _prefs?.getString(_kPrefsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('[StorageService] 加载用户配置失败: $e');
    }
    return null;
  }
}
