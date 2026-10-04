/// What a code node (a sphere in the 3D world) stands for.
enum CodeNodeKind {
  /// A `class`.
  classDecl,

  /// A `mixin`.
  mixinDecl,

  /// An `enum`.
  enumDecl,

  /// An `extension`.
  extensionDecl,

  /// An `extension type`.
  extensionTypeDecl,

  /// A method.
  method,

  /// A constructor (unnamed, named or factory).
  constructor,

  /// A getter.
  getter,

  /// A setter.
  setter,

  /// A top-level function.
  function,

  /// A superclass from outside the project, holding the project classes
  /// that extend it.
  ghostParent,

  /// An external package (or the Dart SDK).
  externalPackage;

  /// Whether a node of this kind is a sphere the user can fly into.
  ///
  /// External package spheres are solid in the MVP.
  bool get isEnterable => switch (this) {
    classDecl ||
    mixinDecl ||
    enumDecl ||
    extensionDecl ||
    extensionTypeDecl ||
    ghostParent => true,
    method ||
    constructor ||
    getter ||
    setter ||
    function ||
    externalPackage => false,
  };

  /// Whether a node of this kind comes from outside the analyzed project.
  bool get isExternal => this == ghostParent || this == externalPackage;
}
