# Accountability App

A Flutter web application for managing tasks and goals with Firebase authentication and Firestore database.

## Features

- User authentication (Email/Password)
- Create, read, update, and delete tasks
- Mark tasks as complete
- Due date tracking
- Real-time updates using Firestore

## Prerequisites

- Flutter SDK
- Firebase project
- Web browser

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Firebase:
   - Create a new project in the Firebase Console
   - Enable Authentication (Email/Password)
   - Create a Firestore database
   - Add your web app to Firebase
   - Update the Firebase configuration in `lib/main.dart`

## Running the App

```bash
flutter run -d chrome
```

## Project Structure

- `lib/models/` - Data models
- `lib/screens/` - UI screens
- `lib/services/` - Firebase services
- `lib/widgets/` - Reusable widgets

## Dependencies

- firebase_core
- firebase_auth
- cloud_firestore
- uuid

## Contributing

1. Fork the repository
2. Create a new branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License. 