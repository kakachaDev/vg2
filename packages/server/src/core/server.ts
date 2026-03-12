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
