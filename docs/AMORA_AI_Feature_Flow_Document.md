# AMORA AI Feature Flow Document

Version: 1.0  
Date: 2026-07-09  
Project: AMORA AI Flutter Mobile Application  
Document Type: Screen-wise Functional Specification / Feature Flow Document  
Audience: Client stakeholders, product managers, designers, Flutter developers, QA engineers, administrators, event hosts, support teams

---

## 1. Executive Summary

AMORA AI is a premium AI-powered matchmaking and relationship platform. It is positioned beyond a swipe app: the product combines profile depth, AI compatibility, relationship intentions, curated discovery, event-led offline introductions, premium membership, safety workflows, chat assistance, and operational dashboards for administrators and hosts.

This Feature Flow Document documents every registered production route in the Flutter application, including route aliases and roadmap placeholder screens. It explains screen purpose, user access, available features, UI components, user actions, AI support, premium capability, navigation dependencies, validation rules, and future scope.

### Product Differentiators

| Differentiator | Description | Business Value |
|---|---|---|
| AI-powered compatibility | Explains why two people may align across values, lifestyle, communication, love language, future plans, and chemistry. | Moves AMORA away from shallow swipe mechanics and toward trust-based matchmaking. |
| Profile Studio | Helps users improve bio, photos, prompts, and completion score. | Improves profile quality and match outcomes. |
| AI dating coach | Provides reply suggestions, icebreakers, date plans, and confidence support. | Creates recurring engagement and premium upgrade value. |
| Trust and safety center | Verification, privacy controls, reporting, blocking, SOS check-in, and trusted contacts. | Builds confidence and reduces platform risk. |
| Events ecosystem | Curated singles events, bookings, waitlists, group chat, feedback, host management. | Extends AMORA from digital matching into offline relationship experiences. |
| Premium monetization | Plus, Gold, Platinum, boosts, liked-you paywalls, wallet coins, referrals. | Supports subscription and micro-transaction revenue. |
| Admin and host dashboards | Moderation, verification, events, payouts, analytics, and reports. | Enables operational scale and platform governance. |

---

## 2. Route Inventory

The application registers 69 production routes in `lib/main.dart`. Some routes are aliases that reuse the same implementation.

| Route | Screen | Module | Implementation Notes |
|---|---|---|---|
| `/splash` | Splash Screen | Launch | Initial route. |
| `/landing` | Landing Screen | Launch | Brand/product introduction. |
| `/onboarding` | Onboarding Screen | Onboarding | Multi-slide product education. |
| `/auth` | Auth Entry Screen | Authentication | Phone, email, social, guest entry. |
| `/login` | Login Screen | Authentication | Email/password sign-in. |
| `/signup` | Signup Screen | Authentication | Account creation. |
| `/phone-login` | Phone OTP Screen | Authentication | Phone verification and OTP flow. |
| `/compatibility` | Compatibility Onboarding Screen | Onboarding | AI matching preference setup. |
| `/profile-setup` | Profile Setup Screen | Profile | Profile creation wizard. |
| `/kyc` | KYC Verification Screen | Trust and Safety | Identity verification. |
| `/home` | Home Screen | Core App | Guest/logged-in dashboard. |
| `/browse` | Browse Grid Screen | Discovery | Primary discovery experience. |
| `/discover` | Discover Screen | Discovery | Route aliases to Browse Grid implementation. |
| `/filters` | Advanced Filters Screen | Discovery | Filter and deal preference controls. |
| `/profile` | Profile Screen | Profile | Owner profile and Profile Studio. |
| `/profile-detail` | Profile Detail Screen | Profile/Matching | Public profile inspection and action surface. |
| `/matches` | Matches Screen | Matching | Match list and relationship context. |
| `/match` | Match Screen | Matching | New match celebration and next actions. |
| `/why-we-matched` | Why We Matched Screen | Matching/AI | AI compatibility report. |
| `/super-like` | Super Like Screen | Monetization/Discovery | Premium interest action. |
| `/send-gift` | Send Gift Screen | Commerce | Gift sending. |
| `/gift-shop-catalog` | Gift Catalog Screen | Commerce | Gift catalog and cart. |
| `/chats` | Chat List Screen | Chat | Conversation list. |
| `/chat-detail` | Chat Detail Screen | Chat/AI | Messaging and AI suggestions. |
| `/shared-media-gallery` | Shared Media Gallery Screen | Chat | Media gallery. |
| `/notifications` | Notifications Hub Screen | Notifications | Notification inbox and categories. |
| `/events` | Events Screen | Events | Events browse implementation. |
| `/event-detail` | Event Detail Screen | Events | Event content and booking CTA. |
| `/ticket-booking` | Ticket Booking Screen | Events/Payment | Event checkout. |
| `/my-events` | My Events Screen | Events | User tickets and event pass. |
| `/event-group-chat` | Event Group Chat Screen | Events/Chat | Event discussion. |
| `/event-waitlist` | Event Waitlist Screen | Events | Sold-out event waitlist. |
| `/post-event-feedback` | Post Event Feedback Screen | Events | Event feedback collection. |
| `/date-spots` | Date Spots Screen | Date Planning | AI venue/date recommendations. |
| `/ai-coach` | AI Dating Coach Screen | AI Coach | Assistant, insights, date ideas. |
| `/ai-icebreakers` | AI Icebreakers Screen | AI Coach/Chat | Conversation starter generation. |
| `/subscription` | Subscription Screen | Premium | Plus/Gold/Platinum plans. |
| `/payment` | Payment Screen | Payment | Checkout placeholder. |
| `/wallet` | Amora Wallet Screen | Wallet | Coin balance, packages, redemption. |
| `/profile-boost` | Profile Boost Screen | Monetization | Visibility boost purchase. |
| `/liked-you-paywall` | Liked You Paywall Screen | Premium | Paywall for likes visibility. |
| `/liked-you` | Liked You Paywall Screen | Premium | Alias route for same screen. |
| `/refer-earn` | Refer and Earn Screen | Referral | Invite and reward flow. |
| `/referral-leaderboard` | Referral Leaderboard Screen | Referral | Ranking and referral stats. |
| `/bio-builder` | Bio Builder Screen | Profile/AI | AI-assisted bio drafting. |
| `/photo-manager` | Photo Manager Screen | Profile/AI | Photo management and AI guidance. |
| `/dealbreakers` | Dealbreakers Screen | Preferences | Hard preference controls. |
| `/dating-recap` | Dating Recap Screen | Analytics/AI | Weekly personal insights. |
| `/settings` | Settings Screen | Settings | Grouped settings hub. |
| `/profile-settings` | Profile Settings Screen | Settings/Profile | Account and profile preferences. |
| `/safety-privacy` | Safety Privacy Screen | Trust and Safety | Privacy, safety, consent, block list. |
| `/report-flow` | Report Flow Screen | Trust and Safety | User report workflow. |
| `/sos-checkin` | SOS Check-in Screen | Trust and Safety | Date safety check-in. |
| `/trusted-contacts` | Trusted Contacts Screen | Roadmap/Safety | Placeholder roadmap screen. |
| `/language-selection` | Language Selection Screen | Settings | Language preference. |
| `/notification-preferences` | Notification Preferences Screen | Settings | Notification toggles. |
| `/dark-mode-settings` | Dark Mode Settings Screen | Settings | Appearance setting. |
| `/offline-mode` | Offline Mode Screen | Settings | Cached/offline access controls. |
| `/accessibility-settings` | Accessibility Settings Screen | Settings/Accessibility | Font, contrast, motion controls. |
| `/data-export` | Data Export Screen | Privacy | Data export request. |
| `/faq-support` | FAQ Support Screen | Support | Help center and tickets. |
| `/success-stories` | Success Stories Screen | Social Proof | Testimonials and stories. |
| `/stories` | Stories Screen | Roadmap/Social | Roadmap placeholder. |
| `/liveness-check` | Liveness Check Screen | Roadmap/Safety | Roadmap placeholder. |
| `/twenty-questions` | Twenty Questions Screen | Roadmap/Matching | Roadmap placeholder. |
| `/poll-prompts` | Poll Prompts Screen | Roadmap/Profile | Roadmap placeholder. |
| `/video-speed-dating` | Video Speed Dating Screen | Roadmap/Events | Roadmap placeholder. |
| `/admin-panel` | Admin Panel Screen | Admin | Platform operations. |
| `/host-dashboard` | Host Dashboard Screen | Host | Event host operations. |

---

## 3. Screen-wise Functional Specification

### 3.1 Splash Screen

| Section | Specification |
|---|---|
| Screen Purpose | Launch AMORA AI, establish premium brand impression, show version, then enter the app flow. |
| User Type | Guest, Logged In User. |
| Features Available | Brand splash (P1; establishes identity; AI: No; Premium: No); timed transition (P1; app entry; AI: No; Premium: No); version display (P2; QA/support traceability; AI: No; Premium: No). |
| UI Components | Brand text, splash copy, version label, animated transition, full-screen background. |
| User Actions | Wait for auto-navigation. |
| AI Features | None on-screen. |
| Premium Features | None. |
| Navigation Flow | Splash -> Home/Landing depending app flow. |
| Validation Rules | Must complete within acceptable launch delay; no user input. |
| Future Scope | Remote config-driven launch routing; app maintenance banner; force update handling. |

### 3.2 Landing Screen

| Section | Specification |
|---|---|
| Screen Purpose | Present AMORA AI as a premium AI-powered matchmaking platform and drive users into onboarding/auth. |
| User Type | Guest. |
| Features Available | Brand storytelling (P1; acquisition; AI: Yes as product promise; Premium: No); entry CTA (P1; conversion; AI: No; Premium: No); visual product signal (P1; trust and polish; AI: No; Premium: No). |
| UI Components | Hero image/media, CTA buttons, premium text hierarchy, feature highlights. |
| User Actions | Start onboarding, enter auth flow, explore as guest if available. |
| AI Features | AI matching, AI coach, AI compatibility messaging. |
| Premium Features | Premium positioning and future upgrade messaging. |
| Navigation Flow | Landing -> Onboarding -> Auth -> Home. |
| Validation Rules | CTA must be visible on small screens; no form validation. |
| Future Scope | A/B tested value props; localized landing copy; invite-code entry. |

### 3.3 Onboarding Screen

| Section | Specification |
|---|---|
| Screen Purpose | Educate new users on AI matching, verification, events, coach, and safe dating before sign-up. |
| User Type | Guest. |
| Features Available | Multi-page onboarding (P1; product comprehension; AI: Yes; Premium: No); skip onboarding (P1; friction reduction; AI: No; Premium: No); progress dots (P2; wayfinding; AI: No; Premium: No). |
| UI Components | PageView, image panels, insight cards, progress dots, Skip, Next/Get Started CTA. |
| User Actions | Swipe slides, tap Next, tap Skip, start auth. |
| AI Features | AI matching, AI coach, AI compatibility education. |
| Premium Features | Premium brand positioning; no locked action. |
| Navigation Flow | Onboarding -> Auth Entry. |
| Validation Rules | All slides should render at mobile sizes; image fallback required. |
| Future Scope | Personalized onboarding by intent; analytics event tracking per slide. |

### 3.4 Auth Entry Screen

| Section | Specification |
|---|---|
| Screen Purpose | Let users choose a sign-in/sign-up method while preserving a premium, trusted entry experience. |
| User Type | Guest. |
| Features Available | Phone entry (P1; conversion; AI: No; Premium: No); email entry (P1; conversion; AI: No; Premium: No); Google/Apple placeholder (P2; convenience; AI: No; Premium: No); guest explore (P2; trial; AI: No; Premium: No). |
| UI Components | Auth hero image, primary buttons, social buttons, divider, footer links, back header. |
| User Actions | Continue with phone, email, Google, Apple, guest explore, create account, open footer links. |
| AI Features | None directly; AI product value is communicated. |
| Premium Features | None directly. |
| Navigation Flow | Auth -> Phone OTP / Login / Signup / Home. |
| Validation Rules | Guest mode may limit protected actions via access control. |
| Future Scope | OAuth integration; consent capture; region-based login options. |

### 3.5 Login Screen

| Section | Specification |
|---|---|
| Screen Purpose | Authenticate existing users using email and password. |
| User Type | Guest returning user. |
| Features Available | Email/password login (P1; account access; AI: No; Premium: No); remember me (P2; convenience; AI: No; Premium: No); forgot password dialog (P1; account recovery; AI: No; Premium: No); phone alternative (P2; flexibility; AI: No; Premium: No). |
| UI Components | Form, email/password fields, password visibility toggle, checkbox, primary button, dialog, social buttons, policy copy. |
| User Actions | Enter email, enter password, toggle password visibility, remember device, submit, request reset, navigate to phone or signup. |
| AI Features | None. |
| Premium Features | None. |
| Navigation Flow | Login -> Home after successful local login; Login -> Signup; Login -> Phone OTP. |
| Validation Rules | Email required and valid format; password required and minimum 6 characters; submit disabled until minimum fields are present. |
| Future Scope | Backend authentication; lockout policy; biometric login. |

### 3.6 Signup Screen

| Section | Specification |
|---|---|
| Screen Purpose | Create a new AMORA AI account and begin profile onboarding. |
| User Type | Guest. |
| Features Available | Account creation form (P1; acquisition; AI: No; Premium: No); form validation (P1; data quality; AI: No; Premium: No); route to login/phone (P2; flexibility; AI: No; Premium: No). |
| UI Components | Text fields, buttons, auth header, policy copy, progress/visual panels. |
| User Actions | Enter user details, submit signup, navigate to login or OTP. |
| AI Features | None directly. |
| Premium Features | None. |
| Navigation Flow | Signup -> Compatibility Onboarding / Profile Setup / Home depending app flow. |
| Validation Rules | Required fields; email/phone formatting where applicable. |
| Future Scope | Referral code field; real backend account creation; fraud/risk scoring. |

### 3.7 Phone OTP Screen

| Section | Specification |
|---|---|
| Screen Purpose | Verify phone ownership through OTP-style flow. |
| User Type | Guest, returning user. |
| Features Available | Phone input (P1; login/signup; AI: No; Premium: No); OTP verification placeholder (P1; trust; AI: No; Premium: No); resend timer style flow (P2; UX; AI: No; Premium: No). |
| UI Components | Phone field, OTP field, CTA button, helper text, back navigation. |
| User Actions | Enter phone, request OTP, enter OTP, submit, return to auth. |
| AI Features | None. |
| Premium Features | None. |
| Navigation Flow | Phone OTP -> Home/Profile Setup. |
| Validation Rules | Phone required; OTP required; future 6-digit validation. |
| Future Scope | SMS gateway integration; WhatsApp OTP; device trust. |

### 3.8 Compatibility Onboarding Screen

| Section | Specification |
|---|---|
| Screen Purpose | Collect match preferences and relationship signals for AI compatibility. |
| User Type | Guest onboarding, Logged In User completing setup. |
| Features Available | Compatibility questions (P1; match quality; AI: Yes; Premium: No); preference selection (P1; discovery relevance; AI: Yes; Premium: No); progress UI (P2; completion; AI: No; Premium: No). |
| UI Components | Question cards, chips, progress header, CTA buttons. |
| User Actions | Select answers, continue, skip/back where available. |
| AI Features | AI compatibility input, AI matching preferences. |
| Premium Features | Advanced future matching reports may be premium. |
| Navigation Flow | Auth/Onboarding -> Compatibility -> Profile Setup. |
| Validation Rules | Required core relationship answers before continuation. |
| Future Scope | Adaptive questions; personality model scoring; compatibility vector generation. |

### 3.9 Profile Setup Screen

| Section | Specification |
|---|---|
| Screen Purpose | Create the user's match profile including photos, bio, relationship intention, lifestyle, prompts, and personal details. |
| User Type | Logged In User. |
| Features Available | Photo setup (P1; profile quality; AI: Future/partial; Premium: No); personal details (P1; required profile data; AI: No; Premium: No); relationship intentions (P1; match quality; AI: Yes; Premium: No); lifestyle chips (P1; matching input; AI: Yes; Premium: No); prompt answers (P1; conversation quality; AI: Yes; Premium: No); completion progress (P1; activation; AI: No; Premium: No). |
| UI Components | Progress header, photo manager, text fields, dropdowns, intent chips, lifestyle chips, prompt inputs, Save Draft and Continue buttons. |
| User Actions | Add/reorder/select photos, enter profile fields, select intent/interests, answer prompts, save draft, continue. |
| AI Features | Matching signals from intent, lifestyle, prompts; future AI profile analysis. |
| Premium Features | None during setup; premium may unlock advanced profile optimization later. |
| Navigation Flow | Compatibility/Auth -> Profile Setup -> Home. |
| Validation Rules | At least one photo; required name, DOB, gender, height, profession, education, city; bio minimum 40 characters and max 220; prompt answers required. |
| Future Scope | Voice/video prompt capture; AI bio rewrite; photo quality scoring; moderation scan. |

### 3.10 KYC Verification Screen

| Section | Specification |
|---|---|
| Screen Purpose | Build trust by guiding users through identity verification. |
| User Type | Logged In User, Verified User candidate. |
| Features Available | ID verification status (P1; trust; AI: Future face match; Premium: No); selfie/liveness placeholder (P1; safety; AI: Yes future; Premium: No); verification CTA (P1; community quality; AI: Future; Premium: No). |
| UI Components | Verification cards, status badges, CTA buttons, progress/check indicators. |
| User Actions | Start verification, review status, continue after verification. |
| AI Features | Future face verification and liveness detection. |
| Premium Features | Verified badges increase trust but are not premium. |
| Navigation Flow | Profile Setup/Profile Settings -> KYC -> Profile/Home. |
| Validation Rules | Future mandatory ID/selfie files; age restriction 18+. |
| Future Scope | KYC provider integration; fraud detection; document OCR. |

### 3.11 Home Screen

| Section | Specification |
|---|---|
| Screen Purpose | Provide the main dashboard for discovery, profile prompts, matches, events, AI, and quick actions. |
| User Type | Guest, Logged In User. |
| Features Available | Greeting/dashboard (P1; orientation; AI: No; Premium: No); curated cards (P1; engagement; AI: Yes where recommendations appear; Premium: Mixed); quick entry to discovery, chats, events, profile (P1; navigation; AI: No; Premium: No); guest access handling (P1; conversion; AI: No; Premium: No). |
| UI Components | Cards, banners, profile previews, bottom navigation, CTAs, image panels. |
| User Actions | Explore profiles, open matches, navigate tabs, open profile, access events/settings/AI areas. |
| AI Features | AI match suggestions, coach entry, profile insight prompts. |
| Premium Features | Premium cards, boost/upgrade prompts, locked likes where surfaced. |
| Navigation Flow | Home -> Browse/Matches/Chats/Events/Profile/Settings. |
| Validation Rules | Guest protected actions must trigger login-required sheet. |
| Future Scope | Personalized home feed; real recommendation API; dynamic task checklist. |

### 3.12 Browse Grid Screen

| Section | Specification |
|---|---|
| Screen Purpose | Let users discover compatible profiles through grid/card browsing, categories, filters, and profile actions. |
| User Type | Guest, Logged In User, Premium User for advanced actions. |
| Features Available | Profile browsing (P1; core matching; AI: Yes; Premium: No); AI Picks/category filters (P1; relevance; AI: Yes; Premium: No); like/super-like/pass actions (P1; matching; AI: No; Premium: Super Like can be premium); grid/card mode (P2; UX preference; AI: No; Premium: No); search/filter (P1; discovery control; AI: No; Premium: advanced filters can be premium). |
| UI Components | Profile cards, category chips, search bar, filter button, action buttons, bottom nav, compatibility badges, empty states. |
| User Actions | Browse, search, filter, open profile, like, pass, super like, switch layout, open premium actions. |
| AI Features | AI Picks, compatibility percentages, suggested profiles. |
| Premium Features | Super Likes, advanced filters, boosts, unlimited likes. |
| Navigation Flow | Home/Discover -> Browse -> Profile Detail / Filters / Super Like. |
| Validation Rules | Guest actions require login; daily like limits future; premium gates future. |
| Future Scope | Ranking API; pagination; location radius; passport mode. |

### 3.13 Discover Screen

| Section | Specification |
|---|---|
| Screen Purpose | Route-level discovery entry point; currently maps to Browse Grid implementation. |
| User Type | Guest, Logged In User. |
| Features Available | Same as Browse Grid (P1; discovery; AI: Yes; Premium: Mixed). |
| UI Components | Same as Browse Grid. |
| User Actions | Same as Browse Grid. |
| AI Features | AI Picks and compatibility scoring. |
| Premium Features | Same as Browse Grid. |
| Navigation Flow | Bottom Nav Discover -> Browse Grid implementation. |
| Validation Rules | Same as Browse Grid. |
| Future Scope | Dedicated Discover layout separate from Browse route. |

### 3.14 Advanced Filters Screen

| Section | Specification |
|---|---|
| Screen Purpose | Allow users to refine discovery by preferences, filters, and compatibility criteria. |
| User Type | Logged In User; Premium User for advanced filters. |
| Features Available | Filter controls (P1; relevance; AI: No; Premium: Mixed); reset/apply filters (P1; usability; AI: No; Premium: No); advanced criteria (P2; monetization; AI: Yes future; Premium: Yes). |
| UI Components | Sliders, chips, sections, reset button, apply/search CTA. |
| User Actions | Change age/distance/preferences, reset, apply filters, go back. |
| AI Features | Future AI-assisted filter recommendations. |
| Premium Features | Advanced filters, passport, incognito-style filtering. |
| Navigation Flow | Browse -> Filters -> Browse results. |
| Validation Rules | Valid ranges; at least one broad criterion recommended. |
| Future Scope | Saved filter presets; premium filter unlocks; explainable filter impact. |

### 3.15 Profile Screen

| Section | Specification |
|---|---|
| Screen Purpose | Show the owner's profile, status, completion, Profile Studio, stats, prompts, and quick actions. |
| User Type | Logged In User, Guest in limited mode. |
| Features Available | Profile hero (P1; identity; AI: No; Premium: No); profile completion (P1; activation; AI: No; Premium: No); Profile Studio (P1; profile quality; AI: Yes; Premium: Mixed future); stats grid (P2; engagement; AI: No; Premium: No); quick actions (P1; navigation; AI: Mixed; Premium: Mixed). |
| UI Components | Hero image, avatar, badges, progress bar, cards, chips, quick action tiles, bottom nav. |
| User Actions | Edit profile, manage photos, open bio builder, open AI coach, open wallet, subscription, settings, safety, recap, referrals. |
| AI Features | AI Bio Writer, AI Profile Review, Smart Photo Selection, Best Photo Recommendation, Completeness Score. |
| Premium Features | Membership card, liked-you, premium plan navigation, VIP event messaging. |
| Navigation Flow | Profile -> Profile Detail/Edit, Photo Manager, Bio Builder, Settings, Safety, Subscription, Wallet, AI Coach. |
| Validation Rules | Profile completion reflects required setup fields. |
| Future Scope | Live profile audit API; user-visible profile preview modes. |

### 3.16 Profile Detail Screen

| Section | Specification |
|---|---|
| Screen Purpose | Let users inspect another profile deeply and take relationship actions. |
| User Type | Guest limited, Logged In User, Premium User for enhanced actions. |
| Features Available | Photo gallery (P1; attraction/trust; AI: No; Premium: No); profile bio/prompts (P1; expression; AI: Yes via prompt quality; Premium: No); voice prompt (P1; authenticity; AI: Future transcription; Premium: No); video prompt preview (P1; authenticity; AI: Future analysis; Premium: Mixed); AI compatibility report (P1; differentiation; AI: Yes; Premium: Full report future premium); like/super/gift/date/chat actions (P1; matching; AI: Mixed; Premium: Super/gift). |
| UI Components | Gallery, thumbnails, hero overlay, compatibility circular score, voice waveform, video card, prompt cards, match note composer, chips, bottom action bar, safety sheet. |
| User Actions | Swipe/select photos, like photo/prompt/voice, send like, attach note, super like, gift, save, report, block, view why matched, start chat. |
| AI Features | Compatibility report, AI date plan card, AI explanations, prompt-based matching. |
| Premium Features | Super Like, gifts, full AI reports, read receipts/chat features, premium date planning future. |
| Navigation Flow | Browse/Matches -> Profile Detail -> Chat / Super Like / Gift / Report / Why We Matched. |
| Validation Rules | Guest actions require login; match note max 180 characters; gallery requires fallback image. |
| Future Scope | Real voice/video upload, AI media moderation, profile reputation score. |

### 3.17 Matches Screen

| Section | Specification |
|---|---|
| Screen Purpose | Show current matches and provide pathways to profile details, chat, and compatibility context. |
| User Type | Logged In User. |
| Features Available | Match list (P1; core retention; AI: Yes; Premium: No); compatibility snippets (P1; differentiation; AI: Yes; Premium: Mixed); chat/profile shortcuts (P1; engagement; AI: No; Premium: No). |
| UI Components | Match cards, avatars/images, compatibility labels, list/grid sections, bottom nav. |
| User Actions | Open profile, open chat, inspect match details, navigate tabs. |
| AI Features | Compatibility score/insights. |
| Premium Features | See more match insights, read receipts future. |
| Navigation Flow | Matches -> Profile Detail / Chat / Why We Matched. |
| Validation Rules | Empty state when no matches; guest gating if accessed without login. |
| Future Scope | Match quality sorting; expired matches; nudges. |

### 3.18 Match Screen

| Section | Specification |
|---|---|
| Screen Purpose | Celebrate a new match and guide the user to a next action. |
| User Type | Logged In User. |
| Features Available | Match celebration (P1; emotional reward; AI: No; Premium: No); chat CTA (P1; engagement; AI: No; Premium: No); AI insight CTA (P2; differentiation; AI: Yes; Premium: Mixed). |
| UI Components | Match visual, profile avatars/images, CTA buttons, AI insight card. |
| User Actions | Start chat, view insight, keep browsing. |
| AI Features | AI compatibility insight. |
| Premium Features | AI detailed report future. |
| Navigation Flow | Like -> Match -> Chat / Why We Matched / Browse. |
| Validation Rules | Must have matched profile data or fallback. |
| Future Scope | Match animation variants; first-message assistant prompt. |

### 3.19 Why We Matched Screen

| Section | Specification |
|---|---|
| Screen Purpose | Explain compatibility in a premium AI report format. |
| User Type | Logged In User; Premium User for future detailed reports. |
| Features Available | AI summary (P1; trust in matching; AI: Yes; Premium: Mixed); category scores (P1; transparency; AI: Yes; Premium: Mixed); view profile/icebreaker CTAs (P1; conversion to action; AI: Yes; Premium: No). |
| UI Components | Avatar card, AI summary card, compatibility overview, score grid, circular progress, CTA buttons. |
| User Actions | Review report, view profile, open AI icebreaker. |
| AI Features | Overall compatibility, emotional, communication, lifestyle, values, love language, relationship goals, interests, future plans, chemistry. |
| Premium Features | Deeper explanations and historical compatibility trends future. |
| Navigation Flow | Profile Detail/Match -> Why We Matched -> Profile Detail / AI Icebreakers. |
| Validation Rules | Scores must be 0-100; fallback profile if route args absent. |
| Future Scope | Generated natural language report; explainability API. |

### 3.20 Super Like Screen

| Section | Specification |
|---|---|
| Screen Purpose | Let users send a stronger interest signal and optionally attach a note. |
| User Type | Logged In User, Premium User. |
| Features Available | Super Like action (P1; monetization; AI: No; Premium: Yes); note customization (P2; match quality; AI: Future; Premium: Mixed); preview card (P2; confidence; AI: No; Premium: Yes). |
| UI Components | Profile preview, premium badges, note field/cards, CTA buttons, benefits. |
| User Actions | Send Super Like, edit note, open premium upsell, return. |
| AI Features | Future AI note optimization. |
| Premium Features | Super Likes, visibility priority. |
| Navigation Flow | Browse/Profile Detail -> Super Like -> Profile/Discovery. |
| Validation Rules | Premium allowance/coin balance future; note length cap future. |
| Future Scope | Super Like inventory; conversion analytics; AI-personalized note. |

### 3.21 Send Gift Screen

| Section | Specification |
|---|---|
| Screen Purpose | Allow users to send a romantic or thoughtful gift to another profile. |
| User Type | Logged In User, Premium/Wallet User for paid gifts. |
| Features Available | Gift selection (P1; monetization; AI: No; Premium: Mixed); gift message (P2; personalization; AI: Future; Premium: Mixed); purchase/send CTA (P1; revenue; AI: No; Premium: Mixed). |
| UI Components | Gift cards, price labels, buttons, confirmation snack/dialog. |
| User Actions | Choose gift, send gift, preview gift, return. |
| AI Features | Future AI gift recommendations. |
| Premium Features | Premium gifts, wallet coin usage. |
| Navigation Flow | Profile Detail -> Send Gift -> Payment/Confirmation. |
| Validation Rules | Gift selection required; payment balance future. |
| Future Scope | Real catalog API; recipient delivery status; occasion-based AI recommendations. |

### 3.22 Gift Catalog Screen

| Section | Specification |
|---|---|
| Screen Purpose | Browse gift categories and add gifts to a lightweight local cart before sending. |
| User Type | Logged In User, Premium/Wallet User. |
| Features Available | Gift category browsing (P1; revenue discovery; AI: No; Premium: Mixed); cart count (P1; purchase intent; AI: No; Premium: No); gift preview sheet (P1; confidence; AI: No; Premium: No); send gift CTA (P1; conversion; AI: No; Premium: Mixed). |
| UI Components | Header, cart badge, category chips, gift cards, bottom sheet, primary CTA. |
| User Actions | Filter category, preview gift, add to cart, send gift. |
| AI Features | Future AI gift matching by recipient personality. |
| Premium Features | Luxury gifts, paid gift bundles, wallet redemption future. |
| Navigation Flow | Profile/Commerce -> Gift Catalog -> Send Gift. |
| Validation Rules | Cart can be empty currently; future checkout requires at least one item. |
| Future Scope | Real cart, inventory, payment, personalization note. |

### 3.23 Chat List Screen

| Section | Specification |
|---|---|
| Screen Purpose | Display all conversations and help users re-enter active chats. |
| User Type | Logged In User. |
| Features Available | Conversation list (P1; retention; AI: No; Premium: No); unread/preview signals (P1; usability; AI: Future; Premium: No); search/filter future (P2; scale; AI: Future; Premium: No). |
| UI Components | Chat list cards, avatars, timestamps/previews, bottom nav, empty/loading states. |
| User Actions | Open chat, navigate tabs, inspect profile if supported. |
| AI Features | Future conversation summary and health indicators. |
| Premium Features | Read receipts/priority inbox future. |
| Navigation Flow | Home/Bottom Nav -> Chats -> Chat Detail. |
| Validation Rules | Empty state if no conversations. |
| Future Scope | Archived chats, search, pinned chats. |

### 3.24 Chat Detail Screen

| Section | Specification |
|---|---|
| Screen Purpose | Enable messaging with a match while keeping AI help accessible but not intrusive. |
| User Type | Logged In User, Premium User for enhanced chat features. |
| Features Available | Messaging (P1; core retention; AI: No; Premium: No); AI suggestion card (P1; differentiation; AI: Yes; Premium: Mixed); smart reply chips (P1; engagement; AI: Yes; Premium: Mixed); date invite card (P2; offline conversion; AI: Yes; Premium: Mixed); safety notice (P1; trust; AI: No; Premium: No); shared media (P2; media management; AI: No; Premium: No). |
| UI Components | Chat header, message bubbles, date separator, AI suggestion card, chips, media strip, composer, attachment icons, bottom sheet. |
| User Actions | Send text, insert emoji, attach photo/video/audio placeholder, use AI suggestion, open profile, report, block, mute, shared media, toggle read receipts. |
| AI Features | Smart Reply, Ice Breaker, Emoji suggestion, Translate, Conversation Summary, Conversation Health, date invite draft. |
| Premium Features | Read receipts, video call, AI assistant advanced suggestions future. |
| Navigation Flow | Chat List/Match/Profile -> Chat Detail -> Profile Detail / Shared Media / Report. |
| Validation Rules | Cannot send empty message; text composer max future; attachment permissions future. |
| Future Scope | Real-time messaging, voice notes, translation API, toxicity detection. |

### 3.25 Shared Media Gallery Screen

| Section | Specification |
|---|---|
| Screen Purpose | Show shared photos, videos, and audio from a conversation. |
| User Type | Logged In User. |
| Features Available | Media categories (P2; organization; AI: No; Premium: No); media preview grid/list (P2; usability; AI: Future; Premium: No). |
| UI Components | Header, tabs/filters, media tiles, preview cards. |
| User Actions | Browse media, switch media type, return to chat. |
| AI Features | Future AI media summary/moderation. |
| Premium Features | Cloud storage expansion future. |
| Navigation Flow | Chat Detail -> Shared Media Gallery. |
| Validation Rules | Empty states per media type. |
| Future Scope | Full-screen media viewer; download/share controls. |

### 3.26 Notifications Hub Screen

| Section | Specification |
|---|---|
| Screen Purpose | Centralize notifications for matches, chats, events, payments, AI, offers, and safety. |
| User Type | Logged In User. |
| Features Available | Notification list (P1; engagement; AI: Mixed; Premium: Mixed); category filters (P2; usability; AI: No; Premium: No); mark/open/delete actions (P1; management; AI: No; Premium: No). |
| UI Components | Notification cards, category chips, unread dot, action buttons. |
| User Actions | Filter notifications, open item, delete, mark/read future. |
| AI Features | AI coach and insight notification categories. |
| Premium Features | Premium offer notifications. |
| Navigation Flow | Home/Profile/Settings -> Notifications -> relevant destination. |
| Validation Rules | Empty state if no notifications; unread state consistency. |
| Future Scope | Push notification integration; notification preferences linkage. |

### 3.27 Events Screen

| Section | Specification |
|---|---|
| Screen Purpose | Browse curated offline/online dating events. |
| User Type | Guest limited, Logged In User, Premium User for VIP events. |
| Features Available | Event browsing (P1; engagement/revenue; AI: Yes recommendations; Premium: Mixed); city/category filters (P1; relevance; AI: No; Premium: No); booking CTA (P1; revenue; AI: No; Premium: Mixed); compatibility badge (P2; differentiation; AI: Yes; Premium: Mixed). |
| UI Components | Hero banner, event cards, city chips, category chips, bottom nav/headers, image panels. |
| User Actions | Browse events, filter city/category, open event, book, join waitlist where sold out. |
| AI Features | Event compatibility score and AI event recommendations. |
| Premium Features | VIP events, priority seats, premium event access. |
| Navigation Flow | Home/Settings -> Events -> Event Detail / Ticket Booking / Waitlist. |
| Validation Rules | Guest booking requires login; seat count limits future. |
| Future Scope | Event API, geolocation, ticket inventory, host-created events. |

### 3.28 Event Detail Screen

| Section | Specification |
|---|---|
| Screen Purpose | Provide full event information and booking path. |
| User Type | Guest limited, Logged In User, Premium User. |
| Features Available | Event detail (P1; conversion; AI: No; Premium: Mixed); attendee/host preview (P2; trust; AI: No; Premium: No); agenda/info tiles (P2; clarity; AI: No; Premium: No); book/waitlist CTA (P1; revenue; AI: No; Premium: Mixed). |
| UI Components | Hero image, badges, info tiles, host card, attendee avatars, agenda timeline, CTA buttons. |
| User Actions | Book ticket, favorite/share, join waitlist, view map/route, inspect details. |
| AI Features | Compatibility score/context. |
| Premium Features | VIP seats, premium events, early access future. |
| Navigation Flow | Events -> Event Detail -> Ticket Booking / Waitlist / Group Chat future. |
| Validation Rules | Sold-out events route to waitlist; user login required for booking. |
| Future Scope | Real maps, host Q&A, attendee matching before event. |

### 3.29 Ticket Booking Screen

| Section | Specification |
|---|---|
| Screen Purpose | Complete event ticket booking and payment preparation. |
| User Type | Logged In User. |
| Features Available | Ticket quantity/summary (P1; checkout; AI: No; Premium: Mixed); promo code (P2; marketing; AI: No; Premium: Mixed); booking stepper (P2; clarity; AI: No; Premium: No); payment CTA (P1; revenue; AI: No; Premium: No). |
| UI Components | Stepper, ticket controls, text fields, price summary card, CTA buttons. |
| User Actions | Change ticket quantity, apply offer, review total, continue to payment. |
| AI Features | Future AI seating/date pairing suggestions. |
| Premium Features | Premium discounts, VIP tickets. |
| Navigation Flow | Event Detail -> Ticket Booking -> Payment / My Events. |
| Validation Rules | Quantity min/max; promo format future; payment amount required. |
| Future Scope | Real payment gateway; seat selection; cancellation policy acceptance. |

### 3.30 My Events Screen

| Section | Specification |
|---|---|
| Screen Purpose | Show booked events, passes, QR-like pass, and post-event actions. |
| User Type | Logged In User. |
| Features Available | Event tickets list (P1; utility; AI: No; Premium: No); QR pass (P1; event entry; AI: No; Premium: No); post-event feedback/share/media actions (P2; engagement; AI: Future; Premium: No). |
| UI Components | Ticket cards, QR pass card, action buttons, status chips. |
| User Actions | View pass, download/share, open route, cancel, feedback, gallery. |
| AI Features | Future event recap and suggested matches from event. |
| Premium Features | VIP event passes. |
| Navigation Flow | Events/Profile -> My Events -> Event Detail / Feedback / Group Chat. |
| Validation Rules | Ticket must have event, ticket number, date; cancellation policy future. |
| Future Scope | Real QR code, calendar sync, event chat unlocks. |

### 3.31 Event Group Chat Screen

| Section | Specification |
|---|---|
| Screen Purpose | Provide a temporary group discussion for event attendees. |
| User Type | Event attendee, Host/Admin future moderation. |
| Features Available | Group messages (P2; event engagement; AI: Future moderation; Premium: Event-gated); event context (P2; relevance; AI: No; Premium: Mixed). |
| UI Components | Chat bubbles, event header, composer, participant context. |
| User Actions | Send message, read group updates, return to event. |
| AI Features | Future moderation, summary, icebreakers for event attendees. |
| Premium Features | Available to booked event users; VIP event chats future. |
| Navigation Flow | My Events/Event Detail -> Event Group Chat. |
| Validation Rules | User should be event attendee future; cannot send empty message. |
| Future Scope | Real-time group chat, host announcements, moderation tools. |

### 3.32 Event Waitlist Screen

| Section | Specification |
|---|---|
| Screen Purpose | Capture demand for sold-out events and notify users if seats open. |
| User Type | Logged In User. |
| Features Available | Waitlist join (P1; conversion recovery; AI: No; Premium: Mixed); waitlist status (P2; transparency; AI: No; Premium: No). |
| UI Components | Waitlist card, CTA button, event summary, status messaging. |
| User Actions | Join waitlist, leave/back, open event details. |
| AI Features | Future AI alternate event recommendation. |
| Premium Features | Premium priority waitlist future. |
| Navigation Flow | Event Detail -> Waitlist -> Events. |
| Validation Rules | Requires event context future; duplicate waitlist prevention future. |
| Future Scope | Auto-ticket release, notification integration. |

### 3.33 Post Event Feedback Screen

| Section | Specification |
|---|---|
| Screen Purpose | Collect user feedback after events to improve quality and recommendations. |
| User Type | Event attendee. |
| Features Available | Rating/feedback (P1; quality loop; AI: Future sentiment; Premium: No); submit feedback (P1; analytics; AI: Future; Premium: No). |
| UI Components | Rating controls, text area, chips, submit button, confirmation state. |
| User Actions | Rate event, select feedback tags, write note, submit. |
| AI Features | Future sentiment analysis and match insight extraction. |
| Premium Features | None directly. |
| Navigation Flow | My Events -> Feedback -> My Events/Home. |
| Validation Rules | Rating or feedback required future; text max future. |
| Future Scope | Host score, venue score, match outcome analytics. |

### 3.34 Date Spots Screen

| Section | Specification |
|---|---|
| Screen Purpose | Recommend venues and date ideas based on comfort, safety, mood, city, and budget. |
| User Type | Logged In User, Premium User for advanced recommendations. |
| Features Available | Venue search (P1; date planning; AI: Yes future; Premium: No); city/category filters (P1; relevance; AI: No; Premium: No); map preview (P2; spatial context; AI: No; Premium: No); venue cards (P1; conversion; AI: Yes recommendation score; Premium: Mixed); save/buy package (P1; monetization; AI: No; Premium: Mixed). |
| UI Components | Search field, filter chips, map preview, venue cards, editorial panel, package dialog. |
| User Actions | Search venues, filter by city/category, save venue, reserve/buy package, open details. |
| AI Features | AI Venue Match, venue/date score, comfort/safety recommendation logic. |
| Premium Features | Premium date packages, AI curated venue plans future. |
| Navigation Flow | Profile/Chat/AI Coach -> Date Spots -> Package Dialog/Payment future. |
| Validation Rules | Search can be empty; no venues state shown. |
| Future Scope | Google Maps SDK, booking inventory, partner venues, route planning. |

### 3.35 AI Dating Coach Screen

| Section | Specification |
|---|---|
| Screen Purpose | Provide AI-powered relationship guidance, quick actions, date planning, and profile improvement suggestions. |
| User Type | Logged In User, Premium User. |
| Features Available | Daily tip (P1; coaching; AI: Yes; Premium: Mixed); assistant quick actions (P1; task entry; AI: Yes; Premium: Mixed); conversation score (P1; insight; AI: Yes; Premium: Mixed); first date carousel (P2; date planning; AI: Yes; Premium: Mixed); reflection prompts (P2; learning; AI: Yes; Premium: No); profile suggestions (P1; profile quality; AI: Yes; Premium: Mixed). |
| UI Components | Header, premium badge, assistant card, action chips, score card, progress bars, date carousel, insight cards, CTA buttons. |
| User Actions | Open quick action, generate advice, generate date plan, improve profile, open icebreakers. |
| AI Features | Dating coach, suggest reply, opening messages, confidence coach, relationship advice, conversation score, date ideas. |
| Premium Features | Gold/VIP feature badge, advanced AI advice, premium date plans. |
| Navigation Flow | Profile/Home/Chat -> AI Coach -> AI Icebreakers / Date Spots future. |
| Validation Rules | Backend integration pending; local placeholder actions. |
| Future Scope | LLM-backed coaching, personalization memory, safety-aware advice. |

### 3.36 AI Icebreakers Screen

| Section | Specification |
|---|---|
| Screen Purpose | Generate and customize conversation starters for a selected match. |
| User Type | Logged In User, Premium User for unlimited generation future. |
| Features Available | Tone selection (P1; personalization; AI: Yes; Premium: Mixed); generated openers (P1; chat conversion; AI: Yes; Premium: Mixed); copy/edit/send (P1; actionability; AI: Yes; Premium: No); regenerate (P2; engagement; AI: Yes; Premium: Mixed). |
| UI Components | Match mini card, tone chips, icebreaker cards, copy/edit/send buttons, customize bottom sheet. |
| User Actions | Select tone, copy, edit, send to chat, generate more. |
| AI Features | Suggested opening message, funny ice breaker, thoughtful question, travel/movie/food/coffee conversation. |
| Premium Features | Unlimited generation future, premium tone packs. |
| Navigation Flow | AI Coach/Profile Detail/Why Matched -> AI Icebreakers -> Chat Detail. |
| Validation Rules | Generated text required before send; edit text should not be empty future. |
| Future Scope | Real LLM generation, profile-grounded prompts, tone safety checks. |

### 3.37 Subscription Screen

| Section | Specification |
|---|---|
| Screen Purpose | Convert users to paid memberships and explain premium benefits. |
| User Type | Logged In User, Guest limited. |
| Features Available | Monthly/annual toggle (P1; pricing; AI: No; Premium: No); plan cards (P1; monetization; AI: Mixed; Premium: Yes); premium previews (P1; upsell; AI: Mixed; Premium: Yes); comparison matrix (P1; decision support; AI: No; Premium: Yes); restore/terms (P2; compliance; AI: No; Premium: No). |
| UI Components | Header, segmented button, plan cards, lock chips, comparison table, CTA buttons. |
| User Actions | Switch billing cycle, choose plan, continue with Gold, restore purchase, open terms. |
| AI Features | AI Dating Coach as premium benefit. |
| Premium Features | Amora Plus, Amora Gold, Amora Platinum, see likes, incognito, advanced filters, premium events. |
| Navigation Flow | Profile/Paywall/Settings -> Subscription -> Payment. |
| Validation Rules | Free/zero amount should not open payment; plan amount required. |
| Future Scope | StoreKit/Play Billing, trials, promo codes, entitlement sync. |

### 3.38 Payment Screen

| Section | Specification |
|---|---|
| Screen Purpose | Collect payment method and confirm purchase/top-up/subscription. |
| User Type | Logged In User. |
| Features Available | Payment summary (P1; checkout; AI: No; Premium: Mixed); payment method selection (P1; revenue; AI: No; Premium: No); secure checkout placeholder (P1; trust; AI: No; Premium: No). |
| UI Components | Payment header, amount card, method tiles, radio buttons, CTA. |
| User Actions | Select payment method, confirm payment, return. |
| AI Features | None. |
| Premium Features | Used to purchase premium, coins, tickets, boosts. |
| Navigation Flow | Subscription/Wallet/Ticket Booking -> Payment -> Confirmation/Home. |
| Validation Rules | Payment amount > 0; payment method selected. |
| Future Scope | Razorpay/Stripe integration, receipts, refunds. |

### 3.39 Wallet Screen

| Section | Specification |
|---|---|
| Screen Purpose | Manage AMORA coins for boosts, gifts, events, and AI perks. |
| User Type | Logged In User, Premium User. |
| Features Available | Coin balance (P1; wallet utility; AI: No; Premium: Mixed); quick actions (P1; usability; AI: No; Premium: Mixed); top-up packages (P1; revenue; AI: No; Premium: No); redemption options (P1; monetization; AI: Mixed; Premium: Mixed); transaction history (P1; trust; AI: No; Premium: No). |
| UI Components | Balance card, quick action grid, package tiles, action chips, transaction list, redeem dialog. |
| User Actions | Top up, select package, redeem option, view history, open payment. |
| AI Features | AI Coach redemption option. |
| Premium Features | Coins used for premium actions, gifts, boosts. |
| Navigation Flow | Profile/Settings -> Wallet -> Payment. |
| Validation Rules | Selected package required; redemption balance check future. |
| Future Scope | Real ledger, wallet KYC, coupons, refunds. |

### 3.40 Profile Boost Screen

| Section | Specification |
|---|---|
| Screen Purpose | Sell temporary profile visibility boosts. |
| User Type | Logged In User, Premium User. |
| Features Available | Boost package selection (P1; revenue; AI: No; Premium: Yes); estimated reach/benefits (P1; conversion; AI: Future; Premium: Yes); purchase CTA (P1; revenue; AI: No; Premium: Yes). |
| UI Components | Benefit cards, package options, CTA buttons, premium visuals. |
| User Actions | Select boost, purchase/activate, return. |
| AI Features | Future AI best-time boost recommendation. |
| Premium Features | Boost visibility, profile priority. |
| Navigation Flow | Profile/Browse/Subscription -> Profile Boost -> Payment. |
| Validation Rules | Requires logged-in user; package/coin balance future. |
| Future Scope | Real boost analytics, scheduling, dynamic pricing. |

### 3.41 Liked You Paywall Screen

| Section | Specification |
|---|---|
| Screen Purpose | Monetize access to the list of people who liked the user. |
| User Type | Logged In User; Premium unlock target. |
| Features Available | Blurred likes preview (P1; upsell; AI: No; Premium: Yes); upgrade CTA (P1; conversion; AI: No; Premium: Yes); benefits list (P1; explanation; AI: Mixed; Premium: Yes). |
| UI Components | Locked cards, blur/placeholder content, premium badges, CTA buttons. |
| User Actions | Upgrade, preview feature, return. |
| AI Features | Future AI ranking of incoming likes. |
| Premium Features | See Who Likes You, unlimited likes, advanced filters. |
| Navigation Flow | Profile/Notifications -> Liked You Paywall -> Subscription. |
| Validation Rules | Alias routes `/liked-you` and `/liked-you-paywall` use same screen. |
| Future Scope | Real likes list, priority sorting, compatibility preview. |

### 3.42 Refer and Earn Screen

| Section | Specification |
|---|---|
| Screen Purpose | Encourage user acquisition through referral rewards. |
| User Type | Logged In User. |
| Features Available | Referral code/link (P1; growth; AI: No; Premium: No); reward stats (P1; motivation; AI: No; Premium: No); invite CTA (P1; acquisition; AI: No; Premium: No); leaderboard link future/current. |
| UI Components | Stats cards, referral card, CTA buttons, reward text. |
| User Actions | Share referral, view rewards, open leaderboard. |
| AI Features | None. |
| Premium Features | Rewards may include coins/premium discounts. |
| Navigation Flow | Profile/Settings -> Refer Earn -> Referral Leaderboard. |
| Validation Rules | Referral code required future; share target availability. |
| Future Scope | Deep links, fraud detection, referral attribution. |

### 3.43 Referral Leaderboard Screen

| Section | Specification |
|---|---|
| Screen Purpose | Show referral rankings and incentivize growth. |
| User Type | Logged In User. |
| Features Available | Leaderboard list (P2; gamification; AI: No; Premium: No); rank stats (P2; motivation; AI: No; Premium: No). |
| UI Components | Ranking list, avatars, badges, stat cards. |
| User Actions | View rank, return, share referral future. |
| AI Features | None. |
| Premium Features | Premium reward tiers future. |
| Navigation Flow | Refer Earn -> Referral Leaderboard. |
| Validation Rules | Ranking data fallback needed. |
| Future Scope | Real leaderboard API, region filters, monthly contests. |

### 3.44 Bio Builder Screen

| Section | Specification |
|---|---|
| Screen Purpose | Help users write a warmer and more specific profile bio. |
| User Type | Logged In User. |
| Features Available | Prompt selection (P1; profile quality; AI: Yes; Premium: Mixed); bio editor (P1; profile data; AI: Yes; Premium: No); AI generate placeholder (P1; differentiation; AI: Yes; Premium: Mixed); save bio (P1; profile completion; AI: No; Premium: No). |
| UI Components | Back header, choice chips, text field, character counter, generate/save buttons. |
| User Actions | Select prompt, edit bio, generate draft, save. |
| AI Features | AI bio draft generation. |
| Premium Features | Advanced AI bio rewrites future. |
| Navigation Flow | Profile/Profile Studio -> Bio Builder -> Profile. |
| Validation Rules | Bio max 240 characters; should not be empty future. |
| Future Scope | Tone variants, moderation, profile-fit scoring. |

### 3.45 Photo Manager Screen

| Section | Specification |
|---|---|
| Screen Purpose | Let users manage profile photos and receive AI guidance. |
| User Type | Logged In User. |
| Features Available | Photo grid (P1; profile quality; AI: Future; Premium: No); add/delete/reorder/primary selection (P1; profile control; AI: No; Premium: No); AI photo guidance (P1; quality; AI: Yes; Premium: Mixed); save changes (P1; persistence; AI: No; Premium: No). |
| UI Components | Header, photo grid, add tile, action chips/buttons, guidance card, save button. |
| User Actions | Add photo, set primary, delete, move earlier, save. |
| AI Features | Best photo suggestion, quality indicator, future face detection. |
| Premium Features | Advanced photo ranking future. |
| Navigation Flow | Profile/Profile Studio -> Photo Manager -> Profile. |
| Validation Rules | Max 9 photos; primary index must stay valid; at least one photo recommended. |
| Future Scope | Upload integration, crop tool, AI moderation, best-order optimizer. |

### 3.46 Dealbreakers Screen

| Section | Specification |
|---|---|
| Screen Purpose | Capture hard preferences that should influence matching. |
| User Type | Logged In User. |
| Features Available | Dealbreaker selection (P1; match relevance; AI: Yes; Premium: Mixed); preference toggles/chips (P1; user control; AI: Yes; Premium: Mixed); save preferences (P1; personalization; AI: No; Premium: No). |
| UI Components | Cards, chips, toggles, save CTA. |
| User Actions | Select/remove dealbreakers, save, return. |
| AI Features | AI matching constraints and preference weighting. |
| Premium Features | Advanced dealbreakers future. |
| Navigation Flow | Profile/Settings -> Dealbreakers -> Profile. |
| Validation Rules | Avoid over-filtering future warning; saved selections should persist. |
| Future Scope | Soft vs hard preference weighting; match-pool impact preview. |

### 3.47 Dating Recap Screen

| Section | Specification |
|---|---|
| Screen Purpose | Summarize weekly activity and provide improvement insights. |
| User Type | Logged In User, Premium User for advanced insights future. |
| Features Available | Weekly metrics (P2; engagement; AI: No; Premium: Mixed); AI insight cards (P1; improvement; AI: Yes; Premium: Mixed); share recap (P2; viral/social; AI: No; Premium: No). |
| UI Components | Header, metric cards, insight cards, share CTA. |
| User Actions | View recap, share, open suggestions future. |
| AI Features | Chat quality suggestions, coach suggestions, profile warmth insights. |
| Premium Features | Advanced recap reports future. |
| Navigation Flow | Profile -> Dating Recap. |
| Validation Rules | Date range required future; fallback when no activity. |
| Future Scope | Real analytics pipeline, trend charts, personalized weekly tasks. |

### 3.48 Settings Screen

| Section | Specification |
|---|---|
| Screen Purpose | Provide grouped access to account, safety, experience, premium, and support settings. |
| User Type | Logged In User, Guest limited. |
| Features Available | Grouped settings navigation (P1; usability; AI: Mixed; Premium: Mixed); bottom nav (P1; app navigation; AI: No; Premium: No). |
| UI Components | Section header, grouped cards, settings tiles, icons, bottom navigation. |
| User Actions | Open profile settings, safety, SOS, contacts, language, notifications, appearance, offline, accessibility, data export, events, premium, AI coach, support. |
| AI Features | Entry to AI Coach; AI settings future. |
| Premium Features | Entry to subscription and premium controls. |
| Navigation Flow | Profile/Bottom Nav -> Settings -> Setting Detail Screens. |
| Validation Rules | Routes must resolve; guest limitations future. |
| Future Scope | Search settings, account center, notification badges. |

### 3.49 Profile Settings Screen

| Section | Specification |
|---|---|
| Screen Purpose | Manage personal information, verification, notifications, privacy, account actions, and subscription links. |
| User Type | Logged In User. |
| Features Available | User summary (P1; identity; AI: No; Premium: Mixed); editable personal info (P1; account data; AI: No; Premium: No); verification status (P1; trust; AI: Future; Premium: No); notification toggles (P1; retention; AI: No; Premium: No); privacy toggles (P1; safety; AI: No; Premium: Mixed); account actions (P1; utility; AI: No; Premium: Mixed). |
| UI Components | Profile summary card, TrustPills, settings tiles, toggles, edit bottom sheet, logout sheet. |
| User Actions | Edit info, review verification, toggle notifications/privacy, open language/notifications/dark/offline/accessibility/subscription/wallet/data export, logout. |
| AI Features | AI Coach tips notification toggle. |
| Premium Features | Gold Member badge, subscription management, incognito. |
| Navigation Flow | Settings/Profile -> Profile Settings -> Detail settings screens. |
| Validation Rules | Edited values should not be empty future; logout confirmation. |
| Future Scope | Real account API, password change flow, device sessions. |

### 3.50 Safety Privacy Screen

| Section | Specification |
|---|---|
| Screen Purpose | Centralize verification, safety tools, privacy toggles, blocked users, reports, consent, and dangerous account actions. |
| User Type | Logged In User. |
| Features Available | Trust overview (P1; confidence; AI: No; Premium: No); verification center (P1; safety; AI: Future; Premium: No); safety cards (P1; support; AI: Future; Premium: No); blocked users (P1; control; AI: No; Premium: No); report history (P1; trust; AI: No; Premium: No); privacy toggles (P1; control; AI: No; Premium: Mixed); DPDP consent controls (P1; compliance; AI: No; Premium: No); delete account (P1; compliance; AI: No; Premium: No). |
| UI Components | Trust banner, metrics cards, safety grid, list tiles, toggles, report rows, delete dialog. |
| User Actions | Open verification, safety tips, emergency contact, report/block, unblock user, toggle privacy, manage consent, request deletion. |
| AI Features | Future suspicious message filtering and verification/liveness. |
| Premium Features | Incognito toggle. |
| Navigation Flow | Settings/Profile -> Safety Privacy -> Report Flow / Data Controls future. |
| Validation Rules | Delete requires typing DELETE; blocked list updates locally. |
| Future Scope | Real moderation backend, consent audit log, emergency contact integration. |

### 3.51 Report Flow Screen

| Section | Specification |
|---|---|
| Screen Purpose | Let users report unsafe, fake, abusive, or inappropriate behavior. |
| User Type | Logged In User. |
| Features Available | Report reason selection (P1; safety; AI: Future triage; Premium: No); details input (P1; moderation quality; AI: Future; Premium: No); submit report (P1; platform trust; AI: Future; Premium: No). |
| UI Components | Header, reason cards/chips, text field, submit button, success state. |
| User Actions | Select reason, describe issue, submit report, go back. |
| AI Features | Future report triage, abuse classification. |
| Premium Features | None; safety is universal. |
| Navigation Flow | Profile Detail/Chat/Safety -> Report Flow -> Previous screen. |
| Validation Rules | Reason required; description optional/required future; attachment future. |
| Future Scope | Evidence upload, moderation queue integration, status updates. |

### 3.52 SOS Check-in Screen

| Section | Specification |
|---|---|
| Screen Purpose | Support safer real-world dates through check-ins and emergency workflows. |
| User Type | Logged In User. |
| Features Available | Date check-in setup (P1; safety; AI: No; Premium: No); safety status/actions (P1; risk reduction; AI: Future; Premium: No); emergency contact prompts (P1; trust; AI: No; Premium: No). |
| UI Components | Safety cards, status indicators, CTA buttons, emergency/safe actions. |
| User Actions | Start check-in, mark safe, trigger help placeholder, return. |
| AI Features | Future anomaly/risk reminders. |
| Premium Features | None; safety universal. |
| Navigation Flow | Settings/Safety -> SOS Check-in. |
| Validation Rules | Trusted contact/date details required future. |
| Future Scope | Location sharing, timed check-ins, emergency service integration. |

### 3.53 Trusted Contacts Screen

| Section | Specification |
|---|---|
| Screen Purpose | Roadmap placeholder for managing trusted safety contacts. |
| User Type | Logged In User. |
| Features Available | Roadmap feature preview (P2; expectation setting; AI: No; Premium: No). |
| UI Components | Premium roadmap card, icon, CTA/placeholder. |
| User Actions | View future feature, return. |
| AI Features | None currently. |
| Premium Features | None. |
| Navigation Flow | Settings -> Trusted Contacts. |
| Validation Rules | None currently. |
| Future Scope | Add contacts, invite contacts, SOS integration, permission model. |

### 3.54 Language Selection Screen

| Section | Specification |
|---|---|
| Screen Purpose | Let users select preferred app language. |
| User Type | Logged In User. |
| Features Available | Language list (P1; localization; AI: No; Premium: No); selected state (P1; usability; AI: No; Premium: No); save action (P1; preference persistence; AI: No; Premium: No). |
| UI Components | Header, language cards/list, radio icons, save button. |
| User Actions | Select language, save, go back. |
| AI Features | Future localized AI replies. |
| Premium Features | None. |
| Navigation Flow | Settings/Profile Settings -> Language. |
| Validation Rules | One language selected. |
| Future Scope | Full localization, multilingual AI coach. |

### 3.55 Notification Preferences Screen

| Section | Specification |
|---|---|
| Screen Purpose | Configure notification categories. |
| User Type | Logged In User. |
| Features Available | Notification toggles (P1; user control; AI: Mixed; Premium: Mixed); save preferences (P1; retention/compliance; AI: No; Premium: No). |
| UI Components | Header, toggle tiles, save button. |
| User Actions | Toggle categories, save, return. |
| AI Features | AI coach tips notification category. |
| Premium Features | Premium offer notifications. |
| Navigation Flow | Settings/Profile Settings -> Notification Preferences. |
| Validation Rules | Toggle state valid boolean. |
| Future Scope | Push channels, quiet hours, per-match mute settings. |

### 3.56 Dark Mode Settings Screen

| Section | Specification |
|---|---|
| Screen Purpose | Manage appearance preferences. |
| User Type | Logged In User. |
| Features Available | Theme selection/preview (P2; personalization; AI: No; Premium: No). |
| UI Components | Header, option cards/toggles, preview. |
| User Actions | Select mode, save/return. |
| AI Features | None. |
| Premium Features | None. |
| Navigation Flow | Settings -> Dark Mode. |
| Validation Rules | One appearance mode selected future. |
| Future Scope | Actual dark theme implementation, system sync. |

### 3.57 Offline Mode Screen

| Section | Specification |
|---|---|
| Screen Purpose | Manage cached/offline access preferences. |
| User Type | Logged In User. |
| Features Available | Offline sync controls (P2; reliability; AI: No; Premium: Mixed); cache clearing (P2; storage management; AI: No; Premium: No). |
| UI Components | Header, status cards, toggles, action buttons. |
| User Actions | Toggle offline mode, sync, clear cache. |
| AI Features | Future offline AI prompt cache. |
| Premium Features | Offline premium access future. |
| Navigation Flow | Settings -> Offline Mode. |
| Validation Rules | Storage permission/cache availability future. |
| Future Scope | Offline chat drafts, cached profiles, encrypted cache. |

### 3.58 Accessibility Settings Screen

| Section | Specification |
|---|---|
| Screen Purpose | Improve usability for users with visual, motion, and readability needs. |
| User Type | Logged In User, Guest if exposed. |
| Features Available | Font size controls (P1; accessibility; AI: No; Premium: No); contrast/motion toggles (P1; accessibility; AI: No; Premium: No); preview/save/reset (P1; usability; AI: No; Premium: No). |
| UI Components | Sliders, toggles, preview card, save/reset buttons. |
| User Actions | Adjust font size, toggle accessibility settings, save, reset. |
| AI Features | None. |
| Premium Features | None; accessibility universal. |
| Navigation Flow | Settings -> Accessibility. |
| Validation Rules | Font size constrained to supported range; no overflow at large text future. |
| Future Scope | Screen reader optimization, color-blind palettes, reduced motion global flag. |

### 3.59 Data Export Screen

| Section | Specification |
|---|---|
| Screen Purpose | Support privacy/data portability rights. |
| User Type | Logged In User. |
| Features Available | Data export request (P1; compliance; AI: No; Premium: No); export categories/status (P2; transparency; AI: No; Premium: No). |
| UI Components | Header, cards, request button, status messaging. |
| User Actions | Request export, view categories, return. |
| AI Features | None. |
| Premium Features | None. |
| Navigation Flow | Settings/Profile Settings -> Data Export. |
| Validation Rules | Auth required; export cooldown future. |
| Future Scope | DPDP/GDPR workflow, email download link, audit log. |

### 3.60 FAQ Support Screen

| Section | Specification |
|---|---|
| Screen Purpose | Provide self-service help and support ticket entry. |
| User Type | Guest limited, Logged In User. |
| Features Available | FAQ search/categories (P1; support deflection; AI: Future; Premium: No); accordion answers (P1; usability; AI: No; Premium: No); support channels/ticket card (P1; service; AI: Future; Premium: Mixed). |
| UI Components | Header, search field, category quick cards, accordion tiles, support cards, ticket status. |
| User Actions | Search FAQ, expand answers, contact support, create/view ticket. |
| AI Features | Future AI support assistant. |
| Premium Features | Priority support for premium users future. |
| Navigation Flow | Settings/Profile -> FAQ Support. |
| Validation Rules | Search can be empty; ticket form fields future. |
| Future Scope | Help center CMS, chatbot, ticket backend. |

### 3.61 Success Stories Screen

| Section | Specification |
|---|---|
| Screen Purpose | Build trust and emotional proof through relationship success stories. |
| User Type | Guest, Logged In User. |
| Features Available | Story browsing (P2; brand trust; AI: No; Premium: No); testimonial cards (P2; conversion; AI: No; Premium: No). |
| UI Components | Story cards, images, filters/carousel, CTA. |
| User Actions | Read stories, browse, share/open future. |
| AI Features | None. |
| Premium Features | None. |
| Navigation Flow | Landing/Profile/Roadmap -> Success Stories. |
| Validation Rules | Image fallback required. |
| Future Scope | User-submitted stories, moderation, video testimonials. |

### 3.62 Roadmap Placeholder Screens

Includes: Liveness Check, Stories, Twenty Questions, Poll Prompts, Trusted Contacts, Video Speed Dating.

| Section | Specification |
|---|---|
| Screen Purpose | Present planned capabilities in a consistent premium placeholder format without building duplicate production flows. |
| User Type | Logged In User, sometimes Guest depending route access. |
| Features Available | Feature preview (P2; roadmap communication; AI: Mixed; Premium: Mixed); return/back action (P1; navigation; AI: No; Premium: No). |
| UI Components | Premium card, icon, title, explanatory copy, placeholder CTA. |
| User Actions | View planned feature, return. |
| AI Features | Liveness AI, twenty questions matching, poll prompt intelligence, video dating moderation future. |
| Premium Features | Video speed dating and premium story formats may be premium. |
| Navigation Flow | Settings/Profile/Events -> Roadmap Placeholder -> Previous screen. |
| Validation Rules | No business logic yet. |
| Future Scope | Convert placeholders into full production modules. |

### 3.63 Admin Panel Screen

| Section | Specification |
|---|---|
| Screen Purpose | Provide platform administration for users, verification, reports, revenue, events, moderation, and analytics. |
| User Type | Admin. |
| Features Available | KPI dashboard (P1; operations; AI: No; Premium: No); verification queue (P1; trust operations; AI: Future; Premium: No); reports/moderation (P1; safety; AI: Future; Premium: No); event/revenue views (P1; business ops; AI: No; Premium: No); admin action cards (P1; workflow entry; AI: Mixed; Premium: No). |
| UI Components | Dashboard header, KPI cards, queues, status chips, action cards, charts/list cards. |
| User Actions | Review KPIs, approve/reject verification, inspect reports, open revenue/event tools. |
| AI Features | Future moderation triage, fraud detection, verification scoring. |
| Premium Features | Admin monitors premium revenue but does not consume premium features. |
| Navigation Flow | Profile/Settings quick action -> Admin Panel -> admin sections. |
| Validation Rules | Admin role required future; all actions audited future. |
| Future Scope | Role-based access control, dashboards, exports, moderation queues. |

### 3.64 Host Dashboard Screen

| Section | Specification |
|---|---|
| Screen Purpose | Let event hosts manage event performance, attendees, payouts, and host operations. |
| User Type | Host, Admin. |
| Features Available | Host KPIs (P1; operations; AI: No; Premium: No); event performance cards (P1; revenue; AI: No; Premium: No); attendee check-in (P1; event operations; AI: No; Premium: No); payout/verification status (P1; business ops; AI: No; Premium: No). |
| UI Components | Dashboard header, KPI cards, event cards, attendee tiles, status chips, action buttons. |
| User Actions | View event stats, check in attendees, promote event, open reports, manage payouts. |
| AI Features | Future event demand forecasting and attendee matching insights. |
| Premium Features | Hosts may manage VIP events. |
| Navigation Flow | Profile quick action -> Host Dashboard -> event operations. |
| Validation Rules | Host role required future; capacity and check-in state consistency. |
| Future Scope | Host onboarding, settlement reports, create event flow. |

---

## 4. Complete User Journey

### Guest User Flow

Splash -> Landing -> Onboarding -> Auth Entry -> Guest Explore -> Home -> Browse -> Profile Detail -> Login Required Sheet -> Auth

### Login Flow

Auth Entry -> Login or Phone OTP -> Home -> Profile/Profile Setup Completion -> Discovery

### Profile Completion Flow

Profile Setup -> Photo Setup -> Personal Details -> Relationship Intention -> Lifestyle Interests -> Prompt Questions -> KYC Verification -> Home/Profile

### AI Matching Flow

Compatibility Onboarding -> Browse/Grid -> Profile Detail -> AI Compatibility Report -> Why We Matched -> AI Icebreakers -> Chat

### Chat Flow

Matches/Match/Profile Detail -> Chat List -> Chat Detail -> AI Suggestions -> Date Invite/Date Spots -> Report/Block if needed

### Premium Flow

Liked You/Super Like/Profile Boost/AI Coach/Subscription Prompt -> Subscription -> Plan Selection -> Payment -> Entitlement Future

### Events Flow

Home/Settings/Profile -> Events -> Event Detail -> Ticket Booking or Waitlist -> Payment -> My Events -> Group Chat -> Feedback

### Wallet Flow

Profile/Settings -> Wallet -> Select Coin Package -> Payment -> Redeem for Boost/Gift/Event/AI Coach

### Settings Flow

Settings -> Account / Safety / Experience / Premium groups -> Detail screens -> Save preferences or return

### Admin/Host Flow

Profile Quick Actions -> Admin Panel or Host Dashboard -> Review KPIs -> Manage verification/events/attendees/reports

---

## 5. Feature Mapping Master Table

| Screen/Module | Features | AI Features | Premium Features | APIs | Status |
|---|---|---|---|---|---|
| Launch and Onboarding | Splash, landing, onboarding, auth entry | AI value messaging | Premium positioning | None/local | UI complete, backend pending |
| Authentication | Login, signup, phone OTP | None | None | Auth/SMS/OAuth future | UI placeholder/local |
| Profile Setup | Photos, bio, prompts, intentions, lifestyle | Match signals, future AI profile scoring | Advanced profile tools future | Profile API future | UI complete/local |
| Profile Studio | Bio builder, photo manager, completeness | AI bio, AI review, AI photo guidance | Advanced AI optimization future | AI/Profile APIs future | UI complete/local |
| Discovery | Browse, discover, filters, profile details | AI Picks, compatibility | Super Like, advanced filters, unlimited likes | Discovery/Match APIs future | UI complete/local data |
| Matching | Matches, match celebration, why matched | Compatibility report | Detailed AI reports future | Match/AI APIs future | UI complete/local |
| Chat | Chat list, detail, media gallery | Smart reply, icebreakers, translation, summary, health | Read receipts, advanced assistant | Messaging/AI APIs future | UI complete/local |
| AI Coach | Coach dashboard, icebreakers, date ideas | Dating coach, reply suggestions, date plan | Gold/Platinum AI benefits | LLM APIs future | UI complete/local |
| Events | Browse, detail, booking, tickets, waitlist, group chat, feedback | Event compatibility, future recommendations | VIP events, priority access | Event/Payment APIs future | UI complete/local |
| Date Planning | Date spots, venue recommendations | AI venue match | Premium plans/packages future | Maps/Venue APIs future | UI complete/local |
| Monetization | Subscription, boost, liked-you paywall | AI Coach benefit | Plus, Gold, Platinum, boosts | Billing APIs future | UI complete/local |
| Wallet/Payments | Wallet, packages, redemption, payment | AI Coach redemption | Coins for premium actions | Payment/Ledger APIs future | UI complete/local |
| Referral | Refer earn, leaderboard | None | Rewarded premium discounts future | Referral APIs future | UI complete/local |
| Notifications | Notification hub/preferences | AI coach notifications | Premium offers | Push APIs future | UI complete/local |
| Trust and Safety | KYC, safety, report, SOS, contacts | Future liveness/moderation | Incognito | KYC/Moderation APIs future | UI complete/local |
| Settings and Privacy | Settings, profile settings, language, accessibility, export | AI preference categories future | Subscription management | User/Consent APIs future | UI complete/local |
| Admin | Admin panel, moderation, verification, reports | Future AI triage | Revenue monitoring | Admin APIs future | UI complete/local |
| Host | Host dashboard, attendees, events, payouts | Future demand forecasting | VIP event management | Host/Event APIs future | UI complete/local |
| Roadmap | Liveness, stories, questions, polls, video speed dating | Planned AI features | Mixed future premium | TBD | Placeholder |

---

## 6. Module Breakdown

| Module | Included Screens | Responsibility | Primary Users |
|---|---|---|---|
| Authentication | Auth Entry, Login, Signup, Phone OTP | Account access and identity start | Guest |
| Onboarding | Landing, Onboarding, Compatibility Onboarding | Product education and preference capture | Guest, new user |
| Profile | Profile Setup, Profile, Profile Detail, Bio Builder, Photo Manager | Identity, expression, profile quality | Logged In User |
| Discovery | Home, Browse, Discover, Filters, Date Spots | Finding compatible people and date ideas | Guest, Logged In User |
| Matching | Matches, Match, Why We Matched, Super Like | Relationship actions and compatibility explanation | Logged In User |
| Chat | Chat List, Chat Detail, Shared Media Gallery | Conversation and media | Logged In User |
| AI Engine | AI Coach, AI Icebreakers, Profile Studio, Compatibility Reports | Advice, matching, prompts, profile improvements | Logged In/Premium |
| Events | Events, Detail, Booking, My Events, Waitlist, Group Chat, Feedback | Offline social experience lifecycle | Users, Hosts |
| Premium | Subscription, Liked You, Boost | Subscription and paid unlocks | Logged In/Premium |
| Payments | Payment, Wallet | Checkout and coin ledger | Logged In User |
| Notifications | Notifications, Notification Preferences | Alerts and engagement | Logged In User |
| Settings | Settings, Profile Settings, Language, Dark Mode, Offline, Accessibility | App/user preferences | Logged In User |
| Privacy | Data Export, Safety Privacy, Consent Controls | Compliance and data rights | Logged In User |
| Trust and Safety | KYC, Report, SOS, Trusted Contacts, Liveness future | Verification and protection | Logged In User/Admin |
| Admin | Admin Panel | Platform operations | Admin |
| Host | Host Dashboard | Event host operations | Host |
| Analytics | Dating Recap, Admin KPIs, Host KPIs | User and business insights | User/Admin/Host |
| Social Proof | Success Stories, Stories future | Trust and marketing | Guest/User |
| Roadmap | Twenty Questions, Poll Prompts, Video Speed Dating | Planned expansion | User/Premium |

---

## 7. Client Presentation Summary

| Category | Count / Summary |
|---|---|
| Total Registered Routes | 69 routes in `MaterialApp.routes`. |
| Total Functional Screen Groups | 64 documented screen specs, with aliases and grouped roadmap placeholders noted. |
| Total Major Modules | 17 modules: Authentication, Onboarding, Profile, Discovery, Matching, Chat, AI Engine, Events, Premium, Payments, Wallet, Notifications, Settings, Privacy, Trust and Safety, Admin, Host. |
| Total Feature Areas | 100+ feature areas across profile, matching, chat, events, AI, premium, wallet, safety, and operations. |
| AI Features | AI matching, compatibility reports, AI Profile Studio, AI Bio Writer, AI profile review, smart photo selection, AI dating coach, reply suggestions, icebreakers, conversation summary, conversation health, date planning, event compatibility, future moderation/liveness. |
| Premium Features | Amora Plus, Amora Gold, Amora Platinum, see who likes you, unlimited likes, advanced filters, incognito, Super Likes, boosts, read receipts, AI coach premium, VIP events, premium gifts, premium reports future. |
| Admin Features | Verification queue, report/moderation management, revenue/event KPIs, user/platform operations, action cards. |
| Host Features | Event KPIs, attendee check-in, event performance, promotion/report actions, payout/settlement future. |
| Trust and Safety Features | KYC, photo/face verification placeholders, report user, block user, blocked list, SOS check-in, emergency contact, privacy toggles, consent controls, data export, delete account. |
| Current API Status | UI/local-placeholder implementation. Backend, payment, auth, messaging, KYC, AI, maps, push, and event APIs are future integration points. |
| Estimated Development Complexity | High. The product spans marketplace-style discovery, AI personalization, chat, events, payments, safety/compliance, admin, and host operations. |

### Future Roadmap

| Roadmap Area | Future Enhancement | Complexity |
|---|---|---|
| AI Engine | Real LLM-based coach, compatibility explanation generation, profile optimization, moderation triage. | High |
| Messaging | Real-time chat, media upload, voice notes, translation, read receipts, typing indicators. | High |
| Discovery | Recommendation API, ranking, pagination, passport, saved filters. | High |
| Safety | KYC provider, liveness, emergency contacts, location sharing, moderation workflows. | High |
| Events | Real inventory, maps, host event creation, ticket QR, group chat, calendar sync. | High |
| Payments | Razorpay/Stripe/UPI integration, wallet ledger, subscriptions, refunds, invoices. | High |
| Admin | RBAC, audit logs, moderation dashboard, exportable reports. | Medium-High |
| Premium | Entitlement service, trials, promos, plan experiments. | Medium-High |
| Localization | Hindi/Gujarati support, localized AI replies. | Medium |
| Accessibility | Global text scaling QA, reduced motion, screen reader semantic labels. | Medium |

### Client-Friendly Positioning

AMORA AI is designed as a premium relationship ecosystem. The current Flutter application already contains the core screen architecture for onboarding, profile creation, discovery, matching, AI guidance, chat, events, premium subscriptions, payments, safety, settings, admin operations, and host management. The application differentiates itself by combining meaningful relationship intent with AI compatibility and safe offline experiences, making it more sophisticated than a standard swipe-based dating app.

For production launch, the next major workstream is backend integration: authentication, profile persistence, recommendation APIs, real-time messaging, AI generation, KYC, payments, wallet ledger, push notifications, event inventory, admin roles, and moderation workflows. The screen architecture is broad and client-demo ready; production readiness depends on connecting these UI flows to secure, scalable services and completing QA across devices, accessibility settings, and edge cases.

