class PagedResponse<T> {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;

  PagedResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
  });

  factory PagedResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    final page = json['page'] as Map<String, dynamic>;
    final items = (json['content'] as List).map((e) => fromJsonT(e)).toList();

    return PagedResponse(
      content: items,
      pageNumber: page['number'],
      pageSize: page['size'],
      totalElements: page['totalElements'],
      totalPages: page['totalPages'],
    );
  }
}