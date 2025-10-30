# Contributing to ShopFast Demo

Thank you for your interest in contributing! This project is designed as an educational demo for Grafana alerting.

## How to Contribute

### Reporting Issues
- Check existing issues first
- Provide clear reproduction steps
- Include your OS and Docker version
- Attach relevant logs

### Suggesting Enhancements
- Describe the use case
- Explain the benefit
- Keep it aligned with the demo purpose

### Pull Requests
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on your platform
5. Update documentation if needed
6. Submit a pull request

## Development Guidelines

### Adding New Scenarios
If you want to add a new simulation scenario:

1. Add the scenario function to `simulation/simulator.py`
2. Update the interactive menu in `run-simulation.sh` and `run-simulation.bat`
3. Document the scenario in `README.md`
4. Test on at least one platform

### Modifying Services
If you modify the microservices:

1. Ensure Prometheus metrics still work
2. Maintain log format for Loki
3. Update alert rules if thresholds change
4. Test that existing alerts still work

### Documentation
- Use clear, concise language
- Include code examples
- Test all commands before documenting
- Update multiple docs if needed (README, USAGE_GUIDE, etc.)

## Code Style

### Shell Scripts
- Use `#!/bin/bash` for Linux/Mac
- Add comments for complex logic
- Handle errors gracefully
- Test on multiple shells if possible

### Python Code
- Follow PEP 8 style guide
- Add docstrings to functions
- Handle exceptions properly
- Keep dependencies minimal

### Docker
- Use official base images
- Minimize image size
- Add labels for maintainability
- Document exposed ports

## Testing

Before submitting:

1. **Test on your platform:**
   ```bash
   docker compose up -d
   ./run-simulation.sh  # Test all scenarios
   ./demo-control.sh    # Test all options
   docker compose down -v
   ```

2. **Verify documentation:**
   - All commands work as documented
   - Links are valid
   - Instructions are clear

3. **Check for breaking changes:**
   - Existing workflows still work
   - Alert rules still fire
   - Services start correctly

## What We're Looking For

### High Priority
- Cross-platform compatibility improvements
- Additional realistic scenarios
- Better error handling
- Performance optimizations
- Documentation improvements

### Medium Priority
- Additional alert types
- More service integrations
- Custom dashboard examples
- Notification channel examples

### Low Priority
- UI/UX improvements to scripts
- Additional metrics
- Alternative deployment methods

## What We're NOT Looking For

- Major architectural changes
- Dependencies that require installation
- Platform-specific features
- Complex configuration requirements

The goal is to keep this demo **simple, portable, and easy to use**.

## Questions?

Open an issue for discussion before starting major work.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping improve this demo! 🚀

