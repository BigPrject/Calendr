//
//  CalendarCellView.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import RxSwift

class CalendarCellView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: Observable<CalendarCellViewModel>
    private let hoverObserver: AnyObserver<Date?>
    private let clickObserver: AnyObserver<Date>
    private let doubleClickObserver: AnyObserver<Date>
    private let calendarScaling: Observable<Double>
    private let videoPlayObserver: AnyObserver<Date>

    private let videoIndicator: NSImageView = {
        let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let image = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: "Video")?.withSymbolConfiguration(symbolConfiguration)
        return NSImageView(image: image ?? NSImage())
    }()
    private let label = Label()
    private let eventsStackView = NSStackView()
    private let borderLayer = CALayer()

    init(
        viewModel: Observable<CalendarCellViewModel>,
        hoverObserver: AnyObserver<Date?>,
        clickObserver: AnyObserver<Date>,
        doubleClickObserver: AnyObserver<Date>,
        calendarScaling: Observable<Double>,
        videoPlayObserver: AnyObserver<Date>

    ) {

        self.viewModel = viewModel
        self.hoverObserver = hoverObserver
        self.clickObserver = clickObserver
        self.doubleClickObserver = doubleClickObserver
        self.calendarScaling = calendarScaling
        self.videoPlayObserver = videoPlayObserver

        super.init(frame: .zero)

        setUpAccessibility()

        configureLayout()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        setAccessibilityElement(true)

        Observable.combineLatest(
            viewModel.map(\.isToday).distinctUntilChanged(),
            viewModel.map(\.isSelected).distinctUntilChanged(),
            viewModel.map(\.isHovered).distinctUntilChanged()
        )
        .map { isToday, isSelected, isHovered in
            [
                Accessibility.Calendar.date,
                isToday ? Accessibility.Calendar.today : nil,
                isSelected ? Accessibility.Calendar.selected : nil,
                isHovered ? Accessibility.Calendar.hovered : nil
            ]
            .compact()
        }
        .bind(to: rx.accessibilityIdentifiers)
        .disposed(by: disposeBag)
    }

    private func configureLayout() {

        forAutoLayout()

        wantsLayer = true
        borderLayer.cornerRadius = Constants.cornerRadius
        layer!.addSublayer(borderLayer)

        label.alignment = .center
        label.textColor = .headerTextColor

        let eventsContainer = NSView()
        eventsContainer.addSubview(eventsStackView)

        eventsStackView.spacing = 2
        eventsStackView.top(equalTo: eventsContainer)
        eventsStackView.bottom(equalTo: eventsContainer)
        eventsStackView.center(in: eventsContainer, orientation: .horizontal)
        eventsStackView.widthAnchor.constraint(lessThanOrEqualTo: eventsContainer.widthAnchor).activate()
        
        let contentStackView = NSStackView(views: [label, eventsContainer])
            .with(orientation: .vertical)
            .with(spacing: 2)

        addSubview(contentStackView)

        contentStackView.center(in: self)
        addSubview(videoIndicator)
        videoIndicator.isHidden = true

                
        videoIndicator.size(equalTo: 7)
        videoIndicator.top(equalTo: self, constant: 0)

    }

    private func setUpBindings() {

        calendarScaling
            .map { .systemFont(ofSize: Constants.fontSize * $0) }
            .bind(to: label.rx.font)
            .disposed(by: disposeBag)

        calendarScaling
            .bind { [weak self, borderLayer] in
                borderLayer.borderWidth = Constants.borderWidth * $0
                self?.updateLayer()
            }
            .disposed(by: disposeBag)

        viewModel
            .map(\.text)
            .distinctUntilChanged()
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)

        viewModel
            .map(\.alpha)
            .distinctUntilChanged()
            .bind(to: label.rx.alpha)
            .disposed(by: disposeBag)

        viewModel
            .repeat(when: rx.updateLayer)
            .map(\.borderColor.effectiveCGColor)
            .distinctUntilChanged()
            .bind(to: borderLayer.rx.borderColor)
            .disposed(by: disposeBag)
        
        viewModel
            .map(\.hasVideo)
            .distinctUntilChanged()
            .map { !$0 }  // Invert the boolean value
            .bind(to: videoIndicator.rx.isHidden)
            .disposed(by: disposeBag)


        Observable.combineLatest(
            viewModel.map(\.dots).distinctUntilChanged(),
            calendarScaling
        )
        .map { dots, scaling in
            (dots.isEmpty ? [.clear] : dots).map { makeEventDot(color: $0, scaling: scaling) }
        }
        .bind(to: eventsStackView.rx.arrangedSubviews)
        .disposed(by: disposeBag)

        rx.click
                    .withLatestFrom(viewModel.map(\.date))
                    .bind(to: videoPlayObserver)
                    .disposed(by: disposeBag)

                rx.doubleClick
                    .withLatestFrom(viewModel.map(\.date))
                    .bind(to: doubleClickObserver)
                    .disposed(by: disposeBag)

                rx.mouseEntered
                    .withLatestFrom(viewModel.map(\.date))
                    .bind(to: hoverObserver)
                    .disposed(by: disposeBag)
    }

    override func updateLayer() {
        super.updateLayer()
        borderLayer.frame = bounds
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    // Prevent propagating event to superview
    override func mouseExited(with event: NSEvent) { }

    override func updateTrackingAreas() {

        if let trackingArea = trackingAreas.first {
            guard trackingArea.rect != bounds else { return }
            removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self
        )

        addTrackingArea(trackingArea)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func makeEventDot(color: NSColor, scaling: Double) -> NSView {

    let view = NSView()
    let size = Constants.eventDotSize * scaling

    view.size(equalTo: size)

    view.wantsLayer = true
    view.layer!.backgroundColor = color.cgColor
    view.layer!.cornerRadius = size / 2

    if BuildConfig.isUITesting {
        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(Accessibility.Calendar.event)
    }

    return view
}

private enum Constants {

    static let fontSize: CGFloat = 12
    static let eventDotSize: CGFloat = 3

    static let borderWidth: CGFloat = 2
    static let cornerRadius: CGFloat = 5
}
