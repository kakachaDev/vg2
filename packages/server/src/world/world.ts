import { Entity, Player, Vec2D } from '@vg2/core';
import { Chunk } from './chunk.js';

export class World {
  public readonly id: string;
  public readonly name: string;
  private entities: Map<string, Entity> = new Map();
  private chunks: Map<string, Chunk> = new Map();
  private playerChunks: Map<string, Set<string>> = new Map();
  private entityChunks: Map<string, string> = new Map();

  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
  }

  public addEntity(entity: Entity): void {
    this.entities.set(entity.id, entity);
    const chunkX = Math.floor(entity.position.x / Chunk.SIZE);
    const chunkY = Math.floor(entity.position.y / Chunk.SIZE);
    const chunk = this.getChunk(chunkX, chunkY);
    chunk.addEntity(entity);
    this.entityChunks.set(entity.id, `${chunkX},${chunkY}`);
    this.updateEntityChunks(entity);
  }

  public removeEntity(entityId: string): boolean {
    const entity = this.entities.get(entityId);
    if (entity) {
      const chunkKey = this.entityChunks.get(entityId);
      if (chunkKey) {
        const [chunkX, chunkY] = chunkKey.split(',').map(Number);
        const chunk = this.getChunk(chunkX, chunkY);
        chunk.removeEntity(entityId);
      }
      this.playerChunks.delete(entityId);
      this.entityChunks.delete(entityId);
    }
    return this.entities.delete(entityId);
  }

  public updateEntityPosition(entityId: string, newPosition: Vec2D): void {
    const entity = this.entities.get(entityId);
    if (!entity) return;

    const oldChunkKey = this.entityChunks.get(entityId);
    const newChunkX = Math.floor(newPosition.x / Chunk.SIZE);
    const newChunkY = Math.floor(newPosition.y / Chunk.SIZE);
    const newChunkKey = `${newChunkX},${newChunkY}`;

    entity.position = newPosition;

    if (oldChunkKey !== newChunkKey) {
      if (oldChunkKey) {
        const [oldX, oldY] = oldChunkKey.split(',').map(Number);
        const oldChunk = this.getChunk(oldX, oldY);
        oldChunk.removeEntity(entityId);
      }

      const newChunk = this.getChunk(newChunkX, newChunkY);
      newChunk.addEntity(entity);
      this.entityChunks.set(entityId, newChunkKey);
      this.updateEntityChunks(entity);
    }
  }

  public getEntity(id: string): Entity | undefined {
    return this.entities.get(id);
  }

  public getAllEntities(): Entity[] {
    return Array.from(this.entities.values());
  }

  public getPlayers(): Player[] {
    return Array.from(this.entities.values()).filter(
      (entity): entity is Player => entity.type === 'player',
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
