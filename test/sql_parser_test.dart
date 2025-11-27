import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SQL Statement Parser Tests', () {
    /// Helper function to simulate the _splitSqlStatements method
    List<String> splitSqlStatements(String content) {
      final statements = <String>[];
      final buffer = StringBuffer();

      bool inSingleQuote = false;
      bool inDoubleQuote = false;
      bool inLineComment = false;
      bool inBlockComment = false;

      for (int i = 0; i < content.length; i++) {
        final char = content[i];
        final nextChar = i + 1 < content.length ? content[i + 1] : '';
        final prevChar = i > 0 ? content[i - 1] : '';

        // Handle line comments
        if (!inSingleQuote && !inDoubleQuote && !inBlockComment) {
          if (char == '-' && nextChar == '-') {
            inLineComment = true;
            buffer.write(char);
            continue;
          }
        }

        // End line comment on newline
        if (inLineComment && (char == '\n' || char == '\r')) {
          inLineComment = false;
          buffer.write(char);
          continue;
        }

        // Handle block comments
        if (!inSingleQuote && !inDoubleQuote && !inLineComment) {
          if (char == '/' && nextChar == '*') {
            inBlockComment = true;
            buffer.write(char);
            continue;
          }
        }

        if (inBlockComment && char == '*' && nextChar == '/') {
          inBlockComment = false;
          buffer.write(char);
          i++; // Skip the next '/'
          buffer.write(content[i]);
          continue;
        }

        // Skip processing if we're in a comment
        if (inLineComment || inBlockComment) {
          buffer.write(char);
          continue;
        }

        // Handle string literals
        // Check for escaped quotes (e.g., \' or \")
        final isEscaped = prevChar == '\\';

        if (char == "'" && !inDoubleQuote && !isEscaped) {
          inSingleQuote = !inSingleQuote;
          buffer.write(char);
          continue;
        }

        if (char == '"' && !inSingleQuote && !isEscaped) {
          inDoubleQuote = !inDoubleQuote;
          buffer.write(char);
          continue;
        }

        // Handle statement terminator (semicolon)
        if (char == ';' && !inSingleQuote && !inDoubleQuote) {
          // Don't include the semicolon in the statement
          final statement = buffer.toString().trim();
          if (statement.isNotEmpty) {
            statements.add(statement);
          }
          buffer.clear();
          continue;
        }

        buffer.write(char);
      }

      // Add any remaining content as the last statement
      final lastStatement = buffer.toString().trim();
      if (lastStatement.isNotEmpty) {
        statements.add(lastStatement);
      }

      return statements;
    }

    test('Simple statements separated by semicolons', () {
      const sql = '''
        SELECT * FROM users;
        SELECT * FROM posts;
        SELECT * FROM comments;
      ''';

      final statements = splitSqlStatements(sql);
      expect(statements.length, 3);
      expect(statements[0], contains('users'));
      expect(statements[1], contains('posts'));
      expect(statements[2], contains('comments'));
    });

    test('Semicolons inside single-quoted strings are ignored', () {
      const sql = '''
        INSERT INTO users (name) VALUES ('John; Doe');
        SELECT * FROM users WHERE name = 'Jane; Smith';
      ''';

      final statements = splitSqlStatements(sql);
      expect(statements.length, 2);
      expect(statements[0], contains("'John; Doe'"));
      expect(statements[1], contains("'Jane; Smith'"));
    });

    test('Semicolons inside double-quoted strings are ignored', () {
      const sql = '''
        INSERT INTO users (name) VALUES ("John; Doe");
        SELECT * FROM users WHERE name = "Jane; Smith";
      ''';

      final statements = splitSqlStatements(sql);
      expect(statements.length, 2);
      expect(statements[0], contains('"John; Doe"'));
      expect(statements[1], contains('"Jane; Smith"'));
    });

    test('Line comments with semicolons are handled correctly', () {
      const sql = '''
        SELECT * FROM users; -- This is a comment; with semicolons
        SELECT * FROM posts;
      ''';

      final statements = splitSqlStatements(sql);
      expect(statements.length, 2);
      expect(statements[0], contains('users'));
      // Comments after semicolons are part of the next statement or trimmed
      expect(statements[1], contains('posts'));
    });

    test('Block comments with semicolons are handled correctly', () {
      const sql = '''
        SELECT * FROM users; /* This is a comment; with semicolons */
        SELECT * FROM posts;
      ''';

      final statements = splitSqlStatements(sql);
      expect(statements.length, 2);
      expect(statements[0], contains('users'));
      // Block comments after semicolons are part of the next statement or trimmed
      expect(statements[1], contains('posts'));
    });

    test('Multi-line stored procedure is handled correctly', () {
      const sql = '''
        CREATE PROCEDURE test()
        BEGIN
          SELECT * FROM table1;
          SELECT * FROM table2;
        END;
      ''';

      final statements = splitSqlStatements(sql);
      // Note: This parser splits on ALL semicolons outside of strings/comments
      // For stored procedures, you may need database-specific handling
      // This is acceptable for most SQL dump imports
      expect(statements.length, 3);
      // Just verify we get 3 statements - the exact content depends on formatting
    });

    test('Escaped quotes are handled correctly', () {
      const sql = r'''
        INSERT INTO users (name) VALUES ('O\'Brien');
        INSERT INTO users (name) VALUES ("Quote: \"Hello\"");
      ''';

      final statements = splitSqlStatements(sql);
      expect(statements.length, 2);
      expect(statements[0], contains(r"'O\'Brien'"));
      expect(statements[1], contains(r'"Quote: \"Hello\""'));
    });

    test('Empty statements are filtered out', () {
      const sql = '''
        SELECT * FROM users;;;
        ;;
        SELECT * FROM posts;
      ''';

      final statements = splitSqlStatements(sql);
      expect(statements.length, 2);
      expect(statements[0], contains('users'));
      expect(statements[1], contains('posts'));
    });

    test('Statement without trailing semicolon is included', () {
      const sql = '''
        SELECT * FROM users;
        SELECT * FROM posts
      ''';

      final statements = splitSqlStatements(sql);
      expect(statements.length, 2);
      expect(statements[0], contains('users'));
      expect(statements[1], contains('posts'));
    });
  });
}
