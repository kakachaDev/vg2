import { describe, it, expect } from 'vitest';
import { Vec2D } from '../vec2d';

describe('Vec2D', () => {
  it('should create a vector with given coordinates', () => {
    const v = new Vec2D(1, 2);
    expect(v.x).toBe(1);
    expect(v.y).toBe(2);
  });

  it('should add two vectors correctly', () => {
    const v1 = new Vec2D(1, 2);
    const v2 = new Vec2D(3, 4);
    const result = v1.add(v2);
    expect(result.x).toBe(4);
    expect(result.y).toBe(6);
  });

  it('should subtract two vectors correctly', () => {
    const v1 = new Vec2D(5, 7);
    const v2 = new Vec2D(2, 3);
    const result = v1.sub(v2);
    expect(result.x).toBe(3);
    expect(result.y).toBe(4);
  });

  it('should check equality correctly', () => {
    const v1 = new Vec2D(1, 2);
    const v2 = new Vec2D(1, 2);
    const v3 = new Vec2D(2, 1);
    expect(v1.eq(v2)).toBe(true);
    expect(v1.eq(v3)).toBe(false);
  });

  it('should calculate distance correctly', () => {
    const v1 = new Vec2D(0, 0);
    const v2 = new Vec2D(3, 4);
    expect(v1.distance(v2)).toBe(5);
  });

  it('should return string representation', () => {
    const v = new Vec2D(1, 2);
    expect(v.toString()).toBe('Vec2D(1, 2)');
  });

  it('should clone vector correctly', () => {
    const v1 = new Vec2D(1, 2);
    const v2 = v1.clone();
    expect(v2.x).toBe(1);
    expect(v2.y).toBe(2);
    expect(v1).not.toBe(v2);
    expect(v1.eq(v2)).toBe(true);
  });
});
