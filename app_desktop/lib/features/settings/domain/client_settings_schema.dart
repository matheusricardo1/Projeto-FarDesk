import 'setting.dart';

/// Configurações do app como cliente (lado Moonlight). As chaves seguem os
/// nomes das preferências de streaming do Moonlight pra facilitar o mapeamento
/// quando o núcleo de stream for integrado.
const clientSettingsPages = <SettingsPage>[
  SettingsPage(
    id: 'client.basic',
    label: 'Básico',
    scope: SettingsScope.client,
    blocks: [
      SettingsGroup(
        title: 'Vídeo',
        subtitle: 'Valores muito altos pro seu PC ou pra sua conexão podem causar atraso, travamento ou erro de stream.',
        items: [
          ChoiceSetting(
            key: 'resolution',
            label: 'Resolução',
            defaultValue: '720p',
            options: [
              SettingOption('720p', '720p'),
              SettingOption('1080p', '1080p'),
              SettingOption('1440p', '1440p'),
              SettingOption('2160p', '4K'),
            ],
          ),
          ChoiceSetting(
            key: 'fps',
            label: 'Quadros por segundo (FPS)',
            defaultValue: '30',
            options: [
              SettingOption('30', '30 FPS'),
              SettingOption('60', '60 FPS'),
              SettingOption('90', '90 FPS'),
              SettingOption('120', '120 FPS'),
            ],
          ),
          TextSetting(
            key: 'bitrate',
            label: 'Bitrate do vídeo (Mbps)',
            description: 'Abaixe em conexões mais lentas. Aumente pra melhorar a qualidade de imagem.',
            defaultValue: '2',
          ),
          ChoiceSetting(
            key: 'windowMode',
            label: 'Modo da tela',
            defaultValue: 'borderless',
            options: [
              SettingOption('fullscreen', 'Tela cheia'),
              SettingOption('borderless', 'Janela sem bordas (Recomendado)'),
              SettingOption('windowed', 'Janela'),
            ],
          ),
          ToggleSetting(key: 'vsync', label: 'Sincronização vertical (V-Sync)', defaultValue: true),
          ToggleSetting(key: 'framePacing', label: 'Ritmo de quadros (Frame pacing)', defaultValue: true),
        ],
      ),
    ],
  ),
  SettingsPage(
    id: 'client.input',
    label: 'Entrada',
    scope: SettingsScope.client,
    blocks: [
      SettingsGroup(title: 'Mouse e teclado', items: [
        ToggleSetting(key: 'absoluteMouseMode', label: 'Otimizar o mouse pra Desktop Remoto (em vez de jogos)', defaultValue: false),
        ChoiceSetting(
          key: 'captureSysKeysMode',
          label: 'Capturar teclas de atalho do sistema',
          defaultValue: 'always',
          options: [SettingOption('never', 'Nunca'), SettingOption('always', 'Sempre'), SettingOption('fullscreen', 'Em tela cheia')],
        ),
        ToggleSetting(key: 'swapMouseButtons', label: 'Inverter os botões esquerdo e direito do mouse', defaultValue: false),
        ToggleSetting(key: 'reverseScrollDirection', label: 'Inverter a direção da roda do mouse', defaultValue: false),
      ]),
      SettingsGroup(title: 'Toque', items: [
        ToggleSetting(key: 'absoluteTouchMode', label: 'Usar o touchscreen como trackpad virtual', defaultValue: false),
      ]),
    ],
  ),
  SettingsPage(
    id: 'client.controller',
    label: 'Controle',
    scope: SettingsScope.client,
    blocks: [
      SettingsGroup(title: 'Controle', items: [
        ToggleSetting(key: 'swapFaceButtons', label: 'Trocar os botões A/B e X/Y do controle', defaultValue: false),
        ToggleSetting(key: 'forceGamepadConnected', label: 'Forçar o controle #1 a estar sempre conectado', defaultValue: false),
        ToggleSetting(key: 'gamepadMouse', label: 'Controlar o mouse pelo controle segurando "Start"', defaultValue: false),
        ToggleSetting(key: 'backgroundGamepad', label: 'Processar entrada do controle com o FarDesk em segundo plano', defaultValue: false),
      ]),
    ],
  ),
  SettingsPage(
    id: 'client.audio',
    label: 'Áudio',
    scope: SettingsScope.client,
    blocks: [
      SettingsGroup(title: 'Áudio', items: [
        ChoiceSetting(
          key: 'audioConfig',
          label: 'Configuração de áudio',
          defaultValue: 'stereo',
          options: [SettingOption('stereo', 'Estéreo'), SettingOption('surround51', '5.1 Surround'), SettingOption('surround71', '7.1 Surround')],
        ),
        ToggleSetting(key: 'muteHostAudio', label: 'Silenciar os alto-falantes do host durante o stream', defaultValue: false),
        ToggleSetting(key: 'muteOnFocusLoss', label: 'Silenciar o áudio quando o FarDesk não é a janela ativa', defaultValue: false),
      ]),
    ],
  ),
  SettingsPage(
    id: 'client.session',
    label: 'Sessão',
    scope: SettingsScope.client,
    blocks: [
      SettingsGroup(title: 'Ao conectar', items: [
        ToggleSetting(
          key: 'autoConnectTrusted',
          label: 'Conectar automaticamente a dispositivos confiáveis',
          description: 'Pula a confirmação ao acessar um dispositivo marcado como confiável.',
          defaultValue: true,
        ),
        ToggleSetting(key: 'gameOptimizations', label: 'Otimizar as configurações do jogo pro streaming', defaultValue: false),
      ]),
      SettingsGroup(title: 'Ao encerrar', items: [
        ToggleSetting(key: 'quitAppAfter', label: 'Sair do aplicativo no host depois de terminar o stream', defaultValue: false),
      ]),
    ],
  ),
  SettingsPage(
    id: 'client.advanced',
    label: 'Avançado',
    scope: SettingsScope.client,
    blocks: [
      SettingsGroup(title: 'Decodificação', items: [
        ChoiceSetting(
          key: 'videoDecoderSelection',
          label: 'Decodificador de vídeo',
          defaultValue: 'auto',
          options: [SettingOption('auto', 'Automático (Recomendado)'), SettingOption('hardware', 'Hardware'), SettingOption('software', 'Software')],
        ),
        ChoiceSetting(
          key: 'videoCodecConfig',
          label: 'Codec de vídeo',
          defaultValue: 'auto',
          options: [
            SettingOption('auto', 'Automático (Recomendado)'),
            SettingOption('h264', 'H.264'),
            SettingOption('hevc', 'HEVC'),
            SettingOption('av1', 'AV1'),
          ],
        ),
        ToggleSetting(key: 'enableHdr', label: 'Habilitar HDR (Experimental)', defaultValue: false),
      ]),
      SettingsGroup(title: 'Experimental', items: [
        ToggleSetting(key: 'enableYUV444', label: 'Habilitar YUV 4:4:4 (Experimental)', defaultValue: false),
        ToggleSetting(key: 'unlockBitrate', label: 'Desbloquear limite de bitrate (Experimental)', defaultValue: false),
      ]),
    ],
  ),
  SettingsPage(
    id: 'client.interface',
    label: 'Interface',
    scope: SettingsScope.client,
    blocks: [
      SettingsGroup(title: 'Idioma e aparência', items: [
        ChoiceSetting(
          key: 'language',
          label: 'Idioma',
          defaultValue: 'pt',
          options: [SettingOption('pt', 'Português (Brasil)'), SettingOption('en', 'English'), SettingOption('es', 'Español')],
        ),
        ChoiceSetting(
          key: 'uiDisplayMode',
          label: 'Modo de exibição da interface',
          defaultValue: 'windowed',
          options: [SettingOption('windowed', 'Janela'), SettingOption('fullscreen', 'Tela cheia')],
        ),
        ChoiceSetting(
          key: 'theme',
          label: 'Tema',
          defaultValue: 'dark',
          options: [SettingOption('dark', 'Escuro'), SettingOption('light', 'Claro (em breve)'), SettingOption('system', 'Automático (em breve)')],
        ),
      ]),
      SettingsGroup(title: 'Rede e descoberta', items: [
        ToggleSetting(key: 'enableMdns', label: 'Encontrar PCs na rede local automaticamente (Recomendado)', defaultValue: true),
        ToggleSetting(key: 'connectionWarnings', label: 'Mostrar avisos de qualidade de conexão', defaultValue: true),
        ToggleSetting(key: 'detectNetworkBlocking', label: 'Detectar conexões bloqueadas automaticamente (Recomendado)', defaultValue: true),
      ]),
      SettingsGroup(title: 'Outros', items: [
        ToggleSetting(key: 'richPresence', label: 'Integração de Presença Avançada do Discord', defaultValue: false),
        ToggleSetting(key: 'showPerformanceOverlay', label: 'Mostrar estatísticas de desempenho durante o stream', defaultValue: false),
        ToggleSetting(
          key: 'fpsHud',
          label: 'Mostrar mini HUD de FPS durante o stream',
          description: 'Indicador compacto do FarDesk, mais discreto que as estatísticas completas.',
          defaultValue: true,
        ),
        ToggleSetting(key: 'keepAwake', label: 'Manter a tela ativa durante o stream', defaultValue: true),
      ]),
    ],
  ),
];
