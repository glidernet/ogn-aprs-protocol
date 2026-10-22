---
title: SkySignals APRS message specification
description: APRS messages sent by the SkySignals backend to OGN
date: 2026-10-21
version: 1.0.0
---

# SkySignals APRS message specification

SkySignals (https://skysignals.app/) is an Android app for paragliding and
hang gliding pilots. It connects over Bluetooth to a SkyCard Radio, which
transmits and receives FLARM-compatible and FANET radio traffic, and shows
that traffic on a radar and a map.

The app sends positions to the SkySignals backend. The backend validates and
rate-controls them and forwards them to OGN over one central persistent
APRS-IS connection. Phones do not open their own connections to send to OGN.

Two kinds of positions are forwarded:

* **own position:** the pilot's own fix, from the SkyCard Radio's GNSS;
* **relayed traffic:** FLARM and FANET aircraft that the pilot's SkyCard Radio
  received by radio. Many paragliding sites, in mountains and in remote areas,
  have no OGN ground station in range. A pilot who lands out or sends a
  distress call there can still be heard by a SkySignals pilot flying nearby,
  and this makes that pilot's position and ground state, such as Need medical
  help or Distress call, visible on OGN.

A position is forwarded only where OGN does not already have it (section 6.3).
In areas with good ground-station coverage nothing is sent.

Nothing is sent yet. The format is documented before the first packet goes
out.

## 1 Identifiers and transport

SkySignals uses the following fixed identifiers:

* APRS-IS login: `SKYSIG`
* TOCALL: `OGNSIG`
* software identifier in the APRS-IS login: `SkySignals-Backend 1.0`

The APRS source callsign is the aircraft the position belongs to, with the
prefix an OGN receiver gives it: `FLR` or `ICA` for FLARM-compatible radio,
`FNT` for FANET (section 4).

The backend login has this form:

```
user SKYSIG pass <password> vers SkySignals-Backend 1.0
```

The backend ends the path of each packet with the client-side construct `qOR`
and no callsign. The APRS-IS server rewrites it to `qAS` followed by the
login, and consumers see `...,qAS,SKYSIG:`. Relayed traffic carries `RELAY*`
before `qOR` (section 2).

Every example in this document is shown twice:

* **SEND** is the sentence the backend sends to APRS-IS;
* **RECV** is the sentence an APRS client receives.

`OGNSIG` identifies version 1 of this format. SkySignals does not append a
version suffix to the TOCALL.

The app also keeps a receive-only APRS-IS connection, logged in as `NOCALL`,
to show OGN traffic on its radar and map. That connection never sends a
position.

The app sends the backend some fields that are never forwarded to OGN:
the received signal strength and the distance at which the SkyCard Radio heard
each aircraft. These feed SkySignals' own statistics on SkyCard Radio
reception.

## 2 Position message

The backend sends only complete position lines in these two forms.

In flight:

```
<prefix><address>>OGNSIG[,RELAY*],qOR:/<timestamp>h<latitude><table><longitude><symbol><course>/<speed>/A=<altitude> !W<precision>! id<identifier>[ <climb>fpm]
```

On the ground, with a FANET ground state (section 3):

```
<prefix><address>>OGNSIG[,RELAY*],qOR:/<timestamp>h<latitude>\<longitude>n !W<precision>! id3E<address> FNT7<state>
```

Parameters:

* **prefix**, **address**: section 4.
* **RELAY\***: present on relayed traffic, absent on the own position. 
* **timestamp**: UTC `HHMMSS` of the position (section 6.1).
* **latitude**, **longitude**: uncompressed APRS position, `DDMM.mmN` and
  `DDDMM.mmE`.
* **table**, **symbol**: `/g` for a paraglider or hang glider, `/'` for any
  other aircraft in flight, and `\n` on the ground.
* **course**: ground track in degrees, three digits.
* **speed**: ground speed in knots, three digits.
* **altitude**: in feet, six digits, above mean sea level. A position whose
  altitude would be negative is not sent, because parsers read this field as
  unsigned.
  * Own position: the GNSS altitude from the SkyCard Radio's GGA sentence,
    without the geoid separation.
  * FLARM-compatible radio: the own GNSS altitude that comes from `$GNGGA` sentence plus the relative vertical distance to  the target that comes from `$PFLAA` sentence.
  * FANET: the altitude field of the FANET tracking packet (type 1), which is the sender's GPS altitude in metres (as encoded in $FNNGB sentence).
* **precision**: the third decimal of the latitude and longitude minutes, as
  in OGN-flavoured APRS.
* **identifier**: eight hex digits, the detail byte `STttttaa` followed by the
  address:
  * stealth and no-track are always 0, because such an aircraft is not sent
    at all (section 5);
  * aircraft type `tttt` is given in section 4;
  * address type `aa` is given in section 4.
* **climb**: vertical speed in feet per minute, sign and three digits. It is
  omitted when the radio packet carries none.

Deliberately not sent:

* **signal strength, frequency offset and error count** (`dB`, `kHz`, `e`).
  The SkyCard Radio reports received power (`RSSI` in `$PFLAA`), not the
  signal-to-noise ratio the `dB` field carries. A relayed position would also
  otherwise count towards some receiver's range statistics;
* **turn rate**, because most targets do not carry it, and `+0.0rot` would
  claim straight flight in a thermal;
* **GPS accuracy** (`gps`), software and hardware versions, and any hardware
  identifier of the phone or the SkyCard Radio;
* **names, registrations and status packets.** No name is sent, neither the
  pilot's own nor any relayed pilot's.

## 3 Ground states

FANET pilots report their state after landing with a FANET ground-tracking
packet (type 7). OGN receivers forward these as `OGNFNT` beacons ending in
`FNT7x`, where `x` is the FANET ground state. SkySignals sends the same
field, the same detail byte (aircraft type `F`) and the same `\n` symbol, with
no course, speed or altitude. That is how the OGN receivers send them.
Relayed ground states are copied from the FANET packet. The pilot's own
ground state is the one selected in the app.

| `state` | FANET ground state |
| --- | --- |
| `8` | Need a ride |
| `9` | Landed well |
| `C` | Need technical support |
| `D` | Need medical help |
| `E` | Distress call |
| `F` | Distress call, automatic |

FANET states 0 to 4 (other, walking, vehicle, bike, boat) are never sent:
vehicles and people on foot stay off the feed.

## 4 Aircraft type and identity

Relayed aircraft are sent under their own identity: the callsign prefix,
address and address type that an OGN receiver gives the same radio packet.
Relayed positions therefore merge into one track with what the ground
stations hear.

| Heard as | Callsign | Address type |
| --- | --- | --- |
| FLARM-compatible radio, `$PFLAA` `IDType` 2 | `FLR` + address | 2 (FLARM) |
| FLARM-compatible radio, `$PFLAA` `IDType` 1 | `ICA` + address | 1 (ICAO) |
| FANET | `FNT` + manufacturer and device id (6 hex digits) | 2, as OGN receivers send FANET |

The own position uses the address the pilot's SkyCard Radio itself
transmits, with the matching prefix and address type. Normally that is the
SkyCard Radio's FLARM address (`FLR`, type 2). If the pilot has configured the
aircraft's ICAO address, it is `ICA`, type 1. OGN receivers in range report
the same SkyCard Radio under the same identity, so the two tracks merge.

The aircraft type is the OGN aircraft type:

* **FLARM-compatible radio:** the aircraft type the radio packet carries,
  which uses the same numbers.
* **Own position:** the aircraft type the pilot set in the app (paraglider by
  default).
* **FANET in flight:** mapped as in the table below.
* **FANET ground states:** `F`, as the OGN receivers send them.

| FANET | OGN |
| --- | --- |
| 0 Other | 0 Unknown |
| 1 Paraglider | 7 Paraglider |
| 2 Hang glider | 6 Hang glider |
| 3 Balloon | 11 Balloon |
| 4 Glider | 1 Glider |
| 5 Powered aircraft | 8 Powered aircraft |
| 6 Helicopter | 3 Helicopter |
| 7 UAV | 13 UAV |

## 5 Privacy and consent

### 5.1 Identifiers and personal data

Neither the 24-bit address nor the APRS message contains a name, email
address, phone identifier or phone MAC address.

SkySignals never creates a 24-bit address of its own. Every address it sends
comes from a radio device:

* for the own position, the SkyCard Radio attached to the app;
* for relayed traffic, the aircraft's own FLARM or FANET device.

That address is the one the device already broadcasts over the air to every
receiver in range. It carries no personal information. An owner may have
registered it in the OGN Device Database or with other public tracking
services, but that is done outside SkySignals. SkySignals does not create or
update entries in the OGN Device Database.

### 5.2 Own position

The own position is sent only when all of these hold:

* the pilot has turned on "Share own position on OGN" in the app. It is off
  by default;
* the SkyCard Radio is not set to stealth or no-track;
* the OGN Device Database does not mark the address as not to be tracked;
* the SkyCard Radio has a GNSS fix with an altitude that is not below mean sea
  level.

The app sends the pilot's choice with every position. The backend checks it
again immediately before forwarding, so a position is never forwarded after
the pilot has turned sharing off.

### 5.3 Relayed traffic

A relayed position is sent only when all of these hold:

* the pilot has "Relay FLARM/FANET traffic to OGN" turned on in the app. It is
  on by default, because the pilots this helps most are the ones nobody else
  can hear;
* the position was received **by radio** by the pilot's own SkyCard Radio.
  Positions the app took from OGN or from any other internet source are never sent back;
* for FLARM-compatible radio, as the SkyCard Radio reports the target in its
  `$PFLAA` sentence:
  * `Source` is 0: the target was received over FLARM-compatible radio.
    Targets taken from ADS-B, ADS-R, TIS-B or Mode-S are never relayed;
  * `NoTrack` is 0: the aircraft has not asked not to be tracked. A target
    whose `$PFLAA` sentence does not carry the `NoTrack` field is not relayed;
  * `IDType` is not 0: the address is not a random (privacy) address;
* for FANET: the "Online Tracking" bit of the FANET packet is set. A pilot who
  cleared it has asked not to appear on internet tracking;
* the OGN Device Database does not mark the address as not to be tracked;
* the aircraft is not ground support or a static object (FLARM aircraft types
  `E` and `F`), and a FANET ground position is one of the states in section 3.

The backend downloads the OGN Device Database once a day and drops every
position, own or relayed, whose address it marks as not to be tracked. Until
the backend has a copy, it forwards nothing.

## 6 Timestamp, rate control, position age and reconnect behaviour

### 6.1 Timestamp

**The timestamp is the time of the position**, taken from the SkyCard
Radio's GNSS clock, never from the phone's or the backend's clock.

* **Own position:** the UTC time of the GNSS fix, from the time field of the
  SkyCard Radio's GGA sentence.
* **Relayed traffic:** FLARM-compatible and FANET radio packets carry no time
  field. They are transmitted within about a second of the fix they contain.
  The SkyCard Radio outputs each received target (`$PFLAA`, FANET) in the same once-a-second cycle as its own GGA sentence. The timestamp is therefore the time of the most recent GGA fix when the target was reported. That is within a second of reception, which is the same time an OGN receiver writes for the same packet.

The app attaches the timestamp when it takes the position, and the backend
copies it into the sentence unchanged.

### 6.2 Rate and position age

The backend applies the rate per aircraft address, across all phones. If
several SkySignals pilots hear the same aircraft, it still goes out at most at
this rate.

* **In flight:** at most one position every 20 seconds.
* **On the ground:** about one position a minute. An aircraft counts as on the
  ground when it reports a FANET ground state, or when its ground speed is
  below 5 km/h with no vertical speed.
* **A change of ground state** (for example from Landed well to Distress call)
  is forwarded at the next opportunity, still no sooner than 20 seconds after
  the previous position for that address.

The backend rejects:

* a position whose timestamp is more than 15 seconds old, or more than 5
  seconds in the future, when it arrives;
* a position not newer than the last one forwarded for that address;
* a queued position that becomes older than 15 seconds before it can be
  written.

### 6.3 Duplicate suppression

The app's receive-only OGN connection shows it the OGN traffic within 50 km of
the pilot (section 1). For 30 seconds after OGN publishes a position for an
address from any source other than `OGNSIG`, the app does not send that
address to the backend. This applies to relayed aircraft and to the pilot's
own SkyCard Radio. Where a ground station hears an aircraft, nothing is
forwarded for it.

### 6.4 Connection and reconnect

* **One connection:** the backend holds one persistent APRS-IS connection to
  `aprs.glidernet.org` on port 14580. It resolves the name on every connection
  and never reuses the address from the previous one.
* **Test network:** the feed runs on port 15580 until OGN has validated it.
* **Keepalive:** while connected, the backend sends
  `# SkySignals-Backend 1.0` every 10 minutes.
* **Reconnect:** the backend reconnects with exponential backoff, starting at
  one second and doubling to a maximum of 60 seconds, with 20% jitter. The
  backoff returns to one second once a connection has stayed up for 30
  seconds.
* **No replay:** the queue keeps only the latest position per address. It is
  cleared on disconnect, and positions received while disconnected are not
  queued, so a reconnect never replays an old track. Only positions received
  after the new connection is up are forwarded.

## 7 Examples

The addresses below were not in the OGN Device Database when this was
written. The same sentences, in the form the backend sends them, are in
[valid_messages/OGNSIG_SkySignals.txt](valid_messages/OGNSIG_SkySignals.txt).

Own position, a paraglider in a thermal, one position every 20 seconds:

```
SEND FLRDF2A61>OGNSIG,qOR:/123010h5152.27N/00032.71Wg214/017/A=003871 !W41! id1EDF2A61 +472fpm
RECV FLRDF2A61>OGNSIG,qAS,SKYSIG:/123010h5152.27N/00032.71Wg214/017/A=003871 !W41! id1EDF2A61 +472fpm
SEND FLRDF2A61>OGNSIG,qOR:/123030h5152.29N/00032.68Wg031/014/A=003958 !W72! id1EDF2A61 +256fpm
RECV FLRDF2A61>OGNSIG,qAS,SKYSIG:/123030h5152.29N/00032.68Wg031/014/A=003958 !W72! id1EDF2A61 +256fpm
```

The same pilot after landing out: Landed well, then Need a ride a minute
later:

```
SEND FLRDF2A61>OGNSIG,qOR:/151502h5150.79N\00030.12Wn !W14! id3EDF2A61 FNT79
RECV FLRDF2A61>OGNSIG,qAS,SKYSIG:/151502h5150.79N\00030.12Wn !W14! id3EDF2A61 FNT79
SEND FLRDF2A61>OGNSIG,qOR:/151602h5150.79N\00030.12Wn !W14! id3EDF2A61 FNT78
RECV FLRDF2A61>OGNSIG,qAS,SKYSIG:/151602h5150.79N\00030.12Wn !W14! id3EDF2A61 FNT78
```

Relayed: a glider with a FLARM address, heard by the pilot's SkyCard Radio:

```
SEND FLRDE91D3>OGNSIG,RELAY*,qOR:/123012h5153.04N/00033.62W'044/064/A=004921 !W42! id06DE91D3 -157fpm
RECV FLRDE91D3>OGNSIG,RELAY*,qAS,SKYSIG:/123012h5153.04N/00033.62W'044/064/A=004921 !W42! id06DE91D3 -157fpm
```

Relayed: a FANET paraglider:

```
SEND FNT07B21C>OGNSIG,RELAY*,qOR:/123014h5151.44N/00031.87Wg355/015/A=003412 !W36! id1E07B21C +118fpm
RECV FNT07B21C>OGNSIG,RELAY*,qAS,SKYSIG:/123014h5151.44N/00031.87Wg355/015/A=003412 !W36! id1E07B21C +118fpm
```

Relayed: a FANET pilot on the ground sending a distress call:

```
SEND FNT07C4E9>OGNSIG,RELAY*,qOR:/124402h5149.97N\00029.92Wn !W54! id3E07C4E9 FNT7E
RECV FNT07C4E9>OGNSIG,RELAY*,qAS,SKYSIG:/124402h5149.97N\00029.92Wn !W54! id3E07C4E9 FNT7E
```

## 8 Contact

skysignalsapp@gmail.com

## 9 Related documents

* [Publishing data to OGN](Publishing_to_OGN.md)
* [OGN APRS messages](aprsmsgs.txt)
* [FANET protocol](FANET.protocol.txt)
* [APRS Protocol Reference, Protocol Version 1.0](http://www.aprs.org/doc/APRS101.PDF)
