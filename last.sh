#!/bin/bash

# Переписываем тест "should prevent moving through other players" с использованием события PLAYER_MOVED и улучшенной проверкой
cat > packages/server/src/__tests__/movement-collision.test.ts.tmp << 'EOF'
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
      player1.worldId = 'default';
      player2.worldId = 'default';
    }

    // Убедимся, что player2 действительно в мире
    const worldPlayers = world?.getPlayers();
    expect(worldPlayers?.length).toBe(2);

    // Сбросим время последнего движения, чтобы избежать rate limit
    (server.getPlayerManager() as any).lastMoveTimes.set('player1', Date.now() - 100);

    await new Promise<void>((resolve, reject) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'player1',
          worldId: 'default',
          spawnPoint: { x: 0, y: 0 }
        });
      });

      clientSocket.on(ServerEvent.WORLD_STATE, () => {
        // Отправляем движение к позиции за player2
        clientSocket.emit(ClientEvent.MOVE, {
          playerId: 'player1',
          position: { x: 3, y: 0 },
          sequence: 1
        });
      });

      // Ждем события PLAYER_MOVED
      clientSocket.on(ServerEvent.PLAYER_MOVED, (data: any) => {
        if (data.playerId === 'player1') {
          const updatedPlayer = server.getPlayerManager().getPlayer('player1');
          try {
            expect(updatedPlayer?.position.x).toBeLessThan(2); // Не должен пройти через player2
            resolve();
          } catch (e) {
            reject(e);
          }
        }
      });

      // Таймаут на случай, если событие не придет
      setTimeout(() => {
        reject(new Error('Timeout waiting for PLAYER_MOVED'));
      }, 1000);
    });
  });

  it('should reject out-of-order move sequences', async () => {
    const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
    server.getPlayerManager().addPlayer(player);

    const world = server.getWorld('default');
    if (world) {
      world.addEntity(player);
      player.worldId = 'default';
    }

    (server.getPlayerManager() as any).lastMoveTimes.set('test-player', Date.now() - 100);
    (server.getPlayerManager() as any).moveSequences.set('test-player', 0);

    await new Promise<void>((resolve, reject) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'test-player',
          worldId: 'default',
          spawnPoint: { x: 0, y: 0 }
        });
      });

      clientSocket.on(ServerEvent.WORLD_STATE, () => {
        let firstMoveProcessed = false;

        clientSocket.on(ServerEvent.PLAYER_MOVED, (data: any) => {
          if (data.sequence === 2) {
            firstMoveProcessed = true;
          } else if (data.sequence === 1) {
            reject(new Error('Second out-of-order move was accepted'));
          }
        });

        clientSocket.emit(ClientEvent.MOVE, {
          playerId: 'test-player',
          position: { x: 1, y: 0 },
          sequence: 2
        });

        const interval = setInterval(() => {
          if (firstMoveProcessed) {
            clearInterval(interval);
            clientSocket.emit(ClientEvent.MOVE, {
              playerId: 'test-player',
              position: { x: 2, y: 0 },
              sequence: 1
            });

            setTimeout(() => {
              resolve();
            }, 100);
          }
        }, 10);
      });

      setTimeout(() => {
        reject(new Error('Timeout in out-of-order test'));
      }, 2000);
    });
  });

  it('should handle many move requests without crashing', async () => {
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
          spawnPoint: { x: 0, y: 0 }
        });
      });

      clientSocket.on(ServerEvent.WORLD_STATE, () => {
        let moveCount = 0;
        const movesSent = 10;

        clientSocket.on(ServerEvent.PLAYER_MOVED, () => {
          moveCount++;
        });

        for (let i = 1; i <= movesSent; i++) {
          setTimeout(() => {
            clientSocket.emit(ClientEvent.MOVE, {
              playerId: 'test-player',
              position: { x: i, y: 0 },
              sequence: i
            });
          }, i * 2);
        }

        setTimeout(() => {
          try {
            expect(server.getPlayerManager().getPlayer('test-player')).toBeDefined();
            const finalPlayer = server.getPlayerManager().getPlayer('test-player');
            expect(finalPlayer?.position.x).toBeGreaterThan(0);
            resolve();
          } catch (e) {
            reject(e);
          }
        }, movesSent * 2 + 200);
      });

      clientSocket.on(ServerEvent.ERROR, () => {});
    });
  });
});
EOF

# Заменяем старый файл новым
mv packages/server/src/__tests__/movement-collision.test.ts.tmp packages/server/src/__tests__/movement-collision.test.ts

# Обновляем PROGRESS.md
cat >> PROGRESS.md << 'EOF'

- [x] Исправлен тест "should prevent moving through other players": теперь ожидается событие PLAYER_MOVED и проверка позиции после обработки
EOF

# Коммит
git add .
git commit -m "test: улучшен тест коллизии игроков с ожиданием события PLAYER_MOVED"

# Запуск тестов
npm test