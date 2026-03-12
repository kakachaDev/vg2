import { describe, it, expect } from 'vitest';
import { Chunk } from '../world/chunk';
import { Vec2D } from '@vg2/core';

describe('Chunk', () => {
  it('should create chunk with coordinates', () => {
    const chunk = new Chunk(1, 2);
    expect(chunk.x).toBe(1);
    expect(chunk.y).toBe(2);
    expect(chunk.getPosition()).toEqual({ x: 1, y: 2 });
  });

  it('should set and get tiles', () => {
    const chunk = new Chunk(0, 0);
    const tile = { type: 'grass', solid: false };
    
    chunk.setTile(5, 5, tile);
    expect(chunk.getTile(5, 5)).toBe(tile);
  });

  it('should throw error for out of bounds tiles', () => {
    const chunk = new Chunk(0, 0);
    const tile = { type: 'grass', solid: false };
    
    expect(() => chunk.setTile(-1, 5, tile)).toThrow();
    expect(() => chunk.setTile(16, 5, tile)).toThrow();
  });

  it('should add and get entities', () => {
    const chunk = new Chunk(0, 0);
    const entity = {
      id: '1',
      position: new Vec2D(10, 10)
    };
    
    chunk.addEntity(entity);
    expect(chunk.getEntity('1')).toBe(entity);
    expect(chunk.getAllEntities()).toContain(entity);
  });

  it('should remove entities', () => {
    const chunk = new Chunk(0, 0);
    const entity = {
      id: '1',
      position: new Vec2D(10, 10)
    };
    
    chunk.addEntity(entity);
    expect(chunk.removeEntity('1')).toBe(true);
    expect(chunk.getEntity('1')).toBeUndefined();
  });
});
