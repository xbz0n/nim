import winim/lean
import strformat

proc performWmiQuery() =
  echo "WMI Query Demonstration"
  echo "======================="
  
  var hr = CoInitializeEx(nil, COINIT_MULTITHREADED)
  if FAILED(hr):
    echo fmt"Failed to initialize COM: 0x{hr:X}"
    return
  defer: CoUninitialize()
  
  # Initialize security
  hr = CoInitializeSecurity(
    nil, 
    -1, 
    nil, 
    nil, 
    RPC_C_AUTHN_LEVEL_DEFAULT, 
    RPC_C_IMP_LEVEL_IMPERSONATE, 
    nil, 
    EOAC_NONE, 
    nil
  )
  
  if FAILED(hr) and hr != RPC_E_TOO_LATE:
    echo fmt"Failed to initialize security: 0x{hr:X}"
    return
  
  # Create WMI locator
  var pLoc: ptr IWbemLocator
  hr = CoCreateInstance(
    addr CLSID_WbemLocator, 
    nil, 
    CLSCTX_INPROC_SERVER, 
    addr IID_IWbemLocator, 
    cast[ptr LPVOID](addr pLoc)
  )
  
  if FAILED(hr):
    echo fmt"Failed to create IWbemLocator: 0x{hr:X}"
    return
  defer: pLoc.Release()
  
  # Connect to WMI
  var pSvc: ptr IWbemServices
  var resource: BSTR = SysAllocString("ROOT\\CIMV2")
  defer: SysFreeString(resource)
  
  hr = pLoc.ConnectServer(
    resource,
    nil, # User
    nil, # Password
    nil, # Locale
    0,   # Security flags
    nil, # Authority
    nil, # Context
    addr pSvc
  )
  
  if FAILED(hr):
    echo fmt"Failed to connect to WMI: 0x{hr:X}"
    return
  defer: pSvc.Release()
  
  # Set security levels
  hr = CoSetProxyBlanket(
    cast[ptr IUnknown](pSvc),
    RPC_C_AUTHN_WINNT,
    RPC_C_AUTHZ_NONE,
    nil,
    RPC_C_AUTHN_LEVEL_CALL,
    RPC_C_IMP_LEVEL_IMPERSONATE,
    nil,
    EOAC_NONE
  )
  
  if FAILED(hr):
    echo fmt"Failed to set proxy blanket: 0x{hr:X}"
    return
  
  # Execute query
  var pEnumerator: ptr IEnumWbemClassObject
  var query: BSTR = SysAllocString("SELECT * FROM Win32_OperatingSystem")
  defer: SysFreeString(query)
  
  hr = pSvc.ExecQuery(
    SysAllocString("WQL"),
    query,
    WBEM_FLAG_FORWARD_ONLY or WBEM_FLAG_RETURN_IMMEDIATELY,
    nil,
    addr pEnumerator
  )
  
  if FAILED(hr):
    echo fmt"Failed to execute query: 0x{hr:X}"
    return
  defer: pEnumerator.Release()
  
  # Process results
  var pclsObj: ptr IWbemClassObject
  var uReturn: ULONG = 0
  
  while pEnumerator.Next(WBEM_INFINITE, 1, addr pclsObj, addr uReturn) == 0:
    var vtProp: VARIANT
    
    # Get Caption property
    hr = pclsObj.Get(
      SysAllocString("Caption"),
      0,
      addr vtProp,
      nil,
      nil
    )
    
    if SUCCEEDED(hr):
      echo fmt"Operating System: {vtProp.bstrVal}"
      VariantClear(addr vtProp)
    
    # Get Version property
    hr = pclsObj.Get(
      SysAllocString("Version"),
      0,
      addr vtProp,
      nil,
      nil
    )
    
    if SUCCEEDED(hr):
      echo fmt"Version: {vtProp.bstrVal}"
      VariantClear(addr vtProp)
    
    # Get OSArchitecture property
    hr = pclsObj.Get(
      SysAllocString("OSArchitecture"),
      0,
      addr vtProp,
      nil,
      nil
    )
    
    if SUCCEEDED(hr):
      echo fmt"Architecture: {vtProp.bstrVal}"
      VariantClear(addr vtProp)
    
    pclsObj.Release()

performWmiQuery() 