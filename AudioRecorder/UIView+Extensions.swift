//
//  UIView+Extensions.swift
//  AudioRecorder
//
//  Created by Afsal on 11/06/2024.
//

import UIKit

extension UIView {
  
  // MARK: - NSLayoutConstraint Convenience Methods
  
  func addAutoLayoutSubview(_ subview: UIView) {
    addSubview(subview)
    subview.translatesAutoresizingMaskIntoConstraints = false
  }
  
  // MARK: Layout Macros
  
  func centerInSuperview() {
    guard let superview = self.superview else { return }
    NSLayoutConstraint.activate([
      centerXAnchor.constraint(equalTo: superview.centerXAnchor),
      centerYAnchor.constraint(equalTo: superview.centerYAnchor)
    ])
  }
  
  // MARK: Layout Margins Guide Shortcut
  
  var leftMargin: NSLayoutXAxisAnchor {
    return layoutMarginsGuide.leftAnchor
  }
  
  var rightMargin: NSLayoutXAxisAnchor {
    return layoutMarginsGuide.rightAnchor
  }
  
  // MARK: Animate
  
  func animate(_ changes: @escaping () -> Void) {
    UIView.transition(with: self,
                      duration: 0.3,
                      options: [.transitionCrossDissolve, .curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
                      animations: changes,
                      completion: nil)
  }

}
