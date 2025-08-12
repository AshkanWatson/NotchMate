import SwiftUI
import AppKit

// MARK: - Main App
@main
struct NotchNookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindow: NotchWindow?
    var mouseTracker: MouseTracker?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // Run as background app
        setupNotchInterface()
    }
    
    private func setupNotchInterface() {
        // Create the hidden notch overlay window
        setupNotchWindow()
        setupMouseTracking()
    }
    
    private func setupNotchWindow() {
        notchWindow = NotchWindow()
        notchWindow?.orderOut(nil) // Hidden by default
    }
    
    private func setupMouseTracking() {
        mouseTracker = MouseTracker { [weak self] isInNotchArea in
            DispatchQueue.main.async {
                self?.notchWindow?.setVisibility(isInNotchArea)
            }
        }
        mouseTracker?.startTracking()
    }
}

// MARK: - Mouse Tracker for Notch Area
class MouseTracker {
    private var trackingArea: NSTrackingArea?
    private var mouseMonitor: Any?
    private let onNotchHover: (Bool) -> Void
    
    init(onNotchHover: @escaping (Bool) -> Void) {
        self.onNotchHover = onNotchHover
    }
    
    func startTracking() {
        // Monitor global mouse position
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.checkMousePosition(event.locationInWindow)
        }
    }
    
    private func checkMousePosition(_ location: NSPoint) {
        guard let screen = NSScreen.main else { return }
        
        // Get the actual notch area (approximate)
        let screenFrame = screen.frame
        let notchWidth: CGFloat = 200 // Approximate notch width
        let notchHeight: CGFloat = 30 // Area above menu bar for hover detection
        
        let notchArea = NSRect(
            x: (screenFrame.width - notchWidth) / 2,
            y: screenFrame.height - notchHeight,
            width: notchWidth,
            height: notchHeight
        )
        
        // Convert global mouse position
        let globalPoint = NSEvent.mouseLocation
        let isInNotchArea = notchArea.contains(globalPoint)
        
        onNotchHover(isInNotchArea)
    }
    
    deinit {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// MARK: - Custom Notch Window
class NotchWindow: NSWindow {
    private var isCurrentlyVisible = false
    
    init() {
        guard let screen = NSScreen.main else {
            super.init(contentRect: NSRect.zero, styleMask: .borderless, backing: .buffered, defer: false)
            return
        }
        
        let screenFrame = screen.frame
        let menuBarHeight: CGFloat = 24
        
        // Start small and hidden in the notch area
        let windowRect = NSRect(
            x: (screenFrame.width - 400) / 2, // Centered
            y: screenFrame.height - 35, // Just above menu bar
            width: 400,
            height: 35
        )
        
        super.init(
            contentRect: windowRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = false
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow))) // Above everything
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.ignoresMouseEvents = false
        
        let contentView = NotchContentView()
        self.contentView = NSHostingView(rootView: contentView)
    }
    
    func setVisibility(_ visible: Bool) {
        guard visible != isCurrentlyVisible else { return }
        
        isCurrentlyVisible = visible
        
        if visible {
            showNotchInterface()
        } else {
            hideNotchInterface()
        }
    }
    
    private func showNotchInterface() {
        // Make window visible first
        self.orderFrontRegardless()
        self.alphaValue = 0.0 // Start transparent
        
        // Animate appearance
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            self.animator().alphaValue = 1.0
            
            // Expand the window
            if let screen = NSScreen.main {
                let screenFrame = screen.frame
                let expandedRect = NSRect(
                    x: (screenFrame.width - 600) / 2,
                    y: screenFrame.height - 80,
                    width: 600,
                    height: 80
                )
                self.animator().setFrame(expandedRect, display: true)
            }
        }) {
            // Animation complete
        }
    }
    
    private func hideNotchInterface() {
        // Animate disappearance
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            self.animator().alphaValue = 0.0
            
            // Shrink the window back
            if let screen = NSScreen.main {
                let screenFrame = screen.frame
                let collapsedRect = NSRect(
                    x: (screenFrame.width - 200) / 2,
                    y: screenFrame.height - 35,
                    width: 200,
                    height: 35
                )
                self.animator().setFrame(collapsedRect, display: true)
            }
        }) {
            // Hide window completely after animation
            self.orderOut(nil)
        }
    }
}

// MARK: - Main Notch Content View
struct NotchContentView: View {
    @StateObject private var viewModel = NotchViewModel()
    
    var body: some View {
        ZStack {
            // Background pill shape (like iPhone Dynamic Island)
            RoundedRectangle(cornerRadius: 25)
                .fill(.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 10)
            
            // Content
            HStack(spacing: 16) {
                // Left side - App shortcuts
                HStack(spacing: 8) {
                    NotchAppButton(title: "Nook", icon: "sparkles", color: .yellow)
                    NotchAppButton(title: "Tray", icon: "tray.full", color: .blue)
                }
                
                // Center - Music player (like in your image)
                MusicPlayerWidget()
                
                Spacer()
                
                // Right side - Calendar and other widgets
                HStack(spacing: 8) {
                    CalendarWidget()
                    MirrorAppButton()
                    SettingsButton()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - View Model
class NotchViewModel: ObservableObject {
    @Published var currentSong = Song.sample
    @Published var isPlaying = true
}

// MARK: - Song Model
struct Song {
    let title: String
    let artist: String
    let albumArt: String
    
    static let sample = Song(
        title: "In the Mood",
        artist: "The Savory Collection",
        albumArt: "🎵"
    )
}

// MARK: - Music Player Widget (Main center widget like in your image)
struct MusicPlayerWidget: View {
    @StateObject private var viewModel = NotchViewModel()
    
    var body: some View {
        HStack(spacing: 12) {
            // Album art placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(.orange.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("🎵")
                        .font(.title2)
                )
            
            // Song info
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentSong.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(viewModel.currentSong.artist)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            // Media controls
            HStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
        )
    }
}

// MARK: - Calendar Widget (Right side like in your image)
struct CalendarWidget: View {
    var body: some View {
        VStack(spacing: 2) {
            // Month indicator
            HStack(spacing: 4) {
                Text("Aug")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            
            // Days
            HStack(spacing: 3) {
                ForEach([13, 14, 15, 16, 17], id: \.self) { day in
                    Text("\(day)")
                        .font(.system(size: 8, weight: day == 15 ? .bold : .regular))
                        .foregroundColor(day == 15 ? .black : .white.opacity(0.7))
                        .frame(width: 16, height: 12)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(day == 15 ? .white : Color.clear)
                        )
                }
            }
            
            Text("Nothing for today")
                .font(.system(size: 7))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.1))
        )
    }
}

// MARK: - Individual Components
struct NotchAppButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MirrorAppButton: View {
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 2) {
                Image(systemName: "record.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Mirror")
                    .font(.system(size: 7))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsButton: View {
    var body: some View {
        Button(action: {}) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct NotchContentView_Previews: PreviewProvider {
    static var previews: some View {
        NotchContentView()
            .frame(width: 600, height: 80)
            .background(Color.purple.opacity(0.3)) // For preview visibility
    }
}
