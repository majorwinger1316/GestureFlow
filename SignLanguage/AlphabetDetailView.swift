//
//  AlphabetDetailView.swift
//  newProj
//
//  Created by admin@33 on 29/01/25.
//

import SwiftUI
import AVFoundation
import Vision
import CoreML

struct AlphabetDetailView: View {
    let letter: String
    @State private var showCamera = false
    @State private var isCompleted = false
    
    var body: some View {
        VStack {
            if isCompleted {
                CompletionView(letter: letter)
            } else {
                if !showCamera {
                    LearningView(letter: letter, showCamera: $showCamera)
                } else {
                    CameraView(letter: letter, isCompleted: $isCompleted)
                }
            }
        }
        .navigationTitle("Learn \(letter)")
    }
}

struct CameraView: View {
    let letter: String
    @Binding var isCompleted: Bool
    @StateObject private var camera = CameraController()
    @State private var recognizedLetter: String = ""
    @State private var confidence: Float = 0.0
    @State private var consecutiveCorrect = 0
    private let requiredConsecutive = 3
    @State private var showHelp = false
    
    private let alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
                            "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
                            "U", "V", "W", "X", "Y", "Z"]

    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("Sign: \(letter)")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    
                    Spacer()
                    
                    Text("\(Int(confidence * 100))%")
                        .font(.title3).bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                }
                .padding()
                
                // Help button
                Button(action: { showHelp.toggle() }) {
                    Text(showHelp ? "Hide Help" : "Show Help")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                // Help image for the sign
                if showHelp {
                    Image("ASL_\(letter)")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(15)
                        .shadow(radius: 10)
                        .padding(.top, 20)
                }
                
                Spacer()
                
                Text(recognizedLetter.isEmpty ? "Show hand sign" : recognizedLetter)
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            camera.startCapture()
            camera.onRecognition = { label, conf in
                recognizedLetter = label
                confidence = conf
                
                // Assuming the model returns predictions as numbers 0 to 25
                if let predictedIndex = Int(label), predictedIndex >= 0 && predictedIndex <= 25 {
                    recognizedLetter = alphabet[predictedIndex]
                }
                
                if label == letter && conf >= 0.85 {
                    consecutiveCorrect += 1
                    if consecutiveCorrect >= requiredConsecutive {
                        DispatchQueue.main.async {
                            isCompleted = true
                        }
                    }
                } else {
                    consecutiveCorrect = 0
                }
            }
        }
        .onDisappear {
            camera.stopCapture()
        }
    }
}

class CameraController: NSObject, ObservableObject {
    let captureSession = AVCaptureSession()
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private var model: MyHandPoseClassifier_1?
    var onRecognition: ((String, Float) -> Void)?
    
    private var predictionHistory: [(String, Float)] = []
    private let historyLength = 10  // Increased history length
    private let predictionInterval: TimeInterval = 0.2  // Adjusted interval
    private var confidenceThreshold: Float = 0.8  // Higher base confidence
    private var stabilityCounter = 0
    private var lastStablePrediction: String?
    
    private var lastPredictionTime: Date? = Date()
    
    private let jointOrder: [VNHumanHandPoseObservation.JointName] = [
        .wrist,
        .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
        .indexMCP, .indexPIP, .indexDIP, .indexTip,
        .middleMCP, .middlePIP, .middleDIP, .middleTip,
        .ringMCP, .ringPIP, .ringDIP, .ringTip,
        .littleMCP, .littlePIP, .littleDIP, .littleTip
    ]
    
    override init() {
        super.init()
        setupCamera()
        setupModel()
        handPoseRequest.maximumHandCount = 1
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .medium  // Changed from .high to .medium
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else { return }
        
        try? device.lockForConfiguration()
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
        device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
        device.unlockForConfiguration()
        
        captureSession.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue", qos: .userInteractive))
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        
        // Configure output connection
        if let connection = output.connection(with: .video) {
            connection.videoOrientation = .portrait
            connection.isEnabled = true
        }
    }
    
    func startCapture() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            self?.lastPredictionTime = Date()  // Initialize the timestamp
        }
    }
    
    private func setupModel() {
        do {
            model = try MyHandPoseClassifier_1(configuration: MLModelConfiguration())
        } catch {
            print("Error loading model: \(error)")
        }
    }
    
//    func startCapture() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            if !self.captureSession.isRunning {
//                self.captureSession.startRunning()
//            }
//        }
//    }
    
    func stopCapture() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )
        
        do {
            try requestHandler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else { return }
            
            let features = try self.extractFeatures(from: observation)
            try self.classifyPose(features)
            
        } catch {
            print("Processing error: \(error)")
        }
    }
    
    private func extractFeatures(from observation: VNHumanHandPoseObservation) throws -> MLMultiArray {
            let array = try MLMultiArray(shape: [1, 3, 21] as [NSNumber], dataType: .float32)
            var validPoints = 0
            
            // Stricter hand confidence check
            guard observation.confidence > 0.5 else {
                throw NSError(domain: "HandPose", code: 1, userInfo: ["NSLocalizedDescriptionKey": "Low hand confidence"])
            }
            
            // Reference points with higher confidence
            guard let wristPoint = try? observation.recognizedPoint(.wrist),
                  let indexMCP = try? observation.recognizedPoint(.indexMCP),
                  let middleMCP = try? observation.recognizedPoint(.middleMCP),
                  let pinkyMCP = try? observation.recognizedPoint(.littleMCP),
                  wristPoint.confidence > 0.4,
                  indexMCP.confidence > 0.4,
                  middleMCP.confidence > 0.4,
                  pinkyMCP.confidence > 0.4 else {
                throw NSError(domain: "HandPose", code: 1, userInfo: ["NSLocalizedDescriptionKey": "Reference points not detected"])
            }
            
            // Calculate hand plane for 3D normalization
            let handNormal = calculateHandPlane(wrist: wristPoint.location,
                                              index: indexMCP.location,
                                              pinky: pinkyMCP.location)
            
            let handWidth = hypot(indexMCP.location.x - pinkyMCP.location.x,
                                indexMCP.location.y - pinkyMCP.location.y)
            
            let centerX = (indexMCP.location.x + pinkyMCP.location.x) / 2
            let centerY = (indexMCP.location.y + pinkyMCP.location.y) / 2
            
            for (index, joint) in jointOrder.enumerated() {
                if let point = try? observation.recognizedPoint(joint),
                   point.confidence > 0.3 {
                    validPoints += 1
                    
                    // Apply 3D normalization
                    let normalizedPoint = normalizePoint(point.location,
                                                       center: CGPoint(x: centerX, y: centerY),
                                                       handWidth: handWidth,
                                                       normal: handNormal)
                    
                    array[[0, 0, index] as [NSNumber]] = normalizedPoint.x as NSNumber
                    array[[0, 1, index] as [NSNumber]] = normalizedPoint.y as NSNumber
                    array[[0, 2, index] as [NSNumber]] = point.confidence as NSNumber
                } else {
                    array[[0, 0, index] as [NSNumber]] = 0.0
                    array[[0, 1, index] as [NSNumber]] = 0.0
                    array[[0, 2, index] as [NSNumber]] = 0.0
                }
            }
            
            guard validPoints >= 16 else {
                throw NSError(domain: "HandPose", code: 2, userInfo: ["NSLocalizedDescriptionKey": "Insufficient valid points"])
            }
            
            return array
        }
    
    private func calculateHandPlane(wrist: CGPoint, index: CGPoint, pinky: CGPoint) -> SIMD3<Float> {
        let v1 = SIMD3<Float>(Float(index.x - wrist.x),
                             Float(index.y - wrist.y),
                             0)
        let v2 = SIMD3<Float>(Float(pinky.x - wrist.x),
                             Float(pinky.y - wrist.y),
                             0)
        return normalize(cross(v1, v2))
    }
    
    private func normalizePoint(_ point: CGPoint, center: CGPoint, handWidth: CGFloat, normal: SIMD3<Float>) -> (x: Float, y: Float) {
        let dx = point.x - center.x
        let dy = point.y - center.y
        
        let normalizedX = Float(dx / handWidth)
        let normalizedY = Float(dy / handWidth)
        
        // Apply perspective correction
        let correctedX = normalizedX * (1 + abs(normal.z) * 0.2)
        let correctedY = normalizedY * (1 + abs(normal.z) * 0.2)
        
        return (correctedX, correctedY)
    }
    
    private func classifyPose(_ features: MLMultiArray) throws {
        guard let model = model,
              let lastTime = lastPredictionTime,
              Date().timeIntervalSince(lastTime) >= predictionInterval else { return }
        
        let prediction = try model.prediction(poses: features)
        let sortedPredictions = prediction.labelProbabilities.sorted { $0.value > $1.value }
        
        guard let topPrediction = sortedPredictions.first,
              Float(topPrediction.value) > confidenceThreshold else {
            stabilityCounter = 0
            return
        }
        
        predictionHistory.append((topPrediction.key, Float(topPrediction.value)))
        if predictionHistory.count > historyLength {
            predictionHistory.removeFirst()
        }
        
        let groupedPredictions = Dictionary(grouping: predictionHistory, by: { $0.0 })
        if let mostFrequent = groupedPredictions.max(by: { $0.value.count < $1.value.count }),
           mostFrequent.value.count >= 5 {
            
            let avgConfidence = mostFrequent.value.reduce(0) { $0 + $1.1 } / Float(mostFrequent.value.count)
            
            if avgConfidence > 0.85 {
                if mostFrequent.key == lastStablePrediction {
                    stabilityCounter += 1
                } else {
                    stabilityCounter = 0
                }
                
                lastStablePrediction = mostFrequent.key
                
                if stabilityCounter >= 2 {
                    DispatchQueue.main.async {
                        self.onRecognition?(mostFrequent.key, avgConfidence)
                    }
                }
            }
        }
        
        lastPredictionTime = Date()
    }
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        processFrame(sampleBuffer)
    }
}

struct CameraPreview: UIViewRepresentable {
    let camera: CameraController
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: camera.captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct LearningView: View {
    let letter: String
    @Binding var showCamera: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image("ASL_\(letter)")
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .cornerRadius(15)
                .shadow(radius: 10)
            
            Text("Learn the sign for '\(letter)'")
                .font(.title2)
                .bold()
            
            Button(action: { showCamera = true }) {
                Text("Start Practice")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                             startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct CompletionView: View {
    let letter: String
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
            
            Text("Great Job!")
                .font(.largeTitle)
                .bold()
            
            Text("You've mastered the sign for '\(letter)'")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: ContentView()) {
                Text("Back to Alphabet")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
        }
    }
}

let ASL_LABELS = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
                  "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
                  "U", "V", "W", "X", "Y", "Z", "SPACE", "NOTHING"]
