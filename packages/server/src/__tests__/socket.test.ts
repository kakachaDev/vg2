import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { Server } from '../core/server.js';
import { io as Client } from 'socket.io-client';
import { Vec2D, Player } from '@vg2/core';
import { ClientEvent, ServerEvent } from '@vg2/shared';

describe('Socket.IO Server', () => {
  let server: Server;
  let clientSocket: any;
  const PORT = 3001;

  beforeEach(async () => {
    server = new Server();
    await server.start(PORT);

    clientSocket = Client(`http://localhost:${PORT}`, {
      autoConnect: false,
      transports: ['websocket'],
    });
  });

  afterEach(async () => {
    if (clientSocket && clientSocket.connected) {
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
    const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
    server.getPlayerManager().addPlayer(player);

    await new Promise<void>((resolve) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'test-player',
          worldId: 'default',
          spawnPoint: { x: 0, y: 0 },
        });
      });

      clientSocket.on(ServerEvent.WORLD_STATE, (data: any) => {
        expect(data.worldId).toBe('default');
        expect(data.worldName).toBe('Main World');
        resolve();
      });
    });
  });

  it('should handle player movement', async () => {
    const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
    server.getPlayerManager().addPlayer(player);

    const world = server.getWorld('default');
    if (world) {
      world.addEntity(player);
      player.worldId = 'default';
    }

    (server.getPlayerManager() as any).lastMoveTimes.set('test-player', Date.now() - 100);

    await new Promise<void>((resolve, reject) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'test-player',
          worldId: 'default',
        });
      });

      clientSocket.on(ServerEvent.WORLD_STATE, () => {
        setTimeout(() => {
          clientSocket.emit(ClientEvent.MOVE, {
            playerId: 'test-player',
            position: { x: 3, y: 3 },
            sequence: 1,
          });

          setTimeout(() => {
            const updatedPlayer = server.getPlayerManager().getPlayer('test-player');
            try {
              expect(updatedPlayer?.position.x).toBe(3);
              expect(updatedPlayer?.position.y).toBe(3);
              resolve();
            } catch (e) {
              reject(e);
            }
          }, 100);
        }, 20);
      });

      clientSocket.on(ServerEvent.ERROR, (data: any) => {
        reject(new Error(`Server error: ${data.code} - ${data.message}`));
      });
    });
  });

  it('should handle chat messages', async () => {
    const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
    server.getPlayerManager().addPlayer(player);

    await new Promise<void>((resolve) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'test-player',
          worldId: 'default',
        });

        clientSocket.on(ServerEvent.CHAT_MESSAGE, (data: any) => {
          expect(data.playerId).toBe('test-player');
          expect(data.playerName).toBe('TestPlayer');
          expect(data.message).toBe('Hello world');
          resolve();
        });

        setTimeout(() => {
          clientSocket.emit(ClientEvent.CHAT, {
            playerId: 'test-player',
            message: 'Hello world',
            channel: 'global',
          });
        }, 100);
      });
    });
  });

  it('should handle player leaving world', async () => {
    const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
    server.getPlayerManager().addPlayer(player);

    await new Promise<void>((resolve) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'test-player',
          worldId: 'default',
        });

        setTimeout(() => {
          clientSocket.emit(ClientEvent.LEAVE_WORLD, {
            playerId: 'test-player',
            worldId: 'default',
          });
          resolve();
        }, 200);
      });
    });
  });

  it('should validate invalid move payload', async () => {
    await new Promise<void>((resolve, reject) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.MOVE, {
          playerId: 'non-existent-player',
          position: { x: 10, y: 10 },
          sequence: 1,
        });
      });

      clientSocket.on(ServerEvent.ERROR, (data: any) => {
        try {
          expect(data.code).toBe('PLAYER_NOT_FOUND');
          resolve();
        } catch (e) {
          reject(e);
        }
      });
    });
  });
});
