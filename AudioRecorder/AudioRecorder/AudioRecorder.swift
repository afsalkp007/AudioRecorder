//
//  AudioRecorder.swift
//  AudioRecorder
//
//  Created by Afsal on 12/06/2024.
//

import AVFoundation

enum State {
  case empty
  case recording
  case paused
  case playing
  case error(message: String)
}

class AudioRecorder: NSObject {
  
  var updateUI: ((State) -> Void)?
  var updateTimestamp: ((TimeInterval) -> Void)?
  var updateSamples: ((Float) -> Void)?
  
  private var recordingTimer: Timer?
  private var playingTimer: Timer?
  
  private var previousState: State = .empty
  var state: State = .empty {
    didSet {
      previousState = oldValue
      stateDidChange()
    }
  }
  
  private var outputFileType: AVFileType = .mp4
  
  var audioRecorder: AVAudioRecorder!
  var audioPlayer: AVAudioPlayer?
  private let composer = TrackMerger()
  
  var outputURL: URL!
  
  var recordingTimestamp: TimeInterval = 0 {
    didSet {
      updateTimestamp?(recordingTimestamp)
    }
  }
  
  /// The playback timestamp in milliseconds
  var playbackTimestamp: TimeInterval = 0 {
    didSet {
      updateTimestamp?(playbackTimestamp)
    }
  }
  
  func configureOutputURL() {
    outputURL = newRecordingURL
  }
  
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
    
    updateUI?(state)
  }
  
  func changeState(_ state: State) {
    self.state = state
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
  
  func configureAudioRecorder(with url: URL? = nil) {
    let settings: [String: Any] = [
      AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
      AVSampleRateKey: 44100.0,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
    ]
    do {
      audioRecorder = try AVAudioRecorder(url: url ?? newRecordingURL, settings: settings)
      audioRecorder.isMeteringEnabled = true
      audioRecorder.delegate = self
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .default, options: [])
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
  
  func startRecording() {
    recordingTimestamp = 0
    audioRecorder.deleteRecording()
    startRecordingTimerAndWave()
  }
  
  func resumeRecording() {
    configureAudioRecorder(with: newRecordingURL)
    startRecordingTimerAndWave()
  }
  
  func pauseRecording() {
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
  
  func deinitialize() {
    stopRecording()
    stopPlaying()
    stopPlaybackTimer()
    stopRecordingTimer()
  }
  
  private func stopRecording() {
    stopRecordingTimer()
    if audioRecorder.isRecording {
      audioRecorder.stop()
    }
  }
  
  private func startRecordingTimerAndWave() {
    stopRecordingTimer()
    audioRecorder.record()
    recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      self.recordingTimestamp += 1
      
      audioRecorder.updateMeters() // gets the current value
      let sample = 1 - pow(10, audioRecorder.averagePower(forChannel: 0) / 20)
      self.updateSamples?(sample)
    }
  }
  
  private func stopRecordingTimer() {
    recordingTimer?.invalidate()
  }
  
  // MARK: Playback
  
  func startPlaying() {
    configureAudioPlayer(with: outputURL)
    playbackTimestamp = 0
    startPlaybackTimer()
    audioPlayer?.currentTime = 0
    audioPlayer?.play()
  }
  
  func resumePlaying() {
    startPlaybackTimer()
    audioPlayer?.play()
  }
  
  func pausePlaying() {
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
  
  func startPlaybackTimer() {
    stopPlaybackTimer()
    playingTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) {
      [weak self] _ in
      self?.playbackTimestamp += 1
    }
  }
  
  func stopPlaybackTimer() {
    playingTimer?.invalidate()
  }
  
}

extension AudioRecorder: AVAudioRecorderDelegate {
  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    changeState(.error(message: error?.localizedDescription ?? "Error encoding audio"))
  }
}

extension AudioRecorder: AVAudioPlayerDelegate {
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    changeState(.error(message: error?.localizedDescription ?? "Error decoding audio for playback"))
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    changeState(.paused)
  }
}


