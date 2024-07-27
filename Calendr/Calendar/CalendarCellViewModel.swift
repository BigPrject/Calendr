//
//  CalendarCellViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa

struct CalendarCellViewModel: Equatable {
    let date: Date
    let inMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let isHovered: Bool
    let events: [EventModel]
    let hasVideo: Bool

     let calendar: Calendar

    init(
        date: Date,
        inMonth: Bool,
        isToday: Bool,
        isSelected: Bool,
        isHovered: Bool,
        events: [EventModel],
        calendar: Calendar,
        hasVideo: Bool
    ) {
        self.date = date
        self.inMonth = inMonth
        self.isToday = isToday
        self.isSelected = isSelected
        self.isHovered = isHovered
        self.events = events
        self.calendar = calendar
        self.hasVideo = hasVideo
    }
}

extension CalendarCellViewModel {

    var text: String {
        "\(calendar.component(.day, from: date))"
    }

    var alpha: CGFloat {
        inMonth ? 1 : 0.3
    }

    var borderColor: NSColor {
        if isToday {
            return .controlAccentColor
        } else if isSelected {
            return .secondaryLabelColor
        } else if isHovered {
            return .tertiaryLabelColor
        } else {
            return .clear
        }
    }

    var dots: [NSColor] {
        let colors = events.map(\.calendar)
            .sorted {
                ($0.account.localizedLowercase, $0.title.localizedLowercase)
                <
                ($1.account.localizedLowercase, $1.title.localizedLowercase)
            }
            .map(\.color)

        return NSOrderedSet(array: colors).array as! [NSColor]
    }
}
