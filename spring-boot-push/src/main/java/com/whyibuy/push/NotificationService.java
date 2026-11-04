package com.whyibuy.push;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.messaging.*;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class NotificationService {
    private final Firestore firestore;
    private final FirebaseMessaging messaging;

    public NotificationService(Firestore firestore, FirebaseMessaging messaging) {
        this.firestore = firestore;
        this.messaging = messaging;
    }

    public int send(NotificationRequest request) throws Exception {
        Query query = firestore.collection("users");
        if (request.targetUserId() != null && !request.targetUserId().isBlank()) {
            query = query.whereEqualTo(FieldPath.documentId(), request.targetUserId());
        }

        List<String> tokens = new ArrayList<>();
        for (DocumentSnapshot user : query.get().get().getDocuments()) {
            Object value = user.get("fcmTokens");
            if (value instanceof List<?> list) {
                for (Object token : list) {
                    if (token instanceof String tokenValue && !tokenValue.isBlank() && !tokens.contains(tokenValue)) {
                        tokens.add(tokenValue);
                    }
                }
            }
        }

        int sent = 0;
        for (int start = 0; start < tokens.size(); start += 500) {
            List<String> batch = tokens.subList(start, Math.min(start + 500, tokens.size()));
            MulticastMessage message = MulticastMessage.builder()
                    .addAllTokens(batch)
                    .setNotification(Notification.builder()
                            .setTitle(request.title())
                            .setBody(request.body())
                            .build())
                    .putAllData(Map.of(
                            "type", "admin_broadcast",
                            "targetScreen", request.targetScreen() == null ? "" : request.targetScreen()))
                    .build();
            BatchResponse response = messaging.sendEachForMulticast(message);
            sent += response.getSuccessCount();
        }
        return sent;
    }
}
