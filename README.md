# CoBaT
 Corona Bavaria Traffic light

IOS project to use during application phase.

# Overview
The App reads the current RKI data for Covid 19 and stores them locally in a userdefault store on each start and by user request.

There are three granularity levels: Country, State and County.

If the received data are different a new data set is stored. Usually this reflects a new set of daily data. Maximum of 15 of these data sets are stored.

UI is able browse over that datasets. It also shows the regularities for public behavior based on the new Covid-19-Cases of last 7 days per 100,000 inhabitants ("Incidences")

UI is build with UIKit.

# Package content

  - Xcode project
  - playground with initial tests for JSON hgandling of the RKI data interface
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
 - Version 2 will have a timed trigger in Background

Background service
 - manages the background fetch of the RKI Data, uses BGTaskScheduler, introduced with IOS 13

Location service
 - will hold the location service for Version 2

## Data store
Global Storage
 - holds the data structures used in all app parts related to RKI data
 - handles new incoming datasets
 - manage the permanent Storage (simply userDefaults)
 - post messages on several occasions for the UI
 - provides a simple error message handling, by storing the last 20 error messages (non permanent)

 Notification service
  - extents the IOS notification namespace by the names used by this app

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

Help Screen
 - shows the data copyright and disclaimer by RKI
 - shows the stored error messages

 CovitRating
  - provides the unique decision point which incident values needs what color code and what ranking (Traffic lights)

## User Notifications
  - provides a well formatted user notification if a background fetch found new data

## Helpers
  - just some predefined formatters

## Assets.xcassets
  - keeps the images and the definition of the tint color (Bavaria blue)


## Localizable.strings
  - Language support for German and English
