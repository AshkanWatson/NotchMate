import SwiftUI
import NotchMateKit

struct SettingsView: View {
    @ObservedObject var settingsModel: SettingsModel
    @ObservedObject var controller: NotchController
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchAtLoginError: String?

    private var settings: Binding<NotchSettings> { $settingsModel.settings }

    var body: some View {
        Form {
            Section {
                LabeledContent("Status") {
                    Text(controller.statusDescription)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("settings.status")
                }
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in
                        do {
                            try LaunchAtLogin.setEnabled(enabled)
                            launchAtLoginError = nil
                        } catch {
                            launchAtLoginError = error.localizedDescription
                            launchAtLogin = LaunchAtLogin.isEnabled
                        }
                    }
                if let launchAtLoginError {
                    Text(launchAtLoginError).font(.caption).foregroundStyle(.red)
                }
            }

            Section("Behavior") {
                Toggle("Expand when hovering over the notch", isOn: settings.expandOnHover)
                    .accessibilityIdentifier("settings.expandOnHover")
                SliderRow(title: "Open delay", value: settings.openDelay, range: NotchSettings.openDelayRange, unit: "s")
                SliderRow(title: "Close delay", value: settings.closeDelay, range: NotchSettings.closeDelayRange, unit: "s")
                SliderRow(title: "Hover area padding", value: settings.hoverPadding, range: NotchSettings.hoverPaddingRange, unit: "pt", step: 1)
                Toggle("Haptic feedback on expand", isOn: settings.hapticFeedback)
            }

            Section("Appearance") {
                Picker("Panel style", selection: settings.appearance) {
                    Text("Notch (always black)").tag(PanelAppearance.notch)
                    Text("Match system appearance").tag(PanelAppearance.system)
                }
                SliderRow(title: "Panel width", value: settings.expandedWidth, range: NotchSettings.expandedWidthRange, unit: "pt", step: 10)
                SliderRow(title: "Panel height", value: settings.expandedHeight, range: NotchSettings.expandedHeightRange, unit: "pt", step: 10)
            }

            Section("Displays") {
                Picker("Show on", selection: settings.displayPreference) {
                    Text("Display with a notch, else main display").tag(DisplayPreference.automatic)
                    Text("Built-in display").tag(DisplayPreference.builtIn)
                    Text("Display with the menu bar").tag(DisplayPreference.primary)
                }
                Toggle("Show a virtual notch on displays without one", isOn: settings.showOnDisplaysWithoutNotch)
                    .accessibilityIdentifier("settings.virtualNotch")
                if settingsModel.settings.showOnDisplaysWithoutNotch {
                    SliderRow(title: "Virtual notch width", value: settings.virtualNotchWidth, range: NotchSettings.virtualNotchWidthRange, unit: "pt", step: 5)
                }
            }

            Section("Widgets") {
                Toggle("Clock", isOn: settings.showClock)
                Toggle("Battery", isOn: settings.showBattery)
                Toggle("Now Playing (Music & Spotify)", isOn: settings.showNowPlaying)
            }

            Section {
                HStack {
                    Text("NotchMate \(Bundle.main.shortVersion)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Reset to Defaults") { settingsModel.resetToDefaults() }
                        .accessibilityIdentifier("settings.reset")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .frame(minHeight: 520, idealHeight: 640)
        .accessibilityIdentifier("settings.form")
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    var step: Double = 0.05

    var body: some View {
        LabeledContent(title) {
            HStack {
                Slider(value: $value, in: range, step: step)
                    .labelsHidden()
                Text(formatted)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 56, alignment: .trailing)
            }
        }
    }

    private var formatted: String {
        unit == "s" ? String(format: "%.2f s", value) : "\(Int(value.rounded())) \(unit)"
    }
}

extension Bundle {
    var shortVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }
}
