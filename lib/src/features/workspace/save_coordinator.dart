/// Serializes overlapping editor saves so an older write can never finish
/// after (and clobber the state of) a newer one.
///
/// The bug it prevents: manual Save tapped while an auto-save write is in
/// flight (or double-tapped Save). Both captured different snapshots; if the
/// older write finished last, the tab was marked clean with stale text while
/// the disk held older content than the editor — "save brings old values".
///
/// Protocol: [begin] returns true when the caller owns the write slot and
/// must perform exactly one write; false means "coalesced, someone else is
/// writing — your snapshot will be picked up". After the write, [end]
/// returns true when another save was requested meanwhile and the caller
/// must loop and write again (the fresh text, not a stale capture).
class SaveGate {
  bool _writing = false;
  bool _requested = false;

  /// Enter the gate. True: perform one write now. False: coalesced.
  bool begin() {
    if (_writing) {
      _requested = true;
      return false;
    }
    _writing = true;
    return true;
  }

  /// Leave the gate after a write. True: loop and write again.
  bool end() {
    if (_requested) {
      _requested = false;
      return true;
    }
    _writing = false;
    return false;
  }

  /// Idle and untouched (for tests).
  bool get isIdle => !_writing && !_requested;
}

/// Post-write dirty decision. The tab may only be marked clean when the
/// editor still holds exactly what was written; keystrokes that landed
/// during the async write keep the tab dirty (and must re-arm auto-save).
enum SaveSettle { clean, stillDirty }

SaveSettle settleSave({
  required String written,
  required String current,
}) =>
    current == written ? SaveSettle.clean : SaveSettle.stillDirty;
