# CoBaT
Corona Basic Traffic light

IOS project to fetch and browse data provided by Rpbert-Koch-Institute (RKI) related to Covid-19 / Corona. 

Data are only valid for Germany.

# Overview
The App reads the current RKI data for Covid 19 and stores them locally in a userdefault store on each start and by user request. It also uses iCloud public container to store new data there.

There are three granularity levels: Country, State and County.

If the received data are different a new data set is stored. Usually this reflects a new set of daily data. Maximum of 22 of these data sets are stored.

UI is able browse over that datasets. It also shows some graphs of that data.

UI is build with UIKit.

# Package content

  - Xcode project
  - playground with initial tests for JSON handling of the RKI data interface
  - Sketch files with the images
  - Powerpoint with UI design and some initial notes
  - this readme.md file


# Main Parts Xcode Project

There are three main parts of the App structure, which also reflects the folder structure of the xCode project
+ Data gathering
+ Data store
+ UI



## Data gathering
RKI data
 - holds the JSON structs to decode the JSON data from RKI
 - reads the RKI JSON data
 - handles the decoding
 - triggered by app start and on request by user in UI
 
Background service
 - manages the background fetch of the RKI Data, uses BGTaskScheduler, introduced with IOS 13

Location service
 - will hold the location service for Version 3

## Data store
Global Storage
 - holds the data structures used in all app parts related to RKI data
 - handles new incoming datasets
 - manage the permanent Storage (simply userDefaults)
 - post messages on several occasions for the UI
 - provides a simple error message handling, by storing the last 20 error messages (non permanent)

iCloud Integration
 - holds the original RKI JSON files and JSON files of the internal datastructures in the default public container
 - like the original RKI data there are seperated tables for federal states and counties / cities
 - RKI only provides data for "Yesterday", so this code implememts a mechanism to provide older data for new users 
     - Each time the app recieves new data, it checks if the new date is already in the container. If not, it adds it as new data or updates the existing data.
     - If the iCloud container holds data which the app does not have, the app loads this data from the iCloud container.
  
## UI
Global UI Data
  - holds the common data elements of the UI
  - some of the elements are store permanently in the userDefaults, to restore last UI status for the user
  - posts some messages to keep the different UI parts in sync

Main Screen
 - Entry point of the UI and main Screen
 - shows an overview of the data of the preselected area (Bavaria, Regensburg on first app start)
 - three different area levels (Country, State and County) are available by a tabBarController
 - based on the Incidences (cases last 7 days per 100,000) of the selected area the obligatory rules are shown
 - provides buttons to show a help Screen, retrieve new data set, select a different area and show details

Browse RKI Data
 - shows some summary data for each selectable item
 - provides per item a button to select this item as selected area or shows details on that item
 - provides a sort button to sort the table alphabetically, be incidents in ascending and descending order

Details RKI data
 - lists all datasets for the selected item
 - each data set holds the data of one days
 - it also shows the differences between each two data sets
 - provides three self sizing graphs for new cases, deaths and incidences, each showing values of last three weeks

Help Screen
 - shows the data copyright and disclaimer by RKI
 - shows the stored error messages

 CovitRating
  - provides the unique decision point which incident values needs what color code and what ranking (Traffic lights)

## User Notifications
 - extents the IOS notification namespace by the names used by this app
 - provides a well formatted user notification if a background fetch found new data

## Helpers
  - just some predefined formatters

## Assets.xcassets
  - keeps the images and the definition of the tint color (Bavaria blue)


## Localizable.strings
  - Language support for German and English
