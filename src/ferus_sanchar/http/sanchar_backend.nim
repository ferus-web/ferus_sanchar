import std/[strutils, options, strformat, tables, net], 
       ../[sanchar, url, telemetry], pretty

type HTTPClient* = ref object of Sanchar
  socket*: Socket
  requestHeaders*: TableRef[string, string]

proc setHeader*(client: HTTPClient, key, value: string) {.inline.} =
  client.requestHeaders[key] = value

proc getHandshakePayload*(client: HTTPClient, url: URL): string =
  var data = fmt"GET /{url.getPath()} HTTP/1.1"
  data &= "\r\n"
  
  for header, value in client.requestHeaders:
    data &= header & ": " & value & "\r\n"

  data &= "\r\n"

  data

proc parseResponseHeaders(data: string): TableRef[string, string] =
  var
    pos = 0
    value = false
    currKey: string
    currVal: string
    headers = newTable[string, string]()
  
  # while data[pos] != '\l': inc pos

  while pos < data.len:
    case data[pos]:
      of ':':
        if not value:
          value = true
        else:
          currVal &= ':'
      of ' ':
        if value:
          if currVal.len > 1:
            currVal &= ' '
        else:
          currKey &= ' '
      of '\c': discard
      of '\l':
        if currKey.len < 1:
          return headers
        headers[currKey] = currVal
        value = false
        currKey.reset()
        currVal.reset()
      else:
        if value:
          currVal &= data[pos]
        else:
          currKey &= data[pos]
    inc pos

  headers

method fetch*(client: HTTPClient, url: URL): Response =
  var intercepted: bool
  var connection = Connection(
    to: url,
    status: csInProgress
  )
  for interceptor in client.interceptors:
    if interceptor(connection) != true:
      intercepted = true

  client.setHeader("Host", url.getHostname())

  if intercepted:
    connection.status = csIntercepted
    return (connection: connection, response: Response())

  if connection.to.getScheme() == "https":
    when defined(ssl):
      let ctx = newContext()
      wrapSocket(ctx, client.socket)
    else:
      raise newException(SancharDefect, "Attempt to connect to https scheme without compiling with SSL; re-compile with -d:ssl!")
  
  # Connect to the server
  client.socket.connect(connection.to.getHostname(), Port(connection.to.getPort()))
  
  # Send request header
  let payload = client.getHandshakePayload(connection.to)
  client.socket.send(payload)

  var full: string

  while true:
    let next = client.socket.recv(1)
    if next == "":
      break

    full &= next

  echo full
  
  (connection: connection, response: Response())

proc newHTTPClient*: HTTPClient =
  let socket = newSocket()
  result = HTTPClient(socket: socket, requestHeaders: newTable[string, string]())
  result.setHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) Ferus/0.1.1")
