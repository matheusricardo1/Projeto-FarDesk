import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../core/moonlight/moonlight_client.dart';

/// Renderiza o frame de vídeo mais recente entregue pelo core nativo do
/// Moonlight (`fardesk_stream_core.dll`): decodifica o buffer BGRA recebido
/// via FFI para uma `ui.Image` e desenha via `RawImage`, mantendo a
/// proporção original do vídeo.
class MoonlightVideoView extends StatefulWidget {
  const MoonlightVideoView({super.key, required this.client});

  final MoonlightClient client;

  @override
  State<MoonlightVideoView> createState() => _MoonlightVideoViewState();
}

class _MoonlightVideoViewState extends State<MoonlightVideoView> {
  ui.Image? _image;
  MoonlightVideoFrame? _lastDecodedFrame;
  bool _decoding = false;

  @override
  void initState() {
    super.initState();
    widget.client.latestVideoFrame.addListener(_onFrame);
    _onFrame();
  }

  @override
  void didUpdateWidget(covariant MoonlightVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client != widget.client) {
      oldWidget.client.latestVideoFrame.removeListener(_onFrame);
      widget.client.latestVideoFrame.addListener(_onFrame);
      _onFrame();
    }
  }

  @override
  void dispose() {
    widget.client.latestVideoFrame.removeListener(_onFrame);
    _image?.dispose();
    super.dispose();
  }

  void _onFrame() {
    final frame = widget.client.latestVideoFrame.value;
    if (frame == null || frame == _lastDecodedFrame || _decoding) return;
    _lastDecodedFrame = frame;
    _decoding = true;
    ui.decodeImageFromPixels(
      frame.bgra,
      frame.width,
      frame.height,
      ui.PixelFormat.bgra8888,
      (image) {
        _decoding = false;
        if (!mounted) {
          image.dispose();
          return;
        }
        final previous = _image;
        setState(() => _image = image);
        previous?.dispose();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return const SizedBox.shrink();
    }
    return FittedBox(
      fit: BoxFit.contain,
      child: RawImage(image: image, width: image.width.toDouble(), height: image.height.toDouble()),
    );
  }
}
