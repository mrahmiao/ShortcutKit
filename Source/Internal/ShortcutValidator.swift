//
//  ShortcutValidator.swift
//  ShortcutKit
//
//  Created by mrahmiao on 11/6/15.
//  Copyright © 2015 Code4Blues. All rights reserved.
//

import Foundation
import Carbon

class ShortcutValidator {
  
  let preferences: SCKPreferences
  
  init(preferences: SCKPreferences) {
    self.preferences = preferences
  }
  
  func validateShortcut(shortcut: Shortcut) throws {
    
    if !isShortcutValid(shortcut) {
      throw ShortcutError.Invalid
    }
    
    if isShortcutExistInApp(shortcut) {
      throw ShortcutError.ExistsInApp
    }
    
    if isShortcutTakenBySystem(shortcut) {
      throw ShortcutError.TakenBySystem
    }
    
    if let menuItem = conflictMenuItemForShortcut(shortcut) {
      throw ShortcutError.ExistsInMenu(menuItem)
    }
  }
}

// MARK: - Helpers
private extension ShortcutValidator {
  func isShortcutValid(shortcut: Shortcut) -> Bool {
    
    // Allows key combinations with arbitrary function key
    if shortcut.isFunctionKey {
      return true
    }
    
    // In other cases, modifiers are required
    if shortcut.modifierFlags.isEmpty {
      return false
    }
    
    // Allows key combinations with Command key or/and Control, Shift key
    let modifiersWithAritraryKey: NSEventModifierFlags = [.CommandKeyMask, .ControlKeyMask, .ShiftKeyMask]
    if modifiersWithAritraryKey.contains(shortcut.modifierFlags.intersect(modifiersWithAritraryKey)) {
      return true
    }
    
    // Key combinations with option key only available in selected cases
    if shortcut.modifierFlags.contains(.AlternateKeyMask) {
      
      if preferences.allowsArbitaryKeysWithOptionKey {
        return true
      }
      
      if shortcut.isAvailableWithOptionKey {
        return true
      }
      
      return false
    }
    
    return false
  }
  
  func isShortcutExistInApp(shortcut: Shortcut) -> Bool {
    return HotkeyManager.sharedManager.isShortcutRegistered(shortcut)
  }

  func isShortcutTakenBySystem(shortcut: Shortcut) -> Bool {
    var unmanagedGlobalHotkeys: Unmanaged<CFArray>? = nil
    if CopySymbolicHotKeys(&unmanagedGlobalHotkeys) != noErr {
      fatalError("Unable to get system-wide hotkeys")
    }
    
    guard let globalHotkeys = unmanagedGlobalHotkeys?.takeRetainedValue() else {
      return false
    }
    
    for (var i: CFIndex = 0, count = CFArrayGetCount(globalHotkeys); i < count; i++) {
      guard let hotKeyInfo: NSDictionary = unsafeBitCast(CFArrayGetValueAtIndex(globalHotkeys, i), NSDictionary.self),
        let enabled = (hotKeyInfo[kHISymbolicHotKeyEnabled] as? NSNumber)?.boolValue,
      let keycode = (hotKeyInfo[kHISymbolicHotKeyCode] as? NSNumber)?.unsignedIntValue,
      let modifiers = (hotKeyInfo[kHISymbolicHotKeyModifiers] as? NSNumber)?.unsignedIntValue else {
        continue
      }
      
      if enabled && shortcut.isEqualToSystemShortcutWithKeycode(keycode, modifierFlags: modifiers) {
        return true
      }
    }
    
    return false
  }
  
  func conflictMenuItemForShortcut(shortcut: Shortcut) -> NSMenuItem? {
    
    func findConflictMenuItemInMenu(menu: NSMenu) -> NSMenuItem? {
      for menuItem in menu.itemArray {
        if let submenu = menuItem.submenu, let menuItem = findConflictMenuItemInMenu(submenu) {
          return menuItem
        }
        
        let keyEquivalent = menuItem.keyEquivalent.uppercaseString
        let modifierFlags = NSEventModifierFlags(rawValue: UInt(menuItem.keyEquivalentModifierMask))
        
        if keyEquivalent == "" {
          continue
        }
        
        if keyEquivalent == shortcut.unicodeKeyCodeRepresentation && modifierFlags == shortcut.modifierFlags {
          return menuItem
        }
      }
      
      return nil
    }
    
    guard let menu = NSApp.mainMenu else {
      return nil
    }
  
    return findConflictMenuItemInMenu(menu)
  }
}