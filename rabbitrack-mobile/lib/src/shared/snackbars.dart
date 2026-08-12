import 'package:flutter/material.dart';

import '../theme/rabbitrack_colors.dart';

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: RabbiTrackColors.forestGreen,
      content: Text(message),
    ),
  );
}
