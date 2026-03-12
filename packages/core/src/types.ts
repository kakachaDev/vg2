import { Vec2D } from './vec2d.js';

export enum Direction {
  North = 'north',
  South = 'south',
  East = 'east',
  West = 'west'
}

export interface Entity {
  id: string;
  type: string;
  position: Vec2D;
}

export class Player implements Entity {
  public readonly id: string;
  public readonly type: string = 'player';
  public position: Vec2D;
  public name: string;
  public sessionId?: string;
  public worldId?: string;

  constructor(id: string, name: string, position: Vec2D) {
    this.id = id;
    this.name = name;
    this.position = position;
  }
}

export interface IWorld {
  id: string;
  name: string;
  entities: Map<string, Entity>;
  addEntity(entity: Entity): void;
  removeEntity(entityId: string): boolean;
  getEntity(id: string): Entity | undefined;
  getPlayers(): Player[];
}
