import { Entity, Player } from '@vg2/core';
import { Chunk } from './chunk';

export class World {
  public readonly id: string;
  public readonly name: string;
  private entities: Map<string, Entity> = new Map();
  private chunks: Map<string, Chunk> = new Map();
  private playerChunks: Map<string, Set<string>> = new Map();

  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
  }

  public addEntity(entity: Entity): void {
    this.entities.set(entity.id, entity);
    this.updateEntityChunks(entity);
  }

  public removeEntity(entityId: string): boolean {
    const entity = this.entities.get(entityId);
    if (entity) {
      this.playerChunks.delete(entityId);
    }
    return this.entities.delete(entityId);
  }

  public getEntity(id: string): Entity | undefined {
    return this.entities.get(id);
  }

  public getAllEntities(): Entity[] {
    return Array.from(this.entities.values());
  }

  public getPlayers(): Player[] {
    return Array.from(this.entities.values()).filter(
      (entity): entity is Player => 'sessionId' in entity
    );
  }

  public getChunk(chunkX: number, chunkY: number): Chunk {
    const key = `${chunkX},${chunkY}`;
    let chunk = this.chunks.get(key);
    if (!chunk) {
      chunk = new Chunk(chunkX, chunkY);
      this.chunks.set(key, chunk);
    }
    return chunk;
  }

  public getChunksInRange(centerX: number, centerY: number, radius: number): Chunk[] {
    const chunks: Chunk[] = [];
    const chunkX = Math.floor(centerX / Chunk.SIZE);
    const chunkY = Math.floor(centerY / Chunk.SIZE);

    for (let dx = -radius; dx <= radius; dx++) {
      for (let dy = -radius; dy <= radius; dy++) {
        chunks.push(this.getChunk(chunkX + dx, chunkY + dy));
      }
    }
    return chunks;
  }

  private updateEntityChunks(entity: Entity): void {
    const chunkX = Math.floor(entity.position.x / Chunk.SIZE);
    const chunkY = Math.floor(entity.position.y / Chunk.SIZE);
    
    let chunks = this.playerChunks.get(entity.id);
    if (!chunks) {
      chunks = new Set();
      this.playerChunks.set(entity.id, chunks);
    }
    chunks.add(`${chunkX},${chunkY}`);
  }

  public getEntityChunks(entityId: string): string[] {
    return Array.from(this.playerChunks.get(entityId) || []);
  }
}
