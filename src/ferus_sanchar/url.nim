## A mostly WhatWG compliant URL parser
## Parsing URLs
## ============
##
## This example creates a URL parser, and parses a string to make it a URL type.
##
## .. code-block:: Nim
##  import ferus_sanchar
##
##  var parser = newURLParser()
##  let url = parser.parse("https://google.com")
##
##  doAssert url.getScheme() == "https"
##  doAssert url.getHostname() == "google.com"
##  doAssert url.getTLD() == "com"

import std/[strutils, tables]

const DEFAULT_PROTO_PORTS = {
  "ftp": 20'u,
  "http": 80'u,
  "https": 443'u,
  "gemini": 1965'u
}.toTable

type
  ## An error that occured whilst initializing a URL, possibly due to bad arguments
  URLDefect* = Defect

  ## An error that occured whilst parsing a URL
  URLParseDefect* = Defect
  
  ## The current state of the URL parser
  URLParserState* = enum
    sInit, parseScheme, parseHostname, parsePort, parsePath, parseFragment, parseQuery,
    sEnd, limbo
  
  ## The URL parser itself
  URLParser* = ref object of RootObj
    state: URLParserState
  
  ## The URL type, contains everything for a URL
  URL* = ref object of RootObj
    # scheme     hostname                   path
    # ^^^^^   ^^^^^^^^^^^^^     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    # https://wikipedia.org:443/wiki/Nim_(programming_language)#Adoption
    #                       ^^^                                 ^^^^^^^^
    #                      port                                 fragment
    scheme: string               ## The scheme of the URL.
    hostname: string             ## The hostname of the URL.
    port: uint                   ## The port of the URL.
    portRaw: string              ## The raw string representing the port of the URL.
    path: string                 ## The path of the URL.
    fragment: string             ## The fragment of the URL.
    query: string                ## The query of the URL.

    parsedScheme: bool
    parsedHostname: bool
    parsedPort: bool
    parsedPath: bool
    parsedFragment: bool

proc `$`*(url: URL): string {.inline.} =
  ## Turn the URL back into a string representation
  ## This can turn a URL back into string form
  ##
  ## .. code-block:: nim
  ##    import ferus_sanchar
  ##
  ##    let url = URL(
  ##      scheme: "https",
  ##      hostname: "google.com",
  ##      port: 443,
  ##      portRaw: "443",
  ##      path: "",
  ##      fragment: "",
  ##      query: ""
  ##    )
  ##
  ##    doAssert $url == "https://google.com/"
  result = url.scheme & "://" & url.hostname

  if url.portRaw.len > 0:
    result &= ':' & url.portRaw

  result &= '/' & url.path

  if url.fragment.len > 0:
    result &= '#' & url.fragment

  if url.query.len > 0:
    result &= '?' & url.query

proc getScheme*(url: URL): string {.inline.} =
  ## Get the scheme of a URL
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##
  ##  let url = URL(
  ##    scheme: "https",
  ##    hostname: "google.com",
  ##    port: 443,
  ##    portRaw: "443",
  ##    path: "",
  ##    fragment: "",
  ##    query: ""
  ##  )
  ##
  ##  doAssert url.getScheme() == "https"
  url.scheme

proc getHostname*(url: URL): string {.inline.} =
  ## Get the hostname of a URL
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##
  ##  let url = URL(
  ##    scheme: "https",
  ##    hostname: "google.com",
  ##    port: 443,
  ##    portRaw: "443",
  ##    path: "",
  ##    fragment: "",
  ##    query: ""
  ##  )
  ##
  ##  doAssert url.getHostname() == "google.com"
  url.hostname

proc getPort*(url: URL): uint {.inline.} =
  ## Get the port of the URL which is an unsigned integer
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##
  ##  let url = URL(
  ##    scheme: "https",
  ##    hostname: "google.com",
  ##    port: 443,
  ##    portRaw: "443",
  ##    path: "",
  ##    fragment: "",
  ##    query: ""
  ##  )
  ##
  ##  doAssert url.getPort() == 443
  if url.port == 0:
    if url.scheme in DEFAULT_PROTO_PORTS:
      return DEFAULT_PROTO_PORTS[url.scheme]

  url.port

proc getPath*(url: URL): string {.inline.} =
  ## Get the path of the URL, granted the URL has one
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##
  ##  let url = URL(
  ##    scheme: "https",
  ##    hostname: "google.com",
  ##    port: 443,
  ##    portRaw: "443",
  ##    path: "",
  ##    fragment: "",
  ##    query: ""
  ##  )
  ##
  ##  doAssert url.getPath() == ""
  url.path

proc getFragment*(url: URL): string {.inline.} =
  ## Get the fragment of the URL, granted it exists
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##
  ##  let url = URL(
  ##    scheme: "https",
  ##    hostname: "google.com",
  ##    port: 443,
  ##    portRaw: "443",
  ##    path: "",
  ##    fragment: "",
  ##    query: ""
  ##  )
  ##
  ##  doAssert url.getFragment() == ""
  url.fragment

proc getTLD*(url: URL): string =
  ## Get the TLD domain for this URL. It does not need to be a real TLD (eg. test.blahblahblah).
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##
  ##  let url = URL(
  ##    scheme: "https",
  ##    hostname: "google.com",
  ##    port: 443,
  ##    portRaw: "443",
  ##    path: "",
  ##    fragment: "",
  ##    query: ""
  ##  )
  ##
  ##  doAssert url.getTLD() == "com"
  var 
    pos: int
    canInc = false
    tld: string

  while pos < url.hostname.len:
    canInc = url.hostname[pos] == '.'
    if canInc: break
    inc pos

  while pos < url.hostname.len:
    tld &= url.hostname[pos]
    inc pos

  tld

proc getQuery*(url: URL): string {.inline.} =
  ## Get the query segment of the URL, granted there was one.
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##
  ##  let url = URL(
  ##    scheme: "https",
  ##    hostname: "google.com",
  ##    port: 443,
  ##    portRaw: "443",
  ##    path: "",
  ##    fragment: "",
  ##    query: ""
  ##  )
  ##
  ##  doAssert url.getQuery() == ""

  url.query

proc newURL*(
  scheme, hostname, path, fragment: string,
  port: uint = 0
): URL =
  ## Create a new URL object, takes in the scheme, hostname, path, fragment and port.
  ##
  ## .. code-block:: Nim
  ##  let url = newURL("https", "google.com", "", "", 443)
  var url = URL()

  url.scheme = scheme
  url.hostname = hostname
  url.path = path
  url.fragment = fragment
  
  if port == 0:
    if scheme in DEFAULT_PROTO_PORTS:
      url.port = DEFAULT_PROTO_PORTS[scheme]
    else:
      raise newException(URLDefect, "Port is 0 and \"" & scheme & "\" does not match any default protocol ports")
  else:
    url.port = port

#[
  Convert the URL into a human-friendly string representation
]#
#[ proc `$`*(url: URL): string {.inline.} =
  fmt"""
Scheme: {url.scheme}
Hostname: {url.hostname}
Port: {url.port}
Path(s): {url.path}
Query: {url.query}
Fragment: {url.fragment}
""" ]#

proc parse*(parser: URLParser, src: string): URL =
  ## Parse a string into a URL, granted it is not malformed.
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##
  ##  var urlParser = newURLParser()
  ##  let url = urlParser.parse("https://google.com")
  var
    pos: int
    curr: char
    url = URL()

  while pos < src.len:
    curr = src[pos]

    if parser.state == sInit:
      parser.state = parseScheme
      continue
    
    if parser.state == parseScheme:
      if curr != ':':
        url.scheme &= curr
      else:
        if curr.toLowerAscii() in {'a'..'z'}:
          raise newException(URLParseDefect, "Invalid character in URL scheme: " & curr)

        parser.state = parseHostname
        pos += 3 # discard '//'
        continue
    elif parser.state == parseHostname:
      if curr == '/':
        parser.state = parsePath
        pos += 1
        continue
      elif curr == '#':
        parser.state = parseFragment
        continue
      elif curr == ':':
        parser.state = parsePort
      elif curr == '?':
        parser.state = parseQuery
        continue
      else:
        url.hostname &= curr
    elif parser.state == parsePort:
      if curr == '/':
        parser.state = parsePath
        pos += 1
        continue
      elif curr == '#':
        parser.state = parseFragment
        continue
      elif curr in {'0'..'9'}:
        url.portRaw &= curr
      else:
        raise newException(URLParseDefect, "Non-numeric character and non-terminator found in URL during port parsing!")
    elif parser.state == parsePath:
      if curr == '#':
        parser.state = parseFragment
        continue
      elif curr == '?':
        parser.state = parseQuery
        continue
      else:
        url.path &= curr
    elif parser.state == parseFragment:
      url.fragment &= curr
    elif parser.state == parseQuery:
      if curr.toLowerAscii() notin {'a'..'z'} and curr notin ['=', ' ']:
        raise newException(URLParseDefect, "Non-alphabetic character found in URL during query parsing!")
      url.query &= curr

    inc pos
  
  if url.portRaw.len > 0:
    url.port = parseUint(url.portRaw)
  elif url.scheme in DEFAULT_PROTO_PORTS:
    url.port = DEFAULT_PROTO_PORTS[url.scheme]
  
  parser.state = sInit
  url

proc newURLParser*: URLParser {.inline.} =
  ## Create a new URL parser
  ## Initialize a new URLParser with the state set to sInit
  ##
  ## .. code-block:: Nim
  ##  var parser = newURLParser()
  URLParser(state: sInit)
