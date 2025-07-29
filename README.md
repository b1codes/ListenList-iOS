# ListenList

ListenList is an iOS application that allows you to curate your own music library. Search for your favorite songs, albums, and artists and add them to your personal "ListenList".

## Features

* **Search**: Find any song, album, or artist available on Spotify.
* **Authorization**: Securely log in with your Spotify account to unlock the app's features.
* **Personalized List**: Add your favorite music to a personal "ListenList" for easy access.
* **View Your List**: See all of your saved songs, albums, and artists in one place.
* **Edit Your List**: Remove items from your ListenList at any time.

## Technologies Used

* **SwiftUI**: The entire user interface is built with Apple's modern UI framework.
* **Firebase Firestore**: Your ListenList is stored in the cloud with Firebase's NoSQL database, allowing for data persistence across sessions.
* **Spotify Web API**: All music data is fetched from the extensive Spotify library.

## Getting Started

To run this project, you will need to set up your own Firebase project and Spotify Developer application.

### Prerequisites

* Xcode
* A Spotify Developer account
* A Firebase account

### Setup

1.  **Firebase**
    * Create a new project on the [Firebase Console](https://console.firebase.google.com/).
    * Add an iOS app to your Firebase project.
    * Download the `GoogleService-Info.plist` file and place it in the `ListenList/ListenList/` directory.

2.  **Spotify**
    * Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/).
    * Create a new application.
    * In the project directory, create a file named `Config.xcconfig` inside the `ListenList/` folder with the following content:
        ```
        SPOTIFY_API_CLIENT_ID = YOUR_SPOTIFY_CLIENT_ID
        SPOTIFY_API_CLIENT_SECRET = YOUR_SPOTIFY_CLIENT_SECRET
        ```
    * Replace `YOUR_SPOTIFY_CLIENT_ID` and `YOUR_SPOTIFY_CLIENT_SECRET` with the credentials from your Spotify application.

3.  **Run the app**
    * Open `ListenList.xcworkspace` in Xcode.
    * Build and run the project on a simulator or a physical device.

## License

This project is licensed under the MIT License - see the [LICENSE](ListenList/LICENSE) file for details.
