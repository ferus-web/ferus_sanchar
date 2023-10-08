# Basic HTTP client
import std/os
import ferus_sanchar/[
  http, sanchar, url
]

if paramCount() < 1:
  echo "error: specify a URL"
  quit 1

let urlString = paramStr(1)

let 
  httpClient = newHTTPClient()
  urlParser = newURLParser()
  request = httpClient.fetch(
    urlParser.parse(urlString)
  )

if request.response.code == 200:
  echo request.response.body
