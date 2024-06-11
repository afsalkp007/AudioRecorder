//
//  AudioRecorderView.swift
//  AudioRecorder
//
//  Created by Afsal on 11/06/2024.
//

import UIKit

class AudioRecorderView: UIView {
  
  let errorLabel = UILabel()
  let timestampLabel = UILabel()
  let recordButton = UIButton()
  let playButton = UIButton()
  
  private let verticalStack = UIStackView()
  private let horizontalStack = UIStackView()
  
  convenience init() {
    self.init(frame: .zero)
    configureSubviews()
    configureLayout()
  }
  
  private func configureSubviews() {
    backgroundColor = .black
    
    errorLabel.textAlignment = .center
    errorLabel.textColor = .red
    errorLabel.font = UIFont.preferredFont(forTextStyle: .body)
    errorLabel.numberOfLines = 0
    
    timestampLabel.textAlignment = .center
    timestampLabel.textColor = .white
    
    let timestampFont = UIFont.monospacedDigitSystemFont(ofSize: 45, weight: UIFont.Weight.bold)
    timestampLabel.font = timestampFont
    
    func image(named name: String) -> UIImage? {
      return UIImage(named: name, in: Bundle(for: Self.self), compatibleWith: nil)
    }
    
    recordButton.setImage(image(named: "Record Button"), for: .normal)
    recordButton.setImage(image(named: "Record Button Highlighted"), for: .highlighted)
    recordButton.setImage(image(named: "Record Button Disabled"), for: .disabled)
    recordButton.setImage(image(named: "Stop Button"), for: .selected)
    recordButton.setImage(image(named: "Stop Button Highlighted"), for: [.selected, .highlighted])
    recordButton.setImage(image(named: "Stop Button Disabled"), for: [.selected, .disabled])
    
    playButton.setImage(image(named: "Play Button"), for: .normal)
    playButton.setImage(image(named: "Play Button Highlighted"), for: .highlighted)
    playButton.setImage(image(named: "Play Button Disabled"), for: .disabled)
    playButton.setImage(image(named: "Pause Button"), for: .selected)
    playButton.setImage(image(named: "Pause Button Highlighted"), for: [.selected, .highlighted])
    playButton.setImage(image(named: "Pause Button Disabled"), for: [.selected, .disabled])
    
    verticalStack.axis = .vertical
    verticalStack.spacing = 60
    verticalStack.alignment = .center
    
    horizontalStack.axis = .horizontal
    horizontalStack.spacing = 50
    horizontalStack.alignment = .center
  }
  
  private func configureLayout() {
    addAutoLayoutSubview(errorLabel)
    addAutoLayoutSubview(verticalStack)
    verticalStack.addArrangedSubview(timestampLabel)
    verticalStack.addArrangedSubview(horizontalStack)
    horizontalStack.addArrangedSubview(playButton)
    horizontalStack.addArrangedSubview(recordButton)
    verticalStack.centerInSuperview()
    
    NSLayoutConstraint.activate([
      errorLabel.leftAnchor.constraint(equalTo: leftMargin),
      errorLabel.rightAnchor.constraint(equalTo: rightMargin),
      errorLabel.topAnchor.constraint(equalTo: topAnchor, constant: 35)
    ])
  }
}
