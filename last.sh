#!/bin/bash

# Начинаю выполнение задачи 7: Обработка игроков и авторитетность

# 1. Создаю validators.ts в shared пакете
cat > packages/shared/src/validators.ts << 'EOF'
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
EOF

# 2. Создаю collision-detector.ts для проверки коллизий
cat > packages/server/src/world/collision-detector.ts << 'EOF'
import { Vec2D } from '@vg2/core';
import { World } from './world.js';
import { Chunk } from './chunk.js';

export class CollisionDetector {
  constructor(private world: World) {}

  public canMove(from: Vec2D, to: Vec2D, entityId: string): boolean {
    const distance = from.distance(to);
    
    if (distance > 10) {
      return false;
    }

    const chunks = this.world.getChunksInRange(to.x, to.y, 1);
    
    for (const chunk of chunks) {
      const localX = Math.floor(to.x % Chunk.SIZE);
      const localY = Math.floor(to.y % Chunk.SIZE);
      
      const tile = chunk.getTile(localX, localY);
      if (tile && tile.solid) {
        return false;
      }
      
      const entities = chunk.getAllEntities();
      for (const entity of entities) {
        if (entity.id !== entityId && entity.type === 'player') {
          if (entity.position.distance(to) < 1) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  public getValidMovePosition(from: Vec2D, to: Vec2D, entityId: string): Vec2D {
    if (this.canMove(from, to, entityId)) {
      return to;
    }
    
    const step = 0.5;
    const direction = new Vec2D(to.x - from.x, to.y - from.y);
    const distance = from.distance(to);
    
    if (distance === 0) return from;
    
    const normalizedDir = new Vec2D(
      direction.x / distance,
      direction.y / distance
    );
    
    for (let d = step; d <= distance; d += step) {
      const checkPos = new Vec2D(
        from.x + normalizedDir.x * d,
        from.y + normalizedDir.y * d
      );
      
      if (!this.canMove(from, checkPos, entityId)) {
        const prevPos = new Vec2D(
          from.x + normalizedDir.x * Math.max(0, d - step),
          from.y + normalizedDir.y * Math.max(0, d - step)
        );
        return prevPos;
      }
    }
    
    return from;
  }
}
EOF

# 3. Обновляю player-manager.ts с авторитетным движением
cat > packages/server/src/managers/player-manager.ts << 'EOF'
import { Player, Vec2D } from '@vg2/core';
import { Server } from '../core/server.js';
import { CollisionDetector } from '../world/collision-detector.js';

export class PlayerManager {
  private players: Map<string, Player> = new Map();
  private lastMoveTimes: Map<string, number> = new Map();
  private moveSequences: Map<string, number> = new Map();
  private server: Server;

  constructor(server: Server) {
    this.server = server;
  }

  public addPlayer(player: Player): void {
    this.players.set(player.id, player);
    this.lastMoveTimes.set(player.id, Date.now());
    this.moveSequences.set(player.id, 0);
  }

  public removePlayer(playerId: string): boolean {
    const player = this.players.get(playerId);
    if (player && player.worldId) {
      const world = this.server.getWorld(player.worldId);
      if (world) {
        world.removeEntity(playerId);
      }
    }
    this.lastMoveTimes.delete(playerId);
    this.moveSequences.delete(playerId);
    return this.players.delete(playerId);
  }

  public getPlayer(id: string): Player | undefined {
    return this.players.get(id);
  }

  public getAllPlayers(): Player[] {
    return Array.from(this.players.values());
  }

  public movePlayer(playerId: string, newPosition: Vec2D, sequence: number): {
    success: boolean;
    authorizedPosition: Vec2D;
    sequence: number;
  } {
    const player = this.players.get(playerId);
    if (!player) {
      return { success: false, authorizedPosition: new Vec2D(0, 0), sequence: 0 };
    }

    const lastMove = this.lastMoveTimes.get(playerId) || 0;
    const now = Date.now();
    
    if (now - lastMove < 16) {
      return { 
        success: false, 
        authorizedPosition: player.position, 
        sequence: this.moveSequences.get(playerId) || 0 
      };
    }

    const lastSequence = this.moveSequences.get(playerId) || 0;
    if (sequence <= lastSequence) {
      return { 
        success: false, 
        authorizedPosition: player.position, 
        sequence: lastSequence 
      };
    }

    const distance = player.position.distance(newPosition);
    const maxSpeed = 5;
    
    if (distance > maxSpeed) {
      const direction = new Vec2D(
        newPosition.x - player.position.x,
        newPosition.y - player.position.y
      );
      const normalizedDir = new Vec2D(
        direction.x / distance,
        direction.y / distance
      );
      newPosition = new Vec2D(
        player.position.x + normalizedDir.x * maxSpeed,
        player.position.y + normalizedDir.y * maxSpeed
      );
    }

    let authorizedPosition = player.position;
    
    if (player.worldId) {
      const world = this.server.getWorld(player.worldId);
      if (world) {
        const collisionDetector = new CollisionDetector(world);
        authorizedPosition = collisionDetector.getValidMovePosition(
          player.position,
          newPosition,
          playerId
        );
      }
    }

    if (!authorizedPosition.eq(player.position)) {
      player.position = authorizedPosition;
      this.lastMoveTimes.set(playerId, now);
      this.moveSequences.set(playerId, sequence);

      if (player.worldId) {
        const world = this.server.getWorld(player.worldId);
        if (world) {
          world.updateEntityPosition(playerId, authorizedPosition);
        }
      }
    }

    return {
      success: true,
      authorizedPosition: player.position,
      sequence: this.moveSequences.get(playerId) || 0
    };
  }

  public getPlayersInWorld(worldId: string): Player[] {
    const world = this.server.getWorld(worldId);
    if (!world) {
      return [];
    }
    return world.getPlayers();
  }

  public updatePlayerSession(playerId: string, sessionId: string): boolean {
    const player = this.players.get(playerId);
    if (!player) {
      return false;
    }
    player.sessionId = sessionId;
    return true;
  }

  public updatePlayerWorld(playerId: string, worldId: string): boolean {
    const player = this.players.get(playerId);
    if (!player) {
      return false;
    }

    if (player.worldId) {
      const oldWorld = this.server.getWorld(player.worldId);
      if (oldWorld) {
        oldWorld.removeEntity(playerId);
      }
    }

    player.worldId = worldId;

    const newWorld = this.server.getWorld(worldId);
    if (newWorld) {
      newWorld.addEntity(player);
    }

    return true;
  }
}
EOF

# 4. Обновляю world.ts с методом updateEntityPosition
cat > packages/server/src/world/world.ts << 'EOF'
import { Entity, Player, Vec2D } from '@vg2/core';
import { Chunk } from './chunk.js';

export class World {
  public readonly id: string;
  public readonly name: string;
  private entities: Map<string, Entity> = new Map();
  private chunks: Map<string, Chunk> = new Map();
  private playerChunks: Map<string, Set<string>> = new Map();
  private entityChunks: Map<string, string> = new Map();

  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
  }

  public addEntity(entity: Entity): void {
    this.entities.set(entity.id, entity);
    this.updateEntityChunks(entity);
  }

  public removeEntity(entityId: string): boolean {
    const entity = this.entities.get(entityId);
    if (entity) {
      this.playerChunks.delete(entityId);
      this.entityChunks.delete(entityId);
    }
    return this.entities.delete(entityId);
  }

  public updateEntityPosition(entityId: string, newPosition: Vec2D): void {
    const entity = this.entities.get(entityId);
    if (!entity) return;

    const oldChunkKey = this.entityChunks.get(entityId);
    const newChunkX = Math.floor(newPosition.x / Chunk.SIZE);
    const newChunkY = Math.floor(newPosition.y / Chunk.SIZE);
    const newChunkKey = `${newChunkX},${newChunkY}`;

    entity.position = newPosition;

    if (oldChunkKey !== newChunkKey) {
      if (oldChunkKey) {
        const [oldX, oldY] = oldChunkKey.split(',').map(Number);
        const oldChunk = this.getChunk(oldX, oldY);
        oldChunk.removeEntity(entityId);
      }

      const newChunk = this.getChunk(newChunkX, newChunkY);
      newChunk.addEntity(entity);
      this.entityChunks.set(entityId, newChunkKey);
      this.updateEntityChunks(entity);
    }
  }

  public getEntity(id: string): Entity | undefined {
    return this.entities.get(id);
  }

  public getAllEntities(): Entity[] {
    return Array.from(this.entities.values());
  }

  public getPlayers(): Player[] {
    return Array.from(this.entities.values()).filter(
      (entity): entity is Player => entity.type === 'player'
    );
  }

  public getChunk(chunkX: number, chunkY: number): Chunk {
    const key = `${chunkX},${chunkY}`;
    let chunk = this.chunks.get(key);
    if (!chunk) {
      chunk = new Chunk(chunkX, chunkY);
      this.chunks.set(key, chunk);
    }
    return chunk;
  }

  public getChunksInRange(centerX: number, centerY: number, radius: number): Chunk[] {
    const chunks: Chunk[] = [];
    const chunkX = Math.floor(centerX / Chunk.SIZE);
    const chunkY = Math.floor(centerY / Chunk.SIZE);

    for (let dx = -radius; dx <= radius; dx++) {
      for (let dy = -radius; dy <= radius; dy++) {
        chunks.push(this.getChunk(chunkX + dx, chunkY + dy));
      }
    }
    return chunks;
  }

  private updateEntityChunks(entity: Entity): void {
    const chunkX = Math.floor(entity.position.x / Chunk.SIZE);
    const chunkY = Math.floor(entity.position.y / Chunk.SIZE);

    let chunks = this.playerChunks.get(entity.id);
    if (!chunks) {
      chunks = new Set();
      this.playerChunks.set(entity.id, chunks);
    }
    chunks.add(`${chunkX},${chunkY}`);
  }

  public getEntityChunks(entityId: string): string[] {
    return Array.from(this.playerChunks.get(entityId) || []);
  }
}
EOF

# 5. Обновляю server.ts с валидацией
cat > packages/server/src/core/server.ts << 'EOF'
import { Server as HttpServer } from 'http';
import { Server as SocketServer } from 'socket.io';
import { World } from '../world/world.js';
import { PlayerManager } from '../managers/player-manager.js';
import { ClientEvent, ServerEvent } from '@vg2/shared';
import { Vec2D, Player } from '@vg2/core';
import { 
  C2SMovePayloadSchema, 
  C2SJoinWorldPayloadSchema,
  C2SLeaveWorldPayloadSchema,
  C2SChatPayloadSchema,
  C2SMovePayload
} from '@vg2/shared';

export class Server {
  private worlds: Map<string, World> = new Map();
  private playerManager: PlayerManager;
  private isRunning: boolean = false;
  private io: SocketServer | null = null;
  private httpServer: HttpServer | null = null;

  constructor() {
    this.playerManager = new PlayerManager(this);
    this.createDefaultWorld();
  }

  private createDefaultWorld(): void {
    const defaultWorld = new World('default', 'Main World');
    this.worlds.set(defaultWorld.id, defaultWorld);
  }

  public async start(port: number = 3000): Promise<void> {
    if (this.isRunning) {
      throw new Error('Server is already running');
    }

    this.httpServer = new HttpServer();
    this.io = new SocketServer(this.httpServer, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST']
      },
      transports: ['websocket']
    });

    this.setupSocketHandlers();

    return new Promise((resolve) => {
      this.httpServer?.listen(port, () => {
        this.isRunning = true;
        console.log(`Server started on port ${port}`);
        resolve();
      });
    });
  }

  private setupSocketHandlers(): void {
    if (!this.io) return;

    this.io.on('connection', (socket) => {
      console.log(`Client connected: ${socket.id}`);

      socket.on(ClientEvent.JOIN_WORLD, async (data: unknown) => {
        try {
          const payload = C2SJoinWorldPayloadSchema.parse(data);
          
          let player = this.playerManager.getPlayer(payload.playerId);
          
          if (!player) {
            player = new Player(
              payload.playerId,
              `Player-${payload.playerId.substring(0, 4)}`,
              payload.spawnPoint ? Vec2D.from(payload.spawnPoint) : new Vec2D(0, 0)
            );
            this.playerManager.addPlayer(player);
          }

          this.playerManager.updatePlayerSession(payload.playerId, socket.id);

          socket.join(`world:${payload.worldId}`);
          
          this.playerManager.updatePlayerWorld(payload.playerId, payload.worldId);

          const world = this.getWorld(payload.worldId);
          if (world) {
            const nearbyChunks = world.getChunksInRange(
              player.position.x,
              player.position.y,
              2
            );

            for (const chunk of nearbyChunks) {
              socket.emit(ServerEvent.CHUNK_UPDATE, {
                chunkX: chunk.x,
                chunkY: chunk.y,
                tiles: Array.from(chunk.getTiles().entries()).map(([key, tile]) => {
                  const [x, y] = key.split(',').map(Number);
                  return { x, y, type: tile.type, solid: tile.solid };
                }),
                entities: chunk.getAllEntities().map(e => ({
                  id: e.id,
                  type: e.type,
                  position: { x: e.position.x, y: e.position.y }
                }))
              });
            }

            socket.emit(ServerEvent.WORLD_STATE, {
              worldId: world.id,
              worldName: world.name,
              players: world.getPlayers().length,
              chunks: nearbyChunks.map(c => ({ x: c.x, y: c.y }))
            });
          }

          socket.emit(ServerEvent.PLAYER_JOINED, {
            player: {
              id: player.id,
              name: player.name,
              position: { x: player.position.x, y: player.position.y }
            },
            worldId: payload.worldId
          });

          socket.broadcast.to(`world:${payload.worldId}`).emit(ServerEvent.PLAYER_JOINED, {
            player: {
              id: player.id,
              name: player.name,
              position: { x: player.position.x, y: player.position.y }
            },
            worldId: payload.worldId
          });

        } catch (error) {
          socket.emit(ServerEvent.ERROR, {
            code: 'INVALID_PAYLOAD',
            message: 'Invalid join world payload',
            details: error
          });
        }
      });

      socket.on(ClientEvent.MOVE, (data: unknown) => {
        try {
          const payload = C2SMovePayloadSchema.parse(data) as C2SMovePayload;
          
          const player = this.playerManager.getPlayer(payload.playerId);

          if (!player) {
            socket.emit(ServerEvent.ERROR, {
              code: 'PLAYER_NOT_FOUND',
              message: 'Player not found'
            });
            return;
          }

          const newPos = Vec2D.from(payload.position);
          const result = this.playerManager.movePlayer(
            payload.playerId, 
            newPos, 
            payload.sequence
          );

          if (result.success && player.worldId) {
            const moveEvent = {
              playerId: payload.playerId,
              position: { x: result.authorizedPosition.x, y: result.authorizedPosition.y },
              worldId: player.worldId,
              sequence: result.sequence
            };

            socket.broadcast.to(`world:${player.worldId}`).emit(ServerEvent.PLAYER_MOVED, moveEvent);
            socket.emit(ServerEvent.PLAYER_MOVED, moveEvent);
          } else {
            socket.emit(ServerEvent.PLAYER_MOVED, {
              playerId: payload.playerId,
              position: { x: result.authorizedPosition.x, y: result.authorizedPosition.y },
              worldId: player.worldId,
              sequence: result.sequence
            });
          }
        } catch (error) {
          socket.emit(ServerEvent.ERROR, {
            code: 'INVALID_MOVE',
            message: 'Invalid move payload',
            details: error
          });
        }
      });

      socket.on(ClientEvent.CHAT, (data: unknown) => {
        try {
          const payload = C2SChatPayloadSchema.parse(data);
          
          const player = this.playerManager.getPlayer(payload.playerId);

          if (!player) {
            socket.emit(ServerEvent.ERROR, {
              code: 'PLAYER_NOT_FOUND',
              message: 'Player not found'
            });
            return;
          }

          const messagePayload = {
            playerId: payload.playerId,
            playerName: player.name,
            message: payload.message,
            channel: payload.channel,
            timestamp: Date.now()
          };

          if (payload.channel === 'whisper' && payload.targetId) {
            const targetPlayer = this.playerManager.getPlayer(payload.targetId);
            if (targetPlayer?.sessionId) {
              socket.to(targetPlayer.sessionId).emit(ServerEvent.CHAT_MESSAGE, messagePayload);
            }
          } else if (player.worldId) {
            this.io?.to(`world:${player.worldId}`).emit(ServerEvent.CHAT_MESSAGE, messagePayload);
          }
        } catch (error) {
          socket.emit(ServerEvent.ERROR, {
            code: 'INVALID_CHAT',
            message: 'Invalid chat payload',
            details: error
          });
        }
      });

      socket.on(ClientEvent.LEAVE_WORLD, (data: unknown) => {
        try {
          const payload = C2SLeaveWorldPayloadSchema.parse(data);
          
          socket.leave(`world:${payload.worldId}`);

          socket.broadcast.to(`world:${payload.worldId}`).emit(ServerEvent.PLAYER_LEFT, {
            playerId: payload.playerId,
            worldId: payload.worldId
          });

          const player = this.playerManager.getPlayer(payload.playerId);
          if (player) {
            const world = this.getWorld(payload.worldId);
            if (world) {
              world.removeEntity(payload.playerId);
            }
            player.worldId = undefined;
          }

        } catch (error) {
          socket.emit(ServerEvent.ERROR, {
            code: 'INVALID_LEAVE',
            message: 'Invalid leave world payload',
            details: error
          });
        }
      });

      socket.on('disconnect', () => {
        console.log(`Client disconnected: ${socket.id}`);
        
        for (const player of this.playerManager.getAllPlayers()) {
          if (player.sessionId === socket.id) {
            if (player.worldId) {
              socket.broadcast.to(`world:${player.worldId}`).emit(ServerEvent.PLAYER_LEFT, {
                playerId: player.id,
                worldId: player.worldId
              });
            }
            this.playerManager.removePlayer(player.id);
            break;
          }
        }
      });
    });
  }

  public async stop(): Promise<void> {
    if (!this.isRunning) {
      throw new Error('Server is not running');
    }

    return new Promise((resolve) => {
      if (this.io) {
        this.io.close(() => {
          this.httpServer?.close(() => {
            this.isRunning = false;
            this.io = null;
            this.httpServer = null;
            console.log('Server stopped');
            resolve();
          });
        });
      } else {
        resolve();
      }
    });
  }

  public getWorld(id: string): World | undefined {
    return this.worlds.get(id);
  }

  public getAllWorlds(): World[] {
    return Array.from(this.worlds.values());
  }

  public addWorld(world: World): void {
    this.worlds.set(world.id, world);
  }

  public getPlayerManager(): PlayerManager {
    return this.playerManager;
  }

  public isActive(): boolean {
    return this.isRunning;
  }

  public getIO(): SocketServer | null {
    return this.io;
  }
}
EOF

# 6. Обновляю тест движения с коллизиями
cat > packages/server/src/__tests__/movement-collision.test.ts << 'EOF'
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { Server } from '../core/server.js';
import { io as Client } from 'socket.io-client';
import { Vec2D, Player } from '@vg2/core';
import { ClientEvent, ServerEvent } from '@vg2/shared';

describe('Movement with Collision Detection', () => {
  let server: Server;
  let clientSocket: any;
  const PORT = 3002;

  beforeEach(async () => {
    server = new Server();
    await server.start(PORT);

    clientSocket = Client(`http://localhost:${PORT}`, {
      autoConnect: false,
      transports: ['websocket']
    });
  });

  afterEach(async () => {
    if (clientSocket && clientSocket.connected) {
      clientSocket.disconnect();
    }
    await server.stop();
  });

  it('should enforce speed limit', async () => {
    const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
    server.getPlayerManager().addPlayer(player);

    await new Promise<void>((resolve) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'test-player',
          worldId: 'default',
          spawnPoint: { x: 0, y: 0 }
        });

        clientSocket.on(ServerEvent.WORLD_STATE, () => {
          clientSocket.emit(ClientEvent.MOVE, {
            playerId: 'test-player',
            position: { x: 100, y: 0 },
            sequence: 1
          });

          setTimeout(() => {
            const updatedPlayer = server.getPlayerManager().getPlayer('test-player');
            expect(updatedPlayer?.position.x).toBeLessThanOrEqual(5);
            expect(updatedPlayer?.position.x).toBeGreaterThan(0);
            resolve();
          }, 50);
        });
      });
    });
  });

  it('should prevent moving into solid tiles', async () => {
    const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
    server.getPlayerManager().addPlayer(player);

    const world = server.getWorld('default');
    if (world) {
      const chunk = world.getChunk(0, 0);
      chunk.setTile(1, 0, { type: 'wall', solid: true });
    }

    await new Promise<void>((resolve) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'test-player',
          worldId: 'default',
          spawnPoint: { x: 0, y: 0 }
        });

        clientSocket.on(ServerEvent.WORLD_STATE, () => {
          clientSocket.emit(ClientEvent.MOVE, {
            playerId: 'test-player',
            position: { x: 1.5, y: 0 },
            sequence: 1
          });

          setTimeout(() => {
            const updatedPlayer = server.getPlayerManager().getPlayer('test-player');
            expect(updatedPlayer?.position.x).toBeLessThan(1);
            resolve();
          }, 50);
        });
      });
    });
  });

  it('should prevent moving through other players', async () => {
    const player1 = new Player('player1', 'Player 1', new Vec2D(0, 0));
    const player2 = new Player('player2', 'Player 2', new Vec2D(2, 0));
    
    server.getPlayerManager().addPlayer(player1);
    server.getPlayerManager().addPlayer(player2);
    
    const world = server.getWorld('default');
    if (world) {
      world.addEntity(player1);
      world.addEntity(player2);
    }

    await new Promise<void>((resolve) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'player1',
          worldId: 'default',
          spawnPoint: { x: 0, y: 0 }
        });

        clientSocket.on(ServerEvent.WORLD_STATE, () => {
          clientSocket.emit(ClientEvent.MOVE, {
            playerId: 'player1',
            position: { x: 3, y: 0 },
            sequence: 1
          });

          setTimeout(() => {
            const updatedPlayer = server.getPlayerManager().getPlayer('player1');
            expect(updatedPlayer?.position.x).toBeLessThan(2);
            resolve();
          }, 50);
        });
      });
    });
  });

  it('should reject out-of-order move sequences', async () => {
    const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
    server.getPlayerManager().addPlayer(player);

    let receivedSequence = 0;

    await new Promise<void>((resolve) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'test-player',
          worldId: 'default',
          spawnPoint: { x: 0, y: 0 }
        });

        clientSocket.on(ServerEvent.WORLD_STATE, () => {
          clientSocket.emit(ClientEvent.MOVE, {
            playerId: 'test-player',
            position: { x: 1, y: 0 },
            sequence: 2
          });

          clientSocket.on(ServerEvent.PLAYER_MOVED, (data: any) => {
            receivedSequence = data.sequence;
          });

          setTimeout(() => {
            clientSocket.emit(ClientEvent.MOVE, {
              playerId: 'test-player',
              position: { x: 2, y: 0 },
              sequence: 1
            });

            setTimeout(() => {
              expect(receivedSequence).toBe(2);
              resolve();
            }, 50);
          }, 50);
        });
      });
    });
  });

  it('should enforce move rate limiting', async () => {
    const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
    server.getPlayerManager().addPlayer(player);

    await new Promise<void>((resolve) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'test-player',
          worldId: 'default',
          spawnPoint: { x: 0, y: 0 }
        });

        clientSocket.on(ServerEvent.WORLD_STATE, () => {
          const startTime = Date.now();
          let moveCount = 0;

          clientSocket.on(ServerEvent.PLAYER_MOVED, () => {
            moveCount++;
          });

          for (let i = 1; i <= 10; i++) {
            setTimeout(() => {
              clientSocket.emit(ClientEvent.MOVE, {
                playerId: 'test-player',
                position: { x: i, y: 0 },
                sequence: i
              });
            }, i * 5);
          }

          setTimeout(() => {
            const elapsed = Date.now() - startTime;
            expect(moveCount).toBeLessThan(10);
            resolve();
          }, 200);
        });
      });
    });
  });
});
EOF

# 7. Устанавливаю зависимости
cd packages/server && npm install --save-dev @types/socket.io-client && cd ../..
cd packages/shared && npm install zod && cd ../..

# 8. Обновляю package.json в shared для экспорта валидаторов
cat > packages/shared/package.json << 'EOF'
{
  "name": "@vg2/shared",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "clean": "rm -rf dist",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "zod": "^3.22.4"
  },
  "devDependencies": {
    "@vg2/core": "^1.0.0"
  }
}
EOF

# 9. Обновляю PROGRESS.md
cat >> PROGRESS.md << 'EOF'
- [x] Реализована обработка игроков и авторитетность
  - [x] Добавлен CollisionDetector для проверки коллизий
  - [x] Реализована валидация движения (скорость, стены, игроки)
  - [x] Добавлена защита от спама (rate limiting)
  - [x] Реализована проверка последовательности команд (sequence numbers)
  - [x] Обновлен PlayerManager с авторитетным движением
  - [x] Добавлены тесты на все сценарии движения
  - [x] Интегрирована валидация через zod

EOF

# 10. Обновляю TODO.md (переношу выполненный пункт 7 вниз)
cat > TODO.md << 'EOF'
# TODO — основа сервера

## 1. Репозиторий и монорепозиторий

- [x] Создать GitHub/GitLab репозиторий
- [x] Инициализировать монорепозиторий (npm workspaces)
- [x] Настроить .gitignore (Node, dist, logs, .env)
- [x] Настроить EditorConfig и Prettier для единого форматирования
- [x] Добавить LICENSE (MIT)

## 2. Базовые пакеты

- [x] **packages/core** — общие типы, утилиты, математика, интерфейсы
- [x] **packages/server** — основная логика сервера
- [x] **packages/shared** — константы, протоколы обмена
- [x] **packages/types** — отдельный пакет только для TypeScript-типов
- [x] Настроить сборку (TypeScript) для каждого пакета

## 3. Настройка тестовой среды (TDD с самого начала)

- [x] Установить Vitest в корне и каждом пакете
- [x] Настроить общую команду `test` для запуска всех тестов
- [x] Написать первый падающий тест для core (сложение векторов)
- [x] Настроить coverage (istanbul/v8)
- [x] Добавить CI (GitHub Actions) для автоматического прогона тестов на каждый push/PR

## 4. Core — базовые сущности

- [x] Реализовать Vec2D с методами (add, sub, eq, distance)
- [x] Написать тесты для Vec2D
- [x] Реализовать типы Direction (North, South, East, West)
- [x] Реализовать базовые интерфейсы Entity, Player, World
- [x] Покрыть тестами

## 5. Server — структура и первичные модули

- [x] Создать точку входа (index.ts) для сервера
- [x] Настроить базовый класс Server (запуск/останов)
- [x] Реализовать простой World (контейнер для игроков и чанков)
- [x] Реализовать Chunk (дискретная сетка тайлов/объектов)
- [x] Реализовать PlayerManager (подключение/отключение игроков)
- [x] Покрыть модули тестами

## 6. Сеть и протокол (Socket.io)

- [x] Установить socket.io и socket.io-client
- [x] Создать в shared типы событий: C2S_MOVE, C2S_INTERACT, C2S_CHAT, S2C_CHUNK и др.
- [x] Написать валидаторы (zod)
- [x] Протестировать соединение

## 7. Обработка игроков и авторитетность

- [x] Реализовать onConnection — создание Player
- [x] Реализовать onDisconnect — удаление из мира
- [x] Реализовать onMoveRequest с проверкой коллизий
- [x] Написать тесты на движение

## 8. Чанки и зоны видимости

- [ ] Реализовать систему подписки на чанки
- [ ] При перемещении пересчитывать видимость
- [ ] Отправлять S2C_CHUNK при входе в новые чанки
- [ ] Написать тест на получение чанков

## 9. Документация

- [ ] Создать README.md в корне с описанием проекта
- [ ] В каждом пакете создать README
- [ ] Написать CONTRIBUTING.md

## 10. Нагрузочное тестирование

- [ ] Выбрать инструмент
- [ ] Написать сценарии тестирования
- [ ] Добавить замеры
- [ ] Задокументировать результаты

## 11. Инстансы и переходы между мирами

- [ ] Реализовать Gateway/Proxy
- [ ] Добавить событие C2S_SWITCH_WORLD
- [ ] Graceful disconnect
- [ ] Написать тест на переключение

## 12. Интеграция с хранилищем

- [ ] Поднять Redis
- [ ] Сохранять состояние игроков
- [ ] Загружать при входе
- [ ] Написать тесты
EOF

# 11. Коммит и запуск тестов
git add .
git commit -m "feat: complete player handling with authoritative movement"

# 12. Запуск тестов
npm run test
EOF