# Don Jorge

M3U playlist proxy service with header injection support.

## Overview

Don Jorge is a Go service that generates M3U playlists and proxies streaming requests. It's designed to work around CORS restrictions and inject custom HTTP headers when accessing stream sources that require them.

## Features

- M3U playlist generation with extended metadata (tvg-name, tvg-id, tvg-logo, group-title)
- Proxy handler with custom header injection
- Automatic relative URL resolution
- Configuration via YAML file or NixOS module

## Usage

### Command Line

```bash
./don-jorge -channels channels.yaml -addr :8080
```

Flags:
- `-channels`: Path to YAML configuration file (required)
- `-addr`: Address to listen on (default `:8080`)

### Configuration (YAML)

```yaml
channels:
  - name: "Channel Name"
    url: "https://stream-url.com/playlist.m3u8"
    headers:
      Referer: "https://example.com"
      User-Agent: "MyApp/1.0"
    logo: "https://example.com/logo.png"
    group: "Sports"
  - name: "Local Channel"
    url: "http://192.168.1.100:8080/live.m3u"
    # no headers - passed through directly
```

### Channel Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | string | Yes | Display name of the channel |
| `url` | string | Yes | Upstream M3U playlist URL |
| `headers` | map | No | HTTP headers to inject when proxying |
| `logo` | string | No | URL to channel logo image |
| `group` | string | No | Group title for categorization |

### Generated Output

```
#EXTM3U
#EXTINF:-1 tvg-name="ESPN" tvg-id="espn" tvg-logo="https://example.com/logo.png" group-title="Sports",ESPN
http://server:8080/proxy/espn
#EXTINF:-1 tvg-name="Local TV" tvg-id="local-tv",Local TV
http://192.168.1.100:8080/live.m3u
```

## NixOS Module

Enable the service:

```nix
services.don-jorge = {
  enable = true;
  channels = [
    {
      name = "Teletica";
      url = "https://cdn01.teletica.com/stream/playlist.m3u8";
      headers = {
        Origin = "https://bradmax.com";
        Referer = "https://bradmax.com";
      };
      logo = "https://example.com/teletica.png";
      group = "Costa Rica";
    }
  ];
};
```

## API Endpoints

- `GET /playlist.m3u` - Returns generated M3U playlist
- `GET /proxy/{slug}` - Proxies requests to upstream with headers injected

## Building

```bash
# With Go
go build -o don-jorge .

# With Nix
nix build
```

## Use Cases

1. **Header injection**: Many streaming services require `Referer` or `User-Agent` headers as anti-hotlink measures. Playlist files can't send headers, so Don Jorge acts as middleware to add them.

2. **Single playlist access**: Serve all channels through one endpoint.

3. **URL hiding**: Clients only see proxy URLs, not upstream sources.