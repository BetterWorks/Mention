//
//  MentionDecoder.swift
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

// MARK: - MentionDecoder

/**
The MentionDecoder class provides a simple interface for rendering @mentions and #hashtag comments on UILabel, UITextField, and UITextView.

To handle user taps on an @mentioin you must conform to the `MentionTapHandlerDelegate` protocol and set the delegate on `MentionDecoder`.
*/
public struct MentionDecoder<T: UIView where T: AttributedTextContainingView> {

    private let Pattern         = "\\[\\\(MentionCharacter).+?\\:[0-9]+\\]"
    private let UserIdSignifier = ":"

    var view: AttributedTextContainingView
    private var tapHandler: MentionTapHandler<T>

    // MARK: Init

    /**
    Public initializer for MentionDecoder.

    - parameter view:     A `UIView` that conforms to `AttributedTextContainingView` and `CharacterFinder`
    - parameter delegate: An object that conforms to MentionTapHandlerDelegate

    - returns: An instance of MentionDecoder
    */
    public init(view: T, delegate: MentionTapHandlerDelegate?) {
        self.view = view

        // Handle Taps
        tapHandler = MentionTapHandler(view: view, delegate: delegate)

        // Decode
        decode()
    }

    /**
     Find all instances of @mentions within the view and replace them with a human readable mention
     - Note: This funciton is invoked during init
     */
    public mutating func decode() {
        let startingAttributedString = view.m_attributedText ?? view.defaultAttributedText
        let mutableDecodedString = NSMutableAttributedString(attributedString: startingAttributedString)
        let string = mutableDecodedString.string

        let regex = try? NSRegularExpression(pattern: Pattern, options: .CaseInsensitive)
        let range = NSRange(location: 0, length: string.characters.count)
        if let matches = regex?.matchesInString(string as String, options: .ReportCompletion, range: range) {
            // keeps track of range changes in mutableDecodedString due to replacements
            var offset = 0

            for match in matches {
                // Isolate the mention
                var matchRange = match.range
                matchRange.location += offset
                if let mention = regex?.replacementStringForResult(match, inString: mutableDecodedString.string, offset: offset, template: "$0") {
                    // Find the user id signifier
                    if let userSignifierRange = mention.rangeOfString(UserIdSignifier) {
                        // Find the user id
                        let userIdRange = Range(start: userSignifierRange.startIndex.advancedBy(1), end: userSignifierRange.startIndex.advancedBy(userSignifierRange.startIndex.distanceTo(mention.endIndex) - 1))
                        let userId = mention.substringWithRange(userIdRange)

                        // Strip everything but the user name
                        let userNameRange = Range(start: mention.startIndex.advancedBy(2), end: userSignifierRange.startIndex)
                        let userName = mention.substringWithRange(userNameRange)

                        // Replace the mention with the user name as an attributed string
                        let attributedMention = NSAttributedString(string: userName, attributes: [MentionAttributes.UserId : userId, NSForegroundColorAttributeName : MentionColor, NSFontAttributeName : view.m_font])
                        mutableDecodedString.replaceCharactersInRange(matchRange, withAttributedString: attributedMention)

                        // Offset the difference between the length of the replacement string and the original range of the regex match
                        offset += attributedMention.length - matchRange.length
                    }
                }
            }
        }
        
        view.m_attributedText = NSAttributedString(attributedString: mutableDecodedString)
    }
}
