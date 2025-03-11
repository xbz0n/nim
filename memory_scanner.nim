import winim/lean
import strformat
import strutils
import winim/com

proc scanProcessMemory(targetProcessName: string, signature: seq[byte]) =
  echo "Memory Scanning Demonstration"
  echo "============================"
  
  # Find process by name
  var entry: PROCESSENTRY32
  entry.dwSize = sizeof(PROCESSENTRY32).DWORD
  
  let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
  defer: CloseHandle(snapshot)
  
  var targetPID: DWORD = 0
  
  if Process32First(snapshot, addr entry):
    while true:
      let processName = $cast[cstring](addr entry.szExeFile[0])
      
      if processName.toLowerAscii() == targetProcessName.toLowerAscii():
        targetPID = entry.th32ProcessID
        echo fmt"Found target process: {processName} (PID: {targetPID})"
        break
      
      if not Process32Next(snapshot, addr entry):
        break
  
  if targetPID == 0:
    echo fmt"Process '{targetProcessName}' not found"
    return
  
  # Open process with read memory access
  let hProcess = OpenProcess(PROCESS_VM_READ or PROCESS_QUERY_INFORMATION, FALSE, targetPID)
  if hProcess == 0:
    echo fmt"Failed to open process, error: {GetLastError()}"
    return
  defer: CloseHandle(hProcess)
  
  # Get process memory info
  var memInfo: MEMORY_BASIC_INFORMATION
  var currentAddress: INT_PTR = 0
  var matches = 0
  
  echo "Scanning process memory for signatures..."
  
  while true:
    let result = VirtualQueryEx(
      hProcess,
      cast[LPCVOID](currentAddress),
      addr memInfo,
      sizeof(MEMORY_BASIC_INFORMATION)
    )
    
    if result == 0:
      break  # End of memory space
    
    # Only scan committed memory that is readable
    if (memInfo.State == MEM_COMMIT) and 
       (memInfo.Protect and (PAGE_READONLY or PAGE_READWRITE or PAGE_EXECUTE_READ or PAGE_EXECUTE_READWRITE) != 0):
      
      # Read the memory region
      let regionSize = memInfo.RegionSize
      var buffer = newSeq[byte](regionSize)
      var bytesRead: SIZE_T
      
      if ReadProcessMemory(
        hProcess,
        memInfo.BaseAddress,
        addr buffer[0],
        regionSize,
        addr bytesRead
      ):
        # Search for signature in the buffer
        if bytesRead > 0:
          # Simple Boyer-Moore search implementation
          for i in 0..(bytesRead - signature.len):
            var found = true
            
            for j in 0..<signature.len:
              if buffer[i+j] != signature[j]:
                found = false
                break
            
            if found:
              echo fmt"Found signature at: 0x{cast[INT_PTR](memInfo.BaseAddress) + i:X}"
              matches.inc
      
    # Move to next memory region
    currentAddress = cast[INT_PTR](memInfo.BaseAddress) + memInfo.RegionSize
  
  echo fmt"Memory scan complete. Found {matches} matches."

# Example usage
let signature = @[byte 0x48, 0x8B, 0xC4, 0x48, 0x89, 0x58, 0x08]  # Common x64 function prologue
scanProcessMemory("notepad.exe", signature) 