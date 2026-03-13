# Support

## Getting Help

If you need help with VG2, here are the best ways to get it:

### Documentation
- [README.md](README.md) - Quick start guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute
- [SECURITY.md](SECURITY.md) - Security policies
- Package READMEs in each package directory

### Community Support
- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For questions and community help
- **Discord/Slack**: Real-time chat (links coming soon)

### Professional Support
For commercial support, custom development, or consulting:
- Contact the maintainers directly
- Hire a contributor (see [GOVERNANCE.md](GOVERNANCE.md) for contributor list)

## Common Issues

### Installation Problems
```bash
# Clean install
npm run clean
npm install
```

### Build Errors
```bash
# Clean builds
npm run clean
npm run build

# Check TypeScript version
npx tsc --version
```

### Test Failures
```bash
# Run tests with more details
npm run test:coverage

# Check specific package
cd packages/server && npm test
```

## Reporting Issues

Before reporting an issue:
1. Check existing issues (open and closed)
2. Check documentation
3. Try the latest version
4. Provide minimal reproduction

Good bug reports include:
- VG2 version
- Node.js version
- OS version
- Steps to reproduce
- Expected vs actual behavior
- Logs/error messages

## Feature Requests

When requesting features:
- Explain the use case
- Describe expected behavior
- Provide examples if possible
- Consider alternatives

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Code style guide
- Test requirements
- PR process

## Stay Updated

- Watch releases on GitHub
- Join discussions
- Follow contributors

## License

MIT - See [LICENSE](LICENSE) file
