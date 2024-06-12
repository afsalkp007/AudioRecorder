//
//  AudioEngineController.swift
//  AudioRecorder
//
//  Created by Afsal on 11/06/2024.
//

import UIKit

class AudioRecorderController: UIViewController {
  let audRecorder = AudioRecorder()
  
  @IBOutlet private(set) weak var errorLabel: UILabel!
  @IBOutlet private(set) weak var timestampLabel: UILabel!
  @IBOutlet private(set) weak var recordButton: UIButton!
  @IBOutlet private(set) weak var playButton: UIButton!
  @IBOutlet private(set) weak var waveformView: WaveformLiveView!
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  deinit {
    audRecorder.deinitialize()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setTitle()
    configure()
    configureSubviews()
    
    audRecorder.updateUI = { [weak self] state in
      self?.updateUI(for: state)
    }
    
    audRecorder.updateTimestamp = { [weak self] timestamp in
      self?.updateTimestampLabel(with: timestamp)
    }
    
    audRecorder.updateSamples = { [weak self] sample in
      guard let self = self else { return }
      self.waveformView.add(sample: sample)
    }
  }
  
  private func configureSubviews() {
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
    audRecorder.configureAudioRecorder(with: audRecorder.outputURL)
    
    audRecorder.recordingTimestamp = 0
    audRecorder.playbackTimestamp = 0
  }
  
  private func configureButtonTargets() {
    recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
    playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
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
    guard let label = timestampLabel else { return }
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
    timestampLabel.text = timestamp
  }
  
  private func updateRecordButton(for state: State) {
    guard let button = recordButton else { return }
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
    guard let button = playButton else { return }
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
    guard let label = errorLabel else { return }
    switch state {
    case .error(let message):
      label.text = message
      label.isHidden = false
      
    default:
      label.isHidden = true
    }
  }
}
