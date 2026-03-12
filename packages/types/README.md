# @vg2/types

TypeScript type definitions shared across VG2 server and client.

## Contents

- Core interfaces (`Entity`, `Player`, `World`)
- Direction enums
- Re-exported types from core and shared for convenience
- Utility types

## Installation

```bash
npm install @vg2/types
```

## Usage

```typescript
import { Player, Direction } from '@vg2/types';

const player: Player = {
  id: 'p1',
  position: { x: 0, y: 0 },
  direction: Direction.North,
};
```

## License

MIT
