import { describe, it, expect, beforeEach } from 'vitest';
import { Server } from '../core/server';
import { World } from '../world/world';

describe('Server', () => {
  let server: Server;

  beforeEach(() => {
    server = new Server();
  });

  it('should start and stop', async () => {
    expect(server.isActive()).toBe(false);
    
    await server.start();
    expect(server.isActive()).toBe(true);
    
    await server.stop();
    expect(server.isActive()).toBe(false);
  });

  it('should create default world', () => {
    const worlds = server.getAllWorlds();
    expect(worlds.length).toBe(1);
    expect(worlds[0].id).toBe('default');
    expect(worlds[0].name).toBe('Main World');
  });

  it('should add and get worlds', () => {
    const newWorld = new World('test', 'Test World');
    server.addWorld(newWorld);
    
    expect(server.getWorld('test')).toBe(newWorld);
    expect(server.getAllWorlds().length).toBe(2);
  });

  it('should throw error when starting already running server', async () => {
    await server.start();
    await expect(server.start()).rejects.toThrow('Server is already running');
  });

  it('should throw error when stopping not running server', async () => {
    await expect(server.stop()).rejects.toThrow('Server is not running');
  });
});
