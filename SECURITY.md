# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible for receiving such patches depends on the CVSS v3.0 rating:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

Please report (suspected) security vulnerabilities to **[INSERT SECURITY EMAIL]**. You will receive a response from us within 48 hours. If the issue is confirmed, we will release a patch as soon as possible depending on complexity.

### Please do the following:

- Describe the vulnerability
- Provide steps to reproduce
- Include the version you tested on
- If you have a fix, that's great! Please attach it

### What to expect:

- We will acknowledge receipt within 48 hours
- We will provide a timeline for fix
- We will notify you when fixed
- We will credit you (unless you prefer to remain anonymous)

## Security Measures in VG2

### Network Layer
- All socket connections are validated
- Rate limiting prevents DoS attacks
- Input validation using Zod schemas

### Game Logic
- Authoritative server prevents client cheating
- Movement validation prevents speed hacks
- Collision detection prevents wall hacks

### Data Storage
- No sensitive data in memory
- Redis encryption for stored sessions
- Regular security audits

## Disclosure Policy

We follow the principle of [Responsible Disclosure](https://en.wikipedia.org/wiki/Responsible_disclosure).
