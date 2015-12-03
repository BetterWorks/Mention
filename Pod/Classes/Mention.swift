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
public protocol AttributedTextContainingView: CharacterFinder {
    var m_text: String { get }
    var m_attributedText: NSAttributedString? { get set }
    var m_font: UIFont { get }
    var m_textColor: UIColor { get }
}

public protocol ComposableAttributedTextContainingView: AttributedTextContainingView, UITextInputTraits, UITextInput {
    var m_autoCorrectionType: UITextAutocorrectionType { get set }
    var m_typingAttributes: [String : AnyObject]? { get set }
}

public var MentionCharacter: Character = "@"
public var MentionColor                = UIColor.blueColor()

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
        return font!
    }

    public var m_textColor: UIColor {
        return textColor!
    }

    public var m_autoCorrectionType: UITextAutocorrectionType {
        get {
            return autocorrectionType
        }
        set {
            autocorrectionType = newValue
        }
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
        return font!
    }

    public var m_textColor: UIColor {
        return textColor!
    }

    public var m_autoCorrectionType: UITextAutocorrectionType {
        get {
            return autocorrectionType
        }
        set {
            autocorrectionType = newValue
        }
    }

    public var m_typingAttributes: [String : AnyObject]? {
        get {
            return typingAttributes
        }
        set {
            typingAttributes = newValue!
        }
    }
}

extension AttributedTextContainingView {
    mutating func configureDefaultAttributedText() -> NSAttributedString {
        m_attributedText = m_attributedText ?? NSAttributedString(string: m_text, attributes: [NSFontAttributeName : m_font, NSForegroundColorAttributeName : m_textColor])
        return m_attributedText!
    }
}

///  The MentionController class provides a simple interface for rendering @mentions and #hashtag comments on UILabel, UITextField, and UITextView.
///  To handle user taps on an @mentioin or #hashtag you must conform to the MentionTapHandlerDelegate protocol and set the delegate on MentionController.
///  Note: MentionController is built to be compatible objective C.
public class MentionController<T: UIView where T: AttributedTextContainingView>: NSObject, MentionTapHandlerDelegate {

    var view: AttributedTextContainingView
    weak var delegate: MentionTapHandlerDelegate?
    private var tapHandler: MentionTapHandler<T>!
    private let mentionDecoder: MentionDecoder

    // MARK: Init

    /**
    Public initializer for MentionController.

    - parameter view:     A `UIView` that conforms to `AttributedTextContainingView` and `CharacterFinder`
    - parameter delegate: An object that conforms to MentionTapHandlerDelegate

    - returns: An instance of MentionController
    */
    public convenience init(var view: T, delegate: MentionTapHandlerDelegate?) {
        let attributedString = view.configureDefaultAttributedText()
        self.init(view: view, inputString: attributedString, delegate: delegate)
    }

    private init(view: T, inputString: NSAttributedString, delegate: MentionTapHandlerDelegate?) {
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
public class MentionUser: NSObject {
    
    public let name: String
    public let id: Int
    public let imageURL: String?
    
    public init(name: String, id: Int, imageURL: String?) {
        self.name = name
        self.id = id
        self.imageURL = imageURL
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

public class MentionComposer<T: UIView where T: ComposableAttributedTextContainingView>: NSObject, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource {

    private let MentionCellIdentifier = "MentionCellReuseIdentifier"
    private var MentionRegexString: String {
        return "\\\(MentionCharacter)[^\\\(MentionCharacter).+]+"
    }

    var view: T?
    var tableView: UITableView?
    var delegate: MentionComposerDelegate?
    private var mentionRange: NSRange?
    private var tapRecognizer: UITapGestureRecognizer!
    private let originalAutoCorrectionType: UITextAutocorrectionType!
    private var userNameMatches: [MentionUser]?
    private var previousCharacterCount = 0

    private var mentionCache = [Int : Int]()

    private var recentCharacterRange: NSRange {
        guard let
            beginning = view?.beginningOfDocument,
            selectedRange = view?.selectedTextRange,
            location = view?.offsetFromPosition(beginning, toPosition: selectedRange.start),
            length = view?.offsetFromPosition(selectedRange.start, toPosition: selectedRange.end)
            else { return NSRange(location: 0, length: 0) }

        return NSRange(location: location - 1, length: length + 1)
    }

    /// Returns the text encoded for the API
    var encodedText: String? {
        guard let attributedText = view?.m_attributedText else { return view?.m_text }
        let encodedText = NSMutableAttributedString(attributedString: attributedText)

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

        guard let attributedText = view?.m_attributedText else { return ids }

        attributedText.enumerateAttribute(MentionAttributes.UserId, inRange: NSRange(location: 0, length: attributedText.length), options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
            if let id = value as? Int {
                ids.append(id)
            }
        }

        return ids
    }

    public init(view: T, searchResultsTableView tableView: UITableView, delegate: MentionComposerDelegate?) {
        self.view = view
        self.view?.configureDefaultAttributedText()
        self.tableView = tableView
        self.delegate = delegate
        self.originalAutoCorrectionType = view.autocorrectionType
        super.init()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerNib(UINib(nibName: "MentionTableViewCell", bundle: NSBundle(forClass: MentionTableViewCell.self)), forCellReuseIdentifier: MentionCellIdentifier)
        tapRecognizer = UITapGestureRecognizer(target: self, action: "tableViewTapped:")
        tapRecognizer.delegate = self
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delaysTouchesEnded = false
        tableView.addGestureRecognizer(tapRecognizer)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textChanged", name: UITextFieldTextDidChangeNotification, object: view)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textChanged", name: UITextViewTextDidChangeNotification, object: view)
    }

    // MARK: UITableViewDataSource

    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userNameMatches?.count ?? 0
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(MentionCellIdentifier, forIndexPath: indexPath) as! MentionUserCell
        let user = userNameMatches?[indexPath.row]
        cell.mentionUser = user

        return cell as! UITableViewCell
    }

    public func setCellClass<U: UITableViewCell where U: MentionUserCell>(cellClass: U.Type) {
        tableView?.registerClass(cellClass, forCellReuseIdentifier: MentionCellIdentifier)
    }

    // MARK: UTableViewDelegate

    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MentionTableViewCell
        if let user = cell.mentionUser {
            injectMention(forUser: user)
            userNameMatches = nil
            refreshTableView()
        }

        view?.becomeFirstResponder()
    }

    // MARK: Private methods

    private func mentionQuery(fromString string: NSString) -> NSString? {
        var query: NSString?

        do {
            let regex = try NSRegularExpression(pattern: MentionRegexString, options: .CaseInsensitive)

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
        view?.m_attributedText = attributedText

        guard let
            beginning = view?.beginningOfDocument,
            position = view?.positionFromPosition(beginning, offset: cursorLocation)
            else { return }

        view?.selectedTextRange = view?.textRangeFromPosition(position, toPosition: position)
        textChanged()
    }

    private func injectMention(forUser user: MentionUser) {
        guard let attributedText = view?.m_attributedText,
            font = view?.m_font
            else { return }

        let text = NSMutableAttributedString(attributedString: attributedText)
        let mutableEncodedString = NSMutableAttributedString(attributedString: user.encodedAttributedString())
        mutableEncodedString.addAttributes([NSFontAttributeName : font, NSForegroundColorAttributeName : MentionColor], range: NSRange(location: 0, length: mutableEncodedString.length))
        text.replaceCharactersInRange(mentionRange!, withAttributedString: mutableEncodedString)
        mentionCache[user.id] = mutableEncodedString.length
        let typingAttributes = view?.m_typingAttributes
        setAttributedText(text, cursorLocation: mentionRange!.location + mutableEncodedString.length)
        view?.m_typingAttributes = typingAttributes
        delegate?.userDidComposeMention?()
    }

    private func rangeOfMention(atIndex index: Int) -> NSRange? {
        var mentionRange: NSRange?
        let currentRange = NSRange(location: index, length: 1)
        guard let attributedText = view?.m_attributedText else { return mentionRange }

        attributedText.enumerateAttribute(MentionAttributes.Encoded, inRange: NSRange(location: 0, length: attributedText.length), options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
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
        guard let attributedText = view?.m_attributedText else { return }
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        mutableText.deleteCharactersInRange(range)
        setAttributedText(mutableText, cursorLocation: range.location)
    }

    private func refreshTableView() {
        tableView?.reloadData()
        tableView?.hidden = userNameMatches?.count == 0
    }

    // MARK: UIGestureRecognizerDelegate

    func tableViewTapped(recognizer: UITapGestureRecognizer) {
        tableView?.becomeFirstResponder()
    }

    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        var shouldBegin = true
        if (gestureRecognizer == tapRecognizer) {
            if tableView?.isFirstResponder() == true {
                shouldBegin = false
            }
        }

        return shouldBegin
    }

    /**
     In order for some property changes to take effect on UITextView you must resignFirstResponder
     and then becomeFirstResponder. This method calls these methods back to back respectively.
     */
    private func refreshTextView() {
        let selectedRange = view?.selectedTextRange
        view?.resignFirstResponder()
        view?.becomeFirstResponder()
        view?.selectedTextRange = selectedRange
    }

    func textChanged() {
        guard let text = view?.m_text else { return }

        view?.m_attributedText?.enumerateAttribute(MentionAttributes.UserId, inRange: NSRange(location: 0, length: text.characters.count), options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
            guard let value = value as? Int else { return }
            if let length = self.mentionCache[value] where length != range.length + 1 {
                self.deleteMention(inRange: range)
                self.mentionCache.removeValueForKey(value)
                stop.memory = true
            }
        }

        if let query = mentionQuery(fromString: text) {
            if let userNames = delegate?.usersMatchingQuery(searchQuery: query as String) {
                self.userNameMatches = userNames
                refreshTableView()
            }
        }
        else {
            userNameMatches = nil
            tableView?.reloadData()
            tableView?.hidden = true
        }

        if userNameMatches?.count > 0 {
            if view?.m_autoCorrectionType != .No {
                view?.m_autoCorrectionType = .No
                refreshTextView()
            }
        }
        else if view?.m_autoCorrectionType != originalAutoCorrectionType {
            view?.m_autoCorrectionType = originalAutoCorrectionType
            refreshTextView()
        }

        previousCharacterCount = (view?.m_attributedText?.string.characters.count)!
    }

}

public protocol MentionUserCell {
    var mentionUser: MentionUser? { get set }
}

/**
*  The primary purpose MentionComposerDelegate is to provide the list of users matching an @mention query.
*  Because TextViewMentionComposer relies on the UITextViewDelegate callbacks, it forwards all of them onto the MentionComposerDelegate.
*/
@objc public protocol MentionComposerDelegate {
   
    func usersMatchingQuery(searchQuery query: String) -> [MentionUser]
    
    optional func userDidComposeMention()
}

// MARK: - Decoding

/**
*  A protocol for classes or structs that decode @mentions, tags, or more.
*/
public protocol TagDecoder {
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
    let tagColor        = MentionColor
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
private class MentionTapHandler<T: UIView where T: AttributedTextContainingView>: NSObject {

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
