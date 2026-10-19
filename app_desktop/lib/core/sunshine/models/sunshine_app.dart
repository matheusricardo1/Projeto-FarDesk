/// Um app/jogo instalado no host, como devolvido por `GET /applist`.
class SunshineApp {
  const SunshineApp({required this.id, required this.title, required this.isHdrSupported});

  final String id;
  final String title;
  final bool isHdrSupported;
}
