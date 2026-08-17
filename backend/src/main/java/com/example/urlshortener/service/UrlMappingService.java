package com.example.urlshortener.service;
import com.example.urlshortener.controller.UrlMappingController.ShortenRequest;
import com.example.urlshortener.controller.UrlMappingController.ShortenResponse;
import com.example.urlshortener.controller.UrlMappingController.UrlStats;
import com.example.urlshortener.controller.UrlMappingController.UrlSummary;
import com.example.urlshortener.model.UrlMapping;
import com.example.urlshortener.repository.UrlMappingRepository;

import org.springframework.lang.NonNull;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class UrlMappingService {

    private final UrlMappingRepository repository;
    private final String baseUrl;

    public UrlMappingService(
            UrlMappingRepository repository,
            @Value("${app.base-url:http://localhost:3000}") String baseUrl) {
        this.repository = repository;
        this.baseUrl = baseUrl.replaceAll("/+$", "");
    }

    public ShortenResponse shorten(String ownerId, ShortenRequest request) {
        if (request == null || request.getUrl() == null || request.getUrl().isBlank()) {
            throw new IllegalArgumentException("URL is required");
        }

        try {
            URI uri = new URI(request.getUrl());
            if (uri.getHost() == null || !("http".equalsIgnoreCase(uri.getScheme())
                    || "https".equalsIgnoreCase(uri.getScheme()))) {
                throw new IllegalArgumentException("Invalid URL format");
            }
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid URL format");
        }

        String id = UUID.randomUUID().toString();
        String shortCode = createShortCode(request.getCustom_code());

        UrlMapping urlMapping = new UrlMapping(id, request.getUrl(), shortCode, ownerId);
        urlMapping.setCreatedAt(OffsetDateTime.now());
        repository.save(urlMapping);

        return new ShortenResponse(id, request.getUrl(), shortCode, baseUrl + "/s/" + shortCode);
    }

    public Optional<String> getRedirectLocation(String shortCode) {
        return repository.findByShortCode(shortCode)
                .map(mapping -> {
                    mapping.setClicks(mapping.getClicks() + 1);
                    repository.save(mapping);
                    return mapping.getOriginalUrl();
                });
    }

    public List<UrlSummary> listUrls(String ownerId) {
        return repository.findAllByOwnerIdOrderByCreatedAtDesc(ownerId).stream()
                .map(this::toSummary)
                .collect(Collectors.toList());
    }

    public boolean deleteUrl(String ownerId, @NonNull String id) {
        return repository.findByIdAndOwnerId(id, ownerId)
                .map(mapping -> {
                    repository.delete(mapping);
                    return true;
                })
                .orElse(false);
    }

    public Optional<UrlStats> getStats(String ownerId, String shortCode) {
        return repository.findByShortCodeAndOwnerId(shortCode, ownerId).map(this::toStats);
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
                baseUrl + "/s/" + mapping.getShortCode()
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
