import { Server as HttpServer } from 'http';
import { Server as SocketServer, Socket } from 'socket.io';
import { World } from '../world/world.js';
import { PlayerManager } from '../managers/player-manager.js';
import { ClientEvent, ServerEvent } from '@vg2/shared';
import {
  EventHandler,
  JoinWorldHandler,
  MoveHandler,
  ChatHandler,
  LeaveWorldHandler,
  DisconnectHandler,
} from '../handlers/index.js';

export class Server {
  private worlds: Map<string, World> = new Map();
  private playerManager: PlayerManager;
  private isRunning: boolean = false;
  private io: SocketServer | null = null;
  private httpServer: HttpServer | null = null;
  private handlers: Map<ClientEvent | 'disconnect', EventHandler> = new Map();

  constructor() {
    this.playerManager = new PlayerManager(this);
    this.createDefaultWorld();
    this.registerDefaultHandlers();
  }

  private registerDefaultHandlers(): void {
    this.registerHandler(ClientEvent.JOIN_WORLD, new JoinWorldHandler());
    this.registerHandler(ClientEvent.MOVE, new MoveHandler());
    this.registerHandler(ClientEvent.CHAT, new ChatHandler());
    this.registerHandler(ClientEvent.LEAVE_WORLD, new LeaveWorldHandler());

    this.handlers.set('disconnect', new DisconnectHandler());
  }

  public registerHandler(event: ClientEvent | 'disconnect', handler: EventHandler): void {
    this.handlers.set(event, handler);
  }

  private createDefaultWorld(): void {
    const defaultWorld = new World('default', 'Main World');
    this.worlds.set(defaultWorld.id, defaultWorld);
  }

  public async start(port: number = 3000): Promise<void> {
    if (this.isRunning) {
      throw new Error('Server is already running');
    }

    this.httpServer = new HttpServer();
    this.io = new SocketServer(this.httpServer, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST'],
      },
      transports: ['websocket'],
    });

    this.setupSocketHandlers();

    return new Promise((resolve) => {
      this.httpServer?.listen(port, () => {
        this.isRunning = true;
        console.log(`Server started on port ${port}`);
        resolve();
      });
    });
  }

  private setupSocketHandlers(): void {
    if (!this.io) return;

    this.io.on('connection', (socket: Socket) => {
      console.log(`Client connected: ${socket.id}`);


      for (const [event, handler] of this.handlers.entries()) {
        if (event === 'disconnect') continue;
        socket.on(event as string, (data: unknown) => {
          handler.handle(socket, data, this);
        });
      }


      socket.on('disconnect', () => {
        const handler = this.handlers.get('disconnect');
        if (handler) {
          handler.handle(socket, {}, this);
        }
      });
    });
  }

  public async stop(): Promise<void> {
    if (!this.isRunning) {
      throw new Error('Server is not running');
    }

    return new Promise((resolve) => {
      if (this.io) {
        this.io.close(() => {
          this.httpServer?.close(() => {
            this.isRunning = false;
            this.io = null;
            this.httpServer = null;
            console.log('Server stopped');
            resolve();
          });
        });
      } else {
        resolve();
      }
    });
  }

  public getWorld(id: string): World | undefined {
    return this.worlds.get(id);
  }

  public getAllWorlds(): World[] {
    return Array.from(this.worlds.values());
  }

  public addWorld(world: World): void {
    this.worlds.set(world.id, world);
  }

  public getPlayerManager(): PlayerManager {
    return this.playerManager;
  }

  public isActive(): boolean {
    return this.isRunning;
  }

  public getIO(): SocketServer | null {
    return this.io;
  }
}
