import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

/// Desenha o vídeo simulado: clipe próprio e neutro em loop
/// (`assets/video/sample_live.mp4`, gerado por nós; nada de terceiros).
class FakeVideoView extends StatefulWidget {
  const FakeVideoView({super.key, this.semanticsLabel});

  final String? semanticsLabel;

  static const asset = 'assets/video/sample_live.mp4';

  @override
  State<FakeVideoView> createState() => _FakeVideoViewState();
}

class _FakeVideoViewState extends State<FakeVideoView> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(FakeVideoView.asset);
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          _controller
            ..setLooping(true)
            ..setVolume(0)
            ..play();
          setState(() {});
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller.value.isInitialized;
    return Semantics(
      label: widget.semanticsLabel,
      image: true,
      child: ColoredBox(
        color: Colors.black,
        child: ready
            ? FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
