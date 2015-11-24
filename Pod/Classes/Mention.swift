//
//  Mention.swift
//  BetterWorks
//
//  Created by Connor Smith on 11/25/14.
//  Copyright (c) 2014 BetterWorks. All rights reserved.
//

import Foundation

// MARK: - MentionController

/**
*  The NSAttributesString attributes used to encode and decode @mentions
*/
private struct MentionAttributes {
    static let UserId  = "MentionUserIdAttribute"
    static let Name    = "MentionNameAttribute"
    static let Encoded = "MentionEncodedAttribute"
}

/**
 *  AttributedTextContainingView provides a single interface for text containing views
 */
public protocol AttributedTextContainingView {
    var m_text: String { get }
    var m_attributedText: NSAttributedString? { get set }
    var m_font: UIFont { get }
    var m_textColor: UIColor { get }
}

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

extension UITextField: AttributedTextContainingView {
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
        return font!
    }

    public var m_textColor: UIColor {
        return textColor!
    }
}

extension UITextView: AttributedTextContainingView {
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
        return font!
    }

    public var m_textColor: UIColor {
        return textColor!
    }
}

///  The MentionController class provides a simple interface for rendering @mentions and #hashtag comments on UILabel, UITextField, and UITextView.
///  To handle user taps on an @mentioin or #hashtag you must conform to the MentionTapHandlerDelegate protocol and set the delegate on MentionController.
///  Note: MentionController is built to be compatible objective C.
public class MentionController: NSObject, MentionTapHandlerDelegate {

    var view: AttributedTextContainingView
    weak var delegate: MentionTapHandlerDelegate?
    private var tapHandler: MentionTapHandler!
    private let mentionDecoder: MentionDecoder

    // MARK: Init

    /**
    Public initializer for MentionController.

    - parameter view:     A `UIView` that conforms to `AttributedTextContainingView`
    - parameter delegate: An object that conforms to MentionTapHandlerDelegate

    - returns: An instance of MentionController
    */
    public convenience init<T: UIView where T: AttributedTextContainingView>(view: T, delegate: MentionTapHandlerDelegate?) {
        let attributedString = view.m_attributedText ?? NSAttributedString(string: view.m_text, attributes: [NSFontAttributeName : view.m_font, NSForegroundColorAttributeName : view.m_textColor])
        self.init(view: view, inputString: attributedString, delegate: delegate)
    }

    private init<T: UIView where T: AttributedTextContainingView>(view: T, inputString: NSAttributedString, delegate: MentionTapHandlerDelegate?) {
        self.view = view
        self.delegate = delegate
        self.mentionDecoder = MentionDecoder(attributedString: inputString)
        super.init()

        // Decode
        let attributedStringWithMentions = mentionDecoder.decode()

        // Set Attributed Text
        self.view.m_attributedText = attributedStringWithMentions

        // Handle Taps
        tapHandler = MentionTapHandler(view: view, delegate: self)
    }

    // MARK: MentionTapHandlerDelegate

    public func userTappedWithId(id: String) {
        delegate?.userTappedWithId(id)
    }
}

// MARK: - Mention Composition

/**
*  MentionUser is a lightweight, generic model object intended to be the primary way of 
*  providing MentionComposer classes with a list of users and their attributes.
*/
@objc class MentionUser: NSObject {
    
    let name: String
    let id: Int
    let imageURL: String?
    
    init(name: String, id: Int, imageURL: String?) {
        self.name = name
        self.id = id
        self.imageURL = imageURL
        super.init()
    }
    
    func encodedAttributedString() -> NSAttributedString {
        let encodedString = "@\(name)"
        let attributedString = NSMutableAttributedString(string: name, attributes: [
            MentionAttributes.Encoded : encodedString,
            MentionAttributes.Name: name,
            MentionAttributes.UserId : id,
            ])
        attributedString.appendAttributedString(NSAttributedString(string: " "))
        return attributedString as NSAttributedString
    }
}

/**
*  The primary purpose MentionComposerDelegate is to provide the list of users matching an @mention query.
*  Because TextViewMentionComposer relies on the UITextViewDelegate callbacks, it forwards all of them onto the MentionComposerDelegate.
*/
@objc protocol MentionComposerDelegate {
   
    func usersMatchingQuery(searchQuery query: String) -> [MentionUser]
    
    optional func userDidComposeMention()
    
    // Forwarded UITextViewDelegateMethods
    
    optional func textViewShouldBeginEditing(textView: UITextView) -> Bool
    optional func textViewShouldEndEditing(textView: UITextView) -> Bool
    
    optional func textViewDidBeginEditing(textView: UITextView)
    optional func textViewDidEndEditing(textView: UITextView)
    
    optional func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    optional func textViewDidChange(textView: UITextView)
    
    optional func textViewDidChangeSelection(textView: UITextView)
    
    @available(iOS, introduced=7.0)
    optional func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool
    @available(iOS, introduced=7.0)
    optional func textView(textView: UITextView, shouldInteractWithTextAttachment textAttachment: NSTextAttachment, inRange characterRange: NSRange) -> Bool
}

/**
*  Use TextViewMentionComposer anytime you want to allow the user to compose an @mention using a UITextView.
*/
class TextViewMentionComposer: NSObject {
    
    private let MentionCellIdentifier = "MentionCell"
    private let TextColor = UIColor.blueColor()
    
    private var mentionRange: NSRange?
    private var tapRecognizer: UITapGestureRecognizer!
    private var recentCharacterRange: NSRange = NSRange(location: 0, length: 0)
    private let originalTextColor: UIColor
    private let originalFont: UIFont
    private let originalAutoCorrectionType: UITextAutocorrectionType!
    var textView: UITextView
    var tableView: UITableView
    weak var delegate: MentionComposerDelegate?
    var userNameMatches = [MentionUser]()
    
    /// Returns the text encoded for the API
    var encodedText: String {
        let encodedText = NSMutableAttributedString(attributedString: textView.attributedText)
        
        encodedText.enumerateAttribute(MentionAttributes.Encoded, inRange: NSRange(location: 0, length: encodedText.length), options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
            if let encodedMention = value as? String {
                encodedText.replaceCharactersInRange(range, withString: encodedMention)
            }
        }
        
        return encodedText.string
    }
    
    /// Returns the ids for every mentioned user
    var mentionIds: [Int] {
        var ids = [Int]()
        textView.attributedText.enumerateAttribute(MentionAttributes.UserId, inRange: NSRange(location: 0, length: textView.attributedText.length), options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
            if let id = value as? Int {
                ids.append(id)
            }
        }
        
        return ids
    }
    
    /**
    The default initializer for TextViewMentionComposer.
    
    :param: textView  The UITextView where the user will be entering text.
    :param: tableView The UITableView that will display the list of users matching what the user is composing.
    :param: delegate  The MentionComposerDelegate that will provide the users matching the query. TextViewMentionComposer is useless without a delegate.
    
    :returns: An instance if TextViewMentionComposer.
    */
    init(textView: UITextView, searchResultsTableView tableView: UITableView, delegate: MentionComposerDelegate?) {
        self.textView = textView
        self.delegate = delegate
        self.tableView = tableView
        originalTextColor = textView.textColor ?? UIColor.darkTextColor()
        originalAutoCorrectionType = textView.autocorrectionType
        originalFont = textView.font ?? UIFont.systemFontOfSize(UIFont.systemFontSize())
        super.init()
        textView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerNib(UINib(nibName: "MentionTableViewCell", bundle: nil), forCellReuseIdentifier: MentionCellIdentifier)
        tapRecognizer = UITapGestureRecognizer(target: self, action: "tableViewTapped:")
        tapRecognizer.delegate = self
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delaysTouchesEnded = false
        tableView.addGestureRecognizer(tapRecognizer)
    }
    
    // MARK: Private methods
    
    private func mentionQuery(fromString string: NSString) -> NSString? {
        var query: NSString?
        
        let pattern = "\\@[^\\@.+]+"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
            
            let range = NSRange(location: 0, length: string.length)
            
            let matches = regex.matchesInString(string as String, options: .ReportCompletion, range: range)
            
            for match in matches {
                // Match must be contained in the text the user most recently changed
                if NSIntersectionRange(match.range, recentCharacterRange).length > 0 {
                    let queryLength = recentCharacterRange.location - match.range.location + 1
                    mentionRange = NSRange(location: match.range.location, length: queryLength)
                    query = string.substringWithRange(mentionRange!) as NSString
                    query = query?.substringFromIndex(1)
                }
            }
        } catch {
            print("could not create regex!")
        }
        
        return query
    }
    
    private func setAttributedText(attributedText: NSAttributedString, cursorLocation: Int) {
        textView.attributedText = attributedText
        textView.selectedRange = NSRange(location: cursorLocation, length: 0)
    }
    
    private func injectMention(forUser user: MentionUser) {
        let text = NSMutableAttributedString(attributedString: textView.attributedText)
        let mutableEncodedString = NSMutableAttributedString(attributedString: user.encodedAttributedString())
        mutableEncodedString.addAttributes([NSFontAttributeName : originalFont, NSForegroundColorAttributeName : TextColor], range: NSRange(location: 0, length: mutableEncodedString.length))
        text.replaceCharactersInRange(mentionRange!, withAttributedString: mutableEncodedString)
        setAttributedText(text, cursorLocation: mentionRange!.location + mutableEncodedString.length)
        delegate?.userDidComposeMention?()
    }
    
    private func rangeOfMention(atIndex index: Int) -> NSRange? {
        var mentionRange: NSRange?
        let currentRange = NSRange(location: index, length: 1)
        
        textView.attributedText.enumerateAttribute(MentionAttributes.Encoded, inRange: NSRange(location: 0, length: textView.attributedText.length), options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
            if value != nil  {
                let rangeAfterFirstCharacter = NSRange(location: range.location + 1, length: range.length - 1)
                if NSIntersectionRange(rangeAfterFirstCharacter, currentRange).length > 0 {
                    mentionRange = range
                    stop.memory = true
                }
            }
        }
        
        return mentionRange
    }
    
    private func deleteMention(inRange range: NSRange) {
        let mutableText = NSMutableAttributedString(attributedString: self.textView.attributedText)
        mutableText.deleteCharactersInRange(range)
        self.setAttributedText(mutableText, cursorLocation: range.location)
    }
    
    private func undoMention(inRange range: NSRange) {
        let mutableText = NSMutableAttributedString(attributedString: self.textView.attributedText)
        mutableText.removeAttribute(MentionAttributes.Encoded, range: range)
        mutableText.removeAttribute(MentionAttributes.Name, range: range)
        mutableText.removeAttribute(MentionAttributes.UserId, range: range)
        mutableText.removeAttribute(NSForegroundColorAttributeName, range: range)
        self.setAttributedText(mutableText, cursorLocation: recentCharacterRange.location)
    }
    
    private func refreshTableView() {
        tableView.reloadData()
        tableView.hidden = userNameMatches.count == 0
    }
}

extension TextViewMentionComposer: UIGestureRecognizerDelegate {
    // MARK: UIGestureRecognizerDelegate
    
    func tableViewTapped(recognizer: UITapGestureRecognizer) {
        tableView.becomeFirstResponder()
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        var shouldBegin = true
        if (gestureRecognizer == tapRecognizer) {
            if tableView.isFirstResponder() {
                shouldBegin = false
            }
        }
        
        return shouldBegin
    }
}

extension TextViewMentionComposer: UITextViewDelegate {
    
    /**
    In order for some property changes to take effect on UITextView you must resignFirstResponder
    and then becomeFirstResponder. This method calls these methods back to back respectively.
    The delegate of the text view is set to nil immediately beforehand so we do not forwards the UITextViewDelegate
    methods in MentionComposerDelegate. Immediately proceeding this we set the delegate back to its original state.
    */
    private func refreshTextView() {
        textView.delegate = nil
        textView.resignFirstResponder()
        textView.becomeFirstResponder()
        textView.delegate = self
    }
    
    // MARK: UITextViewDelegate
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        return delegate?.textViewShouldBeginEditing?(textView) ?? true
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        return delegate?.textViewShouldEndEditing?(textView) ?? true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        delegate?.textViewDidBeginEditing?(textView)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        delegate?.textViewDidEndEditing?(textView)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        var location = range.location
        var deleting = false
        if (text == "") && (range.location != 0) {
            deleting = true
            location -= 1
        }
        
        recentCharacterRange = NSRange(location: location, length: 1)
        
        var mentionFound = false
        if let range = rangeOfMention(atIndex: range.location) {
            (deleting) ? deleteMention(inRange: range) : undoMention(inRange: range)
            mentionFound = true
        }
        
        textView.typingAttributes.removeValueForKey(MentionAttributes.Encoded)
        textView.typingAttributes.removeValueForKey(MentionAttributes.UserId)
        textView.typingAttributes.removeValueForKey(MentionAttributes.Name)
        textView.typingAttributes.updateValue(originalTextColor, forKey: NSForegroundColorAttributeName)
        
        return (deleting && mentionFound) ? false : (delegate?.textView?(textView, shouldChangeTextInRange: range, replacementText: text) ?? true)
        
    }
    
    func textViewDidChange(textView: UITextView) {
        let text = textView.text as NSString
        if let query = mentionQuery(fromString: text) {
            if let userNames = delegate?.usersMatchingQuery(searchQuery: query as String) {
                userNameMatches = userNames
                refreshTableView()
            }
        }
        else {
            userNameMatches.removeAll(keepCapacity: false)
            tableView.reloadData()
            tableView.hidden = true
        }
        
        if userNameMatches.count > 0 {
            if textView.autocorrectionType != .No {
                textView.autocorrectionType = .No
                refreshTextView()
            }
        }
        else if textView.autocorrectionType != originalAutoCorrectionType {
            textView.autocorrectionType = originalAutoCorrectionType
            refreshTextView()
        }
        
        delegate?.textViewDidChange?(textView)
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        delegate?.textViewDidChangeSelection?(textView)
    }
    
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        return delegate?.textView?(textView, shouldInteractWithURL: URL, inRange: characterRange) ?? true
    }
    
    func textView(textView: UITextView, shouldInteractWithTextAttachment textAttachment: NSTextAttachment, inRange characterRange: NSRange) -> Bool {
        return delegate?.textView?(textView, shouldInteractWithTextAttachment: textAttachment, inRange: characterRange) ?? true
    }
}

extension TextViewMentionComposer: UITableViewDataSource, UITableViewDelegate {
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userNameMatches.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MentionCellIdentifier, forIndexPath: indexPath) as! MentionTableViewCell
        let user = userNameMatches[indexPath.row]
        cell.mentionUser = user
        
        return cell
    }
    
    // MARK: UTableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MentionTableViewCell
        if let user = cell.mentionUser {
            injectMention(forUser: user)
            userNameMatches.removeAll(keepCapacity: false)
            refreshTableView()
        }
        
        textView.becomeFirstResponder()
    }
}

// MARK: - Decoding

/**
*  A protocol for classes or structs that decode @mentions, tags, or more.
*/
private protocol TagDecoder {
    /// Typically a regex pattern for your tag
    var pattern: String { get }
    /// The text color for decoded tags
    var tagColor: UIColor { get }
    func decode() -> NSAttributedString
}

/**
 *  A MentionDecoder instance finds occurences of @mentions in a string and converts them to regular text
 */
struct MentionDecoder: TagDecoder {

    var pattern         = "\\[\\@.+?\\:[0-9]+\\]"
    let tagColor        = UIColor.blueColor()
    let tagFont         = UIFont.systemFontOfSize(18)
    let userIdSignifier = ":"
    let attributedString: NSAttributedString

    init(attributedString: NSAttributedString) {
        self.attributedString = attributedString
    }

    /**
     Given a String, MentionDecoder replaces all instances of @mention with an NSAttributedString showing just the user name.
     The user id is encoded in the MentionAttributes.UserId attribute.
     The following custom attributes are set on @mention strings:

     MentionAttribute : true
     MentionAttributes.UserId: decoded user id as a string

     - parameter string: A String that may contain @mention substrings.

     - returns: An instance of NSAttributedString.
     */
    func decode() -> NSAttributedString {
        let mutableDecodedString = attributedString.mutableCopy() as! NSMutableAttributedString
        let string = attributedString.string

        let regex = try? NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
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
                    if let userSignifierRange = mention.rangeOfString(userIdSignifier) {
                        // Find the user id
                        let userIdRange = Range(start: userSignifierRange.startIndex.advancedBy(1), end: userSignifierRange.startIndex.advancedBy(userSignifierRange.startIndex.distanceTo(mention.endIndex) - 1))
                        let userId = mention.substringWithRange(userIdRange)

                        // Strip everything but the user name
                        let userNameRange = Range(start: mention.startIndex.advancedBy(2), end: userSignifierRange.startIndex)
                        let userName = mention.substringWithRange(userNameRange)

                        // Replace the mention with the user name as an attributed string
                        let attributedMention = NSAttributedString(string: userName, attributes: [MentionAttributes.UserId : userId, NSForegroundColorAttributeName : tagColor, NSFontAttributeName : tagFont])
                        mutableDecodedString.replaceCharactersInRange(matchRange, withAttributedString: attributedMention)

                        // Offset the difference between the length of the replacement string and the original range of the regex match
                        offset += attributedMention.length - matchRange.length
                    }
                }
            }
        }

        return NSAttributedString(attributedString: mutableDecodedString)
    }
}

// MARK: - MentionTapHandler

/**
*  MentionTapHandlerDelegate defines functions for handling taps on @mention and #hashtag substrings.
*/
public protocol MentionTapHandlerDelegate: class {
    /**
     This method is called when the user taps an @mention string.

     :param: id The id encoded in the @mention string.
     */
    func userTappedWithId(id: String)
}

/// Listens for taps on the supplied view and calls the corresponding MentionTapHandlerDelegate method.
/// Note: Creates an instance of UITapGestureRecognizer on the supplied UIView.
public class MentionTapHandler: NSObject {

    var tapRecognizer: UITapGestureRecognizer!
    weak var delegate: MentionTapHandlerDelegate?

    init<T: UIView where T: AttributedTextContainingView>(view: T, delegate: MentionTapHandlerDelegate) {
        super.init()
        self.delegate = delegate
        tapRecognizer = UITapGestureRecognizer(target: self, action: "viewTapped:")
        view.addGestureRecognizer(tapRecognizer)
    }

    /**
     Called every time the user taps the supplied view. If the user tapped an @mention or a hashtag, the corresponding
     MentionTapHandlerDelegate delegate is called on the delegate property.

     :param: recognizer An instance of UITapGestureRecognizer created in the MentionTapHandler initializer.
     */
    func viewTapped(recognizer: UITapGestureRecognizer) {
        recognizer.cancelsTouchesInView = false

        let view = recognizer.view!
        let location = recognizer.locationInView(view)
        var charIndex: Int?
        var attributedString: NSAttributedString?

        switch view {
        case let label as UILabel:
            charIndex = LabelCharacterFinder.indexOfTappedCharacter(inView: label, tapLocation: location)
            attributedString = label.attributedText
        case let textView as UITextView:
            charIndex = TextViewCharacterFinder.indexOfTappedCharacter(inView: textView, tapLocation: location)
            attributedString = textView.attributedText
        case let textField as UITextField:
            charIndex = TextFieldCharacterFinder.indexOfTappedCharacter(inView: textField, tapLocation: location)
            attributedString = textField.attributedText
        default:
            print("unsupported view")
        }

        if let index = charIndex {
            if let userId = attributedString?.attribute(MentionAttributes.UserId, atIndex: index, effectiveRange: nil) as? String {
                delegate?.userTappedWithId(userId)
                recognizer.cancelsTouchesInView = true
            }
        }
    }
}

// MARK: - CharacterFinder


/**
*  CharacterFinder is a protocol for a class that identifies what character was tapped in the given container of text.
The container class type is at the discretion of the class or struct that implements CharacterFinder.
*/
private protocol CharacterFinder {
    typealias ViewType: UIView
    static func indexOfTappedCharacter(inView view: ViewType, tapLocation: CGPoint) -> Int
}

private struct LabelCharacterFinder: CharacterFinder {
    typealias ViewType = UILabel

    /**
     Finds the character at a given location in a tapped view.

     :param: view        The view that was tapped. Must be an instance of UILabel.
     :param: tapLocation The location of the tap. Usually derived from a gesture recognizer.

     :returns: The index of the tapped character.
     */
    static func indexOfTappedCharacter(inView view: ViewType, tapLocation: CGPoint) -> Int {

        // UILabel doesn't come with NSTextStorage, NSTextContainer, or NSLayoutManager, so
        // we have to create these manually.

        let attributedText = view.attributedText ?? NSAttributedString()
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: view.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = view.numberOfLines
        textContainer.lineBreakMode = view.lineBreakMode
        textContainer.layoutManager = layoutManager

        layoutManager.addTextContainer(textContainer)

        // Find the tapped character

        return layoutManager.characterIndexForPoint(tapLocation, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}

private struct TextViewCharacterFinder: CharacterFinder {
    typealias ViewType = UITextView

    /**
     Finds the character at a given location in a tapped view.

     :param: view        The view that was tapped. Must be an instance of UITextView.
     :param: tapLocation The location of the tap. Usually derived from a gesture recognizer.

     :returns: The index of the tapped character.
     */
    static func indexOfTappedCharacter(inView view: ViewType, tapLocation: CGPoint) -> Int {

        // Location of the tap

        var location = tapLocation
        let layoutManager = view.layoutManager
        location.x -= view.textContainerInset.left
        location.y -= view.textContainerInset.top

        // Find the tapped character

        return layoutManager.characterIndexForPoint(location, inTextContainer: view.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}

private struct TextFieldCharacterFinder: CharacterFinder {
    typealias ViewType = UITextField

    /**
     Finds the character at a given location in a tapped view.

     :param: view        The view that was tapped. Must be an instance of UITextField.
     :param: tapLocation The location of the tap. Usually derived from a gesture recognizer.

     :returns: The index of the tapped character.
     */
    static func indexOfTappedCharacter(inView view: ViewType, tapLocation: CGPoint) -> Int {

        // UITextField doesn't come with NSTextStorage, NSTextContainer, or NSLayoutManager, so
        // we have to create these manually.

        var charIndex = -1

        if let attributedText = view.attributedText {
            let textStorage = NSTextStorage(attributedString: attributedText)
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)

            let textContainer = NSTextContainer(size: view.bounds.size)
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
