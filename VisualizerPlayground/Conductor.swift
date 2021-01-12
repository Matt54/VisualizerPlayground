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
    
    /// limiter to prevent excessive volume at the output - just in case, it's the music producer in me :)
    let outputLimiter : PeakLimiter
    
    let filter : LowPassFilter
    
    /// bin amplitude values (range from 0.0 to 1.0)
    //@Published var amplitudes : [Double] = Array(repeating: 0.5, count: 50)
    
    var file : AVAudioFile!
    
    var fft : FFTModel2!
    
    init(){
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
        filter = LowPassFilter(player)
        silentMixer = Mixer(filter)
        
        // route the silent Mixer to the limiter (you must always route the audio chain to AudioKit.output)
        outputLimiter = PeakLimiter(silentMixer)
        
        // set the limiter as the last node in our audio chain
        engine.output = outputLimiter
        
        //START AUDIOKIT
        do{
            //try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
            //try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            //try AudioKit.Settings.session.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try engine.start()
            //try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            filter.start()
            player.play()
            //osc.start()
        }
        catch{
            assert(false, error.localizedDescription)
        }
        
        
        /*osc.amplitude = 0.5
        osc.frequency = 500
        osc.play()*/
        //silentMixer.volume = 0.0
        fft = FFTModel2(filter)
        filter.cutoffFrequency = 20_000
        filter.resonance = 10
    }
}
