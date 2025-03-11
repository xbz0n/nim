import winim/lean
import strformat

proc injectDLL(processName: string, dllPath: string) =
  echo "DLL Injection Demonstration"
  echo "=========================="
  echo fmt"Target process: {processName}"
  echo fmt"DLL to inject: {dllPath}"
  
  # Find the target process by name
  var entry: PROCESSENTRY32
  entry.dwSize = sizeof(PROCESSENTRY32).DWORD
  
  let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
  defer: CloseHandle(snapshot)
  
  var targetPID: DWORD = 0
  
  if Process32First(snapshot, addr entry):
    while true:
      let exeFile = cast[cstring](addr entry.szExeFile[0])
      let currentProcessName = $exeFile
      
      if currentProcessName.toLowerAscii() == processName.toLowerAscii():
        targetPID = entry.th32ProcessID
        echo fmt"Found target process: {currentProcessName} (PID: {targetPID})"
        break
      
      if not Process32Next(snapshot, addr entry):
        break
  
  if targetPID == 0:
    echo fmt"Process '{processName}' not found"
    return
  
  # Open the target process
  let hProcess = OpenProcess(
    PROCESS_CREATE_THREAD or PROCESS_QUERY_INFORMATION or 
    PROCESS_VM_OPERATION or PROCESS_VM_WRITE or PROCESS_VM_READ,
    FALSE,
    targetPID
  )
  
  if hProcess == 0:
    echo fmt"Failed to open process, error: {GetLastError()}"
    return
  defer: CloseHandle(hProcess)
  
  # Allocate memory in the target process for the DLL path
  let pathLen = dllPath.len + 1  # +1 for null terminator
  let remotePath = VirtualAllocEx(
    hProcess,
    nil,
    pathLen,
    MEM_COMMIT or MEM_RESERVE,
    PAGE_READWRITE
  )
  
  if remotePath == nil:
    echo fmt"Failed to allocate memory in target process, error: {GetLastError()}"
    return
  
  # Write the DLL path to the allocated memory
  var bytesWritten: SIZE_T
  if not WriteProcessMemory(
    hProcess,
    remotePath,
    unsafeAddr dllPath[0],
    pathLen,
    addr bytesWritten
  ):
    echo fmt"Failed to write to process memory, error: {GetLastError()}"
    VirtualFreeEx(hProcess, remotePath, 0, MEM_RELEASE)
    return
  
  # Get the address of LoadLibraryA
  let hKernel32 = GetModuleHandleA("kernel32.dll")
  if hKernel32 == 0:
    echo "Failed to get handle to kernel32.dll"
    VirtualFreeEx(hProcess, remotePath, 0, MEM_RELEASE)
    return
  
  let pLoadLibraryA = GetProcAddress(hKernel32, "LoadLibraryA")
  if pLoadLibraryA == nil:
    echo "Failed to get address of LoadLibraryA"
    VirtualFreeEx(hProcess, remotePath, 0, MEM_RELEASE)
    return
  
  # Create a remote thread that calls LoadLibraryA with the DLL path
  let hThread = CreateRemoteThread(
    hProcess,
    nil,
    0,
    cast[LPTHREAD_START_ROUTINE](pLoadLibraryA),
    remotePath,
    0,
    nil
  )
  
  if hThread == 0:
    echo fmt"Failed to create remote thread, error: {GetLastError()}"
    VirtualFreeEx(hProcess, remotePath, 0, MEM_RELEASE)
    return
  
  # Wait for the thread to complete
  echo "Waiting for injection thread to complete..."
  WaitForSingleObject(hThread, 5000)  # Wait up to 5 seconds
  
  # Get the thread exit code (should be the handle to the loaded DLL)
  var exitCode: DWORD
  GetExitCodeThread(hThread, addr exitCode)
  
  if exitCode == 0:
    echo "Failed to load DLL in target process"
  else:
    echo fmt"DLL successfully injected! Handle: 0x{exitCode:X}"
  
  # Clean up
  CloseHandle(hThread)
  VirtualFreeEx(hProcess, remotePath, 0, MEM_RELEASE)
  
  echo "DLL injection demonstration completed"

# Example usage - would need to use a real DLL path for actual execution
const sampleDllPath = "C:\\path\\to\\your\\sample.dll"
echo "Note: This demonstration requires a valid DLL to inject."
echo "Replace the sample path with an actual DLL before using."
echo ""

# For safe demo, show the function but don't execute with invalid path
echo "Function ready for use with: injectDLL(\"notepad.exe\", pathToDll)" 