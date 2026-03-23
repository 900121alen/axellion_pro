import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

class ClientMessagesScreen extends StatefulWidget {
  const ClientMessagesScreen({super.key});

  @override
  State<ClientMessagesScreen> createState() => _ClientMessagesScreenState();
}

class _ClientMessagesScreenState extends State<ClientMessagesScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'Not authenticated. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      // Fetch client's requests with category name and assigned master info
      final requestsResponse = await Supabase.instance.client
          .from('requests')
          .select(
            'id, description, status, created_at, assigned_master_id, categories(name)',
          )
          .eq('client_id', userId)
          .not('assigned_master_id', 'is', null);

      final requests = List<Map<String, dynamic>>.from(requestsResponse);

      // Collect all master IDs to batch-fetch names
      final masterIds = requests
          .map((r) => r['assigned_master_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<String, String> masterNames = {};
      if (masterIds.isNotEmpty) {
        try {
          final usersResponse = await Supabase.instance.client
              .from('users')
              .select('id, name')
              .inFilter('id', masterIds);
          for (final u in List<Map<String, dynamic>>.from(usersResponse)) {
            masterNames[u['id'] as String] = u['name'] as String? ?? 'Master';
          }
        } catch (_) {}
      }

      final List<Map<String, dynamic>> conversations = [];

      for (final request in requests) {
        final requestId = request['id'] as String?;
        if (requestId == null) continue;

        final masterId = request['assigned_master_id'] as String?;
        final masterName = masterId != null
            ? (masterNames[masterId] ?? 'Master')
            : null;

        final categoryName =
            (request['categories'] as Map<String, dynamic>?)?['name']
                as String? ??
            'Service Request';

        Map<String, dynamic>? lastMessage;
        int unreadCount = 0;

        try {
          // Fetch last message from messages table, sorted by created_at DESC
          final messagesResponse = await Supabase.instance.client
              .from('messages')
              .select('message_text, created_at, sender_id')
              .eq('request_id', requestId)
              .order('created_at', ascending: false)
              .limit(1);

          final msgs = List<Map<String, dynamic>>.from(messagesResponse);
          if (msgs.isNotEmpty) {
            lastMessage = msgs.first;
          }

          // Count unread: messages where receiver_id = currentUserId AND read_at IS NULL
          final unreadResponse = await Supabase.instance.client
              .from('messages')
              .select('id')
              .eq('request_id', requestId)
              .eq('receiver_id', userId)
              .isFilter('read_at', null);

          unreadCount = List<Map<String, dynamic>>.from(unreadResponse).length;
        } catch (_) {}

        final lastMessageText = lastMessage?['message_text'] as String?;
        // Use last message timestamp for sorting; fall back to request created_at
        final lastMessageTimestamp =
            lastMessage?['created_at'] as String? ??
            request['created_at'] as String?;

        conversations.add({
          'request_id': requestId,
          'service_title': categoryName,
          'master_name': masterName,
          'last_message': lastMessageText,
          'timestamp': lastMessageTimestamp,
          'unread_count': unreadCount,
          'has_messages': lastMessage != null,
        });
      }

      // Sort by most recent message timestamp (newest first)
      conversations.sort((a, b) {
        final aTs = a['timestamp'] as String?;
        final bTs = b['timestamp'] as String?;
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load conversations. Pull to refresh.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final m = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '$h:$m $period';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dt.weekday - 1];
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {
      return '';
    }
  }

  Widget _buildSkeletonLoader(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 55.w,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 0.8.h),
                    Container(
                      height: 12,
                      width: 38.w,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 2.h),
          Text(
            _error ?? 'An error occurred',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: _fetchConversations,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: isDark
                ? AppTheme.textMediumEmphasisDark
                : AppTheme.textMediumEmphasisLight,
          ),
          SizedBox(height: 2.h),
          Text(
            'No conversations yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Chats will appear here once a master accepts your request.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.textMediumEmphasisDark
                  : AppTheme.textMediumEmphasisLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark
            ? AppTheme.backgroundDark
            : AppTheme.backgroundLight,
        foregroundColor: isDark ? Colors.white : Colors.black,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.clientHome);
          },
        ),
      ),
      body: _isLoading
          ? _buildSkeletonLoader(isDark)
          : _error != null
          ? _buildErrorState(theme)
          : _conversations.isEmpty
          ? _buildEmptyState(theme, isDark)
          : RefreshIndicator(
              onRefresh: _fetchConversations,
              color: AppTheme.primaryLight,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conv = _conversations[index];
                  final unreadCount = conv['unread_count'] as int? ?? 0;
                  final hasUnread = unreadCount > 0;
                  final hasMessages = conv['has_messages'] as bool? ?? false;
                  final lastMessageText = conv['last_message'] as String?;
                  final masterName = conv['master_name'] as String?;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _ConversationTile(
                      masterName: masterName,
                      serviceTitle:
                          conv['service_title'] as String? ?? 'Service Request',
                      lastMessage: hasMessages
                          ? (lastMessageText ?? 'Start conversation')
                          : 'Start conversation',
                      timestamp: _formatTimestamp(conv['timestamp'] as String?),
                      hasUnread: hasUnread,
                      unreadCount: unreadCount,
                      isDark: isDark,
                      onTap: () async {
                        await Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed(
                          AppRoutes.realTimeMessaging,
                          arguments: {
                            'request_id': conv['request_id'],
                            'service_title': conv['service_title'],
                          },
                        );
                        // Refresh conversations after returning so read state is updated
                        _fetchConversations();
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String? masterName;
  final String serviceTitle;
  final String lastMessage;
  final String timestamp;
  final bool hasUnread;
  final int unreadCount;
  final bool isDark;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.masterName,
    required this.serviceTitle,
    required this.lastMessage,
    required this.timestamp,
    required this.hasUnread,
    required this.unreadCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const avatarBg = Color(0xFFDCEEFB);
    const avatarLetterColor = Color(0xFF1A73E8);
    const masterNameColor = Color(0xFF1A1A2E);
    const badgeBg = Color(0xFFF0F4FF);
    const badgeTextColor = Color(0xFF6B7280);
    const unreadTileBg = Color(0xFFEEF4FF);
    const unreadBadgeBg = Color(0xFF1A73E8);
    const unreadTimestampColor = Color(0xFF1A73E8);

    final tileBackground = hasUnread
        ? (isDark ? const Color(0xFF1A2540) : unreadTileBg)
        : (isDark ? const Color(0xFF1E1E2E) : Colors.white);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: tileBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    masterName != null && masterName!.isNotEmpty
                        ? masterName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: avatarLetterColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Master name + timestamp
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            masterName ?? 'Master',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : masterNameColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timestamp,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? unreadTimestampColor
                                : Colors.grey[500],
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Row 2: Service badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A3550) : badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        serviceTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: isDark
                              ? const Color(0xFF9BAAC8)
                              : badgeTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Row 3: Last message + unread badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: unreadBadgeBg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
