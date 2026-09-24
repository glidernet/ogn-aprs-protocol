# VarioVoice APRS format

VarioVoice is an audio-only flight instrument for paragliding and hang gliding.
It speaks; it has no screen to read in flight. Live tracking is one of its
outputs and is off until the pilot turns it on.

Positions are sent over the internet from the phone itself. There is no radio
and no ground station involved, so this is a non-receiving source and the fields
that only a receiver can know are omitted rather than filled with zeros.

What it is for: a paraglider cannot do much to deconflict, but it helps everyone
else to know where to look. The traffic that matters here is faster than we are
and is reading a display: gliders, tow planes, anything powered. Nothing is
shown to our own pilot, who has no screen in flight by design, and this is not a
collision avoidance system for anybody. Telling the pilot out loud where to look
when somebody approaches is a later question; for now the app only transmits.

TOCALL: `OGNVVO`
Callsign: `VVO` + the six hex digits of the OGN device address
Address type: OGN (3)
Aircraft type: paraglider (7) or hang glider (6), whichever the pilot flies

## Login

    user VVO1A2B3C pass <APRS passcode> vers VarioVoice <version>

## Position

    VVO1A2B3C>OGNVVO:/194125h4543.28N/00924.99Eg135/000/A=001083 id1F1A2B3C +118fpm +5.0rot gps5x8

Fields:

- `194125h` the instant of the fix, UTC
- `4543.28N/00924.99E` the position, with the `/` symbol table and the `g`
  symbol
- `135/000` course over ground and ground speed in knots
- `A=001083` GPS altitude in feet
- `id1F1A2B3C` address type OGN, aircraft type paraglider, no stealth, no
  no-tracking. `id1B…` where the pilot flies a hang glider. The two flags follow
  what the pilot chose in the app and in the device database.
- `+118fpm` vertical speed. This one is measured rather than differenced: the
  instrument fuses the barometer with the accelerometer, which is what the whole
  application is built around, so the figure is about a third of a second behind
  the air rather than three.
- `+5.0rot` the rate of turn, in half turns per minute, so this is a paraglider
  circling at fifteen degrees a second. It carries the case the rest of the
  packet cannot: a reader holding two positions will extend them into a line,
  which is right on a glide and wrong in a thermal, where a paraglider goes
  round a forty metre circle and gets nowhere. A target turning at this rate is
  a target not to extrapolate.
- `gps5x8` the GPS accuracy at that fix, horizontal and vertical, in metres.
  CoreLocation states both on every fix, so this costs nothing to send and
  tells a reader how much to trust the position rather than leaving it to be
  assumed. It also keeps the turn rate readable: `python-ogn-client` 1.3.0
  drops whichever of these optional fields ends the packet, so a packet ending
  on `+5.0rot` parses with no turn rate at all, and a field behind it is what
  makes the turn rate survive.

The course and the ground speed are worth one line of their own, because they
are what anybody extrapolating actually uses. CoreLocation repeats the previous
ground speed on about a fifth of its fixes, so a naive implementation sends a
speed belonging to one instant with a course belonging to another. These are
paired on the instant the velocity was measured.

Deliberately **not** sent: signal strength, frequency offset and error count. A
phone on the internet receives nothing, and inventing `0.0dB 0e +0.0kHz` would
claim a radio reception that never happened. The climb and the turn rate are the
opposite case: both are measured, so both are sent.

## How often

Not at a fixed interval. A position goes out when the glider has moved more than
150 m from the last one sent, with a heartbeat every 45 s so that a pilot who
has landed does not vanish, and never more often than one every 10 s. In normal
flying that comes to about 145 transmissions an hour.

A rule on distance rather than on time is what keeps the gap between two points
on the map bounded whatever the glider is doing: a time rule cannot know how
fast it is going, so it leaves a long tail of gaps on fast glides. The distance
is set at half of the largest gap we are willing to leave, so that losing one
transmission to a hole in the mobile coverage still lands inside the budget.

## The device address

Generated once on the phone and kept. Before it is adopted it is checked against
the device database, and another is drawn if it is already registered, so that
nobody ever appears as somebody else's aircraft. The pilot is then shown the
address and invited to register it at ddb.glidernet.org, which is what turns a
number into a name.

## Why the address type says OGN

`1` and `2` are the ICAO and FLARM registries, and an address that a phone drew
for itself belongs to neither of them; `0` is reserved against use. That leaves
`3`, the OGN address space, which is where a self-assigned 24 bit address
belongs and where the device database can resolve it. Pilots are told to
register as device type OGN so that the pair in the packet and the pair in the
database agree, which is what a name on the map depends on.

An earlier draft of this document sent address type `2`, following PureTrack
and FlyXC. The maintainer of this repository asked for `3` on 23 September
2026, and the packets above are what that looks like.

## Contact

rodolfo@saccani.net
