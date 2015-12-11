//
//  MentionUserType.swift
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
