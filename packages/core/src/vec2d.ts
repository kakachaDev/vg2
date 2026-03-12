export class Vec2D {
  constructor(
    public x: number,
    public y: number
  ) {}

  static from(obj: { x: number; y: number }): Vec2D {
    return new Vec2D(obj.x, obj.y);
  }

  add(other: Vec2D): Vec2D {
    return new Vec2D(this.x + other.x, this.y + other.y);
  }

  sub(other: Vec2D): Vec2D {
    return new Vec2D(this.x - other.x, this.y - other.y);
  }

  eq(other: Vec2D): boolean {
    return this.x === other.x && this.y === other.y;
  }

  distance(to: Vec2D): number {
    const dx = this.x - to.x;
    const dy = this.y - to.y;
    return Math.sqrt(dx * dx + dy * dy);
  }


  clone(): Vec2D {
    return new Vec2D(this.x, this.y);
  }
  toString(): string {
    return `Vec2D(${this.x}, ${this.y})`;
  }
}
