# Flutter SQL Client

A powerful, cross-platform SQL database client built with Flutter, providing a modern and intuitive interface for managing multiple database connections and executing queries.

## 🚀 Features

### Database Support
- **PostgreSQL** - Full support for PostgreSQL databases
- **MySQL** - Complete MySQL/MariaDB compatibility
- **Microsoft SQL Server** - MSSQL Server integration
- **SQLite** - Local SQLite database management

### Query Management
- **Multi-Tab Interface** - Work with multiple queries simultaneously
- **Syntax Highlighting** - SQL syntax highlighting for better readability
- **Auto-Completion** - Smart SQL keyword suggestions
- **Selected Query Execution** - Run specific portions of your SQL by selecting text
- **Query History** - Track and manage your query tabs

### Data Operations
- **Interactive Results Grid** - View and edit query results in a spreadsheet-like interface
- **Export Results** - Export query results to CSV format
- **Database Export** - Export entire databases to SQL dump files
- **Database Import** - Import databases from SQL dump files
- **Real-time Editing** - Edit table data directly with automatic UPDATE query generation

### Table Management
- **Schema Explorer** - Browse databases, tables, and their structures
- **Table Structure Viewer** - View detailed column information with constraints
- **Column Management** - Add new columns with full constraint support (Primary Key, Unique, Auto-Increment, etc.)
- **Index Management** - View and create table indexes
- **Tabbed Interface** - Separate tabs for Columns and Indexes

### Connection Management
- **Connection Testing** - Verify connections before saving
- **Secure Storage** - Encrypted credential storage
- **Multiple Connections** - Manage multiple database connections
- **Connection Validation** - Real-time connection status feedback

### User Experience
- **Modern UI** - Clean, intuitive interface with dark/light theme support
- **Responsive Design** - Optimized for desktop platforms (macOS, Windows, Linux)
- **Error Handling** - Clear error messages and validation
- **Loading States** - Visual feedback for all async operations

## 📦 Installation

### Prerequisites
- Flutter SDK (3.10.1 or higher)
- Dart SDK (included with Flutter)
- Platform-specific requirements:
  - **macOS**: Xcode
  - **Windows**: Visual Studio
  - **Linux**: Standard development tools

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd flutter_sql_client
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
# For macOS
flutter run -d macos

# For Windows
flutter run -d windows

# For Linux
flutter run -d linux
```

## 🎯 Usage

### Creating a Connection

1. Click the **"+"** button on the connections screen
2. Fill in the connection details:
   - **Name**: A friendly name for your connection
   - **Type**: Select database type (PostgreSQL, MySQL, MSSQL, SQLite)
   - **Host**: Database server hostname
   - **Port**: Database server port
   - **Database**: Database name
   - **Username**: Database username
   - **Password**: Database password
3. Click **"Save"** - the connection will be tested automatically
4. If successful, the connection is saved and ready to use

### Running Queries

1. Click on a connection to open the workspace
2. Write your SQL query in the editor
3. Click the **Play** button or press the run shortcut
4. View results in the data grid below
5. To run only part of a query, select the text and click run

### Managing Tables

1. Browse tables in the left sidebar
2. Right-click on a table for options:
   - **View Structure**: See columns and indexes
   - **Add Column**: Add new columns with constraints
   - **Create Index**: Add indexes to improve performance

### Exporting/Importing Data

- **Export Results**: Click the download icon to export query results to CSV
- **Export Database**: Click the backup icon to export the entire database to SQL
- **Import Database**: Click the restore icon to import from an SQL dump file

## 🛠️ Technology Stack

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Database Adapters**:
  - `postgres` - PostgreSQL connectivity
  - `mysql_client` - MySQL connectivity
  - `mssql_connection` - MSSQL Server connectivity
  - `sqflite_common_ffi` - SQLite connectivity
- **UI Components**:
  - `pluto_grid` - Data grid for results
  - `flutter_code_editor` - SQL editor with syntax highlighting
  - `flex_color_scheme` - Theme management
- **Storage**: `flutter_secure_storage` - Encrypted credential storage
- **Utilities**:
  - `csv` - CSV export functionality
  - `file_picker` - File selection dialogs
  - `uuid` - Unique identifier generation

## 📁 Project Structure

```
lib/
├── features/
│   ├── connections/
│   │   ├── data/           # Connection repository
│   │   ├── domain/         # Connection models
│   │   └── presentation/   # Connection UI
│   └── query/
│       ├── data/           # Database adapters
│       ├── domain/         # Query models
│       └── presentation/   # Workspace UI
└── main.dart               # App entry point
```

## 🔒 Security

- Credentials are stored securely using `flutter_secure_storage`
- Connections are tested before being saved
- SQL injection prevention through parameterized queries (where applicable)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🐛 Known Issues

- ObjectBox package may show warnings on certain Flutter SDK versions (non-breaking)
- File picker shows platform-specific warnings (cosmetic only)

## 🔮 Future Enhancements

- [ ] Query result pagination for large datasets
- [ ] Visual query builder
- [ ] Database diagram visualization
- [ ] Stored procedure management
- [ ] Trigger management
- [ ] Database comparison tools
- [ ] Query performance analysis
- [ ] Mobile platform support

## 📧 Support

For issues, questions, or suggestions, please open an issue on the GitHub repository.

---

**Built with ❤️ using Flutter**
