import { Server as HttpServer } from 'http';
import { Server as SocketServer } from 'socket.io';
import { World } from '../world/world.js';
import { PlayerManager } from '../managers/player-manager.js';
import { ClientEvent, ServerEvent } from '@vg2/shared';
import { Vec2D } from '@vg2/core';

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

      socket.on(ClientEvent.JOIN_WORLD, async (payload: any) => {
        try {
          const player = this.playerManager.getPlayer(payload.playerId);
          
          if (!player) {
            socket.emit(ServerEvent.ERROR, {
              code: 'PLAYER_NOT_FOUND',
              message: 'Player not found'
            });
            return;
          }

          socket.join(`world:${payload.worldId}`);
          player.worldId = payload.worldId;
          
          const world = this.getWorld(payload.worldId);
          if (world) {
            world.addEntity(player);
            
            const nearbyChunks = world.getChunksInRange(
              payload.spawnPoint?.x || 0,
              payload.spawnPoint?.y || 0,
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

      socket.on(ClientEvent.MOVE, (payload: any) => {
        try {
          const player = this.playerManager.getPlayer(payload.playerId);
          
          if (!player) {
            socket.emit(ServerEvent.ERROR, {
              code: 'PLAYER_NOT_FOUND',
              message: 'Player not found'
            });
            return;
          }

          const newPos = Vec2D.from(payload.position);
          const success = this.playerManager.movePlayer(payload.playerId, newPos);
          
          if (success && player.worldId) {
            socket.broadcast.to(`world:${player.worldId}`).emit(ServerEvent.PLAYER_MOVED, {
              playerId: payload.playerId,
              position: { x: newPos.x, y: newPos.y },
              worldId: player.worldId,
              sequence: payload.sequence
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

      socket.on(ClientEvent.CHAT, (payload: any) => {
        try {
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
            socket.to(payload.targetId).emit(ServerEvent.CHAT_MESSAGE, messagePayload);
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

      socket.on(ClientEvent.LEAVE_WORLD, (payload: any) => {
        try {
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
