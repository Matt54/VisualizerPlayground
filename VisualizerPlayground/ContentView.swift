//
//  ContentView.swift
//  VisualizerPlayground
//
//  Created by Matt Pfeiffer on 12/29/20.
//

import SwiftUI
import AudioKitUI

/*struct StylizedFFTView: View {
    @EnvironmentObject var conductor: Conductor
    @State var includeCaps = true
    @State var currentGradient = 0
    @State var colorGradients : [Gradient] = [Gradient(colors: [.red, .yellow, .green]),
                                              Gradient(colors: [Color.init(hex: "D16BA5"), Color.init(hex: "86A8E7"), Color.init(hex: "5FFBF1")]),
                                              Gradient(colors: [Color.init(hex: "d902ee"), Color.init(hex: "F4AF1B"), Color.init(hex: "F2BC94")])]
    var body: some View {
        FFTView(conductor.filter, linearGradient: LinearGradient(gradient: colorGradients[currentGradient], startPoint: .top, endPoint: .center) ,includeCaps: includeCaps,
                numberOfBars: 50)
            .onTapGesture {
                withAnimation{
                    if currentGradient + 1 < colorGradients.count{
                        currentGradient += 1
                    } else {
                        currentGradient = 0
                    }
                    includeCaps.toggle()
                }
            }
    }
}*/



struct ContentView: View {
    @EnvironmentObject var conductor: Conductor
    @State var includeCaps = true
    
    @State var currentGradient = 0
    @State var colorGradients : [Gradient] = [Gradient(colors: [.red, .yellow, .green]),
                                              Gradient(colors: [Color.init(hex: "D16BA5"), Color.init(hex: "86A8E7"), Color.init(hex: "5FFBF1")]),
                                              Gradient(colors: [Color.init(hex: "d902ee"), Color.init(hex: "F4AF1B"), Color.init(hex: "F2BC94")])]
    
    @State var filterLowPassPercentage : Float = 1.0
    @State var numberOfBars = 75
    
    var body: some View {
        
        return VStack{
            /*ZStack{
                Color.black
                    .edgesIgnoringSafeArea(.all)
                FFTView(conductor.filter,
                        linearGradient: LinearGradient(gradient: colorGradients[currentGradient], startPoint: .top, endPoint: .center),
                        paddingFraction: 0.0, numberOfBars: numberOfBars)
                    .onTapGesture {
                        if currentGradient + 1 < colorGradients.count{
                            currentGradient += 1
                            numberOfBars = 50
                        } else {
                            currentGradient = 0
                            numberOfBars = 100
                        }
                    }
            }*/

            SpectrumView(node: conductor.filter)
        
            Text("Low Pass Filter Cutoff = \(conductor.filter.cutoffFrequency, specifier: "%.0f") Hz.")
            Slider(value: $filterLowPassPercentage, in: 0.0...1.0, step: 0.0001)
                .onChange(of: filterLowPassPercentage, perform: { value in
                    conductor.filter.cutoffFrequency = Float(logSlider(position: value))
                    //print(conductor.filter.cutoffFrequency)
                })
            
        }
    }
    
    func logSlider(position: Float) -> Double {
        // position will be between 0 and 1.0
        let minp = 0.0;
        let maxp = 1.0;

        // The result should be between 30.0 an 20000.0
        let minv = log(30.0);
        let maxv = log(20000.0);

        // calculate adjustment factor
        let scale = (maxv-minv) / Double(maxp-minp);

        return exp(minv + scale*(Double(position)-minp));
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(Conductor.shared)
    }
}


// Extension converts Hex string to Color values
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
