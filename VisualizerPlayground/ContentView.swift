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
                NavigationLink(destination: WavetableExampleView()){
                    Text("WavetableView Example")
                }
                NavigationLink(destination: AmplitudeExampleView()){
                    Text("AmplitudeView Example")
                }
                NavigationLink(destination: FFTExampleView()){
                    Text("FFTView Example")
                }
                NavigationLink(destination: SpectrogramExampleView()){
                    Text("SpectrogramView Example")
                }
                NavigationLink(destination: SpectrumExampleView()){
                    Text("SpectrumView Example")
                }
            }
            .navigationBarTitle("Visualizer Playground")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
