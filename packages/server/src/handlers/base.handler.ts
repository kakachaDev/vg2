import { Socket } from 'socket.io';
import { Server } from '../core/server.js';
import { EventHandler } from './event-handler.interface.js';
import { PlayerManager } from '../managers/player-manager.js';
import { World } from '../world/world.js';
import { z } from 'zod';

export abstract class BaseHandler implements EventHandler {
  protected getPlayerManager(server: Server): PlayerManager {
    return server.getPlayerManager();
  }

  protected getWorld(server: Server, worldId: string): World | undefined {
    return server.getWorld(worldId);
  }

  protected validate<T>(schema: z.Schema<T>, data: unknown): T {
    return schema.parse(data);
  }

  abstract handle(socket: Socket, data: unknown, server: Server): void | Promise<void>;
}
