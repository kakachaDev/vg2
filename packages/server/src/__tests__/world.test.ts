import { describe, it, expect, beforeEach } from 'vitest';
import { World } from '../world/world';
import { Chunk } from '../world/chunk';
import { Vec2D } from '@vg2/core';

describe('World', () => {
  let world: World;

  beforeEach(() => {
    world = new World('test', 'Test World');
  });

  it('should create world with correct properties', () => {
    expect(world.id).toBe('test');
    expect(world.name).toBe('Test World');
    expect(world.getAllEntities()).toEqual([]);
  });

  it('should add and get entity', () => {
    const entity = {
      id: '1',
      position: new Vec2D(10, 10),
    };

    world.addEntity(entity);
    expect(world.getEntity('1')).toBe(entity);
    expect(world.getAllEntities()).toContain(entity);
  });

  it('should remove entity', () => {
    const entity = {
      id: '1',
      position: new Vec2D(10, 10),
    };

    world.addEntity(entity);
    expect(world.removeEntity('1')).toBe(true);
    expect(world.getEntity('1')).toBeUndefined();
  });

  it('should get and create chunks', () => {
    const chunk = world.getChunk(0, 0);
    expect(chunk).toBeInstanceOf(Chunk);
    expect(chunk.x).toBe(0);
    expect(chunk.y).toBe(0);

    const sameChunk = world.getChunk(0, 0);
    expect(sameChunk).toBe(chunk);
  });

  it('should get chunks in range', () => {
    const chunks = world.getChunksInRange(0, 0, 1);
    expect(chunks.length).toBe(9);
  });
});
