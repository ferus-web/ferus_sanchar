import std/[strformat, options, tables, heapqueue], url

type
  ConnectionStatus* = enum
    csInProgress, csDenied, csIntercepted, csSuccess

  Connection* = ref object of RootObj
    to*: URL
    status*: ConnectionStatus

  SancharDefect* = Defect

  Sanchar* = ref object of RootObj
    processed*: seq[Connection]
    interceptors*: seq[Interceptor] 

  SancharResponse* = ref object of RootObj
    version*: string
    statusMsg*: string
    code*: int
    headers*: TableRef[string, string]
    body*: string

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
Total Processed Connections: {sanchar.processed.len}
"""

proc `$`*(conn: Connection): string {.inline.} =
  fmt"""
To: {$conn.to}
Status: {$conn.status}
"""

proc addInterceptor*(sanchar: Sanchar, interceptor: Interceptor) =
  sanchar.interceptors.add(interceptor)

method fetch*(sanchar: Sanchar, url: URL): tuple[connection: Connection, response: SancharResponse] {.base.} =
  return

proc newSanchar*: Sanchar =
  Sanchar(processed: @[])
