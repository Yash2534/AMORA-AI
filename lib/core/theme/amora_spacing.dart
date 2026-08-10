import 'package:flutter/widgets.dart';

/// Four-point sub-grid with all layout rhythm landing on the 8-point system.
abstract final class AmoraSpacing {
  static const double space0 = 0;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space56 = 56;
  static const double space64 = 64;

  static const double minimumTouchTarget = 48;
  static const double controlHeight = 56;
  static const double compactControlHeight = 48;

  /// Header heights exclude the system status-bar inset, which is owned by
  /// Scaffold/AppBar or the containing SafeArea exactly once.
  static const double appBarHeight = 56;
  static const double appBarWithSubtitleHeight = 64;
  static const double navigationBarHeight = 80;
  static const double navigationContentInset = 136;
  static const double assistantNavigationInset = 96;
  static const double stateIllustrationSize = 80;
  static const double profileHeroAvatarCompact = 128;
  static const double profileHeroAvatar = 144;

  static const EdgeInsets screen = EdgeInsets.fromLTRB(
    space20,
    space20,
    space20,
    space32,
  );
  static const EdgeInsets card = EdgeInsets.all(space20);
  static const EdgeInsets compactCard = EdgeInsets.all(space16);
  static const EdgeInsets field = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space16,
  );
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: space24,
    vertical: space16,
  );
  static const EdgeInsets dialog = EdgeInsets.all(space24);
  static const EdgeInsets bottomSheet = EdgeInsets.fromLTRB(
    space20,
    space12,
    space20,
    space32,
  );

  static const double section = space24;
  static const double list = space12;
  static const double control = controlHeight;

  // Compatibility aliases.
  static const double x1 = space4;
  static const double x2 = space8;
  static const double x3 = space12;
  static const double x4 = space16;
  static const double x5 = space20;
  static const double x6 = space24;
  static const double x8 = space32;
  static const double x10 = space40;
  static const double x12 = space48;
  static const double x14 = space56;
  static const double x16 = space64;
}

abstract final class AmoraRadius {
  static const double none = 0;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 20;
  static const double hero = 24;
  static const double sheetTop = 28;
  static const double full = 999;

  static const BorderRadius card = BorderRadius.all(
    Radius.circular(extraLarge),
  );
  static const BorderRadius button = BorderRadius.all(Radius.circular(large));
  static const BorderRadius input = BorderRadius.all(Radius.circular(large));
  static const BorderRadius dialog = BorderRadius.all(
    Radius.circular(extraLarge),
  );
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(sheetTop),
  );
  static const BorderRadius pillBorder = BorderRadius.all(
    Radius.circular(full),
  );

  // Compatibility aliases.
  static const double md = large;
  static const double buttonRadius = large;
  static const double lg = 20;
  static const double xl = extraLarge;
  static const double xxl = 28;
  static const double xxxl = 32;
  static const double pill = full;
}
