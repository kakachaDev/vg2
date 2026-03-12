# @vg2/server

Authoritative game server for VG2. Handles player connections, world simulation, and network communication.

## Features

- WebSocket server (Socket.io) with event validation (zod)
- Player management (connection, disconnection, movement)
- Chunk-based world with collision detection
- Authority-based movement and validation
- Rate limiting and out-of-order protection
- Support for 1000+ concurrent players

## Installation

```bash
npm install @vg2/server
```

## Quick Start

```typescript
import { Server } from '@vg2/server';

const server = new Server({
  port: 3000,
  worldConfig: {
    chunkSize: 16,
    viewDistance: 2,
  },
});

server.start();
```

## License

MIT
