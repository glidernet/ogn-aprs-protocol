https://public-api.safesky.app/swagger-ui/  the public API




======================================================================================================0





SafeSky Public REST API 1.0 
[ Base URL: public-api.safesky.app/ ]https://public-api.safesky.app/v2/api-docs
Welcome to SafeSky developer documentation.
In order to make the sky the safest place on earth, SakeSky wants to contribute significantly at improving interoperability between the various protocols available in the world of aircraft position transmission.

Therefore, SafeSky is encouraging the development of new and innnovative projects by sharing with you our anonymised traffic based on the SafeSky community of pilots.

We are providing you with a set of APIs so that you can create content, apps, websites or any other projects that can benefit from our data integration.

You can use our APIs for free for personal and non-profit applications but any commercial use requires our consent.

By using our API, you are accepting the SAFESKY Data Use Policy.

In order to use our API, you simply need to request an API key along side with a short description of what you plan to build with it.

Usage example:

curl 'https://public-api.safesky.app/v1/stats/overview' --header 'x-api-key: <your_api_key>'
1 - Introduction to ADS-BI
ADS-BI (Automatic Dependent Surveillance-Broadcast-Internet) is an open protocol used by SafeSky to exchange aircraft position data.

This protocol is directly derived from the standard aviation ADS-B protocol (Automatic Dependent Surveillance–Broadcast): a surveillance technology in which an aircraft determines its position via satellite navigation or other sensors and periodically broadcasts it, enabling it to be tracked.

The major difference from the ADS-B protocol is that ADS-B operates over radio signal frequency at 1090 MHz or 978 MHz, where ADS-BI provides the same information as a lightweight internet protocol based on JSON format.

The JSON format is available as two flavors:

A verbose version, encapsulating all the fields and human readable
An optimised version as a JSON array, where each element has a precise position in the array.
In it's optimised version, a typical message has a size of 150 bytes - which can make 1 hour of flight time fit into 50Kb - which is working very well under low internet conditions.

2 - Introduction to FIS-BI
FIS-BI (Flight information services-broadcast-internet) is an open protocol used by SafeSky to exchange flight information services while in the air.

Similar to ADS-BI, FIS-BI protocol is directly derived from the standard aviation FIS-B (Flight information services-broadcast), which provides aeronautical information such as weather text, NOTAMs, ATIS, and similar information. Aircraft that want to receive FIS-B information must be equipped with ADS-B Out and ADS-B In equipment.

With FIS-BI, there is no need for additional equipment. While FIS-B operates over radio signal frequency with a dedicated 978 MHz Universal Access Transceiver, FIS-BI provides the same information as a lightweight internet protocol based on JSON format.

The JSON format is available as two flavors:

A raw format as a short string as broadcasted by the ground station
A decoded format in a human readable format
3 – Available APIs
You will find below our APIs organized by categories. Please watch this space as we are continuously developing API extensions.

Terms of service
Development - Website
Send email to Development
Beacon API
Provides access to SafeSky beacon based on the open ADS-BI protocol.


Health API
Provides health checks against SafeSky.


Stats API
Provides statistics around the SafeSky network.


Traffic Information Service API
Provides access to information services based on the open FIS-BI protocol.


Models
