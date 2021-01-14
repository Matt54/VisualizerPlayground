//
//  Conductor.swift
//  VisualizerPlayground
//
//  Created by Matt Pfeiffer on 12/29/20.
//

import AudioKit
import AVFoundation
import Foundation

class Conductor : ObservableObject{
    
    /// Single shared data model
    static let shared = Conductor()
    
    /// Audio engine instance
    let engine = AudioEngine()
        
    /// default microphone
    var mic: AudioEngine.InputNode
    
    //var osc: Oscillator
    
    var player: AudioPlayer
    
    /// mixing node for microphone input - routes to plotting and recording paths
    let micMixer : Mixer
    
    /// mixer with no volume so that we don't output audio
    let silentMixer : Mixer
    
    let combinationMixer : Mixer
    
    /// limiter to prevent excessive volume at the output - just in case, it's the music producer in me :)
    let outputLimiter : PeakLimiter
    
    let filter : LowPassFilter
    
    /// bin amplitude values (range from 0.0 to 1.0)
    //@Published var amplitudes : [Double] = Array(repeating: 0.5, count: 50)
    
    var file : AVAudioFile!
    
    var fft : FFTModel2!
    
    var sampleRate : Double = AudioKit.Settings.sampleRate
    
    init(){
        
        do{
            try AudioKit.Settings.session.setCategory(.playAndRecord, options: .defaultToSpeaker)
        } catch{
            assert(false, error.localizedDescription)
        }
        
        guard let input = engine.input else {
            fatalError()
        }
        
        // setup mic
        mic = input
        micMixer = Mixer(mic)
        
        let url = URL(fileURLWithPath: Bundle.main.resourcePath! + "/track.mp3")
        do{
            file = try AVAudioFile(forReading: url)
        } catch{
            print("oh no!")
        }
        player = AudioPlayer(file: file)!
        
        /*osc = Oscillator(waveform: Table(.sawtooth))
        micMixer = Mixer(osc)*/
        silentMixer = Mixer(micMixer)
        //silentMixer.addInput(micMixer)
        
        filter = LowPassFilter(silentMixer)
        
        combinationMixer = Mixer(filter)
        combinationMixer.addInput(silentMixer)
        
        // route the silent Mixer to the limiter (you must always route the audio chain to AudioKit.output)
        outputLimiter = PeakLimiter(combinationMixer)
        
        // set the limiter as the last node in our audio chain
        engine.output = outputLimiter
        
        //START AUDIOKIT
        do{
            //try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
            //try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            //try AudioKit.Settings.session.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try engine.start()
            //try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            print("conductor.swift isRunning: " + String(engine.avEngine.isRunning))
            filter.start()
            
            //let startSampleFramePosition = player.playerNode.lastRenderTime?.sampleTime
            //let avTime = AVAudioTime(sampleTime: startSampleFramePosition!, atRate: sampleRate)
            //player.play()
            //osc.start()
        }
        catch{
            assert(false, error.localizedDescription)
        }
        
        
        /*osc.amplitude = 0.5
        osc.frequency = 500
        osc.play()*/
        combinationMixer.volume = 0.0
        fft = FFTModel2(filter)
        filter.cutoffFrequency = 20_000
        filter.resonance = 10
    }
}
