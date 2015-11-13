//
//  SCKError.swift
//  ShortcutKit
//
//  Created by mrahmiao on 11/6/15.
//  Copyright © 2015 Code4Blues. All rights reserved.
//

import Foundation

public let ShortcutKitErrorDomain = "com.code4blues.mrahmiao.ShortcutKit.ErrorDomain"

enum ShortcutError: ErrorType {
  case Invalid
  case ExistsInApp
  case TakenBySystem
  case ExistsInMenu(NSMenuItem)
  
  func errorWithShortcut(shortcut: Shortcut) -> NSError {
    var userInfo: [NSObject: AnyObject] = [
      NSLocalizedDescriptionKey: localizedErrorMessageTextWithShortcut(shortcut)
    ]
    
    switch self {
    case .Invalid:
      userInfo[NSLocalizedRecoverySuggestionErrorKey] = NSLocalizedString("ShortcutErrorInvalidRecoverySuggestion", value: "Invalid key combination. Please change to another one.", comment: "Recovery suggestion for an invalid key combination.")
    case .ExistsInApp:
      userInfo[NSLocalizedRecoverySuggestionErrorKey] = NSLocalizedString("ShortcutErrorExistsInAppRecoverySuggestion", value: "Shortcut already registered in your app. Please Change another one.", comment: "Recovery suggestion for an key combination that already exist in app.")
    case .TakenBySystem:
      userInfo[NSLocalizedRecoverySuggestionErrorKey] = NSLocalizedString("ShortcutErrorSystemTakenRecoverySuggestion", value: "It is already used by a system-wide keyboard shortcut. If you really want to use this key combination, most shorcuts can be changed in the Keyboard panel in System Preferences.", comment: "Recovery suggestion for a shortcut that has been taken by a system-wide one.")
    case .ExistsInMenu(let menuItem):
      userInfo[NSLocalizedRecoverySuggestionErrorKey] = String(format: NSLocalizedString("ShortcutErrorExistsInMenuRecoverySuggestion", value: "It is already used by the menu item \"%@\".", comment: "Recovery suggestion for a shortcut that has been used by an app menu."),  menuItem.menuPath)
    }
    
    return NSError(domain: ShortcutKitErrorDomain, code: 0, userInfo: userInfo)
  }
  
  static func errorWithShortcut(shortcut: Shortcut, failureReason reason: String) -> NSError {
    return NSError(domain: ShortcutKitErrorDomain, code: 0, userInfo: [
      NSLocalizedDescriptionKey: localizedErrorMessageTextWithShortcut(shortcut),
      NSLocalizedRecoverySuggestionErrorKey: reason
    ])
  }
}

// MARK: - Helpers
private func localizedErrorMessageTextWithShortcut(shortcut: Shortcut) -> String {
  return String(format: NSLocalizedString("ShortcutErrorMessageText", value: "The key combination \"%@\" can not be used.", comment: "Message text on the alert dialog displayed when an inappropriate key combination typed"), shortcut.description)
}

private extension NSMenuItem {
  var menuPath: String {
    var menuItems = [self]
  
    func findParentForMenuItem(menuItem: NSMenuItem) {
      if let parentItem = menuItem.parentItem {
        menuItems.append(parentItem)
        findParentForMenuItem(parentItem)
      }
    }
    
    findParentForMenuItem(self)
    
    return menuItems.reverse().map({$0.title}).joinWithSeparator(" → ")
  }
}
