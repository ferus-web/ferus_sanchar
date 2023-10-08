# ferus-sanchar: overglorified networking garbage
ferus-sanchar is the new networking stack for Ferus, as the name suggests. It only does HTTP(s) right now, and it has a cool URL parser and built in time measuring (check telemetry.nim)

"sanchar" means "communication" in Hindi, hence the name.

But hey, atleast it's not as overglorified as Chromium's networking stack (yet :D)

# Basic client
```nim
import ferus_sanchar

let 
  sanchar = newHTTPClient()
  parser = newURLParser()
  url = parser.parse("https://en.wikipedia.org")

sanchar.setHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/116.0")
sanchar.setHeader("Host", url.getHostname())

proc handler(conn: Connection, resp: Response) =
  echo "Request finished processing"
  echo resp.code

sanchar.fetch(
  url,
  handler
)
sanchar.process()
```
For a more advanced example, check `tests/test2.nim`

# URL Parser
There's also a URL parser which works for 99% of URLs, perhaps even 100%
```nim
import ferus_sanchar

let
  parser = newURLParser()
  url = parser.parse("https://en.wikipedia.org/wiki/Linus_Torvalds#Authority_and_trademark")
  url2 = parser.parse("http://bigtechcompany.com/nsa_backdoor/sendUserData?password=ihatethensa")

assert url.getScheme() == "https"
assert url2.getScheme() == "http"
assert url2.getHostname() == "bigtechcompany.com"
assert url1.getTLD() != "com"
echo $url
echo $url2
```
