#!/usr/bin/env python3
"""Type-check exported SwiftUI source. Does not link or package an iOS app."""
import json,pathlib,subprocess,sys
base=pathlib.Path(__file__).resolve().parents[1]/'.artifacts/platform-exports'
root=pathlib.Path(sys.argv[1]) if len(sys.argv)>1 else pathlib.Path(json.loads((base/'paths.json').read_text())['swiftui'])
sdk=subprocess.check_output(['xcrun','--sdk','iphonesimulator','--show-sdk-path'],text=True).strip()
files=sorted((root/'Sources/GeneratedUI').glob('*.swift'))
if not files:raise SystemExit('No exported SwiftUI source found')
result=subprocess.run(['xcrun','swiftc','-typecheck','-sdk',sdk,'-target','arm64-apple-ios17.0-simulator','-module-name','GeneratedUI',*map(str,files)])
if result.returncode:raise SystemExit(result.returncode)
print('SWIFTUI_TYPECHECK_PASS · no mobile package generated')
