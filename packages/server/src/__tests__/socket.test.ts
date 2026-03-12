import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { Server } from '../core/server.js';
import { io as Client, Socket } from 'socket.io-client';
import { Player, Vec2D } from '@vg2/core';
import { ClientEvent, ServerEvent } from '@vg2/shared';

describe('Socket.IO Server', () => {
  let server: Server;
  let clientSocket: Socket;
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
    if (clientSocket.connected) {
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
    await new Promise<void>((resolve) => {
      clientSocket.connect();

      const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
      server.getPlayerManager().addPlayer(player);

      clientSocket.on(ServerEvent.WORLD_STATE, (data) => {
        expect(data.worldId).toBe('default');
        expect(data.worldName).toBe('Main World');
        expect(data.players).toBeDefined();
      });

      clientSocket.on(ServerEvent.PLAYER_JOINED, (data) => {
        expect(data.player.id).toBe('test-player');
        expect(data.player.name).toBe('TestPlayer');
        expect(data.worldId).toBe('default');
        resolve();
      });

      clientSocket.emit(ClientEvent.JOIN_WORLD, {
        playerId: 'test-player',
        worldId: 'default',
        spawnPoint: { x: 0, y: 0 }
      });
    });
  });

  it('should handle player movement', async () => {
    await new Promise<void>((resolve) => {
      clientSocket.connect();

      const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
      server.getPlayerManager().addPlayer(player);

      clientSocket.emit(ClientEvent.JOIN_WORLD, {
        playerId: 'test-player',
        worldId: 'default'
      });

      setTimeout(() => {
        clientSocket.emit(ClientEvent.MOVE, {
          playerId: 'test-player',
          position: { x: 10, y: 10 },
          sequence: 1
        });

        const updatedPlayer = server.getPlayerManager().getPlayer('test-player');
        expect(updatedPlayer?.position.x).toBe(10);
        expect(updatedPlayer?.position.y).toBe(10);
        resolve();
      }, 100);
    });
  });

  it('should handle chat messages', async () => {
    await new Promise<void>((resolve) => {
      clientSocket.connect();

      const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
      server.getPlayerManager().addPlayer(player);

      clientSocket.emit(ClientEvent.JOIN_WORLD, {
        playerId: 'test-player',
        worldId: 'default'
      });

      clientSocket.on(ServerEvent.CHAT_MESSAGE, (data) => {
        expect(data.playerId).toBe('test-player');
        expect(data.playerName).toBe('TestPlayer');
        expect(data.message).toBe('Hello world');
        expect(data.channel).toBe('global');
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

  it('should handle player leaving world', async () => {
    await new Promise<void>((resolve) => {
      clientSocket.connect();

      const player = new Player('test-player', 'TestPlayer', new Vec2D(0, 0));
      server.getPlayerManager().addPlayer(player);

      clientSocket.emit(ClientEvent.JOIN_WORLD, {
        playerId: 'test-player',
        worldId: 'default'
      });

      setTimeout(() => {
        clientSocket.on(ServerEvent.PLAYER_LEFT, (data) => {
          expect(data.playerId).toBe('test-player');
          expect(data.worldId).toBe('default');
          resolve();
        });

        clientSocket.emit(ClientEvent.LEAVE_WORLD, {
          playerId: 'test-player',
          worldId: 'default'
        });
      }, 100);
    });
  });

  it('should validate invalid move payload', async () => {
    await new Promise<void>((resolve) => {
      clientSocket.connect();

      clientSocket.on(ServerEvent.ERROR, (data) => {
        expect(data.code).toBe('INVALID_MOVE');
        resolve();
      });

      clientSocket.emit(ClientEvent.MOVE, {
        playerId: 'invalid-uuid',
        position: { x: 'not a number', y: 10 },
        sequence: -1
      });
    });
  });
});
