import winim/lean
import strformat
import strutils

proc inspectProcesses() =
  echo "Process and Memory Inspection"
  echo "============================"
  
  # List running processes with basic info
  echo "Listing processes..."
  var processCount = 0
  var pids: array[1024, DWORD]
  var needed: DWORD
  
  if EnumProcesses(addr pids[0], sizeof(pids), addr needed):
    processCount = needed div sizeof(DWORD)
    echo fmt"Found {processCount} running processes"
    
    for i in 0..<processCount:
      let pid = pids[i]
      if pid == 0: continue
      
      # Open the process
      let hProcess = OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, pid)
      if hProcess != 0:
        # Get the process name
        var baseName = newString(MAX_PATH)
        if GetModuleBaseNameA(hProcess, 0, addr baseName[0], MAX_PATH) > 0:
          # Trim the string at the first null character
          var nameLen = 0
          while nameLen < baseName.len and baseName[nameLen] != '\0': 
            nameLen.inc
          baseName.setLen(nameLen)
          
          # Basic process info
          echo fmt"PID: {pid}, Name: {baseName}"
        
        CloseHandle(hProcess)
  else:
    echo fmt"Failed to enumerate processes, error: {GetLastError()}"

# Run the demonstration
inspectProcesses() 