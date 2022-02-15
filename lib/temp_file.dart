import 'dart:io';

import 'package:flutter/material.dart';

class TempFilePage extends StatelessWidget {
  final File tempFile;
  const TempFilePage({Key? key, required this.tempFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Center(
        child: Image.file(
          File(tempFile.path),
          height: 120,
          width: 120,
        ),
      ),
    );
  }
}
