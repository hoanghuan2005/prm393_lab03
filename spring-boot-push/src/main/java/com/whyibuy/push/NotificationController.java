package com.whyibuy.push;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {
    private final FirebaseAuth firebaseAuth;
    private final NotificationService notificationService;
    private final String adminEmail;

    public NotificationController(
            FirebaseAuth firebaseAuth,
            NotificationService notificationService,
            org.springframework.core.env.Environment environment) {
        this.firebaseAuth = firebaseAuth;
        this.notificationService = notificationService;
        this.adminEmail = environment.getProperty("app.admin-email", "admin@gmail.com");
    }

    @PostMapping("/send")
    public ResponseEntity<Map<String, Object>> send(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody NotificationRequest request) throws Exception {
        FirebaseToken caller = verifyAdmin(authorization);
        int sent = notificationService.send(request);
        return ResponseEntity.ok(Map.of("sentTokens", sent, "admin", caller.getEmail()));
    }

    private FirebaseToken verifyAdmin(String authorization) throws Exception {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new UnauthorizedException();
        }
        FirebaseToken token = firebaseAuth.verifyIdToken(authorization.substring(7));
        if (!adminEmail.equalsIgnoreCase(token.getEmail())) {
            throw new UnauthorizedException();
        }
        return token;
    }

    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    private static class UnauthorizedException extends RuntimeException {
    }
}
