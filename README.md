# Notify

A Flutter-based mobile application that enables users to connect with each other and send personalized notifications with stickers. The app features a connection system, sticker collections, custom sticker creation, todo management, and real-time notifications powered by Firebase.

## Features

### 🔗 User Connection
- **Pairing System**: Connect with another user using unique connection codes
- **Secure Pairing**: Generate and share connection codes to establish secure connections
- **Connection Status**: Real-time connection status tracking

### 📱 Sticker-Based Messaging
- **Sticker Collections**: Browse through a curated collection of stickers
- **Favorites**: Mark your favorite stickers for quick access
- **Custom Stickers**: Create and upload your own custom stickers with images
- **Message Composition**: Send personalized messages with titles, body text, and stickers

### 🔔 Notifications
- **Push Notifications**: Receive real-time push notifications via Firebase Cloud Messaging
- **Notification History**: View your complete notification history
- **Latest Notifications Widget**: Quick access to recent notifications on the home screen
- **Foreground Notifications**: Handle notifications even when the app is in the foreground

### ✅ Todo Management
- **Task Creation**: Create and manage todo items
- **Subtasks**: Add subtasks to your main todos
- **Task Reordering**: Drag and drop to reorder tasks
- **Synchronization**: Sync todos with your connected partner
- **Local Notifications**: Get notified about upcoming tasks

### 👤 Profile Management
- **User Profiles**: Create and manage your profile
- **Avatar Upload**: Upload and customize your profile picture
- **Mood Status**: Set and update your current mood/status

## Tech Stack

### Frontend
- **Flutter** (SDK >=3.2.3 <4.0.0)
- **Riverpod** - State management
- **Material Design 3** - UI framework

### Backend & Services
- **Firebase Core** - Firebase initialization
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - Database for users, notifications, stickers, and todos
- **Firebase Storage** - Image storage for custom stickers and avatars
- **Firebase Cloud Messaging** - Push notifications
- **Firebase Cloud Functions** - Backend functions for notification delivery

### Key Dependencies
- `flutter_riverpod` - State management
- `cloud_firestore` - Firestore database
- `firebase_messaging` - Push notifications
- `flutter_local_notifications` - Local notifications
- `shared_preferences` - Local storage
- `cached_network_image` - Image caching
- `image_picker` - Image selection
- `http` - HTTP requests
- `uuid` - Unique ID generation
- `intl` - Internationalization
- `timezone` - Timezone handling

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (>=3.2.3)
- **Dart SDK** (included with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Xcode** (for iOS development on macOS)
- **Firebase CLI** (for Firebase functions)
- **Node.js** (v22) - for Firebase Cloud Functions

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd notify
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

#### Android Setup
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`

#### iOS Setup
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/GoogleService-Info.plist`

#### Firebase Options
The app uses `firebase_options.dart` which should be generated using:
```bash
flutterfire configure
```

### 4. Firebase Cloud Functions Setup

Navigate to the functions directory and install dependencies:

```bash
cd functions
npm install
```

### 5. Configure API Endpoint

Update the notification API URL in `lib/config/const_variables.dart`:
```dart
const String notificationApiUrl = 'https://your-cloud-function-url';
```

### 6. Generate Code (if needed)

If you need to regenerate generated files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 7. Run the App

#### Android
```bash
flutter run
```

#### iOS
```bash
flutter run
```

## Project Structure

```
lib/
├── config/              # Configuration files
│   ├── const_variables.dart
│   └── firebase_options.dart
├── core/
│   └── services/        # Core services (logger, etc.)
├── data/
│   ├── firebase/        # Firebase data layer
│   │   ├── firebase_connect.dart
│   │   ├── firebase_favorites.dart
│   │   ├── firebase_notification.dart
│   │   ├── firebase_profile.dart
│   │   ├── firebase_stickers.dart
│   │   └── firebase_todo.dart
│   ├── local_notification/  # Local notification service
│   ├── local_storage/    # Shared preferences
│   └── providers/       # Riverpod providers
├── domain/              # Domain models
│   ├── connection_main_model.dart
│   ├── connection_secondary_model.dart
│   ├── notification_model.dart
│   ├── sticker_model.dart
│   └── user_profile_model.dart
├── models/              # Additional models
│   └── todo_item.dart
├── presentation/        # UI layer
│   ├── custom_stickers/
│   ├── favorites/
│   ├── main/
│   ├── notification/
│   ├── todo/
│   └── widgets/
└── main.dart            # App entry point
```

## Firebase Collections Structure

### Users Collection
```
users/
  {userId}/
    - typeUser: "primary" | "secondary"
    - tokenId: string
    - partnerCode: string
    - notifications/ (subcollection)
    - customStickers/ (subcollection)
    - todos/ (subcollection)
    - profile: {avatarUrl, mood, ...}
```

### Stickers Collection
```
stickers/
  {stickerId}/
    - title: string
    - body: string
    - url: string
    - createdAt: timestamp
```

## Features in Detail

### Connection Flow
1. User generates a unique connection code
2. Partner enters the code to connect
3. Both users are paired and can send notifications to each other
4. Connection status is tracked in real-time

### Sticker System
- **Collection View**: Browse all available stickers
- **Favorites View**: View only favorited stickers
- **Custom View**: View and manage custom uploaded stickers
- Stickers can be favorited/unfavorited with a tap

### Notification System
- Notifications are sent via Firebase Cloud Messaging
- Each notification includes:
  - Title
  - Body message
  - Sticker image
  - Timestamp
  - Sender information

### Todo System
- Create todos with titles and descriptions
- Add multiple subtasks to each todo
- Reorder todos and subtasks via drag-and-drop
- Todos are synced between connected users
- Local notifications for task reminders

## Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Environment Variables

The app uses Firebase configuration files that should be kept secure:
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)
- `firebase_options.dart`

**Note**: These files contain sensitive information and should not be committed to public repositories.

## Troubleshooting

### Common Issues

1. **Firebase not initialized**
   - Ensure `firebase_options.dart` is properly generated
   - Check that `google-services.json` and `GoogleService-Info.plist` are in the correct locations

2. **Notifications not working**
   - Verify Firebase Cloud Messaging is enabled in Firebase Console
   - Check notification permissions are granted
   - Ensure the notification API endpoint is correctly configured

3. **Build errors**
   - Run `flutter clean` and `flutter pub get`
   - Clear build cache: `flutter clean`
   - For iOS: `cd ios && pod install`

## License

This project is private and not intended for public distribution.

## Version

Current version: **1.1.0**

## Support

For issues and questions, please open an issue in the repository.

---

Built with ❤️ using Flutter
