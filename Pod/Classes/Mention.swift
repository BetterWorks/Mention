//
//  Mention.swift
//  BetterWorks
//
//  Created by Connor Smith on 11/25/14.
//  Copyright (c) 2014 BetterWorks. All rights reserved.
//

import Foundation

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

extension AttributedTextContainingView {
    mutating func configureDefaultAttributedText() {
        m_attributedText = m_attributedText ?? defaultAttributedText
    }

    var defaultAttributedText: NSAttributedString {
        return NSAttributedString(string: m_text, attributes: [NSFontAttributeName : m_font, NSForegroundColorAttributeName : m_textColor])
    }
}

// MARK: - Decoding

// MARK: - MentionDecoder

///  The MentionDecoder class provides a simple interface for rendering @mentions and #hashtag comments on UILabel, UITextField, and UITextView.
///  To handle user taps on an @mentioin or #hashtag you must conform to the MentionTapHandlerDelegate protocol and set the delegate on MentionDecoder.
///  Note: MentionDecoder is built to be compatible objective C.
public struct MentionDecoder<T: UIView where T: AttributedTextContainingView> {

    private let Pattern         = "\\[\\\(MentionCharacter).+?\\:[0-9]+\\]"
    private let UserIdSignifier = ":"

    var view: AttributedTextContainingView
    private var tapHandler: MentionTapHandler<T>!

    // MARK: Init

    /**
    Public initializer for MentionDecoder.

    - parameter view:     A `UIView` that conforms to `AttributedTextContainingView` and `CharacterFinder`
    - parameter delegate: An object that conforms to MentionTapHandlerDelegate

    - returns: An instance of MentionDecoder
    */
    
    public init(view: T, delegate: MentionTapHandlerDelegate?) {
        self.view = view

        // Decode
        decode()

        // Handle Taps
        tapHandler = MentionTapHandler(view: view, delegate: delegate)
    }

    /**
    Find all instances of @mentions within the view and replace them with a human readable mention
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
        
        self.view.m_attributedText = NSAttributedString(attributedString: mutableDecodedString)
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

// MARK: - Mention Composition

// MARK: - MentionUserType

public protocol MentionUserType {
    var name: String { get }
    var id: Int { get }

    func encodedNameForAPI() -> String
}

public extension MentionUserType {
    func encodedNameForAPI() -> String {
        return "@\(name)"
    }
}

extension MentionUserType {
    var humanReadableMentionString: NSAttributedString {
        let attributedString = NSMutableAttributedString(string: name, attributes: [
            MentionAttributes.Encoded : encodedNameForAPI(),
            MentionAttributes.Name: name,
            MentionAttributes.UserId : id,
            ])
        attributedString.appendAttributedString(NSAttributedString(string: " "))
        return attributedString as NSAttributedString
    }
}

// MARK: - MentionComposer

/**
 *  The primary purpose MentionComposerDelegate is to provide the list of users matching an @mention query.
 *  Because TextViewMentionComposer relies on the UITextViewDelegate callbacks, it forwards all of them onto the MentionComposerDelegate.
 */
public protocol MentionComposerDelegate: class {
    func usersMatchingQuery(query: String, handler: MentionUserClosure)
}

public protocol MentionUserCell: class {
    var mentionUser: MentionUserType? { get set }
}

public typealias MentionUserClosure = (users: [MentionUserType]?) -> Void

public class MentionComposer<T: UIView where T: ComposableAttributedTextContainingView>: NSObject, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource {

    private let MentionCellIdentifier = "MentionCellReuseIdentifier"
    private var MentionRegexString: String {
        return "\\\(MentionCharacter)[^\\\(MentionCharacter).+]+"
    }

    var view: T?
    var tableView: UITableView?
    weak var delegate: MentionComposerDelegate?
    private var mentionRange = NSRange(location: 0, length: 0)
    private var tapRecognizer: UITapGestureRecognizer!
    private let originalTextColor: UIColor
    private var userNameMatches = [MentionUserType]()
    private var lengthOfMentionPerId = [Int : Int]()

    /// Returns the range of the most recently typed character
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
    public var encodedText: String? {
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
    public var mentionIds: [Int] {
        var ids = [Int]()

        guard let attributedText = view?.m_attributedText else { return ids }

        attributedText.enumerateAttribute(MentionAttributes.UserId, inRange: NSRange(location: 0, length: attributedText.length), options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
            if let id = value as? Int {
                ids.append(id)
            }
        }

        return ids
    }

    /// A custom `UINib` to be used by `tableView`.
    /// - note: Do not set in conjunction with `cellClass`
    public var nib: UINib? {
        didSet {
            tableView?.registerNib(nib, forCellReuseIdentifier: MentionCellIdentifier)
        }
    }

    /// A custom `UITableViewCell` class to be used by `tableView`.
    /// - note: Do not set in conjunction with `nib`
    public var cellClass: MentionUserCell.Type? {
        didSet {
            tableView?.registerClass(cellClass, forCellReuseIdentifier: MentionCellIdentifier)
        }
    }

    public init(view: T, searchResultsTableView tableView: UITableView, delegate: MentionComposerDelegate?) {
        self.view = view
        self.view?.configureDefaultAttributedText()
        self.tableView = tableView
        self.delegate = delegate
        self.originalTextColor = view.m_textColor
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

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: UITableViewDataSource

    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userNameMatches.count
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MentionCellIdentifier, forIndexPath: indexPath) as? MentionUserCell
        let user = userNameMatches[indexPath.row]
        cell?.mentionUser = user

        return cell as? UITableViewCell ?? UITableViewCell()
    }

    public func setCellClass<U: UITableViewCell where U: MentionUserCell>(cellClass: U.Type) {
        tableView?.registerClass(cellClass, forCellReuseIdentifier: MentionCellIdentifier)
    }

    // MARK: UTableViewDelegate

    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let
            cell = tableView.cellForRowAtIndexPath(indexPath) as? MentionUserCell,
            user = cell.mentionUser
            else { return }

        injectMention(forUser: user)
        userNameMatches.removeAll()
        refreshTableView()

        view?.becomeFirstResponder()
    }

    // MARK: Private methods

    private func mentionQuery(fromString string: NSString) -> NSString? {
        var query: NSString?
        guard let regex = try? NSRegularExpression(pattern: MentionRegexString, options: .CaseInsensitive) else { return query }
        let range = NSRange(location: 0, length: string.length)
        let matches = regex.matchesInString(string as String, options: .ReportCompletion, range: range)
        for match in matches {
            // Match must be contained in the text the user most recently changed
            if NSIntersectionRange(match.range, recentCharacterRange).length > 0 {
                mentionRange = NSRange(location: match.range.location, length: match.range.length)
                query = string.substringWithRange(mentionRange) as NSString
                query = query?.substringFromIndex(1)
            }
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

    private func injectMention(forUser user: MentionUserType) {
        guard let attributedText = view?.m_attributedText,
            font = view?.m_font
            else { return }

        let text = NSMutableAttributedString(attributedString: attributedText)
        let encodedMentionString = NSMutableAttributedString(attributedString: user.humanReadableMentionString)
        encodedMentionString.addAttributes([NSFontAttributeName : font, NSForegroundColorAttributeName : MentionColor], range: NSRange(location: 0, length: encodedMentionString.length))
        text.replaceCharactersInRange(mentionRange, withAttributedString: encodedMentionString)
        lengthOfMentionPerId[user.id] = encodedMentionString.length
        let typingAttributes = view?.m_typingAttributes
        setAttributedText(text, cursorLocation: mentionRange.location + encodedMentionString.length)
        view?.m_typingAttributes = typingAttributes
        view?.m_typingAttributes?[NSForegroundColorAttributeName] = originalTextColor
    }

    private func deleteMention(inRange range: NSRange) {
        guard let attributedText = view?.m_attributedText else { return }
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        mutableText.deleteCharactersInRange(range)
        setAttributedText(mutableText, cursorLocation: range.location)
    }

    private func refreshTableView() {
        tableView?.reloadData()
        tableView?.hidden = userNameMatches.count == 0
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

    func textChanged() {
        guard let
            text = view?.m_text,
            attributedString = view?.m_attributedText
            else { return }

        // Delete mentions if either of the following conditions are met:
        // 1. A character in the mention was deleted
        // 2. A character was added within the range of the mention
        var removedMentionIds = Set<Int>()
        view?.m_attributedText?.enumerateAttribute(MentionAttributes.UserId, inRange: NSRange(location: 0, length: text.characters.count), options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
            guard let value = value as? Int else { return }

            if let length = self.lengthOfMentionPerId[value] where length != range.length + 1 {
                removedMentionIds.insert(value)
                self.deleteMention(inRange: range)
            }
        }

        for mentionId in removedMentionIds {
            self.lengthOfMentionPerId.removeValueForKey(mentionId)
        }

        // When typing a character immediately adjacent to or within the range of a mention, the character will automatically be given the styling of a mention (text color and font).
        // Here we restore that character to the non-mention styling.
        var rangeToUpdate: NSRange?
        view?.m_attributedText?.enumerateAttribute(NSForegroundColorAttributeName, inRange: NSRange(location: 0, length: text.characters.count), options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (value, range, stop) -> Void in
            guard let color = value as? UIColor where color == MentionColor else { return }
            var effectiveRange = NSRange(location: 0, length: 20)
            guard let attributes = self.view?.m_attributedText?.attributesAtIndex(range.location, effectiveRange: &effectiveRange) where !attributes.keys.contains(MentionAttributes.Encoded) else { return }
            rangeToUpdate = effectiveRange
            stop.memory = true
        }

        if let range = rangeToUpdate {
            let mutableString = NSMutableAttributedString(attributedString: attributedString)
            mutableString.addAttribute(NSForegroundColorAttributeName, value: self.originalTextColor, range: range)
            setAttributedText(mutableString, cursorLocation: recentCharacterRange.location + 1)
        }

        // Check for a mention query
        if let query = mentionQuery(fromString: text) {
            delegate?.usersMatchingQuery(query as String) { [weak self] (users) -> Void in
                if let users = users {
                    self?.userNameMatches = users
                    self?.refreshTableView()
                }
            }
        }
        else {
            userNameMatches.removeAll()
            refreshTableView()
        }
        
        view?.m_typingAttributes?[NSForegroundColorAttributeName] = originalTextColor
    }
    
}
