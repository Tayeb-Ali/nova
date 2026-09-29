import 'package:flutter/material.dart';

import '../bridge/generated/ide_api.g.dart' as bridge;

/// Runtime kinds supported by the embedded environment (task.md §4).
enum RuntimeType {
  php,
  node,
  python,
  git,
  composer,
  go,
  rust,
  ruby,
  java,
  kotlin,
  dart,
  other;

  static RuntimeType fromId(String id) {
    switch (id) {
      case 'php':
        return RuntimeType.php;
      case 'node':
        return RuntimeType.node;
      case 'python':
        return RuntimeType.python;
      case 'git':
        return RuntimeType.git;
      case 'composer':
        return RuntimeType.composer;
      case 'go':
        return RuntimeType.go;
      case 'rust':
        return RuntimeType.rust;
      case 'ruby':
        return RuntimeType.ruby;
      case 'java':
        return RuntimeType.java;
      case 'kotlin':
        return RuntimeType.kotlin;
      case 'dart':
        return RuntimeType.dart;
      default:
        return RuntimeType.other;
    }
  }

  /// True for programming languages (grouped under "Languages");
  /// tools (git/composer/ssh/…) go under "Tools".
  bool get isLanguage {
    switch (this) {
      case RuntimeType.php:
      case RuntimeType.node:
      case RuntimeType.python:
      case RuntimeType.go:
      case RuntimeType.rust:
      case RuntimeType.ruby:
      case RuntimeType.java:
      case RuntimeType.kotlin:
      case RuntimeType.dart:
        return true;
      case RuntimeType.git:
      case RuntimeType.composer:
      case RuntimeType.other:
        return false;
    }
  }

  /// Leading icon for runtime tiles.
  IconData get icon {
    switch (this) {
      case RuntimeType.php:
        return Icons.language;
      case RuntimeType.node:
        return Icons.integration_instructions;
      case RuntimeType.python:
        return Icons.terminal;
      case RuntimeType.go:
        return Icons.speed;
      case RuntimeType.rust:
        return Icons.shield_outlined;
      case RuntimeType.ruby:
        return Icons.diamond_outlined;
      case RuntimeType.java:
        return Icons.coffee_outlined;
      case RuntimeType.kotlin:
        return Icons.bolt_outlined;
      case RuntimeType.dart:
        return Icons.flutter_dash;
      case RuntimeType.git:
        return Icons.account_tree;
      case RuntimeType.composer:
        return Icons.inventory_2;
      case RuntimeType.other:
        return Icons.extension_outlined;
    }
  }

  /// One-line description shown under the runtime name.
  String get description {
    switch (this) {
      case RuntimeType.php:
        return 'لغة الويب — Laravel وWordPress';
      case RuntimeType.node:
        return 'JavaScript وTypeScript — npm مدمجة';
      case RuntimeType.python:
        return 'سكربتات وبيانات — pip مدمجة';
      case RuntimeType.go:
        return 'لغة Go المترجمة — سريعة وخفيفة';
      case RuntimeType.rust:
        return 'لغة Rust — أمان الذاكرة والأداء';
      case RuntimeType.ruby:
        return 'لغة Ruby للسكربتات والويب';
      case RuntimeType.java:
        return 'Java 25 — منصة JVM كاملة';
      case RuntimeType.kotlin:
        return 'Kotlin — تعمل على JVM (تحتاج Java)';
      case RuntimeType.dart:
        return 'Dart — تطبيقات وأدوات سطر أوامر';
      case RuntimeType.git:
        return 'إدارة الإصدارات والمستودعات';
      case RuntimeType.composer:
        return 'مدير حزم PHP';
      case RuntimeType.other:
        return '';
    }
  }
}

class RuntimeInfo {
  final String id;
  final String displayName;
  final String? version;
  final bool installed;
  final String? executable;

  RuntimeInfo({
    required this.id,
    required this.displayName,
    this.version,
    this.installed = false,
    this.executable,
  });

  RuntimeType get type => RuntimeType.fromId(id);

  factory RuntimeInfo.fromBridge(bridge.RuntimeInfo b) => RuntimeInfo(
        id: b.id,
        displayName: b.displayName,
        version: b.version,
        installed: b.installed,
        executable: b.executable,
      );
}