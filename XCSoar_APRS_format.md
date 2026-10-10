# XCSoar APRS format

XCSoar (https://xcsoar.org/) is an open source glide computer for Android,
iOS, Linux, Windows and Kobo e-readers. Its tracking service, the XCSoar Cloud,
will forward the position of a glider running XCSoar to OGN, so that a pilot
flying out of reach of the ground stations still leaves one continuous track
next to the one the receivers produce.

This document describes what the XCSoar Cloud server sends. Nothing is sent
yet; the format is documented before the first packet goes out.

## 1 Source and identifiers

* APRS-IS login: `XCSOAR`
* TOCALL: `OGNXCS`
* APRS source callsign: `FLR` or `ICA` followed by the aircraft's own six
  hex digit FLARM radio address
* software identifier in the APRS-IS login: `XCSoar-Cloud <version>`

```
user XCSOAR pass <passcode> vers XCSoar-Cloud <version>
```

The app sends its fixes to the XCSoar Cloud server, not to APRS-IS. The server
holds one APRS-IS connection and sends on behalf of the pilots, so each packet
carries the client-side construct `qOR` with no callsign after it. The server
rewrites it, and consumers see `...,qAR,XCSOAR:`.

The examples in section 5 and in `valid_messages/OGNXCS_XCSoar.txt` are what
the XCSoar Cloud server SENDS. `aprsmsgs.txt` carries them in the form the
network emits them.

`OGNXCS` identifies version 1 of this format.

## 2 Which aircraft

Only the aircraft XCSoar flies in, and only when all of these hold:

* the pilot has turned OGN forwarding on in XCSoar. It is off by default, and
  the app repeats the choice with every fix, so the server never forwards a
  position the pilot did not agree to send;
* XCSoar has read the radio address from the connected FLARM (`PFLAC,R,RADIOID`).
  An address the pilot typed is not used: a typing error would put the
  position on somebody else's aircraft;
* the FLARM is not set to `PRIV` (stealth) or `NOTRACK`;
* the OGN device database does not mark the address as not to be tracked or
  not to be identified;
* XCSoar considers the aircraft to be flying.

No traffic received by the phone is relayed: no FLARM, FANET or ADS-B
targets, only the aircraft XCSoar is in.

## 3 Position message

```
<prefix><address>>OGNXCS,qOR:/<timestamp>h<latitude>/<longitude>'<course>/<speed>/A=<altitude> !W<precision>! id<identifier> <climb>fpm
```

* **prefix** — `FLR` when the FLARM reports a FLARM address, `ICA` when it
  transmits the aircraft's ICAO address. It is the same callsign the OGN
  receivers produce for that aircraft, so both tracks merge into one.
* **address** — the six hex digit radio address, as read from the FLARM.
* **timestamp** — UTC time of the fix in `HHMMSS`, never the time of
  transmission.
* **latitude**, **longitude** — uncompressed APRS position with the `/`
  symbol table and the `'` aircraft symbol.
* **course** — ground track in degrees, three digits.
* **speed** — ground speed in knots, three digits. `000/000` means that
  neither is known.
* **altitude** — GPS altitude above mean sea level in feet, six digits. Not
  the barometric altitude, so that it matches what a FLARM sends through a
  ground station and the merged track does not jump between the two.
* **precision** — the third decimal of the latitude and longitude minutes, as
  in OGN-flavoured APRS. The app sends the position in micro degrees.
* **identifier** — eight hex digits `STttttaa` + address, as in OGN-flavoured
  APRS:
  * stealth and no-tracking are always 0, because such an aircraft is not sent
    at all (section 2);
  * aircraft type as set in the FLARM (`ACFT`), which uses the same numbers;
  * address type `2` (FLARM) or `1` (ICAO), as reported by the FLARM. Never
    `3`: the address is the aircraft's own radio address, not one the app
    drew for itself.

  A glider with a FLARM address gives `id06…`, a glider transmitting its ICAO
  address gives `id05…`, a tow plane with a FLARM address `id0A…`.
* **climb** — vertical speed from the GPS altitude in feet per minute, sign
  and three digits. Not a total energy or netto vario.

Deliberately not sent:

* signal strength, frequency offset and error count. A phone on the internet
  receives nothing, and `0.0dB 0e +0.0kHz` would claim a reception that never
  happened;
* the turn rate. The fix the app sends to the Cloud does not carry it, and
  `+0.0rot` would claim straight flight in a thermal.

## 4 Rate

One position every 10 s per aircraft while flying, and never more often. The
app sends one fix every 10 s when forwarding is on; the server forwards a fix
when it arrives and drops a fix older than the last one it sent for that
aircraft. Nothing is queued: a fix that is lost on the mobile network stays
lost.

## 5 Examples

A glider with a FLARM address, released from tow, then circling in a thermal
with one fix every 10 s:

```
FLRDD5A01>OGNXCS,qOR:/123000h4744.29N/01226.10E'060/052/A=003609 !W80! id06DD5A01 +098fpm
FLRDD5A01>OGNXCS,qOR:/123010h4744.18N/01226.19E'150/048/A=003635 !W39! id06DD5A01 +315fpm
FLRDD5A01>OGNXCS,qOR:/123020h4744.18N/01226.00E'270/046/A=003688 !W39! id06DD5A01 +413fpm
FLRDD5A01>OGNXCS,qOR:/123030h4744.30N/01226.11E'030/050/A=003757 !W32! id06DD5A01 +472fpm
FLRDD5A01>OGNXCS,qOR:/123040h4744.19N/01226.20E'150/047/A=003832 !W09! id06DD5A01 +453fpm
```

The same glider on a glide 25 minutes later:

```
FLRDD5A01>OGNXCS,qOR:/125512h4756.79N/01236.40E'095/092/A=005643 !W09! id06DD5A01 -256fpm
FLRDD5A01>OGNXCS,qOR:/125522h4756.76N/01236.79E'095/093/A=005600 !W73! id06DD5A01 -276fpm
```

A glider whose FLARM transmits its ICAO address:

```
ICA3E5A01>OGNXCS,qOR:/131004h4751.72N/01246.99E'210/085/A=006398 !W73! id053E5A01 -177fpm
```

The addresses `DD5A01` and `3E5A01` were not in the OGN device database when
this was written. Every field of these packets, in the emitted form, round
trips through python-ogn-client 2.0.0: position, time, course, ground speed,
altitude, address, address type, aircraft type, stealth, no-tracking and
climb rate.

## 6 Contact

https://github.com/XCSoar/XCSoar/issues/1282

## 7 Related documents

* [OGN APRS messages](aprsmsgs.txt)
* [APRS Protocol Reference, Protocol Version 1.0](http://www.aprs.org/doc/APRS101.PDF)
* [Naviter APRS message specification](Naviter_APRS_format.md)
* [Alpium APRS format](Alpium_APRS_format.md)
