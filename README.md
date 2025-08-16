# Zomato Clone

A cross-platform mobile application built with Flutter that replicates the core functionality of the Zomato food delivery platform.

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Setup Instructions](#setup-instructions)
- [Running the Apps](#running-the-apps)
- [License](#license)

## 🌟 Overview

This project is a feature-rich clone of the popular food delivery platform Zomato. It allows users to browse restaurants, view menus, place orders, track deliveries, and more - all within a seamless, intuitive interface.

## ✨ Features

- User authentication and profile management
- Restaurant browsing with search and filters
- Menu viewing with item details
- Cart functionality
- Order placement
- Payment integration
- Ratings and reviews

## 🏗️ Architecture

This project follows a clean architecture approach with a focus on separation of concerns:

### 1. Presentation Layer
- **UI Components**: Built using Flutter widgets
- **State Management**: Utilizes [Bloc] for efficient state management
- **Navigation**: Implements named routes for seamless navigation

### 2. Domain Layer
- **Use Cases**: Business logic encapsulated in use case classes
- **Entities**: Core business objects
- **Repository Interfaces**: Abstractions for data operations

### 3. Data Layer
- **Repositories**: Implementation of domain repositories
- **Data Sources**: Remote (API) and local (database) data sources
- **Models**: Data transfer objects for parsing API responses

### 4. Core
- **Utils**: Helper functions and extensions
- **Constants**: App-wide constants
- **Theme**: App theming configurations

## 🛠️ Tech Stack

- **Frontend**: Flutter/Dart
- **State Management**: [Bloc]
- **Local Storage**: [Shared Preferences/Hive/SQLite]
- **Networking**: [Dio/http]
- **Authentication**: Firebase Auth
- **Payment**: [Stripe/Razorpay]

## 🚀 Setup Instructions

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio or VS Code
- Git
- Android emulator or physical device / iOS simulator or physical device

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Naman30903/zomato_clone.git
   cd zomato_clone
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   
   The project already has Firebase set up with the necessary Google service files included in the repository.

## 🏃‍♂️ Running the Apps

This repository contains three distinct applications:

### 1. User App (Main Zomato Clone)

This is the main consumer-facing application for food ordering.

```bash
# Navigate to the user app directory
cd feastly

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 2. Restaurant Partner App

This app is for restaurant owners to manage their menu, orders, and business on the platform.

```bash
# Navigate to the restaurant app directory
cd feastly_restaurant

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 3. Delivery Agent App

This app is for delivery partners to manage and complete delivery assignments.

```bash
# Navigate to the delivery app directory
cd feastly_delivery

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Building for Production

```bash
# For User App
cd feastly
flutter build apk --release  # For Android
flutter build ios --release  # For iOS

# For Restaurant App
cd feastly_restaurant
flutter build apk --release  # For Android
flutter build ios --release  # For iOS

# For Delivery Agent App
cd feastly_delivery
flutter build apk --release  # For Android
flutter build ios --release  # For iOS
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
