#!/bin/bash

# 1. Создание файлов core пакета
cat > packages/core/src/types.ts << 'EOF'
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

cat > packages/core/src/vec2d.ts << 'EOF'
export class Vec2D {
  constructor(
    public x: number,
    public y: number
  ) {}

  add(other: Vec2D): Vec2D {
    return new Vec2D(this.x + other.x, this.y + other.y);
  }

  sub(other: Vec2D): Vec2D {
    return new Vec2D(this.x - other.x, this.y - other.y);
  }

  eq(other: Vec2D): boolean {
    return this.x === other.x && this.y === other.y;
  }

  distance(other: Vec2D): number {
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  toString(): string {
    return `Vec2D(${this.x}, ${this.y})`;
  }
}
EOF

cat > packages/core/src/__tests__/vec2d.test.ts << 'EOF'
import { describe, it, expect } from 'vitest';
import { Vec2D } from '../vec2d';

describe('Vec2D', () => {
  it('should create a vector with given coordinates', () => {
    const v = new Vec2D(1, 2);
    expect(v.x).toBe(1);
    expect(v.y).toBe(2);
  });

  it('should add two vectors correctly', () => {
    const v1 = new Vec2D(1, 2);
    const v2 = new Vec2D(3, 4);
    const result = v1.add(v2);
    expect(result.x).toBe(4);
    expect(result.y).toBe(6);
  });

  it('should subtract two vectors correctly', () => {
    const v1 = new Vec2D(5, 7);
    const v2 = new Vec2D(2, 3);
    const result = v1.sub(v2);
    expect(result.x).toBe(3);
    expect(result.y).toBe(4);
  });

  it('should check equality correctly', () => {
    const v1 = new Vec2D(1, 2);
    const v2 = new Vec2D(1, 2);
    const v3 = new Vec2D(2, 1);
    expect(v1.eq(v2)).toBe(true);
    expect(v1.eq(v3)).toBe(false);
  });

  it('should calculate distance correctly', () => {
    const v1 = new Vec2D(0, 0);
    const v2 = new Vec2D(3, 4);
    expect(v1.distance(v2)).toBe(5);
  });

  it('should return string representation', () => {
    const v = new Vec2D(1, 2);
    expect(v.toString()).toBe('Vec2D(1, 2)');
  });
});
EOF

cat > packages/core/src/index.ts << 'EOF'
export * from './vec2d';
export * from './types';
EOF

# 2. Обновление PROGRESS.md
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
- [x] Реализован Vec2D с методами (add, sub, eq, distance)
- [x] Написаны тесты для Vec2D
- [x] Реализованы типы Direction, Entity, Player, World

## В процессе
- [ ] Настройка CI (GitHub Actions)

## Очередь
- [ ] Server — структура и первичные модули
EOF

# 3. Обновление TODO.md (перенос выполненных пунктов)
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
- [ ] Добавить CI (GitHub Actions) для автоматического прогона тестов на каждый push/PR

## 4. Core — базовые сущности
- [x] Реализовать Vec2D с методами (add, sub, eq, distance)
- [x] Написать тесты для Vec2D
- [x] Реализовать типы Direction (North, South, East, West)
- [x] Реализовать базовые интерфейсы Entity, Player, World
- [x] Покрыть тестами

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

# 4. Коммит
git add .
git commit -m "feat(core): implement Vec2D and basic types with tests"
EOF