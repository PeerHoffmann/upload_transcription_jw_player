[![Donate](https://img.shields.io/badge/Donate-PayPal-blue)](https://www.paypal.me/peerhoffmann)

If you find this project helpful, consider supporting me with a small donation.

# JW Player VTT Transcription Upload Tool

A production-ready bash script for automatically uploading VTT transcription files to JW Player via their Management API v2. Supports both single file and batch processing modes with comprehensive error handling, logging, and configuration management.

## Features

- **Dual Processing Modes**: Single file or batch directory processing
- **Robust API Integration**: JW Player Management API v2 with rate limiting and retry logic  
- **Flexible Configuration**: JSON-based configuration with validation
- **Comprehensive Logging**: Timestamped logs with configurable verbosity
- **Error Handling**: Automatic retries, meaningful error messages, and graceful failures
- **Security**: Secure credential management and input validation
- **Language Support**: Full internationalization with ISO 639-1 language codes
- **Track Customization**: Support for all JW Player track kinds and custom labels
- **Dry Run Mode**: Preview operations without making actual uploads
- **Force Mode**: Overwrite existing transcriptions when needed

## Installation

### Prerequisites

The script requires the following system dependencies:

- **bash** (version 4.0 or higher)
- **curl** - HTTP client for API requests
- **jq** - JSON processor for configuration parsing

### Package Manager Installation

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install curl jq git
```

#### CentOS/RHEL/Fedora
```bash
# CentOS/RHEL 7/8
sudo yum install curl jq git

# Fedora/RHEL 9+
sudo dnf install curl jq git
```

#### Arch Linux
```bash
sudo pacman -S curl jq git
```

#### Alpine Linux
```bash
sudo apk add curl jq git bash
```

### Installation Methods

#### Method 1: Git Clone (Recommended)
```bash
git clone https://github.com/PeerHoffmann/upload_transcription_jw_player.git
cd upload_transcription_jw_player
chmod +x upload_transcriptions.sh
```

#### Method 2: Direct Download
```bash
wget https://github.com/PeerHoffmann/upload_transcription_jw_player/archive/main.zip
unzip main.zip
cd upload_transcription_jw_player-main
chmod +x upload_transcriptions.sh
```

#### Method 3: Manual Installation
```bash
mkdir upload_transcription_jw_player
cd upload_transcription_jw_player
# Download files manually from https://github.com/PeerHoffmann/upload_transcription_jw_player
chmod +x upload_transcriptions.sh
```

### Verification
Verify the installation by running:
```bash
./upload_transcriptions.sh --version
./upload_transcriptions.sh --help
```

## Updating

### Git-based Installation (Recommended)

#### Method 1: Clean Update (Preserves Config)
```bash
cd upload_transcription_jw_player

# Backup your config file
cp config.json config.json.backup

# Check for local changes
git status

# If you have uncommitted changes to config.json only:
git stash push -m "backup local config" config.json

# Pull latest updates
git pull origin main

# Restore your config
git stash pop
# OR if stash fails:
cp config.json.backup config.json
```

#### Method 2: Force Update (When Conflicts Occur)
```bash
cd upload_transcription_jw_player

# Backup your config file
cp config.json config.json.backup

# Reset to match remote exactly
git fetch origin main
git reset --hard origin/main

# Restore your config
cp config.json.backup config.json
```

#### Method 3: Fresh Clone
```bash
# Backup your config
cp upload_transcription_jw_player/config.json config.json.backup

# Remove old installation
rm -rf upload_transcription_jw_player

# Fresh clone
git clone https://github.com/PeerHoffmann/upload_transcription_jw_player.git
cd upload_transcription_jw_player
chmod +x upload_transcriptions.sh

# Restore your config
cp ../config.json.backup config.json
```

### Direct Download Installation
For non-git installations:
```bash
# Backup your config
cp config.json config.json.backup

# Download latest version
wget https://github.com/PeerHoffmann/upload_transcription_jw_player/archive/main.zip
unzip main.zip

# Replace script files
cp upload_transcription_jw_player-main/upload_transcriptions.sh .
chmod +x upload_transcriptions.sh

# Clean up
rm -rf upload_transcription_jw_player-main main.zip

# Restore your config
cp config.json.backup config.json
```

### Verify Update
```bash
./upload_transcriptions.sh --version
```

## Configuration

### Initial Setup

1. **Copy the example configuration**:
   ```bash
   cp config.json.example config.json
   ```

2. **Edit the configuration file**:
   ```bash
   nano config.json  # or your preferred editor
   ```

3. **Configure required settings**:
   - Set your JW Player API key in `api.key`
   - Set your JW Player site ID in `api.site_id`
   - Update file paths as needed

### Configuration Reference

The `config.json` file contains the following sections:

#### API Configuration
```json
{
  "api": {
    "key": "your_jwplayer_api_key",
    "site_id": "your_site_id",
    "base_url": "https://api.jwplayer.com",
    "rate_limit": {
      "requests_per_minute": 60,
      "retry_delay": 5
    }
  }
}
```

#### File Paths
```json
{
  "paths": {
    "vtt_directory": "/path/to/your/vtt/files",
    "log_file": "/var/log/jw_upload.log"
  }
}
```

#### Upload Settings
```json
{
  "upload": {
    "max_retries": 3,
    "timeout": 30,
    "chunk_size": 1024
  }
}
```

#### Text Track Defaults
```json
{
  "text_tracks": {
    "default_language": "en",
    "default_kind": "captions",
    "default_label": "Auto-generated captions",
    "set_as_default": false
  }
}
```

### Getting JW Player Credentials

1. **API Key**: 
   - Log into your JW Player dashboard
   - Go to Settings > API Credentials
   - Generate a new API key with appropriate permissions

2. **Site ID**:
   - Found in your JW Player dashboard URL
   - Format: 8-character alphanumeric string

## Usage

### Command Line Syntax

```bash
./upload_transcriptions.sh [OPTIONS] [FILE]
```

### Arguments

- **FILE**: Single VTT file to upload (optional)

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-d, --directory PATH` | Directory containing VTT files | From config |
| `-c, --config FILE` | Configuration file path | `./config.json` |
| `-l, --log FILE` | Log file path | From config |
| `-k, --kind TYPE` | Track kind (captions, subtitles, chapters, descriptions, metadata) | `captions` |
| `-g, --language CODE` | Language code (ISO 639-1 format) | `en` |
| `-b, --label TEXT` | Human-readable label for the track | Auto-generated |
| `--default` | Set track as default track | `false` |
| `-n, --dry-run` | Preview mode - no actual uploads | `false` |
| `-f, --force` | Overwrite existing transcriptions | `false` |
| `-v, --verbose` | Verbose output | `false` |
| `-h, --help` | Show help message | - |
| `--version` | Show version information | - |

### Usage Examples

#### Basic Usage
```bash
# Process default directory from config
./upload_transcriptions.sh

# Upload single file
./upload_transcriptions.sh media123.vtt

# Process specific directory
./upload_transcriptions.sh -d /path/to/vtt/files
```

#### Advanced Usage
```bash
# Preview single file upload
./upload_transcriptions.sh --dry-run media123.vtt

# Upload Spanish subtitles
./upload_transcriptions.sh -g es -k subtitles media123.vtt

# Upload French captions as default track
./upload_transcriptions.sh --language fr --default media123.vtt

# Batch process with custom label
./upload_transcriptions.sh -b "Professional Captions" -d /media/captions/

# Force overwrite existing transcriptions
./upload_transcriptions.sh --force -d /updated/captions/

# Verbose output with custom log file
./upload_transcriptions.sh -v -l /tmp/upload.log media123.vtt
```

### File Naming Convention

VTT files should be named using the JW Player media ID:
```
media_id.vtt
```

Examples:
- `abc123.vtt` → Media ID: `abc123`
- `xyz789.vtt` → Media ID: `xyz789`
- `my-video-001.vtt` → Media ID: `my-video-001`

### Processing Modes

#### Single File Mode
Automatically detected when a file is provided as an argument:
```bash
./upload_transcriptions.sh media123.vtt
```

#### Batch Directory Mode
Automatically detected when no file argument is provided:
```bash
./upload_transcriptions.sh -d /path/to/vtt/files
```

## Logging and Monitoring

### Log Levels
- **INFO**: General operation information
- **WARN**: Warning messages for non-critical issues  
- **ERROR**: Error messages for failed operations
- **DEBUG**: Detailed debugging information (requires `-v` flag)

### Log Format
```
[2024-01-15 14:30:25] [INFO] Successfully uploaded media123.vtt to media ID media123
[2024-01-15 14:30:26] [ERROR] Upload failed for media456.vtt (HTTP 404): Media not found
```

### Monitoring Commands
```bash
# Follow log in real-time
tail -f /var/log/jw_upload.log

# Check recent errors
grep ERROR /var/log/jw_upload.log | tail -10

# Monitor upload progress
grep "Successfully uploaded" /var/log/jw_upload.log | wc -l
```

## Error Handling

### Exit Codes
- **0**: All uploads successful
- **1**: Some uploads failed
- **2**: Configuration error
- **3**: No VTT files found

### Common Issues and Solutions

#### Missing Dependencies
```bash
# Error: Missing required dependencies: jq curl
sudo apt-get install curl jq
```

#### Configuration Errors
```bash
# Error: Please configure your JW Player API key
nano config.json  # Edit api.key field
```

#### File Permission Issues
```bash
# Error: VTT file not readable
chmod 644 *.vtt
```

#### API Authentication
```bash
# Error: HTTP 401 - Unauthorized
# Check API key and site ID in config.json
```

#### Rate Limiting
```bash
# Warning: Rate limit exceeded, waiting 5 seconds
# Script automatically handles rate limiting with backoff
```

## Tools & Dependencies

### Core Dependencies
- **[curl](https://curl.se/)** - HTTP client for API requests | [GitHub](https://github.com/curl/curl) | [Docs](https://curl.se/docs/)
- **[jq](https://jqlang.github.io/jq/)** - JSON processor for configuration parsing | [GitHub](https://github.com/jqlang/jq) | [Manual](https://jqlang.github.io/jq/manual/)
- **[Bash](https://www.gnu.org/software/bash/)** - Shell scripting environment (v4.0+) | [Manual](https://www.gnu.org/software/bash/manual/)

### System Requirements
- **Linux** - Any modern Linux distribution
- **Bash** - Version 4.0 or higher
- **Internet Connection** - For API communication with JW Player

### APIs & Services
- **[JW Player Management API v2](https://docs.jwplayer.com/platform/reference/)** - Video platform API for transcription uploads | [GitHub](https://github.com/jwplayer) | [Rate Limits](https://docs.jwplayer.com/platform/reference/overview)

## Development

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Testing
```bash
# Test with dry run mode
./upload_transcriptions.sh --dry-run test.vtt

# Test configuration validation
./upload_transcriptions.sh -c invalid-config.json

# Test different file scenarios
./upload_transcriptions.sh nonexistent.vtt
```

## Security Considerations

- API keys are never logged or displayed
- Configuration file should have restricted permissions: `chmod 600 config.json`
- Log files may contain media IDs but no sensitive credentials
- All input parameters are validated and sanitized
- HTTPS is used for all API communications

## Troubleshooting

### Debug Mode
Enable verbose logging for detailed troubleshooting:
```bash
./upload_transcriptions.sh -v media123.vtt
```

### Common Diagnostics
```bash
# Check script dependencies
command -v curl jq

# Validate configuration
jq empty config.json

# Test API connectivity
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.jwplayer.com/v2/sites/YOUR_SITE_ID/media/
```

### Getting Help
- Check the log files for detailed error messages
- Use `--dry-run` to test operations safely
- Enable `--verbose` for additional debugging information
- Verify your JW Player API credentials and permissions

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Support

For issues, questions, or contributions:
- Create an issue on GitHub
- Check existing documentation
- Review log files for error details

---
[![Donate](https://img.shields.io/badge/Donate-PayPal-blue)](https://www.paypal.me/peerhoffmann)

If you find this project helpful, consider supporting me with a small donation.

More information about me and my projects can be found at https://www.peer-hoffmann.de.

If you need support with search engine optimization for your website, online shop, or international project, feel free to contact me at https://www.om96.de.