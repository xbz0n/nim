import winim/lean

proc demonstrateDirectAPICalls() =
  # Demonstrate direct Windows API calls for system information gathering
  var memoryStatus: MEMORYSTATUSEX
  memoryStatus.dwLength = sizeof(MEMORYSTATUSEX).DWORD
  
  if GlobalMemoryStatusEx(memoryStatus.addr):
    echo "Memory information:"
    echo "  Total physical memory: ", memoryStatus.ullTotalPhys div (1024*1024), " MB"
    echo "  Available memory: ", memoryStatus.ullAvailPhys div (1024*1024), " MB"
    echo "  Memory load: ", memoryStatus.dwMemoryLoad, "%"
  
  # Demonstrate process information gathering
  var sysInfo: SYSTEM_INFO
  GetSystemInfo(sysInfo.addr)
  
  echo "System information:"
  echo "  Processor architecture: ", sysInfo.wProcessorArchitecture
  echo "  Number of processors: ", sysInfo.dwNumberOfProcessors
  echo "  Page size: ", sysInfo.dwPageSize, " bytes"

demonstrateDirectAPICalls() 