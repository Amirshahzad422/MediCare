import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/chat_bubble.dart';
import '../services/call_service.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

/// Real simultaneous video call screen.
///
/// Both patient and doctor navigate here from their Appointments / Dashboard.
/// They share the SAME Firestore call room (keyed by appointment ID).
/// When both have joined, the status becomes [CallService.statusConnected]
/// and both screens show the live indicator.
/// In-call chat is streamed from Firestore in real time — both parties see
/// every message the moment it is sent.
class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final CallService _callService = CallService();

  // Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraError;

  // UI state
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _showChat = false;
  bool _joiningCall = true;   // spinner while we create/join the room

  // Call-room data
  String? _callId;
  String _callStatus = CallService.statusScheduled;
  bool _isDoctor = false;
  String _myName = '';

  // In-call chat
  final _msgController = TextEditingController();
  List<CallChatMessage> _messages = [];
  StreamSubscription<List<CallChatMessage>>? _chatSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;

  // Route args
  late Map<String, dynamic> _app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && _callId == null) {
      _app = args;
      _initCallRoom();
    }
  }

  Future<void> _initCallRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Determine role from app data or UID
    _isDoctor = (_app['isDoctor'] as bool?) ?? false;
    _myName = user.displayName ?? (user.email ?? 'User');

    try {
      final cid = await _callService.ensureCallRoom(_app);
      await _callService.joinCall(cid, isDoctor: _isDoctor, name: _myName);

      if (!mounted) return;
      setState(() {
        _callId = cid;
        _joiningCall = false;
      });

      // Stream call-room status
      _callSub = _callService.watchCall(cid).listen((snap) {
        if (!mounted) return;
        final data = snap.data();
        if (data == null) return;
        setState(() {
          _callStatus = data['status'] ?? CallService.statusScheduled;
        });
        // If call was ended by the other party
        if (_callStatus == CallService.statusEnded) {
          _showEndedByOtherDialog();
        }
      });

      // Stream messages
      _chatSub = _callService.watchMessages(cid).listen((msgs) {
        if (!mounted) return;
        setState(() => _messages = msgs);
      });

      // Start camera
      _initCamera();
    } catch (e) {
      if (!mounted) return;
      setState(() => _joiningCall = false);
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera found on this device.');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(front, ResolutionPreset.medium, enableAudio: true);
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cameraError =
          'Allow camera/mic permission in your browser or device settings.');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _msgController.dispose();
    _chatSub?.cancel();
    _callSub?.cancel();
    super.dispose();
  }

  // ─── Call room actions ───────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _callId == null) return;
    _msgController.clear();
    await _callService.sendMessage(
      _callId!,
      _isDoctor ? 'doctor' : 'patient',
      _myName,
      text,
    );
  }

  Future<void> _endCall() async {
    if (_callId == null) {
      Navigator.pop(context);
      return;
    }
    await _callService.endCall(_callId!, endedBy: _isDoctor ? 'doctor' : 'patient');
    if (!mounted) return;
    _showCompletionDialog();
  }

  void _showEndedByOtherDialog() {
    // Prevent duplicate dialogs
    _callSub?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.call_end, color: AppColors.error),
            SizedBox(width: 8),
            Text('Call Ended'),
          ],
        ),
        content: const Text('The other party has ended the consultation.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);  // close dialog
              Navigator.pop(context);  // leave call screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepBlue),
            child: const Text('OK', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    final patientName = _app['patientName'] ?? 'Patient';
    final doctorName  = _app['doctorName']  ?? 'Doctor';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Consultation Complete',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          _isDoctor
              ? 'Consultation with $patientName has ended.\nYou can now write a prescription from the Dashboard.'
              : 'Thank you, $patientName!\nYour consultation with $doctorName has ended.\nYour prescription will appear in the Prescriptions tab.',
          style: AppTypography.bodyLarge,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // leave call screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepBlue,
              foregroundColor: AppColors.white,
              minimumSize: const Size(100, 44),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: Center(
          child: Text(
            'No consultation session found.',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.white),
          ),
        ),
      );
    }

    final app = args;
    final doctorName  = app['doctorName']  ?? 'Doctor';
    final doctorPhoto = app['doctorPhoto'] ?? '';
    final patientName = app['patientName'] ?? 'Patient';

    final isConnected = _callStatus == CallService.statusConnected;
    final isRinging   = _callStatus == CallService.statusRinging;

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video background (doctor photo as stand-in for remote stream)
            Positioned.fill(
              child: Image.network(
                doctorPhoto,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.darkNavy,
                  child: const Icon(Icons.person, size: 100, color: AppColors.white),
                ),
              ),
            ),

            // Overlay tint
            Positioned.fill(
              child: Container(
                color: AppColors.darkNavy.withValues(alpha: isConnected ? 0.35 : 0.85),
              ),
            ),

            // ─── Joining spinner ───────────────────────────────────────────
            if (_joiningCall)
              const Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.white),
                      SizedBox(height: 20),
                      Text('Connecting to call room…',
                          style: TextStyle(color: AppColors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),

            // ─── Waiting for other party ───────────────────────────────────
            if (!_joiningCall && !isConnected && _callStatus != CallService.statusEnded)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.iceBlue,
                        backgroundImage:
                            doctorPhoto.isNotEmpty ? NetworkImage(doctorPhoto) : null,
                        child: doctorPhoto.isEmpty
                            ? const Icon(Icons.person, size: 48, color: AppColors.deepBlue)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        doctorName,
                        style: AppTypography.titleLarge.copyWith(color: AppColors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRinging
                            ? 'Waiting for ${_isDoctor ? patientName : doctorName} to join…'
                            : 'Call room ready. Starting when both parties join…',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.lightBlue),
                      ),
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(color: AppColors.iceBlue, strokeWidth: 2),
                    ],
                  ),
                ),
              ),

            // ─── Top bar: LIVE badge + close ──────────────────────────────
            if (!_joiningCall)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.darkNavy.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Live',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.white, size: 28),
                      onPressed: () {
                        if (isConnected) {
                          _endCall();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),

            // ─── Self-camera pip ──────────────────────────────────────────
            if (isConnected)
              Positioned(
                right: 20,
                bottom: _showChat ? 320 : 120,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 110,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.deepBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.iceBlue, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: _buildSelfCamera(),
                  ),
                ),
              ),

            // ─── Controls ─────────────────────────────────────────────────
            if (isConnected)
              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: _buildControls(),
              ),

            // ─── Chat panel ───────────────────────────────────────────────
            if (isConnected && _showChat) _buildChatPanel(doctorName, doctorPhoto),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfCamera() {
    if (_isCameraOff) {
      return Container(
        color: AppColors.deepBlue,
        child: const Center(child: Icon(Icons.videocam_off, color: AppColors.white, size: 30)),
      );
    }
    if (_cameraError != null) {
      return Container(
        color: AppColors.deepBlue,
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            _cameraError!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.white, fontSize: 10),
          ),
        ),
      );
    }
    if (_isCameraInitialized && _cameraController != null) {
      return CameraPreview(_cameraController!);
    }
    return const Center(child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2));
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkNavy.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlBtn(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            active: !_isMuted,
            onTap: () => setState(() => _isMuted = !_isMuted),
            tooltip: _isMuted ? 'Unmute' : 'Mute',
          ),
          _controlBtn(
            icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
            active: !_isCameraOff,
            onTap: () => setState(() => _isCameraOff = !_isCameraOff),
            tooltip: _isCameraOff ? 'Camera On' : 'Camera Off',
          ),
          _controlBtn(
            icon: Icons.chat_bubble_outline,
            active: _showChat,
            onTap: () => setState(() => _showChat = !_showChat),
            tooltip: 'Chat',
          ),
          // End call
          GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error,
              ),
              child: const Icon(Icons.call_end, color: AppColors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.mediumBlue.withValues(alpha: 0.8)
                : AppColors.error.withValues(alpha: 0.7),
          ),
          child: Icon(icon, color: AppColors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildChatPanel(String doctorName, String doctorPhoto) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 310,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.iceBlue)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('In-Call Chat', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.darkNavy),
                    onPressed: () => setState(() => _showChat = false),
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet.\nSay hello!',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.lightBlue),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = _messages[i];
                        final isMine = _isDoctor
                            ? msg.senderRole == 'doctor'
                            : msg.senderRole == 'patient';
                        return ChatBubble(
                          text: msg.text,
                          isMine: isMine,
                          senderName: isMine ? 'You' : msg.senderName,
                        );
                      },
                    ),
            ),
            // Input
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        hintStyle: AppTypography.bodyMedium,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.lightBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.deepBlue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.deepBlue,
                      ),
                      child: const Icon(Icons.send, color: AppColors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}