import { Vec2D } from '@vg2/core';
import { World } from './world.js';
import { Chunk } from './chunk.js';

export class CollisionDetector {
  constructor(private world: World) {}

  public canMove(from: Vec2D, to: Vec2D, entityId: string): boolean {
    const distance = from.distance(to);

    if (distance > 10) {
      return false;
    }

    const chunks = this.world.getChunksInRange(to.x, to.y, 1);

    for (const chunk of chunks) {
      const localX = Math.floor(to.x - chunk.x * Chunk.SIZE);
      const localY = Math.floor(to.y - chunk.y * Chunk.SIZE);

      if (localX >= 0 && localX < Chunk.SIZE && localY >= 0 && localY < Chunk.SIZE) {
        const tile = chunk.getTile(localX, localY);
        if (tile && tile.solid) {
          return false;
        }
      }

      const entities = chunk.getAllEntities();
      for (const entity of entities) {
        if (entity.id !== entityId && entity.type === 'player') {
          if (entity.position.distance(to) < 1.0) {
            return false;
          }
        }
      }
    }

    return true;
  }

  public getValidMovePosition(from: Vec2D, to: Vec2D, entityId: string): Vec2D {
    const direction = new Vec2D(to.x - from.x, to.y - from.y);
    const distance = from.distance(to);

    if (distance < 0.1) return from;

    const steps = Math.ceil(distance / 0.1);
    let lastValidPos = from;

    for (let i = 1; i <= steps; i++) {
      const t = i / steps;
      const checkPos = new Vec2D(
        from.x + direction.x * t,
        from.y + direction.y * t
      );

      if (this.canMove(from, checkPos, entityId)) {
        lastValidPos = checkPos;
      } else {
        break;
      }
    }

    return lastValidPos;
  }
}
