# SITACO APRS format

SITACO is a drone operations platform. DJI drones (for example the Matrice
4TD) connect to it through the DJI Cloud API, and SITACO shows their live
position to the operators. With OGN export, a SITACO deployment also forwards
the position of the drones its admin has enabled, so that other airspace
users see them on OGN maps and apps.

This document describes what a SITACO server sends. The feed starts on the
test network (port 15580).

## 1 Source and identifiers

* APRS-IS login: one login per SITACO deployment, issued by OGN
* TOCALL: `OGNSIT`
* APRS source callsign: `SIT` followed by the drone's six hex digit OGN
  address (section 4), for example `SITB4E21C`
* software identifier in the APRS-IS login: `SITACO 1.0`

```
user <login> pass <password> vers SITACO 1.0
```

The drones never connect to OGN. They send their telemetry to the SITACO
server, and that server holds one long-lived APRS-IS connection per
deployment and sends on behalf of the drones. Each packet ends its path at
`qOR`, with no callsign after it; the server rewrites it and appends the
login.

The examples in section 6 and in `valid_messages/OGNSIT_SITACO.txt` are what
the SITACO server SENDS. `aprsmsgs.txt` carries them in the form clients
receive them.

`OGNSIT` identifies version 1 of this format.

## 2 Which positions

* Only drones. No dock, remote controller, vehicle or other device is ever
  sent.
* Only drones an admin has enabled for OGN export, one by one. Nothing is
  sent by default, and the setting says that the position becomes public.
* Only drones whose address has **no** entry in the OGN Device Database
  (section 4). SITACO checks this before forwarding starts and again once a
  day; a drone whose address gets an entry, of any device type, stops being
  sent until it is moved to a new address.
* Only while the drone is airborne, plus one last position at landing.
  Nothing is sent while the drone is on the ground.
* Only positions with a height above the geoid (section 6) that is not
  below mean sea level. A position without one, or below sea level, is not
  sent.

## 3 Rate

* airborne: one sentence every 20 seconds per drone;
* at landing: one last sentence;
* on the ground: nothing.

The drone reports its position to SITACO about every 2 seconds; the SITACO
server applies the rate. It never sends more often than above.

## 4 Identity

**Address.** DJI drones have no ICAO or FLARM address, so each drone gets an
OGN address (address type 3) in the range `B00000`–`BFFFFF`. SITACO derives
a candidate from the drone's serial number (the serial number itself is
never sent) and adopts it only if it is not registered in the
OGN Device Database and not used by another drone of the same deployment. A
registered address is skipped and the next candidate taken, so a drone never
appears as somebody else's aircraft.

**The addresses are not registered.** SITACO doesn't enter its drones in
the OGN Device Database. Following `Publishing_to_OGN.md`, which asks that an
OGN address "is not already registered in the OGN Device Database", SITACO
uses an address only while it has no entry there:

* forwarding of a drone can be switched on only when a lookup at that
  moment finds no entry for its address;
* once a day SITACO looks up the address of every drone it forwards; a
  drone whose address has an entry by then, of any device type, is no
  longer sent;
* the admin then moves the drone to the next free candidate ("Rotate ID"),
  and it is sent under the new address from then on, never again under the
  old one.

So OGN maps show our drones without a registration or a name, only with
their address. The Uphere and VarioVoice feeds check the addresses they draw
against the Device Database in the same way before they adopt them.

**Aircraft type** is always D (UAV). **Stealth and no-track** are always 0:
an operator who does not want a drone to be seen leaves OGN export off for
it, and then nothing is sent.

No serial number or other hardware identifier is sent.

## 5 Timestamp

**The `HHMMSS` field is the UTC time at which the SITACO server received the
position from the drone. It is not the drone's own measurement time.**

The position reaches SITACO through the DJI Cloud API without a GNSS fix
time that SITACO copies through. The DJI message has a timestamp of its own;
SITACO does not use it. So SITACO stamps each position with its own receive
time, from the server's clock.

The receive time is later than the measurement time by the transmission
delay from the drone to the SITACO server. We expect that delay to be
typically well under a few seconds. **This figure is an estimate; we will
measure it on the test network and report it.**

This differs from section 5 of `Publishing_to_OGN.md`, which asks for the
measurement time of the fix. We ask OGN to say in the review of this
document whether the receive time is acceptable for this feed.

The time the sentence is sent never appears. A sentence waits at most 120
seconds in the server's queue; an older one is dropped. Nothing is replayed
after a reconnect.

## 6 Position message

```
SIT<address>>OGNSIT,qOR:/<HHMMSS>h<lat>/<lon>'<course>/<speed>/A=<altitude> !W<a><b>! id37<address> <climb>fpm
```

* **HHMMSS**: UTC receive time, section 5.
* **lat**, **lon**: uncompressed APRS position, `DDMM.mmN` and `DDDMM.mmE`,
  with the third decimal of the latitude minutes (`a`) and of the longitude
  minutes (`b`) in `!W<a><b>!`, as in OGN-flavoured APRS.
* **symbol**: table `/`, symbol `'`.
* **course**: **the drone's nose heading**, in degrees true, three digits,
  `001`–`360`; north is written `360`. **It is not the direction of
  travel.** A multicopter can fly sideways or backwards, and then the course
  slot does not match its track. SITACO does not compute a direction of
  travel.
* **speed**: ground speed in knots, three digits. A hovering drone sends
  `000`.
* **altitude**: height above the geoid (EGM2008) in feet, six digits. The
  value is not the ellipsoid height and not the height above take-off.
  Never negative: a position below mean sea level is not sent (section 2),
  because parsers such as ogn-parser read the altitude as an unsigned number
  and would drop it together with the course and the speed.
* **id**: `id37` + address. Detail byte `0x37` = `STttttaa` with stealth 0,
  no-track 0, aircraft type D (UAV) and address type 3 (OGN).
* **climb**: vertical speed in feet per minute, sign and at least three
  digits.

Deliberately not sent: turn rate; signal strength, frequency offset and
error count (`dB`, `kHz`, `e`), because no radio reception took place; GPS
accuracy; software and hardware versions; serial numbers; status packets;
fields of our own.

What the SITACO server sends to the APRS server. Addresses and positions are
invented. A drone in cruise; the same drone later, hovering with its nose to
the north; a second drone descending, nose to the south-west; that drone's
last position, at landing:

```
SITB4E21C>OGNSIT,qOR:/104212h4842.74N/00918.94E'072/024/A=001354 !W16! id37B4E21C +039fpm
SITB4E21C>OGNSIT,qOR:/104452h4843.13N/00919.76E'360/000/A=001470 !W45! id37B4E21C +000fpm
SITB71A05>OGNSIT,qOR:/110540h4841.43N/00916.21E'215/003/A=001284 !W10! id37B71A05 -492fpm
SITB71A05>OGNSIT,qOR:/110720h4841.40N/00916.19E'215/000/A=001276 !W06! id37B71A05 +000fpm
```

What an APRS client receives for the first sentence (`SITACO1` stands for
the login of one SITACO deployment):

```
SITB4E21C>OGNSIT,qAR,SITACO1:/104212h4842.74N/00918.94E'072/024/A=001354 !W16! id37B4E21C +039fpm
```

A client further along the network may see `qAS` instead:

```
SITB4E21C>OGNSIT,qAS,SITACO1:/104212h4842.74N/00918.94E'072/024/A=001354 !W16! id37B4E21C +039fpm
```

## 7 Connection

Each SITACO deployment holds one long-lived connection. The server resolves
`aprs.glidernet.org` on every connect and never reuses the address of a
previous connection. While the connection is up it sends a keepalive every
10 minutes:

```
# SITACO 1.0
```

The feed goes to the test port 15580 first. Only after OGN has validated it
does the deployment switch to port 14580.

## Contact

sfink, sfink@m4com.de, https://sitaco.de/
