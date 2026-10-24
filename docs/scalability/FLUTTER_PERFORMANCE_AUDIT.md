# AMORAA Flutter performance audit

## Verdict

The Flutter client has good pagination and image-decoding foundations, but it has avoidable memory/reconnect risks and several screens/repos that can accumulate complete lists. No device performance profile was run; findings are static repository evidence.

## What is already good

- `AuthService` reuses an `http.Client` and coalesces token refresh with `_refreshInFlight`.
- Discovery requests default to 10 items and use backend cursors.
- Chat conversations load 20 per page and message history loads 30 with `beforeId` cursor pagination.
- Repository loading flags prevent obvious concurrent load-more duplication in chat.
- No continuous API polling loop was found. Periodic timers are UI countdowns, not data polling.
- `AmoraProfileImage` calculates decode cache dimensions when width/height are known, and shared adaptive image widgets use `ResizeImage`.
- Image picking requests bounded dimensions (2048x2560), quality 90, and limits accepted bytes to 12 MB.
- Socket and media state is cleared on account deletion.

## P0/P1 findings

### Realtime reconnect can create overlapping reconnect mechanisms

`socket_io_client` reconnection is enabled, while `onConnectError` also schedules a forced reconnect after two seconds. The delayed callback is not retained/cancelled, and forced connection creation disposes/replaces the socket. A network outage can cause overlapping library retries and manual reconnects, repeated authentication (`realtimeAccessToken()` first calls `/api/auth/me`), socket churn, and reconnect storms.

Use one reconnection owner, exponential backoff with jitter and a cap, lifecycle/network-awareness, token-refresh coordination, and metrics. Re-subscribe active conversation rooms after reconnect and test duplicate event handlers.

### Unbounded in-memory chat media cache

`ChatRepository` stores `Future<Uint8List>` by media path in `_mediaCache` and only clears it on account deletion. It has no byte/count bound, LRU eviction, expiry, or logout/lifecycle clear shown. Long chat sessions with 10 MB images can retain substantial memory. Use a bounded cache and disk/image cache appropriate to privacy requirements.

### Upload bytes are duplicated

The media picker holds raw `Uint8List`, a base64 `dataUri` (roughly 33% larger), and later multipart byte copies. Profile editing also keeps photo bytes in memory. Lower quality/size targets, avoid constructing `dataUri` when not required, stream file-backed uploads on mobile, and clear byte maps after upload/navigation.

### Protected media caching is inefficient/inconsistent

Profile media responses use `private, no-store`, so normal HTTP caching is defeated even though profile screens may revisit the same photos. Chat media has a five-minute private cache header, but the app downloads it into an unbounded byte cache. Define privacy-safe ETag/versioned object caching and an explicit bounded client cache.

## Screen/request findings

- Chat initialization and `ChatListScreen.initState` are guarded by repository state, which reduces duplicate initial fetches.
- Conversation realtime updates call `_refreshQuietly`; bursts of updates can repeatedly reload page 1 unless that method coalesces/debounces all overlapping events. Add an in-flight/coalescing gate and burst test.
- Like/super-like/match/notification socket events trigger notification repository refreshes. Event bursts can cause duplicate full refreshes; coalesce by short window or apply payload deltas.
- Search in the chat list filters locally and rebuilds on each keystroke. This is acceptable for a page-sized list but becomes more expensive as loaded pages accumulate; use a lightweight debounce only if profiling shows jank.
- Profile relationship initialization issues saved/likes/super-likes requests in parallel, which reduces latency but creates a three-request burst on screen entry. It is bounded and acceptable; monitor duplicate controller construction.
- Match and blocked-user backend lists are unbounded, so Flutter may receive/parse/render large payloads even if widgets are lazy. Backend pagination is mandatory.
- Large JSON decoding happens on the UI isolate through `jsonDecode`. Current page sizes limit normal feeds, but privacy results, unbounded matches/blocks/admin-like payloads, or large profiles can cause frame stalls. Move genuinely large payload parsing to an isolate after server-side bounding.

## Image behavior

The shared image system is a strength, but many calls have unknown width/height and therefore no `cacheWidth/cacheHeight`. Audit high-density grids/cards with DevTools image-size diagnostics. Add server-generated thumbnail sizes so a card never downloads an original 12 MB upload. Precache only the next one or two discovery images and avoid prefetching protected/high-resolution media on cellular data.

The current picker compresses through the platform API, but the 2048x2560/quality-90 result can still be large and it does not guarantee metadata stripping. Introduce approved re-encoding and thumbnail generation server-side; client compression is an optimization, not a trust boundary.

## List and rebuild behavior

- Lazy `ListView.builder`/`GridView.builder` use is common and positive.
- Several static/demo screens use nested `SingleChildScrollView`, `GridView.count`, or eagerly mapped child lists. They are low priority while datasets remain static.
- Very large presentation files and broad repository `notifyListeners()` updates can rebuild an entire screen for small state changes. Profile with Flutter DevTools before refactoring; split listenable state for chat connection, conversation list, and active conversation if rebuild times are material.
- Blur/backdrop filters, large shadows, animations, and high-resolution profile imagery appear in chat/profile UI. Test raster/UI thread frame time on a representative low/mid Android device, not only desktop/web.

## Required repository changes before production

1. Make socket reconnect single-owner, bounded, jittered, lifecycle-aware, and observable.
2. Bound and clear chat/profile media byte caches; eliminate unnecessary base64 copies.
3. Add automatic infinite-scroll thresholds or clearly controlled load-more without concurrent requests; preserve cursors.
4. Ensure every growing backend list is paginated so Flutter cannot receive full history.
5. Add thumbnail variants and request size-appropriate images.
6. Coalesce socket-triggered repository refreshes and notification refresh bursts.
7. Add request tracing headers/correlation propagation and client latency/error metrics without PII.

## Device performance test plan

On at least one low/mid Android device and one current iOS device, measure:

- cold/warm startup and authenticated restore;
- discovery first page, five additional pages, fast swiping, filters, and image prefetch;
- chat list with 20/100/500 test conversations;
- conversation with 1,000 test messages, repeated older-page loads, and 20 media items;
- upload of 1/6 profile photos and 10–12 MB verification/media files;
- background/foreground, airplane-mode recovery, token expiry, and reconnect storm;
- memory before/after navigation cycles and image viewing;
- UI/raster p50/p95 frame time, jank percentage, network bytes, image decode dimensions, CPU, and peak RSS.

Project targets should include no sustained memory growth after repeated navigation, no duplicate API call per lifecycle event, no unbounded reconnect loop, and smooth frame delivery on the chosen device matrix. Exact thresholds must be approved by product/engineering and measured.
