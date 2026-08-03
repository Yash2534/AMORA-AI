import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider<Object>? localProfilePhotoFileProvider(String source) {
  final value = source.trim();
  if (value.isEmpty ||
      value.startsWith('data:image/') ||
      value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('blob:') ||
      value.startsWith('content://') ||
      value.startsWith('assets/')) {
    return null;
  }
  late final String path;
  try {
    path = value.startsWith('file://')
        ? Uri.parse(value).toFilePath(windows: Platform.isWindows)
        : value;
  } on FormatException {
    return null;
  } on UnsupportedError {
    return null;
  }
  if (!File(path).isAbsolute) return null;
  return FileImage(File(path));
}
