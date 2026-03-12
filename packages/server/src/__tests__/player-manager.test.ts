import { describe, it, expect, beforeEach } from 'vitest';
import { PlayerManager } from '../managers/player-manager.js';
import { Server } from '../core/server.js';
import { Vec2D } from '@vg2/core';
import { Player } from '@vg2/core';

describe('PlayerManager', () => {
  let server: Server;
  let playerManager: PlayerManager;

  beforeEach(() => {
    server = new Server();
    playerManager = new PlayerManager(server);
  });

  it('should add and get player', () => {
    const player = new Player('1', 'TestPlayer', new Vec2D(0, 0));
    playerManager.addPlayer(player);

    const retrieved = playerManager.getPlayer('1');
    expect(retrieved).toBeDefined();
    expect(retrieved?.id).toBe('1');
    expect(retrieved?.name).toBe('TestPlayer');
  });

  it('should remove player', () => {
    const player = new Player('1', 'TestPlayer', new Vec2D(0, 0));
    playerManager.addPlayer(player);

    const removed = playerManager.removePlayer('1');
    expect(removed).toBe(true);
    expect(playerManager.getPlayer('1')).toBeUndefined();
  });

  it('should move player', async () => {
    const player = new Player('1', 'TestPlayer', new Vec2D(0, 0));
    playerManager.addPlayer(player);
    
    const world = server.getWorld('default');
    if (world) {
      world.addEntity(player);
      player.worldId = 'default';
    }

    const newPosition = new Vec2D(3, 3);
    await new Promise(resolve => setTimeout(resolve, 20));

    setTimeout(() => {
    const moved = playerManager.movePlayer('1', newPosition);

    }, 20);
    expect(moved).toBe(true);
    expect(player.position.x).toBe(3);
    expect(player.position.y).toBe(3);
  });

  it('should update player session', () => {
    const player = new Player('1', 'TestPlayer', new Vec2D(0, 0));
    playerManager.addPlayer(player);

    const updated = playerManager.updatePlayerSession('1', 'session123');
    expect(updated).toBe(true);
    expect(player.sessionId).toBe('session123');
  });

  it('should get players in default world', () => {
    const player = new Player('1', 'TestPlayer', new Vec2D(0, 0));
    playerManager.addPlayer(player);

    player.worldId = 'default';
    const world = server.getWorld('default');
    if (world) {
      world.addEntity(player);
    }

    const players = playerManager.getPlayersInWorld('default');
    expect(players.length).toBeGreaterThan(0);
    expect(players[0].id).toBe('1');
  });
});
