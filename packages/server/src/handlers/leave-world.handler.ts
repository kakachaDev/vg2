import { Socket } from 'socket.io';
import { Server } from '../core/server.js';
import { BaseHandler } from './base.handler.js';
import { ClientEvent, ServerEvent, leaveWorldPayloadSchema } from '@vg2/shared';

export class LeaveWorldHandler extends BaseHandler {
  async handle(socket: Socket, data: unknown, server: Server): Promise<void> {
    try {
      const payload = this.validate(leaveWorldPayloadSchema, data);

      socket.leave(`world:${payload.worldId}`);

      socket.broadcast.to(`world:${payload.worldId}`).emit(ServerEvent.PLAYER_LEFT, {
        playerId: payload.playerId,
        worldId: payload.worldId,
      });

      const player = server.getPlayerManager().getPlayer(payload.playerId);
      if (player) {
        const world = server.getWorld(payload.worldId);
        if (world) {
          world.removeEntity(payload.playerId);
        }
        player.worldId = undefined;
      }
    } catch (error) {
      socket.emit(ServerEvent.ERROR, {
        code: 'INVALID_LEAVE',
        message: 'Invalid leave world payload',
        details: error,
      });
    }
  }
}
