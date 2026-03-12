import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { Server } from '../core/server.js';
import { Vec2D, Player } from '@vg2/core';
import { io as Client } from 'socket.io-client';
import { ClientEvent, ServerEvent } from '@vg2/shared';

describe('Integration Tests', () => {
  let server: Server;
  let clientSocket: any;
  const PORT = 3000;

  beforeEach(async () => {
    server = new Server();
    await server.start(PORT);
  });

  afterEach(async () => {
    if (clientSocket && clientSocket.connected) {
      clientSocket.disconnect();
    }
    await server.stop();
  });

  it('should handle complete player lifecycle', async () => {
    const playerManager = server.getPlayerManager();
    const player = new Player('player1', 'TestPlayer', new Vec2D(0, 0));
    playerManager.addPlayer(player);

    const world = server.getWorld('default');
    if (world) {
      world.addEntity(player);
    }

    playerManager.updatePlayerWorld('player1', 'default');
    await new Promise((resolve) => setTimeout(resolve, 20));

    const moved = playerManager.movePlayer('player1', new Vec2D(3, 3));
    expect(moved).toBe(true);
    expect(player.position.x).toBe(3);
    expect(player.position.y).toBe(3);

    playerManager.removePlayer('player1');
    expect(playerManager.getPlayer('player1')).toBeUndefined();
  });

  it('should handle multiple players in same world', async () => {
    const playerManager = server.getPlayerManager();

    const player1 = new Player('player1', 'Player 1', new Vec2D(0, 0));
    const player2 = new Player('player2', 'Player 2', new Vec2D(5, 5));

    playerManager.addPlayer(player1);
    playerManager.addPlayer(player2);

    const world = server.getWorld('default');
    if (world) {
      world.addEntity(player1);
      world.addEntity(player2);
      player1.worldId = 'default';
      player2.worldId = 'default';
    }

    const playersInWorld = playerManager.getPlayersInWorld('default');
    expect(playersInWorld.length).toBe(2);
  });

  it('should handle chunk transitions and send chunk updates', async () => {
    const playerManager = server.getPlayerManager();
    const player = new Player('player1', 'TestPlayer', new Vec2D(0, 0));
    playerManager.addPlayer(player);

    const world = server.getWorld('default');
    if (world) {
      world.addEntity(player);
      player.worldId = 'default';
    }

    const chunk1 = world?.getChunk(0, 0);
    const chunk2 = world?.getChunk(1, 0);

    expect(chunk1).toBeDefined();
    expect(chunk2).toBeDefined();

    // Подключаем клиент для получения чанков
    clientSocket = Client(`http://localhost:${PORT}`, {
      autoConnect: false,
      transports: ['websocket'],
    });

    await new Promise<void>((resolve, reject) => {
      let chunkUpdateReceived = false;
      let moveProcessed = false;

      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'player1',
          worldId: 'default',
          spawnPoint: { x: 0, y: 0 },
        });
      });

      clientSocket.on(ServerEvent.WORLD_STATE, () => {
        // Двигаем игрока в другой чанк
        clientSocket.emit(ClientEvent.MOVE, {
          playerId: 'player1',
          position: { x: 20, y: 0 },
          sequence: 1,
        });
      });

      clientSocket.on(ServerEvent.CHUNK_UPDATE, (data: any) => {
        if (data.chunkX === 1 && data.chunkY === 0) {
          chunkUpdateReceived = true;
        }
      });

      clientSocket.on(ServerEvent.PLAYER_MOVED, (data: any) => {
        if (data.playerId === 'player1') {
          moveProcessed = true;
        }
      });

      setTimeout(() => {
        if (moveProcessed && chunkUpdateReceived) {
          resolve();
        } else {
          reject(new Error('Chunk update not received after movement'));
        }
      }, 500);
    });
  });
});
