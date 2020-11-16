# HealthMonitoringAppWatchOS

This application collects health information in real-time and sends it over to AWS to analyze for abnormalities. 

<p float="left">
<img src="https://github.com/UBC-CIC/HealthMonitoringAppWatchOS/blob/main/docs/images/watchossc1.png"  width="200"/>
<img src="https://github.com/UBC-CIC/HealthMonitoringAppWatchOS/blob/main/docs/images/watchossc2.png"  width="200"/>
<img src="https://github.com/UBC-CIC/HealthMonitoringAppWatchOS/blob/main/docs/images/watchossc3.png"  width="200"/>
</p>

## Overview 
This app is capable of collecting health information such as heart rate and the location of the user. You can adjust the sampling rate for both location and heart rate to improve battery life. 

## Setup

You should familiarize yourself with Cloudformation, ApiGateway before following the [instructions](https://github.com/UBC-CIC/HealthMonitoringAppWatchOS/blob/main/docs/Setup%20Guide/setup.md).

## AWS Architecture

<img src="https://github.com/UBC-CIC/HealthMonitoringAppWatchOS/blob/main/docs/images/architecture.png"  width="500"/>

## Useful links

[Sample app that collects health information](https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/speedysloth_creating_a_workout)

[Getting user's location](https://developer.apple.com/documentation/corelocation/getting_the_user_s_location)

## Related Projects

[The Mobile Health Monitoring Platform](https://github.com/UBC-CIC/Mobile_Health_Monitoring_Platform)

[HealthMonitoringAppWearOS](https://github.com/UBC-CIC/HealthMonitoringAppWearOS)

## License

This project is distributed under [MIT](https://github.com/UBC-CIC/HealthMonitoringAppWatchOS/blob/main/LICENSE/LICENSE.txt) license.
