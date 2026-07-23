# Responsiveness Report

The automated regression suite covers 320, 360, 375, 390, 414, 768, and 1024 px widths for the primary journeys: onboarding, authentication, profile setup, home, discover, match, chat, subscription, and settings.

All registered routes also have a build smoke test at 430 x 932. Layout uses `ResponsiveMobileFrame`, scrollable screen bodies, flexible text, and width-aware components to avoid fixed-width failure modes.
