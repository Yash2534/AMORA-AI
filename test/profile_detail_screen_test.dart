import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProfileActionApi extends PhaseTwoApiService {
  _ProfileActionApi(
    this.profileValue, {
    this.relationship = const PublicRelationshipState(),
  });

  final DummyProfile profileValue;
  final PublicRelationshipState relationship;
  final List<String> superLikeTargets = <String>[];
  Object? superLikeError;

  @override
  Future<PublicProfileResult> profile(String userId) async =>
      PublicProfileResult(
        profile: profileValue,
        relationship: relationship,
      );

  @override
  Future<void> superLikeProfile(String userId) async {
    if (superLikeError case final error?) throw error;
    superLikeTargets.add(userId);
  }
}

void main() {
  Future<void> pumpProfile(
    WidgetTester tester, {
    DummyProfile? profile,
    ValueChanged<RouteSettings>? onRoute,
    Future<bool> Function()? onSuperLike,
    PhaseTwoApiService? api,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: SizedBox.expand()),
        onGenerateRoute: (settings) {
          onRoute?.call(settings);
          if (settings.name == ProfileDetailScreen.routeName) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  ProfileDetailScreen(onSuperLike: onSuperLike, api: api),
            );
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(
              body: Center(child: Text('${settings.name} destination')),
            ),
          );
        },
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(
      ProfileDetailScreen.routeName,
      arguments: profile ?? ImageRepository.profiles.first,
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    AmoraSession.logIn();
    ProfileRelationshipController.instance.clear();
    await ChatRepository.instance.resetForTesting();
  });

  tearDown(AmoraSession.logOut);

  testWidgets('renders immersive profile hierarchy at 320px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final profile = ImageRepository.profiles.first;

    await pumpProfile(tester, profile: profile);

    expect(find.byKey(const ValueKey('profile-media-gallery')), findsOneWidget);
    expect(
      find.text('${profile.name.split(' ').first}, ${profile.age}'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('profile-quick-facts')), findsOneWidget);
    expect(find.text('About me'), findsOneWidget);
    expect(find.text('Relationship intentions'), findsOneWidget);
    expect(find.text('Lifestyle'), findsOneWidget);
    expect(find.text('Interests'), findsOneWidget);
    expect(find.text('Profile prompts'), findsOneWidget);
    expect(find.text('Compatibility insight'), findsOneWidget);
    expect(find.text('Safety & trust'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-like-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-message-button')),
      findsOneWidget,
    );
    expect(find.text('AI explanation:'), findsNothing);
    expect(find.textContaining('Indie cinema'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery de-duplicates photos and swipes horizontally', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final profile = ImageRepository.profiles.first;
    final uniquePhotos = <String>{profile.imageUrl, ...profile.gallery}.length;

    await pumpProfile(tester, profile: profile);
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, uniquePhotos);
    expect(find.text('1 / $uniquePhotos'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('profile-photo-0')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / $uniquePhotos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('image tap opens zoomable full-screen gallery', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpProfile(tester);
    await tester.tap(find.byKey(const ValueKey('profile-photo-0')));
    // The gallery deliberately distinguishes a tap from a double tap, so let
    // the double-tap recognizer's deadline elapse before settling the route.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-fullscreen-gallery')),
      findsOneWidget,
    );
    expect(find.byType(InteractiveViewer), findsWidgets);
    expect(find.byTooltip('Close gallery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('double tap invokes the existing like action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpProfile(tester);
    final photo = find.byKey(const ValueKey('profile-photo-0'));
    await tester.tap(photo);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(photo);
    await tester.pumpAndSettle();

    expect(find.text('Profile liked successfully'), findsOneWidget);
    expect(find.text('Like'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Like fill follows the current viewer relationship state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final profile = publicProfileFromJson({
      'id': '41',
      'name': 'Like State Profile',
    }).profile;

    Color likeFill() {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const ValueKey('profile-like-button')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    await pumpProfile(
      tester,
      profile: profile,
      api: _ProfileActionApi(profile),
    );
    expect(likeFill(), AppColors.surface);

    await tester.tap(find.byKey(const ValueKey('profile-like-button')));
    await tester.pumpAndSettle();
    expect(likeFill(), AppColors.secondary);

    ProfileRelationshipController.instance.clear();
    await pumpProfile(
      tester,
      profile: profile,
      api: _ProfileActionApi(
        profile,
        relationship: const PublicRelationshipState(liked: true),
      ),
    );
    expect(likeFill(), AppColors.secondary);
  });

  testWidgets('message action preserves its existing route', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RouteSettings? openedRoute;

    await pumpProfile(tester, onRoute: (settings) => openedRoute = settings);
    await tester.tap(find.byKey(const ValueKey('profile-message-button')));
    await tester.pumpAndSettle();

    expect(openedRoute?.name, '/chat-detail');
    expect(find.text('/chat-detail destination'), findsOneWidget);
  });

  testWidgets(
    'Super Like sends through the supplied callback without routing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var calls = 0;
      RouteSettings? openedRoute;

      await pumpProfile(
        tester,
        onRoute: (settings) => openedRoute = settings,
        onSuperLike: () async {
          calls++;
          return true;
        },
      );
      openedRoute = null;
      await tester.tap(find.byKey(const ValueKey('profile-super-like-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(calls, 1);
      expect(openedRoute, isNull);
      expect(find.text('Super Like sent'), findsWidgets);
    },
  );

  testWidgets('Super Like uses the existing API when no callback is supplied', (
    tester,
  ) async {
    final profile = publicProfileFromJson({
      'id': '27',
      'name': 'Backend Profile',
    }).profile;
    final api = _ProfileActionApi(profile);
    await pumpProfile(tester, profile: profile, api: api);

    await tester.tap(find.byKey(const ValueKey('profile-super-like-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(api.superLikeTargets, <String>['27']);
    expect(find.text('Super Like sent'), findsWidgets);
  });

  testWidgets('Super Like displays the backend failure without local success', (
    tester,
  ) async {
    final profile = publicProfileFromJson({
      'id': '31',
      'name': 'Blocked Profile',
    }).profile;
    final api = _ProfileActionApi(profile)
      ..superLikeError = const AuthException(
        'Profile is not available for Discover.',
        code: 'PROFILE_NOT_DISCOVERABLE',
        statusCode: 404,
      );
    await pumpProfile(tester, profile: profile, api: api);

    await tester.tap(find.byKey(const ValueKey('profile-super-like-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(api.superLikeTargets, isEmpty);
    expect(find.text('Profile is not available for Discover.'), findsOneWidget);
    expect(find.text('Super Like sent'), findsNothing);
  });

  testWidgets('more control exposes existing report and block actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpProfile(tester);
    await tester.tap(find.byKey(const ValueKey('profile-more-button')));
    await tester.pumpAndSettle();

    expect(find.text('Safety actions'), findsOneWidget);
    expect(find.text('Report Profile'), findsOneWidget);
    expect(find.text('Block Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop uses centred two-column presentation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpProfile(tester);
    final scroll = find.byKey(const ValueKey('profile-detail-scroll'));
    final gallery = find.byKey(const ValueKey('profile-media-gallery'));
    final facts = find.byKey(const ValueKey('profile-quick-facts'));

    expect(tester.getSize(scroll).width, lessThanOrEqualTo(1080));
    expect(tester.getCenter(scroll).dx, moreOrLessEquals(600, epsilon: 1));
    expect(
      tester.getTopLeft(gallery).dx,
      lessThan(tester.getTopLeft(facts).dx),
    );
    expect(tester.takeException(), isNull);
  });
}
