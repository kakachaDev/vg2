#!/bin/bash

# Исправляем проблемы с TypeScript

# 1. Добавляем экспорт Vec2D в core/index.ts и исправляем импорты
cat > packages/core/src/index.ts << 'EOF'
export { Vec2D } from './vec2d';
export { Direction, Entity, Player, World } from './types';
EOF

# 2. Исправляем types.ts - импортируем Vec2D
cat > packages/core/src/types.ts << 'EOF'
import { Vec2D } from './vec2d';

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

# 3. Исправляем tsconfig.json в core для правильной компиляции
cat > packages/core/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "lib": ["ES2020"],
    "target": "ES2020",
    "module": "NodeNext",
    "moduleResolution": "NodeNext"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF

# 4. Исправляем tsconfig.json в корне для поддержки console
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2020"],
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

# 5. Исправляем tsconfig.json в server
cat > packages/server/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "lib": ["ES2020"],
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

# 6. Добавляем зависимости в server
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

# 7. Добавляем @types/node в корневой package.json
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

# 8. Форматируем код
npm run format -- --write

# 9. Переустанавливаем зависимости
rm -rf node_modules package-lock.json
npm install

# 10. Запускаем сборку
echo "=== Повторная сборка ==="
npm run build

# 11. Запускаем все тесты с покрытием
echo "=== Финальное тестирование ==="
npm run test:coverage

# 12. Обновляем PROGRESS.md с исправлениями
cat >> PROGRESS.md << 'EOF'
- [x] Исправлены проблемы TypeScript
  - [x] Добавлен экспорт Vec2D в core/index.ts
  - [x] Исправлен импорт Vec2D в types.ts
  - [x] Добавлены @types/node для поддержки console
  - [x] Настроены правильные ссылки между пакетами
  - [x] Исправлены tsconfig.json во всех пакетах
EOF

# 13. Коммит исправлений
git add .
git commit -m "fix: typescript configuration and imports

- Add Vec2D export in core/index.ts
- Fix Vec2D import in types.ts
- Add @types/node for console support
- Configure proper package references
- Fix tsconfig.json in all packages"
EOF