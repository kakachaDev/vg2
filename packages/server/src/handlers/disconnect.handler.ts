import { Socket } from 'socket.io';
import { Server } from '../core/server.js';
import { BaseHandler } from './base.handler.js';
import { ServerEvent } from '@vg2/shared';

export class DisconnectHandler extends BaseHandler {
  handle(socket: Socket, data: unknown, server: Server): void {
    console.log(`Client disconnected: ${socket.id}`);

    for (const player of server.getPlayerManager().getAllPlayers()) {
      if (player.sessionId === socket.id) {
        if (player.worldId) {
          socket.broadcast.to(`world:${player.worldId}`).emit(ServerEvent.PLAYER_LEFT, {
            playerId: player.id,
            worldId: player.worldId,
          });
        }
        server.getPlayerManager().removePlayer(player.id);
        break;
      }
    }
  }
}
