import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ChatInputWidget extends StatefulWidget {
  final Function(String text, {String? filePath, List<int>? fileBytes, String? fileName}) onSend;
  final TextEditingController? controller;
  final bool isEditing;
  final VoidCallback? onCancelEdit;

  const ChatInputWidget({
    Key? key,
    required this.onSend,
    this.controller,
    this.isEditing = false,
    this.onCancelEdit,
  }) : super(key: key);

  @override
  _ChatInputWidgetState createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  late TextEditingController _controller;
  bool _isRecordingVoice = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _controller) {
      _controller = widget.controller!;
    }
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecordingVoice = true;
      _recordingSeconds = 0;
    });
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }
    });
  }

  void _stopAndSendVoiceRecording() {
    final int finalSecs = _recordingSeconds;
    _recordingTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
    });
    final durationStr = _formatRecordingTime(finalSecs);
    widget.onSend(
      "[Voice Note|$durationStr]",
      fileName: "voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a",
    );
  }

  void _cancelVoiceRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
      _recordingSeconds = 0;
    });
  }

  PlatformFile? _stagedFile;
  double _uploadProgress = 0.0;
  bool _isUploadingFile = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'mp4', 'mov', 'avi'],
      withData: true,
    );
    if (result != null) {
      final file = result.files.single;
      setState(() {
        _stagedFile = file;
        _isUploadingFile = true;
        _uploadProgress = 0.0;
      });

      // Simulate smooth upload progress bar before ready to send
      Timer.periodic(const Duration(milliseconds: 150), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _uploadProgress += 0.2;
          if (_uploadProgress >= 1.0) {
            _uploadProgress = 1.0;
            _isUploadingFile = false;
            timer.cancel();
          }
        });
      });
    }
  }

  void _clearStagedFile() {
    setState(() {
      _stagedFile = null;
      _isUploadingFile = false;
      _uploadProgress = 0.0;
    });
  }

  Future<void> _pickVoiceNote() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'aac'],
      withData: true,
    );
    if (result != null) {
      final file = result.files.single;
      widget.onSend(
        "[Voice Note]",
        filePath: file.path,
        fileBytes: file.bytes,
        fileName: file.name,
      );
    }
  }

  String _formatRecordingTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final inputBgColor = isDark ? Colors.grey.shade800 : const Color(0xFFF2F2F2);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: bgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_stagedFile != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stagedFile!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.grey.shade400,
                          color: _isUploadingFile ? Colors.blue : Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_isUploadingFile)
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.green, size: 24),
                      onPressed: () {
                        final f = _stagedFile!;
                        _clearStagedFile();
                        widget.onSend(
                          "[Attachment]",
                          filePath: f.path,
                          fileBytes: f.bytes,
                          fileName: f.name,
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: _clearStagedFile,
                  ),
                ],
              ),
            ),
          _isRecordingVoice
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
                    onPressed: _cancelVoiceRecording,
                    tooltip: "إلغاء التسجيل",
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatRecordingTime(_recordingSeconds),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "جاري تسجيل الصوت...",
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _stopAndSendVoiceRecording,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: textColor),
                      onChanged: (text) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey),
                        border: InputBorder.none,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isEditing)
                              IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red.shade400, size: 22),
                                onPressed: widget.onCancelEdit,
                              )
                            else ...[
                              IconButton(
                                icon: Icon(Icons.attach_file, color: isDark ? Colors.grey.shade400 : Colors.grey, size: 22),
                                onPressed: _pickFile,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    if (_controller.text.trim().isNotEmpty) {
                      widget.onSend(_controller.text);
                      _controller.clear();
                      setState(() {});
                    } else if (!widget.isEditing) {
                      _startVoiceRecording();
                    }
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: widget.isEditing
                          ? Colors.blue
                          : (_controller.text.trim().isNotEmpty
                              ? const Color(0xFFFFCC00)
                              : const Color(0xFF00A884)), // WhatsApp green for mic
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isEditing
                          ? Icons.check
                          : (_controller.text.trim().isNotEmpty ? Icons.arrow_upward : Icons.mic),
                      color: widget.isEditing || _controller.text.trim().isEmpty ? Colors.white : Colors.black,
                      size: 22,
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
