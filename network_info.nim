import winim/lean
import strformat
import net

proc getNetworkInfo() =
  echo "Network Information Gathering"
  echo "============================"
  
  # Get hostname
  var hostname = getHostname()
  echo fmt"Hostname: {hostname}"
  
  # Get IP addresses
  echo "IP Addresses:"
  for ip in getLocalIPs():
    echo fmt"  {ip}"
  
  # Enumerate network adapters
  var pAdapterInfo: PIP_ADAPTER_INFO
  var dwBufLen: DWORD = 0
  
  # First call to get the buffer size
  if GetAdaptersInfo(nil, addr dwBufLen) == ERROR_BUFFER_OVERFLOW:
    # Allocate the required buffer
    pAdapterInfo = cast[PIP_ADAPTER_INFO](alloc(dwBufLen))
    
    if GetAdaptersInfo(pAdapterInfo, addr dwBufLen) == NO_ERROR:
      var adapter = pAdapterInfo
      while adapter != nil:
        echo fmt"Adapter: {cast[cstring](addr adapter.Description[0])}"
        echo fmt"  MAC: {adapter.Address[0]:02x}:{adapter.Address[1]:02x}:{adapter.Address[2]:02x}:{adapter.Address[3]:02x}:{adapter.Address[4]:02x}:{adapter.Address[5]:02x}"
        echo fmt"  IP: {cast[cstring](addr adapter.IpAddressList.IpAddress.String[0])}"
        echo fmt"  Gateway: {cast[cstring](addr adapter.GatewayList.IpAddress.String[0])}"
        echo fmt"  DHCP: {cast[cstring](addr adapter.DhcpServer.IpAddress.String[0])}"
        
        # Move to next adapter
        adapter = adapter.Next
    
    # Free the allocated memory
    dealloc(pAdapterInfo)
  
  # Get ARP table
  echo "\nARP Table:"
  var pIpNetTable: PMIB_IPNETTABLE
  var dwSize: DWORD = 0
  
  # First call to get size
  if GetIpNetTable(nil, addr dwSize, 0) == ERROR_INSUFFICIENT_BUFFER:
    # Allocate memory
    pIpNetTable = cast[PMIB_IPNETTABLE](alloc(dwSize))
    
    if GetIpNetTable(pIpNetTable, addr dwSize, 0) == NO_ERROR:
      for i in 0..<pIpNetTable.dwNumEntries:
        let entry = pIpNetTable.table[i]
        let ipAddr = inet_ntoa(cast[IN_ADDR](addr entry.dwAddr)[])
        echo fmt"  {ipAddr} -> {entry.bPhysAddr[0]:02x}:{entry.bPhysAddr[1]:02x}:{entry.bPhysAddr[2]:02x}:{entry.bPhysAddr[3]:02x}:{entry.bPhysAddr[4]:02x}:{entry.bPhysAddr[5]:02x}"
    
    # Free allocated memory
    dealloc(pIpNetTable)

getNetworkInfo() 