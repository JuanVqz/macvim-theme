# Publishing Guide

This guide will help you publish the MacVim theme to the VS Code Marketplace.

## Prerequisites

1. **Install vsce (VS Code Extension Manager)**
   ```bash
   npm install -g @vscode/vsce
   ```

2. **Create a Publisher Account**
   - Go to https://marketplace.visualstudio.com/manage
   - Sign in with your Microsoft/GitHub account
   - Create a new publisher (note the publisher ID)

3. **Update package.json**
   - Replace `"your-publisher-name"` with your actual publisher name
   - Update the repository URL if you have one
   - Add an icon.png file (128x128 pixels recommended)

## Publishing Steps

1. **Login to VS Code Marketplace**
   ```bash
   vsce login <your-publisher-name>
   ```
   Or use a Personal Access Token:
   ```bash
   vsce publish -p <your-personal-access-token>
   ```

2. **Package the Extension**
   ```bash
   vsce package
   ```
   This creates a `.vsix` file that you can test locally.

3. **Publish the Extension**
   ```bash
   vsce publish
   ```

## Testing Locally

Before publishing, test the extension locally:

1. **Install the extension from VSIX**
   - Open VS Code
   - Go to Extensions view
   - Click "..." menu
   - Select "Install from VSIX..."
   - Choose the generated `.vsix` file

2. **Test the Theme**
   - Open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)
   - Type "Preferences: Color Theme"
   - Select "MacVim"
   - Verify the colors look correct

## Updating the Extension

When you make changes:

1. Update the version in `package.json` (follow semantic versioning)
2. Update `CHANGELOG.md` with your changes
3. Run `vsce publish` again

## Important Notes

- The `publisher` field in `package.json` must match your publisher account
- Make sure all required fields in `package.json` are filled out
- The extension will be available on the marketplace after publishing
- You can unpublish or update the extension from the marketplace management page

## Resources

- [VS Code Extension Publishing Guide](https://code.visualstudio.com/api/working-with-extensions/publishing-extension)
- [vsce Documentation](https://github.com/microsoft/vscode-vsce)
- [VS Code Extension API](https://code.visualstudio.com/api)

