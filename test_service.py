#!/usr/bin/env python3
"""Simple test script that just prints and exits."""

import sys
import time

def main():
    print("=== Test Service Starting ===")
    print("This is a test service that should not hang")
    
    # Just print some messages and exit
    for i in range(5):
        print(f"Test message {i+1}/5")
        time.sleep(1)
    
    print("=== Test Service Complete ===")
    return 0

if __name__ == "__main__":
    sys.exit(main())




