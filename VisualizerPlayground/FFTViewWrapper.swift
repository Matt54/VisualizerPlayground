//
//  FFTViewWrapper.swift
//  VisualizerPlayground
//
//  Created by Matt Pfeiffer on 1/4/21.
//

import SwiftUI

import AudioKit
import SwiftUI

/*class fftWrapper{
    var fft = FFTModel2()
}*/

public class FFTData : ObservableObject {
    @Published var amplitudes: [Double] = Array(repeating: 0.95, count: 50)
}

class FFTModel2: ObservableObject {
    //@Published var amplitudes: [Double] = Array(repeating: 0.95, count: 50)
    var fftData = FFTData()
    var nodeTap: FFTTap!
    private var FFT_SIZE = 512
    var view: FFTView2!
    var isNodeConnected = false
    
    init(){}
    
    init(_ node: Node) {
        connectNode(node)
        /*view = FFTView2(amplitudes)
        nodeTap = FFTTap(node) { fftData in
            DispatchQueue.main.async {
                self.updateAmplitudes(fftData)
            }
        }
        nodeTap.isNormalized = false
        nodeTap.start()*/
    }
    
    func connectNode(_ node: Node){
        view = FFTView2(fftData)
        nodeTap = FFTTap(node) { fftData in
            DispatchQueue.main.async {
                self.updateAmplitudes(fftData)
            }
        }
        nodeTap.isNormalized = false
        nodeTap.start()
        isNodeConnected = true
    }
    
    func updateAmplitudes(_ fftFloats: [Float]) {
        var fftData = fftFloats
        for index in 0..<fftData.count {
            if fftData[index].isNaN { fftData[index] = 0.0 }
        }
        
        //print(fftData)
        
        var tempAmplitudeArray : [Double] = []

        // loop by two through all the fft data
        for i in stride(from: 0, to: FFT_SIZE - 1, by: 2) {
            
            // only do math on the fftData we are visualizing
            if i / 2 < self.fftData.amplitudes.count {
                
                // get the real and imaginary parts of the complex number
                let real = fftData[i]
                let imaginary = fftData[i + 1]
                
                let normalizedBinMagnitude = 2.0 * sqrt(real * real + imaginary * imaginary) / Float(FFT_SIZE)
                let amplitude = Double(20.0 * log10(normalizedBinMagnitude))
                
                // scale the resulting data
                let scaledAmplitude = (amplitude + 250) / 229.80
                
                var mappedAmplitude = self.map(n: scaledAmplitude, start1: 0.8, stop1: 1.4 , start2: 0.0, stop2: 1.0)
                if(mappedAmplitude > 1.0) {
                    mappedAmplitude = 1.0
                }
                if mappedAmplitude < 0.0 {
                    mappedAmplitude = 0.0
                }
                
                tempAmplitudeArray.append(mappedAmplitude)
            }
            
            
        }
        
        // less SwiftUI update events if we swap entire array instead of changing elements of array one at a time?
        DispatchQueue.main.async {
            self.fftData.amplitudes = tempAmplitudeArray
            
            //self.view = FFTView2(self.fftData.amplitudes)
        }
        self.objectWillChange.send()
    }
    
    /// simple mapping function to scale a value to a different range
    func map(n: Double, start1: Double, stop1: Double, start2: Double, stop2: Double) -> Double {
        return ((n - start1) / (stop1 - start1)) * (stop2 - start2) + start2
    }
}

public struct FFTView2: View {
    //@ObservedObject var fft: myFFTModel
    @ObservedObject var fftData: FFTData
    //@State var amplitudes: [Double]
    private var linearGradient: LinearGradient
    private var paddingFraction: CGFloat
    private var includeCaps: Bool
    
    public init(_ fftData: FFTData,
                linearGradient: LinearGradient = LinearGradient(gradient: Gradient(colors: [.red, .yellow, .green]), startPoint: .top, endPoint: .center),
                paddingFraction: CGFloat = 0.2,
                includeCaps: Bool = true) {
        //fft = myFFTModel(node)
        self.fftData = fftData
        self.linearGradient = linearGradient
        self.paddingFraction = paddingFraction
        self.includeCaps = includeCaps
    }
    
    public var body: some View {
        HStack(spacing: 0.0) {
            ForEach(0 ..< fftData.amplitudes.count) { number in
                myAmplitudeBar(amplitude: fftData.amplitudes[number], linearGradient: linearGradient, paddingFraction: paddingFraction, includeCaps: includeCaps)
            }
        }
        .drawingGroup() // Metal powered rendering
        .background(Color.black)
    }
}

struct FFTView2_Previews: PreviewProvider {
    static var previews: some View {
        FFTView2(FFTData())
    }
}
