import { Vec2D } from './vec2d.js';

export enum Direction {
  North = 'north',
  South = 'south',
  East = 'east',
  West = 'west'
}

export interface Entity {
  id: string;
  position: Vec2D;
}

export interface Player extends Entity {
  name: string;
  sessionId: string;
}

export interface World {
  id: string;
  name: string;
  entities: Map<string, Entity>;
}
