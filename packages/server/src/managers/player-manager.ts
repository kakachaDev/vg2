import { Player, Vec2D } from '@vg2/core';
import { Server } from '../core/server';

export class PlayerManager {
  private players: Map<string, Player> = new Map();
  private server: Server;

  constructor(server: Server) {
    this.server = server;
  }

  public addPlayer(player: Player): void {
    this.players.set(player.id, player);
    
    const world = this.server.getWorld('default');
    if (world) {
      world.addEntity(player);
    }
  }

  public removePlayer(playerId: string): boolean {
    const player = this.players.get(playerId);
    if (player) {
      const world = this.server.getWorld('default');
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

    const world = this.server.getWorld('default');
    if (!world) {
      return false;
    }

    const oldPosition = player.position;
    player.position = newPosition;
    
    world.removeEntity(playerId);
    world.addEntity(player);
    
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
}
