#[
  URL parser
]#

import std/[strutils, strformat, tables]

const DEFAULT_PROTO_PORTS = {
  "ftp": 20'u,
  "http": 80'u,
  "https": 443'u,
  "gemini": 1965'u
}.toTable

type
  # An error that occured whilst initializing a URL, possibly due to bad arguments
  URLDefect* = Defect

  # An error that occured whilst parsing a URL
  URLParseDefect* = Defect
  
  # The current state of the URL parser
  URLParserState* = enum
    sInit, parseScheme, parseHostname, parseFileHost, parsePort, parsePath, parseFragment, parseQuery,
    sEnd, limbo
  
  # The URL parser itself
  URLParser* = ref object of RootObj
    state: URLParserState
  
  # The URL type, contains everything for a URL
  URL* = ref object of RootObj
    # scheme     hostname                   path
    # ^^^^^   ^^^^^^^^^^^^^     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    # https://wikipedia.org:443/wiki/Nim_(programming_language)#Adoption
    #                       ^^^                                 ^^^^^^^^
    #                      port                                 fragment
    scheme: string
    hostname: string
    port: uint
    portRaw: string
    path: string
    fragment: string
    query*: string

    parsedScheme*: bool
    parsedHostname*: bool
    parsedPort*: bool
    parsedPath*: bool
    parsedFragment*: bool

#[
  Get the scheme of a URL
]#
proc getScheme*(url: URL): string {.inline.} =
  url.scheme

#[
  Get the hostname of a URL
]#
proc getHostname*(url: URL): string {.inline.} =
  url.hostname

#[
  Get the port of the URL which is an unsigned integer
]#
proc getPort*(url: URL): uint {.inline.} =
  if url.port == 0:
    if url.scheme in DEFAULT_PROTO_PORTS:
      return DEFAULT_PROTO_PORTS[url.scheme]

  url.port

#[
  Get the path of the URL, granted the URL has one
]#
proc getPath*(url: URL): string {.inline.} =
  url.path

#[
  Get the fragment of the URL, granted it exists
]#
proc getFragment*(url: URL): string {.inline.} =
  url.fragment

#[
  Check if this is a valid IPV4 address
]#
proc isIpv4Address*(url: URL): bool =
  for c in url.hostname:
    if c notin {'0'..'9'} and c != '.':
      return false

  let splittedIp = url.hostname.split('.')

  if splittedIp.len != 4:
    return false

  return true

#[
  Get the TLD domain for this URL. It does not need to be a real TLD (eg. test.blahblahblah).
]#
proc getTLD*(url: URL): string {.inline.} =
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

#[
  Create a new URL object, takes in the scheme, hostname, path, fragment and port.
]#
proc newURL*(
  scheme, hostname, path, fragment: string,
  port: uint = 0
): URL =
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
proc `$`*(url: URL): string {.inline.} =
  fmt"""
Scheme: {url.scheme}
Hostname: {url.hostname}
Port: {url.port}
Path(s): {url.path}
Query: {url.query}
Fragment: {url.fragment}
"""

#[
  Compare two URLs.

  Not using the `==` thing because it makes `pretty` freak out.
]#
proc compare*(url1: URL, url2: URL): bool {.inline.} =
  url1.scheme == url2.scheme and
  url1.hostname == url2.hostname and
  url1.port == url2.port and
  url1.path == url2.path and
  url1.query == url2.query and
  url1.fragment == url2.fragment

#[
  Parse queries and get a sequence of key-value pairs.
]#
proc queries*(url: URL): seq[tuple[key, value: string]] =
  var s: seq[tuple[key, value: string]] = @[]

  var
    key, val: string
    keyDone = false
  
  for query in url.query.split('&'):
    for c in query:
      if not keyDone:
        if c != '=':
          key &= c
        else:
          keyDone = true
      else:
        if c != '&':
          val &= c
    
    keyDone = false
    s.add((key: key, value: val))
    key.reset()
    val.reset()
  
  s

#[
  Parse a string into a URL, granted it is not malformed.
]#
proc parse*(parser: URLParser, src: string): URL =
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
      if curr != ':' and curr != '/':
        if curr.isAlphaAscii() or curr in ['+', '-', '.']:
          url.scheme &= curr.toLowerAscii()
        else:
          raise newException(URLParseDefect, "Non-alphanumeric character in URL scheme: " & curr)
      else:
        parser.state = parseHostname
        if curr == '/':
          pos += 2
        else:
          pos += 3 # discard '//'
        continue
    elif parser.state == parseFileHost:
      url.path &= curr
    elif parser.state == parseHostname:
      if url.scheme == "file":
        pos -= 1
        parser.state = parseFileHost
        continue

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
      elif curr == '?':
        parser.state = parseQuery
      else:
        url.path &= curr
    elif parser.state == parseFragment:
      url.fragment &= curr
    elif parser.state == parseQuery:
      url.query &= curr

    inc pos
  
  if url.portRaw.len > 0:
    url.port = parseUint(url.portRaw)
  elif url.scheme in DEFAULT_PROTO_PORTS:
    url.port = DEFAULT_PROTO_PORTS[url.scheme]
  
  parser.state = sInit
  url

#[
  Create a new URL parser, just a short helper for:
  URLParser(state: sInit)
]#
proc newURLParser*: URLParser {.inline.} =
  URLParser(state: sInit)
