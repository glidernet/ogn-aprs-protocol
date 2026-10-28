# Drone Sky Check Remote ID feeder

Drone Sky Check (DSC) implements a centralized APRS feeder for Remote ID observations collected by distributed fixed and mobile receivers. The Traffic V2 backend handles receiver provenance, aircraft identity, measurement-time reconstruction, quality metadata and deduplication. One feeder selects accepted observations and maintains the OGN connection. The implementation and parser have been tested locally.

This proposal follows [Publishing_to_OGN.md](Publishing_to_OGN.md). Proposed TOCALL: `OGNDSC`; software/version: `DSC-TrafficV2 0.1`. The APRS login will be assigned by OGN with its issued password. The feeder name appears on the login line; position paths end at `qOR`.

## Aircraft identity

A persistent assignment registry maps complete, typed Remote ID identities to aircraft addresses. It checks uniqueness of addresses and identity mappings, rejects ambiguous or expired assignments, and supports explicitly associated devices sharing one aircraft address. Basic IDs are not hashed or truncated into 24-bit addresses.

Assignments follow the OGN procedure: use an existing ICAO or FLARM assignment where applicable; otherwise use an OGN address after DDB collision checks and exclusion of ICAO/FLARM ranges. Registry entries retain assignment evidence and dated checks. Real allocations remain unavailable until those checks are verifiable. Callsigns `ICAxxxxxx`, `FLRxxxxxx` and `OGNxxxxxx` match address types 1, 2 and 3 in `id`. Receiver identifiers are separate from aircraft addresses.

The feeder selects accepted, unexpired Remote ID records, validates their stored canonical digest and requires publication authorization in the registry. Explicit no-tracking, stealth or publication denial suppress forwarding.

## Position timestamp

The APRS `/HHMMSSh` field carries the observation's `time.measuredAt`, at whole-second resolution. Traffic V2 reconstructs UTC from the Remote ID temporal component and the receiver's time reference. For RID hour timestamps, the raw value is deciseconds within the UTC hour (0..35999); reconstruction selects the nearest candidate from the previous, current and next hour, including day rollover.

For example, synthetic RID value `20960` and receiver reference `2026-10-26T12:34:56.500Z` yield position time `2026-10-26T12:34:56Z`, encoded as `123456h`. The feeder preserves that measurement time through buffering and reconnection. Receive time and server ingestion time remain separate and do not replace it.

DSC retains the raw value/unit, reconstruction algorithm and reference time, receiver clock basis, measurement quality and receive time. Current reconstructed profiles use GNSS or network-clock references and are classified as operational estimates (`RECONSTRUCTED_UTC` / `OPERATIONAL_ESTIMATED`). These classifications do not specify numerical accuracy or certify clock synchronization. The timestamp mechanism is unchanged by this feeder; its treatment under OGN's measurement-UTC rule is part of this proposal's review.

### Optional provenance extension: dscT

We propose the optional, dimensionless `dscT<code>` token to expose a compact part of that provenance:

| Token | Provenance | Python value `dsc_time_source` |
|---|---|---|
| `dscTO` | Original device fix UTC as declared by the source | `device_fix` |
| `dscTG` | Reconstructed using Android GNSS clock | `android_gnss_clock` |
| `dscTN` | Reconstructed using Android network clock | `android_network_clock` |
| `dscTR` | Other accepted nearest-hour reconstruction | `other_reconstruction` |

The token is case-sensitive and whitespace-delimited. The companion parser recognizes exactly one valid token on an `OGNDSC` position message and sets `dsc_time_reconstructed` to false for O, true otherwise. Missing, unknown, malformed or multiple tokens leave those optional fields absent; ordinary position parsing and other feeders remain unchanged. The raw comment is retained.

`dscT` conveys provenance, not accuracy, and is not a prerequisite for the integration. The local candidate includes it for review; its adoption is independent of the underlying timestamp reconstruction and standard APRS position fields.

## Position, altitude and motion

Latitude/longitude use WGS84 uncompressed coordinates and `!Wxx!` for the third decimal minute. UAVs use symbol `/'` and aircraft type D. Known non-aircraft are excluded; uncertain flight state uses ground support symbol `/z` and type E, as described in Publishing_to_OGN.

`A=` is height above the geoid in feet, rounded to the nearest foot. An explicit GEOID measurement is converted from metres to feet. A derived GEOID measurement is accepted with its geoid-model and derivation metadata. Ellipsoidal height would require a known geoid separation; the feeder does not perform that conversion without an adequate model, nor reinterpret AGL or barometric altitude as geoid height.

Without representable GEOID altitude, the current operational default withholds the position. We propose omission of `A=` as the alternative missing-value policy for maintainer review; the candidate supports this explicitly configured mode. Negative/out-of-field-range values are treated as unavailable, not clamped.

Course is ground track (north 360), speed is knots converted from m/s; both are omitted if either is unavailable. Geometric climb rate is converted to fpm when present. Other OGN extras are left absent when their underlying measurement is unavailable.

## Synthetic examples

These are offline documentation fixtures, not live captures. Address `ABC123`, name `DSCDEMO` and coordinates are synthetic and unallocated; do not transmit these examples. The altitude fixture explicitly supplies a GEOID value.

**Feeder sends** (no login after qOR):

```text
OGNABC123>OGNDSC,qOR:/123456h4530.00N/00915.00E'360/021/A=000394 !W00! id37ABC123 +197fpm dscTG
```

**Client receives**, illustrating the server's path rewrite:

```text
OGNABC123>OGNDSC,qAR,DSCDEMO:/123456h4530.00N/00915.00E'360/021/A=000394 !W00! id37ABC123 +197fpm dscTG
OGNABC123>OGNDSC,qAS,DSCDEMO:/123456h4530.00N/00915.00E'360/021/A=000394 !W00! id37ABC123 +197fpm dscTG
```

## Transport and rate limiting

One central worker owns a persistent connection and locked durable queue. It sends at most one position per aircraft every 20 seconds airborne or 60 seconds on the ground/unknown, with deduplication across receivers and restarts. The latest pending position replaces older ones for the same assigned address. Queue freshness is 120 seconds; capacity is bounded. An ambiguous socket write is not replayed, avoiding duplicate transmission at the possible cost of one fix.

Keepalive is `# DSC-TrafficV2 0.1` every 600 seconds. Reconnection resolves `aprs.glidernet.org` again, with exponential backoff capped at 60 seconds. The connection checks login replies and detects EOF/idle loss. TEST uses 15580; Production uses 14580 with separate configuration/state. No live OGN test or APRS access is claimed here. Network output is currently disabled; TEST operation precedes OGN validation and any Production activation.

## Review points

- Confirm the registry-based assignment procedure for Remote ID aircraft, including multi-device associations.
- Review the documented UTC reconstruction and retained measurement-time provenance.
- Review `OGNDSC` and the optional `dscT` extension.
- Choose the missing-GEOID-altitude policy: withhold, or omit `A=`.

The coordinated parser proposal is [python-ogn-client PR #152](https://github.com/glidernet/python-ogn-client/pull/152). After review and OGN-issued access, the next step is the documented multi-day TEST validation before Production.
