//
//  MentionTapHandler.swift
//  Pods
//
//  Created by Connor Smith on 12/10/15.
//  Copyright (c) 2015 BetterWorks. All rights reserved.
//

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
