import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { Server } from '../core/server.js';
import { Player, Vec2D } from '@vg2/core';

describe('Integration Tests', () => {
  let server: Server;

  beforeEach(() => {
    server = new Server();
  });

  afterEach(async () => {
    await server.stop();
  });

  it('should handle complete player lifecycle', async () => {
    await server.start(3000);

    const player = new Player('player1', 'TestPlayer', new Vec2D(0, 0));
    player.sessionId = 'session123';
    
    const playerManager = server.getPlayerManager();
    playerManager.addPlayer(player);

    const world = server.getWorld('default');
    expect(world).toBeDefined();
    
    if (world) {
      world.addEntity(player);
      expect(world.getEntity('player1')).toBeDefined();
      expect(world.getEntity('player1')?.id).toBe('player1');
    }

    playerManager.updatePlayerWorld('player1', 'default');
    const moved = playerManager.movePlayer('player1', new Vec2D(10, 10));
    expect(moved).toBe(true);
    expect(player.position.x).toBe(10);
    expect(player.position.y).toBe(10);

    const removed = playerManager.removePlayer('player1');
    expect(removed).toBe(true);
    expect(playerManager.getPlayer('player1')).toBeUndefined();
  });

  it('should handle multiple players in same world', async () => {
    await server.start(3000);

    const player1 = new Player('player1', 'Player 1', new Vec2D(0, 0));
    const player2 = new Player('player2', 'Player 2', new Vec2D(5, 5));
    
    const playerManager = server.getPlayerManager();
    playerManager.addPlayer(player1);
    playerManager.addPlayer(player2);

    playerManager.updatePlayerWorld('player1', 'default');
    playerManager.updatePlayerWorld('player2', 'default');

    const world = server.getWorld('default');
    expect(world).toBeDefined();
    
    if (world) {
      world.addEntity(player1);
      world.addEntity(player2);
    }

    const players = playerManager.getPlayersInWorld('default');
    expect(players.length).toBe(2);
    expect(players.map(p => p.id)).toContain('player1');
    expect(players.map(p => p.id)).toContain('player2');
  });

  it('should handle chunk transitions', async () => {
    await server.start(3000);

    const player = new Player('player1', 'TestPlayer', new Vec2D(0, 0));
    const playerManager = server.getPlayerManager();
    playerManager.addPlayer(player);
    playerManager.updatePlayerWorld('player1', 'default');

    const world = server.getWorld('default');
    expect(world).toBeDefined();
    
    if (world) {
      world.addEntity(player);
      
      const initialChunks = world.getEntityChunks('player1');
      
      playerManager.movePlayer('player1', new Vec2D(32, 32));
      
      const newChunks = world.getEntityChunks('player1');
      
      expect(newChunks.length).toBeGreaterThanOrEqual(initialChunks.length);
    }
  });
});
