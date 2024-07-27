//
//  MockVideoServiceProvider.swift
//  Calendr
//
//  Created by Bellamy John on 7/24/24.
//

import Foundation
class MockVideoServiceProvider: VideoServiceProviding {
    // This dictionary will store our mock video data
    private var mockVideos: [Date: URL] = [:]
    
    init() {
        // Generate some random mock data
        let calendar = Calendar.current
        let today = Date()
        for _ in 0..<10 {
            if let randomDate = calendar.date(byAdding: .day, value: Int.random(in: -30...30), to: today) {
                mockVideos[randomDate] = URL(string: "https://example.com/video_\(randomDate.timeIntervalSince1970).mp4")
            }
        }
    }
    
    func hasVideoForDate(_ date: Date) -> Bool {
        // Check if we have a video for the given date
        return mockVideos.keys.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
    
    func getVideoURLForDate(_ date: Date) -> URL? {
        // Find and return the URL for the video on the given date
        return mockVideos.first { Calendar.current.isDate($0.key, inSameDayAs: date) }?.value
    }
    
    func getAllVideoDates() -> [Date] {
        // Return all dates that have videos
        return Array(mockVideos.keys)
    }
}
