import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/legal/presentation/community_guidelines_screen.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/support/data/support_faq_data.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef SupportEmailLauncher = Future<bool> Function(Uri uri);

class FaqSupportScreen extends StatefulWidget {
  const FaqSupportScreen({super.key, this.launchEmail});

  static const routeName = '/support';
  static const legacyRouteName = '/faq-support';

  final SupportEmailLauncher? launchEmail;

  @override
  State<FaqSupportScreen> createState() => _FaqSupportScreenState();
}

class _FaqSupportScreenState extends State<FaqSupportScreen> {
  final _searchController = TextEditingController();
  var _query = '';
  var _selectedCategory = FaqCategory.all;
  String? _expandedId;
  var _launchingEmail = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SupportFaqItem> get _filteredFaqs => supportFaqs
      .where(
        (faq) =>
            (_selectedCategory == FaqCategory.all ||
                faq.category == _selectedCategory) &&
            faq.matches(_query),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaqs;
    final popular = supportFaqs
        .where((faq) => faq.popular)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 920,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: FaqSupportAppBar(
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverList.list(
                  children: [
                    FaqSearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {
                        _query = value;
                        _expandedId = null;
                      }),
                      onClear: _query.isEmpty
                          ? null
                          : () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                                _expandedId = null;
                              });
                            },
                    ),
                    const SizedBox(height: 24),
                    if (_query.isEmpty &&
                        _selectedCategory == FaqCategory.all) ...[
                      const _SectionHeading(
                        title: 'Popular questions',
                        subtitle: 'Quick answers members look for most often',
                      ),
                      const SizedBox(height: 12),
                      _PopularQuestions(
                        faqs: popular,
                        onSelected: (faq) => setState(() {
                          _selectedCategory = FaqCategory.all;
                          _expandedId = faq.id;
                        }),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const _SectionHeading(
                      title: 'Browse by topic',
                      subtitle: 'Choose a category to narrow the answers',
                    ),
                    const SizedBox(height: 12),
                    FaqCategoryBar(
                      selected: _selectedCategory,
                      onSelected: (category) => setState(() {
                        _selectedCategory = category;
                        _expandedId = null;
                      }),
                    ),
                    const SizedBox(height: 26),
                    _SectionHeading(
                      title: _selectedCategory == FaqCategory.all
                          ? 'All help topics'
                          : _selectedCategory.label,
                      subtitle: filtered.isEmpty
                          ? 'Try a different word or category'
                          : '${filtered.length} ${filtered.length == 1 ? 'answer' : 'answers'} available',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              if (filtered.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: FaqSearchEmptyState()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final faq = filtered[index];
                      return FaqAccordionTile(
                        key: ValueKey(faq.id),
                        faq: faq,
                        expanded: _expandedId == faq.id,
                        onTap: () => setState(
                          () => _expandedId = _expandedId == faq.id
                              ? null
                              : faq.id,
                        ),
                      );
                    },
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: EmailSupportCard(
                    email: SupportContact.email,
                    loading: _launchingEmail,
                    onEmail: _composeEmail,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  28,
                  20,
                  AmoraSpacing.space40,
                ),
                sliver: SliverToBoxAdapter(
                  child: LegalSupportLinks(
                    onSafetyCenter: () => Navigator.of(
                      context,
                    ).pushNamed(SafetyPrivacyScreen.routeName),
                    onGuidelines: () => Navigator.of(
                      context,
                    ).pushNamed(CommunityGuidelinesScreen.routeName),
                    onReportConcern: () => Navigator.of(
                      context,
                    ).pushNamed(ReportFlowScreen.routeName),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _composeEmail() async {
    if (_launchingEmail) return;
    setState(() => _launchingEmail = true);
    final uri = Uri(
      scheme: 'mailto',
      path: SupportContact.email,
      queryParameters: const {
        'subject': SupportContact.subject,
        'body': SupportContact.body,
      },
    );

    var launched = false;
    try {
      launched = widget.launchEmail != null
          ? await widget.launchEmail!(uri)
          : await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!mounted) return;
    setState(() => _launchingEmail = false);
    if (!launched) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No email app was available. You can write to '
              '${SupportContact.email}.',
            ),
          ),
        );
    }
  }
}

class FaqSupportAppBar extends StatelessWidget {
  const FaqSupportAppBar({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              constraints: const BoxConstraints.tightFor(
                width: AmoraSpacing.minimumTouchTarget,
                height: AmoraSpacing.minimumTouchTarget,
              ),
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Center',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Answers, reporting, and help from AMORAA.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.tertiary),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaqSearchField extends StatelessWidget {
  const FaqSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Search help topics',
      child: TextField(
        key: const ValueKey('faq-search-field'),
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search help topics',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: AppColors.tertiary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: AppColors.tertiary.withValues(alpha: .72),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(
              color: AppColors.secondary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class FaqCategoryBar extends StatelessWidget {
  const FaqCategoryBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FaqCategory selected;
  final ValueChanged<FaqCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FaqCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = FaqCategory.values[index];
          final active = category == selected;
          return Semantics(
            selected: active,
            button: true,
            label: '${category.label} help topics',
            child: ChoiceChip(
              key: ValueKey('faq-category-${category.name}'),
              selected: active,
              showCheckmark: false,
              avatar: Icon(
                category.icon,
                size: 18,
                color: active ? AppColors.surface : AppColors.secondary,
              ),
              label: Text(category.label),
              onSelected: (_) => onSelected(category),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: active ? AppColors.primary : AppColors.secondary,
              ),
              labelStyle: TextStyle(
                color: active ? AppColors.surface : AppColors.text,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FaqAccordionTile extends StatelessWidget {
  const FaqAccordionTile({
    super.key,
    required this.faq,
    required this.expanded,
    required this.onTap,
  });

  final SupportFaqItem faq;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: faq.question,
      value: expanded ? 'Expanded' : 'Collapsed',
      onTap: onTap,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: expanded
                ? AppColors.secondary
                : AppColors.tertiary.withValues(alpha: .68),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        faq.category.icon,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        faq.question,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? .5 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: expanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(52, 14, 4, 2),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              faq.answer,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FaqSearchEmptyState extends StatelessWidget {
  const FaqSearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.secondary, size: 32),
          SizedBox(height: 10),
          Text(
            'No help topics found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try another keyword or browse a different category.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.text, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class EmailSupportCard extends StatelessWidget {
  const EmailSupportCard({
    super.key,
    required this.email,
    required this.onEmail,
    required this.loading,
  });

  final String email;
  final VoidCallback onEmail;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: .78)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .08),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.secondary,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Still need help?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Send us your question and our support team will respond '
                  'by email. Include as much useful detail as possible.',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    height: 1.48,
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  label: 'Support email address, $email',
                  child: SelectableText(
                    email,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content,
                  const SizedBox(height: 20),
                  AppPrimaryButton(
                    key: const ValueKey('email-support-button'),
                    label: 'Email Support',
                    icon: Icons.mail_rounded,
                    isLoading: loading,
                    onPressed: loading ? null : onEmail,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: content),
                const SizedBox(width: 24),
                SizedBox(
                  width: 190,
                  child: AppPrimaryButton(
                    key: const ValueKey('email-support-button'),
                    label: 'Email Support',
                    icon: Icons.mail_rounded,
                    isLoading: loading,
                    onPressed: loading ? null : onEmail,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LegalSupportLinks extends StatelessWidget {
  const LegalSupportLinks({
    super.key,
    required this.onSafetyCenter,
    required this.onGuidelines,
    required this.onReportConcern,
  });

  final VoidCallback onSafetyCenter;
  final VoidCallback onGuidelines;
  final VoidCallback onReportConcern;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Safety and community',
          subtitle: 'Helpful resources already available in AMORAA',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ResourceLink(
              icon: Icons.shield_outlined,
              label: 'Safety Center',
              onTap: onSafetyCenter,
            ),
            _ResourceLink(
              icon: Icons.favorite_border_rounded,
              label: 'Community Guidelines',
              onTap: onGuidelines,
            ),
            _ResourceLink(
              icon: Icons.flag_outlined,
              label: 'Report a Problem',
              onTap: onReportConcern,
            ),
          ],
        ),
      ],
    );
  }
}

class _PopularQuestions extends StatelessWidget {
  const _PopularQuestions({required this.faqs, required this.onSelected});

  final List<SupportFaqItem> faqs;
  final ValueChanged<SupportFaqItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            for (final faq in faqs)
              SizedBox(
                width: width,
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => onSelected(faq),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.tertiary.withValues(alpha: .68),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            faq.category.icon,
                            color: AppColors.secondary,
                            size: 21,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              faq.question,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ResourceLink extends StatelessWidget {
  const _ResourceLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AmoraSpacing.minimumTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.tertiary),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.secondary, size: 19),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
