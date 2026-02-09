// Dummy VMProtectSDK32.dll implementation for testing purposes
// This DLL provides stub implementations that always return "no protection" values
// For production use, you should obtain the official VMProtect SDK

#include <windows.h>

#ifdef __cplusplus
extern "C" {
#endif

// Protection functions - do nothing
__declspec(dllexport) void __stdcall VMProtectBegin(const char *marker) {
    // Stub: do nothing
}

__declspec(dllexport) void __stdcall VMProtectBeginVirtualization(const char *marker) {
    // Stub: do nothing
}

__declspec(dllexport) void __stdcall VMProtectBeginMutation(const char *marker) {
    // Stub: do nothing
}

__declspec(dllexport) void __stdcall VMProtectBeginUltra(const char *marker) {
    // Stub: do nothing
}

__declspec(dllexport) void __stdcall VMProtectBeginVirtualizationLockByKey(const char *marker) {
    // Stub: do nothing
}

__declspec(dllexport) void __stdcall VMProtectBeginUltraLockByKey(const char *marker) {
    // Stub: do nothing
}

__declspec(dllexport) void __stdcall VMProtectEnd(void) {
    // Stub: do nothing
}

// Utils - return FALSE (no debugger, not in VM)
__declspec(dllexport) BOOL __stdcall VMProtectIsDebuggerPresent(BOOL check) {
    return FALSE;  // Always return no debugger
}

__declspec(dllexport) BOOL __stdcall VMProtectIsVirtualMachinePresent(void) {
    return FALSE;  // Always return not in VM
}

__declspec(dllexport) BOOL __stdcall VMProtectIsValidImageCRC(void) {
    return TRUE;  // Always return valid CRC
}

// String decryption - return input string as-is (assumes already decrypted)
__declspec(dllexport) char * __stdcall VMProtectDecryptStringA(const char *value) {
    if (!value) return NULL;

    size_t len = lstrlenA(value) + 1;
    char *result = (char*)HeapAlloc(GetProcessHeap(), 0, len);
    if (result) {
        lstrcpyA(result, value);
    }
    return result;
}

__declspec(dllexport) wchar_t * __stdcall VMProtectDecryptStringW(const wchar_t *value) {
    if (!value) return NULL;

    size_t len = (lstrlenW(value) + 1) * sizeof(wchar_t);
    wchar_t *result = (wchar_t*)HeapAlloc(GetProcessHeap(), 0, len);
    if (result) {
        lstrcpyW(result, value);
    }
    return result;
}

__declspec(dllexport) BOOL __stdcall VMProtectFreeString(void *value) {
    if (value) {
        return HeapFree(GetProcessHeap(), 0, value);
    }
    return TRUE;
}

// Licensing functions - return default values
__declspec(dllexport) INT __stdcall VMProtectSetSerialNumber(const char *serial) {
    return 0;  // Return success
}

__declspec(dllexport) INT __stdcall VMProtectGetSerialNumberState() {
    return 0;  // Return no error state
}

__declspec(dllexport) BOOL __stdcall VMProtectGetSerialNumberData(void *pData, UINT nSize) {
    if (pData && nSize > 0) {
        ZeroMemory(pData, nSize);
    }
    return TRUE;
}

__declspec(dllexport) INT __stdcall VMProtectGetCurrentHWID(char *HWID, UINT nSize) {
    if (HWID && nSize > 0) {
        lstrcpyA(HWID, "DUMMY-HWID-0000");
    }
    return 0;
}

// Activation functions - return success
__declspec(dllexport) INT __stdcall VMProtectActivateLicense(const char *code, char *serial, int size) {
    return 0;  // ACTIVATION_OK
}

__declspec(dllexport) INT __stdcall VMProtectDeactivateLicense(const char *serial) {
    return 0;  // ACTIVATION_OK
}

__declspec(dllexport) INT __stdcall VMProtectGetOfflineActivationString(const char *code, char *buf, int size) {
    return 0;  // ACTIVATION_OK
}

__declspec(dllexport) INT __stdcall VMProtectGetOfflineDeactivationString(const char *serial, char *buf, int size) {
    return 0;  // ACTIVATION_OK
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    switch (ul_reason_for_call) {
        case DLL_PROCESS_ATTACH:
        case DLL_THREAD_ATTACH:
        case DLL_THREAD_DETACH:
        case DLL_PROCESS_DETACH:
            break;
    }
    return TRUE;
}

#ifdef __cplusplus
}
#endif
