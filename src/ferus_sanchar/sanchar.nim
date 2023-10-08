import std/[strformat, options, tables, heapqueue], url

type
  ConnectionStatus* = enum
    csInProgress, csDenied, csIntercepted, csSuccess

  Connection* = ref object of RootObj
    to*: URL
    status*: ConnectionStatus

  SancharDefect* = Defect

  Sanchar* = ref object of RootObj
    connections*: HeapQueue[Connection]
    processed*: seq[Connection]
    interceptors*: seq[Interceptor] 

  Response* = ref object of RootObj
    version*: string
    statusMsg*: string
    code*: int
    headers*: TableRef[string, string]
    body*: string

  Listener* = proc(conn: Connection, resp: Response)

  Interceptor* = proc(conn: Connection): bool

proc `$`*(status: ConnectionStatus): string {.inline.} =
  case status:
    of csInProgress:
      return "Connection in progress"
    of csDenied:
      return "Denied"
    of csIntercepted:
      return "Intercepted by a specified interceptor"
    of csSuccess:
      return "Completed successfully."

proc `$`*(sanchar: Sanchar): string {.inline.} =
  fmt"""
Pending Connections: {sanchar.connections.len}
Total Processed Connections: {sanchar.processed.len}
"""

proc `$`*(conn: Connection): string {.inline.} =
  fmt"""
To: {$conn.to}
Status: {$conn.status}
"""

proc addInterceptor*(sanchar: Sanchar, interceptor: Interceptor) =
  sanchar.interceptors.add(interceptor)

method fetch*(sanchar: Sanchar, url: URL): tuple[connection: Connection, response: Response] {.base.} =
  return

proc newSanchar*: Sanchar =
  Sanchar(connections: initHeapQueue[Connection](), processed: @[])
