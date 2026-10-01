import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
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
  c,
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
      case 'c':
        return RuntimeType.c;
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
      case RuntimeType.c:
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
      case RuntimeType.c:
        return Icons.memory_outlined;
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
      case RuntimeType.c:
        return 'لغة C وC++ — مترجم Clang السريع';
      case RuntimeType.git:
        return 'إدارة الإصدارات والمستودعات';
      case RuntimeType.composer:
        return 'مدير حزم PHP';
      case RuntimeType.other:
        return '';
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    switch (this) {
      case RuntimeType.php:
        return l10n.runtimeDescPhp;
      case RuntimeType.node:
        return l10n.runtimeDescNode;
      case RuntimeType.python:
        return l10n.runtimeDescPython;
      case RuntimeType.go:
        return l10n.runtimeDescGo;
      case RuntimeType.rust:
        return l10n.runtimeDescRust;
      case RuntimeType.ruby:
        return l10n.runtimeDescRuby;
      case RuntimeType.java:
        return l10n.runtimeDescJava;
      case RuntimeType.kotlin:
        return l10n.runtimeDescKotlin;
      case RuntimeType.dart:
        return l10n.runtimeDescDart;
      case RuntimeType.c:
        return l10n.runtimeDescC;
      case RuntimeType.git:
        return l10n.runtimeDescGit;
      case RuntimeType.composer:
        return l10n.runtimeDescComposer;
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
  /// False when the runtime has no packages for this device ABI.
  /// Null (old hosts / tests) means supported.
  final bool? supported;

  RuntimeInfo({
    required this.id,
    required this.displayName,
    this.version,
    this.installed = false,
    this.executable,
    this.supported,
  });

  /// Whether this runtime can be installed on this device.
  bool get isSupported => supported ?? true;

  RuntimeType get type => RuntimeType.fromId(id);

  /// True for install packs (metapackages, ids `nova-*`): one-tap groups,
  /// installed when all member binaries exist. Derived client-side so the
  /// bridge contract stays untouched.
  bool get isPack => id.startsWith('nova-');

  /// Tile icon: pack-specific for packs, per-language otherwise.
  IconData get displayIcon {
    if (!isPack) return type.icon;
    switch (id) {
      case 'nova-web':
        return Icons.web_asset_outlined;
      case 'nova-systems':
        return Icons.handyman_outlined;
      case 'nova-jvm':
        return Icons.coffee_outlined;
      case 'nova-python':
        return Icons.science_outlined;
      case 'nova-dart':
        return Icons.flutter_dash;
      default:
        return Icons.widgets_outlined;
    }
  }

  /// Tile subtitle: pack members for packs, per-language otherwise.
  String get displayDescription {
    if (!isPack) return type.description;
    switch (id) {
      case 'nova-web':
        return 'PHP + Composer + Ruby + Node.js — تطوير الويب';
      case 'nova-systems':
        return 'Rust + Go + make + cmake — لغات الأنظمة';
      case 'nova-jvm':
        return 'Java 25 + Kotlin — منصة JVM';
      case 'nova-python':
        return 'Python + pip — سكربتات وبيانات';
      case 'nova-dart':
        return 'Dart — أدوات سطر الأوامر';
      default:
        return '';
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    if (!isPack) return type.localizedDescription(l10n);
    switch (id) {
      case 'nova-web':
        return l10n.runtimeDescNovaWeb;
      case 'nova-systems':
        return l10n.runtimeDescNovaSystems;
      case 'nova-jvm':
        return l10n.runtimeDescNovaJvm;
      case 'nova-python':
        return l10n.runtimeDescNovaPython;
      case 'nova-dart':
        return l10n.runtimeDescNovaDart;
      default:
        return '';
    }
  }

  factory RuntimeInfo.fromBridge(bridge.RuntimeInfo b) => RuntimeInfo(
        id: b.id,
        displayName: b.displayName,
        version: b.version,
        installed: b.installed,
        executable: b.executable,
        supported: b.supported,
      );
}