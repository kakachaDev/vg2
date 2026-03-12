import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { Server } from '../core/server';
import { Vec2D } from '@vg2/core';

describe('Integration Tests', () => {
  let server: Server;

  beforeEach(async () => {
    server = new Server();
    await server.start();
  });

  afterEach(async () => {
    await server.stop();
  });

  it('should handle complete player lifecycle', () => {
    const playerManager = server.getPlayerManager();

    // Создание игрока
    const player = {
      id: 'player1',
      name: 'TestPlayer',
      sessionId: 'session123',
      position: new Vec2D(0, 0),
    };

    playerManager.addPlayer(player);

    // Проверка добавления
    expect(playerManager.getPlayer('player1')).toBe(player);

    // Проверка мира
    const world = server.getWorld('default');
    expect(world?.getEntity('player1')).toBe(player);

    // Движение игрока
    const newPosition = new Vec2D(5, 5);
    playerManager.movePlayer('player1', newPosition);
    expect(player.position).toEqual(newPosition);

    // Проверка чанков
    const chunks = world?.getEntityChunks('player1');
    expect(chunks?.length).toBeGreaterThan(0);

    // Удаление игрока
    playerManager.removePlayer('player1');
    expect(playerManager.getPlayer('player1')).toBeUndefined();
    expect(world?.getEntity('player1')).toBeUndefined();
  });

  it('should handle multiple players in same world', () => {
    const playerManager = server.getPlayerManager();

    const player1 = {
      id: 'player1',
      name: 'Player1',
      sessionId: 'session1',
      position: new Vec2D(0, 0),
    };

    const player2 = {
      id: 'player2',
      name: 'Player2',
      sessionId: 'session2',
      position: new Vec2D(10, 10),
    };

    playerManager.addPlayer(player1);
    playerManager.addPlayer(player2);

    const players = playerManager.getPlayersInWorld('default');
    expect(players).toHaveLength(2);
    expect(players).toContain(player1);
    expect(players).toContain(player2);
  });

  it('should handle chunk transitions', () => {
    const playerManager = server.getPlayerManager();
    const world = server.getWorld('default')!;

    const player = {
      id: 'player1',
      name: 'TestPlayer',
      sessionId: 'session123',
      position: new Vec2D(0, 0),
    };

    playerManager.addPlayer(player);

    // Движение в другой чанк
    const farPosition = new Vec2D(100, 100);
    playerManager.movePlayer('player1', farPosition);

    const chunks = world.getEntityChunks('player1');
    expect(chunks).toBeDefined();

    // Проверка получения чанков вокруг игрока
    const nearbyChunks = world.getChunksInRange(farPosition.x, farPosition.y, 1);
    expect(nearbyChunks.length).toBe(9);
  });
});
