//
//  SCKRecorderControl.swift
//  ShortcutKit
//
//  Created by mrahmiao on 11/3/15.
//  Copyright © 2015 Code4Blues. All rights reserved.
//

import Cocoa

@objc public protocol SCKRecorderControlDeletgate {
  /**
   This method is called if validation failed, including validations of ShortcutKit and
   validation you provided in delegate method `recorderControl:validateShortcutWithKeyCode:modfierFlags:`.
   
   The error can be used in an alert dialog.
   
   - Parameters:
     - control The recorder control that sent the message
     - error The error information about the validation.
  */
  optional func recorderControl(control: SCKRecorderControl, validationFailedWithError error: NSError)
  optional func recorderControl(control: SCKRecorderControl, didChangeShortcutWithKeyCode keycode: UInt16, modifierFlags modifiers: NSEventModifierFlags)
  optional func recorderControl(control: SCKRecorderControl, didRemoveShortcutWithKeyCode keycode: UInt16, modifierFlags modifiers: NSEventModifierFlags)
  optional func recorderControl(control: SCKRecorderControl, validateShortcutWithKeyCode keycode: UInt16, modifierFlags modifiers: NSEventModifierFlags) -> String?
}

@IBDesignable
public class SCKRecorderControl: NSControl, HotkeyRegistrable {
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  public override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    
    enabled = true
    wantsLayer = true
    layer?.cornerRadius = 4
    
    if let shortcut = associatedShortcut {
      HotkeyManager.sharedManager.activateShortcut(shortcut, ofControl: self)
    }
  }
  
  public override var enabled: Bool {
    didSet {
      needsDisplay = true
    }
  }
  
  public weak var delegate: SCKRecorderControlDeletgate?
  
  /// Preferences used to control the validation behavior.
  public var preferences: SCKPreferences = SCKPreferences()
  
  /// Used to identify your control in hotkey registration and state restoration. It will be set as
  /// the key of the defaults.
  public internal(set) var controlIdentifier: String! {
    didSet {
      let defaults = NSUserDefaults.standardUserDefaults()
      
      if let shortcutValue = defaults.objectForKey(controlIdentifier) as? [String: AnyObject],
        let keyCode = shortcutValue[UserDefaultsKey.KeyCode.rawValue] as? Int,
        let rawModifierFlags = shortcutValue[UserDefaultsKey.ModifierFlags.rawValue] as? UInt {
          let modifierFlags = NSEventModifierFlags(rawValue: rawModifierFlags)
          associatedShortcut = Shortcut(keycode: UInt16(keyCode), modifierFlags: modifierFlags, control: self)
      }
    }
  }
  
  /// A Shortcut associated with recorder control, which is used to register hotkey.
  private(set) var associatedShortcut: Shortcut? {
    didSet {
      typingShortcut = nil
      
      // New shortcut is not nil
      if let shortcut = associatedShortcut {
        
        // Register new shortcut or update existing shortcut
        HotkeyManager.sharedManager.updateShortcut(shortcut, ofControl: self)
        
        shortcutValue = [
          .KeyCode: shortcut.keyCode,
          .ModifierFlags: shortcut.modifierFlags.rawValue
        ]
        
        delegate?.recorderControl?(self, didChangeShortcutWithKeyCode: shortcut.rawKeyCode, modifierFlags: shortcut.modifierFlags)
      } else {
        
        // New shortcut is nil, and old shortcut is not nil
        guard let oldShortcut = oldValue else {
          return
        }
        
        // Removing an existing shortcut
        HotkeyManager.sharedManager.updateShortcut(nil, ofControl: self)
        shortcutValue = nil
        delegate?.recorderControl?(self, didRemoveShortcutWithKeyCode: oldShortcut.rawKeyCode, modifierFlags: oldShortcut.modifierFlags)
      }
    }
  }
  
  lazy var validator: ShortcutValidator = ShortcutValidator(preferences: self.preferences)
  
  // State of shortcut recording
  @IBInspectable private var recording: Bool = false {
    didSet {
      if recording {
        
        HotkeyManager.sharedManager.pause()
        window?.makeFirstResponder(self)
      } else {
        if NSApp.mainWindow?.firstResponder == self {
          window?.makeFirstResponder(nil)
        }
        
        HotkeyManager.sharedManager.resume()
      }
      
      needsDisplay = true
    }
  }
  
  private var shortcutExists: Bool {
    return associatedShortcut != nil
  }
  
  // Text displayed on the control
  // TODO: Localization
  private var controlText: String {
    if recording {
      
      if let typingShortcut = typingShortcut {
        return typingShortcut.description
      }
      
      return associatedShortcut?.description ?? "Type Shortcut"
    }
    
    return associatedShortcut?.description ?? "Click to Record Shortcut"
  }
  
  private var shortcutValue: [UserDefaultsKey: AnyObject]? {
    didSet {
      if controlIdentifier == nil {
        fatalError("controlIdentifier is a must set property.")
      }
      
      let defaults = NSUserDefaults.standardUserDefaults()
      
      if let shortcutValue = shortcutValue {
        defaults.setDictionary(shortcutValue, forKey: controlIdentifier)
      } else {
        defaults.removeObjectForKey(controlIdentifier)
      }
      
      defaults.synchronize()
    }
  }
  
  private var typingShortcut: Shortcut? {
    didSet {
      needsDisplay = true
    }
  }
  
  private var leftButtonTip: String {
    return "Cancel shortcut recording"
  }
  
  private var rightButtonTip: String {
    if shortcutExists {
      return "Delete existing shortcut"
    }
    
    return "Cancel shortcut recording"
  }
  
  private lazy var rightButtonRect: CGRect = CGRect(x: 162, y: 4, width: 13, height: 13)
  private lazy var leftButtonRect: CGRect = self.rightButtonRect.offsetBy(dx: -15, dy: 0)
  
}

// MARK: - Shortcut Binding API
public extension SCKRecorderControl {
  func bindIdentifier(identifier: String, andShortcutHandler handler: (SCKRecorderControl) -> Void) {
    controlIdentifier = identifier    
    HotkeyManager.sharedManager.bindControl(self, toHandler: { handler(self) })
  }
  
  func unbindShortcutRecorder() {
    if controlIdentifier == nil {
      return
    }
    
    HotkeyManager.sharedManager.unbindControl(self)
  }
}

// MARK: - Drawing
extension SCKRecorderControl {
  public override func drawRect(dirtyRect: NSRect) {
    SCKStyleKit.drawRecorderControl(recording: recording, shortcutExists: shortcutExists, recorderText: controlText)
  }
  
  public override func drawFocusRingMask() {
    NSBezierPath.fillRect(bounds)
  }
  
  public override var focusRingMaskBounds: NSRect {
    // TODO: Add Corner Radius
    return bounds
  }
}

// MARK: - Events
extension SCKRecorderControl {
  public override func mouseDown(theEvent: NSEvent) {
    
    // Do not process any event if disabled.
    if !enabled {
      super.mouseDown(theEvent)
      return
    }
    
    if recording {
      
      // While recodring, cancel recording if clicked in the operation rect
      // If clicked in the shortcut rect, do nothing
      
      // Two buttons appear while shortcut exists
      if shortcutExists {
        if locationInLeftButtonRect(theEvent.locationInWindow) {
          
          // Clicked on the cancel button
          recording = false
        } else if locationInRightButtonRect(theEvent.locationInWindow) {
          
          // Clicked on the delete button
          associatedShortcut = nil
          recording = false
        } else {
          
          // Do nothing while clicked at other places
        }
      } else {
        
        // Only cancel button appears while no shortcut exists
        if locationInRightButtonRect(theEvent.locationInWindow) {
          recording = false
        }
      }
      
      return
    }
    
    // Record a new shortcut
    recording = true
  }
  
  public override func performKeyEquivalent(theEvent: NSEvent) -> Bool {
    
    if self.window?.firstResponder != self || !enabled ||  !recording {
      return false
    }
    
    let shortcut = Shortcut(keyboardEvent: theEvent, control: self)
    
    // Check if is Esc
    if preferences.allowsEscToCancelRecording && shortcut.isOnlyEsc {
      recording = false
      return true
    }
    
    // Check if is Delete or ForwardDelete
    if preferences.allowsDeleteToClearShortcutAndCancelRecording && shortcut.isOnlyDeleteOrBackspace {
      associatedShortcut = nil
      recording = false
      return true
    }
    
    // Validate the shortcut using user defined rules.
    if let failureReason = delegate?.recorderControl?(self, validateShortcutWithKeyCode: shortcut.rawKeyCode, modifierFlags: shortcut.modifierFlags) {
      
      delegate?.recorderControl?(self, validationFailedWithError: ShortcutError.errorWithShortcut(shortcut, failureReason: failureReason))
      recording = false
      return true
    }
    
    // Shortcut validation includes keycode validation, modifier validation and shortcut existence validation.
    do {
      try validator.validateShortcut(shortcut)
    } catch let shortcutError as ShortcutError {
      NSBeep()
      typingShortcut = nil
      
      if preferences.cancelRecordingIfShortcutInvalid {
        recording = false
      }
      
      delegate?.recorderControl?(self, validationFailedWithError: shortcutError.errorWithShortcut(shortcut))

      return true
    } catch {
      fatalError("Error thrown \"\(error)\" is not supported yet.")
    }
    
    self.associatedShortcut = shortcut
    recording = false
    return true
  }
  
  public override func flagsChanged(theEvent: NSEvent) {
    if !recording {
      super.flagsChanged(theEvent)
      return
    }
    
    let shortcut = Shortcut(keyboardEvent: theEvent, control: self)
    
    // TODO: Modifier Validation
    if shortcut.modifierFlags.isEmpty {
      typingShortcut = nil
      return
    }
    
    typingShortcut = shortcut
    
  }
}

// MARK: - Responder Chain
public extension SCKRecorderControl {
  override func becomeFirstResponder() -> Bool {
    let becameFirstResponder = super.becomeFirstResponder()
    
    if becameFirstResponder {
      recording = true
    }
    
    return becameFirstResponder
  }
  
  override func resignFirstResponder() -> Bool {
    let resignedFirstResponder = super.resignFirstResponder()
    
    if resignedFirstResponder && recording {
      recording = false
    }
    
    return resignedFirstResponder
  }
  
}

private extension SCKRecorderControl {
  enum UserDefaultsKey: String, Hashable {
    case Identifier
    case KeyCode
    case ModifierFlags
    
    var hashValue: Int {
      return rawValue.hashValue
    }
  }
  
  // MARK: - Buttons Detecting
  func locationInLeftButtonRect(location: CGPoint) -> Bool {
    
    assert(recording == true, "Detecting is only available at recording")
    return leftButtonRect.contains(convertPoint(location, fromView: nil))
  }
  
  func locationInRightButtonRect(location: CGPoint) -> Bool {
    
    assert(recording == true, "Detecting is only available at recording")
    return rightButtonRect.contains(convertPoint(location, fromView: nil))
  }
}

// MARK: - NSUserDefaults Convenience Methods
private extension NSUserDefaults {
  func setObject(object: AnyObject?, forKey key: SCKRecorderControl.UserDefaultsKey) {
    setObject(object, forKey: key.rawValue)
  }
  
  func setDictionary(dict: [SCKRecorderControl.UserDefaultsKey: AnyObject], forKey key: String) {
    var object = [String: AnyObject]()
    
    for (key, value) in dict {
      object[key.rawValue] = value
    }
    
    setObject(object, forKey: key)
  }
  
  func objectForKey(key: SCKRecorderControl.UserDefaultsKey) -> AnyObject? {
    return objectForKey(key.rawValue)
  }
  
  func stringForKey(key: SCKRecorderControl.UserDefaultsKey) -> String? {
    return stringForKey(key.rawValue)
  }
  
  func removeObjectForKey(key: SCKRecorderControl.UserDefaultsKey) {
    removeObjectForKey(key.rawValue)
  }


}