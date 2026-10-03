import 'package:code_graph/code_graph.dart';
import 'package:test/test.dart';

void main() {
  group(CodeLink, () {
    test('defaults to an exact link counted once', () {
      const link = CodeLink(fromId: 'a', toId: 'b', kind: LinkKind.call);

      expect(link.resolution, LinkResolution.exact);
      expect(link.count, 1);
    });

    test('round-trips through JSON', () {
      const link = CodeLink(
        fromId: 'a',
        toId: 'b',
        kind: LinkKind.mixinLink,
        resolution: LinkResolution.ambiguous,
        count: 4,
      );

      expect(link.toJson(), {
        'from': 'a',
        'to': 'b',
        'kind': 'mixinLink',
        'resolution': 'ambiguous',
        'count': 4,
      });
      expect(CodeLink.fromJson(link.toJson()), link);
    });

    test('supports value equality', () {
      expect(
        const CodeLink(fromId: 'a', toId: 'b', kind: LinkKind.call),
        const CodeLink(fromId: 'a', toId: 'b', kind: LinkKind.call),
      );
      expect(
        const CodeLink(fromId: 'a', toId: 'b', kind: LinkKind.call),
        isNot(const CodeLink(fromId: 'a', toId: 'b', kind: LinkKind.import)),
      );
    });
  });
}
