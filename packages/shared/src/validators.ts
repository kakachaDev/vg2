import { z } from 'zod';

export const Vec2DSchema = z.object({
  x: z.number(),
  y: z.number()
});

export const C2SMovePayloadSchema = z.object({
  playerId: z.string(),
  position: Vec2DSchema,
  sequence: z.number().int().positive()
});

export const C2SInteractPayloadSchema = z.object({
  playerId: z.string(),
  targetId: z.string(),
  interactionType: z.string(),
  position: Vec2DSchema
});

export const C2SChatPayloadSchema = z.object({
  playerId: z.string(),
  message: z.string().min(1).max(256),
  channel: z.enum(['global', 'world', 'whisper']),
  targetId: z.string().optional()
});

export const C2SJoinWorldPayloadSchema = z.object({
  playerId: z.string(),
  worldId: z.string(),
  spawnPoint: Vec2DSchema.optional()
});

export const C2SLeaveWorldPayloadSchema = z.object({
  playerId: z.string(),
  worldId: z.string()
});

export type C2SMovePayload = z.infer<typeof C2SMovePayloadSchema>;
export type C2SInteractPayload = z.infer<typeof C2SInteractPayloadSchema>;
export type C2SChatPayload = z.infer<typeof C2SChatPayloadSchema>;
export type C2SJoinWorldPayload = z.infer<typeof C2SJoinWorldPayloadSchema>;
export type C2SLeaveWorldPayload = z.infer<typeof C2SLeaveWorldPayloadSchema>;
