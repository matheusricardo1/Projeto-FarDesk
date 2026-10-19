/**
 * Sem identidade própria — duas instâncias com as mesmas `props` são o mesmo
 * valor. A invariante é validada no construtor de quem estende, nunca depois.
 */
export abstract class ValueObject<Props extends object> {
  protected constructor(protected readonly props: Readonly<Props>) {}

  equals(other: ValueObject<Props> | undefined): boolean {
    if (other === undefined) return false;
    if (other.constructor !== this.constructor) return false;
    return JSON.stringify(this.props) === JSON.stringify(other.props);
  }
}
