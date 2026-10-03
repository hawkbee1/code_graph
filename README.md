# code_graph

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

The **code map** model of [dart_code_3D](https://github.com/hawkbee1/dart_code_3d)
and its file format. Pure Dart (no Flutter), works on every platform including the web.

## Part of hawkbee

This repository is a git submodule of the
[hawkbee](https://github.com/hawkbee1/hawkbee) monorepo and **only builds inside
it** (pub workspace, `scene` from hawkbee's `packages/flutter_scene` submodule):

```sh
git clone --recurse-submodules https://github.com/hawkbee1/hawkbee.git
cd hawkbee && flutter pub get
```

Design docs: hawkbee's [docs/dart_code_3d](https://github.com/hawkbee1/hawkbee/tree/main/docs/dart_code_3d)
(architecture §4 describes the file format).

## Model

| Type | What it is |
|---|---|
| `CodeNode` | One sphere: a class, mixin, enum, extension, extension type, method, constructor, getter, setter, top-level function, **ghost parent** (external superclass holding the project classes that extend it) or **external package**. `parentId` gives the containment tree: members inside their class, a subclass inside its project superclass. |
| `CodeLink` | A directed link (`call`, `import`, `implementsLink`, `mixinLink`, `extendsExternal`) with a resolution quality (`exact`, `byName`, `ambiguous`, `external`) and a `count`. |
| `CodeGraph` | Nodes + links + `ProjectInfo` (source, rules used, entry node, stats). Validated on construction; indexes: `topLevel`, `childrenOf`, `ancestorsOf`, `depthOf`, `linksFrom`, `linksTo`. |
| `Placement` | Position relative to the parent's center + radius, in world units. |
| `CodeMap` | A graph with one placement per node: what a file holds. |

### Stable ids

Ids stay the same across analyses of the same code, so maps can be compared:

| Node | Id |
|---|---|
| Declaration | `<file path>#<qualified name>`, e.g. `lib/src/user.dart#UserRepository.save` |
| External package | `pkg:<name>`, e.g. `pkg:flutter` |
| Ghost parent | `ghost:<package>:<Class>`, e.g. `ghost:flutter:StatelessWidget` |

## File format

`CodeMapCodec` converts a `CodeMap` to a flutter_scene `SceneDocument` and back:

- one scene node per code node, nested like the containment tree under a root
  named `dc3d root`, each with a `mesh` (shared sphere geometry, one material per kind);
- the code data in custom components: `dc3d.code_element` per node (with the exact
  placement), `dc3d.project` and `dc3d.code_links` (columns of node indices) on the root.

`encodeToBytes` writes a **`.dc3d` file = gzip-compressed `.fscene` JSON**
(~25× smaller: 20,000 nodes and 60,000 links give 52.6 MB of JSON but a 2.0 MB file).
`gunzip` gives back a plain `.fscene` that opens in the Flutter Scene Editor.
`decodeFromBytes` reads `.dc3d` and plain `.fscene` and reports any unreadable
input as a `CodeMapFormatException`.

[`test/fixtures/tiny.fscene`](test/fixtures/tiny.fscene) is a complete small example
(regenerate it with `dart run test/fixtures/write_fixtures.dart`).

## Running tests

```sh
very_good test --coverage
```

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
