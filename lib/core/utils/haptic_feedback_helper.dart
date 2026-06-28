import 'package:haptic_feedback/haptic_feedback.dart';

class HapticHelper {
  static Future<void> light() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) {
      await Haptics.vibrate(HapticsType.light);
    }
  }

  static Future<void> success() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) {
      await Haptics.vibrate(HapticsType.success);
    }
  }

  static Future<void> error() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) {
      await Haptics.vibrate(HapticsType.error);
    }
  }

  static Future<void> heavy() async {
    final canVibrate = await Haptics.canVibrate();
    if (canVibrate) {
      await Haptics.vibrate(HapticsType.heavy);
    }
  }
}
