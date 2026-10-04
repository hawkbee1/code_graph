import 'package:code_graph/src/model/code_node_kind.dart';

/// Default sphere color (linear RGB, 0..1) of each node kind in `.fscene`
/// files. The viewer may override them with its theme.
const Map<CodeNodeKind, ({double r, double g, double b})> kindColors = {
  CodeNodeKind.classDecl: (r: 0.20, g: 0.45, b: 0.85),
  CodeNodeKind.mixinDecl: (r: 0.55, g: 0.35, b: 0.85),
  CodeNodeKind.enumDecl: (r: 0.15, g: 0.65, b: 0.60),
  CodeNodeKind.extensionDecl: (r: 0.85, g: 0.55, b: 0.20),
  CodeNodeKind.extensionTypeDecl: (r: 0.80, g: 0.40, b: 0.55),
  CodeNodeKind.method: (r: 0.35, g: 0.70, b: 0.35),
  CodeNodeKind.constructor: (r: 0.85, g: 0.75, b: 0.25),
  CodeNodeKind.getter: (r: 0.45, g: 0.75, b: 0.75),
  CodeNodeKind.setter: (r: 0.75, g: 0.45, b: 0.45),
  CodeNodeKind.function: (r: 0.25, g: 0.60, b: 0.90),
  CodeNodeKind.ghostParent: (r: 0.70, g: 0.70, b: 0.75),
  CodeNodeKind.externalPackage: (r: 0.45, g: 0.45, b: 0.50),
};
