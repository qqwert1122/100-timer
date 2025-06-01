import 'dart:math';

class TimelineCalculator {
  static double calculateTimelineWidth({
    required int totalDuration,
    required double screenWidth,
    required int totalBreakBlocks,
    double minBlockWidth = 4.0,
    double pixelsPerSecond = 0.4,
  }) {
    final minRequiredWidth = totalBreakBlocks * minBlockWidth * 2.0;
    final baseScale = totalDuration * pixelsPerSecond;
    final minScale = max(minRequiredWidth, screenWidth);
    return max(baseScale, minScale);
  }

  static double positionToSeconds(double position, double timelineWidth, int totalDuration) {
    return (position / timelineWidth) * totalDuration;
  }

  static double secondsToPosition(int seconds, double timelineWidth, int totalDuration) {
    return (seconds / totalDuration) * timelineWidth;
  }

  static int pixelDeltaToSeconds(double deltaX, double timelineWidth, int totalDuration) {
    final secondsPerPixel = totalDuration / timelineWidth;
    return (deltaX * secondsPerPixel).round();
  }
}
