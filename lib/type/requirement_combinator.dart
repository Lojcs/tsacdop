enum RequirementCombinator {
  all("all", sql: " AND", combine: _combineAll),
  any("any", sql: " OR", combine: _combineAny);

  const RequirementCombinator(
    this.serial, {
    required this.sql,
    required this.combine,
  });
  factory RequirementCombinator.fromSerial(String serial) => switch (serial) {
    "all" => all,
    "any" => any,
    _ => all,
  };
  final String serial;
  final String sql;
  final bool Function(bool b0, bool b1) combine;
  static bool _combineAll(bool b0, bool b1) => b0 && b1;
  static bool _combineAny(bool b0, bool b1) => b0 || b1;
}
