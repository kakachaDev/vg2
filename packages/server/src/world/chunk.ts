import { Entity } from '@vg2/core';

export interface Tile {
  type: string;
  solid: boolean;
}

export class Chunk {
  public static readonly SIZE = 16;
  public static readonly VIEW_DISTANCE = 2;

  constructor(
    public readonly x: number,
    public readonly y: number,
  ) {}

  private tiles: Map<string, Tile> = new Map();
  private entities: Map<string, Entity> = new Map();

  private getTileKey(localX: number, localY: number): string {
    return `${localX},${localY}`;
  }

  public setTile(localX: number, localY: number, tile: Tile): void {
    if (localX < 0 || localX >= Chunk.SIZE || localY < 0 || localY >= Chunk.SIZE) {
      throw new Error(`Tile coordinates out of bounds: (${localX}, ${localY})`);
    }
    this.tiles.set(this.getTileKey(localX, localY), tile);
  }

  public getTile(localX: number, localY: number): Tile | undefined {
    return this.tiles.get(this.getTileKey(localX, localY));
  }

  public addEntity(entity: Entity): void {
    this.entities.set(entity.id, entity);
  }

  public removeEntity(entityId: string): boolean {
    return this.entities.delete(entityId);
  }

  public getEntity(entityId: string): Entity | undefined {
    return this.entities.get(entityId);
  }

  public getAllEntities(): Entity[] {
    return Array.from(this.entities.values());
  }

  public getTiles(): Map<string, Tile> {
    return new Map(this.tiles);
  }

  public getPosition(): { x: number; y: number } {
    return { x: this.x, y: this.y };
  }
}
