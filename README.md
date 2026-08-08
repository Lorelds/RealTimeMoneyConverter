# 🌍 Real-Time AR Currency Converter

A Flutter-based mobile application that uses **Augmented Reality (AR)** and **Machine Learning (OCR)** to instantly convert foreign currencies in the physical world. 

Say goodbye to manually typing numbers into a calculator app while traveling. Simply point your phone's camera at a menu, price tag, or receipt, and the app will instantly fetch live global exchange rates and project the converted price right onto your screen.

## ✨ Features
* **Real-Time Text Recognition:** Powered by Google's ML Kit, it instantly reads numbers and prices from the physical world.
* **Augmented Reality Overlays:** Projects the converted currency in a sleek, dark-mode tooltip directly over the physical item.
* **Smart Collision Engine:** Custom-built collision detection prevents AR bubbles from overlapping each other on dense, crowded menus.
* **Live Exchange Rates:** Supports over 30 global currencies, fetching up-to-date conversion rates dynamically.
* **Instant Swap:** Google-Translate style button to quickly swap between source and target currencies.

## 🛠️ Tech Stack
* **Framework:** Flutter / Dart
* **Machine Learning:** Google ML Kit Text Recognition
* **State Management:** Stateful Widgets & Futures
* **Networking:** HTTP (Live Exchange Rate API)

## 🚀 Getting Started

If you want to clone this repository and run it locally, follow these steps:

### Prerequisites
* Install [Flutter](https://flutter.dev/docs/get-started/install)
* Install Android Studio or VS Code

### Installation
1. Clone the repository:
```bash
git clone https://github.com/Lorelds/RealTimeMoneyConverter.git
```
2. Navigate to the project directory:
```bash
cd RealTimeMoneyConverter
```
3. Install dependencies:
```bash
flutter pub get
```
4. Run the app on a connected device:
```bash
flutter run
```
*(Note: Because this app relies on a physical camera stream, it must be tested on a physical Android or iOS device, not a web emulator).*

## 📦 Building for Release (Android)
To generate a lightning-fast, production-ready `.apk` with advanced R8 code shrinking and ProGuard ML Kit optimizations:
```bash
flutter build apk
```
You can find the generated file at `build/app/outputs/flutter-apk/app-release.apk`.

---
*Built from scratch as an open-source side project.*
