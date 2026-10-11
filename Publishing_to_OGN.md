# Publishing data to OGN

This page is for feeders. A feeder forwards aircraft positions to the Open Glider Network (OGN APRS servers).

Write the protocol down in this repository, exercise it on the test network, and only then send it to production.

The position fields are the ones in the OGN aircraft messages, for example [valid_messages/APRS_aircraft.txt](valid_messages/APRS_aircraft.txt), and in the OGN receiver messages in [valid_messages/OGNSDR_TCPIPmsgs.txt](valid_messages/OGNSDR_TCPIPmsgs.txt).

## 1 Two designs

A feeder can be built in either of two ways.

* Each tracker opens its own connection and sends its positions straight to the OGN APRS servers.
* Each tracker sends its positions to the feeder's server, and that server sends them on to the OGN APRS servers. This is the preferred design. The trackers never connect to OGN. One server holds the APRS connection, applies the rules below, and forwards the positions.

Both designs use the same sentences, the same password, and the same rate. The preferred design keeps that connection in one place.

## 2 Describe the protocol

A new feeder writes its protocol document in this repository. For a reference format, use the OGN receiver messages in [valid_messages/OGNSDR_TCPIPmsgs.txt](valid_messages/OGNSDR_TCPIPmsgs.txt).

The document names the feeder and records:

* the APRS-IS login
* the TOCALL
* the source callsign
* the software name and version sent on the login line
* the timestamp rule below: the `HHMMSS` field is the measurement time of that fix
* which existing OGN extra fields the sentence uses, and any field this feeder adds

**Every example is one of two sentences, and the document says which.** The feeder sends one sentence to the APRS server. An APRS client receives another. The position is the same. The path is not, because the server rewrites `qOR` and appends the login.

What the feeder sends to the APRS server:

```
ABC123456>OGNxxx,qOR:/153158h4338.04N/00510.74E'039/000/A=000498 !W85! id07123456 +000fpm +0.0rot
```

What an APRS client receives:

```
ABC123456>OGNxxx,qAR,MYNAME:/153158h4338.04N/00510.74E'039/000/A=000498 !W85! id07123456 +000fpm +0.0rot
```

A client further along the network may see `qAS,MYNAME` instead of `qAR,MYNAME`. A document that shows only one of these sentences, or shows both without saying which is which, does not describe the format.

Put the sentences the feeder sends in the protocol document and under [valid_messages/](valid_messages/). Put the sentences clients receive in [aprsmsgs.txt](aprsmsgs.txt). Add the TOCALL to [tocalls.txt](tocalls.txt). The TOCALL is how a parser tells this feeder from the others. It is an OGN identifier for this protocol, in the same style as the receiver TOCALL `OGNSDR`.

Update [python-ogn-client](https://github.com/glidernet/python-ogn-client) in the same change, so the parser knows the new TOCALL and the extra fields that belong to it. That client is the Python parser OGN uses. A TOCALL that exists only in this repository stays invisible to programs that read the stream through it.

## 3 Ask for the APRS password

The login line is the only place the feeder's name appears:

```
user MYNAME pass <password> vers MySoftware 1.0
```

OGN issues the password for that login. Ask for it by email at [contact@glidernet.org](mailto:contact@glidernet.org).

## 4 Send `qOR`

Each position is one APRS sentence, and the path of that sentence ends at `qOR`:

```
ABC123456>OGNxxx,qOR:/153158h4338.04N/00510.74E'039/000/A=000498 !W85! id07123456 +000fpm +0.0rot
```

`OGNxxx` stands for the TOCALL recorded for this protocol. The login name is not written after `qOR`, and it is not written in the comment. The server rewrites `qOR` and appends the login from the login line. Readers of the stream then see that name on the path, as `qAR,MYNAME` or `qAS,MYNAME`, because the server put it there.

Generic APRS client software does something else. It addresses the sentence to `APRS` and inserts the sender's name on every sentence:

```
ABC123456>APRS,TCPIP*,qAC,MYNAME:/153158h4338.04N/00510.74E'039/000/A=000498 !W85! id07123456 +000fpm +0.0rot
```

That is the wrong path for a feeder. `qAC` is produced by a server. Attaching the name yourself, including as `qOR,MYNAME`, is the same mistake: the name is already on the login line, and the server adds it to the path.

## 5 Timestamp of the position

**The timestamp is the time of the position, and only that time.** The `HHMMSS` field is the exact UTC instant the tracker measured the latitude, longitude, and altitude in the same sentence. In the example above, `153158h` is 15:31:58 UTC of that fix.

The tracker carries that instant with the fix. The feeder copies it through unchanged. A server that receives the fix later still writes the tracker's time. A queue, a retry, and a reconnect do the same: the sentence that finally goes out still carries the original measurement time.

The time the feeder received the position is a different instant, and so is the time the feeder sends the sentence. Either of those, written in place of the measurement time, publishes the right place at the wrong time. The track then sits seconds or minutes away from where the aircraft actually was. Both of those clocks stay out of the sentence.

## 6 Altitude

The `A=` field is the height above the geoid, written in feet. It approximates altitude above mean sea level. The ellipsoid is WGS84, the datum a GPS uses.

A normal GPS reports that height in the NMEA GGA sentence. The feeder copies the GGA altitude into `A=`. In the example above, `A=000498` is 498 feet above the geoid. The geoid separation in the same GGA sentence stays out of `A=`: adding it would turn the value into height above the WGS84 ellipsoid.

## 7 Extra fields

The words after the position are the OGN extra fields. Use the ones the aircraft messages already show, for example in [valid_messages/APRS_aircraft.txt](valid_messages/APRS_aircraft.txt):

* `id` — address, stealth, no-tracking, aircraft type, and address type
* climb rate, in `fpm`
* turn rate, in `rot`
* GPS accuracy, as `gps` with horizontal and vertical metres
* flight level, as `FL`
* software and hardware versions, as `s` and `h`

A radio reception also carries signal-to-noise in `dB`, corrected bit errors in `e`, frequency offset in `kHz`, and received power in `dBm`. A feeder that did not receive the aircraft by radio leaves those out.

A value that none of these fields already carries may be added as a field specific to this tracker. The protocol document names that field, gives its unit, and shows it in an example sentence. When an existing field already carries the same information, that is the field to send.

## 8 Identity

A tracked device uses one of three address types: ICAO, FLARM, or OGN. The two low bits of the `id` detail byte carry that type: `1` for ICAO, `2` for FLARM, `3` for OGN. The six hex digits after that byte are the address.

An aircraft with an ICAO address assigned by an authority uses that address and type ICAO. An aircraft with a FLARM address uses that address and type FLARM. An aircraft with neither uses an OGN address and type OGN.

When several tracking devices ride in the same aircraft, they send that same address and the same address type. The positions then belong to one aircraft.

A device that has a hardware identifier, such as an IMEI, may send it as an extra field on a position sentence. It does not need to be on every sentence. About once every 5 minutes, on a position that is being sent anyway, is enough. When several devices share one OGN, FLARM, or ICAO address and report different positions, that hardware identifier shows which device sent which position. The protocol document names the field.

An OGN address is six hex digits that pass two checks. It is not already registered in the [OGN Device Database](https://ddb.glidernet.org/). It lies outside the ranges assigned to ICAO addresses and outside the ranges assigned to FLARM addresses.

## 9 Track devices that are flying

OGN tracks devices that are flying. A feeder sends those positions.

Boats, cars, and other vehicles that are not aircraft stay off the feed. A tracker in a trailer or in a car stays off the feed too. When the feeder cannot tell well enough to leave that position out, it marks the sentence as ground support in the APRS extra fields: aircraft type `E` in the `id` field, and the APRS symbol `z`. The same aircraft uses its flying type and its flying symbol again once it is in the air.

An aircraft tracker that is on the ground may still send. That position can locate a crashed aircraft. On the ground the feeder sends about one position a minute.

## 10 How often to send

While the aircraft is flying, a feeder sends at most one position every 20 seconds.

It may send more often when it can tell that the path expected from the last sent position, carried forward over those 20 seconds, lies far from the real path. A very high sink rate is one such case. The shorter interval still stops at one position per second.

On the ground, the same aircraft sends about one position a minute.

## 11 Keep the connection

A feeder keeps one APRS connection open. That long-lived connection is the one to use.

While the connection stays up, the feeder sends a keepalive every 10 minutes. The keepalive is a line that starts with `#`, so the server reads it as a comment and not as an APRS position:

```
# MySoftware 1.0
```

## 12 Test network, then production

Both networks answer on the same host: `aprs.glidernet.org`. The servers behind that name are reached by DNS round robin, and a lookup can return a different server each time. A feeder resolves the name when it connects. After a disconnection it resolves the name again and connects to the address that lookup returns. The IP from the previous connection is not kept and not reused.

The test network uses every port you use, plus 1000. A feeder publishes on port **14580**. On the test network that same feeder uses port **15580**. Any other port follows the same rule: keep `aprs.glidernet.org`, and add 1000 to the port.

| Network | Host | Port |
| --- | --- | --- |
| Production | `aprs.glidernet.org` | the port you use, **14580** for a feeder |
| Test | `aprs.glidernet.org` | that port **+ 1000**, so **15580** for a feeder |

**Test data and synthetic data stay on the test servers.** The production port receives positions from aircraft that are actually flying. A position sent to try the software, replayed from a log, or otherwise made up is synthetic. That position, and any other test feed, stays on the test port.

Send the feed to the test port first. The sentences there are the ones described in your protocol document: destination TOCALL, path `qOR`, no copy of your login name, and a timestamp equal to the measurement time of that fix. A sentence stamped with the time it was received, or the time it was sent, is wrong on the test network as well.

Once the feeder has been publishing to the test server for some days, and the pull request for the protocol is ready, email [contact@glidernet.org](mailto:contact@glidernet.org) and ask OGN to validate the content. The production port comes after that validation.
