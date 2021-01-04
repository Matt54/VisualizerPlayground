//
//  Conductor.swift
//  VisualizerPlayground
//
//  Created by Matt Pfeiffer on 12/29/20.
//

import AudioKit
import Foundation

class Conductor : ObservableObject{
    
    /// Single shared data model
    static let shared = Conductor()
    
    /// Audio engine instance
    let engine = AudioEngine()
        
    /// default microphone
    var mic: AudioEngine.InputNode
    
    /// mixing node for microphone input - routes to plotting and recording paths
    let micMixer : Mixer
    
    /// mixer with no volume so that we don't output audio
    let silentMixer : Mixer
    
    /// limiter to prevent excessive volume at the output - just in case, it's the music producer in me :)
    let outputLimiter : PeakLimiter
    
    let filter : LowPassFilter
    
    /// bin amplitude values (range from 0.0 to 1.0)
    //@Published var amplitudes : [Double] = Array(repeating: 0.5, count: 50)
    
    init(){
        guard let input = engine.input else {
            fatalError()
        }
        
        // setup mic
        mic = input
        micMixer = Mixer(mic)
        filter = LowPassFilter(micMixer)
        silentMixer = Mixer(filter)
        
        // route the silent Mixer to the limiter (you must always route the audio chain to AudioKit.output)
        outputLimiter = PeakLimiter(silentMixer)
        
        // set the limiter as the last node in our audio chain
        engine.output = outputLimiter
        
        //START AUDIOKIT
        do{
            try engine.start()
        }
        catch{
            assert(false, error.localizedDescription)
        }

        filter.start()
        silentMixer.volume = 0.0
        
    }
}
