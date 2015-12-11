//
//  CharacterFinder.swift
//  Pods
//
//  Created by Connor Smith on 12/10/15.
//
//

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
