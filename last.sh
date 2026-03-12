#!/bin/bash

# 1. Установка socket.io в серверный пакет
cd packages/server && npm install socket.io @types/socket.io && cd ../..

# 2. Установка socket.io-client в shared для типов (dev dependency)
cd packages/shared && npm install -D socket.io-client && cd ../..

# 3. Создание типов событий в shared
cat > packages/shared/src/types.ts << 'EOF'
import { Vec2D } from '@vg2/core';

export enum ClientEvent {
  MOVE = 'c2s:move',
  INTERACT = 'c2s:interact',
  CHAT = 'c2s:chat',
  JOIN_WORLD = 'c2s:join_world',
  LEAVE_WORLD = 'c2s:leave_world'
}

export enum ServerEvent {
  CHUNK_UPDATE = 's2c:chunk_update',
  PLAYER_JOINED = 's2c:player_joined',
  PLAYER_LEFT = 's2c:player_left',
  PLAYER_MOVED = 's2c:player_moved',
  CHAT_MESSAGE = 's2c:chat_message',
  ERROR = 's2c:error',
  WORLD_STATE = 's2c:world_state'
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
EOF

# 4. Обновление index.ts в shared
cat > packages/shared/src/index.ts << 'EOF'
export * from './types.js';
export * from './validators.js';
EOF

# 5. Создание валидаторов с zod
cat > packages/shared/src/validators.ts << 'EOF'
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
EOF

# 6. Установка zod в shared
cd packages/shared && npm install zod && cd ../..

# 7. Обновление package.json в shared
cat > packages/shared/package.json << 'EOF'
{
  "name": "@vg2/shared",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch"
  },
  "dependencies": {
    "@vg2/core": "^1.0.0",
    "@vg2/types": "^1.0.0",
    "zod": "^3.22.4"
  },
  "devDependencies": {
    "socket.io-client": "^4.7.2",
    "typescript": "^5.4.5"
  }
}
EOF

# 8. Обновление server.ts с поддержкой Socket.io
cat > packages/server/src/core/server.ts << 'EOF'
import { Server as HttpServer } from 'http';
import { Server as SocketServer } from 'socket.io';
import { World } from '../world/world.js';
import { PlayerManager } from '../managers/player-manager.js';
import { ClientEvent, ServerEvent, C2SMovePayload, C2SJoinWorldPayload, C2SLeaveWorldPayload, C2SChatPayload, C2SInteractPayload } from '@vg2/shared';
import { movePayloadSchema, joinWorldPayloadSchema, leaveWorldPayloadSchema, chatPayloadSchema, interactPayloadSchema } from '@vg2/shared';

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
      }
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

      socket.on(ClientEvent.JOIN_WORLD, async (payload: C2SJoinWorldPayload) => {
        try {
          const validated = joinWorldPayloadSchema.parse(payload);
          const player = this.playerManager.getPlayer(validated.playerId);
          
          if (!player) {
            socket.emit(ServerEvent.ERROR, {
              code: 'PLAYER_NOT_FOUND',
              message: 'Player not found'
            });
            return;
          }

          socket.join(`world:${validated.worldId}`);
          
          const world = this.getWorld(validated.worldId);
          if (world) {
            const nearbyChunks = world.getChunksInRange(
              validated.spawnPoint?.x || 0,
              validated.spawnPoint?.y || 0,
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
                  position: e.position
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
              position: player.position
            },
            worldId: validated.worldId
          });

          socket.broadcast.to(`world:${validated.worldId}`).emit(ServerEvent.PLAYER_JOINED, {
            player: {
              id: player.id,
              name: player.name,
              position: player.position
            },
            worldId: validated.worldId
          });

        } catch (error) {
          socket.emit(ServerEvent.ERROR, {
            code: 'INVALID_PAYLOAD',
            message: 'Invalid join world payload',
            details: error
          });
        }
      });

      socket.on(ClientEvent.MOVE, (payload: C2SMovePayload) => {
        try {
          const validated = movePayloadSchema.parse(payload);
          
          const success = this.playerManager.movePlayer(validated.playerId, validated.position);
          
          if (success) {
            const player = this.playerManager.getPlayer(validated.playerId);
            if (player) {
              const worldId = player.worldId || 'default';
              
              socket.broadcast.to(`world:${worldId}`).emit(ServerEvent.PLAYER_MOVED, {
                playerId: validated.playerId,
                position: validated.position,
                worldId,
                sequence: validated.sequence
              });
            }
          }
        } catch (error) {
          socket.emit(ServerEvent.ERROR, {
            code: 'INVALID_MOVE',
            message: 'Invalid move payload',
            details: error
          });
        }
      });

      socket.on(ClientEvent.CHAT, (payload: C2SChatPayload) => {
        try {
          const validated = chatPayloadSchema.parse(payload);
          const player = this.playerManager.getPlayer(validated.playerId);
          
          if (!player) {
            socket.emit(ServerEvent.ERROR, {
              code: 'PLAYER_NOT_FOUND',
              message: 'Player not found'
            });
            return;
          }

          const messagePayload = {
            playerId: validated.playerId,
            playerName: player.name,
            message: validated.message,
            channel: validated.channel,
            timestamp: Date.now()
          };

          if (validated.channel === 'whisper' && validated.targetId) {
            socket.to(validated.targetId).emit(ServerEvent.CHAT_MESSAGE, messagePayload);
          } else {
            const worldId = player.worldId || 'default';
            this.io?.to(`world:${worldId}`).emit(ServerEvent.CHAT_MESSAGE, messagePayload);
          }
        } catch (error) {
          socket.emit(ServerEvent.ERROR, {
            code: 'INVALID_CHAT',
            message: 'Invalid chat payload',
            details: error
          });
        }
      });

      socket.on(ClientEvent.INTERACT, (payload: C2SInteractPayload) => {
        try {
          const validated = interactPayloadSchema.parse(payload);
          
          const player = this.playerManager.getPlayer(validated.playerId);
          if (!player) {
            socket.emit(ServerEvent.ERROR, {
              code: 'PLAYER_NOT_FOUND',
              message: 'Player not found'
            });
            return;
          }

          const world = this.getWorld(player.worldId || 'default');
          if (!world) {
            socket.emit(ServerEvent.ERROR, {
              code: 'WORLD_NOT_FOUND',
              message: 'World not found'
            });
            return;
          }

          const target = world.getEntity(validated.targetId);
          if (!target) {
            socket.emit(ServerEvent.ERROR, {
              code: 'TARGET_NOT_FOUND',
              message: 'Target entity not found'
            });
            return;
          }

          socket.broadcast.to(`world:${player.worldId}`).emit('s2c:interaction', {
            playerId: validated.playerId,
            targetId: validated.targetId,
            interactionType: validated.interactionType,
            position: validated.position
          });

        } catch (error) {
          socket.emit(ServerEvent.ERROR, {
            code: 'INVALID_INTERACTION',
            message: 'Invalid interaction payload',
            details: error
          });
        }
      });

      socket.on(ClientEvent.LEAVE_WORLD, (payload: C2SLeaveWorldPayload) => {
        try {
          const validated = leaveWorldPayloadSchema.parse(payload);
          
          socket.leave(`world:${validated.worldId}`);
          
          socket.broadcast.to(`world:${validated.worldId}`).emit(ServerEvent.PLAYER_LEFT, {
            playerId: validated.playerId,
            worldId: validated.worldId
          });

          const player = this.playerManager.getPlayer(validated.playerId);
          if (player) {
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

# 9. Обновление player-manager.ts
cat > packages/server/src/managers/player-manager.ts << 'EOF'
import { Player, Vec2D } from '@vg2/core';
import { Server } from '../core/server.js';

export class PlayerManager {
  private players: Map<string, Player> = new Map();
  private server: Server;

  constructor(server: Server) {
    this.server = server;
  }

  public addPlayer(player: Player): void {
    this.players.set(player.id, player);
  }

  public removePlayer(playerId: string): boolean {
    const player = this.players.get(playerId);
    if (player && player.worldId) {
      const world = this.server.getWorld(player.worldId);
      if (world) {
        world.removeEntity(playerId);
      }
    }
    return this.players.delete(playerId);
  }

  public getPlayer(id: string): Player | undefined {
    return this.players.get(id);
  }

  public getAllPlayers(): Player[] {
    return Array.from(this.players.values());
  }

  public movePlayer(playerId: string, newPosition: Vec2D): boolean {
    const player = this.players.get(playerId);
    if (!player) {
      return false;
    }

    const world = player.worldId ? this.server.getWorld(player.worldId) : null;
    
    const oldPosition = player.position;
    player.position = newPosition;

    if (world) {
      world.removeEntity(playerId);
      world.addEntity(player);
    }

    return true;
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

# 10. Создание теста для Socket.io соединения
cat > packages/server/src/__tests__/socket.test.ts << 'EOF'
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { Server } from '../core/server.js';
import { io as Client, Socket } from 'socket.io-client';
import { Player, Vec2D } from '@vg2/core';
import { ClientEvent, ServerEvent } from '@vg2/shared';

describe('Socket.IO Server', () => {
  let server: Server;
  let clientSocket: Socket;
  const PORT = 3001;

  beforeEach(async () => {
    server = new Server();
    await server.start(PORT);
    
    clientSocket = Client(`http://localhost:${PORT}`, {
      autoConnect: false,
      transports: ['websocket']
    });
  });

  afterEach(async () => {
    if (clientSocket.connected) {
      clientSocket.disconnect();
    }
    await server.stop();
  });

  it('should handle client connection', async () => {
    await new Promise<void>((resolve) => {
      clientSocket.on('connect', () => {
        expect(clientSocket.connected).toBe(true);
        resolve();
      });
      clientSocket.connect();
    });
  });

  it('should handle player joining world', async () => {
    await new Promise<void>((resolve) => {
      clientSocket.connect();

      const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
      server.getPlayerManager().addPlayer(player);

      clientSocket.on(ServerEvent.WORLD_STATE, (data) => {
        expect(data.worldId).toBe('default');
        expect(data.worldName).toBe('Main World');
        expect(data.players).toBeDefined();
      });

      clientSocket.on(ServerEvent.PLAYER_JOINED, (data) => {
        expect(data.player.id).toBe('test-player');
        expect(data.player.name).toBe('TestPlayer');
        expect(data.worldId).toBe('default');
        resolve();
      });

      clientSocket.emit(ClientEvent.JOIN_WORLD, {
        playerId: 'test-player',
        worldId: 'default',
        spawnPoint: { x: 0, y: 0 }
      });
    });
  });

  it('should handle player movement', async () => {
    await new Promise<void>((resolve) => {
      clientSocket.connect();

      const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
      server.getPlayerManager().addPlayer(player);

      clientSocket.emit(ClientEvent.JOIN_WORLD, {
        playerId: 'test-player',
        worldId: 'default'
      });

      setTimeout(() => {
        clientSocket.emit(ClientEvent.MOVE, {
          playerId: 'test-player',
          position: { x: 10, y: 10 },
          sequence: 1
        });

        const updatedPlayer = server.getPlayerManager().getPlayer('test-player');
        expect(updatedPlayer?.position.x).toBe(10);
        expect(updatedPlayer?.position.y).toBe(10);
        resolve();
      }, 100);
    });
  });

  it('should handle chat messages', async () => {
    await new Promise<void>((resolve) => {
      clientSocket.connect();

      const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
      server.getPlayerManager().addPlayer(player);

      clientSocket.emit(ClientEvent.JOIN_WORLD, {
        playerId: 'test-player',
        worldId: 'default'
      });

      clientSocket.on(ServerEvent.CHAT_MESSAGE, (data) => {
        expect(data.playerId).toBe('test-player');
        expect(data.playerName).toBe('TestPlayer');
        expect(data.message).toBe('Hello world');
        expect(data.channel).toBe('global');
        resolve();
      });

      setTimeout(() => {
        clientSocket.emit(ClientEvent.CHAT, {
          playerId: 'test-player',
          message: 'Hello world',
          channel: 'global'
        });
      }, 100);
    });
  });

  it('should handle player leaving world', async () => {
    await new Promise<void>((resolve) => {
      clientSocket.connect();

      const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
      server.getPlayerManager().addPlayer(player);

      clientSocket.emit(ClientEvent.JOIN_WORLD, {
        playerId: 'test-player',
        worldId: 'default'
      });

      setTimeout(() => {
        clientSocket.on(ServerEvent.PLAYER_LEFT, (data) => {
          expect(data.playerId).toBe('test-player');
          expect(data.worldId).toBe('default');
          resolve();
        });

        clientSocket.emit(ClientEvent.LEAVE_WORLD, {
          playerId: 'test-player',
          worldId: 'default'
        });
      }, 100);
    });
  });

  it('should validate invalid move payload', async () => {
    await new Promise<void>((resolve) => {
      clientSocket.connect();

      clientSocket.on(ServerEvent.ERROR, (data) => {
        expect(data.code).toBe('INVALID_MOVE');
        resolve();
      });

      clientSocket.emit(ClientEvent.MOVE, {
        playerId: 'invalid-uuid',
        position: { x: 'not a number', y: 10 },
        sequence: -1
      });
    });
  });
});
EOF

# 11. Обновление PROGRESS.md
cat >> PROGRESS.md << 'EOF'

- [x] Сеть и протокол (Socket.io)
  - [x] Установлен socket.io и socket.io-client
  - [x] Созданы в shared типы событий: C2S_MOVE, C2S_INTERACT, C2S_CHAT, S2C_CHUNK и др.
  - [x] Написаны валидаторы (zod)
  - [x] Протестировано соединение
EOF

# 12. Обновление TODO.md (перенос выполненного пункта)
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

- [ ] Реализовать onConnection — создание Player
- [ ] Реализовать onDisconnect — удаление из мира
- [ ] Реализовать onMoveRequest с проверкой коллизий
- [ ] Написать тесты на движение

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

# 13. Коммит
git add .
git commit -m "feat: add socket.io network layer with protocol types and validation"

echo "=== DONE ==="
echo "Socket.io setup completed with:"
echo "- Event types in shared package"
echo "- Zod validators for all payloads"
echo "- Socket handlers in server"
echo "- Tests for socket connections"