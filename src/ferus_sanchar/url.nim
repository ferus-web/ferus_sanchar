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
    sInit, parseScheme, parseHostname, parsePort, parsePath, parseFragment, parseQuery,
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

proc `$`*(url: URL): string {.inline.} =
  result = url.scheme & "://" & url.hostname

  if url.portRaw.len > 0:
    result &= ':' & url.portRaw

  result &= '/' & url.path

  if url.fragment.len > 0:
    result &= '#' & url.fragment

  if url.query.len > 0:
    result &= '?' & url.query

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
#[ proc `$`*(url: URL): string {.inline.} =
  fmt"""
Scheme: {url.scheme}
Hostname: {url.hostname}
Port: {url.port}
Path(s): {url.path}
Query: {url.query}
Fragment: {url.fragment}
""" ]#

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

#[
  Create a new URL parser, just a short helper for:
  URLParser(state: sInit)
]#
proc newURLParser*: URLParser {.inline.} =
  URLParser(state: sInit)
