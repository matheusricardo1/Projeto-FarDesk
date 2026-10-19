import { PairingRequest } from '@modules/pairing/domain/aggregates/pairing-request.aggregate';
import { PairingRequestExpiredException } from '@modules/pairing/domain/exceptions/pairing-request-expired.exception';
import { PairingRequestStatus } from '@modules/pairing/domain/value-objects/pairing-request-status.vo';

const NOW = new Date('2026-01-01T00:00:00Z');

function newRequest(now = NOW): PairingRequest {
  return PairingRequest.request({ deviceId: 'device-1', ownerId: 'owner-1', pin: '1234', now });
}

describe('PairingRequest', () => {
  it('nasce Pending e expira 30s depois', () => {
    const request = newRequest();

    expect(request.status).toBe(PairingRequestStatus.Pending);
    expect(request.expiresAt.getTime()).toBe(NOW.getTime() + 30_000);
  });

  it('dispara pairing.requested com o PIN ao nascer', () => {
    const request = newRequest();

    expect(request.domainEvents).toHaveLength(1);
    expect(request.domainEvents[0]?.eventName).toBe('pairing.requested');
  });

  it('acknowledge muda pra Delivered', () => {
    const request = newRequest();

    request.acknowledge(new Date(NOW.getTime() + 1_000));

    expect(request.status).toBe(PairingRequestStatus.Delivered);
  });

  it('acknowledge depois de expirado lança PairingRequestExpiredException', () => {
    const request = newRequest();

    expect(() => request.acknowledge(new Date(NOW.getTime() + 31_000))).toThrow(
      PairingRequestExpiredException,
    );
  });

  it('complete muda pra Completed e dispara pairing.completed', () => {
    const request = newRequest();
    request.acknowledge(new Date(NOW.getTime() + 1_000));
    request.clearDomainEvents();

    request.complete(new Date(NOW.getTime() + 2_000));

    expect(request.status).toBe(PairingRequestStatus.Completed);
    expect(request.domainEvents.map((event) => event.eventName)).toEqual(['pairing.completed']);
  });

  it('fail funciona mesmo depois de expirado — registrar a falha não deveria travar', () => {
    const request = newRequest();

    request.fail('PIN errado');

    expect(request.status).toBe(PairingRequestStatus.Failed);
    expect(request.failureReason).toBe('PIN errado');
  });

  it('isActive é falso depois de expirado, completo ou falho', () => {
    const expired = newRequest();
    expect(expired.isActive(new Date(NOW.getTime() + 31_000))).toBe(false);

    const completed = newRequest();
    completed.complete(new Date(NOW.getTime() + 1_000));
    expect(completed.isActive(new Date(NOW.getTime() + 2_000))).toBe(false);
  });
});
