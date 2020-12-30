//
//  ContentView.swift
//  VisualizerPlayground
//
//  Created by Matt Pfeiffer on 12/29/20.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var conductor: Conductor
    
    var body: some View {
        FFTView(conductor.micMixer)
            .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(Conductor.shared)
    }
}
