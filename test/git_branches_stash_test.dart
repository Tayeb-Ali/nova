import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/bridge/generated/ide_api.g.dart' as bridge;
import 'package:nova/src/core/services/git_service.dart';
import 'package:nova/src/features/git/diff_view.dart';
import 'package:nova/src/features/git/git_screen.dart';

/// NEXT_PLAN 2.2 (G0+G1+G2): per-file stage, colored per-file diff,
/// branches and stash. All native calls are mocked at the Pigeon channel
/// layer via [TestDefaultBinaryMessenger]; no device needed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const statusChannel = 'dev.flutter.pigeon.codeide.GitApi.status';
  const addChannel = 'dev.flutter.pigeon.codeide.GitApi.add';
  const listBranchesChannel = 'dev.flutter.pigeon.codeide.GitApi.listBranches';
  const currentBranchChannel =
      'dev.flutter.pigeon.codeide.GitApi.currentBranch';
  const checkoutChannel = 'dev.flutter.pigeon.codeide.GitApi.checkout';
  const createBranchChannel =
      'dev.flutter.pigeon.codeide.GitApi.createBranch';
  const deleteBranchChannel =
      'dev.flutter.pigeon.codeide.GitApi.deleteBranch';
  const stashListChannel = 'dev.flutter.pigeon.codeide.GitApi.stashList';
  const stashSaveChannel = 'dev.flutter.pigeon.codeide.GitApi.stashSave';
  const stashPopChannel = 'dev.flutter.pigeon.codeide.GitApi.stashPop';
  const stashDropChannel = 'dev.flutter.pigeon.codeide.GitApi.stashDrop';

  final Map<String, List<List<Object?>>> calls = {};
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  ByteData? reply(Object? value) =>
      bridge.GitApi.pigeonChannelCodec.encodeMessage(<Object?>[value]);

  void record(String channel, ByteData? message) {
    final Object? decoded = const StandardMessageCodec().decodeMessage(
      message,
    );
    calls.putIfAbsent(channel, () => []).add(
      (decoded as List<Object?>).toList(),
    );
  }

  setUp(() {
    calls.clear();
    messenger.setMockMessageHandler(statusChannel, (ByteData? message) async {
      record(statusChannel, message);
      return reply(
        bridge.GitStatus(
          branch: 'main',
          modified: const ['a.dart'],
          added: const [],
          deleted: const [],
          untracked: const [],
        ),
      );
    });
    messenger.setMockMessageHandler(addChannel, (ByteData? message) async {
      record(addChannel, message);
      return reply(null);
    });
    messenger.setMockMessageHandler(listBranchesChannel, (
      ByteData? message,
    ) async {
      record(listBranchesChannel, message);
      return reply(<Object?>['main', 'dev']);
    });
    messenger.setMockMessageHandler(currentBranchChannel, (
      ByteData? message,
    ) async {
      record(currentBranchChannel, message);
      return reply('main');
    });
    messenger.setMockMessageHandler(checkoutChannel, (
      ByteData? message,
    ) async {
      record(checkoutChannel, message);
      return reply(null);
    });
    messenger.setMockMessageHandler(createBranchChannel, (
      ByteData? message,
    ) async {
      record(createBranchChannel, message);
      return reply(null);
    });
    messenger.setMockMessageHandler(deleteBranchChannel, (
      ByteData? message,
    ) async {
      record(deleteBranchChannel, message);
      return reply(null);
    });
    messenger.setMockMessageHandler(stashListChannel, (
      ByteData? message,
    ) async {
      record(stashListChannel, message);
      return reply(<Object?>['stash@{0}: WIP on main: demo']);
    });
    messenger.setMockMessageHandler(stashSaveChannel, (
      ByteData? message,
    ) async {
      record(stashSaveChannel, message);
      return reply(null);
    });
    messenger.setMockMessageHandler(stashPopChannel, (
      ByteData? message,
    ) async {
      record(stashPopChannel, message);
      return reply(null);
    });
    messenger.setMockMessageHandler(stashDropChannel, (
      ByteData? message,
    ) async {
      record(stashDropChannel, message);
      return reply(null);
    });
  });

  tearDown(() {
    for (final channel in <String>[
      statusChannel,
      addChannel,
      listBranchesChannel,
      currentBranchChannel,
      checkoutChannel,
      createBranchChannel,
      deleteBranchChannel,
      stashListChannel,
      stashSaveChannel,
      stashPopChannel,
      stashDropChannel,
    ]) {
      messenger.setMockMessageHandler(channel, null);
    }
  });

  const twoFileDiff =
      'diff --git a/a.dart b/a.dart\n'
      'index 111..222 100644\n'
      '--- a/a.dart\n'
      '+++ b/a.dart\n'
      '@@ -1 +1 @@\n'
      '-old\n'
      '+new\n'
      'diff --git a/b.dart b/b.dart\n'
      'index 333..444 100644\n'
      '--- a/b.dart\n'
      '+++ b/b.dart\n'
      '@@ -2 +2 @@\n'
      '-gone\n'
      '+here\n';

  group('G0 diff splitting', () {
    test('splitDiff splits on diff --git headers', () {
      final sections = splitDiff(twoFileDiff);
      expect(sections, hasLength(2));
      expect(sections[0].header, 'diff --git a/a.dart b/a.dart');
      expect(sections[1].header, 'diff --git a/b.dart b/b.dart');
      expect(sections[0].lines, contains('-old'));
      expect(sections[1].lines, contains('+here'));
    });

    test('splitDiff without headers yields a single section', () {
      final sections = splitDiff('nothing to commit');
      expect(sections, hasLength(1));
      expect(sections.single.header, isEmpty);
      expect(sections.single.lines, contains('nothing to commit'));
    });

    test('diffLineColor maps hunk/add/remove lines', () {
      expect(diffLineColor('@@ -1 +1 @@'), isNotNull);
      expect(diffLineColor('+new'), isNotNull);
      expect(diffLineColor('-old'), isNotNull);
      expect(diffLineColor(' context'), isNull);
      expect(diffLineColor('+++ b/a.dart'), isNull);
      expect(diffLineColor('--- a/a.dart'), isNull);
    });
  });

  group('G1+G2 service passthroughs', () {
    test('branches round-trip through the bridge', () async {
      final git = GitService();
      expect(await git.listBranches('/p'), ['main', 'dev']);
      expect(await git.currentBranch('/p'), 'main');
      await git.checkout('/p', 'dev');
      await git.createBranch('/p', 'feat');
      await git.deleteBranch('/p', 'feat');
      expect(calls[checkoutChannel]?.single, ['/p', 'dev']);
      expect(calls[createBranchChannel]?.single, ['/p', 'feat']);
      expect(calls[deleteBranchChannel]?.single, ['/p', 'feat']);
    });

    test('stash round-trip through the bridge', () async {
      final git = GitService();
      expect(await git.stashList('/p'), ['stash@{0}: WIP on main: demo']);
      await git.stashSave('/p', 'wip');
      await git.stashPop('/p', 0);
      await git.stashDrop('/p', 0);
      expect(calls[stashSaveChannel]?.single, ['/p', 'wip']);
      expect(calls[stashPopChannel]?.single, ['/p', 0]);
      expect(calls[stashDropChannel]?.single, ['/p', 0]);
    });

    test('per-file add sends a single path', () async {
      await GitService().add('/p', const ['a.dart']);
      expect(calls[addChannel]?.single, ['/p', ['a.dart']]);
    });
  });

  Widget harness(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  bool selectableContains(WidgetTester tester, String part) =>
      tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .any(
            (w) =>
                (w.data?.contains(part) ?? false) ||
                (w.textSpan?.toPlainText().contains(part) ?? false),
          );

  group('widgets', () {
    testWidgets('DiffView renders both file sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const DiffView(content: twoFileDiff, emptyLabel: '(empty diff)'),
        ),
      );
      await tester.pumpAndSettle();
      expect(selectableContains(tester, 'diff --git a/a.dart b/a.dart'), isTrue);
      expect(selectableContains(tester, 'diff --git a/b.dart b/b.dart'), isTrue);
      expect(selectableContains(tester, '-old'), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GitScreen shows per-file Stage and stash Pop', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(harness(const GitScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField).first, '/data/demo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // G0: per-file Stage action on the modified row.
      expect(find.byTooltip('Stage'), findsOneWidget);
      // G2: stash section with the mocked entry and a Pop action.
      expect(find.textContaining('stash@{0}'), findsOneWidget);
      expect(find.text('Pop'), findsOneWidget);

      // G0: staging a single file sends just that path.
      await tester.tap(find.byTooltip('Stage'));
      await tester.pumpAndSettle();
      expect(calls[addChannel]?.last, ['/data/demo', ['a.dart']]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Branches button opens picker and checks out', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(harness(const GitScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField).first, '/data/demo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Branches'));
      await tester.pumpAndSettle();

      expect(find.text('dev'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'dev'));
      await tester.pumpAndSettle();

      expect(calls[checkoutChannel]?.single, ['/data/demo', 'dev']);
      expect(tester.takeException(), isNull);
    });
  });
}
