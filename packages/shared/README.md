# @vg2/shared

Shared constants, network protocols, and validation schemas for VG2.

## Contents

- Socket.io event names (C2S_MOVE, S2C_CHUNK, etc.)
- Zod validation schemas for all events
- Constants (tick rate, max move speed, chunk size)
- TypeScript types derived from schemas

## Installation

```bash
npm install @vg2/shared
```

## Usage

```typescript
import { C2S_MOVE, MoveSchema } from '@vg2/shared';

// Validate incoming move data
const move = MoveSchema.parse(rawData);
```

## License

MIT
