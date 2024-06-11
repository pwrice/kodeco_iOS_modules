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


protocol MusicEngine: AnyObject {
  var nextBarLogicTick: Int { get set }
  var delegate: MusicEngineDelegate? { get set }

  init()
  func initializeEngine()
  func play()
  func stop()
  func stopEngine()
  func getAvailableLoopPlayer(loopURL: URL?) -> LoopPlayer?
  func releaseLoopPlayer(player: LoopPlayer)
}

protocol MusicEngineDelegate: AnyObject {
  func tick(step16: Int)
}

class LoopPlayer {
  let id: Int
  var loopURL: URL?
  let audioPlayer: AudioPlayer?
  var loopPlaying = false
  var tempo: BPM?
  var allocated = false

  init(id: Int, audioPlayer: AudioPlayer? = nil) {
    self.id = id
    self.audioPlayer = audioPlayer
  }

  func loadLoop(for loopURL: URL, tempo: BPM) {
    self.loopURL = loopURL
    self.tempo = tempo

    do {
      let file = try AVAudioFile(forReading: loopURL)
      try audioPlayer?.load(file: file, buffered: true, preserveEditTime: true)
    } catch let error {
      print("LoopPlayer.loadLoop() error: \(error)")
    }

    audioPlayer?.isEditTimeEnabled = true
    audioPlayer?.editStartTime = 0
    audioPlayer?.editEndTime = Duration(beats: 4, tempo: tempo).seconds
    audioPlayer?.isLooping = true
  }
}

class BaseMusicEngine {
  var nextBarLogicTick: Int = 15 // when we run the logic to schedule the next bar loop, advance the block counter etc..
  var loopPlayers: [LoopPlayer] = []
  var tempo = BPM(80.0) // TODO - set this dynamically per library set
  let numLoopPlayers = 16
  weak var delegate: MusicEngineDelegate?

  required init() {
  }


  func getAvailableLoopPlayer(loopURL: URL?) -> LoopPlayer? {
    if let player = loopPlayers.first(where: { $0.allocated == false }), let loopURL = loopURL {
      player.audioPlayer?.stop()
      player.loopPlaying = false
      player.allocated = true
      player.loopURL = loopURL
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

    let allAudioPlayers = loopPlayers.compactMap { $0.audioPlayer }
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
          let current16thNote = relativeDuration.beats * 4
          let current16thNoteInOneBar = Int(current16thNote) % 16

          if let delegate = musicEngine.delegate {
            delegate.tick(step16: current16thNoteInOneBar)
          }

          if current16thNoteInOneBar == musicEngine.nextBarLogicTick {
            do {
              // TODO - figure out how to handle start / stop / looping more gracefully
              for loopPlayer in musicEngine.loopPlayers where loopPlayer.loopPlaying {
                if let audioPlayer = loopPlayer.audioPlayer, audioPlayer.isPlaying != true {
                  var currentPosition = musicEngine.sequencer.currentPosition
                  currentPosition.tempo = musicEngine.tempo
                  let lastBarBeat0 = Int(floor(currentPosition.beats / 4)) * 4
                  let nextBarBeat0 = lastBarBeat0 + 4
                  let hostTime = try musicEngine.sequencer.hostTime(forBeats: Double(nextBarBeat0))
                  let avTime = AVAudioTime(hostTime: hostTime)
                  audioPlayer.play(at: avTime)
                }
              }
            } catch let error {
              print("clickTrackMidiCallback.callback error: \(error)")
            }
          }

          if Int(current16thNoteInOneBar) % 16 == 0 {
            // TODO - figure out how to handle start / stop / looping more gracefully
            for loopPlayer in musicEngine.loopPlayers where !loopPlayer.loopPlaying {
              if let audioPlayer = loopPlayer.audioPlayer, audioPlayer.isPlaying == true {
                audioPlayer.stop()
              }
            }
          }
        }
      }
    }
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

  func play() {
  }

  func stop() {
  }

  func stopEngine() {
  }
}
