//
//  ProgressBarView.swift
//  Calendr
//
//  Created by Bellamy John on 7/10/24.
//
import Cocoa

class ProgressButtonView: NSButton {
    private let gradientLayer = CAGradientLayer()
    private let progressLayer = CALayer()
    private var progress: Double = 0.0
    private var recordingTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        setupButton()
    }
    
    private func setupLayers() {
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.masksToBounds = true
        
        gradientLayer.colors = [NSColor.green.cgColor, NSColor.yellow.cgColor, NSColor.red.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = bounds
        layer?.addSublayer(gradientLayer)
        
        progressLayer.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        progressLayer.frame = bounds
        gradientLayer.mask = progressLayer
    }
    
    private func setupButton() {
        title = "Start Recording"
        target = self
        action = #selector(buttonClicked)
    }
    
    @objc private func buttonClicked() {
        if title == "Start Recording" {
            title = "Recording..."
            startProgress()
        }
    }
    
    public func startProgress() {
        progress = 0.0
        updateProgressLayer()
        updateGradientColors()
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.progress += 1.0 / 15.0
            self.updateProgressLayer()
            
            if self.progress >= 1.0 {
                timer.invalidate()
                self.title = "Start Recording"
                self.progress = 0.0
                self.updateProgressLayer()
            } else if self.progress == 1.0 / 3.0 || self.progress == 2.0 / 3.0 {
                self.updateGradientColors()
            }
        }
    }
    
    public func updateProgressLayer() {
        progressLayer.frame.size.width = bounds.width * CGFloat(progress)
    }
    
    private func updateGradientColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        gradientLayer.colors = [NSColor.green.cgColor, NSColor.yellow.cgColor, NSColor.red.cgColor]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        CATransaction.commit()
    }
    
    override func layout() {
        super.layout()
        gradientLayer.frame = bounds
        updateProgressLayer()
    }
    
    func stopProgress() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        progress = 0.0
        updateProgressLayer()
        title = "Start Recording"
    }
}
