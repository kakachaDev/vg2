import { Socket } from 'socket.io';
import { Server } from '../core/server.js';

export interface EventHandler {
  handle(socket: Socket, data: unknown, server: Server): void | Promise<void>;
}
