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
          clientSocket.on(ServerEvent.PLAYER_MOVED, (data: any) => {
            receivedSequence = data.sequence;
          });

          clientSocket.emit(ClientEvent.MOVE, {
            playerId: 'test-player',
            position: { x: 1, y: 0 },
            sequence: 2
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
          let moveCount = 0;

          clientSocket.on(ServerEvent.PLAYER_MOVED, () => {
            moveCount++;
          });

          for (let i = 1; i <= 20; i++) {
            setTimeout(() => {
              clientSocket.emit(ClientEvent.MOVE, {
                playerId: 'test-player',
                position: { x: i, y: 0 },
                sequence: i
              });
            }, i * 5);
          }

          setTimeout(() => {
            expect(moveCount).toBeLessThan(20);
            resolve();
          }, 200);
        });
      });
    });
  });
});
