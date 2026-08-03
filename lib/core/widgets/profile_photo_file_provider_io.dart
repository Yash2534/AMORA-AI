import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider<Object>? localProfilePhotoFileProvider(String source) {
  final value = source.trim();
  if (value.isEmpty ||
      value.startsWith('data:image/') ||
      value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('blob:') ||
      value.startsWith('assets/')) {
    return null;
  }
  final path = value.startsWith('file://')
      ? Uri.parse(value).toFilePath(windows: Platform.isWindows)
      : value;
  if (!File(path).isAbsolute) return null;
  return FileImage(File(path));
}
