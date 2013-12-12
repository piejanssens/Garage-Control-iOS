Garage-Control-iOS
==================

[Arduino Garage Control](https://github.com/piejanssens/Garage-Control-Arduino) companion app to monitor garage environment and control the automated garage door.

[Watch it in action!](https://www.youtube.com/watch?v=utPfQMeuSUI)

##Overview
I had only one sensor to check if the garage was closed or not closed. 
Not closed could be completely open, stopped, closing or opening.
My garage has a fixed flow of states.

| State        | Next State When Relay is Switched |
| ------------- |:-------------:|
| Open      | Closing |
| Opening      | Stopped      |
| Stopped | Closing      |
| Closing | Opening      |
| Closed | Opening      |

I measured the time that was needed to open and close completely.
Knowing this I could create an animation in a progressbar that shows the progression between open and close.

Labels are in Dutch. Feel free to fork, add English or any other language and create a merge request.

<img src="https://raw.github.com/piejanssens/piejanssens.github.io/master/IMG_0291.PNG" alt="Screenshot" style="width: 200px;"/>

##Install
Use cocoapods to install the dependency.

!Important! 
Store your BLE Shield UUID in the BLEDefines.h file.
Use an example BLE app from the appstore to check your UUID or check the XCode logs when you run it in debug on the device.
