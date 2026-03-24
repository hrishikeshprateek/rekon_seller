#!/bin/bash

# Reckon BIZ360 - Web Deployment Script
# Usage: ./deploy.sh [firebase|vercel|netlify|local]

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build/web"
DEPLOYMENT_METHOD="${1:-firebase}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Reckon BIZ360 - Web Deployment Script     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"

# Step 1: Clean and prepare
echo -e "\n${YELLOW}Step 1: Cleaning previous builds...${NC}"
flutter clean
rm -rf "$BUILD_DIR"

# Step 2: Get dependencies
echo -e "\n${YELLOW}Step 2: Getting dependencies...${NC}"
flutter pub get

# Step 3: Build for web
echo -e "\n${YELLOW}Step 3: Building for web (release)...${NC}"
flutter build web --release

# Step 4: Verify build
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}✗ Build failed! build/web directory not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build successful!${NC}"

# List build output
echo -e "\n${YELLOW}Build Output:${NC}"
ls -lh "$BUILD_DIR" | head -20

# Step 5: Deploy based on method
case "$DEPLOYMENT_METHOD" in
    firebase)
        echo -e "\n${YELLOW}Step 4: Deploying to Firebase Hosting...${NC}"

        if ! command -v firebase &> /dev/null; then
            echo -e "${RED}✗ Firebase CLI not installed!${NC}"
            echo "Install with: npm install -g firebase-tools"
            exit 1
        fi

        firebase deploy --only hosting
        echo -e "${GREEN}✓ Deployed to Firebase!${NC}"
        firebase open hosting:site
        ;;

    vercel)
        echo -e "\n${YELLOW}Step 4: Deploying to Vercel...${NC}"

        if ! command -v vercel &> /dev/null; then
            echo -e "${RED}✗ Vercel CLI not installed!${NC}"
            echo "Install with: npm i -g vercel"
            exit 1
        fi

        cd "$BUILD_DIR"
        vercel --prod
        cd "$PROJECT_DIR"
        echo -e "${GREEN}✓ Deployed to Vercel!${NC}"
        ;;

    local)
        echo -e "\n${YELLOW}Step 4: Starting local server...${NC}"
        cd "$BUILD_DIR"
        echo -e "${GREEN}✓ Starting server on http://localhost:8000${NC}"
        echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
        python3 -m http.server 8000
        ;;

    *)
        echo -e "${RED}✗ Unknown deployment method: $DEPLOYMENT_METHOD${NC}"
        echo "Usage: ./deploy.sh [firebase|vercel|netlify|local]"
        exit 1
        ;;
esac

echo -e "\n${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Deployment Complete!                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"

