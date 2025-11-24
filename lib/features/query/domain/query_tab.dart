class QueryTab {
  final String id;
  final String title;
  String content;
  List<Map<String, dynamic>>? results;
  String? error;
  bool isLoading;

  QueryTab({
    required this.id,
    required this.title,
    this.content = '',
    this.results,
    this.error,
    this.isLoading = false,
  });

  QueryTab copyWith({
    String? title,
    String? content,
    List<Map<String, dynamic>>? results,
    String? error,
    bool? isLoading,
    bool clearResults = false,
    bool clearError = false,
  }) {
    return QueryTab(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      results: clearResults ? null : (results ?? this.results),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
