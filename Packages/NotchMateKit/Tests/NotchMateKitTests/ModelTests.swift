import XCTest
@testable import NotchMateKit

final class BatteryInfoTests: XCTestCase {
    func testParsesInternalBattery() throws {
        let info = try XCTUnwrap(BatteryInfo(powerSourceDescription: [
            "Type": "InternalBattery",
            "Current Capacity": NSNumber(value: 42),
            "Max Capacity": NSNumber(value: 100),
            "Is Charging": NSNumber(value: false),
            "Power Source State": "Battery Power"
        ]))
        XCTAssertEqual(info.percentage, 42)
        XCTAssertFalse(info.isCharging)
        XCTAssertFalse(info.isPluggedIn)
        XCTAssertEqual(info.symbolName, "battery.50percent")
    }

    func testChargingSymbol() throws {
        let info = try XCTUnwrap(BatteryInfo(powerSourceDescription: [
            "Current Capacity": NSNumber(value: 80),
            "Max Capacity": NSNumber(value: 100),
            "Is Charging": NSNumber(value: true),
            "Power Source State": "AC Power"
        ]))
        XCTAssertTrue(info.isPluggedIn)
        XCTAssertEqual(info.symbolName, "battery.100percent.bolt")
        XCTAssertFalse(info.isLow)
    }

    func testRejectsNonBatteryAndMalformed() {
        XCTAssertNil(BatteryInfo(powerSourceDescription: ["Type": "UPS", "Current Capacity": 5, "Max Capacity": 10]))
        XCTAssertNil(BatteryInfo(powerSourceDescription: ["Current Capacity": NSNumber(value: 5)]))
        XCTAssertNil(BatteryInfo(powerSourceDescription: ["Current Capacity": NSNumber(value: 5), "Max Capacity": NSNumber(value: 0)]))
    }

    func testSymbolThresholdsAndClamping() {
        XCTAssertEqual(BatteryInfo(level: 0.05, isCharging: false, isPluggedIn: false).symbolName, "battery.0percent")
        XCTAssertEqual(BatteryInfo(level: 0.3, isCharging: false, isPluggedIn: false).symbolName, "battery.25percent")
        XCTAssertEqual(BatteryInfo(level: 0.8, isCharging: false, isPluggedIn: false).symbolName, "battery.75percent")
        XCTAssertEqual(BatteryInfo(level: 1.5, isCharging: false, isPluggedIn: false).percentage, 100)
        XCTAssertTrue(BatteryInfo(level: 0.15, isCharging: false, isPluggedIn: false).isLow)
        XCTAssertFalse(BatteryInfo(level: 0.15, isCharging: false, isPluggedIn: true).isLow)
    }
}

final class NowPlayingInfoTests: XCTestCase {
    private let separator = "\u{1F}"

    func testParsesPlayingTrack() throws {
        let info = try XCTUnwrap(NowPlayingInfo.parse("playing\(separator)In the Mood\(separator)Glenn Miller", player: .music))
        XCTAssertEqual(info, NowPlayingInfo(player: .music, title: "In the Mood", artist: "Glenn Miller", isPlaying: true))
    }

    func testParsesPausedTrackWithEmptyArtist() throws {
        let info = try XCTUnwrap(NowPlayingInfo.parse("paused\(separator)Podcast\(separator)\n", player: .spotify))
        XCTAssertFalse(info.isPlaying)
        XCTAssertEqual(info.artist, "")
    }

    func testRejectsStoppedAndMalformed() {
        XCTAssertNil(NowPlayingInfo.parse("stopped", player: .music))
        XCTAssertNil(NowPlayingInfo.parse("", player: .music))
        XCTAssertNil(NowPlayingInfo.parse("fast forwarding\(separator)A\(separator)B", player: .music))
        XCTAssertNil(NowPlayingInfo.parse("playing\(separator)\(separator)B", player: .music))
    }

    func testPrefersPlayingPlayer() {
        let paused = NowPlayingInfo(player: .music, title: "A", artist: "", isPlaying: false)
        let playing = NowPlayingInfo(player: .spotify, title: "B", artist: "", isPlaying: true)
        XCTAssertEqual(NowPlayingInfo.preferred([paused, playing]), playing)
        XCTAssertEqual(NowPlayingInfo.preferred([paused]), paused)
        XCTAssertNil(NowPlayingInfo.preferred([]))
    }

    func testScriptsTargetTheRightApplication() {
        XCTAssertTrue(MediaPlayer.music.statusScript.contains("tell application \"Music\""))
        XCTAssertEqual(MediaPlayer.spotify.commandScript(.nextTrack), "tell application \"Spotify\" to next track")
        XCTAssertEqual(MediaPlayer.music.commandScript(.playPause), "tell application \"Music\" to playpause")
        XCTAssertEqual(MediaPlayer.spotify.bundleIdentifier, "com.spotify.client")
    }
}

final class NotchAnimationTests: XCTestCase {
    func testExpandHasOvershootCollapseDoesNot() {
        XCTAssertLessThan(NotchAnimation.forTransition(to: .expanded, reduceMotion: false).dampingFraction, 1)
        XCTAssertGreaterThan(NotchAnimation.forTransition(to: .collapsed, reduceMotion: false).dampingFraction,
                             NotchAnimation.expand.dampingFraction)
    }

    func testReduceMotion() {
        for state in [NotchState.expanded, .collapsed] {
            let animation = NotchAnimation.forTransition(to: state, reduceMotion: true)
            XCTAssertEqual(animation, .reducedMotion)
            XCTAssertEqual(animation.dampingFraction, 1)
        }
    }
}
