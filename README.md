# Flutter SQL Client

A modern, cross-platform SQL Client built with Flutter.

## Features

- **Connection Manager**: Manage PostgreSQL and SQLite connections.
- **Schema Explorer**: Browse tables.
- **Query Editor**: Syntax highlighting for SQL.
- **Data Grid**: View and sort query results.
- **Export**: Export results to CSV.
- **Theme**: Dark and Light mode support.

## Getting Started

### Prerequisites

- Flutter SDK (Latest Stable)
- PostgreSQL (if testing Postgres connections)

### Installation

1. Clone the repository.
2. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

Run the app on your preferred platform (macOS, Windows, Linux, or Web):

```bash
flutter run -d macos
```

## Architecture

- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Database**: `postgres`, `sqflite_common_ffi`
- **UI**: `flex_color_scheme`, `pluto_grid`, `flutter_code_editor`

## Folder Structure

- `lib/core`: Core utilities, theme, router.
- `lib/features`: Feature-based modules (connections, query, schema).
- `lib/shared`: Shared widgets.
