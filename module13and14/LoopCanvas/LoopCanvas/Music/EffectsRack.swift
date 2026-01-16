import Foundation
import AudioKit
import AudioKitEX
import DunneAudioKit

/// A configurable chain of AudioKit effects with per-stage dry/wet control.
/// Initialize with any input `Node` and access the processed output via `output`.
final class EffectsRack {
  // MARK: - Public output
  let output: Node

  // MARK: - Stages
  // Keep references so clients can tune parameters and dry/wet balance per stage.
  let lowPass: LowPassFilter
  let lowPassMix: DryWetMixer

  let delay: Delay
  let delayMix: DryWetMixer

  let highPass: HighPassFilter
  let highPassMix: DryWetMixer

  let flanger: Flanger
  let flangerMix: DryWetMixer

  let reverb: Reverb
  let reverbMix: DryWetMixer

  // MARK: - Tempo Sync
  /// Current tempo in beats per minute for delay sync calculations.
  var bpm: Double = 120.0 // beats per minute

  /// Enable tempo synchronization of delay time to BPM; if false, delay uses free time in seconds.
  var delaySyncEnabled: Bool = false

  /// Note division used when tempo-syncing delay time.
  var delayDivision: NoteDivision = .eighth

  /// Character pushes mappings from subtle (0) to extreme (1).
  var character: Double = 0.5

  /// Note divisions for tempo-synced delay times, with helper to compute seconds per division.
  enum NoteDivision: CaseIterable {
    case whole, half, quarter, eighth, sixteenth, thirtySecond
    case dottedHalf, dottedQuarter, dottedEighth, dottedSixteenth
    case tripletHalf, tripletQuarter, tripletEighth, tripletSixteenth

    fileprivate func seconds(atBPM bpm: Double) -> Double {
      let beat = 60.0 / max(1.0, bpm) // seconds per quarter note
      switch self {
      case .whole:           return beat * 4.0
      case .half:            return beat * 2.0
      case .quarter:         return beat
      case .eighth:          return beat / 2.0
      case .sixteenth:       return beat / 4.0
      case .thirtySecond:    return beat / 8.0
      case .dottedHalf:      return beat * 3.0
      case .dottedQuarter:   return beat * 1.5
      case .dottedEighth:    return beat * 0.75
      case .dottedSixteenth: return beat * 0.375
      case .tripletHalf:     return (beat * 2.0) / 3.0 * 2.0 // 2 beats as triplets
      case .tripletQuarter:  return beat / 3.0 * 2.0
      case .tripletEighth:   return beat / 6.0 * 2.0
      case .tripletSixteenth:return beat / 12.0 * 2.0
      }
    }
  }

  /// Resolve a delay time in seconds from either synced division or free value (seconds)
  private func resolvedDelayTime(freeSeconds: Double) -> AUValue {
    if delaySyncEnabled {
      let secs = delayDivision.seconds(atBPM: bpm)
      return au(secs)
    } else {
      return au(freeSeconds)
    }
  }

  /// Initialize the rack with an input node and create a chain of effects.
  /// Stages: LowPass -> Delay -> HighPass -> Reverb, each with its own DryWetMixer.
  /// - Parameter input: The upstream node to process.
  init(input: Node) {
    // Stage 1: Low Pass + Dry/Wet
    lowPass = LowPassFilter(input)
    lowPass.cutoffFrequency = 10_000 as AUValue // defaultValue: 6900, range: 10 ... 22050, unit: .hertz
    lowPass.resonance = 0.0 as AUValue // defaultValue: 0, range: -20 ... 40, unit: .decibels
    lowPassMix = DryWetMixer(input, lowPass)
    lowPassMix.balance = 0.0 as AUValue // defaultValue: 0.5, range: 0.0 ... 1.0,

    // Stage 2: High Pass + Dry/Wet
    highPass = HighPassFilter(lowPassMix)
    highPass.cutoffFrequency = 30 as AUValue // defaultValue: 6900, range: 10 ... 22050, unit: .hertz
    highPass.resonance = 0.0 as AUValue // defaultValue: 0, range: -20 ... 40, unit: .decibels
    highPassMix = DryWetMixer(lowPassMix, highPass)
    highPassMix.balance = 0.0 as AUValue // defaultValue: 0.5, range: 0.0 ... 1.0,

    flanger = Flanger(highPassMix)
    flanger.frequency = 1.0 as AUValue// defaultValue: 1.0, range: 0.1 ... 10.0, unit: .hertz
    flanger.depth = 0.25 as AUValue // defaultValue: 0.25, range: 0.0 ... 1.0
    flanger.feedback = 0.25 as AUValue // defaultValue: 0.25, range: 0.0 ... 1.0
    flanger.dryWetMix = 0.5 as AUValue// defaultValue: 0.5, range: 0.0 ... 1.0
    flangerMix = DryWetMixer(highPassMix, flanger)
    flangerMix.balance = 0.0 as AUValue // defaultValue: 0.5, range: 0.0 ... 1.0,

    // Stage 4: Delay + Dry/Wet (take previous stage's mix as input)
    delay = Delay(flangerMix)
    delay.time = 0.5 as AUValue // defaultValue: 1, range: 0 ... 2.0, unit: .seconds
    delay.feedback = 50.0 as AUValue // defaultValue: 15000, range: 10 ... 22050, unit: .hertz
    delay.lowPassCutoff = 7500.0 as AUValue // defaultValue: 15000, range: 10 ... 22050, unit: .hertz
    // keep effect node fully wet; control blend via DryWetMixer
    delay.dryWetMix = 100.0 as AUValue // defaultValue: 100, range: 0.0 ... 100.0,
    delayMix = DryWetMixer(flangerMix, delay)
    delayMix.balance = 0.0 as AUValue // defaultValue: 0.5, range: 0.0 ... 1.0,

    // Stage 4: Reverb + Dry/Wet
    reverb = Reverb(delayMix)
    reverb.dryWetMix = 1.0 as AUValue // keep node fully wet; control with DryWetMixer
    reverbMix = DryWetMixer(delayMix, reverb)
    reverbMix.balance = 0.0 as AUValue // defaultValue: 0.5, range: 0.0 ... 1.0,

    // Final output of the rack is the last stage's mix
    output = reverbMix
  }

  // MARK: - XY Performance Mapping
  /// Map an XY touch and overall amount into effect parameters using a chosen mode.
  /// The 'character' property influences the intensity and extremes of parameter mappings across modes.
  /// - Parameters:
  ///   - xVal: 0.0–1.0 horizontal control.
  ///   - yVal: 0.0–1.0 vertical control.
  ///   - amount: 0.0–1.0 overall wetness sent to all stage DryWetMixers.
  ///   - mode: Selects which mapping set to apply.
  func mapXY(xVal: Double, yVal: Double, amount: Double, mode: XYMode) {
    let x = clamp01(xVal)
    let y = clamp01(yVal)
    let amt = clamp01(amount)

    // Always drive the per-stage Wet/Dry from overall amount (with subtle per-stage weighting)
    setAllMixes(overall: amt)

    switch mode {
    case .filterDelay:
      mapFilterDelay(x: x, y: y, amount: amt)
    case .highPassFlanger:
      mapHighPassFlanger(x: x, y: y, amount: amt)
    case .washVerbEcho:
      mapWashVerbEcho(x: x, y: y, amount: amt)
    case .rhythmicFlangeBandpass:
      mapRhythmicFlangeBandpass(x: x, y: y, amount: amt)
    case .resonantSweep:
      mapResonantSweep(x: x, y: y, amount: amt)
    case .tapeEcho:
      mapTapeEcho(x: x, y: y, amount: amt)
    case .gatedVerb:
      mapGatedVerb(x: x, y: y, amount: amt)
    case .subDrop:
      mapSubDrop(x: x, y: y, amount: amt)
    }
  }

  /// Mapping modes for XY performance space
  enum XYMode {
    case filterDelay
    case highPassFlanger
    case washVerbEcho
    case rhythmicFlangeBandpass
    case resonantSweep
    case tapeEcho
    case gatedVerb
    case subDrop
  }

  // MARK: - Mappers

  /// Sweeping low-pass with tempo-ish delay.
  /// x controls lowPass cutoff sweep; y controls delay time and feedback sweet spot.
  private func mapFilterDelay(x: Double, y: Double, amount: Double) {
    // Low-pass cutoff: from warm (800 Hz) to open (16 kHz)
    lowPass.cutoffFrequency = au(lerp(800.0, 16_000.0, pow(x, 0.7)))
    // Gentle resonance as we sweep for a bit of bite, scaled by character
    lowPass.resonance = au(charLerp(0.0, 8.0, x))

    // Delay: keep in musical range ~ 1/8 to 3/4 sec, increase feedback with Y, scaled by character
    delay.time = resolvedDelayTime(freeSeconds: lerp(0.125, 0.75, smooth(y)))
    delay.feedback = au(charLerp(12.0, 75.0, smooth(y)))
    delay.lowPassCutoff = au(lerp(4_000.0, 9_000.0, x))

    // Stage balances: bias more toward LP & Delay when amount is up
    lowPassMix.balance = AUValue(clamp01(amount * 0.9))
    delayMix.balance = AUValue(clamp01(amount * 0.95))
    // Keep others subtle
    highPassMix.balance = AUValue(clamp01(amount * 0.15))
    flangerMix.balance = AUValue(clamp01(amount * 0.1))
    reverbMix.balance = AUValue(clamp01(amount * 0.25))

    // Keep flanger neutral here
    flanger.depth = au(0.1)
    flanger.feedback = au(0.1)
    flanger.frequency = au(0.2)
    flanger.dryWetMix = au(0.2)

    // Reverb small room
    reverb.dryWetMix = au(0.15)
  }

  /// DJ-style high-pass sweep with flanger color.
  /// x controls HP cutoff and resonance; y controls flanger depth and feedback.
  private func mapHighPassFlanger(x: Double, y: Double, amount: Double) {
    // High-pass cutoff: from 30 Hz up to 6 kHz for aggressive thinning
    highPass.cutoffFrequency = au(lerp(30.0, 6_000.0, smooth(x)))
    highPass.resonance = au(charLerp(0.0, 10.0, smooth(x)))

    // Flanger movement increases with Y, scaled by character
    flanger.frequency = au(lerp(0.1, 1.5, 0.5 + 0.5 * smooth(y)))
    flanger.depth = au(charLerp(0.05, 1.0, smooth(y)))
    flanger.feedback = au(charLerp(0.05, 0.85, smooth(y)))
    flanger.dryWetMix = au(charLerp(0.2, 1.0, smooth(y)))

    // Delay tight and subtle to preserve clarity
    delay.time = resolvedDelayTime(freeSeconds: 0.18)
    delay.feedback = au(18.0)
    delay.lowPassCutoff = au(8_000.0)

    // Stage balances: HP & Flanger lead
    highPassMix.balance = AUValue(clamp01(amount * 0.95))
    flangerMix.balance = AUValue(clamp01(amount * 0.9))
    lowPassMix.balance = AUValue(clamp01(amount * 0.1))
    delayMix.balance = AUValue(clamp01(amount * 0.25))
    reverbMix.balance = AUValue(clamp01(amount * 0.15))

    // Reverb very light
    reverb.dryWetMix = au(0.1)
  }

  /// Wide, lush verb with echo tails; filters shape tone.
  /// x controls darker/brighter tone; y controls space and feedback.
  private func mapWashVerbEcho(x: Double, y: Double, amount: Double) {
    // Tone: combine LP and HP to form a band that opens with X
    let open = smooth(x)
    lowPass.cutoffFrequency = au(lerp(2_500.0, 15_000.0, open))
    lowPass.resonance = au(charLerp(0.0, 6.0, open))
    highPass.cutoffFrequency = au(lerp(60.0, 400.0, 1.0 - open))
    highPass.resonance = au(0.0)

    // Reverb dominates; increase wetness and size impression with Y, scaled by character
    reverb.dryWetMix = au(charLerp(0.25, 1.0, smooth(y)))

    // Delay supports the wash; slower time, higher feedback as space increases (higher y)
    delay.time = resolvedDelayTime(freeSeconds: lerp(0.35, 0.9, smooth(y)))
    delay.feedback = au(charLerp(20.0, 85.0, smooth(y)))
    delay.lowPassCutoff = au(lerp(3_500.0, 7_500.0, open))

    // Stage balances: Verb & Delay lead
    reverbMix.balance = AUValue(clamp01(amount * 0.95))
    delayMix.balance = AUValue(clamp01(amount * 0.8))
    lowPassMix.balance = AUValue(clamp01(amount * 0.35))
    highPassMix.balance = AUValue(clamp01(amount * 0.25))
    flangerMix.balance = AUValue(clamp01(amount * 0.2))

    // Flanger very gentle for shimmer
    flanger.frequency = au(0.15)
    flanger.depth = au(0.1)
    flanger.feedback = au(0.1)
    flanger.dryWetMix = au(0.15)
  }

  /// Rhythmic flanging with bandpass tone and tighter echo.
  /// x controls flanger rate and depth; y controls tightness and brightness.
  private func mapRhythmicFlangeBandpass(x: Double, y: Double, amount: Double) {
    let rate = lerp(0.2, 4.0, smooth(x))
    flanger.frequency = au(rate)
    flanger.depth = au(charLerp(0.2, 1.0, smooth(x)))
    flanger.feedback = au(charLerp(0.15, 0.85, smooth(x)))
    flanger.dryWetMix = au(lerp(0.3, 0.85, smooth(x)))

    // Create a moving band by coupling HP/LP around a mid frequency controlled by y
    let mid = lerp(600.0, 4_000.0, smooth(y))
    let bwf: Double = 0.7 // in octaves-ish; keep musical
    let lpf = min(20_000.0, mid * pow(2.0, bwf))
    let hpf = max(20.0, mid / pow(2.0, bwf))
    lowPass.cutoffFrequency = au(lpf)
    lowPass.resonance = au(2.0)
    highPass.cutoffFrequency = au(hpf)
    highPass.resonance = au(2.0)

    // Delay: shorter and snappier as y increases (toward top)
    delay.time = resolvedDelayTime(freeSeconds: lerp(0.35, 0.12, smooth(y)))
    delay.feedback = au(lerp(12.0, 40.0, smooth(y)))
    delay.lowPassCutoff = au(lerp(5_000.0, 10_000.0, smooth(x)))

    // Stage balances: Flanger & Delay lead
    flangerMix.balance = AUValue(clamp01(amount * 0.95))
    delayMix.balance = AUValue(clamp01(amount * 0.85))
    lowPassMix.balance = AUValue(clamp01(amount * 0.4))
    highPassMix.balance = AUValue(clamp01(amount * 0.4))
    reverbMix.balance = AUValue(clamp01(amount * 0.25))

    // Reverb restrained to keep rhythm tight, slightly boosted by character
    reverb.dryWetMix = au(charLerp(0.1, 0.35, 0.5))
  }

  /// Resonant LP/HP sweep morph with synced echoes.
  /// x morphs from HP emphasis to LP emphasis; y increases resonance and delay feedback.
  private func mapResonantSweep(x: Double, y: Double, amount: Double) {
    // Morph: when x=0 -> HP focus; x=1 -> LP focus; middle is band-pass-ish
    let tparam = smooth(x)
    let resBoost = charLerp(0.0, 14.0, smooth(y))
    // HP: opens when leaning left; LP: opens when leaning right
    highPass.cutoffFrequency = au(lerp(30.0, 1_000.0, 1.0 - tparam))
    lowPass.cutoffFrequency  = au(lerp(2_000.0, 16_000.0, tparam))
    highPass.resonance = au(resBoost * (1.0 - tparam))
    lowPass.resonance  = au(resBoost * tparam)

    // Delay synced, feedback grows with y and character
    delay.time = resolvedDelayTime(freeSeconds: lerp(0.18, 0.5, tparam))
    delay.feedback = au(charLerp(15.0, 85.0, smooth(y)))
    delay.lowPassCutoff = au(lerp(4_000.0, 9_000.0, tparam))

    // Stage balances
    highPassMix.balance = AUValue(clamp01(amount * (0.6 + 0.4 * (1.0 - tparam))))
    lowPassMix.balance  = AUValue(clamp01(amount * (0.6 + 0.4 * tparam)))
    delayMix.balance    = AUValue(clamp01(amount * 0.8))
    flangerMix.balance  = AUValue(clamp01(amount * 0.2))
    reverbMix.balance   = AUValue(clamp01(amount * 0.25))

    // Subtle flange for motion
    flanger.frequency = au(lerp(0.1, 0.4, tparam))
    flanger.depth = au(0.12)
    flanger.feedback = au(0.12)
    flanger.dryWetMix = au(0.2)

    reverb.dryWetMix = au(0.2)
  }

  /// Tape-style echo: wow/flutter via flanger; darker, longer repeats.
  /// x increases echo time; y increases wow/flutter depth and feedback.
  private func mapTapeEcho(x: Double, y: Double, amount: Double) {
    let tXparam = smooth(x)
    let tYparam = smooth(y)

    // Tape echo feel
    delay.time = resolvedDelayTime(freeSeconds: lerp(0.2, 0.9, tXparam))
    delay.feedback = au(charLerp(25.0, 90.0, tYparam))
    delay.lowPassCutoff = au(lerp(3_000.0, 6_500.0, 1.0 - tYparam)) // darker as y goes up

    // Wow/flutter with slow rate and depth tied to y, scaled by character
    flanger.frequency = au(lerp(0.1, 0.8, tYparam))
    flanger.depth = au(charLerp(0.05, 0.7, tYparam))
    flanger.feedback = au(0.1)
    flanger.dryWetMix = au(lerp(0.15, 0.5, tYparam))

    // Filters: gentle rolloff to taste
    lowPass.cutoffFrequency = au(lerp(8_000.0, 14_000.0, tXparam))
    lowPass.resonance = au(0.0)
    highPass.cutoffFrequency = au(lerp(40.0, 200.0, 1.0 - tXparam))
    highPass.resonance = au(0.0)

    // Stage balances
    delayMix.balance = AUValue(clamp01(amount * 0.9))
    flangerMix.balance = AUValue(clamp01(amount * 0.6))
    lowPassMix.balance = AUValue(clamp01(amount * 0.3))
    highPassMix.balance = AUValue(clamp01(amount * 0.2))
    reverbMix.balance = AUValue(clamp01(amount * 0.35))

    // Reverb for tail scaled by character
    reverb.dryWetMix = au(charLerp(0.2, 0.7, tYparam))
  }

  /// Gated reverb feel: HP/LP tighten the band; reverb opens with y and gates with amount.
  /// x widens the band; y opens reverb and adds pre-delay feel via shorter delay.
  private func mapGatedVerb(x: Double, y: Double, amount: Double) {
    let tXparam = smooth(x)
    let tYparam = smooth(y)

    // Tight band that widens with x
    let mid = lerp(800.0, 3_000.0, tXparam)
    let bw: Double = lerp(0.4, 1.2, tXparam)
    let lp = min(20_000.0, mid * pow(2.0, bw))
    let hp = max(20.0, mid / pow(2.0, bw))
    lowPass.cutoffFrequency = au(lp)
    highPass.cutoffFrequency = au(hp)
    lowPass.resonance = au(1.5)
    highPass.resonance = au(1.5)

    // Reverb opens with y; "gate" by tying stage mix to amount strongly, scaled by character
    reverb.dryWetMix = au(charLerp(0.15, 1.0, tYparam))

    // Short pre-delay style echo
    delay.time = resolvedDelayTime(freeSeconds: lerp(0.05, 0.18, 1.0 - tYparam))
    delay.feedback = au(charLerp(5.0, 35.0, tYparam))
    delay.lowPassCutoff = au(lerp(5_000.0, 9_000.0, tXparam))

    // Stage balances: strong verb gating by amount
    reverbMix.balance = AUValue(clamp01(amount * 1.0))
    delayMix.balance = AUValue(clamp01(amount * 0.5))
    lowPassMix.balance = AUValue(clamp01(amount * 0.4))
    highPassMix.balance = AUValue(clamp01(amount * 0.4))
    flangerMix.balance = AUValue(clamp01(amount * 0.2))

    // Flanger off/minimal
    flanger.frequency = au(0.2)
    flanger.depth = au(0.05)
    flanger.feedback = au(0.05)
    flanger.dryWetMix = au(0.1)
  }

  /// Sub drop build: lows come back in, highs darken, long echo builds.
  /// x restores low end (HP closes) and darkens highs (LP lowers); y increases echo length and verb.
  private func mapSubDrop(x: Double, y: Double, amount: Double) {
    let tXparam = smooth(x)
    let tYparam = smooth(y)

    // Bring back lows and darken top as x increases with character scaling on resonance
    highPass.cutoffFrequency = au(lerp(500.0, 30.0, tXparam))
    highPass.resonance = au(charLerp(4.0, 10.0, 1.0 - tXparam))
    lowPass.cutoffFrequency = au(lerp(14_000.0, 2_500.0, tXparam))
    lowPass.resonance = au(lerp(1.0, 4.0, tXparam))

    // Big echo grows with y and character
    delay.time = resolvedDelayTime(freeSeconds: lerp(0.25, 1.2, tYparam))
    delay.feedback = au(charLerp(30.0, 90.0, tYparam))
    delay.lowPassCutoff = au(lerp(4_000.0, 6_500.0, 1.0 - tYparam))

    // Reverb grows too, scaled by character
    reverb.dryWetMix = au(charLerp(0.2, 0.95, tYparam))

    // Stage balances emphasize Delay/Verb
    delayMix.balance = AUValue(clamp01(amount * 0.95))
    reverbMix.balance = AUValue(clamp01(amount * 0.85))
    lowPassMix.balance = AUValue(clamp01(amount * 0.5))
    highPassMix.balance = AUValue(clamp01(amount * 0.35))
    flangerMix.balance = AUValue(clamp01(amount * 0.25))

    // Flanger subtle for movement
    flanger.frequency = au(lerp(0.15, 0.5, tYparam))
    flanger.depth = au(0.12)
    flanger.feedback = au(0.12)
    flanger.dryWetMix = au(0.2)
  }

  // MARK: - Helpers
  /// Clamp to 0...1
  private func clamp01(_ val: Double) -> Double { max(0.0, min(1.0, val)) }

  /// Linear interpolation
  private func lerp(_ aParam: Double, _ bParam: Double, _ tParam: Double) -> Double { aParam + (bParam - aParam) * tParam }

  /// Smoothstep-like curve for more musical response
  private func smooth(_ tParam: Double) -> Double {
    let xParam = clamp01(tParam)
    return xParam * xParam * (3.0 - 2.0 * xParam)
  }
  
  /// Convert Double to AUValue
  private func au(_ vParam: Double) -> AUValue { AUValue(vParam) }

  /// Blend a range [a,b] by t, then expand by character (0 subtle ... 1 extreme)
  private func charLerp(_ aParam: Double, _ bParam: Double, _ tParam: Double) -> Double {
    let cParam = clamp01(character)
    // Interpolate base
    let base = lerp(aParam, bParam, tParam)
    // Expand toward b as character increases
    return lerp(lerp(aParam, bParam, tParam * 0.7), base, cParam)
  }

  /// Scale an amount by character to exaggerate modulation depth
  private func charScale(_ value: Double, min: Double, max: Double) -> Double {
    let cParam = clamp01(character)
    let widened = lerp(min, max, cParam)
    return value * widened
  }

  /// Set all stage DryWetMixer balances from one overall control, with gentle stage-specific weighting.
  private func setAllMixes(overall amount: Double) {
    let aParam = clamp01(amount)
    // Provide a subtle base so stages are never completely off when performing
    lowPassMix.balance = max(lowPassMix.balance, au(aParam * 0.6))
    highPassMix.balance = max(highPassMix.balance, au(aParam * 0.6))
    flangerMix.balance = max(flangerMix.balance, au(aParam * 0.6))
    delayMix.balance = max(delayMix.balance, au(aParam * 0.7))
    reverbMix.balance = max(reverbMix.balance, au(aParam * 0.7))
  }
}

// MARK: - XYMode display labels
extension EffectsRack.XYMode {
  var displayName: String {
    switch self {
    case .filterDelay: return "Filter + Delay"
    case .highPassFlanger: return "HighPass + Flanger"
    case .washVerbEcho: return "Wash Verb + Echo"
    case .rhythmicFlangeBandpass: return "Rhythmic Flange + Bandpass"
    case .resonantSweep: return "Resonant Sweep"
    case .tapeEcho: return "Tape Echo"
    case .gatedVerb: return "Gated Verb"
    case .subDrop: return "Sub Drop"
    }
  }
}

// MARK: - Extensibility Notes
// To add a new effect stage, follow the pattern:
// 1) Create the effect with the previous stage's mix as input.
// 2) Create a DryWetMixer(previousMix, effect) and expose both as properties if needed.
// 3) Update `output` to the new stage's mix.

