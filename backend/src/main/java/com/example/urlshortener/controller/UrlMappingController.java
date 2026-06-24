package com.example.urlshortener.controller;

import com.example.urlshortener.service.UrlMappingService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.NonNull;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping
@CrossOrigin(origins = "*")
public class UrlMappingController {

    private final UrlMappingService service;

    public UrlMappingController(UrlMappingService service) {
        this.service = service;
    }

    @PostMapping(path = "/api/shorten", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ShortenResponse> shorten(@RequestBody ShortenRequest request) {
        try {
            return ResponseEntity.ok(service.shorten(request));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(new ShortenResponse(ex.getMessage()));
        }
    }

    @GetMapping("/s/{shortCode}")
    public ResponseEntity<Void> redirect(@PathVariable("shortCode") String shortCode) {
        Optional<String> location = service.getRedirectLocation(shortCode);
        if (location.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }

        HttpHeaders headers = new HttpHeaders();
        try {
            headers.setLocation(new URI(location.get()));
            return new ResponseEntity<>(headers, HttpStatus.FOUND);
        } catch (URISyntaxException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping(path = "/api/urls", produces = MediaType.APPLICATION_JSON_VALUE)
    public List<UrlSummary> listUrls() {
        return service.listUrls();
    }

    @DeleteMapping("/api/urls/{id}")
    public ResponseEntity<GenericResponse> deleteUrl(@NonNull @PathVariable("id") String id) {
        service.deleteUrl(id);
        return ResponseEntity.ok(new GenericResponse("URL deleted successfully"));
    }

    @GetMapping(path = "/api/stats/{shortCode}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<UrlStats> getStats(@PathVariable("shortCode") String shortCode) {
        return service.getStats(shortCode)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.status(HttpStatus.NOT_FOUND).build());
    }

    public static class ShortenRequest {
        private String url;
        private String custom_code;

        public String getUrl() {
            return url;
        }

        public void setUrl(String url) {
            this.url = url;
        }

        public String getCustom_code() {
            return custom_code;
        }

        public void setCustom_code(String custom_code) {
            this.custom_code = custom_code;
        }
    }

    public static class ShortenResponse {
        private String id;
        private String original_url;
        private String short_code;
        private String short_url;
        private String error;

        public ShortenResponse() {
        }

        public ShortenResponse(String error) {
            this.error = error;
        }

        public ShortenResponse(String id, String originalUrl, String shortCode, String shortUrl) {
            this.id = id;
            this.original_url = originalUrl;
            this.short_code = shortCode;
            this.short_url = shortUrl;
        }

        public String getId() {
            return id;
        }

        public String getOriginal_url() {
            return original_url;
        }

        public String getShort_code() {
            return short_code;
        }

        public String getShort_url() {
            return short_url;
        }

        public String getError() {
            return error;
        }
    }

    public static class UrlSummary {
        private String id;
        private String original_url;
        private String short_code;
        private String created_at;
        private int clicks;
        private String short_url;

        public UrlSummary(String id, String original_url, String short_code, String created_at, int clicks, String short_url) {
            this.id = id;
            this.original_url = original_url;
            this.short_code = short_code;
            this.created_at = created_at;
            this.clicks = clicks;
            this.short_url = short_url;
        }

        public String getId() {
            return id;
        }

        public String getOriginal_url() {
            return original_url;
        }

        public String getShort_code() {
            return short_code;
        }

        public String getCreated_at() {
            return created_at;
        }

        public int getClicks() {
            return clicks;
        }

        public String getShort_url() {
            return short_url;
        }
    }

    public static class UrlStats {
        private String original_url;
        private String short_code;
        private String created_at;
        private int clicks;

        public UrlStats(String original_url, String short_code, String created_at, int clicks) {
            this.original_url = original_url;
            this.short_code = short_code;
            this.created_at = created_at;
            this.clicks = clicks;
        }

        public String getOriginal_url() {
            return original_url;
        }

        public String getShort_code() {
            return short_code;
        }

        public String getCreated_at() {
            return created_at;
        }

        public int getClicks() {
            return clicks;
        }
    }

    public static class GenericResponse {
        private String message;

        public GenericResponse(String message) {
            this.message = message;
        }

        public String getMessage() {
            return message;
        }
    }
}
