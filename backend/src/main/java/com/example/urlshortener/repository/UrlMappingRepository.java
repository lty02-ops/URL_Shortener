package com.example.urlshortener.repository;

import com.example.urlshortener.model.UrlMapping;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface UrlMappingRepository extends JpaRepository<UrlMapping, String> {
    Optional<UrlMapping> findByShortCode(String shortCode);
    boolean existsByShortCode(String shortCode);
    List<UrlMapping> findAllByOwnerIdOrderByCreatedAtDesc(String ownerId);
    Optional<UrlMapping> findByIdAndOwnerId(String id, String ownerId);
    Optional<UrlMapping> findByShortCodeAndOwnerId(String shortCode, String ownerId);
}
