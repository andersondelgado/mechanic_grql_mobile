import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/providers.dart';
import '../../../../models/peritaje.dart';

class CameraPage extends ConsumerStatefulWidget {
  final Peritaje peritaje;

  const CameraPage({super.key, required this.peritaje});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isUploading = false;

  // Limitar duracion de video a 10s para evitar desbordamiento de RAM (Base64)
  static const int maxVideoDurationSeconds = 10;
  int _recordingTime = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar cámara: $e')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isRecording) {
      return;
    }
    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingTime = 0;
      });
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) return false;
      setState(() {
        _recordingTime++;
      });
      if (_recordingTime >= maxVideoDurationSeconds) {
        _stopRecording();
        return false;
      }
      return true;
    });
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;
    try {
      final video = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });

      // Subir y analizar automáticamente
      _uploadAndAnalyze(video);
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _uploadAndAnalyze(XFile video) async {
    setState(() => _isUploading = true);
    try {
      final file = File(video.path);
      final bytes = await file.readAsBytes();
      final base64Video = base64Encode(bytes);

      // Data URL format requerido por lambdas web
      final base64String = 'data:video/mp4;base64,$base64Video';

      final apiClient = ref.read(apiClientProvider);

      // 1. Upload usando callLambda (igual que web)
      final uploadResponse = await apiClient.uploadVideo(
        base64String,
        widget.peritaje.id!,
      );

      final videoUrl = uploadResponse['video_url'];
      if (videoUrl == null) throw Exception("Error al subir video (No URL)");

      // 2. Analyze usando callLambda (igual que web)
      await apiClient.analyzeVideo(widget.peritaje.id!, videoUrl);

      if (mounted) {
        context.pop();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Análisis IA Completado',
              style: TextStyle(color: AppColors.success),
            ),
            content: const Text(
              'Gemini ha analizado el video exitosamente. La ficha ha sido actualizada.',
            ),
            actions: [
              TextButton(onPressed: () => ctx.pop(), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en el proceso IA: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_controller!)),

          // UI Overlays
          if (_isUploading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Subiendo y Analizando con Gemini IA...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Esto puede tardar unos segundos.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          if (!_isUploading)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (_isRecording)
                    Text(
                      '00:${_recordingTime.toString().padLeft(2, '0')} / 00:$maxVideoDurationSeconds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: _isRecording ? 30 : 60,
                          height: _isRecording ? 30 : 60,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(
                              _isRecording ? 8 : 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}
