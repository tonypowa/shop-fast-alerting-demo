#!/bin/bash
# Git commit script for demo-alerting-stack

# Add all files
git add .

# Show what will be committed
echo "Files to be committed:"
git status --short

echo ""
echo "Commit message preview:"
cat COMMIT_MESSAGE.txt

echo ""
read -p "Proceed with commit? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    git commit -F COMMIT_MESSAGE.txt
    echo "✓ Committed successfully!"
    echo ""
    echo "To push to remote:"
    echo "  git push origin main"
fi

