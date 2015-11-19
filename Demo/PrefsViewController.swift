//
//  PrefsViewController.swift
//  ShortcutKit
//
//  Created by mrahmiao on 11/19/15.
//  Copyright © 2015 Code4Blues. All rights reserved.
//

import Cocoa
import ShortcutKit

class PrefsViewController: NSViewController {

  @IBOutlet weak var redRecorder: SCKRecorderControl! {
    didSet {
      redRecorder.bindIdentifier(RedRecorderIdentifier) { _ in
        guard let colorAlterable = NSApp.delegate as? ColorAlterable else {
          return
        }
        
        colorAlterable.setColorToRed(self)
      }
    }
  }
  
  @IBOutlet weak var blueRecorder: SCKRecorderControl! {
    didSet {
      blueRecorder.bindIdentifier(BlueRecorderIdentifier) { _ in
        guard let colorAlterable = NSApp.delegate as? ColorAlterable else {
          return
        }
        
        colorAlterable.setColorToBlue(self)
      }
    }
  }
  
  @IBOutlet weak var resetRecorder: SCKRecorderControl! {
    didSet {
      resetRecorder.bindIdentifier(ResetRecorderIdentifier) { _ in
        guard let colorAlterable = NSApp.delegate as? ColorAlterable else {
          return
        }
        
        colorAlterable.resetColor(self)
      }
    }
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
  }
  
}
