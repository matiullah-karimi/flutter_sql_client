class QueryTab {
  final String id;
  final String title;
  final String content;
  final List<Map<String, dynamic>>? results;
  final String? error;
  final bool isLoading;
  final String? sourceTable; // Track which table the results came from
  final bool hasChanges; // Track if grid has unsaved changes

  QueryTab({
    required this.id,
    required this.title,
    this.content = '',
    this.results,
    this.error,
    this.isLoading = false,
    this.sourceTable,
    this.hasChanges = false,
  });

  QueryTab copyWith({
    String? title,
    String? content,
    List<Map<String, dynamic>>? results,
    String? error,
    bool? isLoading,
    String? sourceTable,
    bool? hasChanges,
    bool clearResults = false,
    bool clearError = false,
    bool clearSourceTable = false,
  }) {
    return QueryTab(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      results: clearResults ? null : (results ?? this.results),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
      sourceTable: clearSourceTable ? null : (sourceTable ?? this.sourceTable),
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }
}
