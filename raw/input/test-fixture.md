---
type: meeting
date: 2026-04-27
project: ACME Platform
participants:
  - Rajiwath Patel
  - Sarah Chen
  - Unknown Person
---

# ACME Platform Integration Review — 2026-04-27

**Attendees:** Rajiwath Patel (Product), Sarah Chen (Engineering), Unknown Person (External)

## Discussion

Raj opened the meeting by reviewing the current API rate limiting situation.
He confirmed that we need to enforce tenant-level API quotas.

**Sarah** raised a concern about the current authentication token design:
the token does not carry a tenant identifier, which would be required for
per-tenant rate limiting to work.

Unknown Person (introduced as a consultant from PartnerCo) suggested reviewing
the existing architecture decision on token expiry before finalising the rate
limit approach.

## Decisions

- The team agreed that API rate limiting will be enforced at 1000 requests
  per hour per tenant. This supersedes the earlier informal cap of 5000/day.

## Actions

- Sarah Chen to update the auth token specification to include tenant_id claim
  by 2026-05-10.
- Raj to circulate the revised rate limit proposal to the wider engineering team.

## Risks

- If the auth token change is delayed, rate limiting cannot be implemented
  correctly. Risk: high impact, medium likelihood.

## Notes

- The API rate limiting requirement relates to the existing platform scalability
  discussion that was covered in prior architecture sessions.
