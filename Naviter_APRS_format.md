---
title: OGNAVI APRS message specification
description: Naviter APRS message specification file, Copyright © 2025, Naviter d.o.o. All Rights Reserved
date: 2025-04-14
version: 1.0.2
---

# OGNAVI APRS message specification

Naviter’s APRS message format is built on top of the standard OGN-flavoured APRS aircraft beacon messages.

## 1 Versions

In accordance with the OGN’s versioning schema, all sent messages will be versioned using the `destto` field of the APRS message.

Format version consists of two parts:

1. 6-character long OGN-assigned identifier for Naviter: `OGNAVI`,
2. 1-character long format version

Thus, every version will be formatted as `OGNAVI-<version>`, for example `OGNAVI-1`.

**Note:** The `destto` field _may_ be set to `OGNAVI`. This implies version 1.

### 1.1 Version history

**OGNAVI-1.0.2** — FANET address type added (introduced 2025-04-14)
**OGNAVI-1** — first version (introduced 2017-09-16)

## 2 Message format

### 2.1 OGNAVI-1

Every message will begin with a header and will contain a comment as described below.

Header of each message will be formatted as specified in the original APRS message specification:

```
<device_type><device_id>>OGNAVI,qAS,NAVITER:/<timestamp>h<latitude>/<longitude>'<heading>/<ground_speed>/A=<altitude> <comment>
```

**Parameters:**

* **device_type** — 3-character device type identifier (e.g. NAV, FLR, …)
* **device_id** — 24-bit device identifier written in hexadecimal format. Device identifier is only unique in Naviter’s namespace (e.g. two devices using IDs `NAV000000` and `FLR000000` are not necessarily the same).
* **timestamp** — in HMS format as specified in APRS 1.01 (e.g. `010203` means 01:02:03 UTC)
* **latitude** — as specified in APRS 1.01
* **longitude** — as specified in APRS 1.01
* **heading** — as specified in OGN-flavoured APRS
* **ground_speed** — as specified in OGN-flavoured APRS
* **altitude** — as specified in OGN-flavoured APRS

**Note:** OGN-flavoured APRS specification states that if heading and ground speed are set to 0 (i.e. the relevant part of the message is `000/000`), this indicates no data is provided for either of the fields.

### Comment format

Naviter follows OGN’s comment format closely. Comments will be formatted as:

```
!W<precision_enhancement>! id<identifier> +<climb_rate> <turn_rate>rot
```

**Parameters:**

* **precision_enhancement** — as specified in OGN-flavoured APRS
* **identifier** — 40-bit device identifier (see below)
* **climb_rate** — as specified in OGN-flavoured APRS
* **turn_rate** — as specified in OGN-flavoured APRS

### Device identifier format

The device identifier is a 40-bit sequence encoded in hexadecimal (MSB first), structured as follows:

- Bit 39: stealth mode
- Bit 38: do not track mode
- Bits 34-37: aircraft type
- Bits 28-33: address type (extended from 2 to 6 bits to avoid provider collisions)
- Bits 24-27: reserved
- Bits 0-23: device ID (24-bit, same as in APRS header)

**Note:** In OGN-flavoured APRS, the following address types are used:
- `00`: unknown
- `01`: ICAO
- `10`: FLARM
- `11`: OGN devices

Naviter reserves the following extended address type IDs:

- `000000`: unknown
- `000001`: ICAO
- `000010`: FLARM
- `000011`: OGN trackers
- `000100`: Naviter
- `000101`: FANET

More types may be added later.

## 3 Examples

```
NAV042121>OGNAVI,qAS,NAVITER:/140648h4550.36N/01314.85E'090/152/A=001086 !W47! id0440042121 +000fpm +0.5rot
NAV04220E>OGNAVI,qAS,NAVITER:/140748h4552.27N/01155.61E'090/012/A=006562 !W81! id044004220E +060fpm +1.2rot
NAV07220E>OGNAVI,qAS,NAVITER:/125447h4557.77N/01220.19E'258/056/A=006562 !W76! id1C4007220E +180fpm +0.0rot
```

## 4 Other

### 4.1 Relaying messages from other devices

Naviter can relay the position of a FLARM or other similar device connected to an Oudie via its network. The origin of such messages will be `FLR<flarm_id>`, not `NAV<device_id>`. However, the message still uses the OGNAVI schema.

Format of such relayed messages:

```
<device_type><device_id>>OGNAVI,<relay_id>*,qAS,NAVITER:/<timestamp>h<latitude>/<longitude>'<heading>/<ground_speed>/A=<altitude> <comment>
```

**relay_id** is the identifier of the device that relayed the message, formatted as `<device_type><device_id>`, where `device_id` is a 6-character hexadecimal value.

An asterisk `*` after the relay ID indicates that the message was relayed.

**Example:**

```
FLRFFFFFF>OGNAVI,NAVABCDEF*,qAS,NAVITER:/092002h1000.00S/01000.00W'000/000/A=003281 !W00! id2820FFFFFF +300fpm +1.7rot
```

## 5 Related documents

* **APRS Protocol Reference, Protocol Version 1.0:** [http://www.aprs.org/doc/APRS101.PDF](http://www.aprs.org/doc/APRS101.PDF)
* **OGN-flavoured APRS:** [OGN-flavoured APRS Spec](https://github.com/svoop/ogn_client-ruby/wiki/OGN-flavoured-APRS/c6678fecc15222cb980f491d09dfaba7e2982df6)
