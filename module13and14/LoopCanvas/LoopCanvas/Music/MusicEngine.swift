//
//  MusicEngine.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/8/24.
//

import Foundation
import SwiftUI
import AudioKit
import AVFoundation
import os

protocol AudioPlayable: AnyObject {
  var duration: Double { get }
  var isEditTimeEnabled: Bool { get set }
  var editStartTime: Double { get set }
  var editEndTime: Double { get set }
  var isLooping: Bool { get set }
  var currentTime: Double { get }
  var isPlaying: Bool { get }

  func load(file: AVAudioFile, buffered: Bool?, preserveEditTime: Bool) throws
  func play(from startTime: TimeInterval?,
            to endTime: TimeInterval?,
            at when: AVAudioTime?,
            completionCallbackType: AVAudioPlayerNodeCompletionCallbackType)
  func stop()
}

extension AudioPlayer: AudioPlayable {}

// Minimal mock conforming to AudioPlayable
final class MockAudioPlayer: AudioPlayable {
  var duration: Double
  var isEditTimeEnabled = false
  var editStartTime: Double = 0
  var editEndTime: Double = 0
  var isLooping = false
  var isPlaying = false

  // currentTime is settable for tests via a backing var
  private var _currentTime: Double = 0
  var currentTime: Double { _currentTime }

  init(duration: Double) {
    self.duration = duration
  }

  func setCurrentTime(_ time: Double) { _currentTime = time }

  func load(file: AVAudioFile, buffered: Bool?, preserveEditTime: Bool) throws {}
  func play(from startTime: TimeInterval?, to endTime: TimeInterval?, at when: AVAudioTime?, completionCallbackType: AVAudioPlayerNodeCompletionCallbackType) {}
  func stop() { isPlaying = false }
}

protocol MusicEngine: AnyObject {
  var nextBarLogicTick: Int { get set }
  var delegate: MusicEngineDelegate? { get set }
  var tempo: Double { get set }

  func timeUntilNextBar() -> TimeInterval

  init()
  func initializeEngine()
  func play()
  func stop()
  func reset()
  func stopEngine()
  func getAvailableLoopPlayer(loopURL: URL?, numBars: Int) -> LoopPlayer?
  func releaseLoopPlayer(player: LoopPlayer)
}

protocol MusicEngineDelegate: AnyObject {
  func tick(step16: Int)
}

class LoopPlayer {
  private static let logger = Logger(
    subsystem: "MusicEngine",
    category: String(describing: LoopPlayer.self)
  )

  let id: Int
  var loopURL: URL?
  let audioPlayer: AudioPlayable?
  var loopPlaying = false
  var tempo: BPM?
  var allocated = false
  var loopDuration: Duration?
  var numBars = 1
  var maxNumBars: Int {
    if let loopDuration = loopDuration {
      return Int(floor(loopDuration.beats / 4.0))
    }
    return defaultMaxNumBars
  }
  var defaultMaxNumBars = 1
  var startOffsetInBars = 0

  var sampleStartTime: Double {
    if let audioPlayer {
      return audioPlayer.editStartTime / audioPlayer.duration
    }
    return defaultSampleStartTime
  }
  var defaultSampleStartTime = 1.0

  var sampleEndTime: Double {
    if let audioPlayer {
      return audioPlayer.editEndTime / audioPlayer.duration
    }
    return defaultSampleEndTime
  }
  var defaultSampleEndTime = 1.0

  var samplePlayPosition: Double {
    guard let audioPlayer = audioPlayer else { return defaultSamplePlayPosition }

    let startSec = 0.0
    let endSec: Double = audioPlayer.duration
    // Current time in seconds within the file
    return audioPlayer.currentTime / (endSec - startSec)
  }
  var defaultSamplePlayPosition = 0.0

  var loopPlayPosition: Double {
    guard let audioPlayer = audioPlayer, let tempo = tempo else { return 0.0 }

    // Effective loop length in bars
    let loopBars = min(numBars, maxNumBars)

    // Establish edit window
    let startSec = max(0.0, audioPlayer.editStartTime)
    let endSec: Double = {
      let candidate = audioPlayer.editEndTime
      if candidate > 0 {
        return candidate
      } else if audioPlayer.duration > 0 {
        return audioPlayer.duration
      } else {
        return 0.0
      }
    }()

    let window = max(0.0, endSec - startSec)
    guard window > 0, loopBars > 0 else { return 0.0 }

    // Current time in seconds within the file
    let current = audioPlayer.currentTime

    // Map current time into the edit window
    var relative: Double
    if audioPlayer.isLooping {
      // Normalize into [0, window)
      let offset = current - startSec
      let mod = offset.truncatingRemainder(dividingBy: window)
      relative = mod >= 0 ? mod : (mod + window)
    } else {
      // Clamp into [0, window]
      relative = min(max(0.0, current - startSec), window)
    }

    // Convert seconds -> beats -> bars
    let beats = Duration(seconds: relative, tempo: tempo).beats
    let bars = beats / 4.0

    // Normalize to 0.0 ... 1.0 over the loopBars
    let normalized = bars / Double(loopBars)
    return min(max(0.0, normalized), 1.0)
  }

  init(id: Int, audioPlayer: AudioPlayable? = nil) {
    self.id = id
    self.audioPlayer = audioPlayer
  }

  func loadLoop(for loopURL: URL, tempo: BPM) {
    guard let audioPlayer = audioPlayer else {
      Self.logger.error("LoopPlayer.loadLoop() error: audioPlayer is nil")
      return
    }
    self.loopURL = loopURL
    self.tempo = tempo

    do {
      let file = try AVAudioFile(forReading: loopURL)
      try audioPlayer.load(file: file, buffered: true, preserveEditTime: true)
    } catch let error {
      Self.logger.error("LoopPlayer.loadLoop() error: \(error)")
    }

    loopDuration = Duration(seconds: audioPlayer.duration, tempo: tempo)
    audioPlayer.isEditTimeEnabled = true
    audioPlayer.editStartTime = 0
    let loopBars = numBars > maxNumBars ? maxNumBars : numBars
    audioPlayer.editEndTime = Duration(beats: Double(loopBars * 4), tempo: tempo).seconds
    audioPlayer.isLooping = true
  }

  func updateNumBars(_ numBars: Int) {
    guard let audioPlayer, let tempo else { return }
    let loopBars = numBars > maxNumBars ? maxNumBars : numBars
    let startTime = Duration(beats: Double(startOffsetInBars * 4), tempo: tempo).seconds
    let endTime = startTime + Duration(beats: Double(loopBars * 4), tempo: tempo).seconds
    self.numBars = numBars
    audioPlayer.editEndTime = endTime
  }

  func updateStartOffset(_ newStartOffsetInBars: Int) {
    guard let audioPlayer, let tempo, newStartOffsetInBars < maxNumBars else { return }
    let deltaTime = Duration(beats: Double(newStartOffsetInBars * 4), tempo: tempo).seconds
      - Duration(beats: Double(startOffsetInBars * 4), tempo: tempo).seconds
    audioPlayer.editStartTime += deltaTime
    audioPlayer.editEndTime += deltaTime
    self.startOffsetInBars = newStartOffsetInBars
  }
}

class BaseMusicEngine {
  private static let logger = Logger(
    subsystem: "MusicEngine",
    category: String(describing: BaseMusicEngine.self)
  )

  var nextBarLogicTick: Int = 15 // when we run the logic to schedule the next bar loop, advance the block counter etc..
  var loopPlayers: [LoopPlayer] = []
  var tempo: BPM = 80 {
    didSet {
      updateSequencerTempo(newTempo: tempo)
    }
  }

  let numLoopPlayers = 16
  weak var delegate: MusicEngineDelegate?

  func updateSequencerTempo(newTempo: BPM) {}

  func processClickTrackNote(clickTrackPosition: Duration) {
    let current16thNote = clickTrackPosition.beats * 4
    let current16thNoteInOneBar = Int(current16thNote) % 16

    if let delegate = delegate {
      delegate.tick(step16: current16thNoteInOneBar)
    }

    if current16thNoteInOneBar == nextBarLogicTick {
      // TODO - figure out how to handle start / stop / looping more gracefully
      for loopPlayer in loopPlayers where loopPlayer.loopPlaying {
        if let audioPlayer = loopPlayer.audioPlayer {
          let lastBarBeat0 = Int(floor(clickTrackPosition.beats / 4)) * 4
          let nextBarBeat0 = lastBarBeat0 + 4
          if audioPlayer.isPlaying != true {
            scheduleAudioPlaybackOnClickTrack(audioPlayer: audioPlayer as! AudioPlayer, beat: Double(nextBarBeat0))
          }
        }
      }
    }

    if Int(current16thNoteInOneBar) % 16 == 0 {
      // TODO - figure out how to handle start / stop / looping more gracefully
      for loopPlayer in loopPlayers where !loopPlayer.loopPlaying {
        if let audioPlayer = loopPlayer.audioPlayer, audioPlayer.isPlaying == true {
          audioPlayer.stop()
        }
      }
    }
  }

  func scheduleAudioPlaybackOnClickTrack(audioPlayer: AudioPlayer, beat: Double) {
    Self.logger.error("Need to override scheduleAudioPlaybackOnClickTrack")
  }

  required init() {
  }


  func getAvailableLoopPlayer(loopURL: URL?, numBars: Int) -> LoopPlayer? {
    if let player = loopPlayers.first(where: { $0.allocated == false }), let loopURL = loopURL {
      player.audioPlayer?.stop()
      player.loopPlaying = false
      player.allocated = true
      player.loopURL = loopURL
      player.numBars = numBars
      player.loadLoop(for: loopURL, tempo: tempo)
      return player
    }

    return nil
  }

  func releaseLoopPlayer(player: LoopPlayer) {
    player.audioPlayer?.stop()
    player.loopPlaying = false
    player.allocated = false
    player.loopURL = nil
  }
}

// TODO - handle app events to restart AudioKit such as pause for phonecall, background audio etc..

class AudioKitMusicEngine: BaseMusicEngine, MusicEngine {
  private static let logger = Logger(
    subsystem: "MusicEngine",
    category: String(describing: AudioKitMusicEngine.self)
  )

  let engine = AudioEngine()
  var sequencer = AppleSequencer()
  var clickTrackMidiCallback = MIDICallbackInstrument()
  var clickTrack: MusicTrackManager?

  required init() {
    super.init()
  }

  func initializeEngine() {
    for ind in 0..<numLoopPlayers {
      loopPlayers.append(LoopPlayer(id: ind, audioPlayer: AudioPlayer()))
    }

    let allAudioPlayers = loopPlayers.compactMap { $0.audioPlayer as? AudioPlayer }
    engine.output = Mixer(allAudioPlayers, name: "Main Mixer")
    try? engine.start()

    clickTrack = sequencer.newTrack("ClickTrack")

    clickTrack?.setMIDIOutput(clickTrackMidiCallback.midiIn)

    // TODO - handle case more gracefully when sequencer loops
    let clickTrackSeqLenghBars = 256.0

    sequencer.setLength(Duration(beats: clickTrackSeqLenghBars * 4))
    sequencer.enableLooping()
    sequencer.setTempo(tempo)

    // Add 16th notes to the click track
    for ind in 0...Int(clickTrackSeqLenghBars * 16) {
      clickTrack?.add(
        noteNumber: MIDINoteNumber(36),
        velocity: 127,
        position: Duration(beats: 0.25 * Double(ind % Int(clickTrackSeqLenghBars * 16))),
        duration: Duration(beats: 0.25))
    }

    // On each 16th note, check our loopPlayers and re-schedule playing the loop
    clickTrackMidiCallback.callback = { [weak self] status, _, _ in
      if status == 144 { // Note On
        if let musicEngine = self {
          var relativeDuration = musicEngine.sequencer.currentRelativePosition
          relativeDuration.tempo = musicEngine.tempo
          musicEngine.processClickTrackNote(clickTrackPosition: relativeDuration)
        }
      }
    }
  }

  override func scheduleAudioPlaybackOnClickTrack(audioPlayer: AudioPlayer, beat: Double) {
    do {
      let hostTime = try sequencer.hostTime(forBeats: Double(beat))
      let avTime = AVAudioTime(hostTime: hostTime)
      audioPlayer.play(at: avTime)
    } catch let error {
      Self.logger.error("clickTrackMidiCallback.callback error: \(error)")
    }
  }

  override func updateSequencerTempo(newTempo: BPM) {
    sequencer.setTempo(newTempo)
  }

  func timeUntilNextBar() -> TimeInterval {
    // Determine current position in beats with the engine's tempo
    var position = sequencer.currentRelativePosition
    position.tempo = tempo
    let beats = position.beats
    // Compute next bar start in beats (bars are 4 beats)
    let currentBarIndex = floor(beats / 4.0)
    let nextBarStartBeats = (currentBarIndex + 1.0) * 4.0
    let beatsRemaining = max(0.0, nextBarStartBeats - beats)
    // Convert beats remaining to seconds given current tempo
    let secondsRemaining = Duration(beats: beatsRemaining, tempo: tempo).seconds
    return secondsRemaining
  }

  func reset() {
    sequencer.rewind()
  }

  func play() {
    sequencer.play()
  }

  func stop() {
    sequencer.stop()
    for loopPlayer in self.loopPlayers {
      loopPlayer.audioPlayer?.stop()
    }
  }

  func stopEngine() {
    sequencer.stop()
    for loopPlayer in self.loopPlayers {
      loopPlayer.audioPlayer?.stop()
    }
    engine.stop()
  }
}

class MockMusicEngine: BaseMusicEngine, MusicEngine {
  func initializeEngine() {
    for ind in 0..<numLoopPlayers {
      loopPlayers.append(LoopPlayer(id: ind))
    }
  }

  func reset() {
  }

  func play() {
  }

  func stop() {
  }

  func stopEngine() {
  }

  func timeUntilNextBar() -> TimeInterval { 0 }

  override func scheduleAudioPlaybackOnClickTrack(audioPlayer: AudioPlayer, beat: Double) {
  }
}
