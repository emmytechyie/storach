import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Your ChatMessage class is perfect, no changes needed.
class ChatMessage {
  final String id;
  final String? text;
  final DateTime timestamp;
  final bool isSentByMe;
  final String senderName;
  final String? fileUrl;
  final String fileType;
  final String? fileName;
  final Map<String, dynamic> rawData;

  ChatMessage({
    required this.id,
    this.text,
    required this.timestamp,
    required this.isSentByMe,
    required this.senderName,
    required this.rawData,
    this.fileUrl,
    required this.fileType,
    this.fileName,
  });
}

class ChatroomScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String supervisorName;
  final bool isSupervisorView;

  // ✅ FIXED and cleaned up constructor
  const ChatroomScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.supervisorName,
    required this.isSupervisorView,
    required String supervisorInitial,
    required String chatPartnerName,
    required String supervisorId,
    required String,
  });

  @override
  State<ChatroomScreen> createState() => _ChatroomScreenState();
}

class _ChatroomScreenState extends State<ChatroomScreen> {
  // --- UI Constants ---
  static const Color darkScaffoldBackground = Color(0xFF121B22);
  static const Color appBarColor = Color(0xFF202C33);
  static const Color inputAreaColor = Color(0xFF202C33);
  static const Color sentMessageColor = Color(0xFF005C4B);
  static const Color receivedMessageColor = Color(0xFF202C33);
  static const Color primaryTextColor = Colors.white;
  static const Color secondaryTextColor = Color(0xFFB0B3B8);
  static const Color iconColor = Color(0xFFB0B3B8);
  static const Color accentColor = Color(0xFF00A884);

  // --- State Variables ---
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _otherUserId;
  String? _otherUserName;
  final String _myUserId = Supabase.instance.client.auth.currentUser!.id;

  bool _isLoading = true;
  bool _isSending = false; // This now covers both text and file sending
  RealtimeChannel? _messageChannel;

  // ✅ NEW: State variable to hold the selected file before sending
  File? _stagedFile;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(
            const Duration(milliseconds: 300), () => _scrollToStart());
      }
    });
  }

  @override
  void dispose() {
    if (_messageChannel != null) {
      Supabase.instance.client.removeChannel(_messageChannel!);
    }
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- Core Logic ---

  Future<void> _initializeChat() async {
    // This logic remains the same
    final supabase = Supabase.instance.client;
    if (widget.isSupervisorView) {
      _otherUserId = widget.studentId;
      _otherUserName = widget.studentName;
    } else {
      try {
        final assignment = await supabase
            .from('supervisor_assignments')
            .select('supervisor_id')
            .eq('student_id', _myUserId)
            .maybeSingle();
        if (assignment == null || assignment['supervisor_id'] == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        _otherUserId = assignment['supervisor_id'];
        _otherUserName = widget.supervisorName;
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }
    if (_otherUserId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final response = await supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.$_myUserId,receiver_id.eq.$_otherUserId),and(sender_id.eq.$_otherUserId,receiver_id.eq.$_myUserId)')
          .order('created_at', ascending: true);

      final messages =
          (response as List).map((msg) => _mapToChatMessage(msg)).toList();

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToStart(isAnimated: false);
        });
      }

      _setupRealtimeListener();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeListener() {
    // This logic remains the same
    if (_otherUserId == null) return;
    _messageChannel = Supabase.instance.client
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newMsg = payload.newRecord;
            final sender = newMsg['sender_id'];
            final receiver = newMsg['receiver_id'];
            bool belongsToThisChat =
                (sender == _myUserId && receiver == _otherUserId) ||
                    (sender == _otherUserId && receiver == _myUserId);
            if (belongsToThisChat) {
              final message = _mapToChatMessage(newMsg);
              if (mounted && !_messages.any((m) => m.id == message.id)) {
                setState(() => _messages.add(message));
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToStart();
                });
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final oldMsg = payload.oldRecord;
            final deletedMessageId = oldMsg['id'].toString();
            if (mounted) {
              setState(() {
                _messages.removeWhere((msg) => msg.id == deletedMessageId);
              });
            }
          },
        )
        .subscribe();
  }

  ChatMessage _mapToChatMessage(Map<String, dynamic> msg) {
    // This logic remains the same
    final isMe = msg['sender_id'] == _myUserId;
    return ChatMessage(
      id: msg['id'].toString(),
      text: msg['message'],
      timestamp: DateTime.parse(msg['created_at']),
      isSentByMe: isMe,
      senderName: isMe ? 'You' : (_otherUserName ?? 'Other'),
      rawData: msg,
      fileUrl: msg['file_url'],
      fileType: msg['file_type'] ?? 'text',
      fileName: msg['file_name'],
    );
  }

  // ✅ NEW: Unified sending function for text and/or files.
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    // Guard clause: Do nothing if there's no text AND no file.
    if (text.isEmpty && _stagedFile == null) {
      return;
    }
    if (_isSending || _otherUserId == null) return;

    setState(() => _isSending = true);

    String? fileUrl;
    String? fileName;
    String? fileTypeForDb;

    try {
      // Step 1: Upload the file if one is staged
      if (_stagedFile != null) {
        final file = _stagedFile!;
        final fName = p.basename(file.path);
        final fileExtension = p.extension(file.path).toLowerCase();
        final isImage =
            ['.jpg', '.jpeg', '.png', 'gif'].contains(fileExtension);

        fileTypeForDb = isImage ? 'image' : 'document';
        fileName = fName;

        final storagePath =
            '/public/$_myUserId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        await Supabase.instance.client.storage
            .from('chatattachments')
            .upload(storagePath, file);

        fileUrl = Supabase.instance.client.storage
            .from('chatattachments')
            .getPublicUrl(storagePath);
      }

      // Step 2: Insert the message record into the database
      await Supabase.instance.client.from('messages').insert({
        'sender_id': _myUserId,
        'receiver_id': _otherUserId,
        'message': text.isNotEmpty ? text : null,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_type':
            fileTypeForDb ?? 'text', // Use file type or default to 'text'
      });

      // Step 3: Clean up the UI state
      _textController.clear();
      if (mounted) {
        setState(() {
          _stagedFile = null; // Clear the staged file and remove the preview
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // ✅ NEW: This function now ONLY picks the file and stages it for sending.
  Future<void> _pickFile(FileType intentType) async {
    FileType pickerType;
    List<String>? pickerExtensions;

    if (intentType == FileType.image) {
      pickerType = FileType.image;
      pickerExtensions = null;
    } else {
      pickerType = FileType.custom;
      pickerExtensions = [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt'
      ];
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: pickerType,
        allowedExtensions: pickerExtensions,
      );

      if (result != null && result.files.single.path != null) {
        // Instead of uploading, just update the state to show the preview
        setState(() {
          _stagedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: darkScaffoldBackground,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.image, color: iconColor),
                title: const Text('Image',
                    style: TextStyle(color: primaryTextColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFile(FileType.image); // Calls the new picker function
                },
              ),
              ListTile(
                leading: const Icon(Icons.description, color: iconColor),
                title: const Text('Document',
                    style: TextStyle(color: primaryTextColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFile(FileType.any); // Calls the new picker function
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // All other logic functions like _confirmDeleteMessage, _scrollToStart, etc.
  // remain the same.

  // --- UI Builder Methods ---
  @override
  Widget build(BuildContext context) {
    // This remains the same
    final appBarTitle =
        widget.isSupervisorView ? widget.studentName : widget.supervisorName;
    final appBarInitial =
        (appBarTitle).isNotEmpty ? (appBarTitle)[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 1,
        leadingWidth: 70,
        titleSpacing: 0,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back, color: primaryTextColor, size: 24),
              const SizedBox(width: 2),
              CircleAvatar(
                backgroundColor: accentColor,
                radius: 18,
                child: Text(
                  appBarInitial,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appBarTitle,
              style: const TextStyle(
                  color: primaryTextColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ),
            const Text(
              'Online', // You can make this dynamic later
              style: TextStyle(color: secondaryTextColor, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : Column(
              children: <Widget>[
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet. Say hello! 👋',
                            style: TextStyle(color: secondaryTextColor),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageItem(_messages[index]);
                          },
                        ),
                ),
                _buildInputArea(),
              ],
            ),
    );
  }

  // ✅ MODIFIED: The input area is now a Column to hold the preview.
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: inputAreaColor,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NEW: Show the preview only if a file is staged
            if (_stagedFile != null) _buildFilePreview(),
            // The original input row
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: darkScaffoldBackground,
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file, color: iconColor),
                          onPressed: _isSending ? null : _showAttachmentPicker,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            style: const TextStyle(
                                color: primaryTextColor, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Message',
                              hintStyle: TextStyle(
                                  color: secondaryTextColor.withOpacity(0.8)),
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.multiline,
                            maxLines: 5,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed:
                      _isSending ? null : _sendMessage, // Calls unified sender
                  backgroundColor: accentColor,
                  elevation: 1,
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Widget to display the staged file preview in the input area.
  Widget _buildFilePreview() {
    final file = _stagedFile!;
    final fileName = p.basename(file.path);
    final fileExtension = p.extension(file.path).toLowerCase();
    final isImage = ['.jpg', '.jpeg', '.png', 'gif'].contains(fileExtension);

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: receivedMessageColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.5)),
      ),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Row(
            children: [
              if (isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Icon(Icons.description, color: iconColor, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(color: primaryTextColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Cancel button to remove the staged file
          InkWell(
            onTap: () {
              if (_isSending) return;
              setState(() {
                _stagedFile = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // The rest of your UI building methods remain the same
  // (e.g., _buildMessageItem, _buildTextBlock, etc.)
  Widget _buildMessageItem(ChatMessage message) {
    // This is the correct version with the Wrap widget
    final isSentByMe = message.isSentByMe;
    final alignment =
        isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isSentByMe ? sentMessageColor : receivedMessageColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          InkWell(
            onLongPress:
                isSentByMe ? () => _confirmDeleteMessage(message) : null,
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12.0),
                  topRight: const Radius.circular(12.0),
                  bottomLeft:
                      isSentByMe ? const Radius.circular(12.0) : Radius.zero,
                  bottomRight:
                      isSentByMe ? Radius.zero : const Radius.circular(12.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.fileType == 'image')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildImageMessage(message),
                    ),
                  if (message.fileType == 'document')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildDocumentMessage(message),
                    ),
                  _buildTextBlock(message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBlock(ChatMessage message) {
    // This is the correct version with the Wrap widget
    final timeFormat = DateFormat('hh:mm a');
    final timeStr = timeFormat.format(message.timestamp.toLocal());
    if (message.text == null || message.text!.isEmpty) {
      if (message.fileUrl != null) {
        return Align(
          alignment: Alignment.centerRight,
          child: Text(timeStr,
              style: TextStyle(
                color: secondaryTextColor.withOpacity(0.8),
                fontSize: 11,
              )),
        );
      }
      return const SizedBox.shrink();
    }
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
                color: primaryTextColor, fontSize: 15.5, height: 1.3),
            children: [
              TextSpan(text: message.text),
              TextSpan(
                  text: ' ' * (timeStr.length + 2),
                  style: const TextStyle(color: Colors.transparent)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0, left: 8.0),
          child: Text(timeStr,
              style: TextStyle(
                  color: secondaryTextColor.withOpacity(0.8), fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildImageMessage(ChatMessage message) {
    return GestureDetector(
      onTap: () => _openUrl(message.fileUrl!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          message.fileUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              width: 200,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: accentColor,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image,
                color: secondaryTextColor, size: 50);
          },
        ),
      ),
    );
  }

  Widget _buildDocumentMessage(ChatMessage message) {
    return GestureDetector(
      onTap: () => _openUrl(message.fileUrl!),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message.fileName ?? 'Document',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $url')),
      );
    }
  }

  Future<void> _confirmDeleteMessage(ChatMessage message) async {
    if (!message.isSentByMe) return;
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: darkScaffoldBackground,
          title: const Text('Delete Message',
              style: TextStyle(color: primaryTextColor)),
          content: const Text(
              'Are you sure you want to permanently delete this message?',
              style: TextStyle(color: secondaryTextColor)),
          actions: [
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: secondaryTextColor)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child:
                  Text('Delete', style: TextStyle(color: Colors.red.shade400)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (shouldDelete == true) {
      try {
        await Supabase.instance.client
            .from('messages')
            .delete()
            .eq('id', message.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete message: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _scrollToStart({bool isAnimated = true}) {
    if (!_scrollController.hasClients || _messages.isEmpty) return;
    final position = _scrollController.position.maxScrollExtent;
    if (isAnimated) {
      _scrollController.animateTo(position,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(position);
    }
  }
}
