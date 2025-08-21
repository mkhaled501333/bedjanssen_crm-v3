class QueryBuilder {
  final List<String> _whereConditions = [];
  final List<dynamic> _parameters = [];
  
  /// Add a WHERE condition with parameters
  void addCondition(String condition, List<dynamic> params) {
    _whereConditions.add(condition);
    _parameters.addAll(params);
  }
  
  /// Add a simple WHERE condition with a single parameter
  void addSimpleCondition(String column, String operator, dynamic value) {
    _whereConditions.add('$column $operator ?');
    _parameters.add(value);
  }
  
  /// Add a LIKE condition for search
  void addLikeCondition(List<String> columns, String searchTerm) {
    if (columns.isEmpty || searchTerm.isEmpty) return;
    
    final likeConditions = columns.map((col) => '$col LIKE ?').join(' OR ');
    _whereConditions.add('($likeConditions)');
    
    final searchPattern = '%$searchTerm%';
    for (int i = 0; i < columns.length; i++) {
      _parameters.add(searchPattern);
    }
  }
  
  /// Add a date range condition
  void addDateRangeCondition(String dateColumn, String startDate, String endDate) {
    _whereConditions.add('DATE($dateColumn) >= ? AND DATE($dateColumn) <= ?');
    _parameters.addAll([startDate, endDate]);
  }
  
  /// Add an IN condition
  void addInCondition(String column, List<dynamic> values) {
    if (values.isEmpty) return;
    
    final placeholders = List.filled(values.length, '?').join(', ');
    _whereConditions.add('$column IN ($placeholders)');
    _parameters.addAll(values);
  }
  
  /// Get the complete WHERE clause
  String getWhereClause() {
    return _whereConditions.isEmpty ? '1=1' : _whereConditions.join(' AND ');
  }
  
  /// Get all parameters
  List<dynamic> getParameters() {
    return List.from(_parameters);
  }
  
  /// Reset the builder
  void reset() {
    _whereConditions.clear();
    _parameters.clear();
  }
  
  /// Check if any conditions have been added
  bool get hasConditions => _whereConditions.isNotEmpty;
  
  /// Get the number of conditions
  int get conditionCount => _whereConditions.length;
}

/// Helper class for building ORDER BY clauses
class OrderByBuilder {
  final List<String> _orderClauses = [];
  
  /// Add an ORDER BY clause
  void addOrder(String column, {bool ascending = true}) {
    final direction = ascending ? 'ASC' : 'DESC';
    _orderClauses.add('$column $direction');
  }
  
  /// Get the complete ORDER BY clause
  String getOrderByClause() {
    return _orderClauses.isEmpty ? '' : 'ORDER BY ${_orderClauses.join(', ')}';
  }
  
  /// Reset the builder
  void reset() {
    _orderClauses.clear();
  }
}

/// Helper class for building pagination
class PaginationBuilder {
  final int page;
  final int limit;
  
  PaginationBuilder({required this.page, required this.limit});
  
  /// Get the LIMIT clause
  String getLimitClause() {
    return 'LIMIT $limit';
  }
  
  /// Get the OFFSET clause
  String getOffsetClause() {
    final offset = (page - 1) * limit;
    return 'OFFSET $offset';
  }
  
  /// Get both LIMIT and OFFSET
  String getPaginationClause() {
    return '${getLimitClause()} ${getOffsetClause()}';
  }
  
  /// Get the offset value
  int get offset => (page - 1) * limit;
  
  /// Calculate total pages
  int calculateTotalPages(int totalItems) {
    return (totalItems / limit).ceil();
  }
  
  /// Check if there's a next page
  bool hasNextPage(int totalItems) {
    return page < calculateTotalPages(totalItems);
  }
  
  /// Check if there's a previous page
  bool get hasPreviousPage => page > 1;
}