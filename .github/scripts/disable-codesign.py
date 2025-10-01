#!/usr/bin/env python3
"""
Script to disable code signing in Xcode project for unsigned builds.
This modifies the project.pbxproj file to allow building without certificates.
"""

import re
import sys

def disable_code_signing(pbxproj_path):
    """Disable code signing in the Xcode project file."""
    try:
        with open(pbxproj_path, 'r') as f:
            content = f.read()
        
        # Replace code signing settings
        replacements = [
            (r'CODE_SIGN_IDENTITY = "Apple Development";', 'CODE_SIGN_IDENTITY = "";'),
            (r'CODE_SIGN_IDENTITY = "iPhone Developer";', 'CODE_SIGN_IDENTITY = "";'),
            (r'CODE_SIGN_STYLE = Automatic;', 'CODE_SIGN_STYLE = Manual;'),
            (r'DEVELOPMENT_TEAM = [^;]+;', 'DEVELOPMENT_TEAM = "";'),
            (r'"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "iPhone Developer";', '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "";'),
        ]
        
        for pattern, replacement in replacements:
            content = re.sub(pattern, replacement, content)
        
        # Add CODE_SIGNING_REQUIRED and CODE_SIGNING_ALLOWED if not present
        if 'CODE_SIGNING_REQUIRED' not in content:
            # Find buildSettings sections and add the flags
            content = re.sub(
                r'(buildSettings = \{[^}]*CURRENT_PROJECT_VERSION[^}]*)',
                r'\1\n\t\t\t\tCODE_SIGNING_REQUIRED = NO;\n\t\t\t\tCODE_SIGNING_ALLOWED = NO;',
                content
            )
        
        # Write back
        with open(pbxproj_path, 'w') as f:
            f.write(content)
        
        print("✅ Successfully disabled code signing in Xcode project")
        return True
        
    except Exception as e:
        print(f"❌ Error modifying project file: {e}")
        return False

if __name__ == "__main__":
    pbxproj_path = "ios/Runner.xcodeproj/project.pbxproj"
    success = disable_code_signing(pbxproj_path)
    sys.exit(0 if success else 1)

