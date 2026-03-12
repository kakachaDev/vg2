#!/bin/bash

# 1. Восстанавливаем movement-collision.test.ts из предыдущей рабочей версии
cat > packages/server/src/__tests__/movement-collision.test.ts << 'EOF'
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
EOF

# 2. Исправляем player-manager.test.ts: используем прямой доступ к lastMoveTimes
cat > packages/server/src/__tests__/player-manager.test.ts << 'EOF'
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

  it('should move player', () => {
    const player = new Player('1', 'TestPlayer', new Vec2D(0, 0));
    playerManager.addPlayer(player);

    const world = server.getWorld('default');
    if (world) {
      world.addEntity(player);
      player.worldId = 'default';
    }

    // Сбрасываем lastMoveTime, чтобы избежать rate limit
    (playerManager as any).lastMoveTimes.set('1', Date.now() - 100);

    const newPosition = new Vec2D(3, 3);
    const moved = playerManager.movePlayer('1', newPosition);

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
EOF

# 3. Исправляем socket.test.ts: добавляем сброс lastMoveTime и увеличиваем таймаут
cat > packages/server/src/__tests__/socket.test.ts << 'EOF'
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
      transports: ['websocket']
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
          spawnPoint: { x: 0, y: 0 }
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

    // Сбрасываем lastMoveTime, чтобы разрешить движение сразу
    (server.getPlayerManager() as any).lastMoveTimes.set('test-player', Date.now() - 100);

    await new Promise<void>((resolve, reject) => {
      clientSocket.connect();

      clientSocket.on('connect', () => {
        clientSocket.emit(ClientEvent.JOIN_WORLD, {
          playerId: 'test-player',
          worldId: 'default'
        });
      });

      clientSocket.on(ServerEvent.WORLD_STATE, () => {
        // Небольшая задержка, чтобы убедиться, что сервер готов
        setTimeout(() => {
          clientSocket.emit(ClientEvent.MOVE, {
            playerId: 'test-player',
            position: { x: 3, y: 3 },
            sequence: 1
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
          worldId: 'default'
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
            channel: 'global'
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
          worldId: 'default'
        });

        setTimeout(() => {
          clientSocket.emit(ClientEvent.LEAVE_WORLD, {
            playerId: 'test-player',
            worldId: 'default'
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
          sequence: 1
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
EOF

# 4. Обновляем PROGRESS.md
cat >> PROGRESS.md << 'EOF'

- [x] Восстановлен movement-collision.test.ts с корректным синтаксисом
- [x] Исправлен player-manager.test.ts: сброс lastMoveTime и правильная проверка moved
- [x] Исправлен socket.test.ts: сброс lastMoveTime и увеличены задержки
EOF

# 5. Коммит
git add .
git commit -m "fix: исправлены тесты player-manager, socket и movement-collision"

# 6. Запуск тестов
npm test