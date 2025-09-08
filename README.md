# ListenList

ListenList is an iOS application that allows you to curate your own personal library of music and other audio content. You can search for your favorite songs, albums, artists, podcasts, and audiobooks and add them to a personalized "ListenList".

## Demo

You can see screen recordings and screenshots of the app [here](https://brandonlc2020.github.io/Portfolio/project/5).

## Features

  * **Comprehensive Search**: Find any song, album, artist, podcast, or audiobook available on Spotify. The search functionality is categorized, allowing you to specify what you are looking for.
  * **Authorization**: Securely log in with your Spotify account to unlock the app's features. The app authenticates and securely stores your credentials using KeychainSwift.
  * **Personalized List**: Add your favorite audio content to a personal "ListenList" for easy access. Your personalized list is displayed on the home screen of the app.
  * **Multiple Views**: See all of your saved items in either a list view or a grid view.
  * **Edit Your List**: Easily remove items from your ListenList at any time using the "Edit" mode.

## Technologies Used

  * **SwiftUI**: The entire user interface is built with Apple's modern UI framework.
  * **Firebase Firestore**: Your ListenList is stored in the cloud with Firebase's NoSQL database, allowing for data persistence across sessions.
  * **Spotify Web API**: All music and audio data is fetched from the extensive Spotify library.
  * **Swift Package Manager**: For managing project dependencies.

## Dependencies

This project uses the following Swift packages:

  * [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk): To integrate with Firebase services.
  * [keychain-swift](https://github.com/evgenyneu/keychain-swift): To securely store the Spotify refresh token in the keychain.

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

      * Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard).
      * Create a new application.
      * In the project directory, create a file named `Config.xcconfig` inside the `ListenList/` folder with the following content:
        ```
        SPOTIFY_API_CLIENT_ID = YOUR_SPOTIFY_CLIENT_ID
        SPOTIFY_API_CLIENT_SECRET = YOUR_SPOTIFY_CLIENT_SECRET
        REDIRECT_URI_SCHEME = YOUR_REDIRECT_URI_SCHEME
        REDIRECT_URI_HOST = YOUR_REDIRECT_URI_HOST
        ```
      * Replace the placeholder values with your actual Spotify application credentials and redirect URI details.

3.  **Run the app**

      * Open `ListenList.xcworkspace` in Xcode.
      * Build and run the project on a simulator or a physical device.

## License

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.
