//
//  MentionComposer.swift
//  Pods
//
//  Created by Connor Smith on 12/10/15.
//
//

/// The primary purpose `MentionComposerDelegate` is to provide the list of users matching an @mention query.
public protocol MentionComposerDelegate: class {
    func usersMatchingQuery(query: String, handler: MentionUserClosure)
}

/// Defines a protocol for cells that have a property of type `MentionUserType`
public protocol MentionUserCell: class {
    var mentionUser: MentionUserType? { get set }
}

public typealias MentionUserClosure = (users: [MentionUserType]?) -> Void

/// Use MentionComposer to compose @mentions in any `UIView` that conforms to `ComposableAttributedTextContainingView`
public class MentionComposer<T: UIView where T: ComposableAttributedTextContainingView>: NSObject, UITableViewDelegate, UITableViewDataSource {

    private let MentionCellIdentifier = "MentionCellReuseIdentifier"
    private var MentionRegexString: String {
        return "\\\(MentionCharacter)[^\\\(MentionCharacter).+]+"
    }

    var view: T?
    var tableView: UITableView?
    weak var delegate: MentionComposerDelegate?
    private var mentionRange = NSRange(location: 0, length: 0)
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
