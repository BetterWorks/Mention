//
//  AttributedTextContainingView.swift
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

// MARK: AttributedTextContainingView

/**
*  AttributedTextContainingView provides a single interface for text-containing views
*/
public protocol AttributedTextContainingView: CharacterFinder {
    var m_text: String { get }
    var m_attributedText: NSAttributedString? { get set }
    var m_font: UIFont { get }
    var m_textColor: UIColor { get }
}

// MARK: - ComposableAttributedTextContainingView

/**
 *  ComposableAttributedTextContainingView provides a single interface for composable text-containing views
 */
public protocol ComposableAttributedTextContainingView: AttributedTextContainingView, UITextInputTraits, UITextInput {
    var m_typingAttributes: [String : AnyObject]? { get set }
}

// MARK: - AttributedTextContainingView Extension

extension AttributedTextContainingView {
    mutating func configureDefaultAttributedText() {
        m_attributedText = m_attributedText ?? defaultAttributedText
    }

    var defaultAttributedText: NSAttributedString {
        return NSAttributedString(string: m_text, attributes: [NSFontAttributeName : m_font, NSForegroundColorAttributeName : m_textColor])
    }
}

// MARK: - UILabel

extension UILabel: AttributedTextContainingView {
    public var m_text: String {
        get {
            return text ?? ""
        }
    }

    public var m_attributedText: NSAttributedString? {
        set {
            attributedText = newValue
        }
        get {
            return attributedText
        }
    }

    public var m_font: UIFont {
        return font
    }

    public var m_textColor: UIColor {
        return textColor
    }
}

// MARK: - UITextField

extension UITextField: ComposableAttributedTextContainingView {
    public var m_text: String {
        get {
            return self.text ?? ""
        }
    }

    public var m_attributedText: NSAttributedString? {
        set {
            self.attributedText = newValue
        }
        get {
            return self.attributedText
        }
    }

    public var m_font: UIFont {
        return font ?? UIFont.systemFontOfSize(UIFont.systemFontSize())
    }

    public var m_textColor: UIColor {
        return textColor ?? UIColor.darkTextColor()
    }

    public var m_typingAttributes: [String : AnyObject]? {
        get {
            return typingAttributes
        }
        set {
            typingAttributes = newValue
        }
    }
}

// MARK: - UITextView

extension UITextView: ComposableAttributedTextContainingView {
    public var m_text: String {
        get {
            return self.text ?? ""
        }
    }

    public var m_attributedText: NSAttributedString? {
        set {
            self.attributedText = newValue
        }
        get {
            return self.attributedText
        }
    }

    public var m_font: UIFont {
        return font ?? UIFont.systemFontOfSize(UIFont.systemFontSize())
    }

    public var m_textColor: UIColor {
        return textColor ?? UIColor.darkTextColor()
    }

    public var m_typingAttributes: [String : AnyObject]? {
        get {
            return typingAttributes
        }
        set {
            typingAttributes = newValue ?? [String : AnyObject]()
        }
    }
}
