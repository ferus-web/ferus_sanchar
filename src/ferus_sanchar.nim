## ferus_sanchar: a fancy new networking stack for Ferus
## It includes a URL parser and HTTP client. Currently, it relies on `std/httpclient` but
## there'll be a proper backend later on.
##
## .. code-block:: Nim
##  import ferus_sanchar
##
##  let httpClient = newSancharHTTPClient()
##  var parser = newURLParser()
##
##  let url = parser.parse("https://example.org")
##
##  echo "Connecting to: " & $url
##
##  let resp = httpClient.fetch(url)
##
##  echo resp.body

import ferus_sanchar/http/http
import ferus_sanchar/[
  responseutils, sanchar, telemetry, url
]

proc parseUrl*(s: string): URL =
  ## Helper function to quickly parse a URL
  ## Try to avoid it when possible as it allocates a new `URLParser` for every call.
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##
  ##  let url = parseUrl("https://github.com")
  var parser = newURLParser()

  parser.parse(s)

export http, responseutils, sanchar, telemetry, url
