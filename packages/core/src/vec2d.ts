export class Vec2D {
  constructor(
    public x: number,
    public y: number,
  ) {}

  add(other: Vec2D): Vec2D {
    return new Vec2D(this.x + other.x, this.y + other.y);
  }

  sub(other: Vec2D): Vec2D {
    return new Vec2D(this.x - other.x, this.y - other.y);
  }

  eq(other: Vec2D): boolean {
    return this.x === other.x && this.y === other.y;
  }

  distance(other: Vec2D): number {
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  toString(): string {
    return `Vec2D(${this.x}, ${this.y})`;
  }
}
