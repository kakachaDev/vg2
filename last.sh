#!/bin/bash

# 1. Создание корневой структуры
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

cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnpm-store/
.npm/

# Build outputs
dist/
build/
lib/
*.tsbuildinfo

# Environment
.env
.env.local
.env.*.local

# Logs
logs/
*.log
npm-debug.log*
pnpm-debug.log*

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# Coverage
coverage/
.nyc_output/

# Temp files
tmp/
temp/
EOF

cat > .editorconfig << 'EOF'
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false
EOF

cat > .prettierrc << 'EOF'
{
  "semi": true,
  "trailingComma": "all",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "endOfLine": "lf"
}
EOF

cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2026 VG2 Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

cat > vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
    },
  },
});
EOF

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2022"],
    "types": ["vitest/globals"],
    "strict": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "exclude": ["node_modules", "dist"]
}
EOF

# 2. Создание пакетов
mkdir -p packages/core/src
mkdir -p packages/server/src
mkdir -p packages/shared/src
mkdir -p packages/types/src

# Core package
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
    "typescript": "^5.4.5",
    "vitest": "^1.5.0"
  }
}
EOF

cat > packages/core/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF

cat > packages/core/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
  },
});
EOF

# Server package
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
  "devDependencies": {
    "typescript": "^5.4.5",
    "vitest": "^1.5.0"
  }
}
EOF

cat > packages/server/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF

cat > packages/server/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
  },
});
EOF

# Shared package
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
    "typescript": "^5.4.5",
    "vitest": "^1.5.0"
  }
}
EOF

cat > packages/shared/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF

cat > packages/shared/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
  },
});
EOF

# Types package
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
    "typescript": "^5.4.5",
    "vitest": "^1.5.0"
  }
}
EOF

cat > packages/types/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF

cat > packages/types/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
  },
});
EOF

# 3. Начальные файлы для каждого пакета
cat > packages/core/src/index.ts << 'EOF'
export const VERSION = '1.0.0';
EOF

cat > packages/server/src/index.ts << 'EOF'
export const VERSION = '1.0.0';
EOF

cat > packages/shared/src/index.ts << 'EOF'
export const VERSION = '1.0.0';
EOF

cat > packages/types/src/index.ts << 'EOF'
export const VERSION = '1.0.0';
EOF

# 4. Обновление PROGRESS.md
cat > PROGRESS.md << 'EOF'
# Прогресс выполнения

## Выполнено
- [x] Создана корневая структура монорепозитория
- [x] Настроен .gitignore
- [x] Настроен EditorConfig и Prettier
- [x] Добавлена MIT License
- [x] Созданы базовые пакеты: core, server, shared, types
- [x] Настроена TypeScript конфигурация для всех пакетов
- [x] Настроена тестовая инфраструктура Vitest

## В процессе
- [ ] Реализация Vec2D в core пакете

## Очередь
- [ ] Настройка CI (GitHub Actions)
- [ ] Написание первого падающего теста
EOF

# 5. Обновление TODO.md
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
- [ ] Написать первый падающий тест для core (например, сложение векторов)
- [ ] Настроить coverage (istanbul/v8)
- [ ] Добавить CI (GitHub Actions) для автоматического прогона тестов на каждый push/PR

## 4. Core — базовые сущности
- [ ] Реализовать Vec2D с методами (add, sub, eq, distance)
- [ ] Написать тесты для Vec2D
- [ ] Реализовать типы Direction (North, South, East, West)
- [ ] Реализовать базовые интерфейсы Entity, Player, World
- [ ] Покрыть тестами

## 5. Server — структура и первичные модули
- [ ] Создать точку входа (index.ts) для сервера
- [ ] Настроить базовый класс Server (запуск/останов)
- [ ] Реализовать простой World (контейнер для игроков и чанков)
- [ ] Реализовать Chunk (дискретная сетка тайлов/объектов)
- [ ] Реализовать PlayerManager (подключение/отключение игроков)
- [ ] Покрыть модули тестами

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

# 6. Инициализация git и первый коммит
git init
git add .
git commit -m "Initial commit: project structure with npm workspaces"

echo "\n✅ Проект успешно инициализирован!"
echo "📦 Структура монорепозитория создана"
echo "🔧 Для начала работы выполните:"
echo "  npm install"
echo "  npm test"