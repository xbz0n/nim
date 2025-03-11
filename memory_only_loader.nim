import winim/lean
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

memoryOnlyLoader() 