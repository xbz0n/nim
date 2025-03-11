import winim/lean

proc demonstrateProcessHollowing() =
  # Create a suspended process
  var si: STARTUPINFOA
  var pi: PROCESS_INFORMATION
  
  si.cb = sizeof(STARTUPINFOA).DWORD
  
  # Fix the CreateProcessA call
  let notepad = "notepad.exe"  # Create a variable for the process name
  if CreateProcessA(
    nil, 
    cast[LPSTR](notepad.cstring),  # Correct string conversion
    nil,
    nil,
    FALSE,  # Use FALSE constant instead of lowercase false
    CREATE_SUSPENDED,
    nil,
    nil,
    addr si,  # Use addr instead of .addr
    addr pi   # Use addr instead of .addr
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

demonstrateProcessHollowing() 