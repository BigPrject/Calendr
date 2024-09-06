//
//  VideoService.swift
//  Calendr
//
//  Created by Bellamy John on 7/22/24.
//

import Foundation
import Cocoa
import RxSwift

protocol VideoServiceProviding {
    func hasVideoForDate(_ date: Date) -> Bool
    func getVideoURLForDate(_ date: Date) -> URL?
    func getAllVideoDates() -> [Date]

}

class VideoService: VideoServiceProviding {
    
    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        return formatter
    }()

    private var baseFolderURL: URL? {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("calendr video blogs")
    }

    func hasVideoForDate(_ date: Date) -> Bool {
        let hasVideo = getVideoURLForDate(date) != nil
            print("Checking for video on date: \(dateFormatter.string(from: date)), result: \(hasVideo)")
            return hasVideo
    }


    func getVideoURLForDate(_ date: Date) -> URL? {
            print("getVideoURLForDate() called for date: \(dateFormatter.string(from: date))")
            let components = Calendar.current.dateComponents([.year, .month], from: date)
            guard let year = components.year, let month = components.month,
                  let baseFolderURL = baseFolderURL else {
                return nil
            }

            let yearFolder = baseFolderURL.appendingPathComponent(String(year))
            let monthFolder = yearFolder.appendingPathComponent(String(format: "%02d", month))
            let fileName = "\(dateFormatter.string(from: date)).mov"
            let filePath = monthFolder.appendingPathComponent(fileName)

            print("Checking for file at path: \(filePath.path)")
            let fileExists = fileManager.fileExists(atPath: filePath.path)
            print("File exists: \(fileExists)")

            return fileExists ? filePath : nil
        }

    func getAllVideoDates() -> [Date] {
        print("getAllVideoDates() called")
        guard let baseFolderURL = baseFolderURL else { return [] }

        let enumerator = fileManager.enumerator(at: baseFolderURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants])

        var dates: [Date] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "mov",
               let date = dateFormatter.date(from: fileURL.deletingPathExtension().lastPathComponent) {
                dates.append(date)
            }
        }

        return dates
    }
}
