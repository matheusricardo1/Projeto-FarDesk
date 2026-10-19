/** Identidade tipada — evita passar o id de um agregado pro repositório de outro. */
export abstract class EntityId {
  protected constructor(public readonly value: string) {}

  equals(other: EntityId | undefined): boolean {
    return other !== undefined && other.value === this.value && other.constructor === this.constructor;
  }

  toString(): string {
    return this.value;
  }
}

/** Igualdade por identidade, não por valor dos campos (diferente de `ValueObject`). */
export abstract class Entity<Id extends EntityId> {
  protected constructor(public readonly id: Id) {}

  equals(other: Entity<Id> | undefined): boolean {
    if (other === undefined) return false;
    if (this === other) return true;
    return this.id.equals(other.id);
  }
}
