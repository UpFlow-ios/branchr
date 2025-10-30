#!/bin/bash

echo "🔍 Checking Branchr CloudKit Entitlements..."
echo "=============================================="

# Check if the project has entitlements file
ENTITLEMENTS_FILE="branchr/branchr.entitlements"
if [ -f "$ENTITLEMENTS_FILE" ]; then
    echo "✅ Entitlements file found: $ENTITLEMENTS_FILE"
    echo ""
    echo "📋 Current entitlements:"
    cat "$ENTITLEMENTS_FILE"
else
    echo "❌ No entitlements file found at: $ENTITLEMENTS_FILE"
    echo "   This means iCloud capability hasn't been added yet."
fi

echo ""
echo "🔧 Next Steps:"
echo "1. In Xcode, select the 'branchr' project"
echo "2. Select the 'branchr' target"
echo "3. Go to 'Signing & Capabilities' tab"
echo "4. Click '+ Capability' and add 'iCloud'"
echo "5. Check the 'CloudKit' checkbox"
echo "6. Add App Groups capability with: group.com.joedormond.branchr"
echo ""
echo "After adding capabilities, run this script again to verify."
