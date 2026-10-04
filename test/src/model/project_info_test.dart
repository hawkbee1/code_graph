import 'package:code_graph/code_graph.dart';
import 'package:test/test.dart';

void main() {
  group(SourceDescriptor, () {
    test('round-trips every descriptor through JSON', () {
      for (final descriptor in const <SourceDescriptor>[
        LocalFolderDescriptor(name: 'my_app'),
        GitDescriptor(url: 'https://github.com/o/r'),
        GitDescriptor(url: 'https://github.com/o/r', ref: 'v1', commit: 'abc'),
        ZipDescriptor(fileName: 'r.zip'),
      ]) {
        expect(SourceDescriptor.fromJson(descriptor.toJson()), descriptor);
      }
    });

    test('throws $FormatException for an unknown type', () {
      expect(
        () => SourceDescriptor.fromJson(const {'type': 'svn'}),
        throwsA(isA<FormatException>()),
      );
    });

    group('label', () {
      test('is the folder or file name', () {
        expect(const LocalFolderDescriptor(name: 'my_app').label, 'my_app');
        expect(const ZipDescriptor(fileName: 'r.zip').label, 'r.zip');
      });

      test('is the repository name, with the ref when set', () {
        expect(
          const GitDescriptor(url: 'https://github.com/TalaoDAO/AltMe').label,
          'AltMe',
        );
        expect(
          const GitDescriptor(
            url: 'https://github.com/TalaoDAO/AltMe.git/',
            ref: 'main',
          ).label,
          'AltMe @ main',
        );
      });
    });
  });

  group(GraphStats, () {
    test('defaults every counter to 0, also when read from JSON', () {
      expect(GraphStats.fromJson(const {}), const GraphStats());
      expect(const GraphStats().nodes, 0);
    });

    test('round-trips through JSON', () {
      const stats = GraphStats(
        files: 1,
        parseErrors: 2,
        nodes: 3,
        links: 4,
        durationMs: 5,
      );

      expect(GraphStats.fromJson(stats.toJson()), stats);
    });
  });

  group(ProjectInfo, () {
    test('round-trips through JSON', () {
      final info = ProjectInfo(
        generator: 'g',
        source: const ZipDescriptor(fileName: 'a.zip'),
        createdAt: DateTime.utc(2026, 10, 3),
        rules: const {'links.imports': false},
        entryNodeId: 'lib/main.dart#main',
        stats: const GraphStats(files: 3),
      );

      expect(info.schemaVersion, ProjectInfo.currentSchemaVersion);
      expect(ProjectInfo.fromJson(info.toJson()), info);
    });

    test('writes createdAt in UTC and reads missing rules and stats', () {
      final info = ProjectInfo(
        generator: 'g',
        source: const ZipDescriptor(fileName: 'a.zip'),
        createdAt: DateTime.utc(2026),
      );
      final json = info.toJson()
        ..remove('rules')
        ..remove('stats');

      expect(info.toJson()['createdAt'], '2026-01-01T00:00:00.000Z');
      expect(ProjectInfo.fromJson(json), info);
    });
  });
}
