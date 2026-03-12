import { Socket } from 'socket.io';
import { Server } from '../core/server.js';
import { BaseHandler } from './base.handler.js';
import { ClientEvent, ServerEvent, movePayloadSchema } from '@vg2/shared';
import type { C2SMovePayload } from '@vg2/shared';
import { Vec2D } from '@vg2/core';

export class MoveHandler extends BaseHandler {
  async handle(socket: Socket, data: unknown, server: Server): Promise<void> {
    try {
      const payload = this.validate(movePayloadSchema, data) as C2SMovePayload;

      const player = server.getPlayerManager().getPlayer(payload.playerId);

      if (!player) {
        socket.emit(ServerEvent.ERROR, {
          code: 'PLAYER_NOT_FOUND',
          message: 'Player not found',
        });
        return;
      }

      const newPos = Vec2D.from(payload.position);
      const result = server.getPlayerManager().movePlayer(payload.playerId, newPos, payload.sequence);

      if (player.worldId) {
        const world = server.getWorld(player.worldId);
        if (world) {
          const { added } = world.updatePlayerSubscriptions(
            payload.playerId,
            result.authorizedPosition.x,
            result.authorizedPosition.y,
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
        }
      }

      const moveEvent = {
        playerId: payload.playerId,
        position: { x: result.authorizedPosition.x, y: result.authorizedPosition.y },
        worldId: player.worldId,
        sequence: result.sequence,
      };

      socket.broadcast.to(`world:${player.worldId}`).emit(ServerEvent.PLAYER_MOVED, moveEvent);
      socket.emit(ServerEvent.PLAYER_MOVED, moveEvent);
    } catch (error) {
      socket.emit(ServerEvent.ERROR, {
        code: 'INVALID_MOVE',
        message: 'Invalid move payload',
        details: error,
      });
    }
  }
}
