import { Vec2D } from '@vg2/core';

export enum ClientEvent {
  MOVE = 'c2s:move',
  INTERACT = 'c2s:interact',
  CHAT = 'c2s:chat',
  JOIN_WORLD = 'c2s:join_world',
  LEAVE_WORLD = 'c2s:leave_world',
}

export enum ServerEvent {
  CHUNK_UPDATE = 's2c:chunk_update',
  PLAYER_JOINED = 's2c:player_joined',
  PLAYER_LEFT = 's2c:player_left',
  PLAYER_MOVED = 's2c:player_moved',
  CHAT_MESSAGE = 's2c:chat_message',
  ERROR = 's2c:error',
  WORLD_STATE = 's2c:world_state',
}

export interface C2SMovePayload {
  playerId: string;
  position: Vec2D;
  sequence: number;
}

export interface C2SInteractPayload {
  playerId: string;
  targetId: string;
  interactionType: string;
  position: Vec2D;
}

export interface C2SChatPayload {
  playerId: string;
  message: string;
  channel: 'global' | 'world' | 'whisper';
  targetId?: string;
}

export interface C2SJoinWorldPayload {
  playerId: string;
  worldId: string;
  spawnPoint?: Vec2D;
}

export interface C2SLeaveWorldPayload {
  playerId: string;
  worldId: string;
}

export interface S2CChunkUpdatePayload {
  chunkX: number;
  chunkY: number;
  tiles: Array<{
    x: number;
    y: number;
    type: string;
    solid: boolean;
  }>;
  entities: Array<{
    id: string;
    type: string;
    position: Vec2D;
  }>;
}

export interface S2CPlayerJoinedPayload {
  player: {
    id: string;
    name: string;
    position: Vec2D;
  };
  worldId: string;
}

export interface S2CPlayerLeftPayload {
  playerId: string;
  worldId: string;
}

export interface S2CPlayerMovedPayload {
  playerId: string;
  position: Vec2D;
  worldId: string;
  sequence: number;
}

export interface S2CChatMessagePayload {
  playerId: string;
  playerName: string;
  message: string;
  channel: 'global' | 'world' | 'whisper';
  timestamp: number;
}

export interface S2CErrorPayload {
  code: string;
  message: string;
  details?: unknown;
}

export interface S2CWorldStatePayload {
  worldId: string;
  worldName: string;
  players: number;
  chunks: Array<{
    x: number;
    y: number;
  }>;
}
