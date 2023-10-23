# Basic HTTP client
import std/[
  os, tables
]
import ferus_sanchar/[
  http/http, sanchar, url
]

if paramCount() < 1:
  echo "error: specify a URL"
  quit 1

let urlString = paramStr(1)

let 
  httpClient = newSancharHTTPClient()
  urlParser = newURLParser()
  response = httpClient.fetch(
    urlParser.parse(urlString)
  )

for name, val in response.headers:
  echo name & ": " & val

if response.code == 200:
  echo response.body
