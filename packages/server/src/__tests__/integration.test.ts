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

  it('should handle chunk transitions', async () => {
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

    playerManager.movePlayer('player1', new Vec2D(20, 0));
    
    const playerChunks = world?.getEntityChunks('player1');
    expect(playerChunks?.length).toBeGreaterThan(0);
  });
});
