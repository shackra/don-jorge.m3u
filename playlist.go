package main

import (
	"fmt"
	"net/http"
)

func getBaseURL(r *http.Request) string {
	scheme := "http"
	if r.Header.Get("X-Forwarded-Proto") == "https" || r.TLS != nil {
		scheme = "https"
	}
	host := r.Header.Get("X-Forwarded-Host")
	if host == "" {
		host = r.Host
	}
	return scheme + "://" + host
}

func playlistHandler(w http.ResponseWriter, r *http.Request, cfg *Config) {
	w.Header().Set("Content-Type", "application/vnd.apple.mpegurl")

	baseURL := getBaseURL(r)

	fmt.Fprintln(w, "#EXTM3U")

	for _, ch := range cfg.Channels {
		id := Slugify(ch.Name)

		attrs := fmt.Sprintf("tvg-name=\"%s\" tvg-id=\"%s\"", ch.Name, id)
		if ch.Logo != "" {
			attrs += fmt.Sprintf(" tvg-logo=\"%s\"", ch.Logo)
		}
		if ch.Group != "" {
			attrs += fmt.Sprintf(" group-title=\"%s\"", ch.Group)
		}
		fmt.Fprintf(w, "#EXTINF:-1 %s,%s\n", attrs, ch.Name)

		if len(ch.Headers) > 0 {
			slug := Slugify(ch.Name)
			fmt.Fprintf(w, "%s/proxy/%s\n", baseURL, slug)
		} else {
			fmt.Fprintf(w, "%s\n", ch.URL)
		}
	}
}
