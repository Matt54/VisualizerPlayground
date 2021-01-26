//
//  WavetableViewExample.swift
//  VisualizerPlayground
//
//  Created by Macbook on 1/25/21.
//

import SwiftUI

struct WavetableExampleView: View{
    @EnvironmentObject var conductor: Conductor
    var body: some View{
        VStack{
            WavetableView(node: conductor.osc)
            Slider(value: $conductor.wavePosition, in: 0.0...255.0)
            Text("Wavetable Array Index Value: \(Int(conductor.wavePosition))")
                .foregroundColor(.white)
        }
        .background(Color.black)
        .navigationBarTitle(Text("WavetableView Example"), displayMode: .inline)
    }
}

struct WavetableViewExample_Previews: PreviewProvider {
    static var previews: some View {
        WavetableExampleView().environmentObject(Conductor.shared)
    }
}
