import winim/lean
import strformat

proc scanProcessByName(processName: string) =
  echo "Simple Process Memory Scanner"
  echo "==========================="
  echo fmt"Looking for process: {processName}"
  
  # Use EnumProcesses instead of CreateToolhelp32Snapshot
  var pids: array[1024, DWORD]
  var bytesReturned: DWORD
  
  if EnumProcesses(addr pids[0], sizeof(pids), addr bytesReturned):
    let count = bytesReturned div sizeof(DWORD)
    echo fmt"Found {count} processes total"
    
    var found = false
    
    for i in 0..<count:
      if pids[i] == 0: continue
      
      # Open process to get name
      let hProcess = OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, pids[i])
      if hProcess != 0:
        var name = newString(MAX_PATH)
        let nameLen = GetModuleBaseNameA(hProcess, 0, addr name[0], MAX_PATH)
        
        if nameLen > 0:
          name.setLen(nameLen)
          
          if name.toLowerAscii() == processName.toLowerAscii():
            found = true
            echo fmt"Found target process: {name} (PID: {pids[i]})"
            
            # Enumerate memory regions
            var memInfo: MEMORY_BASIC_INFORMATION
            var address: PVOID = nil
            var regionCount = 0
            
            while VirtualQueryEx(hProcess, address, addr memInfo, sizeof(memInfo)) != 0:
              # Only check committed, readable memory
              if (memInfo.State == MEM_COMMIT) and 
                 (memInfo.Protect and (PAGE_READONLY or PAGE_READWRITE or PAGE_EXECUTE_READ or PAGE_EXECUTE_READWRITE) != 0):
                regionCount.inc
                
                # Print region info
                echo fmt"  Region {regionCount}: 0x{cast[int](memInfo.BaseAddress):X} - Size: {memInfo.RegionSize div 1024} KB"
                echo fmt"    Protection: 0x{memInfo.Protect:X}"
                
                # Read a small sample from the region (just first 16 bytes)
                var buffer: array[16, byte]
                var bytesRead: SIZE_T
                
                if ReadProcessMemory(hProcess, memInfo.BaseAddress, addr buffer[0], buffer.len, addr bytesRead):
                  echo "    Sample data: "
                  var hexDump = ""
                  for b in 0..<min(bytesRead, 16):
                    hexDump &= fmt"{buffer[b]:02X} "
                  echo fmt"    {hexDump}"
              
              # Move to next region
              address = cast[PVOID](cast[int](memInfo.BaseAddress) + cast[int](memInfo.RegionSize))
            
            echo fmt"Found {regionCount} memory regions in total"
            break
        
        CloseHandle(hProcess)
    
    if not found:
      echo fmt"Process '{processName}' not found"
  else:
    echo fmt"Failed to enumerate processes, error: {GetLastError()}"

# Run with a common process name
scanProcessByName("notepad.exe") 