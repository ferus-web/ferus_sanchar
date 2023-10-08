import std/[strutils, options, strformat, tables, net], 
       sanchar, url, pretty, telemetry

type GeminiClient* = ref object of Sanchar
  socket*: Socket
  requestHeaders*: TableRef[string, string]

proc setHeader*(client: GeminiClient, key, value: string) {.inline.} =
  client.requestHeaders[key] = value

proc getHandshakePayload*(client: GeminiClient, url: URL): string =
  var data = fmt"GET /{url.getPath()} HTTP/1.1"
  data &= "\r\n"
  
  for header, value in client.requestHeaders:
    data &= header & ": " & value & "\r\n"

  data &= "\r\n"

  data

method handle*(client: GeminiClient, connection: Connection): Option[Response] =
  #[when defined(ssl):
    let ctx = newContext()
    wrapSocket(ctx, client.socket)
  else:
    raise newException(SancharDefect, "Attempt to connect to https scheme without compiling with SSL; re-compile with -d:ssl!")]#

  var telem = newTelemetry(connection.to)

  telem.startRequestTimer()
  
  telem.startRequestTimer("socket-connect")
  echo connection.to
  client.socket.connect(connection.to.getHostname(), Port(connection.to.getPort()))
  telem.stopRequestTimer("socket-connect")
  
  telem.startRequestTimer("create-request-headers")
  let payload = client.getHandshakePayload(connection.to)
  telem.stopRequestTimer("create-request-headers")

  telem.startRequestTimer("send-request-headers")
  client.socket.send(payload)
  telem.stopRequestTimer("send-request-headers")

  telem.startRequestTimer("receive-and-parse-request-data")

  client.socket.send("gemini://" & connection.to.getHostname() & connection.to.getPath() & "\r\n")

  while true:
    let line = client.socket.recvLine()
    echo line
    if line.len < 1:
      break

  telem.stopRequestTimer("receive-and-parse-request-data")
  telem.startRequestTimer("parse-response-headers")
  # let headers = parseResponseHeaders(hData)
  telem.stopRequestTimer("parse-response-headers")
  telem.stopRequestTimer()
  
  #[if responseCode != 200:
    connection.status = csDenied
  else:
    connection.status = csSuccess]#

  some(Response(
    # headers: headers,
    # body: data,
    # version: protocolVer,
    # statusMsg: statusMsg,
    # code: responseCode
  ))

proc newGeminiClient*: GeminiClient =
  let socket = newSocket()
  result = GeminiClient(socket: socket, requestHeaders: newTable[string, string]())
  result.setHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) Ferus/0.1.1")
