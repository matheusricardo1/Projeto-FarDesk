# FarDesk — Pacote de marca final (design M1)

Design escolhido: dois retângulos arredondados (violeta `#7B5CFA` + ciano `#4CC9F0`) sobrepostos com mistura "screen" na interseção, sobre superfície escura `#12151C` / fundo `#0A0C10`.

## Estrutura

- **master/** — PNGs em 1024px (ícone, versão quadrada cheia sem cantos, avatar circular). Ponto de partida pra gerar qualquer tamanho extra.

- **windows/fardesk.ico** — multi-resolução (16 a 256px), pronto pro .exe.

- **macos/**
  - `AppIcon.icns` — pronto pra apontar no Xcode / Info.plist.
  - `AppIcon.iconset/` — PNGs soltos, caso precise regerar com `iconutil` num Mac.

- **android/**
  - `mipmap-*dpi/ic_launcher.png` — ícone legado.
  - `mipmap-*dpi/ic_launcher_foreground.png` + `ic_launcher_background.png` — par pro ícone adaptativo.
  - `play_store_icon_512.png` — pro cadastro na Play Store.

- **linux/fardesk_<tamanho>.png** — 16 a 512px, pro `.desktop`.

- **ios/** — conjunto completo do App Icon set (20pt–1024pt, @1x/@2x/@3x).

- **web/** — favicon.ico, PNGs 16/32, apple-touch-icon (180px), android-chrome 192/512.

- **avatar/** — versão circular, 128 a 1024px.

- **banners/** — arte de divulgação e lojas, todas já com o lockup ícone + "FarDesk" + tagline:
  - `github_social_preview_1280x640.png` — social preview do repositório no GitHub (também serve de Open Graph image pro site).
  - `twitter_x_header_1500x500.png` — capa de perfil no X/Twitter.
  - `play_store_feature_graphic_1024x500.png` — feature graphic da Google Play.
  - `steam_capsule_small_616x353.png` e `steam_capsule_main_460x215.png` — capsules da Steam (caso o projeto também publique lá).
  - `splash_mobile_1080x1920.png` — tela de splash/loading do app mobile, com glow radial e barra de progresso.

## Observação

O nome **FarDesk** ainda está pendente de checagem de marca/domínio (INPI, USPTO) — se mudar, é só regerar tudo com o mesmo script, que desenha tudo via código (não depende de nenhuma ferramenta externa de design).
