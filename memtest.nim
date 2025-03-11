import winim/lean
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
  
  # List running processes (basic example)
  var entry: PROCESSENTRY32W
  entry.dwSize = sizeof(PROCESSENTRY32W).DWORD
  
  let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
  defer: CloseHandle(snapshot)
  
  if Process32FirstW(snapshot, entry.addr):
    echo "Running processes:"
    while true:
      var processName = $entry.szExeFile
      
      echo fmt"  {entry.th32ProcessID}: {processName}"
      
      if not Process32NextW(snapshot, entry.addr):
        break

memoryOnlyTest() 