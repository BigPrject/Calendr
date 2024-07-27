//
//  VideoPlayController.swift
//  Calendr
//
//  Created by Bellamy John on 7/25/24.
//
import Cocoa
import AVKit
import AVFoundation

class VideoPlayController: NSViewController {
    private var videoDate: Date

    
    init(date: Date) {
        self.videoDate = date
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        playVideo()
    }

    private func playVideo() {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let yearString = dateFormatter.string(from: videoDate)

        dateFormatter.dateFormat = "MM"
        let monthString = dateFormatter.string(from: videoDate)

        dateFormatter.dateFormat = "MM-dd-yyyy"
        let fileNameDate = dateFormatter.string(from: videoDate)

        let baseFolderPath = documentsPath.appendingPathComponent("calendr video blogs")
        let yearFolderPath = baseFolderPath.appendingPathComponent(yearString)
        let monthFolderPath = yearFolderPath.appendingPathComponent(monthString)
        let videoURL = monthFolderPath.appendingPathComponent("\(fileNameDate).mov")

        if fileManager.fileExists(atPath: videoURL.path) {
            let player = AVPlayer(url: videoURL)
            let playerView = AVPlayerView()
            playerView.player = player

            self.view.addSubview(playerView)
            playerView.frame = self.view.bounds

            player.play()
        } else {
            let alert = NSAlert()
            alert.messageText = "Video Not Found"
            alert.informativeText = "The video for \(fileNameDate) could not be found."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            self.dismiss(self)
        }
    }
}
