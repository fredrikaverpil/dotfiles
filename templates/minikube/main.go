package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
)

var log = slog.New(slog.NewJSONHandler(os.Stdout, nil))

func helloHandler(w http.ResponseWriter, _ *http.Request) {
	_, err := w.Write([]byte("Hello World!"))
	if err != nil {
		log.Error("Error writing response", "error", err)
	}
}

func middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Info("Request received",
			"method", r.Method,
			"url", r.URL.Path,
			"query", r.URL.Query(),
			"body", r.Body,
			"header", r.Header,
		)

		next.ServeHTTP(w, r)
	})
}

func main() {
	router := mux.NewRouter()
	router.Use(middleware)
	router.HandleFunc("/", helloHandler)

	port := ":9090"

	srv := &http.Server{
		Addr:    port,
		Handler: router,
	}

	// listen for interrupt signal to gracefully shutdown the server
	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	// serve
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Error("Error starting server", "error", err)
		}
	}()
	log.Info("Server started on port " + port)

	// wait for interrupt signal to gracefully shutdown the server with a timeout
	<-done
	log.Info("Server stopped")

	// graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer func() {
		// extra handling here
		cancel()
	}()

	if err := srv.Shutdown(ctx); err != nil {
		log.Error("Server shutdown failed", "error", err)
	}
	log.Info("Server exited gracefully")
}
