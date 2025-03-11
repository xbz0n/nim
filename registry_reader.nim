import winim/lean
import strformat

proc enumerateRegistry() =
  echo "Registry Inspection Example"
  echo "============================"
  
  var hKey: HKEY
  var dwIndex: DWORD = 0
  var dwKeySize: DWORD = 255
  var lpKeyName = newString(dwKeySize)
  
  # Open the Run key in HKCU
  if RegOpenKeyExA(HKEY_CURRENT_USER, "Software\\Microsoft\\Windows\\CurrentVersion\\Run", 0, KEY_READ, addr hKey) == ERROR_SUCCESS:
    echo "Enumerating autostart programs in HKCU\\Run:"
    
    # Enumerate all values in this key
    while RegEnumValueA(hKey, dwIndex, cast[LPSTR](addr lpKeyName[0]), addr dwKeySize, nil, nil, nil, nil) == ERROR_SUCCESS:
      var lpType: DWORD
      var lpData = newString(1024)
      var lpcbData: DWORD = 1024
      
      # Get the value data
      if RegQueryValueExA(hKey, cast[LPSTR](addr lpKeyName[0]), nil, addr lpType, cast[LPBYTE](addr lpData[0]), addr lpcbData) == ERROR_SUCCESS:
        lpKeyName.setLen(dwKeySize)
        lpData.setLen(lpcbData)
        
        # Remove null terminator if present
        if lpcbData > 0 and lpData[lpcbData-1] == '\0':
          lpData.setLen(lpcbData-1)
        
        echo fmt"  {lpKeyName} -> {lpData}"
      
      # Reset for next iteration
      dwIndex.inc
      dwKeySize = 255
      lpKeyName = newString(dwKeySize)
    
    RegCloseKey(hKey)
  else:
    echo "Failed to open registry key"

enumerateRegistry() 