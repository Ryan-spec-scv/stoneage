# Building VMProtectSDK32.dll (Dummy Version)

This folder contains a dummy implementation of VMProtectSDK32.dll for testing purposes.

## Why Dummy DLL?

VMProtect is commercial software protection. For development and testing, this dummy DLL:
- Disables debugger detection (returns FALSE)
- Disables VM detection (returns FALSE)
- Passes through encrypted strings unchanged
- Allows normal program execution without protection

## Compilation Instructions

### Option 1: Using Visual Studio Command Prompt (Recommended)

1. Open "Developer Command Prompt for VS 2022" or "x86 Native Tools Command Prompt"

2. Navigate to the dll folder:
```cmd
cd C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client\dll
```

3. Compile the DLL:
```cmd
cl /LD /O2 VMProtectSDK_dummy.cpp /Fe:VMProtectSDK32.dll kernel32.lib /link /DEF:VMProtectSDK32.def
```

**Note**: The `/DEF:VMProtectSDK32.def` is crucial - it ensures function names are exported correctly without C++ name mangling.

### Option 2: Using CMake (Alternative)

1. Create `CMakeLists.txt` in the dll folder:
```cmake
cmake_minimum_required(VERSION 3.10)
project(VMProtectSDK32)

add_library(VMProtectSDK32 SHARED VMProtectSDK_dummy.cpp)
set_target_properties(VMProtectSDK32 PROPERTIES
    OUTPUT_NAME "VMProtectSDK32"
    SUFFIX ".dll"
)
```

2. Build:
```cmd
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -A Win32
cmake --build . --config Release
```

### Option 3: Using Online Compiler

If you don't have Visual Studio installed, you can:
1. Copy the VMProtectSDK_dummy.cpp content
2. Use an online C++ compiler (e.g., https://www.onlinegdb.com/)
3. Compile as DLL and download

## Installation

After compilation, copy the VMProtectSDK32.dll to:
```
C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client\Win32\VER25_RELEASE\
```

## Verification

Test if the DLL is working:
```cmd
cd C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client\Win32\VER25_RELEASE
sa25.exe
```

If another DLL error appears, check which DLL is missing and repeat the process.

## Common Issues

### Issue: "cl is not recognized"
**Solution**: Use "Developer Command Prompt for VS 2022" instead of regular Command Prompt

### Issue: "error LNK2001: unresolved external symbol"
**Solution**: This dummy DLL might need adjustments. Check function signatures match the header.

### Issue: Client crashes after DLL loads
**Solution**: The dummy DLL doesn't provide real protection. This is expected for testing only.

## Production Considerations

For production deployment:
1. Obtain official VMProtect SDK from https://vmpsoft.com/
2. Replace this dummy DLL with the official version
3. Or remove VMProtect integration entirely from source code

## Function Implementations

This dummy DLL provides:
- ✅ VMProtectBegin/End (no-op)
- ✅ VMProtectIsDebuggerPresent (always FALSE)
- ✅ VMProtectIsVirtualMachinePresent (always FALSE)
- ✅ VMProtectDecryptStringA/W (pass-through)
- ✅ VMProtectFreeString (HeapFree)
- ✅ Serial number functions (stub)
- ✅ Activation functions (stub)

All functions return safe default values for testing.
