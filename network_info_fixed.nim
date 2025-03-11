import winim/lean
import strformat

proc getNetworkInfoFixed() =
  echo "Network Information Gathering (Fixed Version)"
  echo "==========================================="
  
  # Get hostname manually without relying on the standard library
  var hostname: array[256, char]
  var size: DWORD = 256
  
  if GetComputerNameA(addr hostname[0], addr size):
    echo fmt"Hostname: {cast[cstring](addr hostname[0])}"
  else:
    echo fmt"Failed to get hostname, error: {GetLastError()}"
  
  # Get IP addresses using Windows API
  var wsaData: WSADATA
  if WSAStartup(MAKEWORD(2, 2), addr wsaData) == 0:
    defer: WSACleanup()
    
    var hostEntry = gethostbyname(nil)  # Gets localhost entry
    if hostEntry != nil:
      echo "IP Addresses:"
      var addr_list = cast[ptr UncheckedArray[ptr InAddr]](hostEntry.h_addr_list)
      var i = 0
      while addr_list[i] != nil:
        var ip = inet_ntoa(addr_list[i][])
        echo fmt"  {ip}"
        i.inc
    else:
      echo "Failed to get IP addresses"
  
  # Display network adapter information using GetAdaptersInfo
  var adapterInfo: array[8192, byte]  # Buffer for adapter info
  var size = sizeof(adapterInfo).ULONG
  
  if GetAdaptersInfo(cast[PIP_ADAPTER_INFO](addr adapterInfo[0]), addr size) == ERROR_SUCCESS:
    var adapter = cast[PIP_ADAPTER_INFO](addr adapterInfo[0])
    
    while adapter != nil:
      echo fmt"Adapter: {cast[cstring](addr adapter.Description[0])}"
      echo fmt"  MAC: {adapter.Address[0]:02x}:{adapter.Address[1]:02x}:{adapter.Address[2]:02x}:{adapter.Address[3]:02x}:{adapter.Address[4]:02x}:{adapter.Address[5]:02x}"
      echo fmt"  IP: {cast[cstring](addr adapter.IpAddressList.IpAddress.String[0])}"
      echo fmt"  Gateway: {cast[cstring](addr adapter.GatewayList.IpAddress.String[0])}"
      
      # Move to next adapter
      adapter = adapter.Next

# Run the demonstration
getNetworkInfoFixed() 