#[
  Convenience functions to deal with HTTP responses.
]#

import std/[tables, strutils, times], sanchar, semver

type
  InvalidValueDefect* = Defect

#[
  Check whether a response was successful, i.e the server responded with a
  status code 200.
]#
proc isSuccess*(response: Response): bool {.inline.} =
  response.code == 200

#[
  Get the protocol version the server uses as a semantic version
]#
proc getVersion*(response: Response): Version {.inline.} =
  assert response.version.len > 0
  parseVersion(response.version)

#[
  Get the time at which the page was last modified, using the Last-Modified
  response header. Keep in mind that this header is spoofable, so this isn't
  a fool-proof solution.
]#
proc getLastModified*(response: Response): DateTime =
  var
    day: string
    dayDone: bool
    dateRaw: string
    dateDone: bool
    month: string
    monthDone: bool
    yearRaw: string
    yearDone: bool
    timeRaw: string
    timeDone: bool
    timezone: string
    tzDone: bool

    year: int

    pos: int
    src = response.headers["Last-Modified"]
  
  while pos < src.len:
    let curr = src[pos]
    if not dayDone:
      if curr == ',':
        dayDone = true
        pos += 2
        continue
      
      day &= curr
    elif not dateDone:
      if curr == ' ':
        dateDone = true
        inc pos
        continue
      
      dateRaw &= curr
    elif not monthDone:
      if curr == ' ' and month.len == 3:
        monthDone = true
        inc pos
        continue

      month &= curr
    elif not yearDone:
      if curr == ' ' and yearRaw.len == 4:
        yearDone = true
        inc pos
        continue

      yearRaw &= curr
    elif not timeDone:
      if curr == ' ':
        timeDone = true
        inc pos
        continue
      
      timeRaw &= curr
    elif not tzDone:
      timezone &= curr

    inc pos

  let mEnum = case month:
    of "Jan":
      mJan
    of "Feb":
      mFeb
    of "Mar":
      mMar
    of "Apr":
      mApr
    of "May":
      mMay
    of "Jun":
      mJun
    of "Jul":
      mJul
    of "Aug":
      mAug
    of "Sep":
      mSep
    of "Oct":
      mOct
    of "Nov":
      mNov
    of "Dec":
      mDec
    else:
      raise newException(InvalidValueDefect, "Invalid month: " & month)

  let
    splittedTime = timeRaw.split(':')
    hour = parseInt(splittedTime[0])
    minute = parseInt(splittedTime[1])
    second = parseInt(splittedTime[2])

  # TODO: timezones
  initDateTime(
    parseInt(dateRaw),
    mEnum,
    parseInt(yearRaw),
    hour, minute, second
  )

proc getContentLength*(response: Response): int {.inline.} =
  response.headers["Content-Length"].parseInt()

proc getCookies*(response: Response): TableRef[string, string] =
  new result

  for cookie in response.headers["set-cookie"].split(';'):
    let
      splittedCookie = cookie.split('=')

    if splittedCookie.len > 1:
      # Key-value pair
      result[splittedCookie[0]] = splittedCookie[1]
    else:
      # Simple key
      result[splittedCookie[0]] = ""
