// WORK IN PROGRESS

import AudioKit
import SwiftUI

class SpectrumModel: ObservableObject {
    static let numberOfPoints = 210
    
    //@Published var amplitudes: [Double] = Array(repeating: 0.0, count: numberOfPoints)
    //@Published var frequencies: [Double] = Array(repeating: 0.0, count: numberOfPoints)
    @Published var fftDataPoints: [CGPoint] = Array(repeating: CGPoint(x: 0.0, y: 0.0), count: numberOfPoints)
    
    var nodeTap: FFTTap!
    private var FFT_SIZE = 2048
    let sampleRate : double_t = 44100
    var node: Node?
    
    var maxFreq = 20000.0
    
    func updateNode(_ node: Node) {
        if node !== self.node {
            self.node = node
            nodeTap = FFTTap(node,bufferSize: UInt32(FFT_SIZE*2)) { fftData in
                DispatchQueue.main.async {
                    //self.updateAmplitudes(Array(fftData.prefix(SpectrumModel.numberOfPoints*2)))
                    self.updateAmplitudes(fftData)
                }
            }
            nodeTap.isNormalized = false
            nodeTap.start()
            print(nodeTap.bufferSize)
            print(FFT_SIZE)
        }
    }
    
    func updateAmplitudes(_ fftFloats: [Float]) {
        
        // I don't love creating this extra array
        var fftData = fftFloats
        for index in 0..<fftData.count {
            if fftData[index].isNaN { fftData[index] = 0.0 }
        }
        
        fftDataPoints = fftDataCrunch(fftData)
        
        /*var maxAmp = -10000.0
        var maxFreq = 0.0

        // loop by two through all the fft data
        for i in stride(from: 0, to: fftData.count - 1, by: 2) {
            // get the real and imaginary parts of the complex number
            let real = fftData[i]
            let imaginary = fftData[i + 1]
            
            
            // I'm not sure if this is the right method
            //let normalizedBinMagnitude = 2.0 * sqrt(real * real + imaginary * imaginary) / Float(FFT_SIZE)
            //let amplitude = Double(20.0 * log10(normalizedBinMagnitude))
            
            // or this method
            let amplitude = Double(10 * log10(4 * (real * real + imaginary * imaginary)/(Float(FFT_SIZE) * Float(FFT_SIZE))))
            
            // this is correct - tested with an oscillator
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
        print("max freq: \(maxFreq) | max amp.: \(maxAmp)")*/
        //print(fftData.count)
    }
    
    /// Returns frequency, amplitude pairs after removing unwanted data points (there are simply too many in the high frequencies)
    func fftDataCrunch(_ fftFloats: [Float]) -> [CGPoint]{
        
        // I don't love making these extra arrays
        let real = fftFloats.indices.compactMap{$0 % 2 == 0 ? fftFloats[$0] : nil }
        let imaginary = fftFloats.indices.compactMap{$0 % 2 != 0 ? fftFloats[$0] : nil }
        
        var points : [CGPoint] = []
        
        for i in 0..<real.count {
            
            // I don't love doing this for every element
            let frequency = sampleRate * 0.5 * Double(i*2) / Double(FFT_SIZE)
            
            if frequency > maxFreq {
                continue
            }
            
            if frequency > 10000 {
                if i % 8 != 0 {
                    //reject it - we only take 1 in every 10 points when > 10k Hz.
                    continue
                }
            }
            else if frequency > 1000 {
                if i % 4 != 0 {
                    //reject it - we only take 1 in every 2 points when > 1k Hz.
                    continue
                }
            }
            
            let amplitude = Double(10 * log10(4 * (real[i] * real[i] + imaginary[i] * imaginary[i])/(Float(FFT_SIZE) * Float(FFT_SIZE))))

            points.append(CGPoint(x: frequency, y: amplitude))
        }
        
        return points
    }

}

struct SpectrumView: View {
    @StateObject var spectrum = SpectrumModel()
    private var node: Node
    
    public init(_ node: Node) {
        self.node = node
    }
    
    public var body: some View {
        GeometryReader{ geometry in
            ZStack{
                createGraph(width: geometry.size.width, height: geometry.size.height)
                createSpectrum(width: geometry.size.width, height: geometry.size.height)
                    .onAppear {
                        spectrum.updateNode(node)
                    }
                    .drawingGroup()
            }
        }
    }
    
    func createSpectrum(width: CGFloat, height: CGFloat) -> some View {
        
        let frequencies = spectrum.fftDataPoints.map(\.x)
        let amplitudes = spectrum.fftDataPoints.map(\.y)
        
        let maxAmp = amplitudes.max()! + 20.0//0.0 //spectrum.amplitudes.max()! + 10.0
        
        var minAmp = maxAmp - 150.0
        if(maxAmp - amplitudes.min()! < 140){
            minAmp = amplitudes.min()! - 10.0
        }
        let maxFreq = 20000.0
        let minFreq = 10.0
        
        var mappedPoints = Array(repeating: CGPoint(x: 0.0, y: 0.0), count: SpectrumModel.numberOfPoints)
        
        // I imagine this is not good computationally
        for i in 0..<amplitudes.count {
            let mappedAmplitude = map(n: Double(amplitudes[i]), start1: Double(minAmp), stop1: Double(maxAmp), start2: 1.0, stop2: 0.0)
            let mappedFrequency = logMap(n: Double(frequencies[i]), start1: minFreq, stop1: maxFreq, start2: 0.0, stop2: 1.0)
            mappedPoints[i] = CGPoint(x: mappedFrequency, y: mappedAmplitude)
        }
        
        return ZStack{

            //stroke
            /*Path{ path in
                path.move(to: CGPoint(x: 0, y:  height))
                
                var i = 0
                mappedPoints.forEach{ p in
                    if(p.x > 0.00001){
                        if(frequencies[i] > 1000){
                            //if(i % 2 == 0){
                                path.addLine(to: CGPoint(x: p.x * width, y: p.y * height))
                            //}
                        } else {
                            path.addLine(to: CGPoint(x: p.x * width, y: p.y * height))
                        }
                    }
                    else { // get the starting position on the y axis
                        path.addLine(to: CGPoint(x: 0, y: p.y * height))
                    }
                    i += 1
                }
                //To bottom right
                path.addLine(to: CGPoint(x: width, y: height))
                
                //To bottom Left
                path.addLine(to: CGPoint(x: 0, y: height))
                
                //To first point
                path.move(to: CGPoint(x: 0, y: height))
            }
            .stroke(Color.black, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))*/
            
            //fill
            Path{ path in
                path.move(to: CGPoint(x: 0, y:  height))
                
                var i = 0
                mappedPoints.forEach{ p in
                    
                    if(p.x > 0.00001){
                        if(frequencies[i] > 1000){
                            //if(i % 2 == 0){
                                path.addLine(to: CGPoint(x: p.x * width, y: p.y * height))
                            //}
                        } else {
                            path.addLine(to: CGPoint(x: p.x * width, y: p.y * height))
                        }
                    }
                    else { // get the starting position on the y axis
                        path.addLine(to: CGPoint(x: 0, y: p.y * height))
                    }
                    i += 1
                }
                
                //To bottom right
                path.addLine(to: CGPoint(x: width, y: height))
                
                //To bottom Left
                path.addLine(to: CGPoint(x: 0, y: height))
                
                //To first point
                path.move(to: CGPoint(x: 0, y: height))
            }
            .fill(Color(red: 0.8, green: 0.8, blue: 0.8, opacity: 0.4))
            
            //dots
            ForEach(1 ..< mappedPoints.count) {
                if(mappedPoints[$0].x > 0.00001){
                    
                    if(frequencies[$0] > 1000){
                        //if($0 % 2 == 0){ // could show half as many above 1k Hz.
                        Circle()
                            .fill(Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.8))
                            .frame(width: width * 0.005)
                            .position(CGPoint(x: mappedPoints[$0].x * width, y: mappedPoints[$0].y * height))
                            .animation(.easeInOut(duration: 0.15))
                        //}
                    } else {
                        Circle()
                            .fill(Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.8))
                            .frame(width: width * 0.005)
                            .position(CGPoint(x: mappedPoints[$0].x * width, y: mappedPoints[$0].y * height))
                            .animation(.easeInOut(duration: 0.15))
                    }
                }
            }
        }
    }
    
    func createGraph(width: CGFloat, height: CGFloat) -> some View{
        
        let maxFreq = 20000.0
        let minFreq = 10.0
        let freqs = [100.0,1000.0,10000.0]
        
        var mappedFreqs = Array(repeating: 0.0, count: freqs.count)
        
        for i in 0..<freqs.count {
            mappedFreqs[i] = logMap(n: freqs[i], start1: minFreq, stop1: maxFreq, start2: 0.0, stop2: 1.0)
        }
        
        return ZStack{
            Color.black
            
            ForEach(0 ..< mappedFreqs.count) {i in
                Path{ path in
                    path.move(to: CGPoint(x: CGFloat(mappedFreqs[i]) * width, y: 0.0))
                    path.addLine(to: CGPoint(x: CGFloat(mappedFreqs[i]) * width, y: height))
                }
                .stroke(Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.8))
            }
        }
    }
    
    func map(n: Double, start1: Double, stop1: Double, start2: Double, stop2: Double) -> Double {
        return ((n - start1) / (stop1 - start1)) * (stop2 - start2) + start2
    }
    
    func logMap(n: Double, start1: Double, stop1: Double, start2: Double, stop2: Double) -> Double {
        let logN = log10(n)
        let logStart1 = log10(start1)
        let logStop1 = log10(stop1)
        let result = ((logN - logStart1 ) / (logStop1 - logStart1)) * (stop2 - start2) + start2
        if(result.isNaN){
            return 0.1
        } else {
            return ((logN - logStart1 ) / (logStop1 - logStart1)) * (stop2 - start2) + start2
        }
    }
    
}

struct SpectrumView_Previews: PreviewProvider {
    static var previews: some View {
        SpectrumView(Mixer())
    }
}
