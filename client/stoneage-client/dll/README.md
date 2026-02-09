# Stone Age Client Required DLL Files

This folder contains the necessary DLL files for running the Stone Age client (sa25.exe).

## Files Included

### OpenSSL Libraries (Version 1.0.2k)
- **libeay32.dll** (1.3 MB) - OpenSSL crypto library
- **ssleay32.dll** (330 KB) - OpenSSL SSL/TLS library

Source: https://github.com/HW71/ManagedOpenSSL.net/releases/tag/v1.0.0

### Lua Library
- **lua51.dll** - Lua 5.1 scripting engine

## Installation Instructions

### Windows PC Setup
Copy all DLL files from this folder to the same directory as sa25.exe:

```
C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client\Win32\VER25_RELEASE\
```

### Command Line (Windows)
```cmd
cd C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client
copy dll\*.dll Win32\VER25_RELEASE\
```

### PowerShell
```powershell
Copy-Item -Path "dll\*.dll" -Destination "Win32\VER25_RELEASE\" -Force
```

## Troubleshooting

If you encounter "missing DLL" errors:

1. Verify all 3 DLL files are in the same folder as sa25.exe
2. Install Visual C++ Redistributable 2015-2022 (x86) if needed
3. Run sa25.exe as Administrator
4. Check Windows Defender/Antivirus isn't blocking the DLLs

## Version Information

- OpenSSL: 1.0.2k (32-bit, compiled April 21, 2017)
- Lua: 5.1 (32-bit)
- Target Platform: Windows x86 (32-bit)

## License

OpenSSL is licensed under the Apache License 2.0 / OpenSSL License
Lua is licensed under the MIT License
