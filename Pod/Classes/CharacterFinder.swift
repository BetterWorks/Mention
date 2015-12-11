//
//  CharacterFinder.swift
//  Pods
//
//  Created by Connor Smith on 12/10/15.
//  Copyright (c) 2015 BetterWorks. https://www.betterworks.com
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// MARK: - CharacterFinder

/**
*  CharacterFinder is a protocol for a class that identifies what character was tapped in the given container of text.
The container class type is at the discretion of the class or struct that implements CharacterFinder.
*/
public protocol CharacterFinder {
    func indexOfTappedCharacter(tapLocation: CGPoint) -> Int
}

extension UILabel: CharacterFinder {
    /**
     Finds the character at a given location in a tapped view.

     - parameter tapLocation: The location of the tap. Usually derived from a gesture recognizer.

     - returns: The index of the tapped character.
     */
    public func indexOfTappedCharacter(tapLocation: CGPoint) -> Int {
        // UILabel doesn't come with NSTextStorage, NSTextContainer, or NSLayoutManager, so
        // we have to create these manually.

        let attributedText = m_attributedText ?? NSAttributedString()
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode
        textContainer.layoutManager = layoutManager

        layoutManager.addTextContainer(textContainer)

        // Find the tapped character

        return layoutManager.characterIndexForPoint(tapLocation, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}

extension UITextView: CharacterFinder {
    /**
     Finds the character at a given location in a tapped view.

     - parameter tapLocation: The location of the tap. Usually derived from a gesture recognizer.

     - returns: The index of the tapped character.
     */
    public func indexOfTappedCharacter(tapLocation: CGPoint) -> Int {
        // Location of the tap

        var location = tapLocation
        location.x -= textContainerInset.left
        location.y -= textContainerInset.top

        // Find the tapped character

        return layoutManager.characterIndexForPoint(location, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}

extension UITextField: CharacterFinder {
    /**
     Finds the character at a given location in a tapped view.

     - parameter tapLocation: The location of the tap. Usually derived from a gesture recognizer.

     - returns: The index of the tapped character.
     */
    public func indexOfTappedCharacter(tapLocation: CGPoint) -> Int {
        // UITextField doesn't come with NSTextStorage, NSTextContainer, or NSLayoutManager, so
        // we have to create these manually.

        var charIndex = -1

        if let attributedText = m_attributedText {
            let textStorage = NSTextStorage(attributedString: attributedText)
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)

            let textContainer = NSTextContainer(size: bounds.size)
            textContainer.lineFragmentPadding = 0
            textContainer.layoutManager = layoutManager

            layoutManager.addTextContainer(textContainer)
            layoutManager.textStorage = textStorage

            // Find the tapped character

            charIndex = layoutManager.characterIndexForPoint(tapLocation, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        }
        
        return charIndex
    }
}
