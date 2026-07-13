package com.example.api.dto;

import java.util.UUID;

public record OrderResponse(UUID id, String status, long totalCents) {
}
