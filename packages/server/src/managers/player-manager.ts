import { Player, Vec2D } from '@vg2/core';
import { Server } from '../core/server.js';
import { CollisionDetector } from '../world/collision-detector.js';

export class PlayerManager {
  private players: Map<string, Player> = new Map();
  private lastMoveTimes: Map<string, number> = new Map();
  private moveSequences: Map<string, number> = new Map();
  private server: Server;

  constructor(server: Server) {
    this.server = server;
  }

  public addPlayer(player: Player): void {
    this.players.set(player.id, player);
    this.lastMoveTimes.set(player.id, Date.now());
    this.moveSequences.set(player.id, 0);
  }

  public removePlayer(playerId: string): boolean {
    const player = this.players.get(playerId);
    if (player && player.worldId) {
      const world = this.server.getWorld(player.worldId);
      if (world) {
        world.removeEntity(playerId);
      }
    }
    this.lastMoveTimes.delete(playerId);
    this.moveSequences.delete(playerId);
    return this.players.delete(playerId);
  }

  public getPlayer(id: string): Player | undefined {
    return this.players.get(id);
  }

  public getAllPlayers(): Player[] {
    return Array.from(this.players.values());
  }

  public movePlayer(playerId: string, newPosition: Vec2D): boolean;
  public movePlayer(
    playerId: string,
    newPosition: Vec2D,
    sequence: number,
  ): {
    success: boolean;
    authorizedPosition: Vec2D;
    sequence: number;
  };

  public movePlayer(
    playerId: string,
    newPosition: Vec2D,
    sequence?: number,
  ):
    | boolean
    | {
        success: boolean;
        authorizedPosition: Vec2D;
        sequence: number;
      } {
    const player = this.players.get(playerId);
    if (!player) {
      if (sequence !== undefined) {
        return { success: false, authorizedPosition: new Vec2D(0, 0), sequence: 0 };
      }
      return false;
    }

    const now = Date.now();

    if (sequence !== undefined) {
      const lastSequence = this.moveSequences.get(playerId) || 0;
      if (sequence <= lastSequence) {
        return {
          success: false,
          authorizedPosition: player.position,
          sequence: lastSequence,
        };
      }
    }

    const lastMove = this.lastMoveTimes.get(playerId) || 0;
    if (now - lastMove < 16) {
      if (sequence !== undefined) {
        return {
          success: false,
          authorizedPosition: player.position,
          sequence: this.moveSequences.get(playerId) || 0,
        };
      }
      return false;
    }

    const oldPosition = player.position.clone();
    const distance = oldPosition.distance(newPosition);
    const maxSpeed = 5;

    let finalPosition = newPosition;
    if (distance > maxSpeed) {
      const direction = new Vec2D(newPosition.x - oldPosition.x, newPosition.y - oldPosition.y);
      const normalizedDir = new Vec2D(direction.x / distance, direction.y / distance);
      finalPosition = new Vec2D(
        oldPosition.x + normalizedDir.x * maxSpeed,
        oldPosition.y + normalizedDir.y * maxSpeed,
      );
    }

    let authorizedPosition = oldPosition;

    if (player.worldId) {
      const world = this.server.getWorld(player.worldId);
      if (world) {
        const collisionDetector = new CollisionDetector(world);
        authorizedPosition = collisionDetector.getValidMovePosition(
          oldPosition,
          finalPosition,
          playerId,
        );
      }
    }

    const moved = !authorizedPosition.eq(oldPosition);

    if (moved) {
      player.position = authorizedPosition;
      this.lastMoveTimes.set(playerId, now);
      if (sequence !== undefined) {
        this.moveSequences.set(playerId, sequence);
      }

      if (player.worldId) {
        const world = this.server.getWorld(player.worldId);
        if (world) {
          world.updateEntityPosition(playerId, authorizedPosition);
        }
      }
    }

    if (sequence !== undefined) {
      return {
        success: moved,
        authorizedPosition: player.position,
        sequence: this.moveSequences.get(playerId) || 0,
      };
    }

    return moved;
  }

  public getPlayersInWorld(worldId: string): Player[] {
    const world = this.server.getWorld(worldId);
    if (!world) {
      return [];
    }
    return world.getPlayers();
  }

  public updatePlayerSession(playerId: string, sessionId: string): boolean {
    const player = this.players.get(playerId);
    if (!player) {
      return false;
    }
    player.sessionId = sessionId;
    return true;
  }

  public updatePlayerWorld(playerId: string, worldId: string): boolean {
    const player = this.players.get(playerId);
    if (!player) {
      return false;
    }

    if (player.worldId) {
      const oldWorld = this.server.getWorld(player.worldId);
      if (oldWorld) {
        oldWorld.removeEntity(playerId);
      }
    }

    player.worldId = worldId;

    const newWorld = this.server.getWorld(worldId);
    if (newWorld) {
      newWorld.addEntity(player);
    }

    return true;
  }
}
