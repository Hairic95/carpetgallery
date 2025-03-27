export class Vector2 {
  public x: number;
  public y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }

  public equal(otherVec: Vector2): boolean {
    return this.x == otherVec.x && this.y == otherVec.y;
  }
}
