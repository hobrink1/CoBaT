//
//  DetailsRKIGraphic.swift
//  CoBaT
//
//  Created by Hartwig Hopfenzitz on 14.12.20.
//

import Foundation
import UIKit


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Details RKI Graphic
// -------------------------------------------------------------------------------------------------


// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Queues
// -------------------------------------------------------------------------------------------------

// we use a queue to manage the async production of graphs. This provides us from data races. The queue is concurrent,
// so many can read at the same time, but only one can write
let RKIGraphicQueue : DispatchQueue = DispatchQueue(
    label: "org.hobrink.CoBaT.RKIGraphicQueue",
    qos: .userInitiated, attributes: .concurrent)



// -------------------------------------------------------------------------------------------------
// MARK: -
// MARK: - Class
// -------------------------------------------------------------------------------------------------
final class DetailsRKIGraphic: NSObject {
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Singleton
    // ---------------------------------------------------------------------------------------------
    static let unique = DetailsRKIGraphic()
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Class Properties
    // ---------------------------------------------------------------------------------------------
    private let ScreenScale: CGFloat = UIScreen.main.scale
    private let graphBackgroundUIColor: UIColor = UIColor.tertiarySystemBackground
    private let graphBackgroundCGColor: CGColor = UIColor.tertiarySystemBackground.cgColor
    private let graphLabelUIColor: UIColor = UIColor.label
    private let graphLabelCGColor: CGColor = UIColor.label.cgColor
    private let graphAxisUIColor: UIColor = UIColor.tertiaryLabel
    private let graphAxisCGColor: CGColor = UIColor.tertiaryLabel.cgColor
    private let graphBarNormalUIColor: UIColor = UIColor.systemGray
    private let graphBarNormalCGColor: CGColor = UIColor.systemGray.cgColor
    private let graphBarHighlightedUIColor: UIColor = UIColor.systemOrange
    private let graphBarHighlightedCGColor: CGColor = UIColor.systemOrange.cgColor

    private var topBorder:      CGFloat = 1.0
    private var bottomBorder:   CGFloat = 1.0
    private var leftBorder:     CGFloat = 1.0
    private var rightBorder:    CGFloat = 93.0
    private var widthAxis:      CGFloat = 2.0
    private var yAxisY:         CGFloat = 80.0
    private var lengthYAxis:    CGFloat = 79.0
    private var labelY:         CGFloat = 81.0
    private var messageY:       CGFloat = 40.0
    private var barWidth:       CGFloat = 5.0
    private var barGap:         CGFloat = 1.0

    // the oberserver to recognize that a new set of graphs have to be produced
    var newDetailsSelectedObserver: NSObjectProtocol?
    var newRKIDataReadyObserver: NSObjectProtocol?

    
    // ---------------------------------------------------------------------------------------------
    // MARK: - API
    // ---------------------------------------------------------------------------------------------

    // this set is the current set of graphs on screen
    public var GraphLeft: UIImage = UIImage(named: "5To4TestImage")!
    public var GraphMiddle: UIImage = UIImage(named: "5To4TestImage")!
    public var GraphRight: UIImage = UIImage(named: "5To4TestImage")!

    // thus is the pre calculated initial state.. all done except data
    public var GraphLeftInitial: UIImage = UIImage(named: "5To4TestImage")!
    public var GraphMiddleInitial: UIImage = UIImage(named: "5To4TestImage")!
    public var GraphRightInitial: UIImage = UIImage(named: "5To4TestImage")!

    // this is the pre calculated set of graphs showing the localzied string "Soon"
    public var GraphLeftWait: UIImage = UIImage(named: "5To4TestImage")!
    public var GraphMiddleWait: UIImage = UIImage(named: "5To4TestImage")!
    public var GraphRightWait: UIImage = UIImage(named: "5To4TestImage")!
  
    // this is the pre calculated set of graphs showing the localzied string "NoData"
    public var GraphLeftNoData: UIImage = UIImage(named: "5To4TestImage")!
    public var GraphMiddleNoData: UIImage = UIImage(named: "5To4TestImage")!
    public var GraphRightNoData: UIImage = UIImage(named: "5To4TestImage")!
  

    
    /**
     -----------------------------------------------------------------------------------------------
     
     startGraphicSystem()
     
     -----------------------------------------------------------------------------------------------
     */
    public func startGraphicSystem() {
        
        #if DEBUG_PRINT_FUNCCALLS
        print("DetailsRKIGraphic.startGraphicSystem() just started, call createAllNewGraphs()")
        #endif
        
        self.setAllParameters()
        
        self.createAllNewGraphs()
        
        RKIGraphicQueue.async(flags:.barrier, execute: {
            self.GraphLeft = self.GraphLeftWait
            self.GraphMiddle = self.GraphMiddleWait
            self.GraphRight = self.GraphRightWait
        })
        
        
        newDetailsSelectedObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_Graph_NewDetailSelected,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in

                #if DEBUG_PRINT_FUNCCALLS
                print("DetailsRKIGraphic.startGraphicSystem() just recieved signal .CoBaT_Graph_NewDetailSelected, call createNewSetOfGraphs()")
                #endif

                self.createNewSetOfGraphs()
            })

        newRKIDataReadyObserver = NotificationCenter.default.addObserver(
            forName: .CoBaT_NewRKIDataReady,
            object: nil,
            queue: OperationQueue.main,
            using: { Notification in

                #if DEBUG_PRINT_FUNCCALLS
                print("DetailsRKIGraphic.startGraphicSystem() just recieved signal .CoBaT_NewRKIDataReady, call createNewSetOfGraphs()")
                #endif

                self.createNewSetOfGraphs()
            })


        
        self.createNewSetOfGraphs()
        

        
    }
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Life cycle
    // ---------------------------------------------------------------------------------------------

    deinit {

        if let observer = newDetailsSelectedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = newRKIDataReadyObserver {
            NotificationCenter.default.removeObserver(observer)
        }

    }
    
    // ---------------------------------------------------------------------------------------------
    // MARK: - Drawing Helpers
    // ---------------------------------------------------------------------------------------------
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func createAllNewGraphs() {
        
        let noDataTranslated = NSLocalizedString("updateLabels-no-index",
                                                 comment: "Label text that we did not found valid data")
        
        let soonTranslated = NSLocalizedString("willShowSoon",
                                                 comment: "Label text that we are working on it")

        
        // the new image for the left graph
        if let newImage = getNewBlankImage() {
            
            // add the label
            if let newImageLabled = textToImage(
                text: NSLocalizedString("RKIGraph-Cases",
                                        comment: "Label text for graph \"new cases\""),
                image: newImage,
                atPoint: CGPoint(x: 0,
                                 y: self.labelY)) {
                
                RKIGraphicQueue.async(flags: .barrier, execute: {
                    self.GraphLeftInitial = newImageLabled
                })
                
                // paint the Wait image
                if let waitImage = self.textToImage(
                    text: soonTranslated,
                    image: newImageLabled,
                    atPoint: CGPoint(x: 0,
                                     y: self.messageY)) {
                
                    RKIGraphicQueue.async(flags: .barrier, execute: {
                        self.GraphLeftWait = waitImage
                    })
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "DetailsRKIGraphic.createAllNewGraphs().leftImageWait textToImage() returned nil")
                }
                
                // paint the NoData image
                if let noDataImage = self.textToImage(
                    text: noDataTranslated,
                    image: newImageLabled,
                    atPoint: CGPoint(x: 0,
                                     y: self.messageY)) {
                
                    RKIGraphicQueue.async(flags: .barrier, execute: {
                        self.GraphLeftNoData = noDataImage
                    })
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "DetailsRKIGraphic.createAllNewGraphs().leftImageNoData textToImage() returned nil")
                }
                
          } else {
                
                GlobalStorage.unique.storeLastError(
                    errorText: "DetailsRKIGraphic.createAllNewGraphs().leftImage textToImage() returned nil")
            }
            
        } else {
            
            GlobalStorage.unique.storeLastError(
                errorText: "DetailsRKIGraphic.createAllNewGraphs().leftImage getNewBlankImage() returned nil")
        }
        
        
        // the new image for the middle graph
        if let newImage = getNewBlankImage() {
            
            // add the label
            if let newImageLabled = textToImage(
                text: NSLocalizedString("RKIGraph-Deaths",
                                        comment: "Label text for graph \"new deaths\""),
                image: newImage,
                atPoint: CGPoint(x: 0,
                                 y: self.labelY)) {
                
                RKIGraphicQueue.async(flags: .barrier, execute: {
                    self.GraphMiddleInitial = newImageLabled
                })
                
                // paint the Wait image
                if let waitImage = self.textToImage(
                    text: soonTranslated,
                    image: newImageLabled,
                    atPoint: CGPoint(x: 0,
                                     y: self.messageY)) {
                
                    RKIGraphicQueue.async(flags: .barrier, execute: {
                        self.GraphMiddleWait = waitImage
                    })
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "DetailsRKIGraphic.createAllNewGraphs().middleImageWait textToImage() returned nil")
                }
                
                // paint the NoData image
                if let noDataImage = self.textToImage(
                    text: noDataTranslated,
                    image: newImageLabled,
                    atPoint: CGPoint(x: 0,
                                     y: self.messageY)) {
                
                    RKIGraphicQueue.async(flags: .barrier, execute: {
                        self.GraphMiddleNoData = noDataImage
                    })
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "DetailsRKIGraphic.createAllNewGraphs().midleImageNoData textToImage() returned nil")
                }

            } else {
                
                GlobalStorage.unique.storeLastError(
                    errorText: "DetailsRKIGraphic.createAllNewGraphs().middleImage textToImage() returned nil")
            }
            
        } else {
            
            GlobalStorage.unique.storeLastError(
                errorText: "DetailsRKIGraphic.createAllNewGraphs().middleImage getNewBlankImage() returned nil")
        }
        
        // the new image for the right graph
        if let newImage = getNewBlankImage() {

            // add the label
            if let newImageLabled = textToImage(
                text: NSLocalizedString("RKIGraph-Incidences",
                                        comment: "Label text for graph \"incidencess\""),
                image: newImage,
                atPoint: CGPoint(x: 0,
                                 y: self.labelY)) {
                
                RKIGraphicQueue.async(flags: .barrier, execute: {
                    self.GraphRightInitial = newImageLabled
                })
                
                // paint the Wait image
                if let waitImage = self.textToImage(
                    text: soonTranslated,
                    image: newImageLabled,
                    atPoint: CGPoint(x: 0,
                                     y: self.messageY)) {
                
                    RKIGraphicQueue.async(flags: .barrier, execute: {
                        self.GraphRightWait = waitImage
                    })
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "DetailsRKIGraphic.createAllNewGraphs().rightImageWait textToImage() returned nil")
                }
                
                // paint the NoData image
                if let noDataImage = self.textToImage(
                    text: "NoData",
                    image: newImageLabled,
                    atPoint: CGPoint(x: 0,
                                     y: self.messageY)) {
                
                    RKIGraphicQueue.async(flags: .barrier, execute: {
                        self.GraphRightNoData = noDataImage
                    })
                    
                } else {
                    
                    GlobalStorage.unique.storeLastError(
                        errorText: "DetailsRKIGraphic.createAllNewGraphs().rightImageNoData textToImage() returned nil")
                }

            } else {
                
                GlobalStorage.unique.storeLastError(
                    errorText: "DetailsRKIGraphic.createAllNewGraphs().rightImage textToImage() returned nil")
            }
            
        } else {
            
            GlobalStorage.unique.storeLastError(
                errorText: "DetailsRKIGraphic.createAllNewGraphs().rightImage getNewBlankImage() returned nil")
        }

    }
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     Creates a new set of the graphs used for the three images in the detail cell with graphs
     
     -----------------------------------------------------------------------------------------------
    */
    private func createNewSetOfGraphs() {
        
        // first check if we have a valid ID we can use
        if GlobalUIData.unique.UIDetailsRKISelectedMyID != "" {
            
            // yes, it's a valid ID so try to create the graph for cases
            let newLeftGraph = createCasesGraph()
            
            // check if it worked
            if newLeftGraph == nil {
                
                // no it did not, so file the error
                GlobalStorage.unique.storeLastError(
                    errorText: "DetailsRKIGraphic.createNewSetOfGraphs().leftImage createCasesGraph() returned nil")
            }
            
            let newMiddleGraph = createDeathsGraph()
            
            // check if it worked
            if newMiddleGraph == nil {
                
                // no it did not, so file the errormiddleImage
                GlobalStorage.unique.storeLastError(
                    errorText: "DetailsRKIGraphic.createNewSetOfGraphs().middleImage createCasesGraph() returned nil")
            }
 
            
            let newRightGraph = createIncidencesGraph()
            
            // check if it worked
            if newRightGraph == nil {
                
                // no it did not, so file the errormiddleImage
                GlobalStorage.unique.storeLastError(
                    errorText: "DetailsRKIGraphic.createNewSetOfGraphs().rightImage createIncidencesGraph() returned nil")
            }
             
            // store the newly created images and post the event
            RKIGraphicQueue.async(flags: .barrier, execute: {
                
                self.GraphLeft = newLeftGraph ?? self.GraphLeftNoData
                self.GraphMiddle = newMiddleGraph ?? self.GraphMiddleNoData
                self.GraphRight = newRightGraph ?? self.GraphRightNoData
                
                // report that we have selected a new detail
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(Notification(name: .CoBaT_Graph_NewGraphAvailable))
                })
            })
            
        } else {
                  
            // UIDetailsRKISelectedMyID == ""
            RKIGraphicQueue.async(flags: .barrier, execute: {
                
                self.GraphLeft = self.GraphLeftNoData
                self.GraphMiddle = self.GraphMiddleNoData
                self.GraphRight = self.GraphRightNoData
                
                GlobalStorage.unique.storeLastError(
                    errorText: "DetailsRKIGraphic.createNewSetOfGraphs().UIDetailsRKISelectedMyID == \"\", post .CoBaT_Graph_NewGraphAvailable anyway, with NoData graphs")
                
                // report that we have selected a new detail
                NotificationCenter.default.post(Notification(name: .CoBaT_Graph_NewGraphAvailable))
            })
        }
    }
    
    /**
     -----------------------------------------------------------------------------------------------
     
     creates the left image with the new cases
     
     -----------------------------------------------------------------------------------------------

     - Returns: the new Image or nil if an error happens
     
     */
    private func createCasesGraph() -> UIImage? {
        
        // get and freeze the global data
        var selectedID: String!
        var selectedArea: Int!
        var selectedData: [[GlobalStorage.RKIDataStruct]]!
        var selectedWeekdays: [Int]!
        
        GlobalStorageQueue.sync(execute: {
            selectedID = GlobalUIData.unique.UIDetailsRKISelectedMyID
            selectedArea = GlobalUIData.unique.UIDetailsRKIAreaLevel
            selectedData = GlobalStorage.unique.RKIData[selectedArea]
            selectedWeekdays = GlobalStorage.unique.RKIDataWeekdays[selectedArea]
        })
        
        // check if there is work to do
        if selectedData.isEmpty == true {
            
            // nothing to do, return nil
            #if DEBUG_PRINT_FUNCCALLS
            print("createCasesGraph(), RKIData[\(selectedArea!)] is empty, return nil")
            #endif
            
            return nil
        }
        
        // try to calculate the index of the selected ID
        var selectedIDIndex: Int = 0
        if let foundIndex = selectedData[0].firstIndex(where: { $0.myID == selectedID } ) {
            
            selectedIDIndex = foundIndex
            
        } else {
            
            // did not found the index, return nil
            #if DEBUG_PRINT_FUNCCALLS
            print("createCasesGraph(), RKIData[\(selectedArea!)] could not find ID \(selectedID!), return nil")
            #endif
            
            return nil
        }
        
        // OK, now we have the data, so produce an easier to handle array with the values we need
        // calculate the number of days we have to do
        // make sure we do not have too much values (there is only room for 15 bars)
        let numberOfDays: Int = min(16, selectedData.count)
        
        // this will be the values we want to draw
        var valuesToDraw: [Int] = []
        
        // if we only have one day ...
        if numberOfDays == 1 {
            
            // ... we just draw the current value
            valuesToDraw.append(selectedData[0][selectedIDIndex].cases)
            
        } else {
            
            //... otherwise the diff to the day before
            
            // so walk over the data and calculate the diff values
            for index in 0 ..< numberOfDays - 1 {
                
                // calculate the delta
                let delta = selectedData[index][selectedIDIndex].cases
                    - selectedData[index + 1][selectedIDIndex].cases
                
                // and append
                valuesToDraw.append(delta)
            }
        }
        
        // shortcut for the image we use as background
        //let imageToUse: UIImage = self.GraphLeftInitial
        let imageToUse: UIImage = RKIGraphicQueue.sync(execute: { self.GraphLeftInitial })
        
        // this will hold the return image or nil
        let returnImage: UIImage?
        
        
        // shortcut for the dimensions of the image
        let newImageWidth: CGFloat = GlobalUIData.unique.RKIGraphNeededWidth
        let newImageHeight: CGFloat = GlobalUIData.unique.RKIGraphNeededHeight
        let rectOfImage: CGRect = CGRect(x: 0, y: 0, width: newImageWidth, height: newImageHeight)
        
        // get the max value with some headroom for a better look
        let maxValue: CGFloat = (CGFloat(valuesToDraw.max()!) * 1.05)
        
        // this is the value we use to calulate the height of the bar (negative, because of the draw direction)
        let valuePerUnit: CGFloat = CGFloat(self.lengthYAxis / CGFloat(maxValue)) * -1.0
        
        // get the day of the week for reference (all bars with this weekday will be drawnd diffenrently)
        let weekDayReference: Int = selectedWeekdays.first!
        
        
        // the initial canvas
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newImageWidth, height: newImageHeight),
                                               false,
                                               ScreenScale)
        
        // get the current context (our canvas)
        if let context = UIGraphicsGetCurrentContext() {
            
            // ----- get the background image
            
            // we have to flip the canvas, to make sure the image is not upside down etc.
            //flip coordinats
            context.translateBy(x: 0, y: newImageHeight)
            context.scaleBy(x: 1.0, y: -1.0)
            
            //draw image
            context.draw(imageToUse.cgImage!, in: rectOfImage)
            
            //flip back
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0, y: (newImageHeight * -1.0))
            
            // start the drawing (we just set the background)
            context.beginPath()
            
            
            // ----- draw the axis
            
            // prepare drawing of axises
            context.setLineWidth(self.widthAxis)
            context.setStrokeColor(graphAxisCGColor)
            
            // draw the y-axis
            context.move(to: CGPoint(x: self.leftBorder, y: self.topBorder))
            context.addLine(to: CGPoint(x: self.leftBorder, y: self.yAxisY))
            
            // draw the x-axis
            context.move(to: CGPoint(x: self.leftBorder, y: self.yAxisY))
            context.addLine(to: CGPoint(x: self.rightBorder, y: self.yAxisY))
            
            // draw the axis
            context.drawPath(using: .stroke)
            
            
            
            // ----- draw the bars
            
            // we will try to draw the bars in different colors, so save the state
            context.saveGState()
            
            // prepare the drawing
            var nextStartOfBar = CGPoint(
                x: self.rightBorder - self.barWidth - self.barGap,
                y: self.yAxisY)
            
            // set the color for the normal bars
            context.setFillColor(graphBarNormalCGColor)
            
            // walk over the values
            for index in 0 ..< (valuesToDraw.count) {
                
                // shortcuts for the values we need
                let currentValue = CGFloat(valuesToDraw[index])
                let currentWeekday = selectedWeekdays[index]
                
                // start the path
                context.beginPath()
                
                // move to the start point
                context.move(to: nextStartOfBar)
                
                // add the bar
                context.addRect(CGRect(x: nextStartOfBar.x,
                                       y: nextStartOfBar.y,
                                       width: self.barWidth,
                                       height: currentValue * valuePerUnit))
                
                // chack if that bar is on the same weekday as the reference
                if currentWeekday == weekDayReference {
                    
                    // yes, so highlight the bar with a different color
                    
                    // as we change the color we have to push sthe state
                    context.saveGState()
                    
                    // change the color
                    context.setFillColor(graphBarHighlightedCGColor)
                    
                    // draw the bar
                    context.drawPath(using: .fill)
                    
                    // restore the state
                    context.restoreGState()
                    
                } else {
                    
                    // normal bar, so just draw it
                    context.drawPath(using: .fill)
                }
                
                // set the next startpoint
                nextStartOfBar = CGPoint(
                    x: nextStartOfBar.x - self.barWidth - self.barGap,
                    y: nextStartOfBar.y)
            }
            
            
            // ----- close it
            
            // restore the state to have it balanced
            context.restoreGState()
            
            // OK, that's it, we take this as the new image
            returnImage = UIGraphicsGetImageFromCurrentImageContext()
            
        } else {
            
            // couln't get the context, return nil
            returnImage = nil
        }
        
        // OK, we now have a nice new image, store it
        UIGraphicsEndImageContext()
        
        
        return returnImage
        
    }

    
    /**
     -----------------------------------------------------------------------------------------------
     
     creates the left image with the new deaths
     
     -----------------------------------------------------------------------------------------------

     - Returns: the new Image or nil if an error happens
     
     */
    private func createDeathsGraph() -> UIImage? {
        
        // get and freeze the global data
        var selectedID: String!
        var selectedArea: Int!
        var selectedData: [[GlobalStorage.RKIDataStruct]]!
        var selectedWeekdays: [Int]!
        
        GlobalStorageQueue.sync(execute: {
            selectedID = GlobalUIData.unique.UIDetailsRKISelectedMyID
            selectedArea = GlobalUIData.unique.UIDetailsRKIAreaLevel
            selectedData = GlobalStorage.unique.RKIData[selectedArea]
            selectedWeekdays = GlobalStorage.unique.RKIDataWeekdays[selectedArea]
        })
        
        // check if there is work to do
        if selectedData.isEmpty == true {
            
            // nothing to do, return nil
            #if DEBUG_PRINT_FUNCCALLS
            print("createCasesGraph(), RKIData[\(selectedArea!)] is empty, return nil")
            #endif
            
            return nil
        }
        
        // try to calculate the index of the selected ID
        var selectedIDIndex: Int = 0
        if let foundIndex = selectedData[0].firstIndex(where: { $0.myID == selectedID } ) {
            
            selectedIDIndex = foundIndex
            
        } else {
            
            // did not found the index, return nil
            #if DEBUG_PRINT_FUNCCALLS
            print("createCasesGraph(), RKIData[\(selectedArea!)] could not find ID \(selectedID!), return nil")
            #endif
            
            return nil
        }
        
        // OK, now we have the data, so produce an easier to handle array with the values we need
        // calculate the number of days we have to do
        // make sure we do not have too much values (there is only room for 15 bars)
        let numberOfDays: Int = min(16, selectedData.count)
        
        // this will be the values we want to draw
        var valuesToDraw: [Int] = []
        
        // if we only have one day ...
        if numberOfDays == 1 {
            
            // ... we just draw the current value
            valuesToDraw.append(selectedData[0][selectedIDIndex].deaths)
            
        } else {
            
            //... otherwise the diff to the day before
            
            // so walk over the data and calculate the diff values
            for index in 0 ..< numberOfDays - 1 {
                
                // calculate the delta
                let delta = selectedData[index][selectedIDIndex].deaths
                    - selectedData[index + 1][selectedIDIndex].deaths
                
                // and append
                valuesToDraw.append(delta)
            }
        }
        
        // shortcut for the image we use as background
        //let imageToUse: UIImage = self.GraphMiddleInitial
        let imageToUse: UIImage = RKIGraphicQueue.sync(execute: { self.GraphMiddleInitial })

        // this will hold the return image or nil
        let returnImage: UIImage?
        
        
        // shortcut for the dimensions of the image
        let newImageWidth: CGFloat = GlobalUIData.unique.RKIGraphNeededWidth
        let newImageHeight: CGFloat = GlobalUIData.unique.RKIGraphNeededHeight
        let rectOfImage: CGRect = CGRect(x: 0, y: 0, width: newImageWidth, height: newImageHeight)
        
        // get the max value with some headroom for a better look
        let maxValue: CGFloat = (CGFloat(valuesToDraw.max()!) * 1.05)
        
        // this is the value we use to calulate the height of the bar (negative, because of the draw direction)
        let valuePerUnit: CGFloat = CGFloat(self.lengthYAxis / CGFloat(maxValue)) * -1.0
        
        // get the day of the week for reference (all bars with this weekday will be drawnd diffenrently)
        let weekDayReference: Int = selectedWeekdays.first!
        
        
        // the initial canvas
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newImageWidth, height: newImageHeight),
                                               false,
                                               ScreenScale)
        
        // get the current context (our canvas)
        if let context = UIGraphicsGetCurrentContext() {
            
            // ----- get the background image
            
            // we have to flip the canvas, to make sure the image is not upside down etc.
            //flip coordinats
            context.translateBy(x: 0, y: newImageHeight)
            context.scaleBy(x: 1.0, y: -1.0)
            
            //draw image
            context.draw(imageToUse.cgImage!, in: rectOfImage)
            
            //flip back
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0, y: (newImageHeight * -1.0))
            
            // start the drawing (we just set the background)
            context.beginPath()
            
            
            // ----- draw the axis
            
            // prepare drawing of axises
            context.setLineWidth(self.widthAxis)
            context.setStrokeColor(graphAxisCGColor)
            
            // draw the y-axis
            context.move(to: CGPoint(x: self.leftBorder, y: self.topBorder))
            context.addLine(to: CGPoint(x: self.leftBorder, y: self.yAxisY))
            
            // draw the x-axis
            context.move(to: CGPoint(x: self.leftBorder, y: self.yAxisY))
            context.addLine(to: CGPoint(x: self.rightBorder, y: self.yAxisY))
            
            // draw the axis
            context.drawPath(using: .stroke)
            
            
            
            // ----- draw the bars
            
            // we will try to draw the bars in different colors, so save the state
            context.saveGState()
            
            // prepare the drawing
            var nextStartOfBar = CGPoint(
                x: self.rightBorder - self.barWidth - self.barGap,
                y: self.yAxisY)
            
            // set the color for the normal bars
            context.setFillColor(graphBarNormalCGColor)
            
            // walk over the values
            for index in 0 ..< (valuesToDraw.count) {
                
                // shortcuts for the values we need
                let currentValue = CGFloat(valuesToDraw[index])
                let currentWeekday = selectedWeekdays[index]
                
                // start the path
                context.beginPath()
                
                // move to the start point
                context.move(to: nextStartOfBar)
                
                // add the bar
                context.addRect(CGRect(x: nextStartOfBar.x,
                                       y: nextStartOfBar.y,
                                       width: self.barWidth,
                                       height: currentValue * valuePerUnit))
                
                // chack if that bar is on the same weekday as the reference
                if currentWeekday == weekDayReference {
                    
                    // yes, so highlight the bar with a different color
                    
                    // as we change the color we have to push sthe state
                    context.saveGState()
                    
                    // change the color
                    context.setFillColor(graphBarHighlightedCGColor)
                    
                    // draw the bar
                    context.drawPath(using: .fill)
                    
                    // restore the state
                    context.restoreGState()
                    
                } else {
                    
                    // normal bar, so just draw it
                    context.drawPath(using: .fill)
                }
                
                // set the next startpoint
                nextStartOfBar = CGPoint(
                    x: nextStartOfBar.x - self.barWidth - self.barGap,
                    y: nextStartOfBar.y)
            }
            
            
            // ----- close it
            
            // restore the state to have it balanced
            context.restoreGState()
            
            // OK, that's it, we take this as the new image
            returnImage = UIGraphicsGetImageFromCurrentImageContext()
            
        } else {
            
            // couln't get the context, return nil
            returnImage = nil
        }
        
        // OK, we now have a nice new image, store it
        UIGraphicsEndImageContext()
        
        
        return returnImage
        
    }

    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     creates the left image with the incidences
     
     -----------------------------------------------------------------------------------------------

     - Returns: the new Image or nil if an error happens
     
     */
    private func createIncidencesGraph() -> UIImage? {
        
        // get and freeze the global data
        var selectedID: String!
        var selectedArea: Int!
        var selectedData: [[GlobalStorage.RKIDataStruct]]!
        //var selectedWeekdays: [Int]!
        var newImageWidth: CGFloat!
        var newImageHeight: CGFloat!
        
        GlobalStorageQueue.sync(execute: {
            selectedID = GlobalUIData.unique.UIDetailsRKISelectedMyID
            selectedArea = GlobalUIData.unique.UIDetailsRKIAreaLevel
            selectedData = GlobalStorage.unique.RKIData[selectedArea]
            //selectedWeekdays = GlobalStorage.unique.RKIDataWeekdays[selectedArea]

            newImageWidth = GlobalUIData.unique.RKIGraphNeededWidth
            newImageHeight = GlobalUIData.unique.RKIGraphNeededHeight
        })
        
        // check if there is work to do
        if selectedData.isEmpty == true {
            
            // nothing to do, return nil
            #if DEBUG_PRINT_FUNCCALLS
            print("createCasesGraph(), RKIData[\(selectedArea!)] is empty, return nil")
            #endif
            
            return nil
        }
        
        // try to calculate the index of the selected ID
        var selectedIDIndex: Int = 0
        if let foundIndex = selectedData[0].firstIndex(where: { $0.myID == selectedID } ) {
            
            selectedIDIndex = foundIndex
            
        } else {
            
            // did not found the index, return nil
            #if DEBUG_PRINT_FUNCCALLS
            print("createCasesGraph(), RKIData[\(selectedArea!)] could not find ID \(selectedID!), return nil")
            #endif
            
            return nil
        }
        
        // OK, now we have the data, so produce an easier to handle array with the values we need
        // calculate the number of days we have to do
        // make sure we do not have too much values (there is only room for 15 bars)
        let numberOfDays: Int = min(15, selectedData.count)
        
        // this will be the values we want to draw
        var valuesToDraw: [Double] = []
        
        for index in 0 ..< numberOfDays {
            
             valuesToDraw.append(selectedData[index][selectedIDIndex].cases7DaysPer100K)
        }

        
        // shortcut for the image we use as background
        
        let imageToUse: UIImage = RKIGraphicQueue.sync(execute: { self.GraphRightInitial })
        
        // this will hold the return image or nil
        let returnImage: UIImage?
        
        
        // shortcut for the dimensions of the image
        let rectOfImage: CGRect = CGRect(x: 0, y: 0, width: newImageWidth, height: newImageHeight)
        
        // get the max value with some headroom for a better look
        let maxValue: CGFloat = (CGFloat(valuesToDraw.max()!) * 1.05)
        
        // this is the value we use to calulate the height of the bar (negative, because of the draw direction)
        let valuePerUnit: CGFloat = CGFloat(self.lengthYAxis / CGFloat(maxValue)) * -1.0
        
        // get the day of the week for reference (all bars with this weekday will be drawnd diffenrently)
        //let weekDayReference: Int = selectedWeekdays.first!
        
        
        // the initial canvas
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newImageWidth, height: newImageHeight),
                                               false,
                                               ScreenScale)
        
        // get the current context (our canvas)
        if let context = UIGraphicsGetCurrentContext() {
            
            // ----- get the background image
            
            // we have to flip the canvas, to make sure the image is not upside down etc.
            //flip coordinats
            context.translateBy(x: 0, y: newImageHeight)
            context.scaleBy(x: 1.0, y: -1.0)
            
            //draw image
            context.draw(imageToUse.cgImage!, in: rectOfImage)
            
            //flip back
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0, y: (newImageHeight * -1.0))
            
            // start the drawing (we just set the background)
            context.beginPath()
            
            
            // ----- draw the axis
            
            // prepare drawing of axises
            context.setLineWidth(self.widthAxis)
            context.setStrokeColor(graphAxisCGColor)
            
            // draw the y-axis
            context.move(to: CGPoint(x: self.leftBorder, y: self.topBorder))
            context.addLine(to: CGPoint(x: self.leftBorder, y: self.yAxisY))
            
            // draw the x-axis
            context.move(to: CGPoint(x: self.leftBorder, y: self.yAxisY))
            context.addLine(to: CGPoint(x: self.rightBorder, y: self.yAxisY))
            
            // draw the axis
            context.drawPath(using: .stroke)
            
            
            
            // ----- draw the bars
            
            // we will try to draw the bars in different colors, so save the state
            context.saveGState()
            
            // prepare the drawing
            var nextStartOfBar = CGPoint(
                x: self.rightBorder - self.barWidth - self.barGap,
                y: self.yAxisY)
            
            // set the color for the normal bars
            context.setFillColor(graphBarNormalCGColor)
            
            // walk over the values
            for index in 0 ..< (numberOfDays) {
                
                // shortcuts for the values we need
                let currentValue = CGFloat(valuesToDraw[index])
                //let currentWeekday = selectedWeekdays[index]
                
                // start the path
                context.beginPath()
                
                // move to the start point
                context.move(to: nextStartOfBar)
                
                // add the bar
                context.addRect(CGRect(x: nextStartOfBar.x,
                                       y: nextStartOfBar.y,
                                       width: self.barWidth,
                                       height: currentValue * valuePerUnit))
                
                    
                    // as we change the color we have to push sthe state
                    context.saveGState()
                    
                let (covidColor, _, _, _) = CovidRating.unique.getColorsForValue(valuesToDraw[index])
                    // change the color
                context.setFillColor(covidColor.cgColor)
                    
                    // draw the bar
                    context.drawPath(using: .fill)
                    
                    // restore the state
                    context.restoreGState()
                    

                
                // set the next startpoint
                nextStartOfBar = CGPoint(
                    x: nextStartOfBar.x - self.barWidth - self.barGap,
                    y: nextStartOfBar.y)
            }
            
            
            // ----- close it
            
            // restore the state to have it balanced
            context.restoreGState()
            
            // OK, that's it, we take this as the new image
            returnImage = UIGraphicsGetImageFromCurrentImageContext()
            
        } else {
            
            // couln't get the context, return nil
            returnImage = nil
        }
        
        // OK, we now have a nice new image, store it
        UIGraphicsEndImageContext()
        
        
        return returnImage
        
    }
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func setAllParameters() {
        
        RKIGraphicQueue.async(flags: .barrier, execute: {
            
            // we use this general idea of proportions of the graph
            // bar width:         10
            // gap between bars:   1
            // number of bars:    15
            // sum for all bars: 165
            //
            // space for y axis:   5
            // width of y axis:    2
            // left border:        3
            // right border:       5
            //
            // sum:              180
            //
            // so this 180 items have to be distributed over the "widthNeeded"
            
            let heightNeeded = GlobalUIData.unique.RKIGraphNeededHeight
            let widthNeeded  = GlobalUIData.unique.RKIGraphNeededWidth
            
            // first step is to claculate the item width
            let itemWidth: CGFloat = widthNeeded / 180
                        
            self.topBorder = 4.0
            self.bottomBorder = 1.0
            let spaceYAxis = floor(itemWidth * 5.0)
            self.widthAxis = max(1.0, floor(itemWidth * 2.0))
            self.yAxisY = heightNeeded - 16.0
            self.lengthYAxis = self.yAxisY - self.topBorder
            self.labelY = heightNeeded - 15.0
            self.messageY = round(self.yAxisY / 2.0)
            self.barWidth = round(itemWidth * 10.0)
            self.barGap = max(1.0, round(itemWidth * 1.0))
            self.leftBorder = round((widthNeeded -
                                        (CGFloat((15.0 * (self.barWidth + self.barGap)) + spaceYAxis + self.widthAxis))
                                     ) / 2.0)
            
            self.rightBorder = widthNeeded - self.leftBorder
        })
    }
    
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func getNewBlankImage() -> UIImage? {
        
        let newImageHeight = GlobalUIData.unique.RKIGraphNeededHeight
        let newImageWidth = GlobalUIData.unique.RKIGraphNeededWidth
        
        let returnImage: UIImage?
        // the initial canvas
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newImageWidth, height: newImageHeight),
                                               false,
                                               ScreenScale)
        
        // get the current context (our canvas)
        if let context = UIGraphicsGetCurrentContext() {
            
            // start the drawing (we just set the background)
            context.beginPath()
            
            // fill the whole canvas with background color
            context.setFillColor(graphBackgroundCGColor)
            
            // use slightly bigger value to overcome rounding effects and ensure a whole black area
            context.addRect(CGRect(x: 0, y: 0, width: newImageWidth + 1, height: newImageHeight + 1))
            
            // draw it
            context.drawPath(using: .fill)
            
            // OK, that's it, we take this as the new image
            returnImage = UIGraphicsGetImageFromCurrentImageContext()
            
        } else {
            
            // couldn't get a context, return nil
            returnImage = nil
        }
        
        // OK, we now have a nice new image, store it
        UIGraphicsEndImageContext()
        
        // return the new image
        return returnImage

    }
    
    
    
    /**
     -----------------------------------------------------------------------------------------------
     
     textToImage()
     
     -----------------------------------------------------------------------------------------------
     
     - Parameters:
     - :
     
     - Returns:
     
     */
    private func textToImage(text: String,
                             image: UIImage,
                             atPoint: CGPoint) -> UIImage?
    {
        let textColor = self.graphLabelUIColor
        let textFont = UIFont.systemFont(ofSize: 12)
        
        let alignAsCenter = NSMutableParagraphStyle()
        alignAsCenter.alignment = NSTextAlignment.center
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, self.ScreenScale)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.paragraphStyle: alignAsCenter
        ] as [NSAttributedString.Key : Any]
        
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let rect = CGRect(origin: atPoint, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
