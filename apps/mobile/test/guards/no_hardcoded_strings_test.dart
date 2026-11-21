import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regra TRV07: nenhum texto de interface fixo no código de telas.
/// Vale para arquivos de tela: `lib/core/ui/`, `lib/app/*_screen.dart` e
/// `lib/features/**/presentation/`. Rotas ficam em `lib/app/routes.dart`.
/// Permitido: strings dentro de `Key`/`ValueKey`/`TestId` e argumentos `id:`
/// (ids técnicos),
/// diretivas (import/part) e anotações.
const _idTypes = {'Key', 'ValueKey', 'TestId'};

class _Finder extends RecursiveAstVisitor<void> {
  _Finder(this.file);
  final String file;
  final hits = <String>[];

  bool _allowed(AstNode node) {
    for (AstNode? p = node.parent; p != null; p = p.parent) {
      if (p is Directive || p is Annotation) return true;
      if (p is NamedArgument && p.name.lexeme == 'id') return true;
      if (p is InstanceCreationExpression) {
        final name = p.constructorName.type.name.lexeme;
        if (_idTypes.contains(name)) return true;
      }
      if (p is MethodInvocation) {
        final name = p.methodName.name;
        if (_idTypes.contains(name)) return true;
      }
    }
    return false;
  }

  void _check(StringLiteral node) {
    final value = node.stringValue;
    if (value != null && value.trim().isEmpty) return;
    if (_allowed(node)) return;
    hits.add('$file: ${node.toSource()}');
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) => _check(node);

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _check(node);
  }
}

Iterable<File> _screenFiles() sync* {
  for (final dir in ['lib/core/ui', 'lib/app', 'lib/features']) {
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    for (final f in d.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) continue;
      if (dir == 'lib/features' && !f.path.contains('/presentation/')) continue;
      if (dir == 'lib/app' && !f.path.endsWith('_screen.dart')) continue;
      yield f;
    }
  }
}

void main() {
  test('telas não têm texto fixo (use os arquivos ARB)', () {
    final hits = <String>[];
    for (final f in _screenFiles()) {
      final unit = parseString(
        content: f.readAsStringSync(),
        path: f.path,
      ).unit;
      final finder = _Finder(f.path);
      unit.accept(finder);
      hits.addAll(finder.hits);
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('o detector encontra texto fixo (autoteste)', () {
    const src = '''
import 'x.dart';
final a = Text('Olá');
final b = Text(key: ValueKey('ok-id'), x);
''';
    final unit = parseString(content: src, path: 'x.dart').unit;
    final finder = _Finder('x.dart');
    unit.accept(finder);
    expect(finder.hits, ["x.dart: 'Olá'"]);
  });
}
