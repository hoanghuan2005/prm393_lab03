package com.whyibuy.push;

import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Optional extra next to the web admin's announcements: sends an FCM push.
 * Same rule as firestore.rules: only an account whose users/{uid}.role is "admin".
 */
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {
    private final FirebaseAuth firebaseAuth;
    private final Firestore firestore;
    private final NotificationService notificationService;

    public NotificationController(
            FirebaseAuth firebaseAuth,
            Firestore firestore,
            NotificationService notificationService) {
        this.firebaseAuth = firebaseAuth;
        this.firestore = firestore;
        this.notificationService = notificationService;
    }

    @PostMapping("/send")
    public ResponseEntity<Map<String, Object>> send(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody NotificationRequest request) throws Exception {
        FirebaseToken caller = verifyAdmin(authorization);
        int sent = notificationService.send(request);
        return ResponseEntity.ok(Map.of("sentTokens", sent, "admin", caller.getUid()));
    }

    private FirebaseToken verifyAdmin(String authorization) throws Exception {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new UnauthorizedException();
        }
        FirebaseToken token;
        try {
            token = firebaseAuth.verifyIdToken(authorization.substring(7));
        } catch (FirebaseAuthException e) {
            throw new UnauthorizedException();
        }
        DocumentSnapshot user = firestore.collection("users").document(token.getUid()).get().get();
        if (!"admin".equals(user.getString("role"))) {
            throw new ForbiddenException();
        }
        return token;
    }

    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    private static class UnauthorizedException extends RuntimeException {
    }

    @ResponseStatus(HttpStatus.FORBIDDEN)
    private static class ForbiddenException extends RuntimeException {
    }
}
