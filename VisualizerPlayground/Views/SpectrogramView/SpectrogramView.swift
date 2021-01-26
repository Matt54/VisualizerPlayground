//
//  SpectrogramView.swift
//  VisualizerPlayground
//
//  Created by Macbook on 1/21/21.
//

import SwiftUI
import AudioKit

/*struct Queue<T> {
    var items:[T] = []
    
    mutating func enqueue(element: T) {
        items.append(element)
    }
    mutating func dequeue() -> T? {
        if items.isEmpty {
            return nil
        } else {
            let tempElement = items.first
            items.remove(at: 0)
            return tempElement
        }
    }
}*/

struct Queue {
    var items:[[CGPoint]] = []
    
    mutating func enqueue(element: [CGPoint]) {
        items.append(element)
    }
    mutating func dequeue() -> [CGPoint]? {
        if items.isEmpty {
            return nil
        } else {
            let tempElement = items.first
            items.remove(at: 0)
            return tempElement
        }
    }
}

func createTestData() -> Queue{
    var queue = Queue()
    for _ in 0...19 {
        var points : [CGPoint] = []
        for i in 0..<SpectrogramModel.numberOfPoints {
            // I don't love doing this for every element
            let frequency = 44100 * 0.5 * Double(i*2) / Double(2048)
            let amplitude = CGFloat.random(in: -200.0...0.0)
            points.append(CGPoint(x: CGFloat(frequency),y: amplitude))
        }
        queue.enqueue(element: points)
    }
    return queue
}

// MARK: SpectrogramModel
class SpectrogramModel: ObservableObject {
    static let numberOfPoints = 210
    
    @Published var fftDataReadings = createTestData() //Queue()// Queue<[CGPoint]>()
    
    /*init(){
        createTestData()
    }*/
    
    /*@Published var amplitudes: [CGFloat] = Array(repeating: 0.0, count: numberOfPoints)
    @Published var frequencies: [CGFloat] = Array(repeating: 0.0, count: numberOfPoints)*/
    
    var nodeTap: FFTTap!
    private var FFT_SIZE = 2048
    let sampleRate : double_t = 44100
    var node: Node?
    
    /*var minDeadBand: CGFloat = 40.0
    var maxDeadBand: CGFloat = 40.0
    var currentMidAmp: CGFloat = 100.0*/
    
    var minFreq = 30.0
    var maxFreq = 20000.0
    
    /*var minAmp: CGFloat = -1.0
    var maxAmp: CGFloat = -1_000.0
    var topAmp: CGFloat = -60.0
    var bottomAmp: CGFloat = -216.0
    var ampDisplacement: CGFloat = 120.0 / 2.0
    let maxSpan: CGFloat = 170*/
    
    func updateNode(_ node: Node) {
        if node !== self.node {
            self.node = node
            nodeTap = FFTTap(node,bufferSize: UInt32(FFT_SIZE*2)) { fftData in
                DispatchQueue.main.async {
                    self.pushData(fftData)
                }
            }
            nodeTap.isNormalized = false
            nodeTap.start()
        }
    }
    
    func pushData(_ fftFloats: [Float]) {
        // validate data
        // extra array necessary?
        var fftData = fftFloats
        for index in 0..<fftData.count {
            if fftData[index].isNaN { fftData[index] = 0.0 }
        }
        
        captureAmplitudeFrequencyData(fftData)
        //determineAmplitudeBounds()
    }
    
    /// Returns frequency, amplitude pairs after removing unwanted data points (there are simply too many in the high frequencies)
    func captureAmplitudeFrequencyData(_ fftFloats: [Float]){
        
        // I don't love making these extra arrays
        let real = fftFloats.indices.compactMap{$0 % 2 == 0 ? fftFloats[$0] : nil }
        let imaginary = fftFloats.indices.compactMap{$0 % 2 != 0 ? fftFloats[$0] : nil }
        
        var maxSquared : Float = 0.0
        var frequencyChosen = 0.0
        
        /*var tempAmplitudes : [CGFloat] = []
        var tempFrequencies : [CGFloat] = []*/
        var points: [CGPoint] = []
        
        var minAmplitude = -1.0
        var maxAmplitude = -1_000.0
        
        for i in 0..<real.count {
            
            // I don't love doing this for every element
            let frequencyForBin = sampleRate * 0.5 * Double(i*2) / Double(FFT_SIZE)
            
            var squared = real[i] * real[i] + imaginary[i] * imaginary[i]
            
            if frequencyForBin > maxFreq {
                continue
            }
            
            if frequencyForBin > 10000 {
                if squared > maxSquared {
                    maxSquared = squared
                    frequencyChosen = frequencyForBin
                }
                if i % 8 != 0 {
                    // take the greatest 1 in every 8 points when > 10k Hz.
                    continue
                } else {
                    squared = maxSquared
                    maxSquared = 0.0
                }
            }
            else if frequencyForBin > 1000 {
                if squared > maxSquared {
                    maxSquared = squared
                    frequencyChosen = frequencyForBin
                }
                if i % 4 != 0 {
                    // take the greatest 1 in every 4 points when > 1k Hz.
                    continue
                } else {
                    squared = maxSquared
                    maxSquared = 0.0
                }
            } else {
                frequencyChosen = frequencyForBin
            }
            
            let amplitude = Double(10 * log10(4 * (squared)/(Float(FFT_SIZE) * Float(FFT_SIZE))))

            if amplitude > maxAmplitude {
                maxAmplitude = amplitude
            } else if amplitude < minAmplitude {
                minAmplitude = amplitude
            }
            
            points.append(CGPoint(x: frequencyChosen, y: amplitude))
            
            //tempAmplitudes.append(CGFloat(amplitude))
            //tempFrequencies.append(CGFloat(frequencyChosen))
        }
        addFFTDataToQueue(points: points)
        /*amplitudes = tempAmplitudes
        frequencies = tempFrequencies
        minAmp = CGFloat(minAmplitude)
        maxAmp = CGFloat(maxAmplitude)*/
    }
    
    func addFFTDataToQueue(points: [CGPoint]) {
        fftDataReadings.dequeue()
        fftDataReadings.enqueue(element: points)
    }
    
    /// Figures out what we should use for the maximum and minimum amplitudes displayed - also sets a "mid" amp which the dead band lies around
    /*func determineAmplitudeBounds(){
        if maxDeadBand < abs(maxAmp - currentMidAmp) ||  minDeadBand < abs(maxAmp - currentMidAmp) {
            // place us at a new location
            if abs(maxAmp) < ampDisplacement {
                currentMidAmp = -ampDisplacement
            } else {
                currentMidAmp = maxAmp
            }
            topAmp = currentMidAmp + ampDisplacement
            bottomAmp = currentMidAmp - ampDisplacement
            if bottomAmp > minAmp {
                if topAmp - minAmp > maxSpan {
                    bottomAmp = topAmp - maxSpan
                }
                else {
                    bottomAmp = minAmp
                }
            }
        }
        
    }*/

}


struct SpectrogramView: View {
    @StateObject var spectrogram = SpectrogramModel()
    var node: Node
    
    var linearGradient : LinearGradient = LinearGradient(gradient: Gradient(colors: [.blue, .green, .yellow, .red]), startPoint: .bottom, endPoint: .top)
    @State var strokeColor : Color = Color.white.opacity(0.5)
    @State var fillColor : Color = Color.green.opacity(1.0)
    @State var backgroundColor: Color = Color.black
    
    var body: some View {
        
        let xOffset = CGFloat(0.25) / CGFloat(spectrogram.fftDataReadings.items.count)
        let yOffset = CGFloat(-0.85) / CGFloat(spectrogram.fftDataReadings.items.count)
        
        return GeometryReader { geometry in
            ZStack{
                backgroundColor
                /*createWave(width: geometry.size.width, height: geometry.size.height, points: spectrogram.fftDataReadings.items[0])*/
                
                ForEach((0 ..< (spectrogram.fftDataReadings.items.count)).reversed(), id: \.self) { i in
                     Group{
                         createWave(width: geometry.size.width * 0.75, height: geometry.size.height * 0.2, points: spectrogram.fftDataReadings.items[i])
                                 .frame(width: geometry.size.width * 0.5,
                                        height: geometry.size.height * 0.2)
                            .offset(x: CGFloat(i) * geometry.size.width * xOffset - geometry.size.width/4.0,
                                    y: CGFloat(i) * geometry.size.height * yOffset + geometry.size.height/2.5)
                    }
                 }
                 
                 /*
                 ForEach((1...spectrogram.fftDataReadings.items.indices), id: \.self) {index in
                    createWave(width: geometry.size.width, height: geometry.size.height, points: spectrogram.fftDataReadings.items[index])
                }*/
            }
            .onAppear {
                spectrogram.updateNode(node)
            }
            .drawingGroup()
        }
        
    }
    
    func createWave(width: CGFloat, height: CGFloat, points: [CGPoint]) -> some View {
        
        var mappedPoints : [CGPoint] = []
        
        let startY = map(n: Double(points[0].y), start1: -200.0, stop1: 0.0, start2: Double(height), stop2: 0.0)
        
        mappedPoints.append(CGPoint(x: 0.0,y: startY))
        for i in 0..<points.count {
            let x = logMap(n: Double(points[i].x), start1: 30.0, stop1: 20_000, start2: 0.0, stop2: Double(width))
            var y = map(n: Double(points[i].y), start1: -200.0, stop1: 0.0, start2: Double(height), stop2: 0.0)
            
            if x > 0.0 {
                if y > Double(height) {
                    y = Double(height)
                }
                mappedPoints.append(CGPoint(x: x, y: y))
            }
            
        }
        mappedPoints.append(CGPoint(x: Double(width),y: Double(height)))
        mappedPoints.append(CGPoint(x: 0.0,y: Double(height)))
        /*mappedPoints.append(CGPoint(x: Double(width)*0.99,y: Double(height*0.5)))
        mappedPoints.append(CGPoint(x: Double(width)*0.01,y: Double(height*0.5)))*/
        
        return ZStack{
           
            Path{ path in
                path.addLines(mappedPoints)
            }
            .fill(linearGradient)
            
            Path{ path in
                path.addLines(mappedPoints)
            }
            .stroke(strokeColor,lineWidth: 1)
        }
    }
    
}

struct SpectrogramView_Previews: PreviewProvider {
    static var previews: some View {
        SpectrogramView(node: Mixer())
    }
}
