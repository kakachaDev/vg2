#!/bin/bash

# Возвращаем ES Modules, но правильно настраиваем расширения

# 1. Правильно настраиваем core с ES Modules и расширениями .js в импортах
cat > packages/core/src/index.ts << 'EOF'
export { Vec2D } from './vec2d.js';
export { Direction, Entity, Player, World } from './types.js';
EOF

cat > packages/core/src/types.ts << 'EOF'
import { Vec2D } from './vec2d.js';

export enum Direction {
  North = 'north',
  South = 'south',
  East = 'east',
  West = 'west'
}

export interface Entity {
  id: string;
  position: Vec2D;
}

export interface Player extends Entity {
  name: string;
  sessionId: string;
}

export interface World {
  id: string;
  name: string;
  entities: Map<string, Entity>;
}
EOF

# 2. Правильно настраиваем server с ES Modules и расширениями .js
cat > packages/server/src/index.ts << 'EOF'
export { Server } from './core/server.js';
export { World } from './world/world.js';
export { Chunk } from './world/chunk.js';
export { PlayerManager } from './managers/player-manager.js';
EOF

cat > packages/server/src/core/server.ts << 'EOF'
import { World } from '../world/world.js';
import { PlayerManager } from '../managers/player-manager.js';

export class Server {
  private worlds: Map<string, World> = new Map();
  private playerManager: PlayerManager;
  private isRunning: boolean = false;

  constructor() {
    this.playerManager = new PlayerManager(this);
    this.createDefaultWorld();
  }

  private createDefaultWorld(): void {
    const defaultWorld = new World('default', 'Main World');
    this.worlds.set(defaultWorld.id, defaultWorld);
  }

  public async start(): Promise<void> {
    if (this.isRunning) {
      throw new Error('Server is already running');
    }
    this.isRunning = true;
    console.log('Server started');
  }

  public async stop(): Promise<void> {
    if (!this.isRunning) {
      throw new Error('Server is not running');
    }
    this.isRunning = false;
    console.log('Server stopped');
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
}
EOF

cat > packages/server/src/managers/player-manager.ts << 'EOF'
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
EOF

cat > packages/server/src/world/world.ts << 'EOF'
import { Entity, Player } from '@vg2/core';
import { Chunk } from './chunk.js';

export class World {
  public readonly id: string;
  public readonly name: string;
  private entities: Map<string, Entity> = new Map();
  private chunks: Map<string, Chunk> = new Map();
  private playerChunks: Map<string, Set<string>> = new Map();

  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
  }

  public addEntity(entity: Entity): void {
    this.entities.set(entity.id, entity);
    this.updateEntityChunks(entity);
  }

  public removeEntity(entityId: string): boolean {
    const entity = this.entities.get(entityId);
    if (entity) {
      this.playerChunks.delete(entityId);
    }
    return this.entities.delete(entityId);
  }

  public getEntity(id: string): Entity | undefined {
    return this.entities.get(id);
  }

  public getAllEntities(): Entity[] {
    return Array.from(this.entities.values());
  }

  public getPlayers(): Player[] {
    return Array.from(this.entities.values()).filter(
      (entity): entity is Player => 'sessionId' in entity
    );
  }

  public getChunk(chunkX: number, chunkY: number): Chunk {
    const key = `${chunkX},${chunkY}`;
    let chunk = this.chunks.get(key);
    if (!chunk) {
      chunk = new Chunk(chunkX, chunkY);
      this.chunks.set(key, chunk);
    }
    return chunk;
  }

  public getChunksInRange(centerX: number, centerY: number, radius: number): Chunk[] {
    const chunks: Chunk[] = [];
    const chunkX = Math.floor(centerX / Chunk.SIZE);
    const chunkY = Math.floor(centerY / Chunk.SIZE);

    for (let dx = -radius; dx <= radius; dx++) {
      for (let dy = -radius; dy <= radius; dy++) {
        chunks.push(this.getChunk(chunkX + dx, chunkY + dy));
      }
    }
    return chunks;
  }

  private updateEntityChunks(entity: Entity): void {
    const chunkX = Math.floor(entity.position.x / Chunk.SIZE);
    const chunkY = Math.floor(entity.position.y / Chunk.SIZE);
    
    let chunks = this.playerChunks.get(entity.id);
    if (!chunks) {
      chunks = new Set();
      this.playerChunks.set(entity.id, chunks);
    }
    chunks.add(`${chunkX},${chunkY}`);
  }

  public getEntityChunks(entityId: string): string[] {
    return Array.from(this.playerChunks.get(entityId) || []);
  }
}
EOF

cat > packages/server/src/world/chunk.ts << 'EOF'
import { Entity } from '@vg2/core';

export interface Tile {
  type: string;
  solid: boolean;
}

export class Chunk {
  public static readonly SIZE = 16;
  public static readonly VIEW_DISTANCE = 2;

  constructor(
    public readonly x: number,
    public readonly y: number
  ) {}

  private tiles: Map<string, Tile> = new Map();
  private entities: Map<string, Entity> = new Map();

  private getTileKey(localX: number, localY: number): string {
    return `${localX},${localY}`;
  }

  public setTile(localX: number, localY: number, tile: Tile): void {
    if (localX < 0 || localX >= Chunk.SIZE || localY < 0 || localY >= Chunk.SIZE) {
      throw new Error(`Tile coordinates out of bounds: (${localX}, ${localY})`);
    }
    this.tiles.set(this.getTileKey(localX, localY), tile);
  }

  public getTile(localX: number, localY: number): Tile | undefined {
    return this.tiles.get(this.getTileKey(localX, localY));
  }

  public addEntity(entity: Entity): void {
    this.entities.set(entity.id, entity);
  }

  public removeEntity(entityId: string): boolean {
    return this.entities.delete(entityId);
  }

  public getEntity(entityId: string): Entity | undefined {
    return this.entities.get(entityId);
  }

  public getAllEntities(): Entity[] {
    return Array.from(this.entities.values());
  }

  public getTiles(): Map<string, Tile> {
    return new Map(this.tiles);
  }

  public getPosition(): { x: number; y: number } {
    return { x: this.x, y: this.y };
  }
}
EOF

# 3. Настраиваем tsconfig.json для ES Modules
cat > packages/core/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "lib": ["ES2022"],
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "types": ["node"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF

cat > packages/server/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "lib": ["ES2022"],
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "types": ["node"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"],
  "references": [
    { "path": "../core" },
    { "path": "../shared" },
    { "path": "../types" }
  ]
}
EOF

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "types": ["node"],
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "composite": true
  },
  "references": [
    { "path": "./packages/core" },
    { "path": "./packages/server" },
    { "path": "./packages/shared" },
    { "path": "./packages/types" }
  ]
}
EOF

# 4. Возвращаем type: module во все package.json
cat > packages/core/package.json << 'EOF'
{
  "name": "@vg2/core",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "test": "vitest"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.4.5",
    "vitest": "^1.5.0"
  }
}
EOF

cat > packages/server/package.json << 'EOF'
{
  "name": "@vg2/server",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "test": "vitest"
  },
  "dependencies": {
    "@vg2/core": "^1.0.0",
    "@vg2/shared": "^1.0.0",
    "@vg2/types": "^1.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.4.5",
    "vitest": "^1.5.0"
  }
}
EOF

cat > packages/shared/package.json << 'EOF'
{
  "name": "@vg2/shared",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "test": "vitest"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.4.5",
    "vitest": "^1.5.0"
  }
}
EOF

cat > packages/types/package.json << 'EOF'
{
  "name": "@vg2/types",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "test": "vitest"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.4.5",
    "vitest": "^1.5.0"
  }
}
EOF

cat > package.json << 'EOF'
{
  "name": "vg2",
  "version": "1.0.0",
  "description": "Voxel Game 2 - Server",
  "type": "module",
  "workspaces": [
    "packages/*"
  ],
  "scripts": {
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "build": "npm run build --workspaces",
    "dev": "npm run dev --workspaces",
    "lint": "prettier --check .",
    "format": "prettier --write ."
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@vitest/coverage-v8": "^1.5.0",
    "prettier": "^3.2.5",
    "typescript": "^5.4.5",
    "vitest": "^1.5.0"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}
EOF

# 5. Переустанавливаем и собираем
echo "=== Переустановка зависимостей ==="
rm -rf node_modules package-lock.json
npm install

echo "=== Сборка проекта ==="
npm run build

echo "=== Запуск тестов ==="
npm run test

# 6. Обновляем PROGRESS.md
cat >> PROGRESS.md << 'EOF'
- [x] Исправлены ES Modules импорты
  - [x] Добавлены .js расширения во все относительные импорты
  - [x] Настроен module: NodeNext и moduleResolution: NodeNext
  - [x] Возвращен type: module во все package.json
  - [x] Сборка работает с ES Modules правильно
EOF

# 7. Коммит
git add .
git commit -m "fix: correct ES Modules configuration with .js extensions"
EOF