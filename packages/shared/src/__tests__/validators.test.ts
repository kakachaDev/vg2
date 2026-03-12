import { describe, it, expect } from 'vitest';
import { 
  movePayloadSchema, 
  chatPayloadSchema, 
  joinWorldPayloadSchema,
  vec2DSchema 
} from '../validators.js';

describe('Validators', () => {
  it('should validate Vec2D', () => {
    const valid = { x: 10, y: 20 };
    expect(vec2DSchema.parse(valid)).toEqual(valid);
    
    expect(() => vec2DSchema.parse({ x: '10', y: 20 })).toThrow();
    expect(() => vec2DSchema.parse({ x: 10 })).toThrow();
  });

  it('should validate move payload', () => {
    const valid = {
      playerId: '123e4567-e89b-12d3-a456-426614174000',
      position: { x: 10, y: 20 },
      sequence: 1
    };
    expect(movePayloadSchema.parse(valid)).toEqual(valid);

    const invalidSequence = { ...valid, sequence: -1 };
    expect(() => movePayloadSchema.parse(invalidSequence)).toThrow();

    const invalidUuid = { ...valid, playerId: 'not-a-uuid' };
    expect(() => movePayloadSchema.parse(invalidUuid)).toThrow();
  });

  it('should validate chat payload', () => {
    const valid = {
      playerId: '123e4567-e89b-12d3-a456-426614174000',
      message: 'Hello world',
      channel: 'global' as const
    };
    expect(chatPayloadSchema.parse(valid)).toEqual(valid);

    const longMessage = { ...valid, message: 'a'.repeat(300) };
    expect(() => chatPayloadSchema.parse(longMessage)).toThrow();

    const invalidChannel = { ...valid, channel: 'invalid' };
    expect(() => chatPayloadSchema.parse(invalidChannel)).toThrow();
  });

  it('should validate join world payload', () => {
    const valid = {
      playerId: '123e4567-e89b-12d3-a456-426614174000',
      worldId: 'default'
    };
    expect(joinWorldPayloadSchema.parse(valid)).toEqual(valid);

    const withSpawn = {
      ...valid,
      spawnPoint: { x: 100, y: 200 }
    };
    expect(joinWorldPayloadSchema.parse(withSpawn)).toEqual(withSpawn);
  });
});
