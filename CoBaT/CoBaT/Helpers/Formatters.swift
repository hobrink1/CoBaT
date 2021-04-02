//
//  Formatters.swift
//
//  Created by Hartwig Hopfenzitz on 27.09.18.
//  Copyright © 2018 Hobrink. All rights reserved.
//

import Foundation
import CoreLocation


// MARK: - DateFormatter
let debugDateFormatter = DateFormatter()
let specialDateFormatter = DateFormatter()
let shortSingleDateFormatter = DateFormatter()
let shortSingleDateFormatterRKI = DateFormatter()
let shortSingleDateFormatterTZ = DateFormatter()
let mediumSingleDateFormatter = DateFormatter()
let longSingleDateFormatter = DateFormatter()
let longSingleDateFormatterTZ = DateFormatter()
let fullSingleDateFormatter = DateFormatter()
let shortSingleTimeFormatter = DateFormatter()
let shortSingleTimeFormatterTZ = DateFormatter()
let shortSingleDateTimeFormatter = DateFormatter()
let shortSingleRelativeDateFormatter = DateFormatter()
let shortSingleRelativeDateTimeFormatter = DateFormatter()
let mediumSingleRelativeDateFormatter = DateFormatter()
let mediumSingleRelativeDateTimeFormatter = DateFormatter()
let mediumMediumSingleRelativeDateTimeFormatter = DateFormatter()
let longSingleRelativeDateTimeFormatter = DateFormatter()
let MediumSingleTimeFormatter = DateFormatter()
let shortSingleDateTimeFormatterTZ = DateFormatter()
let shortIntervalDateTimeFormatter = DateIntervalFormatter()
let shortIntervalDateFormatter = DateIntervalFormatter()
let shortIntervalTimeFormatter = DateIntervalFormatter()

// MARK: - NumberFormatter
let neutralNumberFormatter = NumberFormatter()

let numberNoFractionFormatter = NumberFormatter()
let number1FractionFormatter = NumberFormatter()
let number3FractionFormatter = NumberFormatter()

let numberNoFractionFormatterEN = NumberFormatter()
let numberNoFraction1DigitsFormatter = NumberFormatter()
let numberNoFraction3DigitsFormatter = NumberFormatter()
let numberNoFraction4DigitsFormatter = NumberFormatter()
let number1Fraction3DigitsFormatter = NumberFormatter()
let number1Fraction5DigitsFormatter = NumberFormatter()
let numberNoFraction13DigitsFormatter = NumberFormatter()
let number1Fraction13DigitsFormatter = NumberFormatter()
let number3Fraction13DigitsFormatter = NumberFormatter()
let numberNoFraction15DigitsFormatter = NumberFormatter()

let dateTimeFormatterForSeeScoreCard = DateFormatter()
let dateTimeFormatterForSeeScoreCardEN = DateFormatter()

let dateFormatterLocalizedYearTZ = DateFormatter()
let dateFormatterLocalizedMonthNameTZ = DateFormatter()
let dateFormatterLocalizedWeekdayTZ = DateFormatter()
let dateFormatterLocalizedWeekdayShortTZ = DateFormatter()
let dateFormatterLocalizedNumberOfDayTZ = DateFormatter()

let dateFormatterLocalizedWeekdayShort = DateFormatter()
let dateFormatterLocalizedYear = DateFormatter()
let dateFormatterLocalizedMonthName = DateFormatter()

let RKIDateFormatter = DateFormatter()


// -----------------------------------------------------------------------------------------------------------
// buildAllFormatters()
//
// builds all kinds of formatters, just for performance reasons. Build a formatter object once and than reuse it.

/* date format string rules
 * http://userguide.icu-project.org/formatparse/datetime
 */

/*
 Characters    Example    Description
 Year
 y          2008    Year, no padding
 yy         08    Year, two digits (padding with a zero if necessary)
 yyyy       2008    Year, minimum of four digits (padding with zeros if necessary)

 Quarter
 Q          4    The quarter of the year. Use QQ if you want zero padding.
 QQQ        Q4    Quarter including "Q"
 QQQQ       4th quarter    Quarter spelled out

 Month
 M          12    The numeric month of the year. A single M will use '1' for January.
 MM         12    The numeric month of the year. A double M will use '01' for January.
 MMM        Dec    The shorthand name of the month
 MMMM       December    Full name of the month
 MMMMM       D    Narrow name of the month

 Day
 d          14    The day of the month. A single d will use 1 for January 1st.
 dd         14    The day of the month. A double d will use 01 for January 1st.
 F          3rd Tuesday in December    The day of week in the month
 E          Tues    The day of week in the month
 EEEE       Tuesday    The full name of the day
 EEEEE      T    The narrow day of week

 Hour
 h          4    The 12-hour hour.
 hh         04    The 12-hour hour padding with a zero if there is only 1 digit
 H          16    The 24-hour hour.
 HH         16    The 24-hour hour padding with a zero if there is only 1 digit.
 a          PM    AM / PM for 12-hour time formats

 Minute
 m          35    The minute, with no padding for zeroes.
 mm         35    The minute with zero padding.

 Second
 s          8    The seconds, with no padding for zeroes.
 ss         08    The seconds with zero padding.

 Time Zone
 zzz        CST    The 3 letter name of the time zone. Falls back to GMT-08:00 (hour offset) if the name is not known.
 zzzz       Central Standard Time    The expanded time zone name, falls back to GMT-08:00 (hour offset) if name is not known.
 zzzz       CST-06:00    Time zone with abbreviation and offset
 Z          -0600    RFC 822 GMT format. Can also match a literal Z for Zulu (UTC) time.
 ZZZZZ      -06:00    ISO 8601 time zone format
 */
func buildAllFormatters() {

    /*

     from: http://maniak-dobrii.com/understanding-ios-internationalization/

     I’ve mentioned NSBundle and NSLocale. You may think of them like this:

     NSLocale tells you about user settings without taking into account what your app provides.

     NSBundle looks at your app and tells you which of what your app provides you should use according to user settings.

     So, NSBundle is usually the one to ask for language. Say, there’s a girl Jane, who likes [young, handsome, broke] guys,
     and there is you - [middle-aged, handsome and rich]. So, for sure, you’d better use the way you look and mute about your
     age and wealth to get with her.

     If you talk to Jane’s sister, she’ll tell you about Jane’s priorities in general, that’s NSLocale.
     If you talk to your buddy - he’ll advice you to weight upon something you’re good at among what Jane likes, that’s NSBundle.


     see also: https://developer.apple.com/internationalization/


     */



    let preferredLanguage : String = Bundle.main.preferredLocalizations.first!


    // use of the standard "Short Style" ... attention: the format is localized
    shortSingleDateTimeFormatter.dateStyle = .short
    shortSingleDateTimeFormatter.timeStyle = .short
    //shortSingleDateTimeFormatter.doesRelativeDateFormatting = true
    //shortSingleDateTimeFormatter.locale = Locale(identifier: preferredLanguage)

    
    MediumSingleTimeFormatter.dateStyle = .none
    MediumSingleTimeFormatter.timeStyle = .medium
    //shortMediumSingleDateTimeFormatter.doesRelativeDateFormatting = true
    MediumSingleTimeFormatter.locale = Locale(identifier: preferredLanguage)

    
    shortSingleRelativeDateFormatter.dateStyle = .short
    shortSingleRelativeDateFormatter.timeStyle = .none
    shortSingleRelativeDateFormatter.doesRelativeDateFormatting = true
    //shortSingleRelativeDateFormatter.locale = Locale(identifier: preferredLanguage)
    
    shortSingleRelativeDateTimeFormatter.dateStyle = .short
    shortSingleRelativeDateTimeFormatter.timeStyle = .short
    shortSingleRelativeDateTimeFormatter.doesRelativeDateFormatting = true
    //shortSingleRelativeDateTimeFormatter.locale = Locale(identifier: preferredLanguage)

    mediumSingleRelativeDateFormatter.dateStyle = .medium
    mediumSingleRelativeDateFormatter.timeStyle = .short
    mediumSingleRelativeDateFormatter.doesRelativeDateFormatting = true
    //mediumSingleRelativeDateFormatter.locale = Locale(identifier: preferredLanguage)

    
    mediumSingleRelativeDateTimeFormatter.dateStyle = .medium
    mediumSingleRelativeDateTimeFormatter.timeStyle = .short
    mediumSingleRelativeDateTimeFormatter.doesRelativeDateFormatting = true
    //mediumSingleRelativeDateTimeFormatter.locale = Locale(identifier: preferredLanguage)

    
    mediumMediumSingleRelativeDateTimeFormatter.dateStyle = .medium
    mediumMediumSingleRelativeDateTimeFormatter.timeStyle = .medium
    mediumMediumSingleRelativeDateTimeFormatter.doesRelativeDateFormatting = true
    //mediumSingleRelativeDateTimeFormatter.locale = Locale(identifier: preferredLanguage)

    longSingleRelativeDateTimeFormatter.dateStyle = .full
    longSingleRelativeDateTimeFormatter.timeStyle = .short
    longSingleRelativeDateTimeFormatter.doesRelativeDateFormatting = true
    //longSingleRelativeDateTimeFormatter.locale = Locale(identifier: preferredLanguage)


    // use of the standard "Short Style" ... attention: the format is localized
    shortSingleDateTimeFormatterTZ.dateStyle = .short
    shortSingleDateTimeFormatterTZ.timeStyle = .short
    //shortSingleDateTimeFormatterTZ.doesRelativeDateFormatting = true
    shortSingleDateTimeFormatterTZ.locale = Locale(identifier: preferredLanguage)
    
    // use of the standard "Long Style" ... attention: the format is localized
    longSingleDateFormatter.dateStyle = .long
    longSingleDateFormatter.timeStyle = .none
    longSingleDateFormatter.doesRelativeDateFormatting = true
    longSingleDateFormatter.locale = Locale(identifier: preferredLanguage)


    // use of the standard "Long Style", build for the SeeScoreCard image
    dateTimeFormatterForSeeScoreCard.dateStyle = .long
    dateTimeFormatterForSeeScoreCard.timeStyle = .long
    dateTimeFormatterForSeeScoreCard.locale = Locale(identifier: preferredLanguage)
    dateTimeFormatterForSeeScoreCard.timeZone = TimeZone.current
    dateTimeFormatterForSeeScoreCard.doesRelativeDateFormatting = false

    // use of the standard "Long Style", build for the SeeScoreCard image
    dateTimeFormatterForSeeScoreCardEN.dateStyle = .long
    dateTimeFormatterForSeeScoreCardEN.timeStyle = .long
    dateTimeFormatterForSeeScoreCardEN.locale = Locale(identifier: "en")
    dateTimeFormatterForSeeScoreCardEN.timeZone = TimeZone.current
    dateTimeFormatterForSeeScoreCardEN.doesRelativeDateFormatting = false
    
   // use of the standard "Long Style" ... attention: the format is localized
    fullSingleDateFormatter.dateStyle = .full
    fullSingleDateFormatter.timeStyle = .none
    fullSingleDateFormatter.doesRelativeDateFormatting = true
    fullSingleDateFormatter.locale = Locale(identifier: preferredLanguage)


    // use of the standard "Short Style" ... attention: the format is localized
    shortSingleDateFormatter.dateStyle = .short
    shortSingleDateFormatter.timeStyle = .none
    shortSingleDateFormatter.doesRelativeDateFormatting = true
    shortSingleDateFormatter.locale = Locale(identifier: preferredLanguage)

    // as the RKI sits in Berlin the date has to be for that timeZone,
    // otherwise the day checks might fail (day in LA might be different)
    // the timeZone "Europe/Berlin" also considers the daylight saving adjustments
    // we use the local "de" to get a unique result, no matter what user settings are changed
    shortSingleDateFormatterRKI.dateStyle = .short
    shortSingleDateFormatterRKI.timeStyle = .none
    shortSingleDateFormatterRKI.doesRelativeDateFormatting = false
    shortSingleDateFormatterRKI.timeZone = TimeZone(identifier: "Europe/Berlin")
    shortSingleDateFormatter.locale = Locale(identifier: "de_DE")
    
    
    
    // use of the standard "Short Style" ... attention: the format is localized
    shortSingleDateFormatterTZ.dateStyle = .short
    shortSingleDateFormatterTZ.timeStyle = .none
    shortSingleDateFormatterTZ.doesRelativeDateFormatting = true
    shortSingleDateFormatterTZ.locale = Locale(identifier: preferredLanguage)
    
    mediumSingleDateFormatter.dateStyle = .medium
    mediumSingleDateFormatter.timeStyle = .none
    mediumSingleDateFormatter.doesRelativeDateFormatting = false
    mediumSingleDateFormatter.locale = Locale(identifier: preferredLanguage)
    
    longSingleDateFormatterTZ.dateStyle = .long
    longSingleDateFormatterTZ.timeStyle = .none
    longSingleDateFormatterTZ.doesRelativeDateFormatting = false
    longSingleDateFormatterTZ.locale = Locale(identifier: preferredLanguage)
    
    
    // use of the standard "Short Style" ... attention: the format is localized
    shortSingleTimeFormatter.dateStyle = .none
    shortSingleTimeFormatter.timeStyle = .short
    shortSingleTimeFormatter.locale = Locale(identifier: preferredLanguage)

    // use of the standard "Short Style" ... attention: the format is localized
    shortSingleTimeFormatterTZ.dateStyle = .none
    shortSingleTimeFormatterTZ.timeStyle = .short
    shortSingleTimeFormatterTZ.locale = Locale(identifier: preferredLanguage)
    
    // use of the standard "Short Style" ... attention: the format is localized
    shortIntervalDateTimeFormatter.dateStyle = .short
    shortIntervalDateTimeFormatter.timeStyle = .short
    shortIntervalDateTimeFormatter.locale = Locale(identifier: preferredLanguage)
    
    // use of the standard "Short Style" ... attention: the format is localized
    shortIntervalDateFormatter.dateStyle = .short
    shortIntervalDateFormatter.timeStyle = .none
    //doesRelativeDateFormatting = true
    shortIntervalDateFormatter.locale = Locale(identifier: preferredLanguage)

    // use of the standard "Short Style" ... attention: the format is localized
    shortIntervalTimeFormatter.dateStyle = .none
    shortIntervalTimeFormatter.timeStyle = .short
    shortIntervalTimeFormatter.locale = Locale(identifier: preferredLanguage)

    
    // can be changed by calling functions
    neutralNumberFormatter.numberStyle = .decimal
    neutralNumberFormatter.minimumFractionDigits = 0
    neutralNumberFormatter.maximumFractionDigits = 0
    neutralNumberFormatter.locale = Locale(identifier: preferredLanguage)


    // formatter for decimals with no fraction
    numberNoFractionFormatter.numberStyle = .decimal
    numberNoFractionFormatter.maximumFractionDigits = 0
    numberNoFractionFormatter.locale = Locale(identifier: preferredLanguage)
    
    // formatter for decimals with fraction of 1 digit
    number1FractionFormatter.numberStyle = .decimal
    number1FractionFormatter.maximumFractionDigits = 1
    number1FractionFormatter.minimumFractionDigits = 1
    number1FractionFormatter.locale = Locale(identifier: preferredLanguage)
    
    // formatter for decimals with fraction of 1 digit
    number3FractionFormatter.numberStyle = .decimal
    number3FractionFormatter.maximumFractionDigits = 3
    number3FractionFormatter.minimumFractionDigits = 3
    number3FractionFormatter.locale = Locale(identifier: preferredLanguage)

    
    
    // formatter for decimals with no fraction
    numberNoFractionFormatterEN.numberStyle = .decimal
    numberNoFractionFormatterEN.maximumFractionDigits = 0
    numberNoFractionFormatterEN.locale = Locale(identifier: "en")
    
    // formatter for decimals with no fraction in a 1 digit format
    numberNoFraction1DigitsFormatter.numberStyle = .decimal
    numberNoFraction1DigitsFormatter.paddingCharacter = " "
    numberNoFraction1DigitsFormatter.maximumFractionDigits = 0
    numberNoFraction1DigitsFormatter.formatWidth = 1
    numberNoFraction1DigitsFormatter.locale = Locale(identifier: preferredLanguage)

    // formatter for decimals with no fraction in a 3 digit format
    numberNoFraction3DigitsFormatter.numberStyle = .decimal
    numberNoFraction3DigitsFormatter.paddingCharacter = " "
    numberNoFraction3DigitsFormatter.maximumFractionDigits = 0
    numberNoFraction3DigitsFormatter.formatWidth = 3
    numberNoFraction3DigitsFormatter.locale = Locale(identifier: preferredLanguage)

    // formatter for decimals with no fraction in a 4 digit format
    numberNoFraction4DigitsFormatter.numberStyle = .decimal
    numberNoFraction4DigitsFormatter.paddingCharacter = " "
    numberNoFraction4DigitsFormatter.maximumFractionDigits = 0
    numberNoFraction4DigitsFormatter.formatWidth = 4
    numberNoFraction4DigitsFormatter.locale = Locale(identifier: preferredLanguage)



    // formatter for decimals with no fraction in a 3 digit format
    number1Fraction3DigitsFormatter.numberStyle = .decimal
    number1Fraction3DigitsFormatter.paddingCharacter = " "
    number1Fraction3DigitsFormatter.formatWidth = 3
    number1Fraction3DigitsFormatter.maximumFractionDigits = 1
    number1Fraction3DigitsFormatter.minimumFractionDigits = 1
    number1Fraction3DigitsFormatter.locale = Locale(identifier: preferredLanguage)

    // formatter for decimals with no fraction in a 5 digit format
    number1Fraction5DigitsFormatter.numberStyle = .decimal
    number1Fraction5DigitsFormatter.paddingCharacter = " "
    number1Fraction5DigitsFormatter.formatWidth = 3
    number1Fraction5DigitsFormatter.maximumFractionDigits = 1
    number1Fraction5DigitsFormatter.minimumFractionDigits = 1
    number1Fraction5DigitsFormatter.locale = Locale(identifier: preferredLanguage)


    // formatter for decimals with no fraction in a 15 digit format
    numberNoFraction15DigitsFormatter.numberStyle = .decimal
    numberNoFraction15DigitsFormatter.paddingCharacter = " "
    numberNoFraction15DigitsFormatter.maximumFractionDigits = 0
    numberNoFraction15DigitsFormatter.formatWidth = 15
    numberNoFraction15DigitsFormatter.locale = Locale(identifier: preferredLanguage)

    // Prepare the format of the digits
    numberNoFraction13DigitsFormatter.numberStyle = .decimal
    numberNoFraction13DigitsFormatter.paddingCharacter = " "
    numberNoFraction13DigitsFormatter.formatWidth = 13
    numberNoFraction13DigitsFormatter.maximumFractionDigits = 0
    numberNoFraction13DigitsFormatter.locale = Locale(identifier: preferredLanguage)

    // build the string part for the area, we want to have the given number of fractions
    number1Fraction13DigitsFormatter.numberStyle = .decimal
    number1Fraction13DigitsFormatter.paddingCharacter = " "
    number1Fraction13DigitsFormatter.formatWidth = 13
    number1Fraction13DigitsFormatter.maximumFractionDigits = 1
    number1Fraction13DigitsFormatter.minimumFractionDigits = 1
    number1Fraction13DigitsFormatter.locale = Locale(identifier: preferredLanguage)

    // build the string part for the area, we want to have the given number of fractions
    number3Fraction13DigitsFormatter.numberStyle = .decimal
    number3Fraction13DigitsFormatter.paddingCharacter = " "
    number3Fraction13DigitsFormatter.formatWidth = 13
    number3Fraction13DigitsFormatter.maximumFractionDigits = 3
    number3Fraction13DigitsFormatter.minimumFractionDigits = 3
    number3Fraction13DigitsFormatter.locale = Locale(identifier: preferredLanguage)


    dateFormatterLocalizedYearTZ.setLocalizedDateFormatFromTemplate("yyyy")
    dateFormatterLocalizedMonthNameTZ.setLocalizedDateFormatFromTemplate("MMMM")
    dateFormatterLocalizedWeekdayTZ.setLocalizedDateFormatFromTemplate("EEEE")
    dateFormatterLocalizedWeekdayShortTZ.setLocalizedDateFormatFromTemplate("EE")
    dateFormatterLocalizedNumberOfDayTZ.setLocalizedDateFormatFromTemplate("d")

    dateFormatterLocalizedWeekdayShort.setLocalizedDateFormatFromTemplate("EE")
    dateFormatterLocalizedYear.setLocalizedDateFormatFromTemplate("yyyy")
    dateFormatterLocalizedMonthName.setLocalizedDateFormatFromTemplate("MMMM")
    
    // RKI data uses the date format "25.11.2020, 00:00 Uhr", used to check if day has changed
    RKIDateFormatter.dateFormat = "dd.MM.yyyy', 'HH:mm' Uhr'"
    RKIDateFormatter.locale = Locale(identifier: "de")
    
//    dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
//    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
//    let date = dateFormatter.date(from:isoDate)!
    //        let dateFormatter = DateFormatter()
    //        let date = Date(timeIntervalSinceReferenceDate: 410220000)
    //
    //        // US English Locale (en_US)
    //        dateFormatter.locale = Locale(identifier: "en_US")
    //        dateFormatter.setLocalizedDateFormatFromTemplate("xd") // set template after setting locale
    //        print(dateFormatter.string(from: date)) // December 31
    //
    //        // British English Locale (en_GB)
    //        dateFormatter.locale = Locale(identifier: "en_GB")
    //        dateFormatter.setLocalizedDateFormatFromTemplate("MMMMd") // // set template after setting locale
    //        print(dateFormatter.string(from: date)) // 31 December
    //



    
}


/**
 -----------------------------------------------------------------------------------------------
 
 build a formatted string of the number with the correct sign (+, ±, -)
 
 -----------------------------------------------------------------------------------------------
 
 - Parameters:
    - number: the integer number to convert into a string
 
 - Returns: the string
 
 */
func getFormattedDeltaTextInt(number: Int) -> String {
    
    var returnString: String = ""
    
    if let valueString = numberNoFractionFormatter.string(from: NSNumber(value: number)) {
        
        if number > 0 {
            returnString = "+"
        } else if number == 0 {
            returnString = "±"
        }
        
        returnString += valueString
        
    } else {
        
        returnString = ""
    }
    
    return returnString
}


/**
 -----------------------------------------------------------------------------------------------
 
 build a formatted string of the number with the correct sign (+, ±, -)
 
 -----------------------------------------------------------------------------------------------
 
 - Parameters:
    - number: the double number to convert into a string
 
 - Returns: the string
 
 */
func getFormattedDeltaTextDouble(number: Double, fraction: Int) -> String {
    
    var returnString: String = ""
    
    neutralNumberFormatter.minimumFractionDigits = fraction
    neutralNumberFormatter.maximumFractionDigits = fraction
    
    let roundBorder = 0.5 / pow( 10.0, Double(fraction) )
    
    if let valueString = neutralNumberFormatter.string(from: NSNumber(value: number)) {
        
        if number > roundBorder {
            
            returnString = "+"
            
        } else if (number >= 0) && (number < roundBorder) {
            
            returnString = "±"
        }
        
        returnString += valueString
        
    } else {
        
        returnString = ""
    }
    
    return returnString
}


// -----------------------------------------
// returns a formatted position in the form "xxx° xx' xx,xx" N / xx° xx' xx,xx" W"
func stringForLocation2D(_ location:CLLocationCoordinate2D, longVersion: Bool) -> String {

    // variables to store and build up the strings
    var resultStringLatitude = ""
    var resultStringLongitude = ""

    // bild the spacer (different for long and short version)
    var spacer = ""
    if longVersion == true {
        spacer = " "
    }

    // Get the degrees
    let degreeLatitude = fabs(trunc(location.latitude))
    let degreeLongitude = fabs(trunc(location.longitude))

    // the rest will be used for Minutes and Seconds, and only the absolute values are used
    let minutesAndSecondsLatitude = fabs(location.latitude) - degreeLatitude
    let minutesAndSecondsLongitude = fabs(location.longitude) - degreeLongitude

    // calculate the minutes
    let minutesLatitude = trunc(minutesAndSecondsLatitude * 60.0)
    let minutesLongitude = trunc(minutesAndSecondsLongitude * 60.0)

    // the rest are the seconds
    let secondsLatitude = (minutesAndSecondsLatitude - (minutesLatitude / 60.0)) * 3_600.0
    let secondsLongitude = (minutesAndSecondsLongitude - (minutesLongitude / 60.0)) * 3_600.0

    //formatter.formatWidth = 2
    //    formatter.formatWidth = 1
    resultStringLatitude = numberNoFraction1DigitsFormatter.string(from: degreeLatitude as NSNumber)! + "°" + spacer

    //formatter.formatWidth = 3
    //    formatter.formatWidth = 1
    resultStringLongitude = numberNoFraction1DigitsFormatter.string(from: degreeLongitude as NSNumber)! + "°" + spacer

    //formatter.formatWidth = 2
    //    formatter.formatWidth = 1
    resultStringLatitude += numberNoFraction1DigitsFormatter.string(from: minutesLatitude as NSNumber)! + "'" + spacer
    resultStringLongitude += numberNoFraction1DigitsFormatter.string(from: minutesLongitude as NSNumber)! + "'" + spacer

    //        formatter.maximumFractionDigits = 1
    //        formatter.minimumFractionDigits = 1
    //        formatter.formatWidth = 3

    resultStringLatitude += numberNoFraction1DigitsFormatter.string(from: secondsLatitude as NSNumber)! + "\""
    resultStringLongitude += numberNoFraction1DigitsFormatter.string(from: secondsLongitude as NSNumber)! + "\""


    let north = NSLocalizedString("north one letter", comment: "One Letter Abbreviation for direction North")
    let east = NSLocalizedString("east one letter", comment: "One Letter Abbreviation for direction east")
    let south = NSLocalizedString("south one letter", comment: "One Letter Abbreviation for direction south")
    let west = NSLocalizedString("west one letter", comment: "One Letter Abbreviation for direction west")

    // last decitions: were (North / South and West / East)
    if longVersion == true {
        if location.latitude > 0 {
            resultStringLatitude += " " + north + " /  " + resultStringLongitude
        } else {
            resultStringLatitude += " " + south + " /  " + resultStringLongitude
        }

        if location.longitude > 0 {
            resultStringLatitude += " " + east
        } else {
            resultStringLatitude += " " + west
        }
    } else {
        if location.latitude > 0 {
            resultStringLatitude += " " + north + " / " + resultStringLongitude
        } else {
            resultStringLatitude += " " + south + " / " + resultStringLongitude
        }

        if location.longitude > 0 {
            resultStringLatitude += " " + east
        } else {
            resultStringLatitude += " " + west
        }
    }

    // return the string
    return resultStringLatitude

}

