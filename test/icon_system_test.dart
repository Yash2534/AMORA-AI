import 'dart:io';

import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Material icon assets are enabled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('uses-material-design: true'));
  });

  test('source does not depend on undeclared or raw icon fonts', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final cupertinoImport =
        'package:flutter/'
        'cupertino.dart';
    final cupertinoIcons =
        'Cupertino'
        'Icons.';
    final rawIconData = RegExp(r'IconData\s*\(\s*0x');

    for (final source in sources) {
      final contents = source.readAsStringSync();
      expect(contents, isNot(contains(cupertinoImport)), reason: source.path);
      expect(contents, isNot(contains(cupertinoIcons)), reason: source.path);
      expect(contents, isNot(matches(rawIconData)), reason: source.path);
    }
  });

  test('Amora semantic icons use the bundled Material icon font', () {
    const icons = <IconData>[
      AmoraIcons.discover,
      AmoraIcons.events,
      AmoraIcons.chats,
      AmoraIcons.profile,
      AmoraIcons.back,
      AmoraIcons.forward,
      AmoraIcons.close,
      AmoraIcons.heart,
      AmoraIcons.heartFill,
      AmoraIcons.sparkle,
      AmoraIcons.filter,
      AmoraIcons.lock,
      AmoraIcons.check,
      AmoraIcons.search,
      AmoraIcons.phone,
      AmoraIcons.message,
      AmoraIcons.verified,
      AmoraIcons.premium,
      AmoraIcons.ai,
      AmoraIcons.play,
      AmoraIcons.pause,
      AmoraIcons.photo,
      AmoraIcons.video,
      AmoraIcons.mic,
      AmoraIcons.shield,
      AmoraIcons.location,
      AmoraIcons.copy,
      AmoraIcons.send,
      AmoraIcons.edit,
      AmoraIcons.calendar,
      AmoraIcons.bookmark,
      AmoraIcons.rewind,
      AmoraIcons.eye,
      AmoraIcons.more,
      AmoraIcons.emoji,
      AmoraIcons.attachment,
      AmoraIcons.upload,
    ];

    for (final icon in icons) {
      expect(icon.fontFamily, 'MaterialIcons');
      expect(icon.fontPackage, isNull);
      expect(icon.codePoint, greaterThan(0));
    }
  });
}
