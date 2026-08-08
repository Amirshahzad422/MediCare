import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _errorMessage;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _showChat = false;
  bool _isCallStarted = false;
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'sender': 'doctor', 'text': 'Hello! How are you feeling today?'},
    {'sender': 'patient', 'text': 'Hi doctor, I have a mild fever since yesterday.'},
  ];

  @override
  void initState() {
    super.initState();
  }

  void _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera hardware found on this device.';
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please click the camera/mic icon in Chrome\'s address bar and allow permissions.';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'sender': 'patient',
        'text': _messageController.text.trim(),
      });
      _messageController.clear();
    });
  }

  void _saveMockPrescription(String doctorName, String specialty, String doctorPhoto) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final dateStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

      await FirebaseFirestore.instance.collection('prescriptions').add({
        'patientId': user.uid,
        'patientName': user.displayName ?? 'Patient',
        'doctorName': doctorName,
        'specialty': specialty,
        'doctorPhoto': doctorPhoto,
        'date': dateStr,
        'diagnosis': 'Acute Viral Fever & Migraine',
        'medicines': [
          {'name': 'Paracetamol 500mg', 'dosage': '1-0-1', 'duration': '5 Days'},
          {'name': 'Amoxicillin 250mg', 'dosage': '1-1-1', 'duration': '7 Days'},
          {'name': 'Panadol Extra', 'dosage': '0-0-1', 'duration': '3 Days'}
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void _showCompletionDialog(String patientName, String doctorName, String specialty, String doctorPhoto) {
    _saveMockPrescription(doctorName, specialty, doctorPhoto);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
          'Thank You, $patientName!\n\nYou have completed the\nonline consultation.\nWe will send the medicine to\nyou.',
          style: AppTypography.bodyLarge,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepBlue,
              foregroundColor: AppColors.white,
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

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
    final doctorName = app['doctorName'] ?? 'Doctor';
    final doctorPhoto = app['doctorPhoto'] ?? '';
    final specialty = app['specialty'] ?? 'General Physician';
    final patientName = app['patientName'] ?? 'Jessica';

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                doctorPhoto,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.darkNavy,
                    child: const Icon(Icons.person, size: 100, color: AppColors.white),
                  );
                },
              ),
            ),
            if (!_isCallStarted)
              Positioned.fill(
                child: Container(
                  color: AppColors.darkNavy.withValues(alpha: 0.85),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.iceBlue,
                          backgroundImage: NetworkImage(doctorPhoto),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          doctorName,
                          style: AppTypography.titleLarge.copyWith(color: AppColors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ready to start your consultation?',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.lightBlue),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isCallStarted = true;
                            });
                            _initializeCamera();
                          },
                          icon: const Icon(Icons.video_call, color: AppColors.white),
                          label: const Text('Start Consultation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _isCallStarted
                      ? Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          Flexible(
                            child: Text(
                              'Live',
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : const SizedBox(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white, size: 28),
                    onPressed: () {
                      if (_isCallStarted) {
                        _showCompletionDialog(patientName, doctorName, specialty, doctorPhoto);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
            if (_isCallStarted)
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
                    child: _isCameraOff
                        ? Container(
                      color: AppColors.deepBlue,
                      child: const Center(
                        child: Icon(Icons.videocam_off, color: AppColors.white, size: 30),
                      ),
                    )
                        : _errorMessage != null
                        ? Container(
                      color: AppColors.deepBlue,
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    )
                        : (_isCameraInitialized && _cameraController != null)
                        ? CameraPreview(_cameraController!)
                        : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),
            if (_isCallStarted)
              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: _isMuted ? AppColors.error : AppColors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isMuted = !_isMuted;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _isCameraOff ? Icons.videocam_off : Icons.videocam,
                          color: _isCameraOff ? AppColors.error : AppColors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isCameraOff = !_isCameraOff;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chat,
                          color: _showChat ? AppColors.iceBlue : AppColors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showChat = !_showChat;
                          });
                        },
                      ),
                      CircleAvatar(
                        backgroundColor: AppColors.error,
                        radius: 24,
                        child: IconButton(
                          icon: const Icon(Icons.call_end, color: AppColors.white),
                          onPressed: () => _showCompletionDialog(patientName, doctorName, specialty, doctorPhoto),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isCallStarted && _showChat)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 300,
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
                              onPressed: () {
                                setState(() {
                                  _showChat = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isPatient = msg['sender'] == 'patient';
                            return Align(
                              alignment: isPatient ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isPatient ? AppColors.deepBlue : AppColors.iceBlue.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isPatient ? AppColors.white : AppColors.darkNavy,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: AppTypography.bodyMedium,
                                  border: const OutlineInputBorder(),
                                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.lightBlue)),
                                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.deepBlue)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send, color: AppColors.deepBlue),
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}