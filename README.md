# Apple Music ALAC / Dolby Atmos Downloader

[English](#) / [简体中文](./README-CN.md)

> [!WARNING]
> **⚠️ Experimental Branch Warning**
> 
> This is a personal experimental branch with extensive modifications. It contains numerous unknown bugs and risks. Use at your own risk!
> 
> This branch includes experimental features that have not been fully tested and may cause data loss, download failures, or other unforeseen issues. For production use, please use the official stable release.

**A powerful Apple Music downloader supporting high-quality audio formats including ALAC, Dolby Atmos, Hi-Res Lossless, and Music Videos.**

Original script by Sorrow. Enhanced with numerous improvements and optimizations.

---

## 🎉 What's New (v2.6.0)

### 🚀 v2.6.0 - Architecture Refactor & System Optimization (2025-10-11)

#### 🏗️ Architecture Refactor
- **Unified Logging System** - New `internal/logger` module with 4-level log control (DEBUG/INFO/WARN/ERROR)
- **Progress Event System** - Observer pattern event architecture, decoupling UI updates from business logic
- **Smart UI Simplification** - Adaptive terminal width display (FullMode/CompactMode/MinimalMode)
- **Album Metadata Fix** - Album and AlbumSort fields now include quality tags (e.g., "Head Hunters Hi-Res Lossless")

#### ⚡ Performance Optimization
- **Reduced UI Refresh Rate** - From 200ms to intelligent refresh, lowering CPU usage
- **Optimized Logger Performance** - Support for high-concurrency logging scenarios
- **Improved Progress Event Distribution** - Enhanced multi-task concurrency efficiency

#### 🐛 Critical Fixes
- **Log Duplication Issue** - Fixed logger output interfering with UI cursor positioning (redirected logger to stderr)
- **UI Rendering Misalignment** - Fixed line overflow and scrolling issues caused by long track names
- **Metadata Quality Tags** - Fixed music management software unable to distinguish different quality versions of the same album

### 🎯 v2.5.0 - Metadata & Naming Convention Improvements (2025-10-10)

> [!IMPORTANT]
> **⭐ Core Feature: Album Folder Naming & Metadata Quality Tags**
> 
> This is a critical feature designed to solve the problem of music management software (like Plex/Emby/Jellyfin) being unable to distinguish different quality versions of the same album.
> 
> **Features:**
> - ✅ **Album Folder Tags** - Quality tags added to folder names (e.g., `Head Hunters Alac/`)
> - ✅ **Metadata Quality Tags** - ALBUM and ALBUMSORT fields include quality tags (e.g., `ALBUM = "Head Hunters Alac"`)
> - ✅ **Perfect Sync** - Folder names and metadata stay consistent
> - ✅ **Configurable** - Flexibly control via configuration file
> 
> **Use Cases:**
> - 📚 Collecting multiple quality versions of the same album (Alac, Hi-Res, Atmos, AAC)
> - 🎵 Using Plex/Emby/Jellyfin music servers
> - 💿 Need precise album version management
> 
> **Configuration:**
> ```yaml
> # config.yaml
> add-quality-tag-to-folder: true      # Folder names include quality tags
> add-quality-tag-to-metadata: true    # Metadata includes quality tags
> ```

#### Album Metadata Quality Tags
- **Album and AlbumSort Fields** - Add quality tags to ALBUM and ALBUMSORT fields in metadata
- **Fix Recognition Issues** - Ensure music management software correctly identifies different quality versions
- **All Quality Support** - Alac / Hi-Res Lossless / Dolby Atmos / Aac 256
- **Compatibility** - Perfect support for iTunes / Plex / Emby / Jellyfin

**Example Effect:**
```
Album Folder: Head Hunters Hi-Res Lossless/
Track Metadata: ALBUM = "Head Hunters Hi-Res Lossless"
               ALBUMSORT = "Head Hunters Hi-Res Lossless"
```

### 📊 Recent Major Updates

#### v2.3.0 - MV Download Enhancement (2025-10-09)
- **🎬 MV Quality Display** - Automatic detection and display of video quality (4K/1080P/720P/480P)
- **📈 True Progress Tracking** - Fixed MV download progress to show actual total size instead of segment size
- **🎨 UI Optimization** - Streamlined progress bars with clear video/audio stream labels

#### v2.2.0 - UI & Logging Governance (2025-10-09)
- **🌏 Chinese Help Menu** - Complete localization of `--help` parameter descriptions
- **✨ Emoji Enhancement** - Beautiful terminal output with contextual emoji icons
- **🔧 Thread-Safe Logging** - OutputMutex + SafePrintf for clean concurrent logs

#### v2.1.0 - Performance & UX Improvements (2025-10-09)
- **⚡ Cache Transfer Mechanism** - 50-70% faster downloads for NFS/network storage
- **🔍 Interactive File Check** - Smart prompts for existing files with skip options
- **🎯 Quality Tag Standardization** - Emby-compatible MV paths and unified quality tags

### 📈 Improvements Summary
- **Code Quality**: Complete refactor, new unit tests, concurrency safety verification (go test -race)
- **User Experience**: Emoji-rich output, Chinese localization, smart UI simplification, clearer progress indicators
- **Performance**: Concurrent downloads, intelligent caching, reduced network overhead, optimized UI refresh
- **Documentation**: 15 technical documents, comprehensive changelog, detailed configuration guides

---

## ✨ Features

### 🎵 Audio Quality Support
- **ALAC (Audio Lossless)** - `audio-alac-stereo`
- **Dolby Atmos / EC3** - `audio-atmos` / `audio-ec3`
- **Hi-Res Lossless** - Up to 24-bit/192kHz
- **AAC Formats** - `audio-stereo`, `audio-stereo-binaural`, `audio-stereo-downmix`
- **AAC-LC** - `audio-stereo` (requires subscription)

### 📹 Music Video Support
- **4K/1080p/720p** resolution options
- **Emby/Jellyfin compatible** naming structure
- **Multiple audio tracks** (Atmos/AC3/AAC)
- Separate save folder configuration

### 🎼 Rich Metadata & Lyrics
- **Embedded covers** and artwork (up to 5000x5000)
- **Synchronized LRC lyrics** (word-by-word / syllable-by-syllable)
- **Translation and pronunciation** lyrics support (Beta)
- **Animated artwork** for Emby/Jellyfin
- Complete metadata tagging

### ⚡ Performance Optimizations
- **Cache transfer mechanism** - 50-70% faster for NFS/network storage
- **Parallel downloading** - Multi-threaded chunk downloads
- **Smart file checking** - Skip already downloaded files
- **Batch downloads** from TXT file with configurable thread count

### 🛠️ Advanced Features
- **Multi-account rotation** - Automatic account selection based on storefront
- **FFmpeg auto-fix** - Detect and repair encoding issues
- **Interactive mode** - Arrow-key navigation for search results
- **Artist download** - Download all albums/MVs from an artist page
- **Custom naming** - Flexible folder and file naming formats
- **Output modes** - Dynamic UI or pure log mode (`--no-ui`)

---

## 📋 Prerequisites

### Required Dependencies

1. **[MP4Box](https://gpac.io/downloads/gpac-nightly-builds/)** - Must be installed and added to system PATH
2. **[wrapper](https://github.com/zhaarey/wrapper)** - Decryption service must be running
3. **[mp4decrypt](https://www.bento4.com/downloads/)** - Required for Music Video downloads
4. **FFmpeg** (Optional) - For animated artwork and auto-fix features

### System Requirements
- Go 1.23.1 or higher
- 8GB+ RAM recommended
- 50GB+ free disk space (if using cache mechanism)

> [!NOTE]
> **💡 Disk Space Recommendations**
> 
> - **Without cache**: Only need enough space to store downloaded files
> - **With cache mechanism**: Additional 50GB+ local temporary space required
> - **Large-scale batch downloads**: Recommend 100GB+ space for optimal performance

---

## 🚀 Quick Start

### 1. Installation

```bash
# Clone the repository
git clone https://github.com/your-repo/apple-music-downloader.git
cd apple-music-downloader

# Install dependencies
go mod tidy

# Build the binary
go build -o apple-music-downloader main.go
```

### 2. Configuration

```bash
# Copy the example config
cp config.yaml.example config.yaml

# Edit with your tokens
nano config.yaml
```

**Get your `media-user-token`:**
1. Open [Apple Music](https://music.apple.com) and log in
2. Press `F12` to open Developer Tools
3. Navigate to `Application` → `Cookies` → `https://music.apple.com`
4. Find `media-user-token` cookie and copy its value
5. Paste into `config.yaml`

### 3. Basic Usage

```bash
# Download an album
./apple-music-downloader https://music.apple.com/us/album/album-name/123456789

# Download with Dolby Atmos
./apple-music-downloader --atmos https://music.apple.com/us/album/album-name/123456789

# Download a single song
./apple-music-downloader --song https://music.apple.com/us/album/album/123?i=456

# Download a playlist
./apple-music-downloader https://music.apple.com/us/playlist/playlist-name/pl.xxxxx

# Download all from an artist
./apple-music-downloader https://music.apple.com/us/artist/artist-name/123456

# Interactive search
./apple-music-downloader --search song "search term"
./apple-music-downloader --search album "album name"
./apple-music-downloader --search artist "artist name"

# Batch download from TXT file
./apple-music-downloader urls.txt

# Pure log mode (for CI/debugging)
./apple-music-downloader --no-ui https://music.apple.com/...
```

---

## 📖 Advanced Usage

### Cache Mechanism (NFS Optimization)

> [!IMPORTANT]
> **⚠️ Cache Mechanism Important Notes**
> 
> **Recommended Use Cases:**
> - ✅ Target path is NFS/SMB or other network file systems
> - ✅ Local machine has 50GB+ available disk space (SSD recommended)
> - ✅ Frequent batch download tasks
> 
> **Key Considerations:**
> - ⚠️ **Disk Space**: Cache folder needs sufficient temporary storage space, recommend at least 50GB
> - ⚠️ **Cache Path**: Must use local fast disk (SSD), do not set on NFS or other network paths
> - ⚠️ **File System**: Cross-filesystem transfers will use copy method, speed will be reduced
> - ⚠️ **Cleanup Mechanism**: Program automatically cleans up successfully transferred cache, also auto-rollback on failure
> - ⚠️ **Manual Cleanup**: You can manually delete the `Cache` folder at any time, program will auto-rebuild
> 
> **Performance Boost Data (Real Tests):**
> - Download time improvement: **50-70%**
> - Network I/O reduction: **90%+**
> - Better stability: Atomic operations, automatic rollback on failure

Significantly improves performance when downloading to network storage (NFS/SMB):

```yaml
# config.yaml
enable-cache: true
cache-folder: "./Cache"  # Local SSD path recommended
```

**Configuration Recommendations:**
- ⚡ **Local SSD Cache** - Set `cache-folder` to a local SSD path (e.g., `/ssd/cache/apple-music`)
- ⚡ **Network Storage Target** - Set `alac-save-folder` and `atmos-save-folder` to NFS/SMB paths
- ⚡ **Sufficient Space** - Ensure cache path has at least 50GB available space

**How It Works:**
1. Files are first downloaded to local cache folder
2. All processing (decryption, merging, metadata) completed locally
3. After completion, batch transfer to target network path
4. Automatically clean up cache, free space

[📚 Read Cache Mechanism Documentation](./CACHE_MECHANISM.md)

### History Records & Resume Downloads

> [!TIP]
> **🔄 Smart Resume Downloads**
> 
> Batch download tasks support automatic history records and resume downloads functionality, allowing tasks to continue from breakpoints after interruption.

**Automatic Features:**
- 📁 Automatically record each batch task in the `history` folder
- 🔍 Automatically detect and skip completed albums before starting new tasks
- ⏸️ Support resuming from breakpoints after task interruption, avoiding duplicate downloads

**Usage Example:**
```bash
# First run
./apple-music-downloader ClassicAlbums.txt

# After interruption, run again (automatically skip completed)
./apple-music-downloader ClassicAlbums.txt
# Output: 📜 History record detected: Found 20 completed tasks
#         ⏭️  Automatically skipped, 43 tasks remaining
```

**Advanced Usage:**
```bash
# View history records
ls -lh history/

# Clear history records (re-download all content)
rm -rf history/
```

[📚 Read History Records Feature Documentation](./HISTORY_FEATURE.md)

### Logging Configuration (v2.6.0+)

**Unified logging system** with 4-level log control and flexible configuration:

```yaml
# config.yaml
logging:
  level: info                  # debug/info/warn/error
  output: stdout               # stdout/stderr/file path
  show_timestamp: false        # Recommend off for UI mode
```

**Log Level Descriptions:**
- `debug` - Show all debug information (for development and troubleshooting)
- `info` - Show general information (default, recommended)
- `warn` - Only show warnings and errors
- `error` - Only show error messages

**Output Targets:**
- `stdout` - Standard output (default)
- `stderr` - Standard error output (automatically used in UI mode)
- File path - e.g., `./logs/download.log`

**Usage Recommendations:**
- Dynamic UI mode: `show_timestamp: false` to avoid timestamp interference with UI
- Pure log mode (`--no-ui`): `show_timestamp: true` for better traceability
- CI/CD environment: Use `--no-ui` + log file output

### Custom Naming Formats

> [!TIP]
> **🏷️ Quality Tag Configuration (v2.5.0+)**
> 
> From v2.5.0, you can flexibly control where quality tags appear:
> 
> ```yaml
> # config.yaml - Quality tag configuration
> add-quality-tag-to-folder: true      # Folder names include quality tags
> add-quality-tag-to-metadata: true    # Metadata includes quality tags
> ```
> 
> **Configuration Combination Effects:**
> 
> | Folder Tag | Metadata Tag | Folder Name | Metadata ALBUM | Use Case |
> |:---:|:---:|---|---|---|
> | ✅ | ✅ | `Head Hunters Alac/` | `Head Hunters Alac` | **Recommended**: Perfect sync, music software recognizes correctly |
> | ✅ | ❌ | `Head Hunters Alac/` | `Head Hunters` | Clear file classification, clean metadata |
> | ❌ | ✅ | `Head Hunters/` | `Head Hunters Alac` | Clean folder names, quality info in metadata |
> | ❌ | ❌ | `Head Hunters/` | `Head Hunters` | Not recommended: Cannot distinguish quality versions |
> 
> **Usage Recommendations:**
> - 🎵 **Plex/Emby/Jellyfin Users**: Enable both (`true`)
> - 💿 **Collecting Multiple Quality Versions**: Enable both (`true`)
> - 🗂️ **File Classification Only**: Enable folder tag only
> - ✨ **Pursuing Simplicity**: Enable metadata tag only

```yaml
# Album folder: "Album Name Dolby Atmos"
album-folder-format: "{AlbumName} {Tag}"

# Song file: "01. Song Name"
song-file-format: "{SongNumer}. {SongName}"

# Artist folder: "Artist Name"
artist-folder-format: "{ArtistName}"

# Playlist folder: "Playlist Name"
playlist-folder-format: "{PlaylistName}"
```

**Available Variables:**
- Album: `{AlbumId}`, `{AlbumName}`, `{ArtistName}`, `{ReleaseDate}`, `{ReleaseYear}`, `{Tag}`, `{Quality}`, `{Codec}`, `{UPC}`, `{Copyright}`, `{RecordLabel}`
- Song: `{SongId}`, `{SongNumer}`, `{SongName}`, `{DiscNumber}`, `{TrackNumber}`, `{Tag}`, `{Quality}`, `{Codec}`
- Playlist: `{PlaylistId}`, `{PlaylistName}`, `{ArtistName}`, `{Tag}`, `{Quality}`, `{Codec}`
- Artist: `{ArtistId}`, `{ArtistName}`, `{UrlArtistName}`

### Multi-Account Configuration

```yaml
accounts:
  - name: "CN"
    storefront: "cn"
    media-user-token: "your-cn-token"
    decrypt-m3u8-port: "127.0.0.1:10020"
    get-m3u8-port: "127.0.0.1:10021"
    
  - name: "US"
    storefront: "us"
    media-user-token: "your-us-token"
    decrypt-m3u8-port: "127.0.0.1:20020"
    get-m3u8-port: "127.0.0.1:20021"
```

The program automatically selects the appropriate account based on the URL's storefront (e.g., `/cn/`, `/us/`).

### Translation & Pronunciation Lyrics (Beta)

1. Open [Apple Music Beta](https://beta.music.apple.com) and log in
2. Press `F12` → `Network` tab
3. Search and play a K-Pop song (or any song with translation)
4. Click the lyrics button
5. Find the `syllable-lyrics` request in Network tab
6. Copy the `l=` parameter value from the URL
7. Paste into `config.yaml`:

```yaml
language: "en-US%2Cko-KR%5Bttml%3Aruby%5D"
```

---

## 🔧 Command Line Options

| Option | Description |
|--------|-------------|
| `--atmos` | Download in Dolby Atmos format |
| `--aac` | Download in AAC 256 format |
| `--song` | Download a single song |
| `--select` | Interactive track selection |
| `--search [type] "term"` | Search (song/album/artist) |
| `--debug` | Show available quality info |
| `--no-ui` | Disable dynamic UI, pure log output |
| `--config path` | Specify custom config file |
| `--output path` | Override save folder |

---

## 📂 Output Structure

### Albums (with Emby-compatible naming)

```
/media/Music/AppleMusic/Alac/
└── Taylor Swift/
    └── 1989 (Taylor's Version) Hi-Res Lossless/
        ├── cover.jpg
        ├── 01. Welcome To New York.m4a
        ├── 02. Blank Space.m4a
        └── ...
```

### Music Videos (Emby/Jellyfin compatible)

```
/media/Music/AppleMusic/MusicVideos/
└── Morgan James/
    └── Thunderstruck (2024)/
        └── Thunderstruck (2024).mp4
```

---

## 🐛 Troubleshooting

### Common Issues

**1. "MP4Box not found"**
- Install [MP4Box](https://gpac.io/downloads/gpac-nightly-builds/)
- Ensure it's in your system PATH
- Test: `MP4Box -version`

**2. "wrapper connection failed"**
- Start the [wrapper](https://github.com/zhaarey/wrapper) decryption service
- Check if ports match your config.yaml

**3. "No media-user-token"**
- AAC-LC, MV, and Lyrics require a valid subscription token
- ALAC/Dolby Atmos work with basic tokens

**4. UI output is messy**
- Use `--no-ui` flag for pure log output
- Better for CI/CD pipelines or when redirecting output

**5. Slow downloads on NFS**
- Enable cache mechanism in config.yaml
- See [Cache Quick Start Guide](./QUICKSTART_CACHE.md)

### FFmpeg Auto-Fix

If downloaded files have encoding issues:

```yaml
ffmpeg-fix: true  # Enable auto-detection after download
```

The program will:
1. Detect corrupted/incomplete files
2. Prompt for confirmation
3. Re-encode using FFmpeg with ALAC codec

---

## 📊 Performance Tips

### For Network Storage (NFS/SMB)
- ✅ Enable cache mechanism
- ✅ Use local SSD for cache folder
- ✅ Increase chunk download threads

### For Batch Downloads
```yaml
txtDownloadThreads: 5  # Parallel album downloads
chunk_downloadthreads: 30  # Parallel chunk downloads
```

### For Large Libraries
- ✅ Enable `ffmpeg-fix` for quality assurance
- ✅ Use `--no-ui` for cleaner logs
- ✅ Save output to file: `./app --no-ui url > download.log 2>&1`

---

## 📚 Documentation

### User Guides
- [README-CN.md](./README-CN.md) - 中文文档
- [QUICKSTART_CACHE.md](./QUICKSTART_CACHE.md) - Cache mechanism quick start
- [CACHE_UPDATE.md](./CACHE_UPDATE.md) - Cache update guide
- [GOO_ALIAS.md](./GOO_ALIAS.md) - Command alias configuration guide
- [EMOJI_DEMO.md](./EMOJI_DEMO.md) - Emoji output demonstration

### Technical Documentation
- [CHANGELOG.md](./CHANGELOG.md) - Complete version history and changes
- [CACHE_MECHANISM.md](./CACHE_MECHANISM.md) - Complete cache technical docs
- [MV_QUALITY_DISPLAY.md](./MV_QUALITY_DISPLAY.md) - MV quality detection feature
- [MV_PROGRESS_FIX.md](./MV_PROGRESS_FIX.md) - MV progress tracking improvements
- [MV_LOG_FIX.md](./MV_LOG_FIX.md) - MV download logging enhancements

---

## 🙏 Credits & Acknowledgments

### 🎖️ Original Authors & Core Contributors
- **Sorrow** - Original script author and architecture
- **chocomint** - Created `agent-arm64.js` for ARM support
- **zhaarey** - [wrapper](https://github.com/zhaarey/wrapper) decryption service
- **Sendy McSenderson** - Stream decryption code

### 🔧 Upstream Dependencies & Tools
- **[mp4ff](https://github.com/Eyevinn/mp4ff)** by Eyevinn - MP4 file manipulation
- **[mp4ff (fork)](https://github.com/itouakirai/mp4ff)** by itouakirai - Enhanced MP4 support
- **[progressbar/v3](https://github.com/schollz/progressbar)** by schollz - Progress display
- **[requests](https://github.com/sky8282/requests)** by sky8282 - HTTP client wrapper
- **[m3u8](https://github.com/grafov/m3u8)** by grafov - M3U8 playlist parser
- **[pflag](https://github.com/spf13/pflag)** by spf13 - Command-line flags
- **[tablewriter](https://github.com/olekukonko/tablewriter)** by olekukonko - Table formatting
- **[color](https://github.com/fatih/color)** by fatih - Colorful terminal output

### 🛠️ External Tools
- **[FFmpeg](https://ffmpeg.org/)** - Audio/video processing
- **[MP4Box](https://gpac.io/)** - GPAC multimedia framework
- **[mp4decrypt](https://www.bento4.com/)** - Bento4 decryption tools

### 💝 Special Thanks
- **[@sky8282](https://github.com/sky8282)** - For the excellent requests library and ongoing support
- All contributors and testers who helped improve this project
- Apple Music API researchers and reverse engineering community
- Open source community for various libraries and tools

---

## ⚠️ Disclaimer

This tool is for educational and personal use only. Please respect copyright laws and Apple Music's Terms of Service. Do not distribute downloaded content.

---

## 📝 License

This project is for personal use only. All rights to the downloaded content belong to their respective owners.

---

## 🔗 Resources

- [Apple Music for Artists](https://artists.apple.com/)
- [Emby Naming Convention](https://emby.media/support/articles/Movie-Naming.html)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [Chinese Tutorial](https://telegra.ph/Apple-Music-Alac高解析度无损音乐下载教程-04-02-2)

---

**Version:** v2.6.0  
**Last Updated:** 2025-10-11  
**Go Version Required:** 1.23.1+
