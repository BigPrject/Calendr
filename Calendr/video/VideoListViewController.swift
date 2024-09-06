//
//  VideoListViewController.swift
//  Calendr
//
//  Created by Bellamy John on 7/26/24.
//

import Foundation
import Cocoa

class VideoListViewController: NSViewController {
    private let collectionView: NSCollectionView
    private let scrollView = NSScrollView()
    private var videos: [Date] = []
    private let videoService: VideoServiceProviding

    init(videoService: VideoServiceProviding) {
        self.videoService = videoService
        
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 50, height: 50)
        flowLayout.sectionInset = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        flowLayout.minimumInteritemSpacing = 10
        flowLayout.minimumLineSpacing = 10
        flowLayout.headerReferenceSize = NSSize(width: 100, height: 40)

        
        self.collectionView = NSCollectionView(frame: .zero)
        self.collectionView.collectionViewLayout = flowLayout
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadVideos()
    }

    private func setupUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(DateCell.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("DateCell"))
        collectionView.isSelectable = true

        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadVideos() {
        videos = videoService.getAllVideoDates().sorted(by: <)
        collectionView.reloadData()
    }
}

extension VideoListViewController: NSCollectionViewDataSource, NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("DateCell"), for: indexPath)
        guard let dateCell = item as? DateCell else { return item }

        let date = videos[indexPath.item]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d"
        dateCell.textField?.stringValue = dateFormatter.string(from: date)

        return dateCell
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        let date = videos[indexPath.item]
        if let url = videoService.getVideoURLForDate(date) {
            let playerController = VideoPlayController(date: date)
            self.presentAsModalWindow(playerController)
        }
    }
}

class DateCell: NSCollectionViewItem {
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.lightGray.cgColor // Transparent background
        self.view.layer?.borderWidth = 1
        self.view.layer?.cornerRadius = 8

        let textField = NSTextField(labelWithString: "")
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        textField.textColor = NSColor.black

        self.view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])

        self.textField = textField
    }
}
