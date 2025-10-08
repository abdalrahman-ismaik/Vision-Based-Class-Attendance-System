/// Export format enumeration
enum ExportFormat {
  csv,
  json,
  excel,
  pdf;

  @override
  String toString() {
    switch (this) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.excel:
        return 'Excel';
      case ExportFormat.pdf:
        return 'PDF';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.csv:
        return '.csv';
      case ExportFormat.json:
        return '.json';
      case ExportFormat.excel:
        return '.xlsx';
      case ExportFormat.pdf:
        return '.pdf';
    }
  }

  String get mimeType {
    switch (this) {
      case ExportFormat.csv:
        return 'text/csv';
      case ExportFormat.json:
        return 'application/json';
      case ExportFormat.excel:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case ExportFormat.pdf:
        return 'application/pdf';
    }
  }
}

/// Export data type enumeration
enum ExportDataType {
  students,
  registrationSessions,
  selectedFrames,
  administrators,
  systemReports;

  @override
  String toString() {
    switch (this) {
      case ExportDataType.students:
        return 'Students';
      case ExportDataType.registrationSessions:
        return 'Registration Sessions';
      case ExportDataType.selectedFrames:
        return 'Selected Frames';
      case ExportDataType.administrators:
        return 'Administrators';
      case ExportDataType.systemReports:
        return 'System Reports';
    }
  }
}

/// Export options configuration
class ExportOptions {
  const ExportOptions({
    this.includeHeaders = true,
    this.includeMetadata = false,
    this.includeFaceEmbeddings = false,
    this.dateFormat = 'yyyy-MM-dd HH:mm:ss',
    this.maxRecords,
    this.customFields,
    this.filterCriteria,
  });

  /// Whether to include column headers
  final bool includeHeaders;

  /// Whether to include metadata fields
  final bool includeMetadata;

  /// Whether to include face embeddings data
  final bool includeFaceEmbeddings;

  /// Date format for datetime fields
  final String dateFormat;

  /// Maximum number of records to export
  final int? maxRecords;

  /// Custom fields to include in export
  final List<String>? customFields;

  /// Filter criteria for data selection
  final Map<String, dynamic>? filterCriteria;
}

/// Export result information
class ExportResult {
  const ExportResult({
    required this.success,
    required this.filePath,
    required this.recordCount,
    required this.fileSize,
    required this.exportedAt,
    this.error,
    this.metadata,
  });

  /// Whether the export was successful
  final bool success;

  /// Path to the exported file
  final String filePath;

  /// Number of records exported
  final int recordCount;

  /// Size of the exported file in bytes
  final int fileSize;

  /// When the export was completed
  final DateTime exportedAt;

  /// Error message if export failed
  final String? error;

  /// Additional metadata about the export
  final Map<String, dynamic>? metadata;
}

/// Abstract repository interface for data export operations
abstract class ExportRepository {
  /// Export student data
  /// 
  /// [format] - Format for the export (CSV, JSON, Excel, PDF)
  /// [destinationPath] - Path where the export file will be saved
  /// [options] - Export configuration options
  /// 
  /// Returns export result with file information
  /// Throws [UnsupportedExportFormatException] if format is not supported
  /// Throws [InvalidExportDestinationException] if destination path is invalid
  /// Throws [ExportOperationException] if export operation fails
  /// Throws [DatabaseException] if data retrieval fails
  Future<ExportResult> exportStudents(
    ExportFormat format,
    String destinationPath, {
    ExportOptions? options,
  });

  /// Export registration session data
  /// 
  /// [format] - Format for the export (CSV, JSON, Excel, PDF)
  /// [destinationPath] - Path where the export file will be saved
  /// [options] - Export configuration options
  /// 
  /// Returns export result with file information
  /// Throws [UnsupportedExportFormatException] if format is not supported
  /// Throws [InvalidExportDestinationException] if destination path is invalid
  /// Throws [ExportOperationException] if export operation fails
  /// Throws [DatabaseException] if data retrieval fails
  Future<ExportResult> exportRegistrationSessions(
    ExportFormat format,
    String destinationPath, {
    ExportOptions? options,
  });

  /// Export selected frame data
  /// 
  /// [format] - Format for the export (CSV, JSON, Excel, PDF)
  /// [destinationPath] - Path where the export file will be saved
  /// [options] - Export configuration options
  /// 
  /// Returns export result with file information
  /// Throws [UnsupportedExportFormatException] if format is not supported
  /// Throws [InvalidExportDestinationException] if destination path is invalid
  /// Throws [ExportOperationException] if export operation fails
  /// Throws [DatabaseException] if data retrieval fails
  Future<ExportResult> exportSelectedFrames(
    ExportFormat format,
    String destinationPath, {
    ExportOptions? options,
  });

  /// Export administrator data
  /// 
  /// [format] - Format for the export (CSV, JSON, Excel, PDF)
  /// [destinationPath] - Path where the export file will be saved
  /// [options] - Export configuration options
  /// 
  /// Returns export result with file information
  /// Throws [UnsupportedExportFormatException] if format is not supported
  /// Throws [InvalidExportDestinationException] if destination path is invalid
  /// Throws [ExportOperationException] if export operation fails
  /// Throws [DatabaseException] if data retrieval fails
  Future<ExportResult> exportAdministrators(
    ExportFormat format,
    String destinationPath, {
    ExportOptions? options,
  });

  /// Export system reports
  /// 
  /// [format] - Format for the export (CSV, JSON, Excel, PDF)
  /// [destinationPath] - Path where the export file will be saved
  /// [reportType] - Type of system report to export
  /// [options] - Export configuration options
  /// 
  /// Returns export result with file information
  /// Throws [UnsupportedExportFormatException] if format is not supported
  /// Throws [InvalidExportDestinationException] if destination path is invalid
  /// Throws [ExportOperationException] if export operation fails
  /// Throws [DatabaseException] if data retrieval fails
  Future<ExportResult> exportSystemReports(
    ExportFormat format,
    String destinationPath,
    String reportType, {
    ExportOptions? options,
  });

  /// Export custom data based on query
  /// 
  /// [format] - Format for the export (CSV, JSON, Excel, PDF)
  /// [destinationPath] - Path where the export file will be saved
  /// [query] - Custom query for data selection
  /// [options] - Export configuration options
  /// 
  /// Returns export result with file information
  /// Throws [UnsupportedExportFormatException] if format is not supported
  /// Throws [InvalidExportDestinationException] if destination path is invalid
  /// Throws [ExportOperationException] if export operation fails
  /// Throws [ValidationException] if query is invalid
  /// Throws [DatabaseException] if data retrieval fails
  Future<ExportResult> exportCustomData(
    ExportFormat format,
    String destinationPath,
    String query, {
    ExportOptions? options,
  });

  /// Get supported export formats for a data type
  /// 
  /// [dataType] - Type of data to export
  /// 
  /// Returns list of supported formats for the data type
  List<ExportFormat> getSupportedFormats(ExportDataType dataType);

  /// Validate export destination path
  /// 
  /// [path] - Path to validate
  /// [format] - Export format
  /// 
  /// Returns true if path is valid for the format
  /// Throws [InvalidExportDestinationException] if path is invalid
  Future<bool> validateDestinationPath(String path, ExportFormat format);

  /// Get export preview (first few records)
  /// 
  /// [dataType] - Type of data to preview
  /// [options] - Export configuration options
  /// [previewLimit] - Number of records to include in preview (default: 10)
  /// 
  /// Returns a map containing preview data
  /// Throws [DatabaseException] if data retrieval fails
  Future<Map<String, dynamic>> getExportPreview(
    ExportDataType dataType, {
    ExportOptions? options,
    int previewLimit = 10,
  });

  /// Get estimated export size
  /// 
  /// [dataType] - Type of data to export
  /// [format] - Export format
  /// [options] - Export configuration options
  /// 
  /// Returns estimated file size in bytes
  /// Throws [DatabaseException] if data retrieval fails
  Future<int> getEstimatedExportSize(
    ExportDataType dataType,
    ExportFormat format, {
    ExportOptions? options,
  });

  /// Cancel an ongoing export operation
  /// 
  /// [exportId] - ID of the export operation to cancel
  /// 
  /// Returns true if cancellation was successful
  Future<bool> cancelExport(String exportId);

  /// Get export history
  /// 
  /// [limit] - Maximum number of export records to return (default: 50)
  /// [offset] - Number of records to skip (default: 0)
  /// [dataType] - Filter by data type (optional)
  /// [startDate] - Filter exports after this date (optional)
  /// [endDate] - Filter exports before this date (optional)
  /// 
  /// Returns list of export results
  /// Throws [DatabaseException] if data retrieval fails
  Future<List<ExportResult>> getExportHistory({
    int limit = 50,
    int offset = 0,
    ExportDataType? dataType,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Clean up old export files
  /// 
  /// [retentionPeriod] - Files older than this duration will be deleted
  /// 
  /// Returns number of files cleaned up
  /// Throws [FileOperationException] if cleanup fails
  Future<int> cleanupOldExports(Duration retentionPeriod);

  /// Get available disk space for exports
  /// 
  /// Returns available space in bytes
  /// Throws [FileSystemException] if unable to check disk space
  Future<int> getAvailableDiskSpace();

  /// Compress export file
  /// 
  /// [filePath] - Path to the file to compress
  /// [compressionLevel] - Compression level (1-9, default: 6)
  /// 
  /// Returns path to the compressed file
  /// Throws [FileOperationException] if compression fails
  Future<String> compressExportFile(
    String filePath, {
    int compressionLevel = 6,
  });

  /// Schedule export operation
  /// 
  /// [dataType] - Type of data to export
  /// [format] - Export format
  /// [destinationPath] - Path where the export file will be saved
  /// [scheduledTime] - When to perform the export
  /// [options] - Export configuration options
  /// 
  /// Returns scheduled export ID
  /// Throws [ValidationException] if schedule parameters are invalid
  Future<String> scheduleExport(
    ExportDataType dataType,
    ExportFormat format,
    String destinationPath,
    DateTime scheduledTime, {
    ExportOptions? options,
  });

  /// Get scheduled exports
  /// 
  /// Returns list of scheduled export operations
  Future<List<Map<String, dynamic>>> getScheduledExports();

  /// Cancel scheduled export
  /// 
  /// [scheduleId] - ID of the scheduled export to cancel
  /// 
  /// Returns true if cancellation was successful
  Future<bool> cancelScheduledExport(String scheduleId);

  /// Export data with encryption
  /// 
  /// [dataType] - Type of data to export
  /// [format] - Export format
  /// [destinationPath] - Path where the export file will be saved
  /// [encryptionKey] - Key for encrypting the export file
  /// [options] - Export configuration options
  /// 
  /// Returns export result with encrypted file information
  /// Throws [ExportOperationException] if export or encryption fails
  Future<ExportResult> exportWithEncryption(
    ExportDataType dataType,
    ExportFormat format,
    String destinationPath,
    String encryptionKey, {
    ExportOptions? options,
  });
}