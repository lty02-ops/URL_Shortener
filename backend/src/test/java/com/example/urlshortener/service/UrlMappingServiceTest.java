package com.example.urlshortener.service;

import com.example.urlshortener.controller.UrlMappingController.ShortenRequest;
import com.example.urlshortener.controller.UrlMappingController.ShortenResponse;
import com.example.urlshortener.model.UrlMapping;
import com.example.urlshortener.repository.UrlMappingRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UrlMappingServiceTest {

    private UrlMappingRepository repository;
    private UrlMappingService service;

    @BeforeEach
    void setUp() {
        repository = mock(UrlMappingRepository.class);
        service = new UrlMappingService(repository, "https://short.example.com/");
    }

    @Test
    void createsCustomShortUrlUsingConfiguredBaseUrl() {
        when(repository.existsByShortCode("custom-code-12345678")).thenReturn(false);
        when(repository.save(any(UrlMapping.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ShortenRequest request = new ShortenRequest();
        request.setUrl("https://example.com/a/long/path");
        request.setCustom_code("custom-code-12345678");

        ShortenResponse response = service.shorten(request);

        assertEquals("custom-code-12345678", response.getShort_code());
        assertEquals("https://short.example.com/s/custom-code-12345678", response.getShort_url());
        verify(repository).save(any(UrlMapping.class));
    }

    @Test
    void rejectsNonHttpUrl() {
        ShortenRequest request = new ShortenRequest();
        request.setUrl("ftp://example.com/file");

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> service.shorten(request));

        assertEquals("Invalid URL format", exception.getMessage());
    }

    @Test
    void rejectsCustomCodeLongerThanTwentyCharacters() {
        ShortenRequest request = new ShortenRequest();
        request.setUrl("https://example.com");
        request.setCustom_code("123456789012345678901");

        assertThrows(IllegalArgumentException.class, () -> service.shorten(request));
    }
}
