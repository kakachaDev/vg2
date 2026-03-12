import { Socket } from 'socket.io';
import { Server } from '../core/server.js';
import { BaseHandler } from './base.handler.js';
import { ClientEvent, ServerEvent, joinWorldPayloadSchema } from '@vg2/shared';
import { Player, Vec2D } from '@vg2/core';

export class JoinWorldHandler extends BaseHandler {
  async handle(socket: Socket, data: unknown, server: Server): Promise<void> {
    try {
      const payload = this.validate(joinWorldPayloadSchema, data);

      let player = server.getPlayerManager().getPlayer(payload.playerId);

      if (!player) {
        player = new Player(
          payload.playerId,
          `Player-${payload.playerId.substring(0, 4)}`,
          payload.spawnPoint ? Vec2D.from(payload.spawnPoint) : new Vec2D(0, 0),
        );
        server.getPlayerManager().addPlayer(player);
      }

      server.getPlayerManager().updatePlayerSession(payload.playerId, socket.id);
      socket.join(`world:${payload.worldId}`);
      server.getPlayerManager().updatePlayerWorld(payload.playerId, payload.worldId);

      const world = server.getWorld(payload.worldId);
      if (world) {
        const { added } = world.updatePlayerSubscriptions(
          payload.playerId,
          player.position.x,
          player.position.y,
          2,
        );

        for (const chunk of added) {
          socket.emit(ServerEvent.CHUNK_UPDATE, {
            chunkX: chunk.x,
            chunkY: chunk.y,
            tiles: Array.from(chunk.getTiles().entries()).map(([key, tile]) => {
              const [x, y] = key.split(',').map(Number);
              return { x, y, type: tile.type, solid: tile.solid };
            }),
            entities: chunk.getAllEntities().map((e) => ({
              id: e.id,
              type: e.type,
              position: { x: e.position.x, y: e.position.y },
            })),
          });
        }

        socket.emit(ServerEvent.WORLD_STATE, {
          worldId: world.id,
          worldName: world.name,
          players: world.getPlayers().length,
          chunks: Array.from(world.getPlayerSubscriptions(payload.playerId)).map((key) => {
            const [x, y] = key.split(',').map(Number);
            return { x, y };
          }),
        });
      }

      socket.emit(ServerEvent.PLAYER_JOINED, {
        player: {
          id: player.id,
          name: player.name,
          position: { x: player.position.x, y: player.position.y },
        },
        worldId: payload.worldId,
      });

      socket.broadcast.to(`world:${payload.worldId}`).emit(ServerEvent.PLAYER_JOINED, {
        player: {
          id: player.id,
          name: player.name,
          position: { x: player.position.x, y: player.position.y },
        },
        worldId: payload.worldId,
      });
    } catch (error) {
      socket.emit(ServerEvent.ERROR, {
        code: 'INVALID_PAYLOAD',
        message: 'Invalid join world payload',
        details: error,
      });
    }
  }
}
