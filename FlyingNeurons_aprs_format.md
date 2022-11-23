

# APRS Messages for Neurones and MiniNeurones
#
# OGNFNO APRS message specification

Flying Neurons

Rev 1 - 23 Nov 2023

## 1 - INTRODUCTION

Neurones (and MiniNeurones) are GPS trackers (and radio transmitter/receivers) which are sending theposition of an aircraft to Flying Neurons server via the app NeuroFly running onboard.

Flying Neurons server is then transferring the data to OGN servers in APRS format for being visible though OGN network.

## 2 - APRS MESSAGES TO OGN SERVER

The messages sent to the OGN server are in the form :

        FNO0003F4>OGNFNO,qOR:/153158h4338.04N/00510.74E'039/000/A=000498 !W85! id200003F4 +000fpm +0.0rot

FNO is the trigram for Flying Neurons trackers (Neurones , MiniNeurones)


## 3 - APRS MESSAGES FROM OGN SERVER 

These messages will be forwarded in the following format to clients by the OGN servers :

        FNO0003F4>OGNFNO,qAS,Neurone:/153158h4338.04N/00510.74E'039/000/A=000498 !W85! id200003F4 +000fpm +0.0rot



## 4 - APRS format description :

It strictly follows the specification of APRS message with the extension OGN-flavoured APRS.

- The tracker type is FNO (3 first characters).

- The tracker id in HEX format in in the 6 following characters (0003F4 in the example above).

- The device identifier idXXYYYYYY  is following OGN/FLARM convention :

XX encodes stealth mode (always 0), no-tracking flag T (always 0), aircraft type tttt and address type aa (always 00) as follows:

        STttttaa    (8 bits from most to least significant).

        S set to 0

        T set to 0

        tttt : same categories as for FLARM :

        Hexadecimal value. Range: from 0 to F.

        Aircraft types as assigned by FLARM:

        0 = (reserved)
        1 = glider/motor glider (turbo, self-launch, jet) / TMG
        2 = tow plane/tug plane
        3 = helicopter/gyrocopter/rotorcraft
        4 = skydiver, parachute (Do not use for drop plane!)
        5 = drop plane for skydivers
        6 = hang glider (hard)
        7 = paraglider (soft)
        8 = aircraft with reciprocating engine(s)
        9 = aircraft with jet/turboprop engine(s)
        A = unknown
        B = balloon (hot, gas, weather, static)
        C = airship, blimp, zeppelin
        D = unmanned aerial vehicle (UAV, RPAS, drone)
        E = (reserved)
        F = static obstacle

        aa : set to 0b00  (not FLARM, not ICAO, not OGN tracker)
        
