import winim/lean
import strformat

proc scanFilesystem() =
  echo "Simple Filesystem Scanner"
  echo "======================="
  
  # Get drives
  var driveBits = GetLogicalDrives()
  if driveBits == 0:
    echo fmt"Failed to get logical drives, error: {GetLastError()}"
    return
  
  echo "Available drives:"
  
  for i in 0..25:  # A-Z
    if (driveBits and (1 shl i)) != 0:
      let driveLetter = char(ord('A') + i)
      let rootPath = fmt"{driveLetter}:\\"
      
      var volumeName = newString(MAX_PATH)
      var fileSystemName = newString(MAX_PATH)
      var serialNumber: DWORD
      var maxComponentLength: DWORD
      var flags: DWORD
      
      if GetVolumeInformationA(
        rootPath, 
        addr volumeName[0], MAX_PATH,
        addr serialNumber,
        addr maxComponentLength,
        addr flags,
        addr fileSystemName[0], MAX_PATH
      ):
        # Find null terminators for C strings
        var volLen, fsLen = 0
        while volLen < volumeName.len and volumeName[volLen] != '\0': volLen.inc
        while fsLen < fileSystemName.len and fileSystemName[fsLen] != '\0': fsLen.inc
        
        volumeName.setLen(volLen)
        fileSystemName.setLen(fsLen)
        
        # Get free space
        var freeBytesAvailable, totalBytes, totalFreeBytes: ULARGE_INTEGER
        if GetDiskFreeSpaceExA(
          rootPath,
          addr freeBytesAvailable,
          addr totalBytes,
          addr totalFreeBytes
        ):
          echo fmt"Drive {rootPath} ({volumeName})"
          echo fmt"  Type: {fileSystemName}"
          echo fmt"  Total space: {totalBytes.QuadPart div (1024*1024*1024)} GB"
          echo fmt"  Free space: {freeBytesAvailable.QuadPart div (1024*1024*1024)} GB"
          
          # List first few files in root directory
          echo fmt"  Files in root directory:"
          
          var findData: WIN32_FIND_DATAA
          let searchPath = fmt"{rootPath}*"
          
          let hFind = FindFirstFileA(searchPath, addr findData)
          if hFind != INVALID_HANDLE_VALUE:
            defer: FindClose(hFind)
            
            var count = 0
            while count < 10:  # Limit to 10 entries
              # Skip . and .. entries
              if $cast[cstring](addr findData.cFileName[0]) notin [".", ".."]:
                let isDir = (findData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0
                let itemType = if isDir: "📁" else: "📄"
                echo fmt"    {itemType} {cast[cstring](addr findData.cFileName[0])}"
                count.inc
              
              if FindNextFileA(hFind, addr findData) == 0:
                break
        else:
          echo fmt"Drive {rootPath} - Failed to get disk space info"
      else:
        echo fmt"Drive {rootPath} - Failed to get volume info"

# Run the scanner
scanFilesystem() 