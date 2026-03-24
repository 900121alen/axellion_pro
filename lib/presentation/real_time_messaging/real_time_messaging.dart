import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/contact_header_widget.dart';
import './widgets/image_preview_widget.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/message_date_separator_widget.dart';
import './widgets/message_input_widget.dart';
import './widgets/typing_indicator_widget.dart';

class RealTimeMessaging extends StatefulWidget {
  const RealTimeMessaging({super.key});

  @override
  State<RealTimeMessaging> createState() => _RealTimeMessagingState();
}

class _RealTimeMessagingState extends State<RealTimeMessaging> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final bool _isTyping = false;
  bool _isLoadingHistory = true;
  bool _showScrollToBottom = false;
  bool _showImagePreview = false;
  String _previewImageUrl = '';
  Map<String, dynamic>? _replyMessage;
  Timer? _typingTimer;
  final int _currentNavIndex = 2;

  late final String _currentUserId;

  String? _requestId;
  String _serviceTitle = 'Messages';

  // Resolved dynamically from requests table
  String? _participantId;

  String _participantName = '';
  bool _participantIsOnline = false;
  DateTime? _participantLastSeen;

  // Service scheduling
  DateTime? _serviceTime;
  DateTime? _serviceTimeEnd;
  String _scheduleStatus = 'pending';

  final Map<String, dynamic> _conversationInfo = {
    'participantName': '',
    'serviceTitle': 'Messages',
  };

  final List<Map<String, dynamic>> _messages = [];

  RealtimeChannel? _messagesChannel;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRouteArguments();
    });
    _scrollController.addListener(_onScroll);
  }

  void _loadRouteArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      setState(() {
        _requestId = args['request_id'] as String?;
        _serviceTitle = args['service_title'] as String? ?? 'Messages';
        _conversationInfo['serviceTitle'] = _serviceTitle;
      });
      _resolveParticipant();
      if (_requestId != null) {
        _initializeChat();
        _subscribeToMessages();
      } else {
        setState(() => _isLoadingHistory = false);
      }
    } else {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _resolveParticipant() async {
    if (_requestId == null || _currentUserId.isEmpty) return;
    try {
      final response = await Supabase.instance.client
          .from('requests')
          .select(
            'client_id, assigned_master_id, service_time, service_time_end, schedule_status',
          )
          .eq('id', _requestId!)
          .maybeSingle();
      if (response == null) return;
      final clientId = response['client_id'] as String?;
      final masterId = response['assigned_master_id'] as String?;
      final resolvedParticipantId = _currentUserId == clientId
          ? masterId
          : clientId;

      // Parse service_time if present
      final serviceTimeStr = response['service_time'] as String?;
      final serviceTimeEndStr = response['service_time_end'] as String?;
      final scheduleStatusStr =
          (response['schedule_status'] as String?) ?? 'pending';
      if (serviceTimeStr != null) {
        final parsed = DateTime.tryParse(serviceTimeStr)?.toLocal();
        final parsedEnd = serviceTimeEndStr != null
            ? DateTime.tryParse(serviceTimeEndStr)?.toLocal()
            : null;
        if (mounted) {
          setState(() {
            _serviceTime = parsed;
            _serviceTimeEnd = parsedEnd;
            _scheduleStatus = scheduleStatusStr;
          });
        }
      }

      if (resolvedParticipantId != null && resolvedParticipantId.isNotEmpty) {
        setState(() => _participantId = resolvedParticipantId);
        await _fetchParticipantName();
      }
    } catch (_) {}
  }

  Future<void> _fetchParticipantName() async {
    if (_participantId == null || _participantId!.isEmpty) return;
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('name, is_online, last_seen')
          .eq('id', _participantId!)
          .maybeSingle();
      final name = (response?['name'] as String?) ?? '';
      final isOnline = (response?['is_online'] as bool?) ?? false;
      final lastSeenString = response?['last_seen'] as String?;
      final lastSeen = lastSeenString != null
          ? DateTime.tryParse(lastSeenString)
          : null;
      if (mounted && name.isNotEmpty) {
        setState(() {
          _participantName = name;
          _participantIsOnline = isOnline;
          _participantLastSeen = lastSeen;
          _conversationInfo['participantName'] = name;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchMessages() async {
    if (_requestId == null) return;
    setState(() => _isLoadingHistory = true);
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select(
            'id, request_id, sender_id, receiver_id, message_text, created_at, message_type, schedule_start, schedule_end',
          )
          .eq('request_id', _requestId!)
          .order('created_at', ascending: true);

      final rows = List<Map<String, dynamic>>.from(response);
      final List<Map<String, dynamic>> loaded = rows.map((row) {
        final createdAt =
            DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
            DateTime.now();
        final msgType = (row['message_type'] as String?) ?? 'text';
        final schedStartStr = row['schedule_start'] as String?;
        final schedEndStr = row['schedule_end'] as String?;
        final schedStart = schedStartStr != null
            ? DateTime.tryParse(schedStartStr)?.toLocal()
            : null;
        final schedEnd = schedEndStr != null
            ? DateTime.tryParse(schedEndStr)?.toLocal()
            : null;
        return {
          'id': row['id'] as String? ?? '',
          'request_id': row['request_id'] as String? ?? _requestId ?? '',
          'sender_id': row['sender_id'] as String? ?? '',
          'receiver_id': row['receiver_id'] as String? ?? '',
          'message_type': msgType,
          'type': _mapDbMessageType(msgType),
          'text': row['message_text'] as String? ?? '',
          'time': _formatTime(createdAt),
          'date': _formatDate(createdAt),
          'createdAt': row['created_at'] as String? ?? '',
          'status': 'read',
          'isActive': true,
          if (schedStart != null) 'scheduleStart': schedStart,
          if (schedEnd != null) 'scheduleEnd': schedEnd,
        };
      }).toList();

      // Mark all proposal messages as inactive except the latest one,
      // and deactivate any proposal that has a schedule_confirmed after it.
      _markOnlyLatestProposalActive(loaded);

      if (mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(loaded);
          _isLoadingHistory = false;
        });
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToBottom(animated: false),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  /// Marks all schedule_proposal messages as inactive except the last one.
  /// Additionally, if a schedule_confirmed message exists AFTER a proposal
  /// (higher index = later in time), that proposal is also marked inactive.
  void _markOnlyLatestProposalActive(List<Map<String, dynamic>> msgs) {
    // Find the index of the last proposal
    int lastProposalIndex = -1;
    for (int i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i]['type'] == 'system_schedule_proposal') {
        lastProposalIndex = i;
        break;
      }
    }

    // Check if a schedule_confirmed exists after the last proposal
    bool hasConfirmedAfterLastProposal = false;
    if (lastProposalIndex >= 0) {
      for (int i = lastProposalIndex + 1; i < msgs.length; i++) {
        if (msgs[i]['type'] == 'system_schedule_confirmed') {
          hasConfirmedAfterLastProposal = true;
          break;
        }
      }
    }

    for (int i = 0; i < msgs.length; i++) {
      if (msgs[i]['type'] == 'system_schedule_proposal') {
        // A proposal is active only if it is the latest AND no confirmation follows it
        final isLatest = (i == lastProposalIndex);
        final isActive = isLatest && !hasConfirmedAfterLastProposal;
        msgs[i] = Map<String, dynamic>.from(msgs[i])..['isActive'] = isActive;
      }
    }
  }

  /// Disables all existing proposal messages in _messages (called before adding a new one).
  void _disableOldProposals() {
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i]['type'] == 'system_schedule_proposal') {
        _messages[i] = Map<String, dynamic>.from(_messages[i])
          ..['isActive'] = false;
      }
    }
  }

  String _mapDbMessageType(String dbType) {
    switch (dbType) {
      case 'schedule_proposal':
        return 'system_schedule_proposal';
      case 'schedule_confirmed':
        return 'system_schedule_confirmed';
      case 'schedule_declined':
        return 'system_schedule_declined';
      default:
        return 'text';
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_requestId == null || _currentUserId.isEmpty) return;
    try {
      await Supabase.instance.client
          .from('messages')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('request_id', _requestId!)
          .eq('receiver_id', _currentUserId)
          .isFilter('read_at', null);
    } catch (_) {}
  }

  Future<void> _initializeChat() async {
    await _fetchMessages();
    await _markMessagesAsRead();
  }

  void _subscribeToMessages() {
    if (_requestId == null) return;
    _messagesChannel = Supabase.instance.client
        .channel('messages:$_requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'request_id',
            value: _requestId!,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            final senderId = row['sender_id'] as String? ?? '';
            if (senderId == _currentUserId) return;
            final createdAt =
                DateTime.tryParse(
                  row['created_at'] as String? ?? '',
                )?.toLocal() ??
                DateTime.now();
            final msgType = (row['message_type'] as String?) ?? 'text';
            final schedStartStr = row['schedule_start'] as String?;
            final schedEndStr = row['schedule_end'] as String?;
            final schedStart = schedStartStr != null
                ? DateTime.tryParse(schedStartStr)?.toLocal()
                : null;
            final schedEnd = schedEndStr != null
                ? DateTime.tryParse(schedEndStr)?.toLocal()
                : null;
            final newMsg = {
              'id': row['id'] as String? ?? '',
              'request_id': row['request_id'] as String? ?? _requestId ?? '',
              'sender_id': senderId,
              'receiver_id': row['receiver_id'] as String? ?? '',
              'message_type': msgType,
              'type': _mapDbMessageType(msgType),
              'text': row['message_text'] as String? ?? '',
              'time': _formatTime(createdAt),
              'date': _formatDate(createdAt),
              'createdAt': row['created_at'] as String? ?? '',
              'status': 'read',
              'isActive': true,
              if (schedStart != null) 'scheduleStart': schedStart,
              if (schedEnd != null) 'scheduleEnd': schedEnd,
            };
            if (mounted) {
              setState(() {
                // New proposal: disable all previous proposals, new one is active
                if (msgType == 'schedule_proposal') {
                  _disableOldProposals();
                }
                // Confirmation received: disable all proposals (they are now superseded)
                if (msgType == 'schedule_confirmed') {
                  _disableOldProposals();
                  _scheduleStatus = 'confirmed';
                }
                _messages.add(newMsg);
              });
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToBottom(),
              );
              // Refresh request data on new proposal
              if (msgType == 'schedule_proposal') {
                _resolveParticipant();
              }
            }
          },
        )
        .subscribe();
  }

  void _onScroll() {
    final atBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80;
    if (atBottom != !_showScrollToBottom) {
      setState(() => _showScrollToBottom = !atBottom);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _navigateBack() async {
    if (mounted) Navigator.pop(context);
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    if (_requestId == null || _currentUserId.isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = {
      'id': tempId,
      'senderId': _currentUserId,
      'type': 'text',
      'text': text,
      'time': _formatTime(DateTime.now()),
      'date': _formatDate(DateTime.now()),
      'status': 'sent',
      if (_replyMessage != null) 'replyTo': _replyMessage,
    };

    setState(() {
      _messages.add(optimisticMsg);
      _replyMessage = null;
    });
    _inputController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      String? receiverId;
      try {
        final requestRow = await Supabase.instance.client
            .from('requests')
            .select('client_id, assigned_master_id')
            .eq('id', _requestId!)
            .maybeSingle();
        if (requestRow != null) {
          final clientId = requestRow['client_id'] as String?;
          final masterId = requestRow['assigned_master_id'] as String?;
          receiverId = _currentUserId == clientId ? masterId : clientId;
        }
      } catch (_) {}

      await Supabase.instance.client.from('messages').insert({
        'request_id': _requestId,
        'sender_id': _currentUserId,
        if (receiverId != null) 'receiver_id': receiverId,
        'message_text': text,
        'message_type': 'text',
      });
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) _messages[idx]['status'] = 'delivered';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m['id'] == tempId));
      }
    }
  }

  void _handleAttachment(String type, dynamic data) {
    if (type == 'image' && data is XFile) {
      final newMsg = {
        'id': 'temp_img_${DateTime.now().millisecondsSinceEpoch}',
        'senderId': _currentUserId,
        'type': 'image',
        'text': '',
        'imageUrl':
            'https://img.rocket.new/generatedImages/rocket_gen_img_13c7dac57-1772375054373.png',
        'imageLabel': 'Shared image from device gallery',
        'time': _formatTime(DateTime.now()),
        'date': _formatDate(DateTime.now()),
        'status': 'sent',
      };
      setState(() => _messages.add(newMsg));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else if (type == 'voice' && data is Map) {
      final newMsg = {
        'id': 'temp_voice_${DateTime.now().millisecondsSinceEpoch}',
        'senderId': _currentUserId,
        'type': 'voice',
        'text': '',
        'duration': data['duration'] ?? 0,
        'time': _formatTime(DateTime.now()),
        'date': _formatDate(DateTime.now()),
        'status': 'sent',
      };
      setState(() => _messages.add(newMsg));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _onTyping() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {});
  }

  void _onLongPressMessage(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 1.5.h),
                _MessageActionTile(
                  icon: 'reply',
                  label: 'Reply',
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _replyMessage = message);
                  },
                ),
                _MessageActionTile(
                  icon: 'content_copy',
                  label: 'Copy',
                  onTap: () => Navigator.pop(ctx),
                ),
                _MessageActionTile(
                  icon: 'delete_outline',
                  label: 'Delete',
                  color: AppTheme.errorLight,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(
                      () => _messages.removeWhere(
                        (m) => m['id'] == message['id'],
                      ),
                    );
                  },
                ),
                SizedBox(height: 1.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadMoreMessages() async {
    await _fetchMessages();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatScheduledLabel(DateTime dt, DateTime? end) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final startH = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final startM = dt.minute.toString().padLeft(2, '0');
    final startPeriod = dt.hour >= 12 ? 'PM' : 'AM';
    if (end != null) {
      final endH = end.hour > 12
          ? end.hour - 12
          : (end.hour == 0 ? 12 : end.hour);
      final endM = end.minute.toString().padLeft(2, '0');
      final endPeriod = end.hour >= 12 ? 'PM' : 'AM';
      return '$month $day • $startH:$startM $startPeriod – $endH:$endM $endPeriod';
    }
    return '$month $day • $startH:$startM $startPeriod';
  }

  // ── Service Time Picker Modal ──────────────────────────────────────────────

  void _openServiceTimePicker({bool isSuggestNew = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ServiceTimePickerSheet(
        initialDate: _serviceTime,
        initialEnd: _serviceTimeEnd,
        onConfirm: (start, end) {
          Navigator.pop(ctx);
          _saveServiceTime(start, end, isSuggestNew: isSuggestNew);
        },
      ),
    );
  }

  Future<void> _saveServiceTime(
    DateTime start,
    DateTime? end, {
    bool isSuggestNew = false,
  }) async {
    if (_requestId == null) return;
    try {
      await Supabase.instance.client
          .from('requests')
          .update({
            'service_time': start.toUtc().toIso8601String(),
            'service_time_end': end?.toUtc().toIso8601String(),
            'schedule_status': 'pending',
          })
          .eq('id', _requestId!);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _serviceTime = start;
        _serviceTimeEnd = end;
        _scheduleStatus = 'pending';
      });
      await _insertScheduleProposalMessage(
        start,
        end,
        isSuggestNew: isSuggestNew,
      );
    }
  }

  Future<void> _insertScheduleProposalMessage(
    DateTime start,
    DateTime? end, {
    bool isSuggestNew = false,
  }) async {
    if (_requestId == null) return;
    final senderName = await _getCurrentUserName();
    final msgText = isSuggestNew
        ? '$senderName suggested a new service time'
        : '$senderName proposed a service time';

    String? receiverId;
    try {
      final requestRow = await Supabase.instance.client
          .from('requests')
          .select('client_id, assigned_master_id')
          .eq('id', _requestId!)
          .maybeSingle();
      if (requestRow != null) {
        final clientId = requestRow['client_id'] as String?;
        final masterId = requestRow['assigned_master_id'] as String?;
        receiverId = _currentUserId == clientId ? masterId : clientId;
      }
    } catch (_) {}

    try {
      await Supabase.instance.client.from('messages').insert({
        'request_id': _requestId,
        'sender_id': _currentUserId,
        if (receiverId != null) 'receiver_id': receiverId,
        'message_text': msgText,
        'message_type': 'schedule_proposal',
        'schedule_start': start.toUtc().toIso8601String(),
        if (end != null) 'schedule_end': end.toUtc().toIso8601String(),
      });
    } catch (_) {}

    // Optimistic local insert — disable old proposals first
    final localMsg = {
      'id': 'sys_sched_${DateTime.now().millisecondsSinceEpoch}',
      'sender_id': _currentUserId,
      'receiver_id': receiverId ?? '',
      'request_id': _requestId ?? '',
      'message_type': 'schedule_proposal',
      'type': 'system_schedule_proposal',
      'text': msgText,
      'time': _formatTime(DateTime.now()),
      'date': _formatDate(DateTime.now()),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'status': 'read',
      'isActive': true,
      'scheduleStart': start,
      'scheduleEnd': end,
    };
    if (mounted) {
      setState(() {
        _disableOldProposals();
        _messages.add(localMsg);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<String> _getCurrentUserName() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', _currentUserId)
          .maybeSingle();
      return (response?['name'] as String?) ?? 'Someone';
    } catch (_) {
      return 'Someone';
    }
  }

  Future<void> _acceptSchedule(Map<String, dynamic> message) async {
    try {
      final msgRequestId =
          (message['request_id'] as String?)?.isNotEmpty == true
          ? message['request_id'] as String
          : _requestId;

      if (msgRequestId == null) return;

      final senderId = message['sender_id'] as String?;

      final receiverId = senderId != null && senderId.isNotEmpty
          ? senderId
          : (message['receiver_id'] as String?);

      if (receiverId == null || receiverId.isEmpty) return;

      final currentUserName = await _getCurrentUserName();

      // 1. Insert confirmation message

      await Supabase.instance.client.from('messages').insert({
        'request_id': msgRequestId,

        'sender_id': _currentUserId,

        'receiver_id': receiverId,

        'message_text': '$currentUserName accepted the scheduled time',

        'message_type': 'schedule_confirmed',

        if (message['scheduleStart'] != null)
          'schedule_start': (message['scheduleStart'] as DateTime)
              .toUtc()
              .toIso8601String(),
      });

      // 2. Update ONLY schedule_status to avoid constraint errors

      await Supabase.instance.client
          .from('requests')
          .update({'schedule_status': 'confirmed'})
          .eq('id', msgRequestId);

      await _fetchMessages();

      if (mounted) {
        setState(() => _scheduleStatus = 'confirmed');

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DB Error: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showImageFullScreen(String url) {
    setState(() {
      _previewImageUrl = url;
      _showImagePreview = true;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _messagesChannel?.unsubscribe();
    super.dispose();
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
        title: Text(_serviceTitle),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark
            ? AppTheme.backgroundDark
            : AppTheme.backgroundLight,
        foregroundColor: isDark ? Colors.white : Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.zero,
                  child: ContactHeaderWidget(
                    participantName: _participantName,
                    isOnline: _participantIsOnline,
                    lastSeen: _participantLastSeen,
                    isTyping: _isTyping,
                    onBackPressed: _navigateBack,
                    onCalendarTap: _openServiceTimePicker,
                    serviceTime: _serviceTime,
                    serviceTimeEnd: _serviceTimeEnd,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadMoreMessages,
                    color: AppTheme.primaryLight,
                    child: _isLoadingHistory
                        ? _buildSkeletonLoader(theme, isDark)
                        : _messages.isEmpty && _serviceTime == null
                        ? _buildEmptyStateWithScheduleCard(theme, isDark)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.h,
                            ),
                            itemCount:
                                _messages.length +
                                (_isTyping ? 1 : 0) +
                                (_serviceTime == null ? 1 : 0) +
                                1,
                            itemBuilder: (ctx, index) {
                              // First item: schedule card or scheduled info
                              if (index == 0) {
                                return _serviceTime == null
                                    ? _buildScheduleCard(theme, isDark)
                                    : _buildScheduledInfoCard(theme, isDark);
                              }
                              final msgIndex = index - 1;
                              if (_isTyping && msgIndex == _messages.length) {
                                return const TypingIndicatorWidget();
                              }
                              if (msgIndex >= _messages.length) {
                                return const SizedBox.shrink();
                              }
                              final msg = _messages[msgIndex];
                              final msgType =
                                  (msg['type'] as String?) ?? 'text';

                              // System schedule proposal message
                              if (msgType == 'system_schedule_proposal') {
                                final showDate =
                                    msgIndex == 0 ||
                                    (msg['date'] as String?) !=
                                        (_messages[msgIndex - 1]['date']
                                            as String?);
                                final schedStart =
                                    msg['scheduleStart'] as DateTime?;
                                final schedEnd =
                                    msg['scheduleEnd'] as DateTime?;
                                final isFromMe =
                                    (msg['senderId'] as String?) ==
                                    _currentUserId;
                                final isActive =
                                    (msg['isActive'] as bool?) ?? false;
                                final msgReceiverId =
                                    (msg['receiver_id'] as String?) ?? '';
                                return Column(
                                  children: [
                                    if (showDate)
                                      MessageDateSeparatorWidget(
                                        date: (msg['date'] as String?) ?? '',
                                      ),
                                    _buildScheduleProposalCard(
                                      theme,
                                      isDark,
                                      msg['text'] as String? ?? '',
                                      schedStart,
                                      schedEnd,
                                      isFromMe,
                                      isActive,
                                      msgReceiverId,
                                      msg,
                                    ),
                                  ],
                                );
                              }

                              // System schedule confirmed message
                              if (msgType == 'system_schedule_confirmed') {
                                final showDate =
                                    msgIndex == 0 ||
                                    (msg['date'] as String?) !=
                                        (_messages[msgIndex - 1]['date']
                                            as String?);
                                final schedStart =
                                    msg['scheduleStart'] as DateTime?;
                                final schedEnd =
                                    msg['scheduleEnd'] as DateTime?;
                                return Column(
                                  children: [
                                    if (showDate)
                                      MessageDateSeparatorWidget(
                                        date: (msg['date'] as String?) ?? '',
                                      ),
                                    _buildScheduleConfirmedCard(
                                      theme,
                                      isDark,
                                      msg['text'] as String? ?? '',
                                      schedStart,
                                      schedEnd,
                                    ),
                                  ],
                                );
                              }

                              final isSender =
                                  (msg['senderId'] as String?) ==
                                  _currentUserId;
                              final showDate =
                                  msgIndex == 0 ||
                                  (msg['date'] as String?) !=
                                      (_messages[msgIndex - 1]['date']
                                          as String?);

                              return Column(
                                children: [
                                  if (showDate)
                                    MessageDateSeparatorWidget(
                                      date: (msg['date'] as String?) ?? '',
                                    ),
                                  Slidable(
                                    key: ValueKey(msg['id']),
                                    startActionPane: isSender
                                        ? null
                                        : ActionPane(
                                            motion: const DrawerMotion(),
                                            extentRatio: 0.2,
                                            children: [
                                              SlidableAction(
                                                onPressed: (_) => setState(
                                                  () => _replyMessage = msg,
                                                ),
                                                backgroundColor:
                                                    AppTheme.secondaryLight,
                                                foregroundColor: Colors.white,
                                                icon: Icons.reply,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ],
                                          ),
                                    endActionPane: isSender
                                        ? ActionPane(
                                            motion: const DrawerMotion(),
                                            extentRatio: 0.2,
                                            children: [
                                              SlidableAction(
                                                onPressed: (_) => setState(
                                                  () => _replyMessage = msg,
                                                ),
                                                backgroundColor:
                                                    AppTheme.secondaryLight,
                                                foregroundColor: Colors.white,
                                                icon: Icons.reply,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: GestureDetector(
                                      onTap: () {
                                        if ((msg['type'] as String?) ==
                                            'image') {
                                          final url =
                                              (msg['imageUrl'] as String?) ??
                                              '';
                                          if (url.isNotEmpty) {
                                            _showImageFullScreen(url);
                                          }
                                        }
                                      },
                                      child: MessageBubbleWidget(
                                        message: msg,
                                        isSender: isSender,
                                        onLongPress: () =>
                                            _onLongPressMessage(msg),
                                        replyMessage: msg['replyTo'] != null
                                            ? (msg['replyTo']
                                                  as Map<String, dynamic>)
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
                MessageInputWidget(
                  controller: _inputController,
                  onSend: _sendMessage,
                  onAttachment: _handleAttachment,
                  onTyping: _onTyping,
                  replyMessage: _replyMessage,
                  onCancelReply: () => setState(() => _replyMessage = null),
                ),
              ],
            ),
            if (_showScrollToBottom)
              Positioned(
                bottom: 14.h,
                right: 4.w,
                child: GestureDetector(
                  onTap: () => _scrollToBottom(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.floatingShadow,
                    ),
                    child: CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            if (_showImagePreview)
              Positioned.fill(
                child: ImagePreviewWidget(
                  imageUrl: _previewImageUrl,
                  onClose: () => setState(() => _showImagePreview = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Schedule Card (no service_time yet) ───────────────────────────────────
  Widget _buildScheduleCard(ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: AppTheme.primaryLight,
                size: 18,
              ),
              SizedBox(width: 2.w),
              Text(
                'Schedule Service Time',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          Text(
            'Choose a date and time for the service.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.textMediumEmphasisDark
                  : AppTheme.textMediumEmphasisLight,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openServiceTimePicker,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 0,
              ),
              child: Text(
                'Schedule Service Time',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Scheduled Info Card (service_time exists) ─────────────────────────────
  Widget _buildScheduledInfoCard(ThemeData theme, bool isDark) {
    final label = _formatScheduledLabel(_serviceTime!, _serviceTimeEnd);
    final isConfirmed = _scheduleStatus == 'confirmed';
    // Only the non-confirmer (proposal sender) can reschedule after confirmation.
    // Before confirmation, anyone can reschedule.
    // We determine role: if _participantId is set, current user is either client or master.
    // Allow reschedule only if not yet confirmed, or if confirmed and current user is the proposer.
    final canReschedule = !isConfirmed;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.successLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: AppTheme.successLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConfirmed ? Icons.check_circle : Icons.check_circle_outline,
                color: AppTheme.successLight,
                size: 18,
              ),
              SizedBox(width: 2.w),
              Text(
                isConfirmed ? 'Service Confirmed' : 'Service Scheduled',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successLight,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.textHighEmphasisDark
                  : AppTheme.textHighEmphasisLight,
              fontSize: 12.sp,
            ),
          ),
          if (canReschedule) ...[
            SizedBox(height: 1.2.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openServiceTimePicker,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryLight,
                  side: BorderSide(
                    color: AppTheme.primaryLight.withValues(alpha: 0.5),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  'Reschedule',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Schedule Proposal Card (in message list) ──────────────────────────────
  Widget _buildScheduleProposalCard(
    ThemeData theme,
    bool isDark,
    String headerText,
    DateTime? schedStart,
    DateTime? schedEnd,
    bool isFromMe,
    bool isActive,
    String receiverId,
    Map<String, dynamic> message,
  ) {
    final timeLabel = schedStart != null
        ? _formatScheduledLabel(schedStart, schedEnd)
        : '';

    // Receiver detection: the receiver is whoever did NOT send this message.
    // Use sender_id field directly for deterministic comparison.
    final senderId = message['sender_id'] as String?;
    final isReceiver = senderId != null && senderId != _currentUserId;

    // Show Accept/Suggest New Time buttons ONLY for the receiver of the latest active proposal
    final showActions = isReceiver && isActive;

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: AppTheme.successLight.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month,
                  color: AppTheme.successLight,
                  size: 16,
                ),
                SizedBox(width: 1.5.w),
                Flexible(
                  child: Text(
                    headerText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.textHighEmphasisLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
            if (timeLabel.isNotEmpty) ...[
              SizedBox(height: 0.8.h),
              Text(
                timeLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.textHighEmphasisDark
                      : AppTheme.textHighEmphasisLight,
                  fontSize: 12.sp,
                ),
              ),
            ],
            if (showActions) ...[
              SizedBox(height: 1.2.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptSchedule(message),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successLight,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Accept',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _openServiceTimePicker(isSuggestNew: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryLight,
                        side: BorderSide(
                          color: AppTheme.primaryLight.withValues(alpha: 0.6),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Suggest New Time',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Schedule Confirmed Card (in message list) ─────────────────────────────
  Widget _buildScheduleConfirmedCard(
    ThemeData theme,
    bool isDark,
    String headerText,
    DateTime? schedStart,
    DateTime? schedEnd,
  ) {
    final timeLabel = schedStart != null
        ? _formatScheduledLabel(schedStart, schedEnd)
        : '';
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: AppTheme.successLight.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: AppTheme.successLight.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successLight,
                  size: 16,
                ),
                SizedBox(width: 1.5.w),
                Flexible(
                  child: Text(
                    headerText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.successLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
            if (timeLabel.isNotEmpty) ...[
              SizedBox(height: 0.8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
                decoration: BoxDecoration(
                  color: AppTheme.successLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 13,
                      color: AppTheme.successLight,
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      timeLabel,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.textHighEmphasisDark
                            : AppTheme.textHighEmphasisLight,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Empty state with schedule card ────────────────────────────────────────
  Widget _buildEmptyStateWithScheduleCard(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: _buildScheduleCard(theme, isDark),
          ),
          SizedBox(height: 4.h),
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: isDark
                ? AppTheme.textMediumEmphasisDark
                : AppTheme.textMediumEmphasisLight,
          ),
          SizedBox(height: 2.h),
          Text(
            'No messages yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start the conversation below',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.textMediumEmphasisDark
                  : AppTheme.textMediumEmphasisLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme, bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      itemCount: 6,
      itemBuilder: (_, index) {
        final isRight = index % 2 == 0;
        return Align(
          alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 0.6.h),
            width: (30 + (index % 3) * 15).toDouble().w,
            height: 5.h,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
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
            'No messages yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start the conversation below',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.textMediumEmphasisDark
                  : AppTheme.textMediumEmphasisLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Service Time Picker Sheet ─────────────────────────────────────────────────

class _ServiceTimePickerSheet extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? initialEnd;
  final void Function(DateTime start, DateTime? end) onConfirm;

  const _ServiceTimePickerSheet({
    required this.onConfirm,
    this.initialDate,
    this.initialEnd,
  });

  @override
  State<_ServiceTimePickerSheet> createState() =>
      _ServiceTimePickerSheetState();
}

class _ServiceTimePickerSheetState extends State<_ServiceTimePickerSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  TimeOfDay? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = widget.initialDate ?? now;
    _selectedTime = widget.initialDate != null
        ? TimeOfDay.fromDateTime(widget.initialDate!)
        : TimeOfDay(hour: now.hour, minute: 0);
    _selectedEndTime = widget.initialEnd != null
        ? TimeOfDay.fromDateTime(widget.initialEnd!)
        : null;
  }

  String _formatDateLabel(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTimeLabel(TimeOfDay t) {
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.primaryLight,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.primaryLight,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _selectedEndTime ??
          TimeOfDay(
            hour: (_selectedTime.hour + 2) % 24,
            minute: _selectedTime.minute,
          ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.primaryLight,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedEndTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 5.w,
        right: 5.w,
        top: 2.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 3.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Schedule Service',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 2.h),

          // Date
          Text(
            'Date',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.textMediumEmphasisDark
                  : AppTheme.textMediumEmphasisLight,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 0.8.h),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.backgroundDark
                    : AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppTheme.primaryLight,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      _formatDateLabel(_selectedDate),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: isDark
                        ? AppTheme.textMediumEmphasisDark
                        : AppTheme.textMediumEmphasisLight,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.5.h),

          // Start Time
          Text(
            'Time',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.textMediumEmphasisDark
                  : AppTheme.textMediumEmphasisLight,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 0.8.h),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.backgroundDark
                    : AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 18,
                    color: AppTheme.primaryLight,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      _formatTimeLabel(_selectedTime),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: isDark
                        ? AppTheme.textMediumEmphasisDark
                        : AppTheme.textMediumEmphasisLight,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.5.h),

          // End Time (Duration / Time Window)
          Text(
            'Duration / Time Window (optional)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.textMediumEmphasisDark
                  : AppTheme.textMediumEmphasisLight,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 0.8.h),
          GestureDetector(
            onTap: _pickEndTime,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.backgroundDark
                    : AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: _selectedEndTime != null
                        ? AppTheme.primaryLight
                        : (isDark
                              ? AppTheme.textMediumEmphasisDark
                              : AppTheme.textMediumEmphasisLight),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      _selectedEndTime != null
                          ? _formatTimeLabel(_selectedEndTime!)
                          : 'Tap to set end time',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                        color: _selectedEndTime != null
                            ? null
                            : (isDark
                                  ? AppTheme.textMediumEmphasisDark
                                  : AppTheme.textMediumEmphasisLight),
                      ),
                    ),
                  ),
                  if (_selectedEndTime != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedEndTime = null),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: isDark
                            ? AppTheme.textMediumEmphasisDark
                            : AppTheme.textMediumEmphasisLight,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: isDark
                          ? AppTheme.textMediumEmphasisDark
                          : AppTheme.textMediumEmphasisLight,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppTheme.textHighEmphasisDark
                        : AppTheme.textHighEmphasisLight,
                    side: BorderSide(
                      color: isDark
                          ? AppTheme.dividerDark
                          : AppTheme.borderLight,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    final start = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );
                    DateTime? end;
                    if (_selectedEndTime != null) {
                      end = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _selectedEndTime!.hour,
                        _selectedEndTime!.minute,
                      );
                    }
                    widget.onConfirm(start, end);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm Time',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageActionTile extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MessageActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileColor = color ?? theme.colorScheme.onSurface;
    return ListTile(
      leading: CustomIconWidget(iconName: icon, color: tileColor, size: 22),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: tileColor),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
