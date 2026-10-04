import 'package:code_graph/src/model/code_graph.dart';
import 'package:equatable/equatable.dart';
import 'package:vector_math/vector_math.dart';

/// Where a node's sphere is: [x], [y], [z] relative to its parent's center
/// (the world origin at the top level), and its [radius], in world units.
class Placement extends Equatable {
  /// Creates a placement.
  const new({
    required this.x,
    required this.y,
    required this.z,
    required this.radius,
  });

  /// X coordinate relative to the parent's center.
  final double x;

  /// Y coordinate relative to the parent's center.
  final double y;

  /// Z coordinate relative to the parent's center.
  final double z;

  /// Radius of the sphere.
  final double radius;

  /// The position as a (single precision) vector, for rendering.
  Vector3 get position => Vector3(x, y, z);

  @override
  List<Object?> get props => [x, y, z, radius];
}

/// A [graph] laid out in 3D: what a `.fscene` code map file holds.
class CodeMap extends Equatable {
  /// Creates a code map; every node of [graph] needs exactly one placement.
  new({required this.graph, required Map<String, Placement> placements})
    : placements = Map.unmodifiable(placements) {
    for (final id in graph.nodes.keys) {
      if (!placements.containsKey(id)) {
        throw CodeGraphException('node "$id" has no placement');
      }
    }
    for (final id in placements.keys) {
      if (!graph.nodes.containsKey(id)) {
        throw CodeGraphException('placement for unknown node "$id"');
      }
    }
  }

  /// The analyzed code.
  final CodeGraph graph;

  /// Where each node's sphere is, by node id.
  final Map<String, Placement> placements;

  @override
  List<Object?> get props => [graph, placements];
}
