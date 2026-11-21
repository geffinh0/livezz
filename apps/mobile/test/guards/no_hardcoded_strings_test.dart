import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regra TRV07: nenhum texto de interface fixo nas telas. Procura literais nas
/// posições onde texto aparece para o usuário: primeiro argumento de
/// `Text`/`SelectableText`/`Tooltip` e argumentos nomeados de texto
/// (`label`, `title`, `message`, `tooltip`, `hintText`, …).
/// Identificadores técnicos (ids, flags, rotas) ficam de fora.
const _textWidgets = {'Text', 'SelectableText', 'Tooltip', 'SnackBar'};
const _textArgs = {
  'label',
  'title',
  'message',
  'tooltip',
  'semanticsLabel',
  'hintText',
  'labelText',
  'helperText',
  'errorText',
  'actionLabel',
  'confirmLabel',
};

class _Finder extends RecursiveAstVisitor<void> {
  _Finder(this.file);
  final String file;
  final hits = <String>[];

  bool _hasText(Expression e) {
    if (e is SimpleStringLiteral) return e.value.trim().isNotEmpty;
    if (e is StringInterpolation) {
      return e.elements.whereType<InterpolationString>().any(
        (s) => s.value.trim().isNotEmpty,
      );
    }
    if (e is AdjacentStrings) return e.strings.any(_hasText);
    return false;
  }

  void _check(Expression e) {
    if (_hasText(e)) hits.add('$file: ${e.toSource()}');
  }

  void _checkArgs(String name, ArgumentList args) {
    for (final a in args.arguments) {
      if (a is NamedArgument) {
        if (_textArgs.contains(a.name.lexeme)) _check(a.argumentExpression);
      }
    }
    if (_textWidgets.contains(name)) {
      final first = args.arguments.where((a) => a is! NamedArgument);
      if (first.isNotEmpty) _check(first.first as Expression);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _checkArgs(node.constructorName.type.name.lexeme, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkArgs(node.methodName.name, node.argumentList);
    super.visitMethodInvocation(node);
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

List<String> _scan(String src, String path) {
  final unit = parseString(content: src, path: path).unit;
  final finder = _Finder(path);
  unit.accept(finder);
  return finder.hits;
}

void main() {
  test('telas não têm texto fixo (use os arquivos ARB)', () {
    final hits = [
      for (final f in _screenFiles()) ..._scan(f.readAsStringSync(), f.path),
    ];
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('o detector encontra texto fixo (autoteste)', () {
    const src = '''
final a = Text('Olá');
final b = AppButton(label: 'Comprar', onPressed: f);
final c = Text('\${x}');
final d = TestId('id.tecnico', child: Text(l.ok));
final e = StateView.empty(title: 'Vazio \$n');
final g = m(label: l.x, key: ValueKey('k'));
''';
    expect(_scan(src, 'x.dart'), [
      "x.dart: 'Olá'",
      "x.dart: 'Comprar'",
      "x.dart: 'Vazio \$n'",
    ]);
  });
}
