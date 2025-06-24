# TODO

This document tracks planned features, improvements, and known issues for the JW Player VTT Transcription Upload Tool.

## Planned Features

### v1.1.0 - Configuration Management
- [ ] Update and merge config file functionality
- [ ] Configuration file validation improvements
- [ ] Support for partial config updates

### v1.2.0 - Multi-language Support
- [ ] Multi-language uploads from single batch
- [ ] Language auto-detection from filename patterns
- [ ] Batch operations with different languages per file
- [ ] Language-specific directory processing
- [ ] Support for language code mapping files

### v1.3.0 - Monitoring and Reporting
- [ ] Progress bar for batch operations
- [ ] Summary reports (CSV/JSON output)
- [ ] Integration with monitoring systems (Prometheus metrics)
- [ ] Email notifications for batch completions
- [ ] Webhook support for external integrations

## Improvements

### Performance
- [ ] Optimize API request batching
- [ ] Implement connection pooling
- [ ] Add compression for large VTT files
- [ ] Cache media ID validation results
- [ ] Implement smarter rate limiting

### Error Handling
- [ ] More granular error categorization
- [ ] Automatic error recovery strategies
- [ ] Enhanced logging with structured data
- [ ] Error reporting to external services
- [ ] Better handling of network timeouts

### Configuration
- [ ] JSON Schema validation for config files
- [ ] Configuration file encryption
- [ ] Dynamic configuration reloading
- [ ] Configuration templates for common use cases
- [ ] Validation of API credentials on startup

## Known Issues

### Minor Issues
- [ ] Log rotation not implemented (relies on external logrotate)
- [ ] No built-in VTT file validation
- [ ] Limited error context for API failures
- [ ] No support for custom HTTP headers

### Enhancement Requests
- [ ] Support for subtitle timing adjustments
- [ ] Integration with subtitle editing tools
- [ ] Support for multiple JW Player accounts
- [ ] Automated testing framework

## Research Items

### API Enhancements
- [ ] Investigate JW Player API v3 when available
- [ ] Research bulk upload endpoints
- [ ] Explore webhook integration possibilities
- [ ] Investigate streaming upload for large files
- [ ] Research API rate limit optimization

### Technology Alternatives
- [ ] Python version for cross-platform compatibility
- [ ] Go version for better performance
- [ ] Node.js version for npm distribution
- [ ] Rust version for system-level integration
- [ ] PowerShell version for Windows environments

## Contributions Welcome

The following items are good candidates for community contributions:

- [ ] Additional language support and translations
- [ ] Platform-specific installation scripts
- [ ] Integration with popular video processing tools
- [ ] Custom output formatters
- [ ] Performance benchmarking tools

## Completed

### v1.0.0 - Initial Release ✅
- [x] Core upload functionality
- [x] Configuration system
- [x] Command-line interface
- [x] Error handling and logging
- [x] Documentation
- [x] Single file and batch processing
- [x] Rate limiting and retries
- [x] Dry run mode
- [x] Force overwrite capability