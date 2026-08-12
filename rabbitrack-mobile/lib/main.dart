import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/theme/rabbitrack_colors.dart';

void main() {
  ErrorWidget.builder = (details) {
    FlutterError.presentError(details);

    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: RabbiTrackColors.cream,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_outlined,
                  color: RabbiTrackColors.forestGreen,
                  size: 36,
                ),
                SizedBox(height: 12),
                Text(
                  'This screen hit a problem.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Move to another tab and come back, or reopen the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF61706A)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(const ProviderScope(child: RabbiTrackApp()));
}
