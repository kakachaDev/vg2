import { describe, it, expect, beforeEach } from 'vitest';
import { Server } from '../core/server';
import { PlayerManager } from '../managers/player-manager';
import { Vec2D } from '@vg2/core';

describe('PlayerManager', () => {
  let server: Server;
  let playerManager: PlayerManager;

  beforeEach(() => {
    server = new Server();
    playerManager = server.getPlayerManager();
  });

  it('should add and get player', () => {
    const player = {
      id: '1',
      name: 'TestPlayer',
      sessionId: 'session1',
      position: new Vec2D(0, 0),
    };

    playerManager.addPlayer(player);
    expect(playerManager.getPlayer('1')).toBe(player);
    expect(playerManager.getAllPlayers()).toContain(player);
  });

  it('should remove player', () => {
    const player = {
      id: '1',
      name: 'TestPlayer',
      sessionId: 'session1',
      position: new Vec2D(0, 0),
    };

    playerManager.addPlayer(player);
    expect(playerManager.removePlayer('1')).toBe(true);
    expect(playerManager.getPlayer('1')).toBeUndefined();
  });

  it('should move player', () => {
    const player = {
      id: '1',
      name: 'TestPlayer',
      sessionId: 'session1',
      position: new Vec2D(0, 0),
    };

    playerManager.addPlayer(player);

    const newPosition = new Vec2D(10, 10);
    const moved = playerManager.movePlayer('1', newPosition);

    expect(moved).toBe(true);
    expect(player.position).toBe(newPosition);
  });

  it('should update player session', () => {
    const player = {
      id: '1',
      name: 'TestPlayer',
      sessionId: 'session1',
      position: new Vec2D(0, 0),
    };

    playerManager.addPlayer(player);

    const updated = playerManager.updatePlayerSession('1', 'newSession');
    expect(updated).toBe(true);
    expect(player.sessionId).toBe('newSession');
  });

  it('should get players in default world', () => {
    const player = {
      id: '1',
      name: 'TestPlayer',
      sessionId: 'session1',
      position: new Vec2D(0, 0),
    };

    playerManager.addPlayer(player);

    const players = playerManager.getPlayersInWorld('default');
    expect(players).toContain(player);
  });
});
