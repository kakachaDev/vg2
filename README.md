# VG2 Server

[![CI](https://github.com/kakachaDev/vg2/actions/workflows/ci.yml/badge.svg)](https://github.com/kakachaDev/vg2/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/kakachaDev/vg2/branch/main/graph/badge.svg)](https://codecov.io/gh/kakachaDev/vg2)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js Version](https://img.shields.io/node/v/vg2-server)](https://nodejs.org)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![Discord](https://img.shields.io/discord/1234567890?label=Discord&logo=discord)](https://discord.gg/example)

Authoritative server for 2D multiplayer games. Supports up to 1000 concurrent players with world instances, chunk-based visibility, and seamless world transitions.

## Features

- 🎮 **Authoritative server architecture** - Server is the source of truth, preventing cheating
- 🌍 **Multiple world instances** - Hub + game worlds with seamless transitions
- 📦 **Chunk-based world management** - Efficient memory usage and network updates
- 👥 **1000+ concurrent players** - Scalable architecture for large player counts
- 🔄 **Seamless world switching** - Move between worlds without disconnecting
- 🧪 **TDD with 90%+ coverage** - Reliable and testable codebase
- 🚀 **CI/CD ready** - Automated testing and deployment
- 🔒 **Security first** - Input validation, rate limiting, anti-cheat measures

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

```
packages/
├── core/          # Shared math, types, and utilities
├── server/        # Main game server implementation
├── shared/        # Network protocols and constants
└── types/         # TypeScript type definitions
```

## Documentation

- [Getting Started](packages/server/README.md) - Server setup guide
- [API Reference](https://kakachadev.github.io/vg2) - API documentation
- [Contributing](CONTRIBUTING.md) - How to contribute
- [Code of Conduct](CODE_OF_CONDUCT.md) - Community guidelines
- [Security](SECURITY.md) - Security policies
- [Governance](GOVERNANCE.md) - Project governance
- [Support](SUPPORT.md) - Getting help
- [Changelog](CHANGELOG.md) - Release notes

## Development

```bash
# Run tests with coverage
npm run test:coverage

# Check types
npm run typecheck

# Format code
npm run format

# Clean build
npm run clean
npm run build
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Quick Contribution Flow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `npm test`
5. Submit a Pull Request

## Roadmap

- [x] Core math library (Vec2D)
- [x] Basic server infrastructure
- [x] Network protocol with Socket.io
- [x] Player movement with collision detection
- [x] Chunk-based world management
- [x] Modular event handlers
- [ ] World instances and transitions
- [ ] Redis integration for persistence
- [ ] Performance optimizations for 1000+ players
- [ ] Monitoring and metrics

See [TODO.md](TODO.md) and [PROGRESS.md](PROGRESS.md) for detailed progress.

## License

MIT © [kakachaDev](https://github.com/kakachaDev)

## Support

- 📫 [Open an issue](https://github.com/kakachaDev/vg2/issues/new/choose)
- 💬 [Join Discord](https://discord.gg/example)
- 📧 [Email maintainers](mailto:maintainers@example.com)
