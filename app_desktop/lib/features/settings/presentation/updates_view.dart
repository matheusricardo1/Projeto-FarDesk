import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design_system/design_system.dart';
import 'update_view_model.dart';

/// Tela "Atualizações" — verificação sob demanda, separada do dialog
/// automático que já existe em `_AppRootState` (dispara ao abrir o app).
class UpdatesView extends StatefulWidget {
  const UpdatesView({super.key});

  @override
  State<UpdatesView> createState() => _UpdatesViewState();
}

class _UpdatesViewState extends State<UpdatesView> {
  @override
  void initState() {
    super.initState();
    final viewModel = context.read<UpdateViewModel>();
    if (viewModel.status == UpdateCheckStatus.idle) viewModel.checkNow();
  }

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final viewModel = context.watch<UpdateViewModel>();

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: rem(680)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Atualizações',
              subtitle: 'Mantenha o FarDesk na versão mais recente, com os recursos e correções mais novos.',
            ),
            SizedBox(height: rem(Space.xxl + 4)),
            _StatusCard(viewModel: viewModel),
            SizedBox(height: rem(Space.xxxl)),
            const SectionLabel('Detalhes'),
            SizedBox(height: rem(Space.md)),
            AppTable(
              headers: const ['Versão instalada', 'Canal', 'Verificação automática'],
              rows: [
                [viewModel.currentVersion, 'Estável', 'Ao abrir o FarDesk'],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.viewModel});

  final UpdateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    final status = viewModel.status;
    final highlighted = switch (status) {
      UpdateCheckStatus.available || UpdateCheckStatus.downloading || UpdateCheckStatus.readyToInstall => true,
      _ => false,
    };

    return AppCard(
      highlighted: highlighted,
      radius: Radii.xl,
      padding: EdgeInsets.all(rem(Space.xxl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(size: 56),
              SizedBox(width: rem(Space.lg)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('FarDesk', style: text.title),
                        SizedBox(width: rem(Space.sm + 2)),
                        _StatusTag(status: status),
                      ],
                    ),
                    SizedBox(height: rem(Space.xs)),
                    Text('Versão instalada: v${viewModel.currentVersion}', style: text.caption),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: rem(Space.xxl)),
          const Divider(height: 1, color: AppColors.border),
          SizedBox(height: rem(Space.xxl)),
          _StatusBody(viewModel: viewModel),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final UpdateCheckStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, pulse) = switch (status) {
      UpdateCheckStatus.idle || UpdateCheckStatus.checking => ('Verificando...', AppColors.brandAlt, true),
      UpdateCheckStatus.upToDate => ('Atualizado', AppColors.success, false),
      UpdateCheckStatus.available => ('Nova versão', AppColors.warning, true),
      UpdateCheckStatus.downloading => ('Baixando...', AppColors.brandAlt, true),
      UpdateCheckStatus.readyToInstall => ('Instalando...', AppColors.brandAlt, true),
      UpdateCheckStatus.error => ('Erro ao verificar', AppColors.danger, false),
    };
    return StatusBadge(label: label, color: color, pulse: pulse);
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({required this.viewModel});

  final UpdateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return switch (viewModel.status) {
      UpdateCheckStatus.idle || UpdateCheckStatus.checking => const _CheckingBody(),
      UpdateCheckStatus.upToDate => _UpToDateBody(viewModel: viewModel),
      UpdateCheckStatus.available => _AvailableBody(viewModel: viewModel),
      UpdateCheckStatus.downloading => _DownloadingBody(viewModel: viewModel),
      UpdateCheckStatus.readyToInstall => const _ReadyToInstallBody(),
      UpdateCheckStatus.error => _ErrorBody(viewModel: viewModel),
    };
  }
}

class _CheckingBody extends StatelessWidget {
  const _CheckingBody();

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    return Row(
      children: [
        SizedBox(
          width: rem(16),
          height: rem(16),
          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandAlt),
        ),
        SizedBox(width: rem(Space.sm + 2)),
        Text('Procurando por novidades...', style: text.body),
      ],
    );
  }
}

class _UpToDateBody extends StatelessWidget {
  const _UpToDateBody({required this.viewModel});

  final UpdateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_rounded, size: rem(18), color: AppColors.success),
            SizedBox(width: rem(Space.sm + 2)),
            Expanded(
              child: Text('Você já está usando a versão mais recente do FarDesk.', style: text.body),
            ),
          ],
        ),
        SizedBox(height: rem(Space.xl)),
        Row(
          children: [
            AppButton(
              label: 'Verificar agora',
              variant: AppButtonVariant.secondary,
              icon: Icons.refresh_rounded,
              onPressed: viewModel.checkNow,
            ),
            SizedBox(width: rem(Space.md)),
            Expanded(
              child: Text(
                _relativeCheckedLabel(viewModel.lastCheckedAt),
                style: text.caption,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvailableBody extends StatelessWidget {
  const _AvailableBody({required this.viewModel});

  final UpdateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    final update = viewModel.available!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('v${viewModel.currentVersion}', style: text.body.copyWith(decoration: TextDecoration.lineThrough)),
            SizedBox(width: rem(Space.sm + 2)),
            Icon(Icons.arrow_forward_rounded, size: rem(14), color: AppColors.textMuted),
            SizedBox(width: rem(Space.sm + 2)),
            Text('v${update.version}', style: text.headline.copyWith(color: AppColors.brandAlt)),
          ],
        ),
        SizedBox(height: rem(Space.sm)),
        Text(
          'Uma nova versão do FarDesk está disponível, com melhorias de desempenho e correções.',
          style: text.body,
        ),
        SizedBox(height: rem(Space.xl)),
        Row(
          children: [
            AppButton(
              label: 'Atualizar agora',
              icon: Icons.download_rounded,
              onPressed: viewModel.downloadAndInstall,
            ),
            SizedBox(width: rem(Space.md)),
            AppButton(
              label: 'Notas de lançamento',
              variant: AppButtonVariant.ghost,
              icon: Icons.open_in_new_rounded,
              onPressed: () => _openReleaseNotes(update.releaseUrl),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openReleaseNotes(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _DownloadingBody extends StatelessWidget {
  const _DownloadingBody({required this.viewModel});

  final UpdateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    final progress = viewModel.progress;
    final percentLabel = progress == null ? 'Baixando atualização...' : 'Baixando atualização... ${(progress * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressBar(value: progress),
        SizedBox(height: rem(Space.sm + 2)),
        Text(percentLabel, style: text.caption),
        SizedBox(height: rem(Space.xl)),
        AppButton(label: 'Baixando...', loading: true, onPressed: null),
      ],
    );
  }
}

class _ReadyToInstallBody extends StatelessWidget {
  const _ReadyToInstallBody();

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Download concluído. Abrindo o instalador e fechando o FarDesk...', style: text.body),
        SizedBox(height: rem(Space.xl)),
        AppButton(label: 'Reiniciando...', loading: true, onPressed: null),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.viewModel});

  final UpdateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InlineNotice(
          text: 'Não foi possível verificar atualizações agora. Confira sua conexão e tente de novo.',
        ),
        SizedBox(height: rem(Space.xl)),
        AppButton(
          label: 'Tentar novamente',
          variant: AppButtonVariant.secondary,
          icon: Icons.refresh_rounded,
          onPressed: viewModel.checkNow,
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  /// `null` = indeterminado (servidor não mandou `Content-Length`).
  final double? value;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    return ClipRRect(
      borderRadius: BorderRadius.circular(rem(Radii.pill)),
      child: SizedBox(
        height: rem(8),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value ?? 0),
          duration: Motion.medium,
          curve: Motion.curve,
          builder: (context, animated, _) => LinearProgressIndicator(
            value: value == null ? null : animated,
            backgroundColor: AppColors.surfaceRaised,
            valueColor: const AlwaysStoppedAnimation(AppColors.brandAlt),
          ),
        ),
      ),
    );
  }
}

String _relativeCheckedLabel(DateTime? at) {
  if (at == null) return '';
  final elapsed = DateTime.now().difference(at);
  if (elapsed.inSeconds < 10) return 'Verificado agora mesmo';
  if (elapsed.inMinutes < 1) return 'Verificado há ${elapsed.inSeconds}s';
  if (elapsed.inHours < 1) return 'Verificado há ${elapsed.inMinutes} min';
  return 'Verificado há ${elapsed.inHours}h';
}
