//
//  CalendarViewModel.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Foundation
import RxSwift

class CalendarViewModel {

    var cellViewModelsObservable: Observable<[CalendarCellViewModel]>
    let focusedDateEventsObservable: Observable<(Date, [EventModel])>
    let videoService: VideoServiceProviding

    let title: Observable<String>
    let weekDays: Observable<[WeekDay]>
    let weekNumbers: Observable<[Int]?>
    let calendarScaling: Observable<Double>
    let cellSize: Observable<Double>
    let weekNumbersWidth: Observable<Double>


    
    init(
        searchObservable: Observable<String>,
        dateObservable: Observable<Date>,
        hoverObservable: Observable<Date?>,
        enabledCalendars: Observable<[String]>,
        calendarService: CalendarServiceProviding,
        dateProvider: DateProviding,
        settings: CalendarSettings,
        notificationCenter: NotificationCenter,
        videoService: VideoServiceProviding
    ) {
        self.videoService = videoService


        let localeChangeObservable = notificationCenter.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .void()
            .startWith(())
            .share(replay: 1)

        let dateFormatterObservable = localeChangeObservable
            .map {
                DateFormatter(format: "MMM yyyy", calendar: dateProvider.calendar).with(context: .beginningOfSentence)
            }
            .share(replay: 1)

        title = Observable.combineLatest(
            dateFormatterObservable, dateObservable
        )
        .map { $0.string(from: $1) }
        .distinctUntilChanged()
        .share(replay: 1)

        weekDays = Observable
            .combineLatest(settings.highlightedWeekdays, settings.firstWeekday)
            .repeat(when: localeChangeObservable)
            .map { highlightedWeekdays, firstWeekday in
                let calendar = dateProvider.calendar
                return (firstWeekday ..< firstWeekday + 7)
                    .map {
                        let weekDay = ($0 - 1) % 7
                        return WeekDay(
                            title: calendar.veryShortWeekdaySymbols[weekDay],
                            isHighlighted: highlightedWeekdays.contains(weekDay),
                            index: weekDay
                        )
                    }
            }
            .share(replay: 1)

        // Calculate date range for current month
        let dateRangeObservable = dateObservable
            .compactMap { selectedDate in
                dateProvider.calendar.dateInterval(of: .month, for: selectedDate)
            }
            .distinctUntilChanged()
            .share(replay: 1)

        // Create cells for current month
        let dateCellsObservable = Observable
            .combineLatest(dateRangeObservable, settings.firstWeekday)
            .map { month, firstWeekday -> [CalendarCellViewModel] in
    
                let calendar = dateProvider.calendar
                let monthStartWeekDay = calendar.component(.weekday, from: month.start)

                let start = calendar.date(
                    byAdding: .day,
                    value: { $0 <= 0 ? $0 : $0 - 7 }(firstWeekday - monthStartWeekDay),
                    to: month.start
                )!

                return (0..<42).map { day -> CalendarCellViewModel in
                    let date = calendar.date(byAdding: .day, value: day, to: start)!
                    let inMonth = calendar.isDate(date, equalTo: month.start, toGranularity: .month)
                
                    return CalendarCellViewModel(
                        date: date,
                        inMonth: inMonth,
                        isToday: false,
                        isSelected: false,
                        isHovered: false,
                        events: [],
                        calendar: calendar,
                        hasVideo: videoService.hasVideoForDate(date)

                    )
                }
            }
            .share(replay: 1)

        weekNumbers = Observable.combineLatest(
            settings.showWeekNumbers, dateCellsObservable
        )
        .map { showWeekNumbers, dateCells in
            !showWeekNumbers ? nil : (0..<6).map {
                dateProvider.calendar.component(.weekOfYear, from: dateCells[7 * $0].date)
            }
        }
        .share(replay: 1)

        
        // Get events for current dates
        let eventsObservable = Observable.combineLatest(
            dateCellsObservable,
            enabledCalendars.startWith([])
        )
        .repeat(when: calendarService.changeObservable)
        .flatMapLatest { cellViewModels, calendars -> Observable<[EventModel]> in

            calendarService.events(
                from: dateProvider.calendar.startOfDay(for: cellViewModels.first!.date),
                to: dateProvider.calendar.endOfDay(for: cellViewModels.last!.date),
                calendars: calendars
            )
        }
        .distinctUntilChanged()
        .share(replay: 1)

        let filteredEventsObservable = Observable.combineLatest(
            eventsObservable,
            settings.showDeclinedEvents,
            searchObservable
        )
        .map { events, showDeclinedEvents, searchTerm in
            events.filter {
                (showDeclinedEvents || $0.status != EventStatus.declined)
                &&
                (searchTerm.isEmpty || $0.contains(searchTerm))
            }
        }
        .optional()
        .startWith(nil)
        .distinctUntilChanged()
        .share(replay: 1)

        var timezone = dateProvider.calendar.timeZone

        // Check if today has changed
        let todayObservable = dateObservable
            .void()
            .map { dateProvider.now }
            .distinctUntilChanged { a, b in
                timezone == dateProvider.calendar.timeZone && dateProvider.calendar.isDate(a, inSameDayAs: b)
            }
            .do(afterNext: { _ in
                timezone = dateProvider.calendar.timeZone
            })
            .share(replay: 1)

        // Check which cell is today
        let isTodayObservable = Observable.combineLatest(
            dateCellsObservable, filteredEventsObservable, todayObservable
        )
        .map { cellViewModels, events, today -> [CalendarCellViewModel] in

            cellViewModels.map { vm in
                vm.with(
                    isToday: dateProvider.calendar.isDate(vm.date, inSameDayAs: today),
                    events: events?.filter { event in
                        dateProvider.calendar.isDate(vm.date, in: (event.start, event.end))
                    },
                    calendar: dateProvider.calendar,
                    hasVideo: vm.hasVideo
                )
            }
        }
        .share(replay: 1)

        // Check which cell is selected
        let isSelectedObservable = Observable.combineLatest(
            isTodayObservable, dateObservable
        )
        .map { cellViewModels, selectedDate -> [CalendarCellViewModel] in

            cellViewModels.map {
                $0.with(
                    isSelected: dateProvider.calendar.isDate($0.date, inSameDayAs: selectedDate),
                    calendar: dateProvider.calendar,
                    hasVideo: $0.hasVideo
                )
            }
        }
        .distinctUntilChanged()
        .share(replay: 1)

        // Clear hover when month changes
        let hoverObservable: Observable<Date?> = Observable.merge(
            dateRangeObservable.map(nil), hoverObservable
        )

        // Check which cell is hovered
        cellViewModelsObservable = Observable.combineLatest(
            isSelectedObservable, hoverObservable
        )
        .map { cellViewModels, hoveredDate -> [CalendarCellViewModel] in

            if let hoveredDate = hoveredDate {
                return cellViewModels.map {
                    $0.with(
                        isHovered: dateProvider.calendar.isDate($0.date, inSameDayAs: hoveredDate),
                        calendar: dateProvider.calendar,
                        hasVideo: $0.hasVideo
                    )
                }
            } else {
                return cellViewModels.map {
                    $0.with(isHovered: false, calendar: dateProvider.calendar,hasVideo: $0.hasVideo)
                }
            }
        }
        .distinctUntilChanged()
        .share(replay: 1)

        calendarScaling = settings.calendarScaling

        cellSize = calendarScaling
            .map { Constants.cellSize * $0 + 10 * ($0 - 1) }
            .distinctUntilChanged()
            .share(replay: 1)

        weekNumbersWidth = Observable
            .combineLatest(weekNumbers, cellSize)
            .map { $0 != nil ? $1 * Constants.weekNumberCellRatio : 0 }
            .distinctUntilChanged()
            .share(replay: 1)

        focusedDateEventsObservable = cellViewModelsObservable
            .compactMap { dates in
                guard
                    let focused = dates.first(where: \.isHovered) ?? dates.first(where: \.isSelected)
                else { return nil }

                guard focused.isToday else { return (focused.date, focused.events) }

                let overdue = dates
                    .filter { dateProvider.calendar.isDate($0.date, lessThan: dateProvider.now, granularity: .day) }
                    .flatMap(\.events)
                    .filter(\.type.isReminder)

                return (focused.date, overdue + focused.events)
            }
            .distinctUntilChanged(==)
            .share(replay: 1)
        
    }
    func updateCellViewModels() {
        let videoDates = Set(videoService.getAllVideoDates())
        
        // Create a new observable that maps over the existing cell view models
        let updatedCellViewModels = cellViewModelsObservable.map { cellViewModels in
            cellViewModels.map { cellViewModel in
                cellViewModel.with(
                    isToday: cellViewModel.isToday,
                    isSelected: cellViewModel.isSelected,
                    isHovered: cellViewModel.isHovered,
                    events: cellViewModel.events,
                    calendar: cellViewModel.calendar,
                    hasVideo: videoDates.contains(cellViewModel.date)
                )
            }
        }
        
        // Combine the updated observable with the existing one
        cellViewModelsObservable = Observable.combineLatest(
            cellViewModelsObservable,
            updatedCellViewModels
        ) { _, updated in
            updated
        }
        .distinctUntilChanged()
        .share(replay: 1)
    }
   
    
}

private extension CalendarCellViewModel {

    func with(
        isToday: Bool? = nil,
        isSelected: Bool? = nil,
        isHovered: Bool? = nil,
        events: [EventModel]? = nil,
        calendar: Calendar,
        hasVideo: Bool? = nil
    ) -> Self {
        

        CalendarCellViewModel(
            date: date,
            inMonth: inMonth,
            isToday: isToday ?? self.isToday,
            isSelected: isSelected ?? self.isSelected,
            isHovered: isHovered ?? self.isHovered,
            events: events ?? self.events,
            calendar: calendar,
            hasVideo: hasVideo ?? self.hasVideo
        )

    }
   
    
}

private enum Constants {

    static let cellSize: CGFloat = 25
    static let weekNumberCellRatio: CGFloat = 0.85
}

private extension EventModel {

    func contains(_ searchTerm: String) -> Bool {
        [
            title,
            location,
            url?.absoluteString,
            notes,
            participants.map(\.name).joined(separator: " ")
        ]
        .contains { $0?.localizedCaseInsensitiveContains(searchTerm) ?? false }
    }
}
