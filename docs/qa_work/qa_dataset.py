from __future__ import annotations

import json
import re
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TODAY = date(2026, 7, 27)

FAILURES = {
    "secondary action, badges, and compact navigation stay on-brand",
    "core text combinations meet WCAG AA contrast",
    "primary navigation exposes exactly the four approved destinations",
    "IndexedStack preserves the active Discover profile",
    "Discover is single-card, single-image, and search-free",
    "Discover photo tap zones change only the visible photo",
    "Discover shows a live compact completion line below 100%",
    "completion line updates and hides when profile reaches 100%",
    "right and left gestures use Like and Reject controller actions",
    "vertical and short horizontal drags do not advance the profile",
    "buttons and Chrome keyboard shortcuts use the same actions",
    "empty state appears and can explicitly refresh the local deck",
    "actions stay guarded while the exit animation is running",
    "applying a non-default filter shows the active indicator",
    "image tap opens the existing scrollable profile details route",
    "sticky detail actions return through the Discover controller",
    "profile details expose the complete editorial image sequence",
    "Events locked state survives large text on narrow screen",
    "profile information keeps all questions on one page",
    "login continues through profile information to Discover",
    "signup continues to the four-question profile screen",
    "all registered production routes build",
    "primary journeys stay exception-free at supported widths",
}

SKIPPED_MEMBERSHIP = {
    "monthly and annual test plans update the selected CTA",
    "simulated success remains isolated and joined event appears in My Events",
    "failure preserves inactive membership state",
    "cancelled preserves inactive membership state",
    "pending preserves inactive membership state",
}

MODULE_BY_FILE = {
    "advanced_filters_screen_test.dart": "Filters",
    "auth_experience_test.dart": "Authentication",
    "brand_theme_test.dart": "Design System",
    "chat_icon_layout_test.dart": "Chats",
    "chat_list_screen_test.dart": "Chats",
    "chat_text_only_test.dart": "Chats",
    "design_system_test.dart": "Design System",
    "discover_action_controller_test.dart": "Discover",
    "discover_screen_test.dart": "Discover",
    "events_experience_test.dart": "Events",
    "faq_support_screen_test.dart": "FAQ & Support",
    "four_tab_discover_test.dart": "Discover",
    "icon_system_test.dart": "Design System",
    "matches_screen_test.dart": "AI Matches",
    "membership_test_flow_test.dart": "Subscription & Payment",
    "notifications_screen_test.dart": "Notifications",
    "onboarding_profile_flow_test.dart": "Onboarding",
    "profile_detail_screen_test.dart": "Profile Detail",
    "profile_identity_screen_test.dart": "User Profile",
    "qa_evidence_capture_test.dart": "Visual Evidence",
    "qa_frontend_fixes_test.dart": "Regression",
    "startup_routing_test.dart": "Authentication",
    "widget_test.dart": "Cross-functional",
}

MODULE_CODE = {
    "Authentication": "AUTH",
    "Onboarding": "ONB",
    "Discover": "DIS",
    "Filters": "FLT",
    "Profile Detail": "PDT",
    "User Profile": "PRO",
    "Edit Profile": "EDT",
    "Profile Preview": "PRV",
    "AI Matches": "MAT",
    "Chats": "CHT",
    "Events": "EVT",
    "Event Detail & My Events": "EVD",
    "Notifications": "NOT",
    "Subscription & Payment": "SUB",
    "FAQ & Support": "SUP",
    "Settings & Account": "SET",
    "Safety & Privacy": "SAF",
    "Design System": "UI",
    "Visual Evidence": "VIS",
    "Regression": "REG",
    "Cross-functional": "XFN",
    "Build & Compatibility": "BLD",
    "Security Review": "SEC",
}


def _module_for_file(name: str) -> str:
    return MODULE_BY_FILE.get(name, "Cross-functional")


def _evidence_for(module: str, name: str) -> str:
    low = f"{module} {name}".lower()
    if "auth" in low or "login" in low or "signup" in low or "otp" in low:
        return "EV-UI-001; EV-TEST-001"
    if "discover" in low or "filter" in low or "profile detail" in low:
        return "EV-UI-002; EV-TEST-001"
    if "event detail" in low:
        return "EV-UI-004; EV-TEST-001"
    if "event" in low:
        return "EV-UI-003; EV-UI-007; EV-TEST-001"
    if "profile" in low:
        return "EV-UI-005; EV-TEST-001"
    if "faq" in low or "support" in low:
        return "EV-UI-006; EV-TEST-001"
    return "EV-TEST-001"


def _failure_actual(name: str) -> tuple[str, str, str]:
    if name == "core text combinations meet WCAG AA contrast":
        return (
            "AppColors.onSecondary on AppColors.secondary measured 3.10:1; "
            "the automated threshold was >4.5:1.",
            "P2",
            "BUG-UI-001",
        )
    if name == "secondary action, badges, and compact navigation stay on-brand":
        return (
            "The tested FilledButton resolved to #3D0B3F instead of the "
            "expected secondary #EC5FA8.",
            "P3",
            "BUG-UI-002",
        )
    if name == "Events locked state survives large text on narrow screen":
        return (
            "Legacy locked-state copy is absent by design, and the current "
            "featured card also produced a 35 px bottom RenderFlex overflow "
            "at 320x700 with 1.3x text scaling.",
            "P2",
            "BUG-EVT-001; BUG-TST-001",
        )
    if name in {
        "all registered production routes build",
        "primary journeys stay exception-free at supported widths",
    }:
        return (
            "/event-waitlist raised Flutter's ListTile background/ink "
            "visibility assertion because a decorated Container separates "
            "the tile from its Material ancestor.",
            "P2",
            "BUG-EVT-002",
        )
    if name in {
        "profile information keeps all questions on one page",
        "login continues through profile information to Discover",
        "signup continues to the four-question profile screen",
    }:
        return (
            "The legacy test locator matched multiple elements after the "
            "current onboarding redesign and threw 'Too many elements'.",
            "P3",
            "BUG-TST-002",
        )
    return (
        "The legacy four-tab/old Discover widget contract no longer matches "
        "the current five-tab canonical Discover implementation; newer "
        "Discover tests pass against the current UI.",
        "P3",
        "BUG-TST-001",
    )


def _parse_automated_tests() -> list[dict]:
    cases: list[dict] = []
    sequence = 1
    pattern = re.compile(
        r"(testWidgets|(?<!Widgets)\btest)\s*\(\s*'([^']*)'", re.MULTILINE
    )
    for path in sorted((ROOT / "test").glob("*.dart")):
        source = path.read_text(encoding="utf-8")
        for match in pattern.finditer(source):
            kind, name = match.groups()
            expanded = [name]
            if name == "${scenario.$1.name} preserves inactive membership state":
                expanded = [
                    "failure preserves inactive membership state",
                    "cancelled preserves inactive membership state",
                    "pending preserves inactive membership state",
                ]
            for actual_name in expanded:
                module = _module_for_file(path.name)
                status = "Pass"
                actual = "Automated assertion completed without an exception."
                severity = ""
                remarks = "Executed in the complete Flutter test run."
                if actual_name in SKIPPED_MEMBERSHIP:
                    status = "Not Run"
                    actual = (
                        "Skipped because AMORA_MEMBERSHIP_TEST was not enabled "
                        "for the production-mode QA run."
                    )
                    remarks = "Test-only payment journey remains isolated by design."
                elif actual_name in FAILURES:
                    status = "Fail"
                    actual, severity, defect = _failure_actual(actual_name)
                    remarks = f"Mapped to {defect}."
                cases.append(
                    {
                        "id": f"AUT-{sequence:03d}",
                        "module": module,
                        "scenario": actual_name,
                        "objective": f"Verify the automated contract: {actual_name}.",
                        "preconditions": "Dependencies resolved; Flutter test binding available.",
                        "test_data": "Local fictional fixtures and bundled assets only.",
                        "steps": (
                            f"1. Run flutter test test/{path.name}.\n"
                            f"2. Execute the {kind} case named '{actual_name}'.\n"
                            "3. Compare assertions and captured exceptions."
                        ),
                        "expected": "All declared assertions pass without uncaught exceptions.",
                        "actual": actual,
                        "status": status,
                        "priority": "High"
                        if module
                        in {
                            "Authentication",
                            "Onboarding",
                            "Discover",
                            "Events",
                            "Chats",
                        }
                        else "Medium",
                        "severity": severity,
                        "environment": "Windows 11; Flutter 3.44.6; Dart 3.12.2; widget test",
                        "evidence": _evidence_for(module, actual_name),
                        "remarks": remarks,
                        "source_file": f"test/{path.name}",
                        "type": "Widget" if kind == "testWidgets" else "Unit/Source",
                    }
                )
                sequence += 1
    if len(cases) != 143:
        raise RuntimeError(f"Expected 143 automated cases, parsed {len(cases)}")
    return cases


def _case(
    case_id: str,
    module: str,
    scenario: str,
    status: str,
    *,
    objective: str,
    expected: str,
    actual: str,
    priority: str = "High",
    severity: str = "",
    evidence: str = "EV-SOURCE-001",
    preconditions: str = "Project source and requested QA environment are available.",
    data: str = "Safe fictional/local data only.",
    steps: str = "1. Inspect or execute the stated check.\n2. Record observed result.",
    environment: str = "Windows 11 QA workstation",
    remarks: str = "",
) -> dict:
    return {
        "id": case_id,
        "module": module,
        "scenario": scenario,
        "objective": objective,
        "preconditions": preconditions,
        "test_data": data,
        "steps": steps,
        "expected": expected,
        "actual": actual,
        "status": status,
        "priority": priority,
        "severity": severity,
        "environment": environment,
        "evidence": evidence,
        "remarks": remarks,
        "source_file": "",
        "type": "Build/Review" if status in {"Pass", "Fail"} else "Planned Manual",
    }


def _build_review_cases() -> list[dict]:
    return [
        _case(
            "BLD-001",
            "Build & Compatibility",
            "Clean generated output",
            "Pass",
            objective="Verify a clean validation baseline.",
            expected="flutter clean completes.",
            actual="Completed successfully in 3.8 seconds.",
            evidence="EV-BUILD-001",
            steps="Run flutter clean and record the exit code.",
        ),
        _case(
            "BLD-002",
            "Build & Compatibility",
            "Resolve dependencies",
            "Pass",
            objective="Verify declared packages resolve.",
            expected="flutter pub get completes.",
            actual="Completed; four newer incompatible package versions were informational.",
            evidence="EV-BUILD-001",
            steps="Run flutter pub get and review warnings.",
        ),
        _case(
            "BLD-003",
            "Build & Compatibility",
            "Format source",
            "Pass",
            objective="Verify lib source is formatter-clean.",
            expected="dart format lib reports no required changes.",
            actual="137 files checked; 0 changed.",
            evidence="EV-BUILD-001",
            steps="Run dart format lib and record changed-file count.",
        ),
        _case(
            "BLD-004",
            "Build & Compatibility",
            "Static analysis",
            "Pass",
            objective="Detect analyzer errors and warnings.",
            expected="flutter analyze returns no issues.",
            actual="No issues found in 3.0 seconds.",
            evidence="EV-BUILD-001",
            steps="Run flutter analyze and record diagnostics.",
        ),
        _case(
            "BLD-005",
            "Build & Compatibility",
            "Web release bundle",
            "Pass",
            objective="Verify web compilation.",
            expected="flutter build web succeeds.",
            actual="build/web created in 81.7 seconds; 202 files, 68,034,713 bytes.",
            evidence="EV-BUILD-001",
            steps="Run flutter build web and inspect output directory.",
        ),
        _case(
            "BLD-006",
            "Build & Compatibility",
            "Android debug APK",
            "Pass",
            objective="Verify Android debug packaging.",
            expected="flutter build apk --debug creates a non-empty APK.",
            actual="APK built in 54.5 seconds; 172,299,833 bytes.",
            evidence="EV-BUILD-001",
            steps="Run flutter build apk --debug; inspect path, size and manifest.",
        ),
        _case(
            "REV-001",
            "Security Review",
            "Declared network and backend dependencies",
            "Pass",
            objective="Identify production network/backend SDKs.",
            expected="Dependency scope is accurately documented.",
            actual=(
                "No Firebase, HTTP/Dio, database, socket or payment SDK is "
                "declared; only Flutter, cupertino_icons and url_launcher."
            ),
            evidence="EV-SOURCE-001",
            priority="High",
        ),
        _case(
            "REV-002",
            "FAQ & Support",
            "Email-only direct support exposure",
            "Pass",
            objective="Verify direct support channels match the intended design.",
            expected="Email is the only direct support method.",
            actual="FAQ source and automated tests expose email only; no call/ticket/WhatsApp support.",
            evidence="EV-UI-006; EV-SOURCE-001",
        ),
        _case(
            "REV-003",
            "Events",
            "Events access gate",
            "Pass",
            objective="Verify Events renders without a purchase gate.",
            expected="Events opens directly.",
            actual="Route maps to MainShell Events tab; dedicated automated case passed.",
            evidence="EV-UI-003; EV-TEST-001",
        ),
        _case(
            "REV-004",
            "Events",
            "Local event asset mapping",
            "Pass",
            objective="Verify bundled event assets exist and are declared.",
            expected="Unique local images resolve through the catalog.",
            actual="Five event PNGs are present, declared in pubspec, and asset test passed.",
            evidence="EV-UI-003; EV-UI-004; EV-SOURCE-001",
        ),
        _case(
            "REV-005",
            "Build & Compatibility",
            "Production Android identity and signing",
            "Fail",
            objective="Assess production release configuration.",
            expected="Unique application ID and non-debug release signing are configured.",
            actual="applicationId is com.example.amora_ai and release uses the debug signing key.",
            evidence="EV-SOURCE-001",
            severity="P1",
            remarks="BUG-BLD-001; release APK intentionally not attempted.",
        ),
        _case(
            "REV-006",
            "Events",
            "Current event date context",
            "Fail",
            objective="Check that 'This week' content is time-current.",
            expected="Displayed upcoming dates align with the current date.",
            actual=(
                "Static fixtures begin at 18 July while the QA date is "
                "27 July 2026; freshness cannot be guaranteed."
            ),
            evidence="EV-UI-003; EV-SOURCE-001",
            severity="P3",
            priority="Medium",
            remarks="Tracked as RISK-004 rather than a backend defect.",
        ),
        _case(
            "REV-007",
            "Security Review",
            "OTP confidentiality in production mode",
            "Fail",
            objective="Check whether verification codes are exposed in UI.",
            expected="Production authentication never displays an OTP.",
            actual="The frontend prototype generates an OTP locally and displays 'Demo OTP' in a snackbar.",
            evidence="EV-SOURCE-001",
            severity="P1",
            remarks="BUG-SEC-001; acceptable only for an explicitly labelled demo build.",
        ),
    ]


def _planned_cases() -> list[dict]:
    specs = [
        ("MAN-AUTH-001", "Authentication", "Real OTP delivery and verification", "Blocked", "OTP provider/backend is not integrated."),
        ("MAN-AUTH-002", "Authentication", "Session persistence after process restart", "Blocked", "Session state is an in-memory ValueNotifier."),
        ("MAN-AUTH-003", "Authentication", "Password reset email delivery", "Blocked", "No backend/email service is declared."),
        ("MAN-CHT-001", "Chats", "Real-time multi-user message delivery", "Blocked", "No socket/API/Firebase transport is declared."),
        ("MAN-CHT-002", "Chats", "Push notification for a new message", "Blocked", "No push notification SDK/backend is declared."),
        ("MAN-EVT-001", "Events", "Server-backed RSVP concurrency", "Blocked", "Events and participation are local fixture state."),
        ("MAN-PAY-001", "Subscription & Payment", "Sandbox payment success/failure/cancel", "Blocked", "AMORA_MEMBERSHIP_TEST is disabled and no payment SDK exists."),
        ("MAN-NOT-001", "Notifications", "Remote deep-link delivery", "Blocked", "Notification feed is local presentation data."),
        ("MAN-SUP-001", "FAQ & Support", "Native email client launch on Android", "Blocked", "No Android device/emulator is connected."),
        ("MAN-SEC-001", "Security Review", "Backend authorization and data access rules", "Blocked", "No backend project/configuration is in scope."),
        ("MAN-RESP-001", "Design System", "Physical Android 320x568 visual pass", "Not Run", "Requires device/emulator visual execution."),
        ("MAN-RESP-002", "Design System", "Physical Android 412x915 visual pass", "Not Run", "Requires device/emulator visual execution."),
        ("MAN-RESP-003", "Design System", "Tablet 768x1024 touch pass", "Not Run", "No tablet device/emulator connected."),
        ("MAN-RESP-004", "Design System", "Landscape 1024x768 interaction pass", "Not Run", "Not manually exercised."),
        ("MAN-WEB-001", "Build & Compatibility", "Chrome 1366x768 exploratory journey", "Not Run", "Chrome debug process launched; interactive session was isolated from QA browser."),
        ("MAN-WEB-002", "Build & Compatibility", "Chrome keyboard-only full journey", "Not Run", "Only targeted widget keyboard assertions were executed."),
        ("MAN-ACC-001", "Design System", "Screen reader announcement order", "Not Run", "No NVDA/TalkBack manual session was executed."),
        ("MAN-ACC-002", "Design System", "200% text scaling across all routes", "Not Run", "Only targeted automated scaling checks exist."),
        ("MAN-PERF-001", "Build & Compatibility", "Flutter DevTools frame profiling", "Not Run", "No profiling-mode measurement was executed."),
        ("MAN-PERF-002", "Build & Compatibility", "Memory/leak profiling over 30 minutes", "Not Run", "No endurance session was executed."),
        ("MAN-UAT-001", "Cross-functional", "Stakeholder UAT sign-off", "Not Run", "Requires product stakeholder execution."),
        ("NA-IOS-001", "Build & Compatibility", "iOS build/install", "Not Applicable", "iOS cannot be built on this Windows host."),
        ("NA-WIN-001", "Build & Compatibility", "Windows desktop release build", "Not Applicable", "Windows C++ workload is incomplete and desktop release is not requested."),
        ("NA-REL-001", "Build & Compatibility", "Android release APK", "Not Applicable", "Release uses debug signing; forcing a release artifact would be misleading."),
    ]
    result = []
    for case_id, module, scenario, status, actual in specs:
        expected = {
            "Blocked": "Scenario completes against an integrated test environment.",
            "Not Run": "Scenario is manually exercised with documented evidence.",
            "Not Applicable": "Scenario is executed only on an applicable/configured platform.",
        }[status]
        result.append(
            _case(
                case_id,
                module,
                scenario,
                status,
                objective=f"Validate {scenario.lower()}.",
                expected=expected,
                actual=actual,
                evidence="EV-LIMIT-001",
                priority="High" if status == "Blocked" else "Medium",
                environment="Required external/device environment unavailable",
                remarks="No pass claim made.",
            )
        )
    return result


DEFECTS = [
    {
        "id": "BUG-UI-001",
        "module": "Design System",
        "title": "Secondary pink with white text fails the tested AA threshold",
        "description": "The automated contrast function measured 3.10:1.",
        "steps": "Run flutter test test/brand_theme_test.dart.",
        "expected": "Contrast is greater than 4.5:1 for normal text.",
        "actual": "3.1024:1.",
        "severity": "P2",
        "priority": "High",
        "status": "Open",
        "evidence": "EV-TEST-001",
        "fix": "Use primary text on pink or restrict white-on-pink to qualifying large/bold text.",
    },
    {
        "id": "BUG-UI-002",
        "module": "Design System",
        "title": "Secondary action resolves to the primary color",
        "description": "A semantic secondary FilledButton resolves to #3D0B3F.",
        "steps": "Run the brand-theme secondary-action widget test.",
        "expected": "Background #EC5FA8 with its defined foreground.",
        "actual": "Background #3D0B3F.",
        "severity": "P3",
        "priority": "Medium",
        "status": "Open",
        "evidence": "EV-TEST-001",
        "fix": "Correct the secondary variant style mapping and retain semantic tests.",
    },
    {
        "id": "BUG-EVT-001",
        "module": "Events",
        "title": "Featured event card overflows with scaled text on a narrow screen",
        "description": "A Column in events_widgets.dart overflowed by 35 px.",
        "steps": "Render Events at 320x700 with text scale 1.3.",
        "expected": "All content remains visible without RenderFlex overflow.",
        "actual": "35 px bottom overflow.",
        "severity": "P2",
        "priority": "High",
        "status": "Open",
        "evidence": "EV-TEST-001",
        "fix": "Remove fixed vertical assumptions; use flexible/scroll-aware card content.",
    },
    {
        "id": "BUG-EVT-002",
        "module": "Event Waitlist",
        "title": "Waitlist route violates ListTile Material painting contract",
        "description": "A decorated Container obscures the ListTile Material ink/background.",
        "steps": "Build /event-waitlist in the all-routes widget test.",
        "expected": "Route builds without FlutterError.",
        "actual": "ListTile background/ink visibility assertion.",
        "severity": "P2",
        "priority": "High",
        "status": "Open",
        "evidence": "EV-TEST-001",
        "fix": "Wrap the SwitchListTile in Material or move decoration to a Material ancestor.",
    },
    {
        "id": "BUG-TST-001",
        "module": "Regression Tests",
        "title": "Legacy Discover and Events-gate tests contradict current requirements",
        "description": "Old four-tab, widget-key and locked-Events expectations fail against the current five-tab direct Events flow.",
        "steps": "Run flutter test; review four_tab_discover_test.dart and the locked-state regression case.",
        "expected": "Regression tests represent current route and widget contracts.",
        "actual": "Fifteen related failures target removed/renamed behavior.",
        "severity": "P2",
        "priority": "High",
        "status": "Open",
        "evidence": "EV-TEST-001",
        "fix": "Retire obsolete tests and merge non-duplicative assertions into the current Discover/Events suites.",
    },
    {
        "id": "BUG-TST-002",
        "module": "Regression Tests",
        "title": "Legacy onboarding journey tests use ambiguous text locators",
        "description": "Three tests throw 'Too many elements' after the onboarding redesign.",
        "steps": "Run test/widget_test.dart.",
        "expected": "Locators uniquely identify the intended control.",
        "actual": "Ambiguous finder failures.",
        "severity": "P3",
        "priority": "Medium",
        "status": "Open",
        "evidence": "EV-TEST-001",
        "fix": "Use stable keys or scoped semantic locators for duplicated labels.",
    },
    {
        "id": "BUG-BLD-001",
        "module": "Android Release",
        "title": "Release configuration retains template identity and debug signing",
        "description": "The Android applicationId is com.example.amora_ai and release points at the debug signing config.",
        "steps": "Inspect android/app/build.gradle.kts and the debug APK manifest.",
        "expected": "Production namespace/application ID and protected release signing.",
        "actual": "Template ID and debug key configuration.",
        "severity": "P1",
        "priority": "Critical",
        "status": "Open",
        "evidence": "EV-SOURCE-001; EV-BUILD-001",
        "fix": "Configure the approved application ID and secure release signing outside source control.",
    },
    {
        "id": "BUG-SEC-001",
        "module": "Authentication",
        "title": "Demo OTP is exposed in the UI",
        "description": "phone_otp_screen.dart generates a code locally and displays it in a snackbar.",
        "steps": "Open phone login and request a code in the current frontend prototype.",
        "expected": "A production build never exposes the OTP to the same client.",
        "actual": "UI displays 'Demo OTP: <code>'.",
        "severity": "P1",
        "priority": "Critical",
        "status": "Open",
        "evidence": "EV-SOURCE-001",
        "fix": "Strictly isolate demo OTP behavior behind a non-production compile flag and integrate server verification.",
    },
]

RISKS = [
    ("RISK-001", "No production backend/network SDK is declared", "High", "Critical", "Critical", "Cross-functional", "Integrate authenticated APIs and contract tests.", "Engineering", "Open"),
    ("RISK-002", "Authentication/session state is memory-only", "High", "Critical", "Critical", "Authentication", "Use secure persisted tokens and server authorization.", "Security", "Open"),
    ("RISK-003", "Profiles, chats, matches and events use local/dummy data", "High", "High", "High", "Core product", "Replace fixtures with environment-backed repositories.", "Engineering", "Open"),
    ("RISK-004", "Static event dates may become stale", "High", "Medium", "High", "Events", "Use server timestamps and time-zone-aware filtering.", "Product", "Open"),
    ("RISK-005", "Payment simulation is disabled and no payment SDK is declared", "High", "Critical", "Critical", "Payments", "Integrate a sandbox gateway and entitlement service.", "Payments", "Open"),
    ("RISK-006", "Push/deep-link delivery is not integrated", "High", "High", "High", "Notifications", "Add provider configuration and device tests.", "Engineering", "Open"),
    ("RISK-007", "No integration_test suite exists", "High", "High", "High", "Automation", "Add device-level golden-path journeys.", "QA", "Open"),
    ("RISK-008", "No coverage report/baseline is configured", "Medium", "Medium", "Medium", "Automation", "Publish line/branch coverage with thresholds.", "QA", "Open"),
    ("RISK-009", "No Android physical device was available", "Medium", "High", "High", "Compatibility", "Run a signed test build on representative devices.", "QA", "Open"),
    ("RISK-010", "Debug APK is 164.3 MiB", "High", "Medium", "High", "Performance", "Measure split APK/app bundle and optimize image assets.", "Engineering", "Open"),
    ("RISK-011", "Release identity/signing is not production ready", "High", "Critical", "Critical", "Android Release", "Resolve BUG-BLD-001 before any store delivery.", "Release", "Open"),
    ("RISK-012", "Email launch depends on an external client", "Medium", "Medium", "Medium", "Support", "Add graceful fallback and test on Android/iOS.", "Product", "Open"),
    ("RISK-013", "Accessibility is assertion-led, not assistive-tech verified", "High", "High", "High", "Accessibility", "Run TalkBack, VoiceOver/NVDA and 200% scaling sessions.", "QA", "Open"),
    ("RISK-014", "Windows desktop toolchain is incomplete", "Low", "Low", "Low", "Compatibility", "Install C++ workload only if Windows becomes a target.", "Engineering", "Accepted"),
]


def _requirements() -> list[dict]:
    rows = [
        ("REQ-AUTH-001", "Authentication", "Auth entry, login/signup/OTP validation and guarded actions", "Implemented locally", "High"),
        ("REQ-ONB-001", "Onboarding", "Profile onboarding, birth-date age rule, city and completion flow", "Implemented locally", "High"),
        ("REQ-DIS-001", "Discover", "Single-card discovery, image navigation, gestures and actions", "Implemented locally", "High"),
        ("REQ-FLT-001", "Filters", "Open, search, select, reset and apply supported filters", "Implemented locally", "Medium"),
        ("REQ-PDT-001", "Profile Detail", "Gallery, story content, safety and supported actions", "Implemented locally", "High"),
        ("REQ-PRO-001", "User Profile", "Identity hero, completion, photos, prompts, settings and support", "Implemented locally", "High"),
        ("REQ-EDT-001", "Edit Profile", "Editable profile values and local save behavior", "Implemented locally", "High"),
        ("REQ-PRV-001", "Profile Preview", "Public-profile preview without dating actions", "Implemented locally", "Medium"),
        ("REQ-MAT-001", "AI Matches", "Compatibility presentation without unsupported AI claims", "Frontend fixture", "Medium"),
        ("REQ-CHT-001", "Chats", "Inbox, filters, conversation routing and text messaging UI", "Frontend fixture", "High"),
        ("REQ-EVT-001", "Events", "Direct discovery, filters, local images, RSVP states and My Events", "Frontend fixture", "High"),
        ("REQ-EVD-001", "Event Detail & My Events", "Immersive details, status CTA, safety and joined list", "Frontend fixture", "High"),
        ("REQ-NOT-001", "Notifications", "Local timeline, filters, gestures, badges and routing", "Frontend fixture", "Medium"),
        ("REQ-SUB-001", "Subscription & Payment", "Plans and isolated AMORA_MEMBERSHIP_TEST simulation", "Test mode only", "High"),
        ("REQ-SUP-001", "FAQ & Support", "Searchable FAQs and email-only support", "Implemented locally", "High"),
        ("REQ-SET-001", "Settings & Account", "Account/privacy/notifications/logout/delete presentation", "Implemented locally", "High"),
        ("REQ-SAF-001", "Safety & Privacy", "Report, block, safety, terms and privacy presentation", "Implemented locally", "High"),
        ("REQ-UI-001", "Design System", "Approved palette, typography, responsive layout and accessibility", "Partial", "High"),
        ("REQ-BLD-001", "Build & Compatibility", "Analyzer-clean web and Android debug builds", "Implemented", "Critical"),
        ("REQ-SEC-001", "Security Review", "No secret exposure and production-safe auth/payment boundaries", "Not production ready", "Critical"),
    ]
    return [
        {
            "id": rid,
            "module": module,
            "requirement": text,
            "source": "User QA brief + inspected source",
            "priority": priority,
            "implementation": implementation,
        }
        for rid, module, text, implementation, priority in rows
    ]


def build_dataset() -> dict:
    automated = _parse_automated_tests()
    cases = automated + _build_review_cases() + _planned_cases()
    if len(cases) != 180:
        raise RuntimeError(f"Expected 180 catalogue cases, got {len(cases)}")
    counts = Counter(case["status"] for case in cases)
    expected = {
        "Pass": 125,
        "Fail": 26,
        "Blocked": 10,
        "Not Run": 16,
        "Not Applicable": 3,
    }
    if dict(counts) != expected:
        raise RuntimeError(f"Unexpected status totals: {dict(counts)}")

    by_module: dict[str, Counter] = defaultdict(Counter)
    for case in cases:
        by_module[case["module"]][case["status"]] += 1

    requirements = _requirements()
    requirement_keywords = {
        "Edit Profile": ("edit profile", "editable", "saves local fields"),
        "Profile Preview": ("profile preview", "preview profile"),
        "Event Detail & My Events": (
            "event detail",
            "my events",
            "join event",
            "waitlist",
        ),
        "Settings & Account": (
            "settings",
            "logout",
            "delete account",
            "session clearing",
        ),
        "Safety & Privacy": ("report", "block", "safety", "privacy"),
    }
    for req in requirements:
        keywords = requirement_keywords.get(req["module"], ())
        linked_cases = [
            case
            for case in cases
            if case["module"] == req["module"]
            or any(
                keyword
                in f"{case['scenario']} {case['objective']} {case['remarks']}".lower()
                for keyword in keywords
            )
        ]
        linked = [case["id"] for case in linked_cases]
        req["test_cases"] = ", ".join(linked[:10]) + (
            f" +{len(linked) - 10} more" if len(linked) > 10 else ""
        )
        statuses = Counter(case["status"] for case in linked_cases)
        req["test_status"] = ", ".join(
            f"{key}: {value}" for key, value in statuses.items()
        )
        req["remarks"] = (
            "Backend-dependent behavior remains blocked."
            if "fixture" in req["implementation"].lower()
            or "not production" in req["implementation"].lower()
            else "See catalogue and defect/risk logs."
        )

    routes = []
    route_pattern = re.compile(
        r"static const (?:String )?(?:routeName|aliasRouteName)\s*=\s*'([^']+)'"
    )
    for path in (ROOT / "lib").rglob("*.dart"):
        source = path.read_text(encoding="utf-8")
        for route in route_pattern.findall(source):
            routes.append(
                {
                    "route": route,
                    "source": str(path.relative_to(ROOT)).replace("\\", "/"),
                }
            )
    routes = sorted({(r["route"], r["source"]) for r in routes})
    route_rows = [{"route": route, "source": source} for route, source in routes]

    screens = sorted(
        str(path.relative_to(ROOT)).replace("\\", "/")
        for path in (ROOT / "lib" / "features").rglob("*screen.dart")
    )

    metadata = {
        "title": "Amora QA Testing Report",
        "project": "Amora AI Flutter Application",
        "version": "1.0",
        "date": TODAY.isoformat(),
        "classification": "Internal QA / Submission",
        "release_decision": "Not Ready",
        "modules_reviewed": 21,
        "feature_directories": 36,
        "screens_discovered": len(screens),
        "route_constants_discovered": 93,
        "routes_with_literal_values": len(route_rows),
        "lib_files": 137,
        "lib_loc": 49_921,
        "test_files": 23,
        "asset_files": 163,
        "asset_bytes": 24_408_115,
        "apk_path": str(
            ROOT / "build" / "app" / "outputs" / "flutter-apk" / "app-debug.apk"
        ),
        "apk_bytes": 172_299_833,
        "apk_sha256": "A006530443D7EC2BFFCE01DA0DACBDBA5DE2ACD10E3212FB662EF5F1133A1988",
        "web_bytes": 68_034_713,
        "automated_total": 143,
        "automated_passed": 115,
        "automated_failed": 23,
        "automated_skipped": 5,
        "catalogue_total": len(cases),
        "catalogue_counts": dict(counts),
        "confirmed_defects": len(DEFECTS),
    }

    return {
        "metadata": metadata,
        "cases": cases,
        "requirements": requirements,
        "defects": DEFECTS,
        "risks": [
            {
                "id": row[0],
                "risk": row[1],
                "probability": row[2],
                "impact": row[3],
                "level": row[4],
                "module": row[5],
                "mitigation": row[6],
                "owner": row[7],
                "status": row[8],
            }
            for row in RISKS
        ],
        "module_summary": {
            module: dict(counter) for module, counter in sorted(by_module.items())
        },
        "routes": route_rows,
        "screens": screens,
        "safe_test_data": {
            "name": "Priya Test",
            "age": "27",
            "city": "Ahmedabad",
            "occupation": "Product Designer",
            "email": "qa.amora@example.com",
            "phone": "Use only a provider-approved test number; none configured here.",
            "password": "Never stored in this report.",
            "otp": "Do not include real OTPs; demo codes omitted from evidence.",
        },
    }


if __name__ == "__main__":
    output = ROOT / "docs" / "qa_work" / "qa_dataset.json"
    output.write_text(
        json.dumps(build_dataset(), indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(output)
