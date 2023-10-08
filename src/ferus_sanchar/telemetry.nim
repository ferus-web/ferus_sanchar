#[
  Helper class to store information about how long a webpage takes to load
]#
import std/[strformat, times, tables], url

type
  RequestTelemetry* = ref object of RootObj
    url*: URL

    times: TableRef[
      string, 
      tuple[start, stop, total: float]
    ]

proc dump*(telemetry: RequestTelemetry): string =
  var str = fmt"""
RequestTelemetry results:
URL: {telemetry.url}
"""
  
  for op, overview in telemetry.times:
    str &= "\n=> " & op
    str &= "\n\t* start cpu time: " & $overview.start & "s"
    str &= "\n\t* stop cpu time: " & $overview.stop & "s"
    str &= "\n\t* total: " & $overview.total & "s"

  str

proc getTime*(
  telemetry: RequestTelemetry, operation: string
): tuple[start, stop, total: float] =
  telemetry.times[operation]

proc startRequestTimer*(telemetry: RequestTelemetry, operation: string = "total") =
  telemetry.times[operation] = (
    start: cpuTime().float,
    stop: 0.0,
    total: 0.0
  )

proc `+`*(telemetry: RequestTelemetry, operation: string = "total") =
  telemetry.startRequestTimer(operation)

proc stopRequestTimer*(telemetry: RequestTelemetry, operation: string = "total") =
  telemetry.times[operation].stop = cpuTime().float
  telemetry.times[operation].total = cast[float](
    telemetry.getTime("total").stop - telemetry.getTime("total").start
  )

proc `-`*(telemetry: RequestTelemetry, operation: string = "total") =
  telemetry.stopRequestTimer(operation)

proc newTelemetry*(url: URL): RequestTelemetry =
  RequestTelemetry(
    url: url,
    times: newTable[string, tuple[start, stop, total: float]]()
  )
