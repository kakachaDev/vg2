#!/bin/bash

# 1. Создание корневого vitest.workspace.js
cat > vitest.workspace.js << 'EOF'
export default [
  "packages/*"
]
EOF

# 2. Создание GitHub Actions workflow
mkdir -p .github/workflows

cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master, develop ]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [20.x]

    steps:
    - uses: actions/checkout@v4

    - name: Use Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'

    - name: Install dependencies
      run: npm ci

    - name: Build packages
      run: npm run build

    - name: Run tests with coverage
      run: npm run test:coverage

    - name: Check formatting
      run: npm run lint

    - name: Upload coverage reports
      uses: codecov/codecov-action@v4
      with:
        token: ${{ secrets.CODECOV_TOKEN }}
        files: ./coverage/coverage-final.json,./packages/core/coverage/coverage-final.json,./packages/server/coverage/coverage-final.json
        flags: unittests
        name: codecov-umbrella
        fail_ci_if_error: false
EOF

# 3. Создание .prettierrc для единого форматирования
cat > .prettierrc << 'EOF'
{
  "semi": true,
  "trailingComma": "all",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "endOfLine": "lf"
}
EOF

# 4. Обновление корневого package.json для добавления CI скриптов
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
    "ci": "npm run lint && npm run build && npm run test:ci"
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

# 5. Обновление vitest.config.ts в каждом пакете для правильной работы coverage
cat > packages/core/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/index.ts', 'src/types.ts'],
    },
  },
})
EOF

cat > packages/server/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/index.ts', 'src/**/types.ts'],
    },
  },
})
EOF

# Создание vitest.config.ts для shared и types
cat > packages/shared/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/index.ts'],
    },
  },
})
EOF

cat > packages/types/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/index.ts'],
    },
  },
})
EOF

# 6. Обновление PROGRESS.md
cat >> PROGRESS.md << 'EOF'

- [x] Настройка CI (GitHub Actions)
  - [x] Создан GitHub Actions workflow для автоматического тестирования
  - [x] Настроен запуск тестов на push и pull request
  - [x] Добавлена проверка форматирования через Prettier
  - [x] Настроена загрузка отчетов coverage в Codecov
  - [x] Создан корневой vitest.workspace.js для управления всеми пакетами
EOF

# 7. Обновление TODO.md (перенос выполненного пункта вниз)
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

# 8. Коммит
git add .
git commit -m "ci: add GitHub Actions workflow with coverage and linting

- Created vitest.workspace.js for multi-package testing
- Added CI workflow for automated testing on push/PR
- Configured coverage reporting for all packages
- Set up Prettier formatting check in CI
- Added Codecov integration for coverage reports"

echo "CI successfully configured! Next steps:"
echo "1. Push to GitHub: git push origin main"
echo "2. Enable GitHub Actions in your repository"
echo "3. (Optional) Add CODECOV_TOKEN secret to GitHub repository for coverage uploads"