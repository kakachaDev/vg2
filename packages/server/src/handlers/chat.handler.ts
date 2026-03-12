import { Socket } from 'socket.io';
import { Server } from '../core/server.js';
import { BaseHandler } from './base.handler.js';
import { ClientEvent, ServerEvent, chatPayloadSchema } from '@vg2/shared';

export class ChatHandler extends BaseHandler {
  async handle(socket: Socket, data: unknown, server: Server): Promise<void> {
    try {
      const payload = this.validate(chatPayloadSchema, data);

      const player = server.getPlayerManager().getPlayer(payload.playerId);

      if (!player) {
        socket.emit(ServerEvent.ERROR, {
          code: 'PLAYER_NOT_FOUND',
          message: 'Player not found',
        });
        return;
      }

      const messagePayload = {
        playerId: payload.playerId,
        playerName: player.name,
        message: payload.message,
        channel: payload.channel,
        timestamp: Date.now(),
      };

      if (payload.channel === 'whisper' && payload.targetId) {
        const targetPlayer = server.getPlayerManager().getPlayer(payload.targetId);
        if (targetPlayer?.sessionId) {
          socket.to(targetPlayer.sessionId).emit(ServerEvent.CHAT_MESSAGE, messagePayload);
        }
      } else if (player.worldId) {
        server
          .getIO()
          ?.to(`world:${player.worldId}`)
          .emit(ServerEvent.CHAT_MESSAGE, messagePayload);
      }
    } catch (error) {
      socket.emit(ServerEvent.ERROR, {
        code: 'INVALID_CHAT',
        message: 'Invalid chat payload',
        details: error,
      });
    }
  }
}
