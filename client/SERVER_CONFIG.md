# Stone Age Client Server Configuration

## Current Status

The client has server IP addresses **hardcoded** in the source code. To connect to your server, you need to modify the source code and recompile.

## Server Configuration Location

**File**: `client/stoneage-client/wgs/common.cpp`

**Line**: ~214-232 (currently commented out)

## Your Server Information

- **IP Address**: 52.65.189.156
- **Port**: 9065

## Required Changes

### Step 1: Edit common.cpp on Windows PC

Open the file:
```
C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client\wgs\common.cpp
```

### Step 2: Find the server configuration section (around line 200-240)

Look for this code (currently commented out):
```cpp
/*
nGroup = 2;
strcpy( gmgroup[0].name, "测试区");
gmgroup[0].num = 2;
gmgroup[0].startindex = 0;
gmgroup[0].used = 1;
strcpy( gmgroup[1].name, "测试大区");
gmgroup[1].num = 2;
gmgroup[1].startindex = 2;
gmgroup[1].used = 1;

strcpy( gmsv[0].ipaddr, "127.0.0.1");
strcpy( gmsv[0].name, "测试一线");
strcpy( gmsv[0].port, "7001");
gmsv[0].used = '1';

strcpy( gmsv[1].ipaddr, "114.215.158.113");
strcpy( gmsv[1].name, "测试二线");
strcpy( gmsv[1].port, "7001");
gmsv[1].used = '1';

strcpy( gmsv[2].ipaddr, "192.168.0.104");
strcpy( gmsv[2].name, "测试三线");
strcpy( gmsv[2].port, "7001");
gmsv[2].used = '1';

strcpy( gmsv[3].ipaddr, "my.gamma7happy.com");
strcpy( gmsv[3].name, "测试四线");
strcpy( gmsv[3].port, "7001");
gmsv[3].used = '1';
*/
```

### Step 3: Uncomment and modify

**Remove the comment markers** `/*` and `*/`, then change to:

```cpp
nGroup = 1;
strcpy( gmgroup[0].name, "StoneAge Server");
gmgroup[0].num = 1;
gmgroup[0].startindex = 0;
gmgroup[0].used = 1;

strcpy( gmsv[0].ipaddr, "52.65.189.156");
strcpy( gmsv[0].name, "Main Server");
strcpy( gmsv[0].port, "9065");
gmsv[0].used = '1';
```

**Note**: We're setting up only 1 server group with 1 server for simplicity.

### Step 4: Save the file

Make sure to save `common.cpp` after editing.

### Step 5: Rebuild the client

In **Developer Command Prompt for VS 2026**:

```cmd
cd C:\Users\admin\Desktop\sa2\stoneage-new\client\stoneage-client

# Clean previous build
rmdir /s /q Win32\VER25_RELEASE

# Rebuild
msbuild 石器源码.vcxproj /p:Configuration=VER25_RELEASE /p:Platform=Win32
```

Or rebuild in Visual Studio:
1. Open `石器源码.vcxproj` in Visual Studio
2. Select **VER25_RELEASE** configuration
3. Build > Rebuild Solution

### Step 6: Copy DLLs again

```cmd
copy dll\*.dll Win32\VER25_RELEASE\
```

### Step 7: Test connection

```cmd
cd Win32\VER25_RELEASE
sa25.exe
```

## Alternative: Configuration File (If Supported)

Some versions of Stone Age client support external configuration files. Check if any of these exist or can be created:

- `setup.txt`
- `server.ini`
- `config.cfg`
- `GMSV.txt`

If configuration files are supported, you can set the server IP without recompiling.

## Troubleshooting

### Issue: Still connecting to 127.0.0.1

**Solution**: Make sure you:
1. Removed the `/*` and `*/` comment markers
2. Saved the file
3. Rebuilt the project (not just ran the old executable)
4. Copied the new `sa25.exe`

### Issue: Build errors after modification

**Solution**: Check for syntax errors:
- Make sure all strings are properly quoted
- Semicolons at the end of each line
- Matching braces `{` and `}`

### Issue: Can't connect to server

**Solution**:
1. Verify server is running: `ssh root@52.65.189.156` and check GMSV status
2. Check firewall allows port 9065
3. Test connectivity: `telnet 52.65.189.156 9065`

## Network Testing

Before rebuilding, test if the server is accessible:

```cmd
# Windows PowerShell
Test-NetConnection -ComputerName 52.65.189.156 -Port 9065

# Command Prompt
telnet 52.65.189.156 9065
```

If this fails, the server may not be running or port 9065 is blocked.

## Next Steps

1. ✅ Modify `common.cpp` with your server IP and port
2. ✅ Rebuild the client
3. ✅ Copy DLLs to output directory
4. ✅ Run `sa25.exe`
5. 📋 Check if connection attempt appears in server logs
6. 📋 Test login functionality

Even without game graphics, you should be able to see if the client successfully connects to the server by monitoring network traffic or server logs.
