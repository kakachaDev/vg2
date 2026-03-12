import { Player, Vec2D } from '@vg2/core';
import { Server } from '../core/server.js';

export class PlayerManager {
  private players: Map<string, Player> = new Map();
  private server: Server;

  constructor(server: Server) {
    this.server = server;
  }

  public addPlayer(player: Player): void {
    this.players.set(player.id, player);
  }

  public removePlayer(playerId: string): boolean {
    const player = this.players.get(playerId);
    if (player && player.worldId) {
      const world = this.server.getWorld(player.worldId);
      if (world) {
        world.removeEntity(playerId);
      }
    }
    return this.players.delete(playerId);
  }

  public getPlayer(id: string): Player | undefined {
    return this.players.get(id);
  }

  public getAllPlayers(): Player[] {
    return Array.from(this.players.values());
  }

  public movePlayer(playerId: string, newPosition: Vec2D): boolean {
    const player = this.players.get(playerId);
    if (!player) {
      return false;
    }

    const world = player.worldId ? this.server.getWorld(player.worldId) : null;
    
    const oldPosition = player.position;
    player.position = newPosition;

    if (world) {
      world.removeEntity(playerId);
      world.addEntity(player);
    }

    return true;
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
