<div align="center">
  <img src="Bookie.png" alt="Bookie Logo" width="200">
  <h1>Bookie</h1>
  <p><b>The Private, Fast, AI-Powered Reader</b></p>
</div>

# 📚 Bookie - The Private, Fast, AI-Powered Reader

**Bookie** is not just another PDF viewer. It was born out of frustration with existing apps that are bloated, slow, or track your data. I built Bookie because I wanted a reading experience that is **blazing fast**, **completely private**, and **intelligent** enough to help me learn faster.

My goal is to release this to the world as the go-to reader for students and researchers who value privacy and speed.

## Why Bookie? 🧐
* **Privacy First:** Unlike other free readers, Bookie keeps your data on your device. Your library and reading history never leave your phone.
* **Speed:** Built with Flutter's optimized engine, Bookie opens large files instantly without the lag found in heavy corporate PDF apps.
* **AI Superpowers:** Integrated with Google Gemini to break down complex academic papers into simple, 3-point summaries.
* **No Paywalls:** Tired of hitting "Upgrade to Pro" limits? Bookie allows unlimited reading and AI summarization for free, making high-end study tools available to everyone.

## ✨ Key Features
### 🧠 AI Intelligence
* **Instant Summaries:** Get the gist of any page in seconds using the "Sparkle" button.
* **Smart Analysis:** Uses Gemini 1.5 Flash for rapid, accurate text processing.

### 📖 Enhanced Reading Experience
* **Smart History:** "Bookie" remembers exactly where you left off in every book, so you never lose your place.
* **Eye-Care Modes:** Includes a Matrix-style Dark Mode and **my personal favorite: Sepia Mode**, which adds a warm, paper-like tint perfect for long reading sessions.
* **Pro Zoom:** Advanced zoom controls, including "Ctrl + Scroll" for desktop users.

### 🖊️ Core PDF Capabilities
* **Crystal Clear Rendering:** High-fidelity rendering for complex diagrams and fonts.
* **Text Interaction:** Select, copy, and interact with text smoothly.
* **Annotation Support:** Built on a robust core supporting standard PDF highlights and strikethroughs (native selection support).

## 🛠️ Tech Stack
* **Framework:** Flutter (Dart)
* **AI Engine:** Google Generative AI (Gemini 1.5 Flash)
* **Storage:** Local SharedPreferences (No external database = 100% Privacy)
* **Core Engine:** Syncfusion Flutter PDFViewer

## 🤰 Installation
If you want to run this project locally:

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/YourUsername/Bookie.git](https://github.com/YourUsername/Bookie.git)
    ```
2.  **Navigate to the project folder:**
    ```bash
    cd Bookie
    ```
3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Add your API Key:**
    * Open `lib/main.dart`
    * Paste your Gemini API Key in the `_apiKey` variable.
5.  **Run the App:**
    ```bash
    flutter run
    ```

## ⚠️ Notes
* **Zoom:** The "Ctrl + Scroll" feature is optimized for mouse users.
* **AI:** This project uses a client-side API key for demonstration purposes.

---
*Built with ❤️ for HackSync 2026.*
