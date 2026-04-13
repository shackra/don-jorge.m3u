package main

import (
	"bufio"
	"io"
	"net/http"
	"net/url"
	"strings"
)

func proxyHandler(w http.ResponseWriter, r *http.Request, cfg *Config) {
	slug := r.PathValue("slug")

	channel := cfg.FindBySlug(slug)
	if channel == nil {
		http.NotFound(w, r)
		return
	}

	req, err := http.NewRequest(http.MethodGet, channel.URL, nil)
	if err != nil {
		http.Error(w, "Failed to create request", http.StatusInternalServerError)
		return
	}

	for key, value := range channel.Headers {
		req.Header.Set(key, value)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, "Failed to fetch URL", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	baseURL, _ := url.Parse(channel.URL)

	for key, values := range resp.Header {
		if strings.EqualFold(key, "Content-Length") {
			continue
		}
		for _, value := range values {
			w.Header().Add(key, value)
		}
	}
	w.WriteHeader(resp.StatusCode)

	scanner := bufio.NewScanner(resp.Body)
	for scanner.Scan() {
		line := scanner.Text()
		if isM3UURL(line) {
			line = resolveURL(baseURL, line)
		}
		io.WriteString(w, line+"\n")
	}
}

func isM3UURL(line string) bool {
	pathPart := strings.SplitN(line, "?", 2)[0]
	return strings.HasSuffix(pathPart, ".m3u8") || strings.HasSuffix(pathPart, ".m3u")
}

func resolveURL(base *url.URL, relative string) string {
	if strings.HasPrefix(relative, "http://") || strings.HasPrefix(relative, "https://") {
		return relative
	}

	relPath := strings.SplitN(relative, "?", 2)[0]

	var resolved string
	if strings.HasPrefix(relPath, "/") {
		resolved = base.Scheme + "://" + base.Host + relPath
	} else {
		resolved = base.Scheme + "://" + base.Host + "/" + relPath
	}

	if strings.Contains(relative, "?") {
		resolved += "?" + strings.SplitN(relative, "?", 2)[1]
	}

	return resolved
}
