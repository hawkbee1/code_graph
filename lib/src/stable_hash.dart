/// 32-bit FNV-1a hash of [value]'s UTF-16 code units, starting from [seed].
///
/// Unlike `String.hashCode`, it is the same on every run and every platform,
/// web included (the arithmetic stays below 2^53 and masks to 32 bits), so it
/// can seed deterministic layouts and ids.
int stableHash(String value, {int seed = 0x811C9DC5}) {
  var hash = seed & 0xFFFFFFFF;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    // hash * 16777619 (0x01000193), split so no intermediate exceeds 2^53.
    hash = (hash * 0x193 + ((hash << 24) & 0xFFFFFFFF)) & 0xFFFFFFFF;
  }
  return hash;
}
