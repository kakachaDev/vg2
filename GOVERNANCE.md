# Project Governance

## Overview

VG2 is an open-source project governed by a **Benevolent Dictator for Life (BDFL)** model with core maintainers. This document outlines how decisions are made, how contributors can get involved, and how the project is structured.

## Roles

### Users

Anyone using the VG2 server for their projects. User feedback is invaluable and helps shape the direction of the project.

### Contributors

Anyone who contributes to the project in the form of:

- Code changes via Pull Requests
- Bug reports via Issues
- Documentation improvements
- Community support
- Feature suggestions

### Maintainers

Trusted contributors who have shown consistent, high-quality contributions. Maintainers have:

- Write access to the repository
- Ability to review and merge PRs
- Vote on project decisions
- Responsibility to review code in a timely manner

Current maintainers:

- [@kakachaDev] - Project Lead

### Technical Steering Committee (TSC)

For major architectural decisions, we may form a TSC consisting of maintainers with significant expertise in specific areas:

- Core Engine
- Network Protocol
- Performance Optimization

## Decision Making Process

### Day-to-day decisions

Made by maintainers reviewing PRs. If there's consensus, changes can be merged. If there's disagreement:

1. Discuss in PR comments
2. Seek input from other maintainers
3. Escalate to Project Lead if needed

### Major Decisions

Changes that affect:

- Public API
- Network protocol
- Core architecture
- Performance characteristics

Process:

1. Create a GitHub Issue with detailed proposal
2. Tag with `proposal` label
3. Discussion period: minimum 7 days
4. Decision by consensus or Project Lead

## Contribution Process

1. Pick an issue or propose a change
2. Discuss implementation approach
3. Write code + tests
4. Submit PR
5. Address review feedback
6. PR merged by maintainer

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Release Process

### Versioning

We follow [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (non-breaking)
- **PATCH**: Bug fixes

### Release Steps

1. Update CHANGELOG.md
2. Update version in package.json
3. Create release branch
4. Run full test suite
5. Create GitHub Release
6. Publish to npm

## Communication

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and community support
- **Discord/Slack**: Real-time chat (link in README)

## Code of Conduct

All participants are expected to follow our [Code of Conduct](CODE_OF_CONDUCT.md). Maintainers are responsible for enforcing it.

## Recognition

Contributors are recognized in:

- Release notes
- Project README (significant contributors)
- All Contributors bot (all contributors)

## Changes to Governance

Proposals to change governance follow the same process as Major Decisions, with the addition of:

- Must be announced to community
- Minimum 30 day discussion period
- 2/3 maintainer approval required
