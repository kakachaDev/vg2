import { z } from 'zod';
import { Vec2D } from '@vg2/core';

export const vec2DSchema = z.object({
  x: z.number(),
  y: z.number()
});

export const movePayloadSchema = z.object({
  playerId: z.string().uuid(),
  position: vec2DSchema,
  sequence: z.number().int().positive()
});

export const interactPayloadSchema = z.object({
  playerId: z.string().uuid(),
  targetId: z.string().uuid(),
  interactionType: z.string().min(1),
  position: vec2DSchema
});

export const chatPayloadSchema = z.object({
  playerId: z.string().uuid(),
  message: z.string().min(1).max(256),
  channel: z.enum(['global', 'world', 'whisper']),
  targetId: z.string().uuid().optional()
});

export const joinWorldPayloadSchema = z.object({
  playerId: z.string().uuid(),
  worldId: z.string().min(1),
  spawnPoint: vec2DSchema.optional()
});

export const leaveWorldPayloadSchema = z.object({
  playerId: z.string().uuid(),
  worldId: z.string().min(1)
});

export const chunkUpdateSchema = z.object({
  chunkX: z.number().int(),
  chunkY: z.number().int(),
  tiles: z.array(z.object({
    x: z.number().int().min(0).max(15),
    y: z.number().int().min(0).max(15),
    type: z.string(),
    solid: z.boolean()
  })),
  entities: z.array(z.object({
    id: z.string().uuid(),
    type: z.string(),
    position: vec2DSchema
  }))
});

export const playerJoinedSchema = z.object({
  player: z.object({
    id: z.string().uuid(),
    name: z.string().min(1).max(32),
    position: vec2DSchema
  }),
  worldId: z.string().min(1)
});

export const playerLeftSchema = z.object({
  playerId: z.string().uuid(),
  worldId: z.string().min(1)
});

export const playerMovedSchema = z.object({
  playerId: z.string().uuid(),
  position: vec2DSchema,
  worldId: z.string().min(1),
  sequence: z.number().int().positive()
});

export const chatMessageSchema = z.object({
  playerId: z.string().uuid(),
  playerName: z.string().min(1).max(32),
  message: z.string().min(1).max(256),
  channel: z.enum(['global', 'world', 'whisper']),
  timestamp: z.number().int().positive()
});

export const errorSchema = z.object({
  code: z.string(),
  message: z.string(),
  details: z.unknown().optional()
});

export const worldStateSchema = z.object({
  worldId: z.string().min(1),
  worldName: z.string(),
  players: z.number().int().min(0),
  chunks: z.array(z.object({
    x: z.number().int(),
    y: z.number().int()
  }))
});
