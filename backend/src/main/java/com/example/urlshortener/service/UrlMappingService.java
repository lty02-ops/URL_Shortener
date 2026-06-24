package com.example.urlshortener.service;
import com.example.urlshortener.controller.UrlMappingController.ShortenRequest;
import com.example.urlshortener.controller.UrlMappingController.ShortenResponse;
import com.example.urlshortener.controller.UrlMappingController.UrlStats;
import com.example.urlshortener.controller.UrlMappingController.UrlSummary;
import com.example.urlshortener.model.UrlMapping;
import com.example.urlshortener.repository.UrlMappingRepository;

import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;

import java.net.URL;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class UrlMappingService {

    private static final String BASE_URL = "http://localhost:5000";
    private final UrlMappingRepository repository;

    public UrlMappingService(UrlMappingRepository repository) {
        this.repository = repository;
    }

    public ShortenResponse shorten(ShortenRequest request) {
        if (request == null || request.getUrl() == null || request.getUrl().isBlank()) {
            throw new IllegalArgumentException("URL is required");
        }

        try {
            new URL(request.getUrl());
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid URL format");
        }

        String id = UUID.randomUUID().toString();
        String shortCode = createShortCode(request.getCustom_code());

        UrlMapping urlMapping = new UrlMapping(id, request.getUrl(), shortCode);
        urlMapping.setCreatedAt(OffsetDateTime.now());
        repository.save(urlMapping);

        return new ShortenResponse(id, request.getUrl(), shortCode, BASE_URL + "/s/" + shortCode);
    }

    public Optional<String> getRedirectLocation(String shortCode) {
        return repository.findByShortCode(shortCode)
                .map(mapping -> {
                    mapping.setClicks(mapping.getClicks() + 1);
                    repository.save(mapping);
                    return mapping.getOriginalUrl();
                });
    }

    public List<UrlSummary> listUrls() {
        return repository.findAll().stream()
                .sorted((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()))
                .map(this::toSummary)
                .collect(Collectors.toList());
    }

    public void deleteUrl(@NonNull String id) {
        repository.deleteById(id);
    }

    public Optional<UrlStats> getStats(String shortCode) {
        return repository.findByShortCode(shortCode).map(this::toStats);
    }

    private String createShortCode(String customCode) {
        if (customCode != null && !customCode.isBlank()) {
            String shortCode = customCode.trim().toLowerCase();
            if (!shortCode.matches("[a-z0-9_-]{3,20}")) {
                throw new IllegalArgumentException("Custom code must be 3-20 characters: letters, numbers, _ or -");
            }
            if (repository.existsByShortCode(shortCode)) {
                throw new IllegalArgumentException("Custom code is already in use");
            }
            return shortCode;
        }

        return createUniqueShortCode();
    }

    private String createUniqueShortCode() {
        String shortCode = generateShortCode();
        while (repository.existsByShortCode(shortCode)) {
            shortCode = generateShortCode();
        }
        return shortCode;
    }

    private String generateShortCode() {
        return UUID.randomUUID().toString().replaceAll("[^a-zA-Z0-9]", "").substring(0, 6).toLowerCase();
    }

    private UrlSummary toSummary(UrlMapping mapping) {
        return new UrlSummary(
                mapping.getId(),
                mapping.getOriginalUrl(),
                mapping.getShortCode(),
                mapping.getCreatedAt().toString(),
                mapping.getClicks(),
                BASE_URL + "/s/" + mapping.getShortCode()
        );
    }

    private UrlStats toStats(UrlMapping mapping) {
        return new UrlStats(
                mapping.getOriginalUrl(),
                mapping.getShortCode(),
                mapping.getCreatedAt().toString(),
                mapping.getClicks()
        );
    }
}
