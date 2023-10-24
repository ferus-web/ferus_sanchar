## HTTP client using `std/httpclient`.
##
## .. code-block:: Nim
##  import ferus_sanchar
##
##  let http = newSancharHTTPClient()
##  let resp = http.fetch(parseUrl("https://example.org"))
##
##  echo resp.body

import ../[sanchar, url, telemetry]
import std/[streams, tables, httpcore]
from std/httpclient import HttpHeaders, newHTTPClient, HttpClient, request, code

type
  SancharHTTPClient* = ref object of Sanchar
    client*: HttpClient
    headers: TableRef[string, string]

proc setHeader*(httpClient: SancharHTTPClient, key, val: string) {.inline.} =
  ## Set a HTTP request header that'll be sent to the server
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##
  ##  let http = newSancharHTTPClient()
  ##  http.setHeader("User-Agent", "My very cool user agent")
  + ("Set header \"" & key & "\" to \"" & val & "\"")
  httpClient.headers[key] = val
  - ("Set header \"" & key & "\" to \"" & val & "\"")

method fetch*(httpClient: SancharHTTPClient, url: URL): SancharResponse =
  ## Send a HTTP GET request to a URL
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##
  ##  let http = newSancharHTTPClient()
  ##
  ##  let resp = http.fetch(parseUrl("https://example.org"))
  ##  doAssert resp.isSuccess()
  var telem = newTelemetry(url)

  + "total"

  + "Allocate request headers"
  echo $telem.times
  var resp = SancharResponse()
  var headers = newHttpHeaders()
  for header, val in httpClient.headers:
    headers[header] = val

  - "Allocate request headers"
  
  + "Send HTTP request"
  let httpResp = httpClient.client.request($url, headers = headers)
  - "Send HTTP request"
  
  + "Construct response type"
  resp.body = httpResp.bodyStream.readAll()
  resp.version = httpResp.version
  resp.statusMsg = httpResp.status
  resp.code = httpResp.code().int
  resp.headers = newTable[string, string]()
  - "Construct response type"
  
  + "Allocate response headers"
  for header, val in httpResp.headers:
    resp.headers[header] = val
  - "Allocate response headers"
  - "total"
  
  resp

proc newSancharHTTPClient*: SancharHTTPClient =
  ## Create a new `SancharHTTPClient`
  ##
  ## let http = newSancharHTTPClient()
  SancharHTTPClient(client: newHTTPClient(), headers: newTable[string, string]())
