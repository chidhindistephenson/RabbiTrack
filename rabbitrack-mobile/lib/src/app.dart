import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import 'theme/rabbitrack_colors.dart';

class RabbiTrackApp extends ConsumerWidget {
  const RabbiTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RabbiTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: RabbiTrackColors.forestGreen,
          primary: RabbiTrackColors.forestGreen,
          secondary: RabbiTrackColors.sageGreen,
          surface: RabbiTrackColors.cream,
        ),
        scaffoldBackgroundColor: RabbiTrackColors.cream,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: RabbiTrackColors.cream,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: RabbiTrackColors.warmTan,
          foregroundColor: RabbiTrackColors.forestGreen,
          extendedTextStyle: TextStyle(
            color: RabbiTrackColors.forestGreen,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: RabbiTrackColors.forestGreen,
            foregroundColor: RabbiTrackColors.cream,
            disabledBackgroundColor: RabbiTrackColors.mintGreen,
            disabledForegroundColor: RabbiTrackColors.forestGreen,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: RabbiTrackColors.forestGreen,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: RabbiTrackColors.forestGreen.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
          hintStyle: TextStyle(
            color: RabbiTrackColors.forestGreen.withValues(alpha: 0.45),
          ),
          prefixIconColor: RabbiTrackColors.sageGreen,
          suffixIconColor: RabbiTrackColors.sageGreen,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: RabbiTrackColors.forestGreen.withValues(alpha: 0.12),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: RabbiTrackColors.forestGreen,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: RabbiTrackColors.cream,
          modalBackgroundColor: RabbiTrackColors.cream,
          showDragHandle: true,
          dragHandleColor: RabbiTrackColors.sageGreen,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: RabbiTrackColors.cream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
