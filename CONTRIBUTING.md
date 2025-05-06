# Contributing to LaunchKit

Thank you for considering contributing to LaunchKit! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please be respectful and considerate of others.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in the Issues.
2. Create a new issue, providing:
   - A clear title and description
   - Steps to reproduce the issue
   - Expected and actual results
   - Version information (OS, Docker, etc.)
   - Any relevant logs or screenshots

### Suggesting Features

1. Check if the feature has already been suggested in the Issues.
2. Create a new issue with the label "enhancement", providing:
   - A clear title and description
   - The rationale for the feature
   - How it would work (if you have ideas)

### Pull Request Process

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/my-feature`).
3. Make your changes, following our coding standards.
4. Run tests to ensure they pass.
5. Update documentation as necessary.
6. Submit a pull request to the `main` branch.

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/launchkit.git
   cd launchkit
   ```

2. Run the initialization script in development mode:
   ```bash
   ./scripts/init.sh
   ```

3. Make your changes and test them.

## Coding Standards

### Python (Django)

- Follow PEP 8 style guide
- Use Black for formatting
- Use isort for import sorting
- Write docstrings for functions and classes
- Include unit tests for new functionality

### JavaScript/TypeScript (Next.js)

- Follow Prettier formatting
- Use ESLint for linting
- Use TypeScript for type safety
- Write Jest tests for components and utilities

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters
- Reference issues and pull requests after the first line

## Developer Certificate of Origin (DCO)

By contributing to this project, you certify that:

1. The contribution was created in whole or in part by you.
2. You have the right to submit it under the open source license used by this project.
3. You understand and agree that your contribution may be used by the project maintainers and the community.

## Questions?

If you have questions about contributing, please open an issue with the label "question". 