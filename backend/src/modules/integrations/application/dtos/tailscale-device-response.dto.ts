export interface TailscaleDeviceResponseDto {
  id: string;
  name: string;
  hostname: string;
  addresses: string[];
  online: boolean;
}
