#!/usr/bin/env python
"""
Script to generate Nim files for security testing
"""

def write_file(filename, content):
    with open(filename, 'w') as f:
        f.write(content)
    print(f"Created {filename}")

# memtest.nim - Fixed version
memtest_content = '''import winim/lean
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
  var entry: PROCESSENTRY32
  entry.dwSize = sizeof(PROCESSENTRY32).DWORD
  
  let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
  defer: CloseHandle(snapshot)
  
  if Process32First(snapshot, entry.addr):
    echo "Running processes:"
    var count = 0
    while true:
      # Safer way to handle process names:
      var processName = ""
      let exeFile = cast[cstring](addr entry.szExeFile[0])
      processName = $exeFile
      
      echo fmt"  {entry.th32ProcessID}: {processName}"
      
      # Break safely to avoid infinite loops
      if not Process32Next(snapshot, entry.addr):
        break

memoryOnlyTest()'''

# memory_only_loader.nim - Fixed version
memory_loader_content = '''import winim/lean
import dynlib
import strutils  # For the toHex function

proc memoryOnlyLoader() =
  # Allocate memory for our "virtual module"
  let size = 4096  # Adjust based on your actual code size
  let mem = VirtualAlloc(
    nil, 
    size, 
    MEM_COMMIT or MEM_RESERVE,
    PAGE_EXECUTE_READWRITE
  )
  
  if mem == nil:
    echo "Memory allocation failed"
    return
    
  # In a real test, you would load your code here
  # This is where shellcode or a PE file would typically be loaded
  
  # Convert pointer to string representation
  let memAddress = cast[int](mem)
  var hexAddress = "0x"
  hexAddress.add(toHex(memAddress))
  echo "Memory allocated at: ", hexAddress
  
  # Execute the code from memory
  # In a real test, you would cast this to a function pointer and call it
  # let func = cast[proc() {.stdcall.}](mem)
  # func()
  
  # Free the memory when done
  VirtualFree(mem, 0, MEM_RELEASE)
  echo "Memory released"

memoryOnlyLoader()'''

# api_caller.nim
api_caller_content = '''import winim/lean

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

demonstrateDirectAPICalls()'''

# process_hollowing_concept.nim
process_hollowing_content = '''import winim/lean

proc demonstrateProcessHollowing() =
  # Create a suspended process
  var si: STARTUPINFO
  var pi: PROCESS_INFORMATION
  
  si.cb = sizeof(STARTUPINFO).DWORD
  
  # Start a legitimate process in suspended state
  if CreateProcessA(
    nil, 
    "notepad.exe", 
    nil,
    nil,
    false,
    CREATE_SUSPENDED,
    nil,
    nil,
    si.addr,
    pi.addr
  ):
    echo "Created suspended process: ", pi.dwProcessId
    
    # In a real test, you would:
    # 1. Get process base address
    # 2. Unmap the original image
    # 3. Allocate memory and write your code
    # 4. Set the entry point and resume the thread
    
    # For this demo, we just terminate the process
    TerminateProcess(pi.hProcess, 0)
    echo "Process terminated (this is just a demo)"
    
    CloseHandle(pi.hProcess)
    CloseHandle(pi.hThread)
  else:
    echo "Failed to create process, error: ", GetLastError()

demonstrateProcessHollowing()'''

# Script to create a batch file for compiling
batch_file_content = '''@echo off
echo Compiling Nim files...

:: Install winim if needed
nimble install -y winim

:: Compile all files with optimizations
nim c -d:danger --opt:size --passL:-s memtest.nim
nim c -d:danger --opt:size --passL:-s memory_only_loader.nim
nim c -d:danger --opt:size --passL:-s api_caller.nim
nim c -d:danger --opt:size --passL:-s process_hollowing_concept.nim

echo.
echo Compilation completed! You can now run:
echo - memtest.exe
echo - memory_only_loader.exe
echo - api_caller.exe
echo - process_hollowing_concept.exe
echo.
pause
'''

# Another more advanced example - shellcode_loader.nim
shellcode_loader_content = '''import winim/lean
import strutils

proc injectShellcode() =
  echo "Basic shellcode injection demonstration"
  
  # This is just a simple MessageBox shellcode for demonstration
  # In a real red team exercise, this would be your payload
  let shellcode: array[193, byte] = [
    # x64 MessageBox shellcode example
    byte 0x48, 0x83, 0xEC, 0x28, 0x48, 0x83, 0xE4, 0xF0, 0x48, 0x8D, 0x15, 0x66, 0x00, 0x00, 0x00,
    0x48, 0x8D, 0x0D, 0x52, 0x00, 0x00, 0x00, 0xE8, 0x9E, 0x00, 0x00, 0x00, 0x48, 0x8D, 0x15, 0x5F,
    0x00, 0x00, 0x00, 0x48, 0x8D, 0x0D, 0x4D, 0x00, 0x00, 0x00, 0xE8, 0x87, 0x00, 0x00, 0x00, 0x48,
    0x8D, 0x15, 0x20, 0x00, 0x00, 0x00, 0x48, 0x8D, 0x0D, 0x48, 0x00, 0x00, 0x00, 0xE8, 0x70, 0x00,
    0x00, 0x00, 0x48, 0x83, 0xC4, 0x28, 0xC3, 0x48, 0x8D, 0x0D, 0x00, 0x00, 0x00, 0x00, 0x48, 0x8D,
    0x05, 0xFE, 0xFF, 0xFF, 0xFF, 0x48, 0x83, 0xEC, 0x08, 0x48, 0x89, 0xE5, 0x48, 0x83, 0xC4, 0x08,
    0xC3, 0x90, 0x90, 0x4D, 0x65, 0x73, 0x73, 0x61, 0x67, 0x65, 0x42, 0x6F, 0x78, 0x41, 0x00, 0x75,
    0x73, 0x65, 0x72, 0x33, 0x32, 0x2E, 0x64, 0x6C, 0x6C, 0x00, 0x54, 0x65, 0x73, 0x74, 0x20, 0x4D,
    0x65, 0x73, 0x73, 0x61, 0x67, 0x65, 0x00, 0x53, 0x65, 0x63, 0x75, 0x72, 0x69, 0x74, 0x79, 0x20,
    0x54, 0x65, 0x73, 0x74, 0x69, 0x6E, 0x67, 0x00, 0x00, 0x00, 0x00, 0x00, 0x48, 0x8B, 0xC4, 0x48,
    0x89, 0x58, 0x08, 0x48, 0x89, 0x68, 0x10, 0x48, 0x89, 0x70, 0x18, 0x48, 0x89, 0x78, 0x20, 0x41,
    0x56, 0x48, 0x83, 0xEC, 0x10, 0x65, 0x48, 0x8B, 0x04, 0x25, 0x60, 0x00, 0x00, 0x00, 0x8B, 0xF1
  ]
  
  # Allocate memory with RWX permissions
  let size = shellcode.len
  let mem = VirtualAlloc(
    nil,
    size,
    MEM_COMMIT or MEM_RESERVE,
    PAGE_EXECUTE_READWRITE
  )
  
  if mem == nil:
    echo "Memory allocation failed"
    return
    
  # Copy the shellcode to the allocated memory
  copyMem(mem, unsafeAddr shellcode[0], size)
  
  # Display memory address (safer conversion)
  let memAddress = cast[int](mem)
  var hexAddress = "0x"
  hexAddress.add(toHex(memAddress))
  echo "Shellcode loaded at: ", hexAddress
  
  # Create a function pointer and execute it
  echo "NOTE: This would execute the shellcode in a real scenario"
  echo "For this demo, we're not actually executing it"
  
  # Uncomment to actually execute (if doing authorized testing)
  # let func = cast[proc() {.stdcall.}](mem)
  # func()
  
  # Free memory
  VirtualFree(mem, 0, MEM_RELEASE)
  echo "Memory released"

injectShellcode()'''

# Write all files
write_file('memtest.nim', memtest_content)
write_file('memory_only_loader.nim', memory_loader_content)
write_file('api_caller.nim', api_caller_content)
write_file('process_hollowing_concept.nim', process_hollowing_content)
write_file('shellcode_loader.nim', shellcode_loader_content)
write_file('compile_all.bat', batch_file_content)

print("\nAll files created successfully!")
print("To compile all files, run: compile_all.bat")
print("Remember to install Nim dependencies with: nimble install winim") 