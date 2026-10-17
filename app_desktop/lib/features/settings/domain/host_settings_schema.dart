import 'setting.dart';

/// Configurações desta máquina como host. As chaves são as do `sunshine.conf`,
/// então a implementação real só precisa ler/escrever o arquivo.
const hostSettingsPages = <SettingsPage>[
  SettingsPage(
    id: 'host.general',
    label: 'Geral',
    scope: SettingsScope.host,
    blocks: [
      SettingsGroup(title: 'Geral', items: [
        ChoiceSetting(
          key: 'locale',
          label: 'Idioma',
          description: 'O idioma usado na interface do host.',
          defaultValue: 'pt',
          options: [SettingOption('pt', 'Português (Brasil)'), SettingOption('en', 'English'), SettingOption('es', 'Español')],
        ),
        TextSetting(
          key: 'sunshine_name',
          label: 'Nome do host',
          description: 'O nome exibido pros clientes. Se não especificado, o nome do PC é usado.',
          defaultValue: 'PC do Matheus',
        ),
        ChoiceSetting(
          key: 'min_log_level',
          label: 'Nível de log',
          description: 'O nível mínimo de log impresso na saída padrão.',
          defaultValue: 'info',
          options: [
            SettingOption('verbose', 'Verbose'),
            SettingOption('debug', 'Debug'),
            SettingOption('info', 'Info'),
            SettingOption('warning', 'Warning'),
            SettingOption('error', 'Error'),
            SettingOption('fatal', 'Fatal'),
            SettingOption('none', 'Nenhum'),
          ],
        ),
        ActionSetting(
          key: 'global_prep_cmd',
          label: 'Comandos de preparação',
          description: 'Comandos executados antes ou depois de rodar qualquer aplicativo. Se um falhar, o lançamento é abortado.',
          actionLabel: 'Gerenciar comandos',
        ),
        ToggleSetting(
          key: 'notify_pre_releases',
          label: 'Notificações de pré-lançamento',
          description: 'Ser notificado sobre novas versões pré-lançamento do host.',
          defaultValue: false,
        ),
        ToggleSetting(
          key: 'system_tray',
          label: 'Ícone na bandeja do sistema',
          description: 'Mostrar ícone na bandeja do sistema e exibir notificações na área de trabalho.',
          defaultValue: true,
        ),
      ]),
    ],
  ),
  SettingsPage(
    id: 'host.input',
    label: 'Entrada',
    scope: SettingsScope.host,
    blocks: [
      SettingsGroup(title: 'Controle', items: [
        ToggleSetting(
          key: 'controller',
          label: 'Habilitar entrada de controle',
          description: 'Permite que convidados controlem o host com um gamepad / controle.',
          defaultValue: true,
        ),
        ChoiceSetting(
          key: 'gamepad',
          label: 'Tipo de controle emulado',
          description: 'Qual tipo de controle emular no host.',
          defaultValue: 'x360',
          options: [SettingOption('auto', 'Automático'), SettingOption('x360', 'X360 (Xbox 360)'), SettingOption('ds4', 'DualShock 4')],
        ),
        TextSetting(
          key: 'back_button_timeout',
          label: 'Timeout de emulação do botão Home/Guide',
          description: 'Segurar Back/Select por esse tempo (ms) emula um Home/Guide. Valor menor que 0 desativa.',
          defaultValue: '-1',
        ),
      ]),
      SettingsGroup(title: 'Teclado', items: [
        ToggleSetting(
          key: 'keyboard',
          label: 'Habilitar entrada de teclado',
          description: 'Permite que convidados controlem o host com o teclado.',
          defaultValue: true,
        ),
        TextSetting(
          key: 'key_repeat_delay',
          label: 'Atraso de repetição de tecla',
          description: 'Atraso inicial em milissegundos antes de repetir teclas.',
          defaultValue: '500',
        ),
        TextSetting(
          key: 'key_repeat_frequency',
          label: 'Frequência de repetição de tecla',
          description: 'Quantas vezes por segundo as teclas repetem. Aceita decimais.',
          defaultValue: '24.9',
        ),
        ToggleSetting(
          key: 'always_send_scancodes',
          label: 'Sempre enviar scancodes',
          description: 'Melhora compatibilidade com jogos, mas pode gerar entrada errada em clientes com layout diferente do inglês americano.',
          defaultValue: true,
        ),
        ToggleSetting(
          key: 'key_rightalt_to_key_win',
          label: 'Mapear Alt direito pra tecla Windows',
          description: 'Útil quando o cliente não consegue enviar a tecla Windows diretamente.',
          defaultValue: false,
        ),
      ]),
      SettingsGroup(title: 'Mouse e toque', items: [
        ToggleSetting(
          key: 'mouse',
          label: 'Habilitar entrada de mouse',
          description: 'Permite que convidados controlem o host com o mouse.',
          defaultValue: true,
        ),
        ToggleSetting(
          key: 'high_resolution_scrolling',
          label: 'Suporte a rolagem de alta resolução',
          description: 'Repassa eventos de rolagem de alta resolução. Desative em apps antigos que rolam rápido demais.',
          defaultValue: true,
        ),
        ToggleSetting(
          key: 'native_pen_touch',
          label: 'Suporte nativo a caneta/toque',
          description: 'Repassa eventos nativos de caneta e toque dos clientes.',
          defaultValue: true,
        ),
      ]),
    ],
  ),
  SettingsPage(
    id: 'host.audioVideo',
    label: 'Áudio e Vídeo',
    scope: SettingsScope.host,
    blocks: [
      SettingsGroup(title: 'Áudio', items: [
        ChoiceSetting(
          key: 'audio_sink',
          label: 'Dispositivo de áudio',
          description: 'Dispositivo de áudio a capturar. Recomendamos deixar no automático.',
          defaultValue: 'auto',
          options: [SettingOption('auto', 'Automático'), SettingOption('speakers', 'Speakers (High Definition Audio Device)')],
        ),
        ChoiceSetting(
          key: 'virtual_sink',
          label: 'Dispositivo virtual',
          description: 'Dispositivo de áudio virtual a usar. Recomendamos deixar no automático.',
          defaultValue: 'auto',
          options: [SettingOption('auto', 'Automático'), SettingOption('steam', 'Steam Streaming Speakers')],
        ),
        ToggleSetting(
          key: 'install_steam_audio_drivers',
          label: 'Instalar drivers de áudio da Steam',
          description: 'Com a Steam instalada, instala o Steam Streaming Speakers pra suportar surround 5.1/7.1 e mutar o host.',
          defaultValue: true,
        ),
        ToggleSetting(
          key: 'stream_audio',
          label: 'Transmitir áudio',
          description: 'Desativar pode ser útil pra streamar telas headless como segundo monitor.',
          defaultValue: true,
        ),
      ]),
      SettingsGroup(title: 'Captura de vídeo', items: [
        ChoiceSetting(
          key: 'adapter_name',
          label: 'Nome do adaptador',
          description: 'GPU usada na captura. Recomendamos deixar no automático.',
          defaultValue: 'auto',
          options: [SettingOption('auto', 'Automático'), SettingOption('rx580', 'Radeon RX 580 Series')],
        ),
        ReadOnlySetting(
          key: 'output_name',
          label: 'ID do dispositivo de exibição',
          description: 'Tela a capturar. Se não definido, a tela primária é usada.',
          defaultValue: '{de9bb7e2-186e-505b-9e93-f48793333810}',
          kind: ReadOnlyKind.display,
        ),
        ActionSetting(
          key: 'dd_configuration_option',
          label: 'Opções avançadas de exibição',
          description: 'Configurações adicionais do dispositivo de exibição usado pra captura.',
          actionLabel: 'Expandir',
        ),
      ]),
      SettingsGroup(title: 'Limites de stream', items: [
        TextSetting(
          key: 'max_bitrate',
          label: 'Bitrate máximo (Kbps)',
          description: 'Limite de bitrate do stream. Com 0, sempre usa o bitrate pedido pelo cliente.',
          defaultValue: '0',
        ),
        TextSetting(
          key: 'minimum_fps_target',
          label: 'FPS mínimo',
          description: 'O FPS efetivo mais baixo do stream. 0 equivale a ~metade do FPS. Recomendado 20 pra conteúdo 24/30fps.',
          defaultValue: '0',
        ),
      ]),
    ],
  ),
  SettingsPage(
    id: 'host.network',
    label: 'Rede',
    scope: SettingsScope.host,
    blocks: [
      SettingsGroup(title: 'Conexão', items: [
        ToggleSetting(
          key: 'upnp',
          label: 'UPnP',
          description: 'Configura automaticamente o encaminhamento de portas pra streaming pela internet.',
          defaultValue: false,
        ),
        ChoiceSetting(
          key: 'address_family',
          label: 'Família de endereços',
          description: 'A família de endereços usada pelo host.',
          defaultValue: 'both',
          options: [SettingOption('ipv4', 'IPv4'), SettingOption('both', 'IPv4+IPv6')],
        ),
        TextSetting(key: 'port', label: 'Porta', description: 'A família de portas usada pelo host.', defaultValue: '47989'),
      ]),
      SettingsTable(
        headers: ['Protocolo', 'Porta', 'Nota'],
        rows: [
          ['TCP', '47984', ''],
          ['TCP', '47989', ''],
          ['TCP', '47990', 'Web UI'],
          ['TCP', '48010', ''],
          ['UDP', '47998 – 48000', ''],
        ],
      ),
      SettingsNotice('Expor a Web UI pra internet é um risco de segurança! Prossiga por sua conta e risco.'),
      SettingsGroup(title: 'Acesso e criptografia', items: [
        ChoiceSetting(
          key: 'origin_web_ui_allowed',
          label: 'Origem permitida na Web UI',
          description: 'De onde a Web UI pode ser acessada.',
          defaultValue: 'wan',
          options: [
            SettingOption('pc', 'Só este PC'),
            SettingOption('lan', 'Só rede local'),
            SettingOption('wan', 'Qualquer um pode acessar a Web UI'),
          ],
        ),
        TextSetting(
          key: 'external_ip',
          label: 'IP externo',
          description: 'Se não informado, o host detecta automaticamente.',
          hint: '123.456.789.12',
        ),
        ChoiceSetting(
          key: 'lan_encryption_mode',
          label: 'Criptografia na LAN',
          description: 'Quando criptografar streams na rede local. Pode reduzir performance em máquinas menos potentes.',
          defaultValue: '0',
          options: [
            SettingOption('0', 'Desativado (padrão)'),
            SettingOption('1', 'Habilitado pra clientes compatíveis'),
            SettingOption('2', 'Sempre habilitado'),
          ],
        ),
        ChoiceSetting(
          key: 'wan_encryption_mode',
          label: 'Criptografia na WAN',
          description: 'Quando criptografar streams pela internet.',
          defaultValue: '1',
          options: [
            SettingOption('0', 'Desativado'),
            SettingOption('1', 'Habilitado pra clientes compatíveis (padrão)'),
            SettingOption('2', 'Sempre habilitado'),
          ],
        ),
        TextSetting(
          key: 'ping_timeout',
          label: 'Timeout de ping',
          description: 'Quanto tempo esperar (ms) por dados do cliente antes de encerrar o stream.',
          defaultValue: '10000',
        ),
      ]),
    ],
  ),
  SettingsPage(
    id: 'host.configFiles',
    label: 'Arquivos de Config.',
    scope: SettingsScope.host,
    blocks: [
      SettingsGroup(
        title: 'Arquivos de configuração',
        subtitle: 'Onde cada arquivo usado pelo host fica salvo no disco.',
        items: [
          ReadOnlySetting(key: 'file_apps', label: 'Arquivo de apps', description: 'Onde os apps do host ficam salvos.', defaultValue: 'apps.json'),
          ReadOnlySetting(
            key: 'credentials_file',
            label: 'Arquivo de credenciais',
            description: 'Guarda usuário/senha separado do arquivo de estado.',
            defaultValue: 'fardesk_state.json',
          ),
          ReadOnlySetting(key: 'log_path', label: 'Caminho do log', description: 'Onde os logs do host ficam salvos.', defaultValue: 'fardesk.log'),
          ReadOnlySetting(
            key: 'pkey',
            label: 'Chave privada',
            description: 'Usada no pareamento com a Web UI e com clientes. Idealmente RSA-2048.',
            defaultValue: '/dir/pkey.pem',
          ),
          ReadOnlySetting(
            key: 'cert',
            label: 'Certificado',
            description: 'Usado no pareamento com a Web UI e com clientes. Idealmente com chave pública RSA-2048.',
            defaultValue: '/dir/cert.pem',
          ),
          ReadOnlySetting(key: 'file_state', label: 'Arquivo de estado', description: 'Onde o estado do host fica salvo.', defaultValue: 'fardesk_state.json'),
        ],
      ),
    ],
  ),
  SettingsPage(
    id: 'host.advanced',
    label: 'Avançado',
    scope: SettingsScope.host,
    blocks: [
      SettingsGroup(
        title: 'Codificação',
        subtitle: 'Valem pra qualquer encoder. As opções específicas de cada encoder ficam nas páginas abaixo.',
        items: [
          TextSetting(
            key: 'fec_percentage',
            label: 'Porcentagem de FEC',
            description: 'Pacotes de correção de erro por pacote de dados. Valores altos corrigem mais perda, com mais uso de banda.',
            defaultValue: '20',
          ),
          TextSetting(
            key: 'qp',
            label: 'Parâmetro de quantização (QP)',
            description: 'Usado em dispositivos sem Bitrate Constante. Valor alto = mais compressão, menos qualidade.',
            defaultValue: '28',
          ),
          TextSetting(
            key: 'min_threads',
            label: 'Mínimo de threads de CPU',
            description: 'O ideal é o menor valor que ainda codifica de forma confiável nas configurações desejadas.',
            defaultValue: '2',
          ),
          ChoiceSetting(
            key: 'hevc_mode',
            label: 'Suporte a HEVC',
            description: 'Permite streams HEVC Main/Main10. É mais pesado pra codificar em software.',
            defaultValue: '0',
            options: [
              SettingOption('0', 'Anunciar com base nas capacidades do encoder (recomendado)'),
              SettingOption('1', 'Não anunciar'),
              SettingOption('3', 'Sempre anunciar'),
            ],
          ),
          ChoiceSetting(
            key: 'av1_mode',
            label: 'Suporte a AV1',
            description: 'Permite streams AV1 Main 8-bit/10-bit. É mais pesado pra codificar em software.',
            defaultValue: '0',
            options: [
              SettingOption('0', 'Anunciar com base nas capacidades do encoder (recomendado)'),
              SettingOption('1', 'Não anunciar'),
              SettingOption('3', 'Sempre anunciar'),
            ],
          ),
          ChoiceSetting(
            key: 'capture',
            label: 'Forçar método de captura',
            description: 'No automático, o host usa o primeiro método que funcionar.',
            defaultValue: 'auto',
            options: [
              SettingOption('auto', 'Detectar automaticamente (recomendado)'),
              SettingOption('ddx', 'DXGI Desktop Duplication'),
              SettingOption('wgc', 'Windows Graphics Capture'),
            ],
          ),
          ChoiceSetting(
            key: 'encoder',
            label: 'Forçar encoder específico',
            description: 'Sem forçar, o host escolhe a melhor opção disponível.',
            defaultValue: 'auto',
            options: [
              SettingOption('auto', 'Detectar automaticamente (recomendado)'),
              SettingOption('nvenc', 'NVIDIA NVENC'),
              SettingOption('quicksync', 'Intel QuickSync'),
              SettingOption('amdvce', 'AMD AMF'),
              SettingOption('software', 'Software'),
            ],
          ),
        ],
      ),
    ],
  ),
  SettingsPage(
    id: 'host.encoder.nvenc',
    label: 'NVIDIA NVENC Encoder',
    scope: SettingsScope.host,
    isSubpage: true,
    blocks: [SettingsPlaceholder('As opções específicas do NVIDIA NVENC Encoder entram aqui assim que tivermos a especificação.')],
  ),
  SettingsPage(
    id: 'host.encoder.quicksync',
    label: 'Intel QuickSync Encoder',
    scope: SettingsScope.host,
    isSubpage: true,
    blocks: [SettingsPlaceholder('As opções específicas do Intel QuickSync Encoder entram aqui assim que tivermos a especificação.')],
  ),
  SettingsPage(
    id: 'host.encoder.amf',
    label: 'AMD AMF Encoder',
    scope: SettingsScope.host,
    isSubpage: true,
    blocks: [SettingsPlaceholder('As opções específicas do AMD AMF Encoder entram aqui assim que tivermos a especificação.')],
  ),
  SettingsPage(
    id: 'host.encoder.software',
    label: 'Software Encoder',
    scope: SettingsScope.host,
    isSubpage: true,
    blocks: [
      SettingsGroup(title: 'Software Encoder', items: [
        ChoiceSetting(
          key: 'sw_preset',
          label: 'Preset',
          description: 'Equilibra velocidade de codificação e eficiência de compressão (qualidade por bit).',
          defaultValue: 'superfast',
          options: [
            SettingOption('ultrafast', 'ultrafast'),
            SettingOption('superfast', 'superfast (padrão)'),
            SettingOption('veryfast', 'veryfast'),
            SettingOption('faster', 'faster'),
            SettingOption('fast', 'fast'),
            SettingOption('medium', 'medium'),
            SettingOption('slow', 'slow'),
          ],
        ),
        ChoiceSetting(
          key: 'sw_tune',
          label: 'Tune',
          description: 'Ajuste fino aplicado depois do preset.',
          defaultValue: 'zerolatency',
          options: [
            SettingOption('zerolatency', 'zerolatency — baixa latência (padrão)'),
            SettingOption('film', 'film'),
            SettingOption('animation', 'animation'),
          ],
        ),
      ]),
    ],
  ),
];
