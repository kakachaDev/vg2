#!/bin/bash

# Исправляем проблему с расширениями файлов в импортах (ES Modules)

# 1. Исправляем tsconfig.json в core для использования Classic resolution вместо NodeNext
cat > packages/core/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "lib": ["ES2020"],
    "target": "ES2020",
    "module": "CommonJS",
    "moduleResolution": "node",
    "types": ["node"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF

# 2. Исправляем tsconfig.json в server
cat > packages/server/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "lib": ["ES2020"],
    "target": "ES2020",
    "module": "CommonJS",
    "moduleResolution": "node",
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

# 3. Исправляем корневой tsconfig.json
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "CommonJS",
    "moduleResolution": "node",
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

# 4. Исправляем package.json во всех пакетах - меняем type: module на commonjs
cat > packages/core/package.json << 'EOF'
{
  "name": "@vg2/core",
  "version": "1.0.0",
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

# 5. Исправляем корневой package.json - убираем type: module
cat > package.json << 'EOF'
{
  "name": "vg2",
  "version": "1.0.0",
  "description": "Voxel Game 2 - Server",
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

# 6. Переустанавливаем зависимости и собираем
echo "=== Переустановка зависимостей ==="
rm -rf node_modules package-lock.json
npm install

echo "=== Сборка проекта ==="
npm run build

echo "=== Запуск тестов ==="
npm run test

echo "=== Проверка покрытия ==="
npm run test:coverage

# 7. Обновляем PROGRESS.md
cat >> PROGRESS.md << 'EOF'
- [x] Исправлены проблемы с ES Modules
  - [x] Переключено с NodeNext на CommonJS
  - [x] Убран type: module из package.json
  - [x] Исправлены tsconfig.json во всех пакетах
  - [x] Сборка теперь работает без ошибок
EOF

# 8. Коммит исправлений
git add .
git commit -m "fix: switch from ES Modules to CommonJS

- Change module resolution from NodeNext to node
- Remove type: module from all package.json files
- Fix TypeScript compilation errors
- All imports now work without .js extensions"
EOF