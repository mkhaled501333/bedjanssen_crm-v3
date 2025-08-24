class TicketsReportParams {
  final int companyId;
  final int page;
  final int limit;
  final String? status;
  final int? categoryId;
  final int? customerId;
  final String? startDate;
  final String? endDate;
  final String? searchTerm;
  final String? productName;
  final String? companyName;
  final String? requestReasonName;
  final bool? inspected;

  TicketsReportParams({
    required this.companyId,
    required this.page,
    required this.limit,
    this.status,
    this.categoryId,
    this.customerId,
    this.startDate,
    this.endDate,
    this.searchTerm,
    this.productName,
    this.companyName,
    this.requestReasonName,
    this.inspected,
  });
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final TicketsReportParams? params;

  ValidationResult.success(this.params) : isValid = true, errorMessage = null;
  ValidationResult.error(this.errorMessage) : isValid = false, params = null;
}

/// Validate tickets report query parameters
ValidationResult validateTicketsReportParams(Map<String, String> queryParams) {
  // Validate required companyId
  final companyIdStr = queryParams['companyId'];
  if (companyIdStr == null || companyIdStr.isEmpty) {
    return ValidationResult.error('companyId is required');
  }
  
  final companyId = int.tryParse(companyIdStr);
  if (companyId == null || companyId <= 0) {
    return ValidationResult.error('companyId must be a valid positive integer');
  }
  
  // Validate pagination parameters
  final pageStr = queryParams['page'] ?? '1';
  final limitStr = queryParams['limit'] ?? '10';
  
  final page = int.tryParse(pageStr);
  if (page == null || page < 1) {
    return ValidationResult.error('page must be a positive integer (minimum 1)');
  }
  
  final limit = int.tryParse(limitStr);
  if (limit == null || limit < 1 || limit > 100) {
    return ValidationResult.error('limit must be a positive integer between 1 and 100');
  }
  
  // Validate optional status
  final status = queryParams['status'];
  if (status != null && !['open', 'in_progress', 'closed'].contains(status.toLowerCase())) {
    return ValidationResult.error('status must be one of: open, in_progress, closed');
  }
  
  // Validate optional categoryId
  int? categoryId;
  final categoryIdStr = queryParams['categoryId'];
  if (categoryIdStr != null && categoryIdStr.isNotEmpty) {
    categoryId = int.tryParse(categoryIdStr);
    if (categoryId == null || categoryId <= 0) {
      return ValidationResult.error('categoryId must be a valid positive integer');
    }
  }
  
  // Validate optional customerId
  int? customerId;
  final customerIdStr = queryParams['customerId'];
  if (customerIdStr != null && customerIdStr.isNotEmpty) {
    customerId = int.tryParse(customerIdStr);
    if (customerId == null || customerId <= 0) {
      return ValidationResult.error('customerId must be a valid positive integer');
    }
  }
  
  // Validate optional date range
  final startDate = queryParams['startDate'];
  final endDate = queryParams['endDate'];
  
  if (startDate != null || endDate != null) {
    if (startDate == null || endDate == null) {
      return ValidationResult.error('Both startDate and endDate must be provided when filtering by date');
    }
    
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(startDate) || !dateRegex.hasMatch(endDate)) {
      return ValidationResult.error('Dates must be in YYYY-MM-DD format');
    }
    
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      if (start.isAfter(end)) {
        return ValidationResult.error('startDate must be before or equal to endDate');
      }
    } catch (e) {
      return ValidationResult.error('Invalid date format');
    }
  }
  
  // Validate optional search term
  final searchTerm = queryParams['searchTerm'];
  if (searchTerm != null && searchTerm.length > 255) {
    return ValidationResult.error('searchTerm must not exceed 255 characters');
  }
  
  // Validate optional productName
  final productName = queryParams['productName'];
  if (productName != null && productName.length > 255) {
    return ValidationResult.error('productName must not exceed 255 characters');
  }
  
  // Validate optional companyName
  final companyName = queryParams['companyName'];
  if (companyName != null && companyName.length > 255) {
    return ValidationResult.error('companyName must not exceed 255 characters');
  }
  
  // Validate optional requestReasonName
  final requestReasonName = queryParams['requestReasonName'];
  if (requestReasonName != null && requestReasonName.length > 255) {
    return ValidationResult.error('requestReasonName must not exceed 255 characters');
  }
  
  // Validate optional inspected
  bool? inspected;
  final inspectedStr = queryParams['inspected'];
  if (inspectedStr != null && inspectedStr.isNotEmpty) {
    if (inspectedStr.toLowerCase() == 'true') {
      inspected = true;
    } else if (inspectedStr.toLowerCase() == 'false') {
      inspected = false;
    } else {
      return ValidationResult.error('inspected must be true or false');
    }
  }
  
  return ValidationResult.success(
    TicketsReportParams(
      companyId: companyId,
      page: page,
      limit: limit,
      status: status?.toLowerCase(),
      categoryId: categoryId,
      customerId: customerId,
      startDate: startDate,
      endDate: endDate,
      searchTerm: searchTerm?.trim(),
      productName: productName?.trim(),
      companyName: companyName?.trim(),
      requestReasonName: requestReasonName?.trim(),
      inspected: inspected,
    ),
  );
}