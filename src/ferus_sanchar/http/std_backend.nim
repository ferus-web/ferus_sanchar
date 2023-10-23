import ../[sanchar, url, telemetry]
import std/[streams, tables, httpcore]
from std/httpclient import HttpHeaders, newHTTPClient, HttpClient, request, code

type
  SancharHTTPClient* = ref object of Sanchar
    client*: HttpClient
    headers: TableRef[string, string]

proc setHeader*(httpClient: SancharHTTPClient, key, val: string) {.inline.} =
  httpClient.headers[key] = val

method fetch*(httpClient: SancharHTTPClient, url: URL): SancharResponse =
  var resp = SancharResponse()
  var headers = newHttpHeaders()
  for header, val in httpClient.headers:
    headers[header] = val
  
  echo $url
  let httpResp = httpClient.client.request($url, headers = headers)
  
  resp.body = httpResp.bodyStream.readAll()
  resp.version = httpResp.version
  resp.statusMsg = httpResp.status
  resp.code = httpResp.code().int
  resp.headers = newTable[string, string]()

  for header, val in httpResp.headers:
    resp.headers[header] = val

  resp

proc newSancharHTTPClient*: SancharHTTPClient =
  SancharHTTPClient(client: newHTTPClient(), headers: newTable[string, string]())
