import winim/lean
import winim/utils  # This might provide additional structure definitions
import strformat

proc memoryOnlyTest() =
  # Basic system reconnaissance that stays in memory
  var computerName = newString(MAX_COMPUTERNAME_LENGTH + 1)
  var size = DWORD(computerName.len)
  
  if GetComputerNameA(addr computerName[0], addr size):
    computerName.setLen(size)
    echo fmt"Memory-based testing on: {computerName}"
  else:
    echo "Failed to get computer name"
  
  # Get current process information
  var process = GetCurrentProcessId()
  echo fmt"Process ID: {process}"
  
  # List running processes using the ansi version explicitly
  var entry: PROCESSENTRY32
  entry.dwSize = sizeof(PROCESSENTRY32).DWORD
  
  let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
  defer: CloseHandle(snapshot)
  
  if Process32First(snapshot, addr entry):
    echo "Running processes:"
    while true:
      # Safely convert the name using the cstring cast technique
      let exeFile = cast[cstring](addr entry.szExeFile[0])
      let processName = $exeFile
      
      echo fmt"  {entry.th32ProcessID}: {processName}"
      
      if not Process32Next(snapshot, addr entry):
        break

memoryOnlyTest() 