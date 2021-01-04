// IGNORE THIS - WORK IN PROGRESS

import AudioKit
import SwiftUI

class SpectrumModel: ObservableObject {
    @Published var amplitudes: [Double] = Array(repeating: 0.95, count: 232)
    @Published var frequencies: [Double] = Array(repeating: 0.95, count: 232)
    
    //@Published var fftDataPoints: [CGPoint] = Array(repeating: CGPoint(x: 0.95, y: 0.95), count: 50)
    
    var nodeTap: FFTTap!
    //private var FFT_SIZE = 512
    private var FFT_SIZE = 512
    let sampleRate : double_t = 44100
    
    init(_ node: Node) {
        nodeTap = FFTTap(node) { fftData in
            DispatchQueue.main.async {
                self.updateAmplitudes(fftData)
            }
        }
        //nodeTap.isNormalized = false
        nodeTap.start()
    }
    
    func updateAmplitudes(_ fftFloats: [Float]) {
        var fftData = fftFloats
        for index in 0..<fftData.count {
            if fftData[index].isNaN { fftData[index] = 0.0 }
        }
        
        var maxAmp = -10000.0
        var maxFreq = 0.0

        // loop by two through all the fft data
        for i in stride(from: 0, to: FFT_SIZE - 1, by: 2) {
            // get the real and imaginary parts of the complex number
            let real = fftData[i]
            let imaginary = fftData[i + 1]
            
            let normalizedBinMagnitude = 2.0 * sqrt(real * real + imaginary * imaginary) / Float(FFT_SIZE)
            let amplitude = Double(20.0 * log10(normalizedBinMagnitude))
            //let amplitude = Double(10 * log10(4 * (real * real + imaginary * imaginary)/(Float(FFT_SIZE) * Float(FFT_SIZE))))
            
            let frequency = sampleRate * 0.5 * Double(i) / Double(FFT_SIZE)
            
            if(i/2 < self.amplitudes.count){
                //print("bin: \(i/2) \t freq: \(frequency)\t ampl.: \(amplitude)")
                //fftDataPoints[i/2] = CGPoint(x: frequency, y: amplitude)
                amplitudes[i/2] = amplitude
                frequencies[i/2] = frequency
            }
            
            if maxAmp < amplitude {
                maxAmp = amplitude
                maxFreq = frequency
            }
            
        }
        //print("max freq: \(maxFreq) | max amp.: \(maxAmp)")
        //print(fftData.count)
        
    }

}

struct SpectrumView: View {
    @ObservedObject var spectrum: SpectrumModel
    
    public init(_ node: Node) {
        spectrum = SpectrumModel(node)
    }
    
    var linearGradient = LinearGradient(gradient: Gradient(colors: [.red, .yellow, .green]), startPoint: .top, endPoint: .center)
    var paddingFraction: CGFloat = 0.2
    var includeCaps: Bool = true
    
    public var body: some View {
        GeometryReader{ geometry in
            createSpectrum(width: geometry.size.width, height: geometry.size.height)
                .drawingGroup()
        }
    }
    
    func createSpectrum(width: CGFloat, height: CGFloat) -> some View {
        
        let maxAmp = -40.0 //spectrum.amplitudes.max()! + 10.0
        let minAmp = maxAmp - 120.0
        let maxFreq = 20000.0
        let minFreq = 0.0
        
        var mappedPoints = Array(repeating: CGPoint(x: 0.0, y: 0.0), count: 232)
        
        for i in 0..<spectrum.amplitudes.count {
            let mappedAmplitude = map(n: spectrum.amplitudes[i], start1: minAmp, stop1: maxAmp, start2: 1.0, stop2: 0.0)
            let mappedFrequency = map(n: spectrum.frequencies[i], start1: minFreq, stop1: maxFreq, start2: 0.0, stop2: 1.0)
            mappedPoints[i] = CGPoint(x: mappedFrequency, y: mappedAmplitude)
        }
        
        return ZStack{
            Color.white
            
            Path{ path in
                path.move(to: CGPoint(x: 0, y:  height))
                mappedPoints.forEach{ p in
                    path.addLine(to: CGPoint(x: p.x * width, y: p.y * height))
                }
                //To bottom right
                path.addLine(to: CGPoint(x: width, y: height))
                
                //To bottom Left
                path.addLine(to: CGPoint(x: 0, y: height))
                
                //To first point
                path.move(to: CGPoint(x: 0, y: height))
            }
            //.fill(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.5))
            .stroke(Color.black, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .animation(.easeInOut(duration: 1.0))
            
            Path{ path in
                path.move(to: CGPoint(x: 0, y:  height))
                mappedPoints.forEach{ p in
                    path.addLine(to: CGPoint(x: p.x * width, y: p.y * height))
                }
                //To bottom right
                path.addLine(to: CGPoint(x: width, y: height))
                
                //To bottom Left
                path.addLine(to: CGPoint(x: 0, y: height))
                
                //To first point
                path.move(to: CGPoint(x: 0, y: height))
            }
            //.fill(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.5))
            .fill(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.4))
            
            /*ForEach(1 ..< spectrum.amplitudes.count) {
                Circle()
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.8))
                    .frame(width: width * 0.01)
                    .position(CGPoint(x: CGFloat(mappedFrequencies[$0]) * width, y: CGFloat(mappedAmplitudes[$0]) * height))
                    .animation(.easeOut(duration: 0.15))
            }*/
        }
    }
    
    func map(n: Double, start1: Double, stop1: Double, start2: Double, stop2: Double) -> Double {
        return ((n - start1) / (stop1 - start1)) * (stop2 - start2) + start2
    }
    
}

struct SpectrumView_Previews: PreviewProvider {
    static var previews: some View {
        SpectrumView(Mixer())
    }
}
