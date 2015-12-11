//
//  MentionUserType.swift
//  Pods
//
//  Created by Connor Smith on 12/10/15.
//
//

/**
*  MentionUserType defines a protocol for model objects compatible with `MentionComposer`
*/
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
