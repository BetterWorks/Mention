//
//  MentionTableViewCell.swift
//  BetterWorks
//
//  Created by Connor Smith on 12/22/14.
//  Copyright (c) 2014 BetterWorks. All rights reserved.
//

import UIKit

class MentionTableViewCell: UITableViewCell, MentionUserCell {

    @IBOutlet private weak var userNameLabel: UILabel!
    
    var mentionUser: MentionUserType? {
        didSet {
            userNameLabel?.text = mentionUser?.name
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        reset()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }

    private func reset() {
        userNameLabel?.text = nil
    }
    
}
