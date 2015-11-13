//
//  HotkeyManager.swift
//  ShortcutKit
//
//  Created by mrahmiao on 11/10/15.
//  Copyright © 2015 Code4Blues. All rights reserved.
//

import Foundation
import Carbon

public typealias HotkeyHandler = Void -> Void
typealias ShortcutUpdater = (Shortcut?, Shortcut?) -> Void
private var hotkeyCarbonID: UInt32 = 0
private let HotkeySignature: OSType = OSTypeFromString("SCKF")

private let HotkeyPressedEventKind = UInt32(kEventHotKeyPressed)
private let KeyboardEventClass = OSType(kEventClassKeyboard)

protocol HotkeyRegistrable {
  var controlIdentifier: String! { get set }
}

private class Hotkey {
  var shortcut: Shortcut?
  let hotkeyID: EventHotKeyID
  var hotkeyRef: EventHotKeyRef
  let handler: HotkeyHandler
  
  var activated: Bool {
    return self.hotkeyRef != EventHotKeyRef()
  }
  
  init(handler: HotkeyHandler) {
    self.handler = handler
    self.hotkeyID = EventHotKeyID(signature: HotkeySignature, id: ++hotkeyCarbonID)
    self.hotkeyRef = EventHotKeyRef()
  }
}


class HotkeyManager {
  static let sharedManager: HotkeyManager = HotkeyManager()
  
  private var hotkeys: [String: Hotkey] = [:]
  
  private var paused: Bool = false
  
  var eventHandlerRef = EventHandlerRef()
  
  private init() {
    
    if installDispatcherEventHandler() != noErr {
      fatalError("Uanble to install hot key event handler.")
    }
  }
  
  deinit {
    RemoveEventHandler(eventHandlerRef)
  }
  
}

extension HotkeyManager {
  /**
   Bind the hotkey handler with your recorder control. This method is invoked in the
   recorder control.
   
   - Parameters:
     - control
     - handler
  */
  func bindControl(control: HotkeyRegistrable, toHandler handler: HotkeyHandler) {
    hotkeys[control.controlIdentifier] = Hotkey(handler: handler)
  }
  
  func unbindControl(control: HotkeyRegistrable) {
    removeShortcutOfControl(control)
    hotkeys[control.controlIdentifier] = nil
  }
  
  func updateShortcut(shortcut: Shortcut?, ofControl control: HotkeyRegistrable) {
    
    // Only update the shortcut of existing hotkey
    guard let hotkey = hotkeys[control.controlIdentifier] else {
      return
    }
    
    hotkey.shortcut = shortcut
  }
  
  func removeShortcutOfControl(control: HotkeyRegistrable) {
    unregisterHotKeyWithControlIdentifier(control.controlIdentifier)
  }
  
  // This should only be call
  func activateShortcut(shortcut: Shortcut, ofControl control: HotkeyRegistrable) {
    guard let hotkey = hotkeys[control.controlIdentifier] else {
      return
    }
    
    if hotkey.activated {
      return
    }
    
    hotkey.shortcut = shortcut
    registerHotKey(hotkey, withIdentifier: control.controlIdentifier)
  }
  
  // Unregister hotkeys and remove event handler
  func pause() {
    if paused { return }
    
    for (_, hotkey) in hotkeys {
      UnregisterEventHotKey(hotkey.hotkeyRef)
      hotkey.hotkeyRef = EventHotKeyRef()
    }
    
    paused = true
  }
  
  // Resume the hotkeys and install event handler
  func resume() {
    if !paused { return }
    
    for (identifier, hotkey) in hotkeys where hotkey.shortcut != nil {
      registerHotKey(hotkey, withIdentifier: identifier)
    }
    
    paused = false
  }
  
  func isShortcutRegistered(shortcut: Shortcut) -> Bool {
    for (identifier, hotkey) in hotkeys where identifier != shortcut.controlIdentifier {
      if hotkey.shortcut == shortcut {
        return true
      }
    }
    
    return false
  }
  
  func clearRegisteredShortcuts() {
    for (identifier, _) in hotkeys {
      unregisterHotKeyWithControlIdentifier(identifier)
    }
    
    hotkeys.removeAll()
  }
  
}

// MARK:- Helpers
private extension HotkeyManager {
  func installDispatcherEventHandler() -> OSStatus {
    var eventSpec = EventTypeSpec(eventClass: KeyboardEventClass, eventKind: HotkeyPressedEventKind)
    return InstallEventHandler(GetEventDispatcherTarget(), { (inHandler, event, context) -> OSStatus in
    return HotkeyManager.sharedManager.dispatchEvent(event)
    }, 1, &eventSpec, nil, &eventHandlerRef)
  }
  
  func registerHotKey(hotkey: Hotkey, withIdentifier identifier: String) -> Bool {
    
    guard let keycode = hotkey.shortcut?.carbonKeyCode, let modifiers = hotkey.shortcut?.carbonModifierFlags else {
      NSLog("Can not register a hotkey without key combination.")
      return false
    }
    
    if RegisterEventHotKey(keycode, modifiers, hotkey.hotkeyID, GetEventDispatcherTarget(), 0, &hotkey.hotkeyRef) != noErr {
      return false
    }
    
    hotkeys[identifier] = hotkey
    return true
  }
  
  func unregisterHotKeyWithControlIdentifier(identifier: String) {
    if let existingHotkey = hotkeys[identifier] {
      UnregisterEventHotKey(existingHotkey.hotkeyRef)
      existingHotkey.shortcut = nil
      existingHotkey.hotkeyRef = EventHotKeyRef()
    }
  }
  
  func dispatchEvent(event: EventRef) -> OSStatus {
    if GetEventClass(event) != KeyboardEventClass {
      return OSStatus(eventClassIncorrectErr)
    }
    
    // Grab ID of pressed hotkey
    var hotkeyID = EventHotKeyID()
    if GetEventParameter(event, UInt32(kEventParamDirectObject), UInt32(typeEventHotKeyID), nil, sizeof(EventHotKeyID), nil, &hotkeyID) != noErr {
      return OSStatus(eventParameterNotFoundErr)
    }
    
    // Find matching hotkey handler
    for hotkey in hotkeys.values {
      if hotkey.hotkeyID != hotkeyID {
        continue
      }
      
      NSOperationQueue.mainQueue().addOperationWithBlock(hotkey.handler)
      return noErr
    }
    
    return OSStatus(eventNotHandledErr)
  }
}

// See http://stackoverflow.com/questions/31320243/swift-equivalent-to-objective-c-fourcharcode-single-quote-literals-e-g-text
private func OSTypeFromString(string : String) -> UInt32 {
  var result : UInt32 = 0
  if let data = string.dataUsingEncoding(NSMacOSRomanStringEncoding) {
    let bytes = UnsafePointer<UInt8>(data.bytes)
    for i in 0..<data.length {
      result = result << 8 + UInt32(bytes[i])
    }
  }
  return result
}

public func hotkeyEventHandler(handler: EventHandlerCallRef, inEvent event: EventRef, context: UnsafeMutablePointer<Void>) -> OSStatus {
  return HotkeyManager.sharedManager.dispatchEvent(event)
}

extension EventHotKeyID: Equatable { }

public func ==(lhs: EventHotKeyID, rhs: EventHotKeyID) -> Bool {
  return lhs.signature == rhs.signature && lhs.id == rhs.id
}