# JWT REVOCATION STRATEGY

The project uses a **two-tier hybrid approach** — one mechanism per token type.

## ACCESS TOKENS (15 MIN) — REDIS BLACKLIST

Access tokens are **stateless by default** — no DB check on every request. Revocation only happens in high-urgency cases (password change, account ban/deletion) via a Redis key:

```
jwt:blacklist:{jti}  →  "1"  (TTL = remaining lifetime of the token)
```

On every authenticated request, [JwtAuthenticationFilter.java:50](vscode-webview://1e7jd267dul0t7vv49n2e9043md3vbefm20ltt2lt576m6enubhk/src/main/java/dev/parallaxsports/auth/security/JwtAuthenticationFilter.java#L50) checks `refreshTokenService.isAccessTokenBlacklisted(jti)` before setting the `SecurityContext`. If the key exists, the request is rejected with a warning log and authentication silently fails.

The blacklist entry is written by `RefreshTokenService.blacklistAccessToken()` ([RefreshTokenService.java:91](vscode-webview://1e7jd267dul0t7vv49n2e9043md3vbefm20ltt2lt576m6enubhk/src/main/java/dev/parallaxsports/auth/service/RefreshTokenService.java#L91)) and automatically expires when the token would have expired anyway, so no cleanup is needed.

## REFRESH TOKENS (7 DAYS) — POSTGRESQL `refresh_tokens` TABLE

Every issued refresh token is stored in the DB with:

- `token_id` = the JWT's `jti` claim (primary key)
- `token_hash` = SHA-256 of the raw token string (not the token itself)
- `revoked_at` = null until revoked

Validation ([RefreshTokenService.java:60-65](vscode-webview://1e7jd267dul0t7vv49n2e9043md3vbefm20ltt2lt576m6enubhk/src/main/java/dev/parallaxsports/auth/service/RefreshTokenService.java#L60)) requires all three to pass: not revoked, not expired, and hash matches the presented token.

Revocation paths:

|Trigger|Method|
|---|---|
|Logout|`revokeByJti(jti)` — sets `revoked_at` on the single token|
|Token rotation (`/refresh`)|Old token marked revoked, new token stored atomically (`@Transactional`)|
|Reuse attack detected|`revokeAllByUser(userId)` — bulk UPDATE sets `revoked_at` on all active tokens|

## REUSE ATTACK DETECTION

In [AuthService.java:107-113](vscode-webview://1e7jd267dul0t7vv49n2e9043md3vbefm20ltt2lt576m6enubhk/src/main/java/dev/parallaxsports/auth/service/AuthService.java#L107), if a refresh token has a **valid JWT signature but no matching row in the DB**, the service treats it as a reuse attack (someone presenting an already-rotated token) and calls `revokeAllByUser()`, nuking all sessions for that user.

## CLEANUP

[RefreshTokenCleanupScheduler.java](vscode-webview://1e7jd267dul0t7vv49n2e9043md3vbefm20ltt2lt576m6enubhk/src/main/java/dev/parallaxsports/auth/service/RefreshTokenCleanupScheduler.java) runs daily at 03:00 UTC and deletes expired tokens and revoked tokens older than a cutoff via `deleteExpiredAndOldRevoked()`.