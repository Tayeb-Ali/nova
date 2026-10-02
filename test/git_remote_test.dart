import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/l10n/generated/app_localizations.dart';
import 'package:nova/src/core/bridge/generated/ide_api.g.dart' as bridge;
import 'package:nova/src/core/services/git_service.dart';
import 'package:nova/src/features/git/git_screen.dart';

/// Phase 1 (SSH-first remotes): clone/fetch/pull/push + SSH key pair.
/// All native calls are mocked at the Pigeon channel layer via
/// [TestDefaultBinaryMessenger]; no device needed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const statusChannel = 'dev.flutter.pigeon.codeide.GitApi.status';
  const cloneChannel = 'dev.flutter.pigeon.codeide.GitApi.clone';
  const fetchChannel = 'dev.flutter.pigeon.codeide.GitApi.fetch';
  const pullChannel = 'dev.flutter.pigeon.codeide.GitApi.pull';
  const pushChannel = 'dev.flutter.pigeon.codeide.GitApi.push';
  const generateSshKeyChannel =
      'dev.flutter.pigeon.codeide.GitApi.generateSshKey';
  const getSshPublicKeyChannel =
      'dev.flutter.pigeon.codeide.GitApi.getSshPublicKey';

  const channels = [
    statusChannel,
    cloneChannel,
    fetchChannel,
    pullChannel,
    pushChannel,
    generateSshKeyChannel,
    getSshPublicKeyChannel,
  ];

  final Map<String, List<List<Object?>>> calls = {};
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  ByteData? reply(Object? value) =>
      bridge.GitApi.pigeonChannelCodec.encodeMessage(<Object?>[value]);

  void record(String channel, ByteData? message) {
    final Object? decoded = message == null
        ? null
        : const StandardMessageCodec().decodeMessage(message);
    // Zero-arg methods send no payload; record an empty arg list.
    final List<Object?> args = decoded is List<Object?> ? decoded.toList() : [];
    calls.putIfAbsent(channel, () => []).add(args);
  }

  void mock(String channel, Object? Function() answer) {
    messenger.setMockMessageHandler(channel, (ByteData? message) async {
      record(channel, message);
      return reply(answer());
    });
  }

  setUp(() {
    calls.clear();
    mock(statusChannel, () => bridge.GitStatus(
          branch: 'main',
          modified: const [],
          added: const [],
          deleted: const [],
          untracked: const [],
        ));
    mock(cloneChannel, () => null);
    mock(fetchChannel, () => null);
    mock(pullChannel, () => null);
    mock(pushChannel, () => null);
    mock(generateSshKeyChannel, () => 'ssh-ed25519 AAAAgenerated');
    mock(getSshPublicKeyChannel, () => 'ssh-ed25519 AAAAexisting');
  });

  tearDown(() {
    for (final channel in channels) {
      messenger.setMockMessageHandler(channel, null);
    }
  });

  group('remote service round-trip', () {
    test('clone/fetch/pull/push send path args', () async {
      final git = GitService();
      await git.clone('git@host:user/repo.git', '/data/clone');
      await git.fetch('/p');
      await git.pull('/p');
      await git.push('/p');
      expect(calls[cloneChannel]?.single, [
        'git@host:user/repo.git',
        '/data/clone',
      ]);
      expect(calls[fetchChannel]?.single, ['/p']);
      expect(calls[pullChannel]?.single, ['/p']);
      expect(calls[pushChannel]?.single, ['/p']);
    });

    test('ssh key pair round-trips', () async {
      final git = GitService();
      expect(await git.generateSshKey(), 'ssh-ed25519 AAAAgenerated');
      expect(await git.getSshPublicKey(), 'ssh-ed25519 AAAAexisting');
    });
  });

  Widget harness(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  group('widgets', () {
    testWidgets('Remote section shows actions, key, and pushes', (
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

      // Remote section is collapsed by default; expand it first.
      await tester.tap(find.text('Remote (SSH)'));
      await tester.pumpAndSettle();

      // Remote section: fetch/pull/push buttons + clone + stored key.
      expect(find.widgetWithText(OutlinedButton, 'Fetch'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Pull'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Push'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Clone'), findsOneWidget);
      expect(find.textContaining('ssh-ed25519 AAAAexisting'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Push'));
      await tester.pumpAndSettle();
      expect(calls[pushChannel]?.single, ['/data/demo']);
      expect(tester.takeException(), isNull);
    });
  });
}
