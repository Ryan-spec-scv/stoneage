# Stone Age Client Data Files

## Current Status

### ✅ Available Files
- **Source Code**: Complete client source code in `stoneage-client/` folder
- **Compiled Executable**: `sa25.exe` (Windows x86)
- **Required DLLs**: OpenSSL, Lua, VMProtect (all provided in `dll/` folder)
- **Lua Scripts**: UI and map scripts in `lua/` folder

### ❌ Missing Files
- **Game Graphics**: Character sprites, item icons, map tiles, UI textures
- **Sound Files**: Background music, sound effects
- **Map Data**: Game world maps and zones
- **Configuration Files**: Game settings, server connection config
- **Other Resources**: Fonts, cursors, animations

## Why Data Files Are Missing

Stone Age client data files are **very large** (typically 500MB - 2GB) and contain:
- Thousands of sprite images
- Map data for entire game world
- Sound and music files
- Other game resources

These files are **NOT included in the source code** and must be obtained separately.

## How to Obtain Client Data

### Option 1: Download Complete Client Package

Search for "石器时代8.5客户端" (Stone Age 8.5 Client) online. You need the full game client installer, not just the source code.

**Warning**: Make sure to download from trusted sources only.

### Option 2: Extract from Existing Installation

If you have Stone Age 8.5 installed elsewhere:
1. Locate the installation folder
2. Copy the `data/` folder
3. Copy all resource files (.pak, .dat, .bin, etc.)
4. Place them in the same directory as `sa25.exe`

### Option 3: Contact Original Developers

Reach out to the Stone Age 8.5 community or original developers for legitimate data files.

## Installation Instructions

Once you have the client data files:

1. **On Windows PC**, copy all data files to:
   ```
   C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client\Win32\VER25_RELEASE\
   ```

2. **Expected folder structure**:
   ```
   Win32\VER25_RELEASE\
   ├── sa25.exe
   ├── libeay32.dll
   ├── ssleay32.dll
   ├── lua51.dll
   ├── VMProtectSDK32.dll
   ├── data\
   │   ├── chardata\      (character sprites)
   │   ├── mapdata\       (map files)
   │   ├── sounddata\     (audio files)
   │   └── ... (other resources)
   ├── lua\
   │   ├── list.lua
   │   ├── title.lua
   │   ├── map\
   │   └── win\
   └── ... (configuration files)
   ```

3. **Run the client**:
   ```cmd
   cd C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client\Win32\VER25_RELEASE
   sa25.exe
   ```

## Current Error

The current error message (showing corrupted Chinese characters) indicates:
- The executable is running
- DLL files are loaded successfully
- But game data files are missing or incomplete

Once you add the complete game data files, the client should start properly.

## Server Connection

After the client loads successfully, you'll need to configure it to connect to your server:
- **Server IP**: 52.65.189.156
- **Server Port**: 9065

Configuration method depends on the client version (config file, registry, or built-in settings).

## Next Steps

1. Obtain complete Stone Age 8.5 client data files
2. Copy them to the Windows PC
3. Place in the correct directory structure
4. Run `sa25.exe` again
5. Configure server connection settings
6. Test login and gameplay

## Need Help?

If you're unable to find the client data files, consider:
- Searching Stone Age community forums
- Checking GitHub for complete client packages
- Contacting other Stone Age private server operators
- Looking for archived versions on game preservation sites
