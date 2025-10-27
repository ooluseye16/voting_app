# Point Voting System

A Flutter-based voting application that allows users to vote for nominees across different categories using a points-based system.

## Features

- **Authentication System**
  - Admin access with special admin code
  - User access through generated access codes
  - Single-use access codes for voting

- **Admin Dashboard**
  - View voting results
  - Manage categories
  - Manage nominees
  - Generate and manage access codes

- **Voting System**
  - Points-based voting (5pts for 1st, 3pts for 2nd, 1pt for 3rd choice)
  - Multiple categories support
  - Real-time progress tracking
  - Vote submission confirmation

## Tech Stack

- Flutter for cross-platform development
- Firebase for backend services
  - Cloud Firestore for database
  - Firebase Authentication
- Material Design 3 for UI components

## Getting Started

### Prerequisites

- Flutter (latest stable version)
- Firebase account
- IDE (VS Code recommended)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a new Firebase project
   - Add your Firebase configuration files
   - Enable Cloud Firestore

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
  ├── models/          # Data models
  ├── screens/         # UI screens
  │   ├── admin/      # Admin dashboard screens
  │   └── user/       # User voting screens
  ├── services/       # Business logic and API services
  └── widgets/        # Reusable UI components
```

## Building for Different Platforms

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

### Web
```bash
flutter build web
```

### Desktop (Windows, macOS, Linux)
```bash
flutter build <platform>
```

## Contributing

1. Fork the repository
2. Create a new branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions and support, please open an issue in the GitHub repository.