//
//  ContentView.swift
//  VisualizerPlayground
//
//  Created by Matt Pfeiffer on 12/29/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        return NavigationView{
            List{
                NavigationLink(destination: FFTExampleView()){
                    Image(systemName: "chart.bar.xaxis")
                    Text("FFT View")
                }
                NavigationLink(destination: SpectrumExampleView()){
                    Image(systemName: "wave.3.right.circle")
                    Text("Spectrum View")
                }
                NavigationLink(destination: FilterExampleView()){
                    Image(systemName: "f.circle")
                    Text("Filter View")
                }
                NavigationLink(destination: SpectrogramExampleView()){
                    Image(systemName: "square.stack.3d.down.right")
                    Text("Spectrogram View")
                }
                NavigationLink(destination: AmplitudeExampleView()){
                    Image(systemName: "speaker.wave.3")
                    Text("Amplitude View")
                }
                NavigationLink(destination: WavetableExampleView()){
                    Image(systemName: "waveform.path.ecg.rectangle")
                    Text("Wavetable View")
                }
            }
            .navigationBarTitle("AudioKitUI")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
