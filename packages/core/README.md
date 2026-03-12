# @vg2/core

Core shared utilities and types for VG2 server.

## Features

- `Vec2D` - 2D vector math (add, sub, eq, distance, etc.)
- Direction types (North, South, East, West)
- Base interfaces: `Entity`, `Player`, `World`
- Common types used across server and client

## Installation

```bash
npm install @vg2/core
```

## Usage

```typescript
import { Vec2D } from '@vg2/core';

const v1 = new Vec2D(1, 2);
const v2 = new Vec2D(3, 4);
const sum = v1.add(v2); // Vec2D(4, 6)
```

## License

MIT
