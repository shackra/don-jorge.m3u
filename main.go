package main

import (
	"flag"
	"log"
	"net/http"
)

func main() {
	channelsFile := flag.String("channels", "", "Path to channels YAML file")
	addr := flag.String("addr", ":8080", "Address to listen on")
	flag.Parse()

	if *channelsFile == "" {
		log.Fatal("Please provide -channels flag")
	}

	cfg, err := LoadConfig(*channelsFile)
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	http.HandleFunc("GET /playlist.m3u", func(w http.ResponseWriter, r *http.Request) {
		playlistHandler(w, r, cfg)
	})

	http.HandleFunc("GET /proxy/{slug}", func(w http.ResponseWriter, r *http.Request) {
		proxyHandler(w, r, cfg)
	})

	log.Printf("Listening on %s", *addr)
	if err := http.ListenAndServe(*addr, nil); err != nil {
		log.Fatal(err)
	}
}
