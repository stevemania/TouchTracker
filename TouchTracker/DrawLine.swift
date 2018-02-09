//
//  DrawLine.swift
//  touchTracker
//
//  Created by STEVE DURAN on 11/7/17.
//  Copyright © 2017 STEVE DURAN. All rights reserved.
//

import UIKit
class DrawView: UIView, UIGestureRecognizerDelegate{
 
    
    //dictionary containing instance of line
    var currentLines = [NSValue:Line]()
    var finishedLines = [Line]()
    //var selectedLineIndex: Int?
    var moveRecognizer: UIPanGestureRecognizer!
    
    @IBInspectable var finishedLineColor: UIColor = UIColor.cyan {
        didSet {
        setNeedsDisplay() }
    }
    @IBInspectable var currentLineColor: UIColor = UIColor.red {
        didSet {
        setNeedsDisplay() }
    }
    @IBInspectable var lineThickness: CGFloat = 20 {
        didSet {
        setNeedsDisplay() }
    }
    
    var selectedLineIndex: Int? {
        didSet {
            if selectedLineIndex == nil {
                let menu = UIMenuController.shared
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    
    //fix this
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        //this allows user to detect line by tapping it
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.tap(_:)))
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        //add the ability for a user to select a line by pressing and holding (a long press) and then move the selected line by dragging the finger (a pan). This will require two more subclasses of UIGestureRecognizer: UILongPressGestureRecognizer and UIPanGestureRecognizer.
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DrawView.longPress(_:)))
        addGestureRecognizer(longPressRecognizer)
        
        // this deals with moving of the lines i believe
        moveRecognizer = UIPanGestureRecognizer(target: self,
                                                action: #selector(DrawView.moveLine(_:)))
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
        
    }
    
    //this will tell console that a line was tapped
    @objc func tap(_ gestureRecognizer: UIGestureRecognizer) {
        print("Recognized a tap")
        
        let point = gestureRecognizer.location(in: self)
        selectedLineIndex = indexOfLine(at: point)
        
        // Grab the menu controller
        let menu = UIMenuController.shared
        if selectedLineIndex != nil {
            // Make DrawView the target of menu item action messages
            becomeFirstResponder()
            // Create a new "Delete" UIMenuItem
            let deleteItem = UIMenuItem(title: "Delete",action: #selector(DrawView.deleteLine(_:)))  //this might be wrong
            menu.menuItems = [deleteItem]
            // Tell the menu where it should come from and show it
            let targetRect = CGRect(x: point.x, y: point.y, width: 2, height: 2)
            menu.setTargetRect(targetRect, in: self)
            menu.setMenuVisible(true, animated: true)
        } else {
            // Hide the menu if no line is selected
            menu.setMenuVisible(false, animated: true)
        }
        setNeedsDisplay()
    }
    
    
    func stroke(_ line: Line) {
        let path = UIBezierPath()
        path.lineWidth = lineThickness
        path.lineCapStyle = .round
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    override func draw(_ rect: CGRect) {
        // Draw finished lines in black
        finishedLineColor.setStroke()
        for line in finishedLines {
            stroke(line)
        }
        
        // Draw current lines in red
        currentLineColor.setStroke()
        for (_, line) in currentLines {
            stroke(line)
        }
        
        if let index = selectedLineIndex {
            UIColor.green.setStroke()
            let selectedLine = finishedLines[index]
            stroke(selectedLine)
        }
    }
    //When a touch begins, you will create a Line and set both of its properties to the point where the touch began. When the touch moves, you will update the Line’s end. When the touch ends, you will have your complete Line.
    //This code first figures out the location of the touch within the view’s coordinate system. Then it calls setNeedsDisplay(), which flags the view to be redrawn at the end of the run loop.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       
        //MULTIPLE LINES TOUCHED
        // Log statement to see the order of events print(#function)
        for touch in touches {
            let location = touch.location(in: self)
            let newLine = Line(begin: location, end: location)
            let key = NSValue(nonretainedObject: touch)
            currentLines[key] = newLine }

        setNeedsDisplay()
    }
    
    
    //so that it updates the end of the currentLine.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Log statement to see the order of events
        print(#function)
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            currentLines[key]?.end = touch.location(in: self)
        }
        setNeedsDisplay() }
    
    //update the end location of the currentLine and add it to the finishedLines array when the touch ends.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Log statement to see the order of events print(#function)
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            if var line = currentLines[key] {
                line.end = touch.location(in: self)
                finishedLines.append(line)
                currentLines.removeValue(forKey: key) }
        }
        setNeedsDisplay()
    }
    
    //this will deal with the app being interuprted by calls, text etc
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Log statement to see the order of events
        print(#function)
        currentLines.removeAll()
        setNeedsDisplay()
    }
    
    //double tap occurs
    @objc func doubleTap(_ gestureRecognizer: UIGestureRecognizer) {
        print("Recognized a double tap")
        
        selectedLineIndex = nil
        currentLines.removeAll()
        finishedLines.removeAll()
        setNeedsDisplay()
    }
    
    override var canBecomeFirstResponder: Bool { return true
    }

    @objc func deleteLine(_ sender: UIMenuController) {
        // Remove the selected line from the list of finishedLines
        if let index = selectedLineIndex {
            finishedLines.remove(at: index)
            selectedLineIndex = nil
            
            // Redraw everything
            setNeedsDisplay()
        }
}
    
    //return index of the line that was picked
    func indexOfLine(at point: CGPoint) -> Int? {
        // Find a line close to point
        for (index, line) in finishedLines.enumerated() {
            let begin = line.begin
            let end = line.end
            // Check a few points on the line
            for t in stride(from: CGFloat(0), to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                // If the tapped point is within 20 points, let's return this line
                if hypot(x - point.x, y - point.y) < 20.0 {
                return index
                }
            }
        }
        // If nothing is close enough to the tapped point, then we did not select a line
        return nil
    }
    
    //deals with long pressing the line
    @objc func longPress(_ gestureRecognizer: UIGestureRecognizer) {
        print("Recognized a long press")
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: self)
            selectedLineIndex = indexOfLine(at: point)
            if selectedLineIndex != nil {
                currentLines.removeAll()
            }
        } else if gestureRecognizer.state == .ended {
            selectedLineIndex = nil }
        setNeedsDisplay()
    }
    
    //deals with moving the line from a different position
    @objc func moveLine(_ gestureRecognizer: UIPanGestureRecognizer) {
        print("Recognized a pan")
        // If a line is selected...
        if let index = selectedLineIndex {
            // When the pan recognizer changes its position... if gestureRecognizer.state == .changed {
            // How far has the pan moved?
            let translation = gestureRecognizer.translation(in: self)
            // Add the translation to the current beginning and end points of the line
            // Make sure there are no copy and paste typos!
            finishedLines[index].begin.x += translation.x
            finishedLines[index].begin.y += translation.y
            finishedLines[index].end.x += translation.x
            finishedLines[index].end.y += translation.y
            
            gestureRecognizer.setTranslation(CGPoint.zero, in: self) //without this, the sync between your mouse and line will be accurate. Look up why sync is horrible without this
            // Redraw the screen
            setNeedsDisplay()
        }
     else {
    // If no line is selected, do not do anything return
     }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
}
