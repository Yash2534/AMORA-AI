import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AmoraaSelectVariant { standard, searchable, compact }

enum AmoraaSelectionMode { single, multiple }

@immutable
class AmoraaSelectOption<T> {
  const AmoraaSelectOption({
    required this.value,
    required this.label,
    this.description,
    this.icon,
  });

  final T value;
  final String label;
  final String? description;
  final IconData? icon;
}

class AmoraaSelectField<T> extends StatefulWidget {
  const AmoraaSelectField({
    super.key,
    required this.label,
    required this.options,
    this.onChanged,
    this.selectionMode = AmoraaSelectionMode.single,
    this.selectedValues,
    this.onSelectionChanged,
    this.value,
    this.hintText,
    this.supportingText,
    this.searchHint = 'Search',
    this.searchSemanticLabel,
    this.prefixIcon,
    this.variant = AmoraaSelectVariant.standard,
    this.enabled = true,
    this.isLoading = false,
    this.readOnly = false,
    this.isRequired = false,
    this.errorText,
    this.validator,
    this.allowClear = false,
  }) : assert(
         selectionMode == AmoraaSelectionMode.single
             ? onChanged != null
             : onSelectionChanged != null,
         'Single-select fields require onChanged; multi-select fields require onSelectionChanged.',
       );

  final String label;
  final List<AmoraaSelectOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final AmoraaSelectionMode selectionMode;
  final Set<T>? selectedValues;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final T? value;
  final String? hintText;
  final String? supportingText;
  final String searchHint;
  final String? searchSemanticLabel;
  final IconData? prefixIcon;
  final AmoraaSelectVariant variant;
  final bool enabled;
  final bool isLoading;
  final bool readOnly;
  final bool isRequired;
  final String? errorText;
  final FormFieldValidator<T>? validator;
  final bool allowClear;

  @override
  State<AmoraaSelectField<T>> createState() => _AmoraaSelectFieldState<T>();
}

class AmoraaSearchableSelect<T> extends AmoraaSelectField<T> {
  const AmoraaSearchableSelect({
    super.key,
    required super.label,
    required super.options,
    super.onChanged,
    super.selectionMode,
    super.selectedValues,
    super.onSelectionChanged,
    super.value,
    super.hintText,
    super.supportingText,
    super.searchHint,
    super.searchSemanticLabel,
    super.prefixIcon,
    super.enabled,
    super.isLoading,
    super.readOnly,
    super.isRequired,
    super.errorText,
    super.validator,
    super.allowClear,
  }) : super(variant: AmoraaSelectVariant.searchable);
}

class AmoraaCompactSelect<T> extends AmoraaSelectField<T> {
  const AmoraaCompactSelect({
    super.key,
    required super.label,
    required super.options,
    super.onChanged,
    super.selectionMode,
    super.selectedValues,
    super.onSelectionChanged,
    super.value,
    super.hintText,
    super.supportingText,
    super.prefixIcon,
    super.enabled,
    super.isLoading,
    super.readOnly,
    super.isRequired,
    super.errorText,
    super.validator,
    super.allowClear,
  }) : super(variant: AmoraaSelectVariant.compact);
}

class _AmoraaSelectFieldState<T> extends State<AmoraaSelectField<T>> {
  final FocusNode _focusNode = FocusNode();
  bool _hovered = false;
  bool _pressed = false;
  bool _open = false;

  bool get _interactive =>
      widget.enabled && !widget.isLoading && !widget.readOnly;

  AmoraaSelectOption<T>? get _selected {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  Set<T> get _selectedValues =>
      widget.selectionMode == AmoraaSelectionMode.multiple
      ? Set<T>.unmodifiable(widget.selectedValues ?? <T>{})
      : <T>{?widget.value};

  String get _displayValue {
    if (widget.selectionMode == AmoraaSelectionMode.single) {
      return _selected?.label ??
          widget.hintText ??
          'Select ${widget.label.toLowerCase()}';
    }
    final selected = _selectedValues;
    if (selected.isEmpty) {
      return widget.hintText ?? 'Select ${widget.label.toLowerCase()}';
    }
    final labels = <String>[
      for (final option in widget.options)
        if (selected.contains(option.value)) option.label,
    ];
    return labels.length == 1 ? labels.single : '${labels.length} selected';
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_refresh);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: widget.value,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) {
        final externalError = widget.errorText;
        final error = externalError ?? field.errorText;
        final selected = _selected;
        final selectedValues = _selectedValues;
        final compact = widget.variant == AmoraaSelectVariant.compact;
        final focusColor = _focusNode.hasFocus || _open
            ? AppColors.secondary
            : AppColors.tertiary;
        final borderColor = error != null
            ? AppColors.primary
            : _hovered
            ? AppColors.secondary.withValues(alpha: .78)
            : focusColor;
        final disabledOpacity = widget.enabled ? 1.0 : .54;
        final semanticValue = selectedValues.isEmpty
            ? widget.hintText ?? 'Not selected'
            : widget.selectionMode == AmoraaSelectionMode.multiple
            ? '${selectedValues.length} options selected'
            : selected?.label ?? 'Not selected';
        return Semantics(
          button: true,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          label:
              '${widget.label}${widget.isRequired ? ', required' : ', optional'}',
          value: semanticValue,
          hint: error,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FocusableActionDetector(
                focusNode: _focusNode,
                enabled: _interactive,
                mouseCursor: _interactive
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                onShowHoverHighlight: (value) =>
                    setState(() => _hovered = value),
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
                },
                actions: {
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (_) {
                      _openSelector(field);
                      return null;
                    },
                  ),
                },
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hovered = true),
                  onExit: (_) => setState(() {
                    _hovered = false;
                    _pressed = false;
                  }),
                  child: GestureDetector(
                    onTapDown: _interactive
                        ? (_) => setState(() => _pressed = true)
                        : null,
                    onTapCancel: _interactive
                        ? () => setState(() => _pressed = false)
                        : null,
                    onTapUp: _interactive
                        ? (_) => setState(() => _pressed = false)
                        : null,
                    child: AnimatedContainer(
                      key: const ValueKey('amoraa-select-closed-field'),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      constraints: BoxConstraints(minHeight: compact ? 52 : 58),
                      decoration: BoxDecoration(
                        color: _pressed
                            ? AppColors.tertiary.withValues(alpha: .42)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(compact ? 16 : 18),
                        border: Border.all(
                          color: borderColor,
                          width: _focusNode.hasFocus || _open ? 1.8 : 1,
                        ),
                      ),
                      child: Material(
                        color: AppColors.transparent,
                        borderRadius: BorderRadius.circular(compact ? 16 : 18),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _interactive
                              ? () => _openSelector(field)
                              : null,
                          child: Opacity(
                            opacity: disabledOpacity,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 12 : 14,
                                vertical: compact ? 8 : 9,
                              ),
                              child: Row(
                                children: [
                                  if (widget.prefixIcon != null) ...[
                                    Icon(
                                      widget.prefixIcon,
                                      size: 21,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: AmoraSpacing.space12),
                                  ],
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${widget.label}${widget.isRequired ? ' *' : ''}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AmoraTextStyles.labelSmall
                                              .copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _displayValue,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AmoraTextStyles.bodyMedium
                                              .copyWith(
                                                color: selectedValues.isEmpty
                                                    ? AppColors.text.withValues(
                                                        alpha: .58,
                                                      )
                                                    : AppColors.text,
                                                fontWeight:
                                                    selectedValues.isEmpty
                                                    ? FontWeight.w400
                                                    : FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AmoraSpacing.space8),
                                  if (widget.isLoading)
                                    const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.secondary,
                                      ),
                                    )
                                  else
                                    AnimatedRotation(
                                      turns: _open ? .5 : 0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      child: const Icon(
                                        Icons.expand_more_rounded,
                                        size: 22,
                                        color: AppColors.text,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: AmoraSpacing.space4),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    key: const ValueKey('amoraa-select-error'),
                    style: AmoraTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ] else if (widget.supportingText case final supporting?) ...[
                const SizedBox(height: AmoraSpacing.space4),
                Text(
                  supporting,
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.text.withValues(alpha: .66),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSelector(FormFieldState<T> field) async {
    if (!_interactive || _open) return;
    _focusNode.requestFocus();
    setState(() => _open = true);
    final width = MediaQuery.sizeOf(context).width;
    final sheet = AmoraaSelectBottomSheet<T>(
      title: widget.label,
      supportingText: widget.supportingText,
      options: widget.options,
      selectedValue: widget.value,
      selectedValues: _selectedValues,
      selectionMode: widget.selectionMode,
      searchable: widget.variant == AmoraaSelectVariant.searchable,
      searchHint: widget.searchHint,
      searchSemanticLabel: widget.searchSemanticLabel,
      allowClear: widget.allowClear,
    );
    final result = width >= 720
        ? await showDialog<_AmoraaSelectResult<T>>(
            context: context,
            barrierColor: AppColors.text.withValues(alpha: .22),
            builder: (context) => Dialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.tertiary),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                  maxHeight: 680,
                ),
                child: sheet,
              ),
            ),
          )
        : await showAmoraBottomSheet<_AmoraaSelectResult<T>>(
            context: context,
            child: sheet,
          );
    if (mounted) setState(() => _open = false);
    if (result == null) return;
    if (widget.selectionMode == AmoraaSelectionMode.multiple) {
      widget.onSelectionChanged!(Set<T>.unmodifiable(result.values ?? <T>{}));
      return;
    }
    field.didChange(result.value);
    widget.onChanged!(result.value);
  }
}

class _AmoraaSelectResult<T> {
  const _AmoraaSelectResult.single(this.value) : values = null;

  _AmoraaSelectResult.multiple(Set<T> values)
    : value = null,
      values = Set<T>.unmodifiable(values);

  final T? value;
  final Set<T>? values;
}

class AmoraaSelectBottomSheet<T> extends StatefulWidget {
  const AmoraaSelectBottomSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.selectedValues,
    required this.selectionMode,
    required this.searchable,
    required this.searchHint,
    this.searchSemanticLabel,
    required this.allowClear,
    this.supportingText,
  });

  final String title;
  final String? supportingText;
  final List<AmoraaSelectOption<T>> options;
  final T? selectedValue;
  final Set<T> selectedValues;
  final AmoraaSelectionMode selectionMode;
  final bool searchable;
  final String searchHint;
  final String? searchSemanticLabel;
  final bool allowClear;

  @override
  State<AmoraaSelectBottomSheet<T>> createState() =>
      _AmoraaSelectBottomSheetState<T>();
}

class _AmoraaSelectBottomSheetState<T>
    extends State<AmoraaSelectBottomSheet<T>> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;
  late final Set<T> _selectedValues;
  String _query = '';
  int _highlightedIndex = 0;

  List<AmoraaSelectOption<T>> get _visibleOptions {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return widget.options
        .where(
          (option) =>
              option.label.toLowerCase().contains(query) ||
              (option.description?.toLowerCase().contains(query) ?? false),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
    _selectedValues = Set<T>.of(widget.selectedValues);
    final selectedIndex = widget.options.indexWhere(
      (option) => option.value == widget.selectedValue,
    );
    _highlightedIndex = selectedIndex < 0 ? 0 : selectedIndex;
    if (widget.searchable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = _visibleOptions;
    final availableHeight = MediaQuery.sizeOf(context).height;
    final height = (availableHeight * .72).clamp(360.0, 680.0);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveHighlight(1, options.length),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveHighlight(-1, options.length),
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            _selectHighlighted(options),
      },
      child: Focus(
        autofocus: !widget.searchable,
        child: SizedBox(
          key: const ValueKey('amoraa-select-sheet'),
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AmoraTextStyles.headlineSmall,
                        ),
                        if (widget.supportingText case final text?) ...[
                          const SizedBox(height: AmoraSpacing.space4),
                          Text(
                            text,
                            style: AmoraTextStyles.bodySmall.copyWith(
                              color: AppColors.text.withValues(alpha: .66),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('amoraa-select-close'),
                    tooltip: 'Close selector',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (widget.searchable) ...[
                const SizedBox(height: AmoraSpacing.space12),
                Semantics(
                  textField: true,
                  label: widget.searchSemanticLabel ?? widget.searchHint,
                  child: TextField(
                    key: const ValueKey('amoraa-select-search'),
                    controller: _searchController,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _query = '';
                                  _highlightedIndex = 0;
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                    onChanged: (value) => setState(() {
                      _query = value;
                      _highlightedIndex = 0;
                    }),
                  ),
                ),
              ],
              const SizedBox(height: AmoraSpacing.space12),
              Divider(
                height: 1,
                color: AppColors.tertiary.withValues(alpha: .72),
              ),
              const SizedBox(height: AmoraSpacing.space8),
              Expanded(
                child: options.isEmpty
                    ? const _AmoraaSelectEmptyState()
                    : ListView.separated(
                        key: const ValueKey('amoraa-select-options'),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.viewPaddingOf(context).bottom,
                        ),
                        itemCount: options.length + (widget.allowClear ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AmoraSpacing.space4),
                        itemBuilder: (context, index) {
                          if (widget.allowClear && index == 0) {
                            return _AmoraaClearOptionTile(
                              selected:
                                  widget.selectionMode ==
                                      AmoraaSelectionMode.multiple
                                  ? _selectedValues.isEmpty
                                  : widget.selectedValue == null,
                              onTap: () {
                                if (widget.selectionMode ==
                                    AmoraaSelectionMode.multiple) {
                                  setState(_selectedValues.clear);
                                  return;
                                }
                                Navigator.of(
                                  context,
                                ).pop(_AmoraaSelectResult<T>.single(null));
                              },
                            );
                          }
                          final optionIndex =
                              index - (widget.allowClear ? 1 : 0);
                          final option = options[optionIndex];
                          return AmoraaSelectOptionTile<T>(
                            key: ValueKey(
                              'amoraa-select-option-${option.label}',
                            ),
                            option: option,
                            selected:
                                widget.selectionMode ==
                                    AmoraaSelectionMode.multiple
                                ? _selectedValues.contains(option.value)
                                : option.value == widget.selectedValue,
                            highlighted: optionIndex == _highlightedIndex,
                            selectionMode: widget.selectionMode,
                            onTap: () {
                              if (widget.selectionMode ==
                                  AmoraaSelectionMode.multiple) {
                                setState(() {
                                  _selectedValues.contains(option.value)
                                      ? _selectedValues.remove(option.value)
                                      : _selectedValues.add(option.value);
                                });
                                return;
                              }
                              Navigator.of(context).pop(
                                _AmoraaSelectResult<T>.single(option.value),
                              );
                            },
                          );
                        },
                      ),
              ),
              if (widget.selectionMode == AmoraaSelectionMode.multiple) ...[
                const SizedBox(height: AmoraSpacing.space8),
                Divider(
                  height: 1,
                  color: AppColors.tertiary.withValues(alpha: .72),
                ),
                const SizedBox(height: AmoraSpacing.space12),
                FilledButton(
                  key: const ValueKey('amoraa-select-done'),
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_AmoraaSelectResult<T>.multiple(_selectedValues)),
                  child: Text(
                    _selectedValues.isEmpty
                        ? 'Done'
                        : 'Done (${_selectedValues.length})',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _moveHighlight(int delta, int length) {
    if (length == 0) return;
    setState(() {
      _highlightedIndex = (_highlightedIndex + delta).clamp(0, length - 1);
    });
  }

  void _selectHighlighted(List<AmoraaSelectOption<T>> options) {
    if (options.isEmpty) return;
    final option = options[_highlightedIndex.clamp(0, options.length - 1)];
    if (widget.selectionMode == AmoraaSelectionMode.multiple) {
      setState(() {
        _selectedValues.contains(option.value)
            ? _selectedValues.remove(option.value)
            : _selectedValues.add(option.value);
      });
      return;
    }
    Navigator.of(context).pop(_AmoraaSelectResult<T>.single(option.value));
  }
}

class _AmoraaClearOptionTile extends StatelessWidget {
  const _AmoraaClearOptionTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Clear selection',
      child: Material(
        color: selected
            ? AppColors.tertiary.withValues(alpha: .72)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('amoraa-select-clear'),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.space16,
              vertical: AmoraSpacing.space12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.secondary : AppColors.tertiary,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.clear_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
                const SizedBox(width: AmoraSpacing.space12),
                Expanded(
                  child: Text(
                    'Clear selection',
                    style: AmoraTextStyles.bodyLarge.copyWith(
                      color: AppColors.text,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? AppColors.secondary : AppColors.tertiary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AmoraaSelectOptionTile<T> extends StatelessWidget {
  const AmoraaSelectOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.highlighted,
    this.selectionMode = AmoraaSelectionMode.single,
    required this.onTap,
  });

  final AmoraaSelectOption<T> option;
  final bool selected;
  final bool highlighted;
  final AmoraaSelectionMode selectionMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selectionMode == AmoraaSelectionMode.single ? selected : null,
      toggled: selectionMode == AmoraaSelectionMode.multiple ? selected : null,
      inMutuallyExclusiveGroup: selectionMode == AmoraaSelectionMode.single,
      label: option.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: selected || highlighted
              ? AppColors.tertiary.withValues(alpha: selected ? .72 : .34)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.tertiary,
          ),
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space16,
                vertical: AmoraSpacing.space12,
              ),
              child: Row(
                children: [
                  if (option.icon != null) ...[
                    Icon(option.icon, color: AppColors.primary, size: 21),
                    const SizedBox(width: AmoraSpacing.space12),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AmoraTextStyles.bodyLarge.copyWith(
                            color: AppColors.text,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        if (option.description case final description?) ...[
                          const SizedBox(height: AmoraSpacing.space4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AmoraTextStyles.bodySmall.copyWith(
                              color: AppColors.text.withValues(alpha: .68),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AmoraSpacing.space12),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? AppColors.secondary : AppColors.tertiary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmoraaSelectEmptyState extends StatelessWidget {
  const _AmoraaSelectEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AmoraSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: AppColors.primary),
            const SizedBox(height: AmoraSpacing.space8),
            Text('No results found', style: AmoraTextStyles.titleMedium),
            const SizedBox(height: AmoraSpacing.space4),
            Text(
              'Try a different search.',
              textAlign: TextAlign.center,
              style: AmoraTextStyles.bodySmall.copyWith(
                color: AppColors.text.withValues(alpha: .66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
