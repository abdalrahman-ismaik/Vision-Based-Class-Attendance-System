enum PoseType {
  frontal,
  leftProfile,
  rightProfile,
  lookingUp,
  lookingDown,
}

/// Backwards-compatible alias used in some tests and older code.
typedef PoseTarget = PoseType;

extension PoseTypeX on PoseType {
  String get nameLabel {
    switch (this) {
      case PoseType.frontal:
        return 'frontal';
      case PoseType.leftProfile:
        return 'left_profile';
      case PoseType.rightProfile:
        return 'right_profile';
      case PoseType.lookingUp:
        return 'looking_up';
      case PoseType.lookingDown:
        return 'looking_down';
    }
  }
}
