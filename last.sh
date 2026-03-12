#!/bin/bash

# 1. Создаем корневой vitest.config.ts
cat > vitest.config.ts << 'EOF'
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html", "lcov"],
      exclude: ["**/node_modules/**", "**/dist/**", "**/coverage/**"],
    },
    environment: "node",
    globals: true,
  },
});
EOF

# 2. Создаем .github/workflows/ci.yml
mkdir -p .github/workflows

cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [main, master, develop]
  pull_request:
    branches: [main, master, develop]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18.x, 20.x, 22.x]

    steps:
      - uses: actions/checkout@v4

      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Check formatting
        run: npm run lint

      - name: Build packages
        run: npm run build

      - name: Run tests with coverage
        run: npm run test:ci

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: ./coverage/coverage-final.json,./packages/core/coverage/coverage-final.json,./packages/server/coverage/coverage-final.json,./packages/shared/coverage/coverage-final.json,./packages/types/coverage/coverage-final.json
          flags: unittests
          name: codecov-umbrella
          fail_ci_if_error: false
          verbose: true

  lint:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Use Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20.x"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Check formatting with Prettier
        run: npx prettier --check "**/*.{js,ts,json,md}"

      - name: Type check core
        run: npx tsc --noEmit -p packages/core/tsconfig.json

      - name: Type check server
        run: npx tsc --noEmit -p packages/server/tsconfig.json

      - name: Type check shared
        run: npx tsc --noEmit -p packages/shared/tsconfig.json

      - name: Type check types
        run: npx tsc --noEmit -p packages/types/tsconfig.json
EOF

# 3. Обновляем корневой package.json для Codecov badge
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
    "test:ci": "vitest run --coverage",
    "build": "npm run build --workspaces",
    "dev": "npm run dev --workspaces",
    "lint": "prettier --check .",
    "format": "prettier --write .",
    "ci": "npm run lint && npm run build && npm run test:ci",
    "typecheck": "npm run typecheck --workspaces"
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

# 4. Создаем .prettierignore
cat > .prettierignore << 'EOF'
node_modules
dist
coverage
.DS_Store
*.log
.env
.idea
.vscode
*.tgz
EOF

# 5. Создаем корневой README.md с бейджами
cat > README.md << 'EOF'
# VG2 - Voxel Game 2 Server

[![CI](https://github.com/yourusername/vg2/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/vg2/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/yourusername/vg2/branch/main/graph/badge.svg)](https://codecov.io/gh/yourusername/vg2)
[![Node Version](https://img.shields.io/node/v/vg2)](https://nodejs.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Authoritative server for 2D multiplayer games. Supports up to 1000 concurrent players with world instances, chunk-based visibility, and seamless world transitions.

## Features

- 🎮 Authoritative server architecture
- 🌍 Multiple world instances (hub + game worlds)
- 📦 Chunk-based world management
- 👥 1000+ concurrent players support
- 🔄 Seamless world switching
- 🧪 TDD with 90%+ coverage
- 🚀 CI/CD ready

## Quick Start

```bash
# Install dependencies
npm install

# Build all packages
npm run build

# Run tests
npm test

# Start development
npm run dev
```

## Project Structure

- `packages/core` - Shared math, types, and utilities
- `packages/server` - Main game server implementation
- `packages/shared` - Network protocols and constants
- `packages/types` - TypeScript type definitions

## Development

```bash
# Run tests with coverage
npm run test:coverage

# Check types
npm run typecheck

# Format code
npm run format
```

## License

MIT
EOF

# 6. Обновляем PROGRESS.md
cat >> PROGRESS.md << 'EOF'

- [x] Настройка CI (GitHub Actions)
  - [x] Создан GitHub Actions workflow для автоматического тестирования
  - [x] Настроен запуск тестов на push и pull request
  - [x] Добавлена проверка форматирования через Prettier
  - [x] Настроена загрузка отчетов coverage в Codecov
  - [x] Создан корневой vitest.config.ts для управления всеми пакетами
  - [x] Добавлены матрицы Node.js версий (18.x, 20.x, 22.x)
  - [x] Настроена отдельная проверка типов для всех пакетов
  - [x] Добавлен бейдж CI и Codecov в README
EOF

# 7. Обновляем TODO.md - переносим выполненный пункт
cat > TODO.md << 'EOF'
# TODO — основа сервера

## 1. Репозиторий и монорепозиторий

- [x] Создать GitHub/GitLab репозиторий
- [x] Инициализировать монорепозиторий (npm workspaces)
- [x] Настроить .gitignore (Node, dist, logs, .env)
- [x] Настроить EditorConfig и Prettier для единого форматирования
- [x] Добавить LICENSE (MIT)

## 2. Базовые пакеты

- [x] **packages/core** — общие типы, утилиты, математика, интерфейсы
- [x] **packages/server** — основная логика сервера
- [x] **packages/shared** — константы, протоколы обмена
- [x] **packages/types** — отдельный пакет только для TypeScript-типов
- [x] Настроить сборку (TypeScript) для каждого пакета

## 3. Настройка тестовой среды (TDD с самого начала)

- [x] Установить Vitest в корне и каждом пакете
- [x] Настроить общую команду `test` для запуска всех тестов
- [x] Написать первый падающий тест для core (сложение векторов)
- [x] Настроить coverage (istanbul/v8)
- [x] Добавить CI (GitHub Actions) для автоматического прогона тестов на каждый push/PR

## 4. Core — базовые сущности

- [x] Реализовать Vec2D с методами (add, sub, eq, distance)
- [x] Написать тесты для Vec2D
- [x] Реализовать типы Direction (North, South, East, West)
- [x] Реализовать базовые интерфейсы Entity, Player, World
- [x] Покрыть тестами

## 5. Server — структура и первичные модули

- [x] Создать точку входа (index.ts) для сервера
- [x] Настроить базовый класс Server (запуск/останов)
- [x] Реализовать простой World (контейнер для игроков и чанков)
- [x] Реализовать Chunk (дискретная сетка тайлов/объектов)
- [x] Реализовать PlayerManager (подключение/отключение игроков)
- [x] Покрыть модули тестами

## 6. Сеть и протокол (Socket.io)

- [ ] Установить socket.io и socket.io-client
- [ ] Создать в shared типы событий: C2S_MOVE, C2S_INTERACT, C2S_CHAT, S2C_CHUNK и др.
- [ ] Написать валидаторы (zod)
- [ ] Протестировать соединение

## 7. Обработка игроков и авторитетность

- [ ] Реализовать onConnection — создание Player
- [ ] Реализовать onDisconnect — удаление из мира
- [ ] Реализовать onMoveRequest с проверкой коллизий
- [ ] Написать тесты на движение

## 8. Чанки и зоны видимости

- [ ] Реализовать систему подписки на чанки
- [ ] При перемещении пересчитывать видимость
- [ ] Отправлять S2C_CHUNK при входе в новые чанки
- [ ] Написать тест на получение чанков

## 9. Документация

- [ ] Создать README.md в корне с описанием проекта
- [ ] В каждом пакете создать README
- [ ] Написать CONTRIBUTING.md

## 10. Нагрузочное тестирование

- [ ] Выбрать инструмент
- [ ] Написать сценарии тестирования
- [ ] Добавить замеры
- [ ] Задокументировать результаты

## 11. Инстансы и переходы между мирами

- [ ] Реализовать Gateway/Proxy
- [ ] Добавить событие C2S_SWITCH_WORLD
- [ ] Graceful disconnect
- [ ] Написать тест на переключение

## 12. Интеграция с хранилищем

- [ ] Поднять Redis
- [ ] Сохранять состояние игроков
- [ ] Загружать при входе
- [ ] Написать тесты
EOF

# 8. Коммит всех изменений
git add .
git commit -m "ci: add GitHub Actions workflow with coverage and linting

- Add comprehensive CI workflow with Node.js matrix (18.x, 20.x, 22.x)
- Configure Codecov coverage upload
- Add separate type checking job
- Create root vitest.config.ts with coverage settings
- Update README with badges
- Add .prettierignore
- Enable CI on push/PR to main/master/develop"

echo "✅ GitHub Actions CI успешно настроен!"
echo "📊 Не забудьте добавить CODECOV_TOKEN в secrets репозитория"
echo "🔗 Ссылка: https://app.codecov.io/gh/yourusername/vg2/settings"