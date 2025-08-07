# 🎩 NotchMate

**NotchMate** is a **free, open-source macOS app** built in **Swift** that customizes and enhances the **MacBook notch area** with playful and useful widgets — just like [NotchNook](https://lo.cafe/notchnook), but fully open source!

> Personalize your Mac’s notch with clocks, battery info, animations, and even a music player — right from the notch!

---

## ✨ Features

- 🕒 **Clock Widget** – Displays the current time right at the notch.
- 🔋 **Battery Widget** – Shows real-time battery percentage.
- 🎵 **Music Widget** – Control playback of Apple Music or the system media player.
- 🎨 **Animated Dots** – Playful bouncing dots around the notch for extra flair.
- 💡 **Lightweight** – Native macOS performance using Swift and AppKit.
- 💻 **Menu Bar App** – Runs silently with a minimal footprint.

---

## 📸 Screenshots

> _(Add screenshots of your notch area with the overlay here!)_

---

## 🚀 Getting Started

### Requirements

- macOS Monterey (12.0) or later
- Xcode 14 or later
- MacBook with a notch

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/AshkanWatson/NotchMate.git
   cd NotchMate
   ```

2. **Open in Xcode**

`open NotchMate.xcodeproj`
3. **Build & Run**

### 🧩 Widgets Included

- Select your Mac as the run target.
- Hit **Run** ▶️ in Xcode.

| Widget  | Description |
|----------|----------|---------------|
| **🕒 Clock** | Digital time display centered under the notch |
| **🔋 Battery** | Real-time battery % above the notch |
| **🎵 Music Player** | Now playing info + playback control (Apple Music) |
| **🟣 Animation** | Smooth animated dots for fun |

### 🎧 Music Control Support

- Integrated with `MPMusicPlayerController`
- Automatically shows current track & artist
- Ready for **play/pause/next/previous** controls (clickable controls coming soon!)

### 🛠️ Built With

- [Swift](https://www.swift.org/) – Apple's modern native language
- [AppKit](https://developer.apple.com/documentation/appkit) – For custom macOS UI
- [MediaPlayer](https://developer.apple.com/documentation/mediaplayer) – For music control
- [IOKit](https://developer.apple.com/documentation/iokit) – For battery status

### 🤝 Contributing

Want to add widgets? Improve animations? Make the notch dance?

1. Fork this repo
2. Create your branch (`git checkout -b feature/music-widget`)
3. Commit your changes (`git commit -m 'Add amazing widget'`)
4. Push to your branch (`git push origin feature/music-widget`)
5. Open a Pull Request

### 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.

### 🙌 Acknowledgements

Inspired by NotchNook — but made for everyone, open-source and free forever.

### 💡 Future Plans

- Widget customization UI
- Spotify & YouTube Music support
- Theme support (dark/light modes)
- Clickable playback buttons
- CPU/Network widgets

**⭐️ Star NotchMate if you love open-source UI creativity for your MacBook notch!**
