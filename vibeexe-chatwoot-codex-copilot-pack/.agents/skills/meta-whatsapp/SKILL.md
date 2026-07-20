---
name: meta-whatsapp
description: Integrate Meta WhatsApp Safely
---

# Integrate Meta WhatsApp Safely


## Scope

Use for WhatsApp Cloud API, Embedded Signup, WABA onboarding, templates, media, message statuses, and webhooks.

## Credential boundaries

- Platform Meta App credentials are installation-level secrets.
- Customer WABA, phone-number, and token data must resolve to the correct account/inbox.
- Never mix credentials or business assets across tenants.

## Procedure

1. Trace Chatwoot current WhatsApp channel and webhook implementation.
2. Verify signature checks, token storage, encryption, and account/inbox resolution.
3. Make webhook processing idempotent because Meta retries events.
4. Handle inbound messages, status changes, media, templates, rate limits, token expiry, and disconnects.
5. Keep Embedded Signup configuration server-side and never expose app secrets.
6. Add structured logs without tokens or full sensitive payloads.
7. Test duplicate events, invalid signatures, wrong-tenant identifiers, expired credentials, and partial onboarding failure.

## Rule

Do not invent current Meta API fields or requirements. Verify against official Meta documentation when implementation depends on them.
