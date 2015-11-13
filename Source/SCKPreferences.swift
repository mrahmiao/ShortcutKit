//
//  SCKPreferences.swift
//  ShortcutKit
//
//  Created by mrahmiao on 11/8/15.
//  Copyright © 2015 Code4Blues. All rights reserved.
//

import Foundation

/**
The style of recorder control.
*/
public enum SCKRecorderControlStyle {
  /// A control with size of (180, 21).
  case Default
  
  /// Use this style if you embedded the control in a table view cell.
  case Inline
}

/**
Preferences used to control the behavior of recorder control and validation.
*/
public struct SCKPreferences {
  
  /**
    Determines whether arbitrary keys can be used as a shortcut with *Option* key.
    And the value defaults to `false`.
   
    If set, arbitrary keys can be used with *Option*. Otherwise, only *Space* and *Esc* can be used.
   */
  public var allowsArbitaryKeysWithOptionKey: Bool = false
  
  /**
   Determins whether empty modifier flags are allowed. Defaults to `false`.
   
   If set, keys without modifiers can be used as shortcuts.
  */
  public var allowsEmptyModifierFlags: Bool = false
  
  /**
   Determines whether Esc can be used to cancel shortcut recording.
   And the value defaults to `true`.
   
   If set, Esc without modifiers **can not** be set as a shortcut.
   */
  public var allowsEscToCancelRecording: Bool = true
  
  /**
   Determines whether Delete (or Forward Delete) can be used to cancel shortcut recording.
   And the value defaults to `true`.
   */
  public var allowsDeleteToClearShortcutAndCancelRecording: Bool = true
  
  /**
   Determines whether cancel recording or not if typing shortcut is invalid. Defaults to `false`.
   */
  public var cancelRecordingIfShortcutInvalid: Bool = false
  
  /// Style of the recorder control.
  public var recorderControlStyle: SCKRecorderControlStyle = .Default
  
  public init() { }
}