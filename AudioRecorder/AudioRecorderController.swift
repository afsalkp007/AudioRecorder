//
//  AudioEngineController.swift
//  AudioRecorder
//
//  Created by Afsal on 11/06/2024.
//

import UIKit
import AVFoundation

class AudioRecorderController: UIViewController {
  
  private var outputFileType: AVFileType = .mp4
  
  private enum State {
    case empty
    case recording
    case paused
    case playing
    case error(message: String)
  }
  
  // MARK: Members
  
  private let contentView = AudioRecorderView()
  
  private var audioRecorder: AVAudioRecorder!
  private var audioPlayer: AVAudioPlayer?
  private let composer = TrackMerger()
  
  // MARK: Properties
  
  private var previousState: State = .empty
  private var state: State = .empty {
    didSet {
      previousState = oldValue
      stateDidChange()
    }
  }
  
  /// The recording timestamp in milliseconds
  private var recordingTimestamp: TimeInterval = 0 {
    didSet {
      updateTimestampLabel(with: recordingTimestamp)
    }
  }
  
  /// The playback timestamp in milliseconds
  private var playbackTimestamp: TimeInterval = 0 {
    didSet {
      updateTimestampLabel(with: playbackTimestamp)
    }
  }
  
  private var recordingTimer: Timer?
  private var playingTimer: Timer?
  
  /// The `URL` at which the newly recorded audio will be found
  private var outputURL: URL!
  
  // MARK: Lifecycle
  
  deinit {
    stopRecording()
    stopPlaying()
  }
  
  override func loadView() {
    edgesForExtendedLayout = []
    view = contentView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setTitle()
    configure()
  }
  
  // MARK: Member Configuration
  
  private func setTitle() {
    navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    navigationController?.navigationBar.prefersLargeTitles = true
    self.title = "Record Audio"
  }
  
  private func configure() {
    state = .empty
    configureButtonTargets()
    configureOutputURL()
    // The audio recorder starts recording at the outputURL.
    // Each time the recorder is paused, it begins recording to a new temporary file.
    configureAudioRecorder(with: outputURL)
    recordingTimestamp = 0
    playbackTimestamp = 0
  }
  
  private func configureButtonTargets() {
    contentView.recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
    contentView.playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
  }
  
  private func configureOutputURL() {
    outputURL = newRecordingURL
  }
  
  private var newRecordingURL: URL {
    var fileExtension = ".mp4"
    switch outputFileType {
    case .mp4: fileExtension = ".mp4"
    case .m4a: fileExtension = ".m4a"
    case .ac3: fileExtension = ".ac3"
    case .amr: fileExtension = ".amr"
    case .aifc: fileExtension = ".aifc"
    case .aiff: fileExtension = ".aiff"
    case .mp3: fileExtension = ".mp3"
    default: break
    }
    let filename = "\(UUID().uuidString)\(fileExtension)"
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    return URL(fileURLWithPath: documentsPath).appendingPathComponent(filename)
  }
  
  private func configureAudioRecorder(with url: URL? = nil) {
    let settings = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 16000, AVNumberOfChannelsKey: 2]
    do {
      audioRecorder = try AVAudioRecorder(url: url ?? newRecordingURL, settings: settings)
      audioRecorder.delegate = self
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(AVAudioSession.Category.playAndRecord)
      try session.setActive(true)
      try session.overrideOutputAudioPort(.speaker)
    } catch {
      state = .error(message: error.localizedDescription)
    }
  }
  
  private func configureAudioPlayer(with url: URL? = nil) {
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: url ?? audioRecorder.url)
      audioPlayer?.delegate = self
    } catch {
      state = .error(message: error.localizedDescription)
    }
  }
}
  
extension AudioRecorderController {
  // MARK: Button Targets
  
  @objc
  private func recordTapped() {
    if case .recording = state {
      state = .paused
    } else {
      state = .recording
    }
  }
  
  @objc
  private func playTapped() {
    if case .playing = state {
      state = .paused
    } else {
      state = .playing
    }
  }
  
  // MARK: State
  
  private func stateDidChange() {
    switch (previousState, state) {
    case (_, .empty):
      break
      
    case (.empty, .recording):
      startRecording()
      
    case (.paused, .recording):
      resumeRecording()
      
    case (.recording, .paused):
      pauseRecording()
      
    case (.paused, .playing):
      if let player = audioPlayer, player.currentTime != 0 {
        resumePlaying()
      } else {
        startPlaying()
      }
      
    case (.playing, .paused):
      pausePlaying()
      
    case (_, .error):
      break
      
    default:
      break
    }
    
    updateUI(for: state)
  }
}

extension AudioRecorderController {
  private func startRecording() {
    recordingTimestamp = 0
    startRecordingTimer()
    audioRecorder.deleteRecording()
    audioRecorder.isMeteringEnabled = true
    audioRecorder.record()
  }
  
  private func resumeRecording() {
    configureAudioRecorder(with: newRecordingURL)
    startRecordingTimer()
    audioRecorder.record()
  }
  
  private func pauseRecording() {
    stopRecordingTimer()
    if audioRecorder.isRecording {
      audioRecorder.stop()
      composer.merge(trackAt: audioRecorder.url, intoTrackAt: outputURL, outputFileType: outputFileType) {
        [unowned self] result in
        
        switch result {
        case let .success(url):
          self.configureAudioPlayer(with: url)
          
        case let .failure(error):
          switch error {
          case .urlsNotUnique:
            self.configureAudioPlayer(with: self.audioRecorder.url)
          default:
            self.state = .error(message: error.localizedDescription)
          }
        }
      }
    }
  }
  
  private func stopRecording() {
    stopRecordingTimer()
    if audioRecorder.isRecording {
      audioRecorder.stop()
    }
  }
  
  private func startRecordingTimer() {
    stopRecordingTimer()
    recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) {
      [weak self] _ in
      self?.recordingTimestamp += 1
    }
  }
  
  private func stopRecordingTimer() {
    recordingTimer?.invalidate()
  }
  
  // MARK: Playback
  
  private func startPlaying() {
    configureAudioPlayer(with: outputURL)
    playbackTimestamp = 0
    startPlaybackTimer()
    audioPlayer?.currentTime = 0
    audioPlayer?.play()
  }
  
  private func resumePlaying() {
    startPlaybackTimer()
    audioPlayer?.play()
  }
  
  private func pausePlaying() {
    stopPlaybackTimer()
    if let player = audioPlayer, player.isPlaying {
      audioPlayer?.pause()
    }
  }
  
  private func stopPlaying() {
    stopPlaybackTimer()
    if let player = audioPlayer, player.isPlaying {
      audioPlayer?.stop()
    }
  }
  
  private func startPlaybackTimer() {
    stopPlaybackTimer()
    playingTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) {
      [weak self] _ in
      self?.playbackTimestamp += 1
    }
  }
  
  private func stopPlaybackTimer() {
    playingTimer?.invalidate()
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
    animateChanges(on: button) {
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
    animateChanges(on: button) {
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
  
  private func animateChanges(on view: UIView, _ changes: @escaping () -> ()) {
    UIView.transition(with: view,
                      duration: 0.3,
                      options: [.transitionCrossDissolve, .curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
                      animations: changes,
                      completion: nil)
  }
}

extension AudioRecorderController: AVAudioRecorderDelegate {
  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    state = .error(message: error?.localizedDescription ?? "Error encoding audio")
  }
}

extension AudioRecorderController: AVAudioPlayerDelegate {
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    state = .error(message: error?.localizedDescription ?? "Error decoding audio for playback")
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    state = .paused
  }
}
