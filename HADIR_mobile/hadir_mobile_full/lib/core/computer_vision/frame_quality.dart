enum FrameQuality {
  excellent,
  good,
  fair,
  poor,
}

extension FrameQualityX on FrameQuality {
  String get label {
    switch (this) {
      case FrameQuality.excellent:
        return 'excellent';
      case FrameQuality.good:
        return 'good';
      case FrameQuality.fair:
        return 'fair';
      case FrameQuality.poor:
        return 'poor';
    }
  }
}
