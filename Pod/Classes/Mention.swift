//
//  Mention.swift
//  BetterWorks
//
//  Created by Connor Smith on 11/25/14.
//  Copyright (c) 2014 BetterWorks. All rights reserved.
//

/**
*  The NSAttributesString attributes used to encode and decode @mentions
*/
struct MentionAttributes {
    static let UserId  = "MentionUserIdAttribute"
    static let Name    = "MentionNameAttribute"
    static let Encoded = "MentionEncodedAttribute"
}

public var MentionCharacter: Character = "@"
public var MentionColor                = UIColor.blueColor()
