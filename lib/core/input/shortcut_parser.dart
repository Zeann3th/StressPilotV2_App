import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ShortcutParser {
  static final Map<String, LogicalKeyboardKey> _keyMap = {
    'A': LogicalKeyboardKey.keyA,
    'B': LogicalKeyboardKey.keyB,
    'C': LogicalKeyboardKey.keyC,
    'D': LogicalKeyboardKey.keyD,
    'E': LogicalKeyboardKey.keyE,
    'F': LogicalKeyboardKey.keyF,
    'G': LogicalKeyboardKey.keyG,
    'H': LogicalKeyboardKey.keyH,
    'I': LogicalKeyboardKey.keyI,
    'J': LogicalKeyboardKey.keyJ,
    'K': LogicalKeyboardKey.keyK,
    'L': LogicalKeyboardKey.keyL,
    'M': LogicalKeyboardKey.keyM,
    'N': LogicalKeyboardKey.keyN,
    'O': LogicalKeyboardKey.keyO,
    'P': LogicalKeyboardKey.keyP,
    'Q': LogicalKeyboardKey.keyQ,
    'R': LogicalKeyboardKey.keyR,
    'S': LogicalKeyboardKey.keyS,
    'T': LogicalKeyboardKey.keyT,
    'U': LogicalKeyboardKey.keyU,
    'V': LogicalKeyboardKey.keyV,
    'W': LogicalKeyboardKey.keyW,
    'X': LogicalKeyboardKey.keyX,
    'Y': LogicalKeyboardKey.keyY,
    'Z': LogicalKeyboardKey.keyZ,
    '0': LogicalKeyboardKey.digit0,
    '1': LogicalKeyboardKey.digit1,
    '2': LogicalKeyboardKey.digit2,
    '3': LogicalKeyboardKey.digit3,
    '4': LogicalKeyboardKey.digit4,
    '5': LogicalKeyboardKey.digit5,
    '6': LogicalKeyboardKey.digit6,
    '7': LogicalKeyboardKey.digit7,
    '8': LogicalKeyboardKey.digit8,
    '9': LogicalKeyboardKey.digit9,
    'F1': LogicalKeyboardKey.f1,
    'F2': LogicalKeyboardKey.f2,
    'F3': LogicalKeyboardKey.f3,
    'F4': LogicalKeyboardKey.f4,
    'F5': LogicalKeyboardKey.f5,
    'F6': LogicalKeyboardKey.f6,
    'F7': LogicalKeyboardKey.f7,
    'F8': LogicalKeyboardKey.f8,
    'F9': LogicalKeyboardKey.f9,
    'F10': LogicalKeyboardKey.f10,
    'F11': LogicalKeyboardKey.f11,
    'F12': LogicalKeyboardKey.f12,
    'Escape': LogicalKeyboardKey.escape,
    'Delete': LogicalKeyboardKey.delete,
    'Enter': LogicalKeyboardKey.enter,
    'Space': LogicalKeyboardKey.space,
    'Tab': LogicalKeyboardKey.tab,
    'Backspace': LogicalKeyboardKey.backspace,
    'ArrowUp': LogicalKeyboardKey.arrowUp,
    'ArrowDown': LogicalKeyboardKey.arrowDown,
    'ArrowLeft': LogicalKeyboardKey.arrowLeft,
    'ArrowRight': LogicalKeyboardKey.arrowRight,
    'Comma': LogicalKeyboardKey.comma,
    'Period': LogicalKeyboardKey.period,
    'Slash': LogicalKeyboardKey.slash,
    'Backslash': LogicalKeyboardKey.backslash,
    'Semicolon': LogicalKeyboardKey.semicolon,
    'Quote': LogicalKeyboardKey.quote,
    'BracketLeft': LogicalKeyboardKey.bracketLeft,
    'BracketRight': LogicalKeyboardKey.bracketRight,
    ',': LogicalKeyboardKey.comma,
    '.': LogicalKeyboardKey.period,
  };

  static SingleActivator? parseActivator(String shortcut) {
    if (shortcut.isEmpty) return null;
    final parts = shortcut.split('+');
    final keyLabel = parts.last;
    final logicalKey = parseKey(keyLabel);
    if (logicalKey == null) return null;

    return SingleActivator(
      logicalKey,
      control: parts.contains('Control'),
      shift: parts.contains('Shift'),
      alt: parts.contains('Alt'),
      meta: parts.contains('Meta'),
    );
  }

  static LogicalKeyboardKey? parseKey(String label) {

    return _keyMap[label] ?? _keyMap[label.toUpperCase()];
  }

  static bool isMatch(KeyEvent event, String shortcut) {
    final parts = shortcut.split('+');
    final keyLabel = parts.last;

    final logicalKey = parseKey(keyLabel);
    if (logicalKey == null) return false;

    if (event.logicalKey != logicalKey) return false;

    final hasControl = parts.contains('Control');
    final hasShift = parts.contains('Shift');
    final hasAlt = parts.contains('Alt');
    final hasMeta = parts.contains('Meta');

    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;
    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;

    return hasControl == isControlPressed &&
           hasShift == isShiftPressed &&
           hasAlt == isAltPressed &&
           hasMeta == isMetaPressed;
  }
}
