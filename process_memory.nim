import winim/lean
import strformat
import strutils

proc accessProcessMemory() =
  echo "Process Memory Access Demonstration"
  echo "=================================="
  
  # Find a process by name (e.g. notepad)
  let targetProcessName = "notepad.exe"
  echo fmt"Looking for process: {targetProcessName}"
  
  var entry: PROCESSENTRY32
  entry.dwSize = sizeof(PROCESSENTRY32).DWORD
  
  let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
  defer: CloseHandle(snapshot)
  
  var targetPID: DWORD = 0
  
  if Process32First(snapshot, addr entry):
    while true:
      let exeFile = cast[cstring](addr entry.szExeFile[0])
      let processName = $exeFile
      
      if processName.toLowerAscii() == targetProcessName.toLowerAscii():
        targetPID = entry.th32ProcessID
        echo fmt"Found target process: {processName} (PID: {targetPID})"
        break
      
      if not Process32Next(snapshot, addr entry):
        break
  
  if targetPID == 0:
    echo fmt"Process '{targetProcessName}' not found"
    return
  
  # Open the process
  let hProcess = OpenProcess(PROCESS_VM_READ or PROCESS_QUERY_INFORMATION, FALSE, targetPID)
  if hProcess == 0:
    echo fmt"Failed to open process, error: {GetLastError()}"
    return
  defer: CloseHandle(hProcess)
  
  # Get process information
  var pmc: PROCESS_MEMORY_COUNTERS
  pmc.cb = sizeof(PROCESS_MEMORY_COUNTERS).DWORD
  
  if GetProcessMemoryInfo(hProcess, addr pmc, sizeof(PROCESS_MEMORY_COUNTERS).DWORD):
    echo "Process Memory Information:"
    echo fmt"  Working Set Size: {pmc.WorkingSetSize div 1024} KB"
    echo fmt"  Page File Usage: {pmc.PagefileUsage div 1024} KB"
    echo fmt"  Peak Working Set: {pmc.PeakWorkingSetSize div 1024} KB"
  
  # Enumerate process modules
  let modSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE or TH32CS_SNAPMODULE32, targetPID)
  defer: CloseHandle(modSnapshot)
  
  var modEntry: MODULEENTRY32
  modEntry.dwSize = sizeof(MODULEENTRY32).DWORD
  
  echo "\nProcess Modules:"
  if Module32First(modSnapshot, addr modEntry):
    while true:
      let modName = $cast[cstring](addr modEntry.szModule[0])
      let modPath = $cast[cstring](addr modEntry.szExePath[0])
      
      echo fmt"  Module: {modName}"
      echo fmt"    Base: 0x{cast[int](modEntry.modBaseAddr):X}"
      echo fmt"    Size: {modEntry.modBaseSize div 1024} KB"
      echo fmt"    Path: {modPath}"
      
      if not Module32Next(modSnapshot, addr modEntry):
        break

accessProcessMemory() 