import AppKit
import SwiftUI

/// Owns the notch panel: keeps it pinned to the notch and opens or closes it as the pointer moves.
@MainActor
final class NotchWindowController {
    /// Extra room around the open notch so its shadow and corner flares are not clipped.
    private static let panelPadding = CGSize(width: 80, height: 40)
    /// Horizontal slack around the closed notch so it is easy to hit with the pointer.
    private static let closedHoverSlack: CGFloat = 20
    /// Margin the pointer must cross beyond the open notch before it closes, so jitter on the edge
    /// does not toggle it.
    private static let openHoverTolerance: CGFloat = 12
    /// Extends the hover area above the screen: with the pointer pushed against the top edge,
    /// `NSEvent.mouseLocation.y` equals `screenFrame.maxY`, which a rect ending there excludes.
    private static let topEdgeAllowance: CGFloat = 4
    private static let closeDelay: Duration = .milliseconds(250)

    private let panel = NotchPanel()
    private let viewModel: NotchViewModel
    private var screenFrame: NSRect = .zero
    private var eventMonitors: [Any] = []
    private var screenObserver: NSObjectProtocol?
    private var closeTask: Task<Void, Never>?

    init(viewModel: NotchViewModel) {
        self.viewModel = viewModel
        panel.contentView = NSHostingView(rootView: NotchContainerView().environment(viewModel))
        reposition()
        panel.orderFrontRegardless()
        installEventMonitors()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reposition() }
        }
    }

    /// Pins the panel to the top center of the notch screen and refreshes the notch measurements.
    func reposition() {
        guard let screen = NSScreen.notchScreen else { return }
        screenFrame = screen.frame
        viewModel.geometry = NotchGeometry(screen: screen)

        let width = NotchViewModel.openSize.width + Self.panelPadding.width
        let height = NotchViewModel.openSize.height + Self.panelPadding.height
        let frame = NSRect(
            x: screenFrame.midX - width / 2,
            y: screenFrame.maxY - height,
            width: width,
            height: height
        )
        panel.setFrame(frame, display: true)
    }

    // MARK: - Pointer tracking

    private func installEventMonitors() {
        let movement: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged]
        // Global monitors see events sent to other apps; local ones see events sent to the panel.
        if let global = NSEvent.addGlobalMonitorForEvents(matching: movement, handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.pointerMoved() }
        }) {
            eventMonitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: movement, handler: { [weak self] event in
            MainActor.assumeIsolated { self?.pointerMoved() }
            return event
        }) {
            eventMonitors.append(local)
        }
        if let outsideClick = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown, handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.close() }
        }) {
            eventMonitors.append(outsideClick)
        }
    }

    /// Screen-space rectangle that counts as "over the notch" for the current state.
    private var hoverRect: NSRect {
        let size = viewModel.currentSize
        let slack = viewModel.state == .closed ? Self.closedHoverSlack : Self.openHoverTolerance
        let bottomSlack = viewModel.state == .closed ? 0 : Self.openHoverTolerance
        let width = size.width + slack * 2
        let height = size.height + bottomSlack + Self.topEdgeAllowance
        return NSRect(
            x: screenFrame.midX - width / 2,
            y: screenFrame.maxY - size.height - bottomSlack,
            width: width,
            height: height
        )
    }

    private func pointerMoved() {
        let isInside = hoverRect.contains(NSEvent.mouseLocation)
        panel.ignoresMouseEvents = !isInside

        switch (viewModel.state, isInside) {
        case (.closed, true):
            open()
        case (.open, true):
            cancelClose()
        case (.open, false):
            scheduleClose()
        case (.closed, false):
            break
        }
    }

    private func open() {
        cancelClose()
        viewModel.state = .open
    }

    private func cancelClose() {
        closeTask?.cancel()
        closeTask = nil
    }

    private func scheduleClose() {
        guard closeTask == nil else { return }
        closeTask = Task { [weak self] in
            try? await Task.sleep(for: Self.closeDelay)
            guard !Task.isCancelled else { return }
            self?.close()
        }
    }

    private func close() {
        cancelClose()
        guard viewModel.state == .open else { return }
        viewModel.state = .closed
        panel.ignoresMouseEvents = true
    }
}
