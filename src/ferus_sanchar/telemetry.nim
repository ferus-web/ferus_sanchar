## Helper utilities to measure how long each segment takes to complete
##
## .. code-block:: Nim
##  import ferus_sanchar
##  let url = parseUrl("https://github.com")
##  var telem = newTelemetry(url)
##  
##  + "do-stuff"
##
##  echo url.getHostname()
##
##  - "do-stuff"
##
##  echo $telem

import std/[algorithm, strformat, times, tables], url

type
  RequestTelemetry* = ref object of RootObj
    url*: URL                               ## The URL this telemetry data is for

    times: seq[                             ## All the timing data for this URL.
      tuple[                                ## Includes when an operation began, when it
        id: int,                            ## stopped and the total time it took to
        op: string,                         ## complete it.
        start, stop, total: float
      ]
    ]

    currId: int

var globalTelem: RequestTelemetry

proc dump*(telemetry: RequestTelemetry = nil): string =
  ## Dump the telemetry details into a human-friendly string for reading.
  ##
  ## .. code-block:: Nim
  ##  import ferus_sanchar
  ##  let t = newTelemetry(parseUrl("https://github.com"))
  ##
  ##  + "blah"
  ##  echo "hello, world!"
  ##  - "blah"
  ##
  ##  echo telem.dump()
  ##
  ## See also:
  ## * `$ proc`_
  var str = fmt"""
RequestTelemetry results:
URL: {telemetry.url}
"""

  var t: RequestTelemetry

  if telemetry == nil:
    assert globalTelem != nil, "Both telemetry and globalTelemetry are nil, cannot dump anything."
    t = globalTelem
  else:
    t = telemetry
  
  t.times.sort()
  for overview in t.times:
    str &= "\n=> #" & $overview.id & ": " & overview.op
    str &= "\n\t* start cpu time: " & fmt"{overview.start:02f}" & "s"
    str &= "\n\t* stop cpu time: " & fmt"{overview.stop:02f}" & "s"
    str &= "\n\t* total: " & fmt"{overview.total:02f}" & "s"

  str

proc `$`*(telemetry: RequestTelemetry): string {.inline.} =
  ## Helper for `dump proc`_
  telemetry.dump()

proc getTime*(
  telemetry: RequestTelemetry, operation: string
): tuple[id: int, op: string, start, stop, total: float] =
  ## Get the time-related data for an operation.
  ##
  ## See also:
  ## * `start proc`_
  ## * `stop proc`_
  for t in telemetry.times:
    if t.op == operation:
      return t

proc start*(telemetry: RequestTelemetry, operation: string = "total") =
  ## Start the time countdown for an operation.
  ##
  ## .. code-block:: Nim
  ##  telemetry.start("doing-the-dishes")
  ##  echo "Washing dishes..."
  ##
  ## See also:
  ## * `+ proc`_
  ## * `stop proc`_
  inc telemetry.currId
  telemetry.times.add((
    id: telemetry.currId,
    op: operation,
    start: cpuTime().float,
    stop: 0.0,
    total: 0.0
  ))

proc `+`*(operation: string) {.inline.} =
  ## Uses `globalTelem` (or the last RequestTelemetry instance created with `newTelemetry proc`_)
  ## and calls `telemetry.start proc`_ on it.
  ##
  ## .. code-block:: Nim
  ##  var t = newTelemetry(parseUrl("https://example.com"))
  ##  + "do-stuff"
  ## 
  ## See also:
  ## * `start proc`_
  ## * `- proc`_
  ## * `stop proc`_
  assert globalTelem != nil, "You cannot use `+` without calling newTelemetry() atleast once"
  globalTelem.start(operation)

proc stop*(telemetry: RequestTelemetry, operation: string) =
  ## Stops the time countdown for an operation and calculates the total time taken.
  ##
  ## .. code-block:: Nim
  ##  telemetry.stop("doing-the-dishes")
  var i: int = -int.high
  for idx, t in telemetry.times:
    if t.op != operation: continue
    i = idx
  
  assert i != -int.high
  telemetry.times[i].stop = cpuTime().float
  telemetry.times[i].total = cast[float](
    telemetry.getTime(operation).stop - telemetry.getTime(operation).start
  )

proc `-`*(operation: string) =
  ## Uses `globalTelem` (or the last RequestTelemetry instance created with `newTelemetry proc`_)
  ## and calls `telemetry.stop proc`_ on it.
  ##
  ## .. code-block:: Nim
  ##  - "do-stuff"
  ##
  ## See also:
  ## * `stop proc`_
  assert globalTelem != nil, "You cannot use `-` without calling newTelemetry() atleast once"
  globalTelem.stop(operation)

proc newTelemetry*(url: URL): RequestTelemetry =
  ## Creates a new `RequestTelemetry type`_ and overrides `globalTelem`
  globalTelem = RequestTelemetry(
    url: url,
    times: @[]
  )

  globalTelem
