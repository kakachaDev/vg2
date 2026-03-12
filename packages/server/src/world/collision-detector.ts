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
      const localX = Math.floor(to.x % Chunk.SIZE);
      const localY = Math.floor(to.y % Chunk.SIZE);
      
      const tile = chunk.getTile(localX, localY);
      if (tile && tile.solid) {
        return false;
      }
      
      const entities = chunk.getAllEntities();
      for (const entity of entities) {
        if (entity.id !== entityId && entity.type === 'player') {
          if (entity.position.distance(to) < 1) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  public getValidMovePosition(from: Vec2D, to: Vec2D, entityId: string): Vec2D {
    if (this.canMove(from, to, entityId)) {
      return to;
    }
    
    const step = 0.5;
    const direction = new Vec2D(to.x - from.x, to.y - from.y);
    const distance = from.distance(to);
    
    if (distance === 0) return from;
    
    const normalizedDir = new Vec2D(
      direction.x / distance,
      direction.y / distance
    );
    
    for (let d = step; d <= distance; d += step) {
      const checkPos = new Vec2D(
        from.x + normalizedDir.x * d,
        from.y + normalizedDir.y * d
      );
      
      if (!this.canMove(from, checkPos, entityId)) {
        const prevPos = new Vec2D(
          from.x + normalizedDir.x * Math.max(0, d - step),
          from.y + normalizedDir.y * Math.max(0, d - step)
        );
        return prevPos;
      }
    }
    
    return from;
  }
}
