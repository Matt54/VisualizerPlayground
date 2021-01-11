// WORK IN PROGRESS

import AudioKit
import SwiftUI

class SpectrumModel: ObservableObject {
    static let numberOfPoints = 372
    
    @Published var amplitudes: [CGFloat] = Array(repeating: 0.0, count: numberOfPoints)
    @Published var frequencies: [CGFloat] = Array(repeating: 0.0, count: numberOfPoints)
    //@Published var fftDataPoints: [CGPoint] = Array(repeating: CGPoint(x: 0.0, y: 0.0), count: numberOfPoints)
    
    var nodeTap: FFTTap!
    private var FFT_SIZE = 2048
    let sampleRate : double_t = 44100
    var node: Node?
    var minDeadBand: CGFloat = 40.0
    var maxDeadBand: CGFloat = 40.0
    var currentMidAmp: CGFloat = 100.0
    
    var minFreq = 30.0
    var maxFreq = 20000.0
    
    var minAmp: CGFloat = -1.0
    var maxAmp: CGFloat = -1_000.0
    var topAmp: CGFloat = -60.0
    var bottomAmp: CGFloat = -216.0
    var ampDisplacement: CGFloat = 120.0 / 2.0
    
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
        
        captureData(fftData)
 
    }
    
    /// Returns frequency, amplitude pairs after removing unwanted data points (there are simply too many in the high frequencies)
    func captureData(_ fftFloats: [Float]){
        
        // I don't love making these extra arrays
        let real = fftFloats.indices.compactMap{$0 % 2 == 0 ? fftFloats[$0] : nil }
        let imaginary = fftFloats.indices.compactMap{$0 % 2 != 0 ? fftFloats[$0] : nil }
        
        var maxSquared : Float = 0.0
        var frequencyChosen = 0.0
        
        var tempAmplitudes : [CGFloat] = []
        var tempFrequencies : [CGFloat] = []
        
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
                if i % 4 != 0 {
                    // take the greatest 1 in every 4 points when > 10k Hz.
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
                if i % 2 != 0 {
                    // take the greatest 1 in every 2 points when > 1k Hz.
                    continue
                } else {
                    squared = maxSquared
                    maxSquared = 0.0
                }
            } else {
                frequencyChosen = frequencyForBin
            }
            
            let amplitude = Double(10 * log10(4 * (squared)/(Float(FFT_SIZE) * Float(FFT_SIZE))))
            //let amplitude = Double(10 * log10(4 * (real[i] * real[i] + imaginary[i] * imaginary[i])/(Float(FFT_SIZE) * Float(FFT_SIZE))))

            if amplitude > maxAmplitude {
                maxAmplitude = amplitude
            } else if amplitude < minAmplitude {
                minAmplitude = amplitude
            }
            
            tempAmplitudes.append(CGFloat(amplitude))
            tempFrequencies.append(CGFloat(frequencyChosen))
        }
        
        amplitudes = tempAmplitudes
        frequencies = tempFrequencies
        minAmp = CGFloat(minAmplitude)
        maxAmp = CGFloat(maxAmplitude)
        
        if maxDeadBand < abs(maxAmp - currentMidAmp) ||  minDeadBand < abs(maxAmp - currentMidAmp) {
            // place us at a new location
            if abs(maxAmp) < ampDisplacement {
                currentMidAmp = -ampDisplacement
            } else {
                currentMidAmp = maxAmp// - minDeadBand
            }
            topAmp = currentMidAmp + ampDisplacement
            bottomAmp = currentMidAmp - ampDisplacement
            if bottomAmp > minAmp {
                bottomAmp = minAmp
            }
        }

        
        
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
            calculateGraph(width: geometry.size.width, height: geometry.size.height)
                .drawingGroup()
                .onAppear {
                    spectrum.updateNode(node)
                }
        }
    }
    
    func calculateGraph(width: CGFloat, height: CGFloat) -> some View {
        return ZStack{
            Color.black
            createHorizontalAxis(width: width, height: height)
            createVerticalAxis(width: width, height: height)//, minAmp: minY, maxAmp: maxY)
            createSpectrum(width: width, height: height)//, minAmp: minY, maxAmp: maxY, frequencies: spectrum.frequencies, amplitudes: spectrum.amplitudes)
        }
    }
    
    func createHorizontalAxis(width: CGFloat, height: CGFloat) -> some View{
        
        //let maxFreq = 20000.0
        //let minFreq = 10.0
        let freqs = [100.0,1000.0,10000.0]
        let freqStrings = ["100","1k","10k"]
        
        var mappedFreqs : [CGFloat] = Array(repeating: 0.0, count: freqs.count)
        
        for i in 0..<freqs.count {
            mappedFreqs[i] = CGFloat(logMap(n: freqs[i], start1: spectrum.minFreq, stop1: spectrum.maxFreq, start2: 0.0, stop2: 1.0))
        }
        
        return ZStack{
            ForEach(0 ..< mappedFreqs.count) {i in
                Path{ path in
                    path.move(to: CGPoint(x: mappedFreqs[i] * width, y: 0.0))
                    path.addLine(to: CGPoint(x: mappedFreqs[i] * width, y: height))
                }
                .stroke(Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.8))

                Text(freqStrings[i])
                    .font(.footnote)
                    .foregroundColor(.white)
                    .position(x: mappedFreqs[i] * width + width * 0.02, y: height * 0.03)
            }
        }
    }
    
    func createVerticalAxis(width: CGFloat, height: CGFloat) -> some View {

        var axisLocations: [CGFloat] = []
        for i in 1...20 {
            let amp : CGFloat = CGFloat(i) * -12.0
            if i % 2 != 0 {
                axisLocations.append(amp)
            }
        }
        
        var mappedAxisLocations:[CGFloat] = Array(repeating: 0.0, count: axisLocations.count)
        var locationData : [HorizontalLineData] = []
        
        for i in 0..<axisLocations.count {
            mappedAxisLocations[i] = map(n: axisLocations[i], start1: spectrum.bottomAmp, stop1: spectrum.topAmp, start2: 1.0, stop2: 0.0)
            locationData.append(HorizontalLineData(yLoc: Double(mappedAxisLocations[i])))
        }
        
        return ZStack{
            ForEach(0 ..< mappedAxisLocations.count) {i in
                if mappedAxisLocations[i] > 0.0 && mappedAxisLocations[i] < 1.0 {
                    
                    MorphableShape(controlPoints: AnimatableVector(with: locationData[i].locationData))
                        .stroke(Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.4))
                        .animation(.easeInOut(duration: 0.2))
                    
                    /*Path{ path in
                        path.move(to: CGPoint(x: 0.0,y: mappedAxisLocations[i] * height))
                        path.addLine(to: CGPoint(x: width, y: mappedAxisLocations[i] * height))
                    }
                    .stroke(Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 0.8))*/
                    
                    let labelString = String(Int(axisLocations[i]))
                    Text(labelString)
                        .position(x: width * 0.03, y: mappedAxisLocations[i] * height - height * 0.03)
                        .animation(.easeInOut(duration: 0.2))
                        .font(.footnote)
                        .foregroundColor(.white)
                        //.background(Color.black)
                }
            }
        }
    }
    
    func createSpectrum(width: CGFloat, height: CGFloat) -> some View {
        
        /*let frequencies = spectrum.fftDataPoints.map(\.x)
        let amplitudes = spectrum.fftDataPoints.map(\.y)
        
        var maxAmp = amplitudes.max()! //+ 10.0//0.0 //spectrum.amplitudes.max()! + 10.0
        var minAmp = amplitudes.min()!
        //let span = maxAmp - minAmp
        
        // make sure we have enough room to fit
        let ampHeight: CGFloat = 150.0
        
        let yDisplacement = ampHeight/2.0
        
        let midAmp = spectrum.currentMidAmp
        
        // place us at a new location if neccesary
        if spectrum.maxDeadBand < abs(maxAmp - midAmp) {
            if spectrum.minDeadBand < abs(minAmp - midAmp) {
                if abs(maxAmp) < yDisplacement {
                    spectrum.currentMidAmp = -yDisplacement
                } else {
                    spectrum.currentMidAmp = maxAmp - (spectrum.maxDeadBand - spectrum.minDeadBand)
                }
            }
        }

        maxAmp = spectrum.currentMidAmp + yDisplacement
        minAmp = spectrum.currentMidAmp - yDisplacement*/
        
        /*if(maxAmp - amplitudes.min()! < 190){
            minAmp =  - 10.0
        }*/
        //let maxFreq = 20000.0
        //let minFreq = 10.0
        
        var mappedPoints = Array(repeating: CGPoint(x: 0.0, y: 0.0), count: SpectrumModel.numberOfPoints)
        var mappedIndexedDoubles: [Double] = Array(repeating: 0.0, count: SpectrumModel.numberOfPoints*2 + 4)
        
        // I imagine this is not good computationally
        for i in 0..<spectrum.amplitudes.count {
            let mappedAmplitude = map(n: Double(spectrum.amplitudes[i]), start1: Double(spectrum.bottomAmp), stop1: Double(spectrum.topAmp), start2: 1.0, stop2: 0.0)
            let mappedFrequency = logMap(n: Double(spectrum.frequencies[i]), start1: spectrum.minFreq, stop1: spectrum.maxFreq, start2: 0.0, stop2: 1.0)
            mappedPoints[i] = CGPoint(x: mappedFrequency, y: mappedAmplitude)
            
            if mappedFrequency > 0.0 && mappedFrequency < 1.0{
                mappedIndexedDoubles[2*i] = mappedFrequency
            }
            mappedIndexedDoubles[2*i+1] = mappedAmplitude
        }
        
        mappedIndexedDoubles[SpectrumModel.numberOfPoints*2 - 4] = 1.0
        mappedIndexedDoubles[SpectrumModel.numberOfPoints*2 - 3] = 1.0
        mappedIndexedDoubles[SpectrumModel.numberOfPoints*2 - 2] = 0.0
        mappedIndexedDoubles[SpectrumModel.numberOfPoints*2 - 1] = 1.0
        
        return ZStack{
            
            //createVerticalAxis(width: width, height: height, minAmp: minAmp, maxAmp: maxAmp)
            
            MorphableShape(controlPoints: AnimatableVector(with: mappedIndexedDoubles))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                .animation(.easeInOut(duration: 0.1))
            
            MorphableShape(controlPoints: AnimatableVector(with: mappedIndexedDoubles))
                .fill(Color(red: 0.8, green: 0.8, blue: 0.8, opacity: 0.4))
                .animation(.easeInOut(duration: 0.1))

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
            .stroke(Color.white, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))*/
            
            //fill
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
            .fill(Color(red: 0.8, green: 0.8, blue: 0.8, opacity: 0.4))*/
            
            //dots
            /*ForEach(1 ..< mappedPoints.count) {
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
            }*/
        }
    }
    
    
    
    func map(n: Double, start1: Double, stop1: Double, start2: Double, stop2: Double) -> Double {
        return ((n - start1) / (stop1 - start1)) * (stop2 - start2) + start2
    }
    
    func map(n: CGFloat, start1: CGFloat, stop1: CGFloat, start2: CGFloat, stop2: CGFloat) -> CGFloat {
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

struct HorizontalLineData{
    let locationData : [Double]
    
    init(yLoc: Double){
        locationData = [0.0, yLoc, 1.0, yLoc]
    }
}

// MARK: MorphableShape
struct MorphableShape: Shape {
    var controlPoints: AnimatableVector
    
    var animatableData: AnimatableVector {
        set { self.controlPoints = newValue }
        get { return self.controlPoints }
    }
    
    func point(x: Double, y: Double, rect: CGRect) -> CGPoint {
        // vector values are expected to by in the range of 0...1
        return CGPoint(x: Double(rect.width)*x, y: Double(rect.height)*y)
    }
    
    func path(in rect: CGRect) -> Path {
        return Path { path in
            
            path.move(to: self.point(x: self.controlPoints.values[0],
                                     y: self.controlPoints.values[1], rect: rect))
            
            var i = 2;
            while i < self.controlPoints.values.count-1 {
                path.addLine(to:  self.point(x: self.controlPoints.values[i],
                                             y: self.controlPoints.values[i+1], rect: rect))
                i += 2;
            }
        }
    }
}

extension Path {
    // return point at the curve
    func point(at offset: CGFloat) -> CGPoint {
        let limitedOffset = min(max(offset, 0), 1)
        guard limitedOffset > 0 else { return cgPath.currentPoint }
        return trimmedPath(from: 0, to: limitedOffset).cgPath.currentPoint
    }
    
    // return control points along the path
    func controlPoints(count: Int) -> AnimatableVector {
        var retPoints = [Double]()
        for index in 0..<count {
            let pathOffset = Double(index)/Double(count)
            let pathPoint = self.point(at: CGFloat(pathOffset))
            retPoints.append(Double(pathPoint.x))
            retPoints.append(Double(pathPoint.y))
        }
        return AnimatableVector(with: retPoints)
    }
}

// MARK: AnimatableVector
struct AnimatableVector: VectorArithmetic {
    
    var values: [Double] // vector values
    
    init(count: Int = 1) {
        self.values = [Double](repeating: 0.0, count: count)
        self.magnitudeSquared = 0.0
    }
    
    init(with values: [Double]) {
        self.values = values
        self.magnitudeSquared = 0
        self.recomputeMagnitude()
    }
    
    func computeMagnitude()->Double {
        // compute square magnitued of the vector
        // = sum of all squared values
        var sum: Double = 0.0
        
        for index in 0..<self.values.count {
            sum += self.values[index]*self.values[index]
        }
        
        return Double(sum)
    }
    
    mutating func recomputeMagnitude(){
        self.magnitudeSquared = self.computeMagnitude()
    }
    
    // MARK: VectorArithmetic
    var magnitudeSquared: Double // squared magnitude of the vector
    
    mutating func scale(by rhs: Double) {
        // scale vector with a scalar
        // = each value is multiplied by rhs
        for index in 0..<values.count {
            values[index] *= rhs
        }
        self.magnitudeSquared = self.computeMagnitude()
    }
    
    // MARK: AdditiveArithmetic
    
    // zero is identity element for aditions
    // = all values are zero
    static var zero: AnimatableVector = AnimatableVector()
    
    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        var retValues = [Double]()
        
        for index in 0..<min(lhs.values.count, rhs.values.count) {
            retValues.append(lhs.values[index] + rhs.values[index])
        }
        
        return AnimatableVector(with: retValues)
    }
    
    static func += (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        for index in 0..<min(lhs.values.count,rhs.values.count)  {
            lhs.values[index] += rhs.values[index]
        }
        lhs.recomputeMagnitude()
    }

    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        var retValues = [Double]()
        
        for index in 0..<min(lhs.values.count, rhs.values.count) {
            retValues.append(lhs.values[index] - rhs.values[index])
        }
        
        return AnimatableVector(with: retValues)
    }
    
    static func -= (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        for index in 0..<min(lhs.values.count,rhs.values.count)  {
            lhs.values[index] -= rhs.values[index]
        }
        lhs.recomputeMagnitude()
    }
}
