import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_system.dart';
import 'device_card.dart';
import 'devices_view_model.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;
    final viewModel = context.watch<DevicesViewModel>();

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Seus dispositivos',
            subtitle: 'Acesse qualquer dispositivo da sua conta, de onde você estiver.',
            trailing: SizedBox(
              width: rem(260),
              child: AppTextField(
                hint: 'Buscar dispositivo...',
                prefixIcon: Icons.search,
                fillColor: AppColors.surface,
                initialValue: viewModel.query,
                onChanged: viewModel.setQuery,
              ),
            ),
          ),
          SizedBox(height: rem(Space.xxxl)),
          if (viewModel.actionError != null) ...[
            const InlineNotice(text: 'Não foi possível concluir a ação. Tente de novo em instantes.'),
            SizedBox(height: rem(Space.lg)),
          ],
          _DevicesBody(viewModel: viewModel),
        ],
      ),
    );
  }
}

class _DevicesBody extends StatelessWidget {
  const _DevicesBody({required this.viewModel});

  final DevicesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final rem = context.rem;

    if (viewModel.isLoading && !viewModel.hasDevices) {
      return Padding(
        padding: EdgeInsets.only(top: rem(80)),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    if (viewModel.loadError != null && !viewModel.hasDevices) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        message: 'Não foi possível carregar seus dispositivos.',
        action: AppButton(
          label: 'Tentar de novo',
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.small,
          onPressed: viewModel.load,
        ),
      );
    }

    final devices = viewModel.visibleDevices;
    if (devices.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        message: viewModel.query.isEmpty
            ? 'Nenhum dispositivo vinculado à sua conta ainda.'
            : 'Nenhum dispositivo encontrado pra "${viewModel.query}".',
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: devices.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: rem(290),
        mainAxisExtent: rem(212),
        mainAxisSpacing: rem(18),
        crossAxisSpacing: rem(18),
      ),
      itemBuilder: (context, index) {
        final device = devices[index];
        return DeviceCard(
          device: device,
          pending: viewModel.isPending(device.id),
          onConnect: () => viewModel.connect(device),
          onWake: () => viewModel.wake(device),
        );
      },
    );
  }
}
