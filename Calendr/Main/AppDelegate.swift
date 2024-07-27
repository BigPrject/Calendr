//
//  AppDelegate.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var viewController: NSViewController?

    func applicationDidFinishLaunching(_ notification: Notification) {

        guard !BuildConfig.isTesting, !BuildConfig.isPreview else { return }

        #if DEBUG
        guard !BuildConfig.isUITesting else {
            viewController = MockMainViewController()
            return
        }
        #endif
        let videoService = VideoService()

        viewController = MainViewController(
            autoLauncher: .default,
            workspace: NSWorkspace.shared,
            calendarService: CalendarServiceProvider(notificationCenter: .default),
            dateProvider: DateProvider(calendar: .autoupdatingCurrent),
            screenProvider: ScreenProvider(notificationCenter: .default),
            userDefaults: .standard,
            notificationCenter: .default,
            videoService: videoService
        )

        setUpEditShortcuts()
        setUpResignFocus()
    }
}
