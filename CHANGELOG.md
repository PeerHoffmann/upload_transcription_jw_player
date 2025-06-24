# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.5] - 2025-06-24

### Fixed
- Increase connection timeout values to prevent HTTP 000000 errors
- Simplify metadata field to use empty JSON with proper content-type header
- Improve connection error messages and debugging information

### Changed
- Increase connect-timeout from 30s to 60s for better reliability
- Increase max-time from 90s to 180s for large file uploads
- Use simplified metadata format: `{};type=application/json`

## [1.0.4] - 2025-06-24

### Fixed
- Comprehensive fix for metadata field handling in JW Player API requests
- Add automatic fallback to upload without metadata field if API rejects it
- Improve metadata JSON formatting with proper shell quoting
- Move metadata field to top of form data for better API compatibility

### Added
- Enhanced debug logging showing exact curl commands being executed
- Automatic retry mechanism without metadata field for compatibility
- Better error messages for metadata-related API failures

### Changed
- Improved error handling for HTTP 400 "metadata is required" responses

## [1.0.3] - 2025-06-24

### Fixed
- Enhance metadata field with actual content including language, type, and title

## [1.0.2] - 2025-06-24

### Fixed
- Fix API field name from 'language' to 'srclang' to match JW Player API specification
- Add required metadata field to resolve upload errors
- Correct API request structure based on JW Player documentation

## [1.0.1] - 2025-06-24

### Fixed
- Remove problematic metadata field from API requests to resolve upload errors
- Update version number to reflect bug fixes

### Changed
- Simplified API request structure based on JW Player documentation

## [1.0.0] - 2025-06-23

### Added
- Initial release of JW Player VTT Transcription Upload Tool
- Comprehensive bash script for uploading VTT files to JW Player API v2
- JSON-based configuration system with validation
- Support for both single file and batch directory processing
- Automatic mode detection based on input parameters
- Command-line interface with extensive options
- Rate limiting and retry logic for API requests
- Comprehensive error handling and meaningful error messages
- Timestamped logging system with configurable verbosity
- Dry run mode for testing operations without uploads
- Force mode for overwriting existing transcriptions
- Support for all JW Player text track kinds:
  - captions
  - subtitles
  - chapters
  - descriptions
  - metadata
- International language support with ISO 639-1 codes
- Custom track labeling with intelligent defaults
- Media ID validation before upload attempts
- Security features:
  - Input validation and sanitization
  - Secure credential handling
  - No logging of sensitive data
- Comprehensive documentation:
  - Installation guide with multiple methods
  - Configuration reference
  - Usage examples
  - Troubleshooting guide
  - API integration details
- Exit codes for integration with automation systems:
  - 0: Success
  - 1: Partial failure
  - 2: Configuration error
  - 3: No files found

### Features
- **Dual Processing Modes**: Automatic detection of single file vs batch processing
- **API Integration**: Full JW Player Management API v2 support
- **Configuration Management**: JSON-based config with schema validation
- **Error Resilience**: Automatic retries with exponential backoff
- **Progress Tracking**: Real-time progress reporting for batch operations
- **Flexible Output**: Multiple verbosity levels and structured logging
- **Production Ready**: Comprehensive error handling and security measures

### Dependencies
- bash (version 4.0+)
- curl (HTTP client)
- jq (JSON processor)

### Supported Platforms
- Linux (all major distributions)
- macOS (with bash 4.0+)
- Windows (WSL/Cygwin/Git Bash)

[Unreleased]: https://github.com/yourusername/jw-player-vtt-upload/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/jw-player-vtt-upload/releases/tag/v1.0.0