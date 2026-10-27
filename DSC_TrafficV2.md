# Drone Sky Check Traffic V2 Remote ID feeder — proposal

Status: local implementation and parser tests; NOT an allocated protocol or authorization to publish. Proposed TOCALL: `OGNDSC`. APRS login: to be assigned by OGN. Software: `DSC-TrafficV2 0.1`. Password must be issued by OGN; no calculated APRS passcode is substituted. The login appears only on the login line, never in positions sent by this feeder.

Drone Sky Check is building a distributed Remote ID observation network using fixed and mobile receivers. All observations are processed by a centralized Traffic V2 backend, which handles receiver provenance, aircraft identity, timestamp reconstruction, quality metadata and deduplication. One DSC feeder selects eligible observations for a single persistent APRS connection; individual receivers do not connect to OGN. This document and the coordinated Python parser proposal are submitted for review and discussion before any production activation.

## Input and identity

A single central process reads accepted, unexpired Remote ID observations from DSC Traffic V2. It checks `status=accepted`, `code=ACCEPTED`, digest version and SHA-256 of the stored canonical body. Rejected/quarantined observations and other acquisition protocols are excluded. Smartphone receivers and optional USB receivers remain independent of this output protocol. The feeder does not change ingestion, node identities or authentication.

An external reviewed registry maps full typed, namespaced Remote ID claims to a verified address. There is no hash-based 24-bit allocation. ICAO/FLARM need assignment evidence; OGN allocations additionally need a dated DDB check and evidence of checks against ICAO/FLARM ranges. The operator provides these references; this software cannot certify their truth. A row may list explicitly associated device identities for one aircraft. Duplicate addresses across rows, conflicting claims, unknown/session/MAC identifiers, revoked/expired assignments and ambiguous mappings block forwarding. Serial HEX/UTF8/BASE64 representations normalize to bytes with trailing NUL padding removed; no other identity inference is performed.

Source callsign is `ICAxxxxxx`, `FLRxxxxxx` or `OGNxxxxxx`, matching address type 1, 2 or 3 in the `id` field. Receiver node IDs are never aircraft addresses. Publication evidence is required in each registry row. Explicit no-tracking, stealth or publication denial suppress forwarding. Absence of an RID privacy flag is not consent.

## Measurement time and proposed DSC extension

`/HHMMSSh` is the stored observation `time.measuredAt`, truncated to the APRS whole second. It is never replaced by `receivedAt`, server ingress or transmission time, including after buffering/reconnect. The complete original time object, uncertainty if present, raw RID timestamp and server admission remain in the local bounded queue.

DSC may accept a reconstructed UTC instant. Remote ID location contains deciseconds within an hour (0..35999). AirSense chooses the UTC-hour candidate nearest the receiver reference; Traffic V2 validates reconstruction and admission. The operational profiles use Android GNSS or Android network clock; they are **operational estimates**, with receiverClock UNKNOWN, not certified/synchronized UTC measurements. A 5 s receiver-admission window is not an uncertainty bound. Network time support and availability depend on Android. The feeder copies the accepted instant; it does not repeat or improve this reconstruction.

For example, the synthetic raw RID value `20960` deciseconds represents 34 minutes 56 seconds within the UTC hour. With receiver reference `2026-10-26T12:34:56.500Z`, nearest-hour reconstruction produces `2026-10-26T12:34:56Z`; APRS carries `123456h`. Candidates in the previous, current and next UTC hour handle hour/day rollover. The raw component does not itself identify a date or prove clock synchronization.

The retained DSC fields distinguish `rawTime` (value, encoding and unit), `measurementBasis=RID_HOUR`, `measurementQuality=RECONSTRUCTED_UTC`, `reconstruction` (algorithm, version, referenceBasis, referenceTime), `receiverClock`, `receivedAt`, and server `timeAdmission`. For the example, the GNSS-clock algorithm version is `2-android-gnss-clock` and admission is `OPERATIONAL_ESTIMATED`. Neither that admission nor the APRS token upgrades the estimate to certified UTC. Server `ingestedAt` remains a separate timestamp and is not the position time.

Proposed DSC-only token `dscT<code>` is timestamp provenance, not accuracy:

| Code | Meaning |
|---|---|
| O | Original device fix UTC as declared by the source; no new certification claim |
| G | Reconstructed using Android GNSS clock |
| N | Reconstructed using Android network clock |
| R | Other accepted nearest-hour reconstruction; full provenance retained in DSC |

The token is one whitespace-delimited, case-sensitive, dimensionless provenance code: `dscTO`, `dscTG`, `dscTN` or `dscTR`. It carries no numerical accuracy or uncertainty. Exactly one valid token is recognized for `OGNDSC` position messages. Missing, unknown, malformed or multiple `dscT` tokens produce no DSC time fields in the Python parser; the raw comment remains available. Sources with other TOCALLs keep their existing behavior. The parser values are respectively `device_fix`, `android_gnss_clock`, `android_network_clock`, and `other_reconstruction`; `dsc_time_reconstructed` is false only for O.

Reconstructed output is disabled until OGN explicitly accepts the model. `python-ogn-client` exposes `dsc_time_source` and `dsc_time_reconstructed`, retaining the raw comment. No GPS accuracy or uncertainty is manufactured. This is an explicit deviation/question relative to the exact-UTC wording in Publishing_to_OGN; local acceptance does not resolve that policy question.

## Position and optional fields

Latitude/longitude use WGS84 uncompressed coordinates and `!Wxx!` for the third decimal minute. Rounding carries into degrees. UAV uses symbol `/'`, aircraft type D. Known non-aircraft are suppressed; unknown flight state is marked ground support (symbol `/z`, type E), not silently called airborne.

Course comes from ground track, never magnetic heading; north is 360. Speed is converted from m/s to knots. Both are omitted if either is unavailable. `A=` contains feet above GEOID only, rounded to the nearest foot. An explicitly derived GEOID value requires geoid-model and derivation metadata. WGS84 ellipsoid height, pressure altitude, AGL and takeoff-relative height are never relabelled as MSL. The current candidate does not ship a geoid grid or invent a separation. Negative/out-of-field-range altitude is omitted, never clamped to zero. Missing altitude requires explicit configuration and OGN confirmation; otherwise the observation is withheld.

Geometric vertical speed may be converted to fpm. No turn-rate, FL, RSSI/SNR, error rate, GPS accuracy, hardware or software extra fields are invented. Acquisition quality is preserved in DSC; additional wire fields require a coordinated proposal if OGN needs them.

## Examples — OFFLINE fixtures, not address allocations

The address ABC123 and name DSCDEMO below are documentation fixtures ONLY. They have not been checked or allocated and must not be used on either OGN network. The sample altitude is an explicitly supplied GEOID fixture, not a conversion of an AirSense ellipsoid measurement.

**Feeder sends to server** (path ends at qOR):

```text
OGNABC123>OGNDSC,qOR:/123456h4530.00N/00915.00E'360/021/A=000394 !W00! id37ABC123 +197fpm dscTG
```

**Client receives after server rewriting**, illustrated; not captured from a live OGN server:

```text
OGNABC123>OGNDSC,qAR,DSCDEMO:/123456h4530.00N/00915.00E'360/021/A=000394 !W00! id37ABC123 +197fpm dscTG
OGNABC123>OGNDSC,qAS,DSCDEMO:/123456h4530.00N/00915.00E'360/021/A=000394 !W00! id37ABC123 +197fpm dscTG
```

## Transport and limits

One process owns one persistent connection and a locked SQLite state file. Host `aprs.glidernet.org`; TEST 15580, PRODUCTION 14580. Both configurations start disabled. Production additionally requires explicit enablement and recorded OGN validation. Test also requires verified access, OGN-issued credential and TOCALL approval. Synthetic/replayed input is excluded from production; CLI file preview cannot be combined with network mode. Queue state is bound to its configuration and cannot be reused across environments.

Maximum one position per aircraft per 20 s airborne, 60 s on ground or unknown. No accelerated trajectory exception is implemented. The rate interval survives restart; latest pending fix replaces older fixes for the same allocated address across receivers. Old/equal measurement times are dropped; pending queue is bounded to 1000 aircraft, history to 10000 addresses, freshness 120 s, future tolerance 2 s. Capacity exhaustion stops accepting new entries rather than silently evicting safety history.

A `# DSC-TrafficV2 0.1` comment is sent every 600 s while connected. Every reconnect calls hostname resolution again; backoff doubles to 60 s. The connection consumes server replies, detects EOF and requires verified login. A 900 s receive-idle limit recovers blackholed connections. A fix is durably reserved before socket write. Ambiguous writes are dropped rather than replayed: this favors no duplicate transmission and may lose a fix. TCP write success is **not** an OGN acceptance receipt. The next fresh fix can be sent after the normal rate interval.

## Requested maintainer decisions

1. Authoritative allocation procedure/ranges and DDB validation for Remote ID aircraft claims, including multiple devices on one aircraft.
2. Acceptance or exclusion of reconstructed UTC, the `dscT` token, and publication without GEOID altitude when unavailable.
3. Assignment of TOCALL/login and issue of password/access for TEST.
4. Whether additional RID/quality fields are required; no receiver or aircraft personal identifiers beyond the assigned address are proposed here.

After agreement: controlled TEST operation for several days, observed server/client sentences, then OGN review and separate production approval. This document and parser changes do not themselves authorize network publication.
