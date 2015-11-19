//
//  AppDelegate.swift
//  Demo
//
//  Created by mrahmiao on 11/13/15.
//  Copyright © 2015 Code4Blues. All rights reserved.
//

import Cocoa
import ShortcutKit

let RedRecorderIdentifier = "RedRecorder"
let BlueRecorderIdentifier = "BlueRecorderIdentifier"
let ResetRecorderIdentifier = "ResetRecorderIdentifier"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(aNotification: NSNotification) {
    // Insert code here to initialize your application
    
    SCKHotkeyManager.sharedManager.bindRegisteredControlWithIdentifier(BlueRecorderIdentifier) { self.setColorToBlue(nil) }
    SCKHotkeyManager.sharedManager.bindRegisteredControlWithIdentifier(RedRecorderIdentifier) { self.setColorToRed(nil) }
    SCKHotkeyManager.sharedManager.bindRegisteredControlWithIdentifier(ResetRecorderIdentifier) { self.resetColor(nil) }

  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }
}

extension AppDelegate: ColorAlterable {
  func setColorToBlue(sender: AnyObject?) {
    if let vc = NSApp.mainWindow?.windowController?.contentViewController as? ColorAlterable {
      vc.setColorToBlue(sender)
    }
  }
  
  func setColorToRed(sender: AnyObject?) {
    if let vc = NSApp.mainWindow?.windowController?.contentViewController as? ColorAlterable {
      vc.setColorToRed(sender)
    }
  }
  
  func resetColor(sender: AnyObject?) {
    if let vc = NSApp.mainWindow?.windowController?.contentViewController as? ColorAlterable {
      vc.resetColor(sender)
    }
  }
}

