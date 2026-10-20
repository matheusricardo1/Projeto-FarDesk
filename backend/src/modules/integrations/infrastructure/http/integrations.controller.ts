import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Inject,
  Param,
  ParseEnumPipe,
  Post,
} from '@nestjs/common';

import type { AuthenticatedUser } from '@modules/auth/application/dtos/authenticated-user.dto';
import { CurrentUser } from '@modules/auth/infrastructure/http/current-user.decorator';
import { ConnectTailscaleIntegrationDto } from '@modules/integrations/application/dtos/connect-tailscale-integration.dto';
import type { IntegrationResponseDto } from '@modules/integrations/application/dtos/integration-response.dto';
import type { TailscaleDeviceResponseDto } from '@modules/integrations/application/dtos/tailscale-device-response.dto';
import { CONNECT_TAILSCALE_INTEGRATION_USE_CASE } from '@modules/integrations/application/ports/in/connect-tailscale-integration.use-case';
import type { ConnectTailscaleIntegrationUseCase } from '@modules/integrations/application/ports/in/connect-tailscale-integration.use-case';
import { DISCONNECT_INTEGRATION_USE_CASE } from '@modules/integrations/application/ports/in/disconnect-integration.use-case';
import type { DisconnectIntegrationUseCase } from '@modules/integrations/application/ports/in/disconnect-integration.use-case';
import { LIST_INTEGRATIONS_USE_CASE } from '@modules/integrations/application/ports/in/list-integrations.use-case';
import type { ListIntegrationsUseCase } from '@modules/integrations/application/ports/in/list-integrations.use-case';
import { LIST_TAILSCALE_DEVICES_USE_CASE } from '@modules/integrations/application/ports/in/list-tailscale-devices.use-case';
import type { ListTailscaleDevicesUseCase } from '@modules/integrations/application/ports/in/list-tailscale-devices.use-case';
import { IntegrationPlatform } from '@modules/integrations/domain/value-objects/integration-platform.vo';

/** `clientSecret` passa por aqui só em trânsito — nunca é logado nem devolvido. */
@Controller('integrations')
export class IntegrationsController {
  constructor(
    @Inject(LIST_INTEGRATIONS_USE_CASE) private readonly listIntegrations: ListIntegrationsUseCase,
    @Inject(CONNECT_TAILSCALE_INTEGRATION_USE_CASE)
    private readonly connectTailscale: ConnectTailscaleIntegrationUseCase,
    @Inject(DISCONNECT_INTEGRATION_USE_CASE)
    private readonly disconnectIntegration: DisconnectIntegrationUseCase,
    @Inject(LIST_TAILSCALE_DEVICES_USE_CASE)
    private readonly listTailscaleDevices: ListTailscaleDevicesUseCase,
  ) {}

  @Get()
  async list(@CurrentUser() user: AuthenticatedUser): Promise<IntegrationResponseDto[]> {
    const result = await this.listIntegrations.execute({ ownerId: user.userId });
    return result.value;
  }

  @Post('tailscale/connect')
  @HttpCode(HttpStatus.OK)
  async connect(
    @Body() body: ConnectTailscaleIntegrationDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<IntegrationResponseDto> {
    const result = await this.connectTailscale.execute({
      ownerId: user.userId,
      apiAccessToken: body.apiAccessToken,
    });
    if (result.isErr) throw result.error;
    return result.value;
  }

  @Delete(':platform')
  @HttpCode(HttpStatus.OK)
  async disconnect(
    @Param('platform', new ParseEnumPipe(IntegrationPlatform)) platform: IntegrationPlatform,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<IntegrationResponseDto> {
    const result = await this.disconnectIntegration.execute({ ownerId: user.userId, platform });
    if (result.isErr) throw result.error;
    return result.value;
  }

  @Get('tailscale/devices')
  async devices(@CurrentUser() user: AuthenticatedUser): Promise<TailscaleDeviceResponseDto[]> {
    const result = await this.listTailscaleDevices.execute({ ownerId: user.userId });
    if (result.isErr) throw result.error;
    return result.value;
  }
}
