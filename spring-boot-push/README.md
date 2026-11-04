# Why I Buy Spring Boot Push Service

## Luồng gửi

`Flutter Web Admin -> POST /api/notifications/send -> Spring Boot -> FCM -> Flutter Mobile`

Spring Boot xác thực Firebase ID token của Admin, đọc `users/{uid}.fcmTokens` từ Firestore và gửi FCM multicast. Service account không bao giờ nằm trong Flutter Web.

## Chạy local

Đặt một trong hai cấu hình:

- `GOOGLE_APPLICATION_CREDENTIALS=C:\path\firebase-service-account.json`
- `FIREBASE_SERVICE_ACCOUNT_JSON` chứa toàn bộ JSON credential

Sau đó:

```powershell
mvn spring-boot:run
```

Mặc định API chạy ở `http://localhost:8080`.
