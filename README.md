# VG2 - Voxel Game 2 Server

[![CI](https://github.com/kakachaDev/vg2/actions/workflows/ci.yml/badge.svg)](https://github.com/kakachaDev/vg2/actions/workflows/ci.yml)
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
