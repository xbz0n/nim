import winim/lean
import strformat

type
  HookData = object
    originalFunction: pointer
    hookFunction: pointer
    originalBytes: array[5, byte]
    functionName: string

var hookInfo: HookData

proc installHook(
  targetModule: string, 
  functionName: string,
  hookFunction: pointer
): bool =
  echo fmt"Installing hook on {functionName} in {targetModule}"
  
  # Get handle to the module containing the function to hook
  let moduleHandle = GetModuleHandleA(targetModule)
  if moduleHandle == 0:
    echo fmt"Could not find module: {targetModule}"
    return false
  
  # Get address of the target function
  let targetFunction = GetProcAddress(moduleHandle, functionName)
  if targetFunction == nil:
    echo fmt"Could not find function: {functionName}"
    return false
  
  echo fmt"Found {functionName} at address: 0x{cast[int](targetFunction):X}"
  
  # Save the original function address and name for later use
  hookInfo.originalFunction = targetFunction
  hookInfo.functionName = functionName
  
  # Save the first 5 bytes of the original function
  copyMem(addr hookInfo.originalBytes[0], targetFunction, 5)
  
  # Change memory protection to allow writing
  var oldProtect: DWORD
  if not VirtualProtect(targetFunction, 5, PAGE_EXECUTE_READWRITE, addr oldProtect):
    echo fmt"Failed to change memory protection, error: {GetLastError()}"
    return false
  
  # Create the jump instruction to our hook function
  # Format: E9 xx xx xx xx (jmp near relative)
  var jumpInstr: array[5, byte]
  jumpInstr[0] = 0xE9  # JMP instruction
  
  # Calculate the relative offset to jump to
  let relativeOffset = cast[int](hookFunction) - cast[int](targetFunction) - 5
  
  # Convert the offset to little-endian bytes
  copyMem(addr jumpInstr[1], addr relativeOffset, 4)
  
  # Write the jump instruction to the target function
  copyMem(targetFunction, addr jumpInstr[0], 5)
  
  # Restore the original memory protection
  var tempProtect: DWORD
  VirtualProtect(targetFunction, 5, oldProtect, addr tempProtect)
  
  echo fmt"Hook installed on {functionName}"
  return true

proc removeHook(): bool =
  if hookInfo.originalFunction == nil:
    echo "No hook is currently installed"
    return false
  
  echo fmt"Removing hook from {hookInfo.functionName}"
  
  # Change memory protection to allow writing
  var oldProtect: DWORD
  if not VirtualProtect(hookInfo.originalFunction, 5, PAGE_EXECUTE_READWRITE, addr oldProtect):
    echo fmt"Failed to change memory protection, error: {GetLastError()}"
    return false
  
  # Restore the original bytes
  copyMem(hookInfo.originalFunction, addr hookInfo.originalBytes[0], 5)
  
  # Restore the original memory protection
  var tempProtect: DWORD
  VirtualProtect(hookInfo.originalFunction, 5, oldProtect, addr tempProtect)
  
  echo fmt"Hook removed from {hookInfo.functionName}"
  return true

# Sample hook function for MessageBoxA
proc hookMessageBoxA(
  hWnd: HWND,
  lpText: LPCSTR,
  lpCaption: LPCSTR,
  uType: UINT
): INT {.stdcall.} =
  echo "MessageBoxA hooked!"
  echo fmt"Original text: {$lpText}"
  echo fmt"Original caption: {$lpCaption}"
  
  # Call the original function with modified parameters
  let modifiedText = "This text was modified by the hook!"
  let modifiedCaption = "Hooked MessageBox"
  
  # We need to call the original function, but we can't call it directly
  # because we've overwritten its first 5 bytes. Instead, we'll use a trampoline.
  
  # In a real implementation, we would need to create a proper trampoline.
  # For this demo, we'll just show the concept.
  echo "Would call original MessageBoxA with modified parameters"
  
  # For demonstration, show a message box using a different API
  var msg = "Hook demonstration - original call would have used:\n" &
            fmt"Text: {$lpText}\n" &
            fmt"Caption: {$lpCaption}\n\n" &
            "Modified to:\n" &
            fmt"Text: {modifiedText}\n" &
            fmt"Caption: {modifiedCaption}"
  
  # Use a different function to avoid recursion
  MessageBoxW(
    hWnd,
    cast[LPCWSTR](addr msg[0]),
    "API Hook Demo", 
    MB_OK or MB_ICONINFORMATION
  )
  
  return 1

proc demonstrateApiHook() =
  echo "API Hooking Demonstration"
  echo "========================"
  
  # Install a hook on MessageBoxA
  let success = installHook("user32.dll", "MessageBoxA", hookMessageBoxA)
  
  if success:
    echo "Hook installed successfully"
    
    # Try to call the hooked function
    echo "Calling MessageBoxA, which should trigger our hook..."
    MessageBoxA(0, "Original message", "Original caption", MB_OK)
    
    # Remove the hook when done
    discard removeHook()
  else:
    echo "Failed to install hook"

# Run the demonstration
demonstrateApiHook() 