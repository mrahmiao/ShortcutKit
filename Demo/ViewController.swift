//
//  ViewController.swift
//  Demo
//
//  Created by mrahmiao on 11/13/15.
//  Copyright © 2015 Code4Blues. All rights reserved.
//

import Cocoa

protocol ColorAlterable {
  func setColorToRed(sender: AnyObject?)
  func setColorToBlue(sender: AnyObject?)
  func resetColor(sender: AnyObject?)
}

class ViewController: NSViewController {
  
  let defaultColor = NSColor.orangeColor()

  @IBOutlet weak var colorWell: NSColorWell!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
}

extension ViewController: ColorAlterable {
  @IBAction func setColorToRed(sender: AnyObject?) {
    colorWell.color = NSColor.redColor()
  }
  
  @IBAction func setColorToBlue(sender: AnyObject?) {
    colorWell.color = NSColor.blueColor()
  }
  
  @IBAction func resetColor(sender: AnyObject?) {
    colorWell.color = defaultColor
  }
}
