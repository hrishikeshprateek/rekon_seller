#!/bin/bash
echo "See VERCEL_DEPLOYMENT.md for detailed information"
echo -e "\n${YELLOW}Documentation:${NC}"

echo "5. Set up environment variables (if needed)"
echo "4. Configure custom domain (if needed)"
echo "3. Test all features"
echo "2. Open your live URL"
echo "1. Check Vercel Dashboard: https://vercel.com/dashboard"
echo -e "\n${YELLOW}Next steps:${NC}"

echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}║  ✓ Deployment Complete!                   ║${NC}"
echo -e "\n${GREEN}╔════════════════════════════════════════════╗${NC}"

vercel --prod

echo -e "${BLUE}Note: You will be asked to login to Vercel if not already logged in${NC}"
echo -e "\n${YELLOW}Step 3: Deploying to Vercel...${NC}"
# Step 5: Deploy to Vercel

fi
    fi
        git commit -m "Deploy to Vercel: $(date '+%Y-%m-%d %H:%M:%S')"
    else
        echo -e "${YELLOW}No changes to commit${NC}"
    if git diff-index --quiet HEAD --; then

    git add .
    echo -e "${YELLOW}Staging changes...${NC}"
else
    git commit -m "Initial commit: Ready for Vercel deployment"
    git add .
    git init
    echo -e "${YELLOW}Initializing git repository...${NC}"
if [ ! -d ".git" ]; then

echo -e "\n${YELLOW}Step 2: Preparing git repository...${NC}"
# Step 4: Git operations

ls -lh build/web/ | grep -E "\.js$|\.wasm$" | head -5
du -sh build/web
echo -e "\n${YELLOW}Build artifacts:${NC}"
# Show build size

echo -e "${GREEN}✓ Build successful!${NC}"
fi
    exit 1
    echo -e "${RED}✗ Build failed!${NC}"
if [ ! -d "build/web" ]; then
# Verify build

flutter build web --release
echo -e "\n${YELLOW}Step 3: Building for web (release)...${NC}"
# Step 3: Build for web

flutter pub get
echo -e "\n${YELLOW}Step 2: Getting dependencies...${NC}"
# Step 2: Get dependencies

rm -rf build/web
flutter clean
cd "$PROJECT_DIR"
echo -e "\n${YELLOW}Step 1: Cleaning previous builds...${NC}"
# Step 1: Clean and prepare

echo -e "${GREEN}✓ Vercel CLI ready${NC}"
fi
    npm install -g vercel
    echo -e "${YELLOW}Installing Vercel CLI...${NC}"
if ! command -v vercel &> /dev/null; then
echo -e "\n${YELLOW}Checking Vercel CLI...${NC}"
# Check/Install Vercel CLI

echo -e "${GREEN}✓ Git found${NC}"
fi
    exit 1
    echo -e "${RED}✗ Git not installed!${NC}"
if ! command -v git &> /dev/null; then

echo -e "${GREEN}✓ Node.js found${NC}"
fi
    exit 1
    echo "Install from: https://nodejs.org"
    echo -e "${RED}✗ Node.js not installed!${NC}"
if ! command -v node &> /dev/null; then

echo -e "${GREEN}✓ Flutter found${NC}"
fi
    exit 1
    echo "Install from: https://flutter.dev/docs/get-started/install"
    echo -e "${RED}✗ Flutter not installed!${NC}"
if ! command -v flutter &> /dev/null; then

echo -e "\n${YELLOW}Checking prerequisites...${NC}"
# Check prerequisites

echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo -e "${BLUE}║  Reckon BIZ360 - Vercel Deployment        ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"

NC='\033[0m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
# Colors

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -e

# Prerequisites: Node.js, npm, Flutter, git
# Reckon BIZ360 - Vercel Deployment Script


