#!/bin/bash

echo "📁 Creating asset directories..."

# Create assets directories
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/fonts

# Create .gitkeep files to ensure directories are tracked by git
touch assets/images/.gitkeep
touch assets/icons/.gitkeep
touch assets/fonts/.gitkeep

echo "✅ Asset directories created!"
echo "📝 You can now add your assets to these directories:"
echo "   - assets/images/ (for images)"
echo "   - assets/icons/ (for icons)"
echo "   - assets/fonts/ (for custom fonts)"
