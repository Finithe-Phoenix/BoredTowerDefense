/// Packs boolean flags into a single double precision value so we can send
/// multiple uniform states to GLSL without needing many float uniforms.
class FlagPacker {
  /// Packs up to 32 boolean flags into a [double].
  static double pack(List<bool> flags) {
    var value = 0;
    for (var i = 0; i < flags.length && i < 32; i++) {
      if (flags[i]) {
        value |= (1 << i);
      }
    }
    return value.toDouble();
  }

  /// Unpacks the boolean at [index] from the packed [value].
  static bool unpack(double value, int index) {
    if (index < 0 || index >= 32) return false;
    final mask = 1 << index;
    return (value.toInt() & mask) != 0;
  }

  /// Convenience helper that returns a closure which evaluates the packed flag.
  static bool Function(int index) createReader(double value) {
    return (int index) => unpack(value, index);
  }
}
