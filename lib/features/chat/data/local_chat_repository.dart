// Compatibility export for older imports. Production chat is implemented by
// the API/realtime-backed ChatRepository.
import 'chat_repository.dart';

export 'chat_repository.dart';

typedef LocalChatRepository = ChatRepository;
