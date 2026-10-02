import "dart:io";

import "package:flutter_test/flutter_test.dart";

import "package:nova/src/features/workspace/recovery_store.dart";
import "package:nova/src/features/workspace/save_coordinator.dart";

void main() {
  group("RecoveryStore", () {
    late Directory dir;
    late RecoveryStore store;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp("nova_recovery_test");
      store = RecoveryStore.testWithDir(dir);
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test("round-trips a draft", () async {
      await store.writeDraft("/proj/index.php", "<?php echo 1;");
      final draft = await store.readDraft("/proj/index.php");
      expect(draft, isNotNull);
      expect(draft!.path, "/proj/index.php");
      expect(draft.text, "<?php echo 1;");
    });

    test("missing draft reads null", () async {
      expect(await store.readDraft("/proj/nope.php"), isNull);
    });

    test("clearDraft removes it", () async {
      await store.writeDraft("/proj/a.php", "x");
      await store.clearDraft("/proj/a.php");
      expect(await store.readDraft("/proj/a.php"), isNull);
    });

    test("oversized drafts are skipped", () async {
      final big = "x" * (RecoveryStore.maxDraftBytes + 1);
      await store.writeDraft("/proj/big.php", big);
      expect(await store.readDraft("/proj/big.php"), isNull);
    });

    test("corrupt files read null", () async {
      final file = File(
        "${dir.path}/${RecoveryStore.fileNameFor("/proj/bad.php")}",
      );
      await file.writeAsString("not json{{{");
      expect(await store.readDraft("/proj/bad.php"), isNull);
    });

    test("file names are deterministic and bounded", () {
      expect(
        RecoveryStore.fileNameFor("/a.php"),
        RecoveryStore.fileNameFor("/a.php"),
      );
      expect(
        RecoveryStore.fileNameFor("/a.php"),
        isNot(RecoveryStore.fileNameFor("/b.php")),
      );
      final long = "/${"d" * 400}/file.php";
      expect(RecoveryStore.fileNameFor(long).length, lessThan(200));
    });
  });

  group("SaveGate", () {
    test("single save owns the slot and releases it", () {
      final gate = SaveGate();
      expect(gate.begin(), isTrue);
      expect(gate.end(), isFalse);
      expect(gate.isIdle, isTrue);
    });

    test("overlapping save coalesces then re-runs once", () {
      final gate = SaveGate();
      expect(gate.begin(), isTrue); // first save writes
      expect(gate.begin(), isFalse); // second save coalesced
      expect(gate.begin(), isFalse); // third save coalesced too
      expect(gate.end(), isTrue); // loop: write again (latest text)
      expect(gate.end(), isFalse); // done, single re-write covered all
      expect(gate.isIdle, isTrue);
    });
  });

  group("settleSave", () {
    test("clean only when nothing changed during the write", () {
      expect(
        settleSave(written: "a", current: "a"),
        SaveSettle.clean,
      );
      expect(
        settleSave(written: "a", current: "ab"),
        SaveSettle.stillDirty,
      );
    });
  });
}
