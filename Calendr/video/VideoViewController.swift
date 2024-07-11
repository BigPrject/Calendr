//
//  VideoViewController.swift
//  Calendr
//
//  Created by Bellamy John on 7/10/24.
//


import Cocoa
import AVFoundation

class VideoViewController: NSViewController {
    private var captureSession: AVCap  ureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private var movieOutput = AVCaptureMovieFileOutput()
        private var recordingTimer: Timer?
    
    private let startBtn = NSButton(title: "Start Recording", target: nil, action: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkPermissions()
    }
    
    private func setupUI() {
        view.addSubview(startBtn)
        
        startBtn.target = self
        startBtn.action = #selector(startRecording)
        
        
        startBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            startBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
        ])
    }
    
    private func checkPermissions() {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch (videoStatus, audioStatus) {
        case (.authorized, .authorized):
            setupCaptureSession()
        case (.notDetermined, _), (_, .notDetermined):
            requestPermissions()
        default:
            DispatchQueue.main.async {
                self.showPermissionDeniedAlert()
            }
        }
    }
    
    private func requestPermissions() {
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                DispatchQueue.main.async {
                    self.showPermissionDeniedAlert()
                }
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if !granted {
                DispatchQueue.main.async {
                    self.showPermissionDeniedAlert()
                }
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.checkPermissions()
        }
    }
    
    private func showPermissionDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Permission Denied"
        alert.informativeText = "Calendr needs access to your camera and microphone to record video. Please grant access in System Preferences."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
        self.dismiss(self)
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        
        guard let camera = AVCaptureDevice.default(for: .video) else {
            print("Unable to access camera")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("Unable to add video input")
                return
            }
            
            if captureSession.canAddOutput(movieOutput) {
                captureSession.addOutput(movieOutput)
            } else {
                print("Unable to add movie output")
                return
            }
            
            setupPreviewLayer()
        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
        }
    }
    
    private func setupPreviewLayer() {
        guard let captureSession = captureSession else { return }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        
        if let previewLayer = previewLayer {
            view.layer = CALayer()
            view.layer?.addSublayer(previewLayer)
        }
        
        previewLayer?.frame = view.bounds
        
        captureSession.startRunning()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
                previewLayer?.frame = view.bounds
    }
    
    @objc private func startRecording() {
        let fileManager = FileManager.default

        // Get the current date components
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let yearString = dateFormatter.string(from: Date())

        dateFormatter.dateFormat = "MM"
        let monthString = dateFormatter.string(from: Date())

        dateFormatter.dateFormat = "MM--dd--yyyy"
        let fileNameDate = dateFormatter.string(from: Date())

        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let baseFolderPath = documentsPath.appendingPathComponent("calendr video blogs")
        let yearFolderPath = baseFolderPath.appendingPathComponent(yearString)
        let monthFolderPath = yearFolderPath.appendingPathComponent(monthString)

        do {
            try fileManager.createDirectory(at: monthFolderPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating directories: \(error.localizedDescription)")
            return
        }

        let filePath = monthFolderPath.appendingPathComponent("\(fileNameDate).mov")
        
        // Debugging output
        print("Recording to file: \(filePath.path)")

        if fileManager.fileExists(atPath: filePath.path) {
            do {
                try fileManager.removeItem(at: filePath)
            } catch {
                print("Error removing existing file: \(error.localizedDescription)")
                return
            }
        }

        movieOutput.startRecording(to: filePath, recordingDelegate: self)
        startBtn.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                self.stopRecording()
            self.startBtn.title = "Done recording"
            
            
            }
    }
    
    @objc private func stopRecording() {
        movieOutput.stopRecording()
        startBtn.isEnabled = true
    }
}

extension VideoViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription) (code: \((error as NSError).code))")
        } else {
            print("Video recording completed: \(outputFileURL.path)")
            // Here you could implement logic to save or link the video to a calendar event
        }
        
        // Update UI or perform any necessary actions after recording is complete
        DispatchQueue.main.async {
            self.startBtn.isEnabled = true
        }
    }
}
