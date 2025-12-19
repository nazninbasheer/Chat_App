# TODO: Optimize List Users Screen Loading

## Steps to Complete

- [ ] Step 1: Modify data model - Add fields to chat documents (lastMessage, lastTimestamp, unreadCountForUser1, unreadCountForUser2)
- [x] Step 2: Update getSortedUsers in lib/screens/list_user.dart - Change to fetch chats instead of users, derive user list from chat data
- [x] Step 3: Remove per-user StreamBuilders in list_user.dart - Use pre-fetched data from chat documents for last messages
- [x] Step 4: Update lib/screens/chat_screen.dart - Add logic to update chat document fields on message send/receive
- [x] Step 5: Handle search and filtering - Ensure search works with minimal queries
- [x] Step 6: Test the app - Verify faster loading and accurate unread counts
- [x] Step 7: Handle edge cases - New chats, deleted messages, etc.
