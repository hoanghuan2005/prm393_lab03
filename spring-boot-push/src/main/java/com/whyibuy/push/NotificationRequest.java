package com.whyibuy.push;

import jakarta.validation.constraints.NotBlank;

public record NotificationRequest(
        @NotBlank String title,
        @NotBlank String body,
        String targetUserId,
        String targetAudience,
        String targetScreen
) {
}
