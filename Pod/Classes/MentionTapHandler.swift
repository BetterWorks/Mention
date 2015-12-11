//
//  MentionTapHandler.swift
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

/// MentionTapHandlerDelegate defines functions for handling taps on @mention and #hashtag substrings.
public protocol MentionTapHandlerDelegate: class {
    /**
     This method is called when the user taps an @mention string.

     :param: id The id encoded in the @mention string.
     */
    func userTappedWithId(id: String)
}

/// Listens for taps on the supplied view and calls the corresponding MentionTapHandlerDelegate method.
/// Note: Creates an instance of UITapGestureRecognizer on the supplied UIView.
class MentionTapHandler<T: UIView where T: AttributedTextContainingView>: NSObject {

    var tapRecognizer: UITapGestureRecognizer!
    weak var delegate: MentionTapHandlerDelegate?

    init<T: UIView where T: AttributedTextContainingView>(view: T, delegate: MentionTapHandlerDelegate?) {
        super.init()
        self.delegate = delegate
        tapRecognizer = UITapGestureRecognizer(target: self, action: "viewTapped:")
        view.addGestureRecognizer(tapRecognizer)
        view.userInteractionEnabled = true
    }

    /**
     Called every time the user taps the supplied view. If the user tapped an @mention or a hashtag, the corresponding
     MentionTapHandlerDelegate delegate is called on the delegate property.

     - parameter recognizer: An instance of UITapGestureRecognizer created in the MentionTapHandler initializer.
     */
    func viewTapped(recognizer: UITapGestureRecognizer) {
        recognizer.cancelsTouchesInView = false

        guard let view = recognizer.view as? T else { return }

        let location = recognizer.locationInView(view)
        let charIndex = view.indexOfTappedCharacter(location)
        let attributedString = view.m_attributedText

        if let userId = attributedString?.attribute(MentionAttributes.UserId, atIndex: charIndex, effectiveRange: nil) as? String {
            delegate?.userTappedWithId(userId)
            recognizer.cancelsTouchesInView = true
        }
    }
}
