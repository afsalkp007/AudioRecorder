//
//  AudioEngineController.swift
//  AudioRecorder
//
//  Created by Afsal on 11/06/2024.
//

import UIKit

class AudioRecorderController: UIViewController {
  let audRecorder = AudioRecorder()
  
  // MARK: Members
  
  private let contentView = AudioRecorderView()
    
  // MARK: Lifecycle
  
  deinit {
    audRecorder.deinitialize()
  }
  
  override func loadView() {
    edgesForExtendedLayout = []
    view = contentView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setTitle()
    configure()
    
    audRecorder.updateUI = { [weak self] state in
      self?.updateUI(for: state)
    }
    
    audRecorder.updateTimestamp = { [weak self] timestamp in
      self?.updateTimestampLabel(with: timestamp)
    }
  }
  
  // MARK: Member Configuration
  
  private func setTitle() {
    navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    navigationController?.navigationBar.prefersLargeTitles = true
    self.title = "Record Audio"
  }
  
  private func configure() {
    updateUI(for: .empty)
    updateTimestampLabel(with: 0)
    
    configureButtonTargets()
    audRecorder.configureOutputURL()
    // The audio recorder starts recording at the outputURL.
    // Each time the recorder is paused, it begins recording to a new temporary file.
    audRecorder.configureAudioRecorder(with: audRecorder.outputURL)
    
    audRecorder.recordingTimestamp = 0
    audRecorder.playbackTimestamp = 0
  }
  
  private func configureButtonTargets() {
    contentView.recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
    contentView.playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
  }
  
}
  
extension AudioRecorderController {
  // MARK: Button Targets
  
  @objc
  private func recordTapped() {
    if case .recording = audRecorder.state {
      audRecorder.changeState(.paused)
    } else {
      audRecorder.changeState(.recording)
    }
  }
  
  @objc
  private func playTapped() {
    if case .playing = audRecorder.state {
      audRecorder.changeState(.paused)
    } else {
      audRecorder.changeState(.playing)
    }
  }
}

extension AudioRecorderController {
  private func updateUI(for state: State) {
    updateTimestampLabel(for: state)
    updateRecordButton(for: state)
    updatePlayButton(for: state)
    updateErrorLabel(for: state)
  }
  
  private func updateTimestampLabel(for state: State) {
    let label = contentView.timestampLabel
    switch state {
    case .empty, .paused:
      label.textColor = UIColor.white.withAlphaComponent(0.5)
    default:
      label.textColor = .white
    }
  }
  
  /// Displays the `time` in "00:00.00" format
  ///
  /// - Parameter time: The timestamp to display (in milliseconds)
  private func updateTimestampLabel(with time: TimeInterval) {
    let t = Int(time)
    let mil = t % 60
    let sec = (t / 60) % 60
    let min = t / 3600
    let format = "%02d:%02d"
    let timestamp = String(format: format, min, sec, mil)
    contentView.timestampLabel.text = timestamp
  }
  
  private func updateRecordButton(for state: State) {
    let button = contentView.recordButton
    button.animate {
      switch state {
      case .empty:
        button.isSelected = false
        button.isEnabled = true
        
      case .recording:
        button.isSelected = true
        button.isEnabled = true
        
      case .paused:
        button.isSelected = false
        button.isEnabled = true
        
      default:
        button.isSelected = false
        button.isEnabled = false
      }
    }
  }
  
  private func updatePlayButton(for state: State) {
    let button = contentView.playButton
    button.animate {
      switch state {
      case .empty:
        button.isSelected = false
        button.isEnabled = false
        
      case .playing:
        button.isSelected = true
        button.isEnabled = true
        
      case .paused:
        button.isSelected = false
        button.isEnabled = true
        
      default:
        button.isSelected = false
        button.isEnabled = false
      }
    }
  }
  
  private func updateErrorLabel(for state: State) {
    let label = contentView.errorLabel
    switch state {
    case .error(let message):
      label.text = message
      label.isHidden = false
      
    default:
      label.isHidden = true
    }
  }
}
