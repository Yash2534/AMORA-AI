String formatUnreadMessageLabel(int unreadCount) {
  if (unreadCount <= 0) return '';
  if (unreadCount == 1) return 'New message';

  final displayedCount = unreadCount - 1;
  return displayedCount == 1 ? '1+ message' : '$displayedCount+ messages';
}
