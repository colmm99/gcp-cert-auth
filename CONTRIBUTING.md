# Contributing to GCP Certificate Authority Terraform Configuration

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and constructive in all interactions with other contributors.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion for improvement:

1. Check if the issue already exists in the GitHub Issues
2. If not, create a new issue with:
   - A clear, descriptive title
   - Detailed description of the issue or suggestion
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Your environment (Terraform version, GCP region, etc.)

### Submitting Changes

1. **Fork the Repository**
   ```bash
   git clone https://github.com/colmm99/gcp-cert-auth.git
   cd gcp-cert-auth
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**
   - Follow the existing code style
   - Update documentation as needed
   - Add comments for complex logic
   - Test your changes thoroughly

4. **Test Your Changes**
   ```bash
   # Format Terraform code
   terraform fmt -recursive
   
   # Validate configuration
   terraform validate
   
   # Test deployment (if possible)
   terraform plan
   ```

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "Description of your changes"
   ```

6. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Go to the original repository on GitHub
   - Click "New Pull Request"
   - Select your branch
   - Provide a clear description of your changes

## Development Guidelines

### Terraform Code Style

- Use consistent indentation (2 spaces)
- Run `terraform fmt` before committing
- Add meaningful variable descriptions
- Use validation blocks for input variables where appropriate
- Comment complex resource configurations

### Documentation

- Update README.md if you add new features
- Update terraform.tfvars.example with new variables
- Add inline comments for complex logic
- Keep examples up to date

### Variables

- Use descriptive variable names
- Provide sensible defaults where possible
- Add validation rules for critical variables
- Document expected formats and examples

### Security

- Never commit sensitive data (credentials, keys, etc.)
- Use variables for all environment-specific values
- Follow GCP security best practices
- Test IAM permissions carefully

## Testing Checklist

Before submitting a pull request, ensure:

- [ ] Code is formatted with `terraform fmt`
- [ ] Configuration passes `terraform validate`
- [ ] All variables have descriptions
- [ ] Documentation is updated
- [ ] Examples are tested and working
- [ ] No sensitive data is committed
- [ ] Changes are backwards compatible (or breaking changes are documented)

## Questions?

If you have questions about contributing, feel free to:
- Open an issue for discussion
- Reach out to the maintainers

Thank you for contributing! 🎉
