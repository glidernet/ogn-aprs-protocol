# Uphere APRS format

Uphere (https://uphere.app) is a web app for VFR pilots in Hungary. On a
tablet mounted in the aircraft it shows which airspace the aircraft is in and
which frequency to call, the day's active areas from the airspace use plan,
the terrain and airspace cross-section ahead, a route planner, and the live
OGN traffic around the aircraft. Position sharing is the other half of that
traffic feature: a pilot who turns it on is forwarded to OGN, so that the
aircraft is visible to every other OGN consumer as well, and leaves one track
next to the one the ground stations produce where receivers hear it.

This document describes what the Uphere server sends. Nothing is sent yet;
the format is documented before the first packet goes out, and the first
packets go to the test network (port 15580).

## 1 Source and identifiers

* APRS-IS login: `UPHERE`
* TOCALL: `OGNUPH`
* APRS source callsign: `ICA` followed by the aircraft's ICAO 24-bit address
  when the pilot entered it in the app's aircraft profile, otherwise `UPH`
  followed by the six hex digit OGN address the tablet drew for itself
  (section 4)
* software identifier in the APRS-IS login: `Uphere-Server <version>`

```
user UPHERE pass <passcode> vers Uphere-Server 1.0
```

The tablets send their fixes to the Uphere server (a Google Cloud function in
europe-west1), not to APRS-IS. The server holds one APRS-IS connection and
sends on behalf of the pilots, so each packet carries the client-side
construct `qOR` with no callsign after it. The server rewrites it to `qAS`
followed by the login, and consumers see `...,qAS,UPHERE:`.

The examples in section 6 and in `valid_messages/OGNUPH_Uphere.txt` are what
the Uphere server SENDS. `aprsmsgs.txt` carries them in the form the network
emits them.

`OGNUPH` identifies version 1 of this format.

## 2 Which positions

Only the aircraft the tablet is in, and only when all of these hold:

* the pilot has turned position sharing on in the app's settings. It is off
  by default, and the setting says that the position becomes public on OGN;
* the fix comes from the tablet's GNSS. The app also has a manual position
  for planning and a route simulator; neither is ever sent;
* the fix is at most 15 seconds old when the server receives it. The tablet
  queues nothing while it has no mobile coverage and replays nothing
  afterwards: a position that arrives late is dropped, not sent late;
* the app's aircraft profile names the aircraft type (section 4).

Boats, cars and people on foot never appear: the tablet is used in an
aircraft. On the ground (ground speed below 5 kt for 60 s) the aircraft is
still sent, once a minute, with its flying type and symbol, so that a stopped
or crashed aircraft can be located.

## 3 Rate

* in flight at most one sentence every 20 seconds per aircraft;
* sooner, down to one every 5 seconds, when the new fix lies far from the
  last sent fix carried forward: more than 300 m off the dead-reckoned
  position, a track change of more than 30°, or a climb-rate change of more
  than 500 ft/min;
* on the ground one sentence a minute.

The tablet sends a fix to the Uphere server every 5 seconds. The server
applies the rate above; the tablet never decides what reaches OGN.

## 4 Identity and aircraft type

**Address.** When the pilot entered the aircraft's ICAO 24-bit address in the
aircraft profile, that address is sent with address type 1 (ICAO) and the
callsign `ICA` + address. An ADS-B or FLARM device in the same aircraft that
the ground stations hear reports the same address, so the two tracks merge
into one aircraft.

Otherwise the tablet draws a six hex digit OGN address once and keeps it. The
address lies outside the ranges assigned to ICAO and to FLARM addresses, and
the server checks it against the OGN Device Database before it is adopted: a
registered one is discarded and another drawn, so nobody appears as somebody
else's aircraft. It is sent with address type 3 (OGN) and the callsign `UPH`
+ address. The pilot sees the address in the app and is invited to register
it at https://ddb.glidernet.org/ as device type OGN, with the registration and
the tracked / identified flags they want. Nothing but that registration turns
the address into a name.

**Aircraft type**, from the aircraft profile, as the OGN aircraft type:

| profile | OGN type | symbol |
| --- | --- | --- |
| powered aircraft, including ultralights (default) | 8 | `/'` |
| glider or motor glider | 1 | `/g` |
| tow plane | 2 | `/'` |
| helicopter | 3 | `/X` |
| balloon | 11 | `/O` |

**Stealth and no-track** are always 0. A pilot who does not want to be seen
turns sharing off, and then nothing is sent at all.

## 5 Privacy

The sentence carries the address, the position and the motion, and nothing
else: no name, no registration, no e-mail address, no identifier of the
tablet. Whether a registration is shown next to the address is decided by the
pilot in the OGN Device Database, not by Uphere. The server keeps no log of
what it forwarded.

The same server reads the OGN feed for the app's traffic display and applies
the Device Database rules to it (no-track and stealth packets dropped, hidden
devices not shown, registrations only for identified devices). The pilot's own
aircraft is matched by its address, so it is not drawn twice.

## 6 Position message

```
<callsign>>OGNUPH,qOR:/<HHMMSS>h<lat><table><lon><symbol><course>/<speed>/A=<altitude> !W<xy>! id<detail><address> <climb>fpm[ <turn>rot][ gps<h>x<v>]
```

* **HHMMSS**: the UTC instant the tablet's GNSS measured this fix. The server
  copies it through unchanged; the time the server received or sent the
  sentence never appears.
* **lat**, **lon**: uncompressed APRS position, `DDMM.mmN` and `DDDMM.mmE`,
  with the third decimal of the minutes in `!W<xy>!` as in OGN-flavoured
  APRS.
* **table**, **symbol**: section 4.
* **course**: ground track in degrees true, three digits.
* **speed**: ground speed in knots, three digits.
* **altitude**: height above the geoid in feet, six digits. On iOS it is the
  altitude CoreLocation reports; on Android, where the GNSS height is above
  the WGS84 ellipsoid, the EGM96 geoid separation is subtracted. A fix whose
  altitude would be negative is not sent, because the field is unsigned.
* **detail**, **address**: the `id` field, detail byte `STttttaa` (stealth
  and no-track 0, aircraft type and address type from section 4) and the six
  hex digit address. Powered aircraft with an OGN address: `id23…`; glider
  with an ICAO address: `id05…`.
* **climb**: vertical speed in feet per minute, sign and three digits, from
  the GNSS altitude over the last 10 seconds, smoothed.
* **turn**: rate of turn in half-turns per minute, from the GNSS track over
  the last 5 seconds. Omitted below 5 kt ground speed, where the track is
  noise.
* **gps**: horizontal and vertical GNSS accuracy in metres, as the tablet
  reports them. Omitted when the tablet gives no vertical accuracy. It also
  keeps the turn rate readable in `python-ogn-client` 1.3.x, which drops the
  optional field that ends a packet.

Deliberately not sent: signal strength, frequency offset and error count
(`dB`, `kHz`, `e`), because no radio reception took place; software and
hardware versions; status packets; names and registrations.

What the server sends to the APRS server (a powered aircraft near Budaörs,
Hungary, first in level flight, then 20 s later, then 6 s after that because
its track changed by more than 30°):

```
UPH3C9F2A>OGNUPH,qOR:/104212h4727.33N/01854.17E'198/097/A=002493 !W64! id233C9F2A -064fpm +0.3rot gps4x7
UPH3C9F2A>OGNUPH,qOR:/104232h4726.82N/01853.93E'198/097/A=002471 !W38! id233C9F2A -064fpm +0.0rot gps4x7
UPH3C9F2A>OGNUPH,qOR:/104238h4726.67N/01853.82E'240/092/A=002480 !W60! id233C9F2A +120fpm +2.0rot gps5x8
```

A glider whose pilot entered the ICAO address, and the powered aircraft above
after landing, on the one-a-minute ground rate:

```
ICA4703C1>OGNUPH,qOR:/104240h4731.10N/01848.55Eg305/058/A=003215 !W27! id054703C1 +236fpm +4.0rot gps5x9
UPH3C9F2A>OGNUPH,qOR:/112001h4726.96N/01854.21E'000/000/A=000495 !W12! id233C9F2A +000fpm gps3x5
```

What an APRS client receives for the first sentence:

```
UPH3C9F2A>OGNUPH,qAS,UPHERE:/104212h4727.33N/01854.17E'198/097/A=002493 !W64! id233C9F2A -064fpm +0.3rot gps4x7
```

## 7 Connection

The server resolves `aprs.glidernet.org` on every connect and never reuses
the address of a previous connection. While the connection is up it sends a
keepalive every 10 minutes:

```
# Uphere-Server 1.0
```

The feed goes to the test port 15580 first. Only after OGN has validated it
does the server switch to port 14580.

## Contact

Miklós Csanády, miklos.csanady@gmail.com, https://uphere.app
