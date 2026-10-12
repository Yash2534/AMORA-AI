# TLS Evidence

- Acceptable: sanitized edge config, dated protocol/cipher scan, HTTP redirect/HSTS and WSS captures, certificate hostname/chain/expiry and renewal alert from an approved endpoint.
- Unacceptable: source settings alone, a browser padlock screenshot, an unapproved hostname, or claims without command/output/time.
- Redact: tokens, cookies, internal IPs where sensitive, account IDs and unrelated hostnames; never redact the tested hostname, protocol result or certificate identity needed for review.
- Provider: DevOps; reviewed by Security and Mobile for device behavior.
- Pass: HTTPS/WSS only, TLS 1.2+, obsolete protocols rejected, valid hostname/chain, correct redirect/HSTS/trusted proxy and tested renewal.
