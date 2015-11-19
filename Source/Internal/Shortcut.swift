//
//  SCKShortcut.swift
//  ShortcutKit
//
//  Created by mrahmiao on 11/4/15.
//  Copyright © 2015 Code4Blues. All rights reserved.
//

import Cocoa
import Carbon

private let availableFlags: [(NSEventModifierFlags, Int)] = [
  (.ControlKeyMask, controlKey),
  (.ShiftKeyMask, shiftKey),
  (.AlternateKeyMask, optionKey),
  (.CommandKeyMask, cmdKey)
]

// The order of modifiers is important
private let modifierCharacters: [(modifier: NSEventModifierFlags, character: String)] = [
  (.ControlKeyMask, "⌃"),
  (.AlternateKeyMask, "⌥"),
  (.ShiftKeyMask, "⇧"),
  (.CommandKeyMask, "⌘")
]

private let acceptableModifierFlags: NSEventModifierFlags = [
  .ControlKeyMask, .AlternateKeyMask, .ShiftKeyMask, .CommandKeyMask
]

struct Shortcut {
  
  let controlIdentifier: String
  
  var carbonKeyCode: UInt32 {
    return UInt32(keyCode)
  }
  
  var carbonModifierFlags: UInt32 {
    
    var result: Int = 0
    for (flag, carbonFlag) in availableFlags {
      if modifierFlags.contains(flag) {
        result |= carbonFlag
      }
    }
    
    return UInt32(result)
  }
  
  var keyCode: Int
  var modifierFlags: NSEventModifierFlags
  
  var rawKeyCode: UInt16 {
    return UInt16(keyCode)
  }
  
  init(keycode: UInt16, modifierFlags flags: NSEventModifierFlags, control: HotkeyRegistrable) {
    self.keyCode = Int(keycode)
    self.modifierFlags = flags.intersect(acceptableModifierFlags)
    self.controlIdentifier = control.controlIdentifier
    
  }
  
  init(keyboardEvent event: NSEvent, control: HotkeyRegistrable) {
    self.init(keycode: event.keyCode, modifierFlags: event.modifierFlags, control: control)
  }
  
  init(keycode: UInt16, modifierFlags flags: NSEventModifierFlags, controlIdentifier identifier: String) {
    self.keyCode = Int(keycode)
    self.modifierFlags = flags.intersect(acceptableModifierFlags)
    self.controlIdentifier = identifier
  }
}

// MARK: - Equatable
extension Shortcut: Equatable { }

func ==(lhs: Shortcut, rhs: Shortcut) -> Bool {
  return lhs.keyCode == rhs.keyCode && lhs.modifierFlags == rhs.modifierFlags
}

// MARK: - Hashable
extension Shortcut: Hashable {
  var hashValue: Int {
    return description.hashValue
  }
}

// MARK: - CustomStringConvertible, CustomDebugStringConvertible
extension Shortcut: CustomStringConvertible, CustomDebugStringConvertible {
  var description: String {
    return "\(modifiersRepresentation)\(unicodeKeyCodeRepresentation)"
  }
  
  var debugDescription: String {
    return description
  }
}

// MARK: - Utilities
extension Shortcut {
  func isEqualToSystemShortcutWithKeycode(keycode: UInt32, modifierFlags modifiers: UInt32) -> Bool {
    return carbonKeyCode == keycode && carbonModifierFlags == modifiers
  }
  
  var modifierFlagsAcceptable: Bool {
    return modifierFlags.union(acceptableModifierFlags) == acceptableModifierFlags
  }
  
  var isFunctionKey: Bool {
    switch keyCode {
    case kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10, kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20:
      return true
    default:
      return false
    }
  }
  
  var isDeleteOrForwardDelete: Bool {
    if keyCode == kVK_Delete || keyCode == kVK_ForwardDelete {
      return true
    }
    
    return false
  }
  
  var isAvailableWithOptionKey: Bool {
    if keyCode == kVK_Space || keyCode == kVK_Escape {
      return true
    }
    
    return false
  }
  
  var isOnlyDeleteOrBackspace: Bool {
    if modifierFlags.isEmpty && (keyCode == kVK_Delete || keyCode == kVK_ForwardDelete) {
      return true
    }
    
    return false
  }
  
  var isOnlyEsc: Bool {
    if modifierFlags.isEmpty && keyCode == kVK_Escape {
      return true
    }
    
    return false
  }
  
  var unicodeKeyCodeRepresentation: String {
    if let unicode = unicodeKeyCode {
      return unicharToString(unicode)
    }
    
    return printableCharacter
  }
  
  var stringRepresentation: String {
    switch keyCode {
    case kVK_F1: return "F1"
    case kVK_F2: return "F2"
    case kVK_F3: return "F3"
    case kVK_F4: return "F4"
    case kVK_F5: return "F5"
    case kVK_F6: return "F6"
    case kVK_F7: return "F7"
    case kVK_F8: return "F8"
    case kVK_F9: return "F9"
    case kVK_F10: return "F10"
    case kVK_F11: return "F11"
    case kVK_F12: return "F12"
    case kVK_F13: return "F13"
    case kVK_F14: return "F14"
    case kVK_F15: return "F15"
    case kVK_F16: return "F16"
    case kVK_F17: return "F17"
    case kVK_F18: return "F18"
    case kVK_F19: return "F19"
    case kVK_F20: return "F20"
    case kVK_Space: return NSLocalizedString("SpaceCharacter", value: " ", comment: "Space Character")
    case kVK_Delete: return KeyCodeGlyph.DeleteLeft.toString()
    case kVK_ForwardDelete: return KeyCodeGlyph.DeleteRight.toString()
    case kVK_ANSI_KeypadClear: return KeyCodeGlyph.KeypadClear.toString()
    case kVK_LeftArrow: return KeyCodeGlyph.LeftArrow.toString()
    case kVK_RightArrow: return KeyCodeGlyph.RightArrow.toString()
    case kVK_UpArrow: return KeyCodeGlyph.UpArrow.toString()
    case kVK_DownArrow: return KeyCodeGlyph.DownArray.toString()
    case kVK_End: return KeyCodeGlyph.SoutheastArrow.toString()
    case kVK_Escape: return KeyCodeGlyph.Escape.toString()
    case kVK_PageDown: return KeyCodeGlyph.PageDown.toString()
    case kVK_PageUp: return KeyCodeGlyph.PageUp.toString()
    case kVK_Return: return KeyCodeGlyph.ReturnR2L.toString()
    case kVK_ANSI_KeypadEnter: return KeyCodeGlyph.Return.toString()
    case kVK_Tab: return KeyCodeGlyph.TabRight.toString()
    case kVK_Help: return "?"
    default:
      return printableCharacter
    }
  }
}

// MARK: - Helpers
private extension Shortcut {
  
  // This is only for special keycodes
  private var unicodeKeyCode: Int? {
    switch keyCode {
    case kVK_F1: return NSF1FunctionKey
    case kVK_F2: return NSF2FunctionKey
    case kVK_F3: return NSF3FunctionKey
    case kVK_F4: return NSF4FunctionKey
    case kVK_F5: return NSF5FunctionKey
    case kVK_F6: return NSF6FunctionKey
    case kVK_F7: return NSF7FunctionKey
    case kVK_F8: return NSF8FunctionKey
    case kVK_F9: return NSF9FunctionKey
    case kVK_F10: return NSF10FunctionKey
    case kVK_F11: return NSF11FunctionKey
    case kVK_F12: return NSF12FunctionKey
    case kVK_F13: return NSF13FunctionKey
    case kVK_F14: return NSF14FunctionKey
    case kVK_F15: return NSF15FunctionKey
    case kVK_F16: return NSF16FunctionKey
    case kVK_F17: return NSF17FunctionKey
    case kVK_F18: return NSF18FunctionKey
    case kVK_F19: return NSF19FunctionKey
    case kVK_F20: return NSF20FunctionKey
    case kVK_Space:
      // Equal to the Space character in menu item
      return 0x0020
    case kVK_Delete: return NSBackspaceCharacter
    case kVK_ForwardDelete: return NSDeleteCharacter
    case kVK_ANSI_KeypadClear: return NSClearLineFunctionKey
    case kVK_LeftArrow: return NSLeftArrowFunctionKey
    case kVK_RightArrow: return NSRightArrowFunctionKey
    case kVK_UpArrow: return NSUpArrowFunctionKey
    case kVK_DownArrow: return NSDownArrowFunctionKey
    case kVK_End: return NSEndFunctionKey
    case kVK_Escape:
      // Equal to the Escape character in menu item
      return 0x001B
    case kVK_PageDown: return NSPageDownFunctionKey
    case kVK_PageUp: return NSPageUpFunctionKey
    case kVK_Return: return NSCarriageReturnCharacter
    case kVK_ANSI_KeypadEnter: return NSEnterCharacter
    case kVK_Tab: return NSTabCharacter
    case kVK_Help: return NSHelpFunctionKey
    default:
      return nil
    }
  }
  
  private var printableCharacter: String {
    
    // Use ASCIICapableKeyboard to print ASCII characters
    let tisSource = TISCopyCurrentASCIICapableKeyboardInputSource().takeRetainedValue()
    
    let layoutData = unsafeBitCast(TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData), CFDataRef.self)
    let keyboardLayout = unsafeBitCast(CFDataGetBytePtr(layoutData), UnsafePointer<UCKeyboardLayout>.self)
    let chars = UnsafeMutablePointer<UniChar>.alloc(1)
    var actualLength = 0
    var deadKeyState: UInt32 = 0
    
    // modifierKeyState = ((EventRecord.modifiers) >> 8) & 0xFF
    if UCKeyTranslate(keyboardLayout, rawKeyCode, UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()), UInt32(kUCKeyTranslateNoDeadKeysBit), &deadKeyState, 4, &actualLength, chars) != noErr {
      return ""
    }
    
    return String(utf16CodeUnits: chars, count: actualLength).uppercaseString
  }
  
  var modifiersRepresentation: String {
    
    let result = modifierCharacters.reduce("") { (str, tuple) -> String in
      if modifierFlags.contains(tuple.modifier) {
        return str + tuple.character
      }
      
      return str
    }
    
    return result
  }
}

private func unicharToString(ch: Int) -> String {
  return String(format: "%C", ch)
}

/**
 Drawable unicode characters for keycodes that do not have appropriate constants
 in Carbon and Cocoa.
 */
private enum KeyCodeGlyph: Int {
  /// ⇤
  case TabLeft = 0x21E4
  /// ⇥
  case TabRight = 0x21E5
  /// ⌅
  case Return = 0x2305
  /// ↩
  case ReturnR2L = 0x21A9
  /// ⌫
  case DeleteLeft = 0x232B
  /// ⌦
  case DeleteRight = 0x2326
  /// ⌧
  case KeypadClear = 0x2327
  /// ←
  case LeftArrow = 0x2190
  /// ↑
  case UpArrow
  /// →
  case RightArrow
  /// ↓
  case DownArray = 0x2193
  /// ⇟
  case PageUp = 0x21DE
  /// ⇞
  case PageDown = 0x21DF
  /// ↖
  case NorthwestArrow = 0x2196
  /// ↘
  case SoutheastArrow = 0x2198
  /// ⎋
  case Escape = 0x238B
  /// ' '
  case Space = 0x0020
  
  func toString() -> String {
    return unicharToString(rawValue)
  }
}
