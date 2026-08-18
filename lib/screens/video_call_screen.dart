import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/chat_bubble.dart';
import '../services/call_service.dart';
import '../models/appointment_model.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

import '../components/prescription_writer_sheet.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final CallService _callService = CallService();

  RtcEngine? _engine;
  int? _remoteUid;
  bool _localUserJoined = false;

  String? _agoraAppId;
  String? _agoraTempToken;

  String? _channelName;

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _showChat = false;
  bool _joiningCall = true;

  String? _callId;
  String _callStatus = CallService.statusScheduled;
  bool _isDoctor = false;
  String _myName = '';

  final _msgController = TextEditingController();
  List<CallChatMessage> _messages = [];
  StreamSubscription<List<CallChatMessage>>? _chatSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;

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

    _isDoctor = (_app['isDoctor'] as bool?) ?? false;
    _myName = user.displayName ?? (user.email ?? 'User');

    try {
      final cid = await _callService.ensureCallRoom(
          AppointmentModel.fromMap(_app, _app['id']),
          callIdOverride: _app['callId']
      );
      await _callService.joinCall(cid, isDoctor: _isDoctor, name: _myName);

      final agoraDoc = await FirebaseFirestore.instance.collection('appSettings').doc('agora').get();
      if (agoraDoc.exists) {
        _agoraAppId = agoraDoc.data()?['appId'];
        _agoraTempToken = agoraDoc.data()?['tempToken'];
      }

      if (!mounted) return;
      setState(() {
        _callId = cid;
        _channelName = "medicare";
        _joiningCall = false;
      });

      _callSub = _callService.watchCall(cid).listen((snap) {
        if (!mounted) return;
        final data = snap.data();
        if (data == null) return;
        setState(() {
          _callStatus = data['status'] ?? CallService.statusScheduled;
        });
        if (_callStatus == CallService.statusEnded) {
          _updateAppointmentStatusToPast();
          _showCompletionDialog();
        }
      });

      _chatSub = _callService.watchMessages(cid).listen((msgs) {
        if (!mounted) return;
        setState(() => _messages = msgs);
      });

      await _initAgora();

    } catch (e, st) {
      if (!mounted) return;
      setState(() => _joiningCall = false);
    }
  }

  Future<void> _initAgora() async {
    if (!kIsWeb) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.camera,
      ].request();

      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        return;
      }
    }

    if (_agoraAppId == null || _agoraTempToken == null) {
      return;
    }

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: _agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
          });
        },
        onError: (ErrorCodeType err, String msg) {
        },
      ),
    );

    await _engine!.enableVideo();
    await _engine!.startPreview();

    await _engine!.joinChannel(
      token: _agoraTempToken!,
      channelId: _channelName!,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _chatSub?.cancel();
    _callSub?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

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

  Future<void> _showPrescriptionWriter({bool exitAfter = false}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PrescriptionWriterSheet(
          doctorName: _app['doctorName'] ?? 'Doctor',
          specialty: _app['specialty'] ?? 'General Physician',
          doctorPhoto: _app['doctorPhoto'] ?? '',
          prefilledPatientId: _app['patientId'],
          prefilledPatientName: _app['patientName'],
        ),
      ),
    );
    if (exitAfter && mounted) {
      Navigator.pop(context); 
    }
  }

  Future<void> _updateAppointmentStatusToPast() async {
    try {
      final appointmentId = _app['id'] as String?;
      if (appointmentId != null && appointmentId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .update({'status': 2});
      }
    } catch (e) {
      debugPrint("Error updating appointment status to past: $e");
    }
  }

  Future<void> _endCall() async {
    if (_callId == null) {
      Navigator.pop(context);
      return;
    }
    await _updateAppointmentStatusToPast();
    await _callService.endCall(_callId!, endedBy: _isDoctor ? 'doctor' : 'patient');
  }

  /*
  void _showEndedByOtherDialog() {
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
          if (_isDoctor) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Later', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPrescriptionWriter(exitAfter: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepBlue),
              child: const Text('Write Prescription', style: TextStyle(color: AppColors.white)),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepBlue),
              child: const Text('OK', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ],
      ),
    );
  }
  */

  void _showCompletionDialog() {
    _callSub?.cancel();
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
              child: Text('Consultation Complete', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
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
          if (_isDoctor) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Later', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPrescriptionWriter(exitAfter: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepBlue, foregroundColor: AppColors.white),
              child: const Text('Write Prescription'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepBlue, foregroundColor: AppColors.white),
              child: const Text('OK'),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine?.muteLocalAudioStream(_isMuted);
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    _engine?.muteLocalVideoStream(_isCameraOff);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return Scaffold(
          backgroundColor: AppColors.darkNavy,
          body: Center(
              child: Text('Error: No session found.', style: AppTypography.bodyLarge.copyWith(color: AppColors.white))
          )
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
            Positioned.fill(
              child: _remoteUid != null && _engine != null
                  ? AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine!,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: _channelName),
                ),
              )
                  : Container(color: AppColors.darkNavy),
            ),
            Positioned.fill(
              child: Container(
                  color: AppColors.darkNavy.withValues(alpha: (_remoteUid != null) ? 0.0 : 0.85)
              ),
            ),
            if (_joiningCall)
              const Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.white),
                      SizedBox(height: 20),
                      Text('Connecting to call room…', style: TextStyle(color: AppColors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            if (!_joiningCall && !isConnected && _callStatus != CallService.statusEnded)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.iceBlue,
                        backgroundImage: (doctorPhoto.isNotEmpty && doctorPhoto.startsWith('http')) ? NetworkImage(doctorPhoto) : null,
                        child: (doctorPhoto.isEmpty || !doctorPhoto.startsWith('http')) ? const Icon(Icons.person, size: 48, color: AppColors.deepBlue) : null,
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
            if (!_joiningCall)
              Positioned(
                top: 20, left: 20, right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_remoteUid != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppColors.darkNavy.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20)
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text('Live', style: AppTypography.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else const SizedBox(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.white, size: 28),
                      onPressed: () {
                        if (isConnected) _endCall();
                        else Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            if (isConnected)
              Positioned(
                right: 20,
                bottom: _showChat ? 320 : 120,
                child: Container(
                  width: 110,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.deepBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.iceBlue, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _isCameraOff
                        ? const Center(child: Icon(Icons.videocam_off, color: AppColors.white, size: 30))
                        : (_localUserJoined && _engine != null)
                        ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                        : const Center(child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)),
                  ),
                ),
              ),
            if (isConnected)
              Positioned(
                left: 20, right: 20, bottom: 30,
                child: _buildControls(),
              ),
            if (isConnected && _showChat) _buildChatPanel(doctorName, doctorPhoto),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: AppColors.darkNavy.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlBtn(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            active: !_isMuted,
            onTap: _toggleMute,
            tooltip: _isMuted ? 'Unmute' : 'Mute',
          ),
          _controlBtn(
            icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
            active: !_isCameraOff,
            onTap: _toggleCamera,
            tooltip: _isCameraOff ? 'Camera On' : 'Camera Off',
          ),
          _controlBtn(
            icon: Icons.chat_bubble_outline,
            active: _showChat,
            onTap: () => setState(() => _showChat = !_showChat),
            tooltip: 'Chat',
          ),
          if (_isDoctor)
            _controlBtn(
              icon: Icons.assignment_outlined,
              active: true,
              onTap: _showPrescriptionWriter,
              tooltip: 'Write Prescription',
            ),
          GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 54, height: 54,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
              child: const Icon(Icons.call_end, color: AppColors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn({required IconData icon, required bool active, required VoidCallback onTap, required String tooltip}) {
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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