import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialHelper {
  static Future<void> showTutorialIfFirstTime({
    required BuildContext context,
    required String prefKey,
    required List<TargetFocus> targets,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(prefKey) ?? false;

    if (!hasShown) {
      if (!context.mounted) return;
      TutorialCoachMark(
        targets: targets,
        colorShadow: Colors.black,
        textSkip: "SKIP",
        paddingFocus: 10,
        opacityShadow: 0.8,
        onFinish: () {
          prefs.setBool(prefKey, true);
        },
        onClickTarget: (target) {

        },
        onClickOverlay: (target) {

        },
        onSkip: () {
          prefs.setBool(prefKey, true);
          return true;
        },
      ).show(context: context);
    }
  }

  static Future<void> resetTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = ['tutorial_projects', 'tutorial_canvas', 'tutorial_endpoint', 'tutorial_environment'];
    for (final key in keys) {
      await prefs.setBool(key, false);
    }
  }
}
