#!/bin/bash
# HelloU Package Testing Script
# This script verifies the installation and functionality of the HelloU package

set -e

# Print colorized output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================${NC}"
echo -e "${BLUE}= HelloU Package Test Suite =${NC}"
echo -e "${BLUE}============================${NC}"
echo

# Check if we're running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root (sudo)${NC}"
  exit 1
fi

# Create a temporary directory for testing
TEST_DIR=$(mktemp -d)
PACKAGE_PATH="/home/hxman/Projects/face-recog/hellou-fixed-1.0.0-final.deb"

echo -e "${YELLOW}Testing package: ${PACKAGE_PATH}${NC}"
echo -e "${YELLOW}Using temporary directory: ${TEST_DIR}${NC}"
echo

# Function to run a test
run_test() {
  local test_name=$1
  local test_cmd=$2
  
  echo -e "${BLUE}Testing: ${test_name}${NC}"
  echo -e "${YELLOW}Command: ${test_cmd}${NC}"
  
  if eval "$test_cmd"; then
    echo -e "${GREEN}✓ Test Passed: ${test_name}${NC}"
    return 0
  else
    echo -e "${RED}✗ Test Failed: ${test_name}${NC}"
    return 1
  fi
  echo
}

# Function to clean up
cleanup() {
  echo -e "${YELLOW}Cleaning up...${NC}"
  cd /
  rm -rf "$TEST_DIR"
  echo -e "${GREEN}Done!${NC}"
}

# Register cleanup on exit
trap cleanup EXIT

# Start tests
echo -e "${BLUE}Starting tests...${NC}"
echo

# Test 1: Package info
run_test "Package Info" "dpkg-deb -I $PACKAGE_PATH"

# Test 2: Package contents
run_test "Package Contents" "dpkg-deb -c $PACKAGE_PATH | grep -E 'bin|etc|lib|usr'"

# Test 3: Package install
run_test "Package Installation" "dpkg -i $PACKAGE_PATH"

# Test 4: Check systemd service
run_test "Systemd Service" "systemctl status face-unlock.service"

# Test 5: Check executable 
run_test "Executable" "which hellou && hellou --help"

# Test 6: Check uninstall executable
run_test "Uninstall Script" "which uninstall-hellou && uninstall-hellou --help"

# Test 7: Check man pages
run_test "Man Pages" "man -w hellou && man -w uninstall-hellou"

# Test 8: Check PAM configuration
run_test "PAM Configuration" "grep -r hellou /etc/pam.d/"

# Test 9: Check file permissions
run_test "File Permissions" "find /etc/hellou /usr/lib/python3/dist-packages/hellou -type f -exec ls -l {} \\; | grep -v '^-rw-r--r-- 1 root root'"

# Test 10: Cleanup
echo -e "${BLUE}Removing package for cleanup...${NC}"
apt-get -y remove hellou

echo -e "${BLUE}============================${NC}"
echo -e "${BLUE}= Test Suite Complete      =${NC}"
echo -e "${BLUE}============================${NC}"
