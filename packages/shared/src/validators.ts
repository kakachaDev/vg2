import { z } from 'zod';

export const Vec2DSchema = z.object({
  x: z.number(),
  y: z.number()
});

export const movePayloadSchema = z.object({
  playerId: z.string(),
  position: Vec2DSchema,
  sequence: z.number().int().positive()
});

export const chatPayloadSchema = z.object({
  playerId: z.string(),
  message: z.string().min(1).max(256),
  channel: z.enum(['global', 'world', 'whisper']),
  targetId: z.string().optional()
});

export const joinWorldPayloadSchema = z.object({
  playerId: z.string(),
  worldId: z.string(),
  spawnPoint: Vec2DSchema.optional()
});

export const leaveWorldPayloadSchema = z.object({
  playerId: z.string(),
  worldId: z.string()
});

export const interactPayloadSchema = z.object({
  playerId: z.string(),
  targetId: z.string(),
  interactionType: z.string(),
  position: Vec2DSchema
});

export const vec2DSchema = Vec2DSchema;

export type C2SMovePayload = z.infer<typeof movePayloadSchema>;
export type C2SChatPayload = z.infer<typeof chatPayloadSchema>;
export type C2SJoinWorldPayload = z.infer<typeof joinWorldPayloadSchema>;
export type C2SLeaveWorldPayload = z.infer<typeof leaveWorldPayloadSchema>;
export type C2SInteractPayload = z.infer<typeof interactPayloadSchema>;
