enum CommunicationStyle {
  frequentTexting('frequent_texting', 'Frequent texting'),
  occasionalTexting('occasional_texting', 'Occasional texting'),
  calls('calls', 'Calls'),
  voiceNotes('voice_notes', 'Voice notes'),
  deepConversations('deep_conversations', 'Deep conversations'),
  lightFunConversations('light_fun_conversations', 'Light/fun conversations');

  const CommunicationStyle(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static CommunicationStyle? fromStorageValue(Object? value) {
    final normalized = value is Map ? value['value'] : value;
    if (normalized is! String) return null;
    for (final style in values) {
      if (style.storageValue == normalized.trim()) return style;
    }
    return null;
  }
}
