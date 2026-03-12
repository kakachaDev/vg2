import { describe, it, expect } from 'vitest';
import {
  Vec2DSchema,
  movePayloadSchema,
  chatPayloadSchema,
  joinWorldPayloadSchema,
  leaveWorldPayloadSchema,
  interactPayloadSchema,
} from '../validators.js';

describe('Validators', () => {
  it('should validate Vec2D', () => {
    const valid = { x: 10, y: 20 };
    expect(Vec2DSchema.parse(valid)).toEqual(valid);

    const invalid = { x: '10', y: 20 };
    expect(() => Vec2DSchema.parse(invalid)).toThrow();
  });

  it('should validate move payload', () => {
    const valid = {
      playerId: 'test-player',
      position: { x: 10, y: 20 },
      sequence: 1,
    };
    expect(movePayloadSchema.parse(valid)).toEqual(valid);

    const invalidSequence = { ...valid, sequence: 0 };
    expect(() => movePayloadSchema.parse(invalidSequence)).toThrow();

    const missingField = { playerId: 'test-player', position: { x: 10, y: 20 } };
    expect(() => movePayloadSchema.parse(missingField)).toThrow();
  });

  it('should validate chat payload', () => {
    const valid = {
      playerId: 'test-player',
      message: 'Hello world',
      channel: 'global',
    };
    expect(chatPayloadSchema.parse(valid)).toEqual(valid);

    const validWhisper = {
      playerId: 'test-player',
      message: 'Hi',
      channel: 'whisper',
      targetId: 'target-player',
    };
    expect(chatPayloadSchema.parse(validWhisper)).toEqual(validWhisper);

    const longMessage = { ...valid, message: 'a'.repeat(257) };
    expect(() => chatPayloadSchema.parse(longMessage)).toThrow();
  });

  it('should validate join world payload', () => {
    const valid = {
      playerId: 'test-player',
      worldId: 'default',
      spawnPoint: { x: 0, y: 0 },
    };
    expect(joinWorldPayloadSchema.parse(valid)).toEqual(valid);

    const validWithoutSpawn = {
      playerId: 'test-player',
      worldId: 'default',
    };
    expect(joinWorldPayloadSchema.parse(validWithoutSpawn)).toEqual(validWithoutSpawn);
  });

  it('should validate leave world payload', () => {
    const valid = {
      playerId: 'test-player',
      worldId: 'default',
    };
    expect(leaveWorldPayloadSchema.parse(valid)).toEqual(valid);
  });

  it('should validate interact payload', () => {
    const valid = {
      playerId: 'test-player',
      targetId: 'target-entity',
      interactionType: 'attack',
      position: { x: 10, y: 20 },
    };
    expect(interactPayloadSchema.parse(valid)).toEqual(valid);
  });
});
