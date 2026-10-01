import 'package:amora_ai/features/chat/presentation/unread_message_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats exact unread-message labels without capping counts', () {
    expect(formatUnreadMessageLabel(-3), '');
    expect(formatUnreadMessageLabel(0), '');
    expect(formatUnreadMessageLabel(1), 'New message');
    expect(formatUnreadMessageLabel(2), '1+ message');
    expect(formatUnreadMessageLabel(3), '2+ messages');
    expect(formatUnreadMessageLabel(4), '3+ messages');
    expect(formatUnreadMessageLabel(5), '4+ messages');
    expect(formatUnreadMessageLabel(10), '9+ messages');
    expect(formatUnreadMessageLabel(100), '99+ messages');
  });
}
