import os
import strformat
import times
import winim/lean

proc crawlDirectory(dir: string, depth: int = 0, maxDepth: int = 2) =
  # Stop recursion if we've reached max depth
  if depth > maxDepth:
    return
  
  # Indent based on depth
  let indent = "  ".repeat(depth)
  
  try:
    for kind, path in walkDir(dir):
      let fileName = extractFilename(path)
      
      # Skip certain system folders
      if ["$Recycle.Bin", "System Volume Information"].contains(fileName):
        continue
      
      # Get file attributes
      var fileAttr: WIN32_FILE_ATTRIBUTE_DATA
      if GetFileAttributesExA(path, GetFileExInfoStandard, addr fileAttr):
        # Convert file time to system time
        var systemTime: SYSTEMTIME
        var localTime: FILETIME
        FileTimeToLocalFileTime(addr fileAttr.ftLastWriteTime, addr localTime)
        FileTimeToSystemTime(addr localTime, addr systemTime)
        
        let modified = fmt"{systemTime.wYear:04}-{systemTime.wMonth:02}-{systemTime.wDay:02} {systemTime.wHour:02}:{systemTime.wMinute:02}"
        
        case kind:
          of pcFile:
            let size = (fileAttr.nFileSizeHigh.int64 shl 32) + fileAttr.nFileSizeLow.int64
            echo fmt"{indent}📄 {fileName} ({size div 1024} KB) - {modified}"
          of pcDir:
            echo fmt"{indent}📁 {fileName} - {modified}"
            # Recursively process subdirectories
            crawlDirectory(path, depth + 1, maxDepth)
          else:
            echo fmt"{indent}🔗 {fileName} - {modified}"
      else:
        case kind:
          of pcFile: echo fmt"{indent}📄 {fileName} (access denied)"
          of pcDir: echo fmt"{indent}📁 {fileName} (access denied)"
          else: echo fmt"{indent}🔗 {fileName} (access denied)"
  except:
    echo fmt"{indent}❌ Error accessing {dir}"

proc scanFileSystem() =
  echo "File System Crawler"
  echo "=================="
  
  # Get logical drives
  var drives = newSeq[char]()
  var driveStrings = newString(256)
  let len = GetLogicalDriveStringsA(255, cast[LPSTR](addr driveStrings[0]))
  
  if len > 0:
    var i = 0
    while i < len:
      if driveStrings[i] != '\0':
        drives.add(driveStrings[i])
        # Skip to next drive letter by finding next null terminator
        while i < len and driveStrings[i] != '\0':
          i.inc
      i.inc
  
  # Get drive information and crawl each drive
  for drive in drives:
    let drivePath = fmt"{drive}:\\"
    
    var volumeName = newString(MAX_PATH)
    var serialNumber: DWORD
    var maxComponentLength: DWORD
    var fileSystemFlags: DWORD
    var fileSystemName = newString(MAX_PATH)
    
    if GetVolumeInformationA(
      drivePath,
      cast[LPSTR](addr volumeName[0]),
      MAX_PATH,
      addr serialNumber,
      addr maxComponentLength,
      addr fileSystemFlags,
      cast[LPSTR](addr fileSystemName[0]),
      MAX_PATH
    ):
      # Null-terminate the strings
      var volLen, fsLen = 0
      while volLen < volumeName.len and volumeName[volLen] != '\0': volLen.inc
      while fsLen < fileSystemName.len and fileSystemName[fsLen] != '\0': fsLen.inc
      
      volumeName.setLen(volLen)
      fileSystemName.setLen(fsLen)
      
      var freeBytes, totalBytes, totalFreeBytes: int64
      if GetDiskFreeSpaceExA(
        drivePath,
        cast[PULARGE_INTEGER](addr freeBytes),
        cast[PULARGE_INTEGER](addr totalBytes),
        cast[PULARGE_INTEGER](addr totalFreeBytes)
      ):
        echo fmt"Drive {drivePath} ({volumeName}) - {fileSystemName}"
        echo fmt"  Total: {totalBytes div (1024*1024*1024)} GB, Free: {freeBytes div (1024*1024*1024)} GB"
        
        # Start crawling this drive
        echo fmt"  Contents (limited to 2 levels deep):"
        crawlDirectory(drivePath)
      else:
        echo fmt"Drive {drivePath} - Unable to get space information"
    else:
      echo fmt"Drive {drivePath} - Unable to get volume information"
    
    echo ""

scanFileSystem() 