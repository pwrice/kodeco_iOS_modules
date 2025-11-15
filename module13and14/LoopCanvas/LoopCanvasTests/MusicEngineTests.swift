import Foundation
import AudioKit
import AVFoundation
import XCTest
@testable import LoopCanvas


final class LoopPlayerCurrentPlayPositionTests: XCTestCase {
  func testPositionAtStart() throws {
    let tempo: BPM = 120
    let mock = MockAudioPlayer(duration: 8.0) // 8 seconds total
    mock.isEditTimeEnabled = true
    mock.editStartTime = 0
    // 2 bars at 120 BPM -> 1 bar = 2.0s, 2 bars = 4.0s
    mock.editEndTime = 4.0
    mock.isLooping = true
    mock.setCurrentTime(0.0)

    let loopPlayer = LoopPlayer(id: 0, audioPlayer: mock)
    loopPlayer.numBars = 2
    loopPlayer.defaultMaxNumBars = 4
    loopPlayer.tempo = tempo

    XCTAssertEqual(loopPlayer.loopPlayPosition, 0.0)
  }

  func testHalfwayThrough() throws {
    let tempo: BPM = 120
    let mock = MockAudioPlayer(duration: 8.0)
    mock.isEditTimeEnabled = true
    mock.editStartTime = 0
    // 2 bars at 120 BPM -> 4.0s
    mock.editEndTime = 4.0
    mock.isLooping = true
    // halfway (2.0s)
    mock.setCurrentTime(2.0)

    let loopPlayer = LoopPlayer(id: 0, audioPlayer: mock)
    loopPlayer.numBars = 2
    loopPlayer.defaultMaxNumBars = 4
    loopPlayer.tempo = tempo

    // Allow small floating error
    XCTAssertEqual(loopPlayer.loopPlayPosition, 0.5)
  }

  func testWrapsWhenLooping() throws {
    let tempo: BPM = 120
    let mock = MockAudioPlayer(duration: 8.0)
    mock.isEditTimeEnabled = true
    mock.editStartTime = 0
    mock.editEndTime = 4.0 // 2 bars
    mock.isLooping = true
    // Current time beyond window should wrap to 2.0s => 0.5
    mock.setCurrentTime(6.0)

    let loopPlayer = LoopPlayer(id: 0, audioPlayer: mock)
    loopPlayer.numBars = 2
    loopPlayer.defaultMaxNumBars = 4
    loopPlayer.tempo = tempo

    XCTAssertEqual(loopPlayer.loopPlayPosition, 0.5)
  }

  func testClampsWhenNotLooping() throws {
    let tempo: BPM = 120
    let mock = MockAudioPlayer(duration: 8.0)
    mock.isEditTimeEnabled = true
    mock.editStartTime = 0
    mock.editEndTime = 4.0 // 2 bars
    mock.isLooping = false
    mock.setCurrentTime(10.0) // beyond end

    let loopPlayer = LoopPlayer(id: 0, audioPlayer: mock)
    loopPlayer.numBars = 2
    loopPlayer.defaultMaxNumBars = 4
    loopPlayer.tempo = tempo

    XCTAssertEqual(loopPlayer.loopPlayPosition, 1.0)
  }
}
