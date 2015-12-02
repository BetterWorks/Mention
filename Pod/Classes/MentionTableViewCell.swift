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
    @IBOutlet weak var userImageView: UIImageView!
    
    var mentionUser: MentionUser? {
        didSet {
            setup()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = CGRectGetHeight(userImageView.bounds) / 2
        userImageView.clipsToBounds = true
        reset()
    }
    
    func reset() {
        userNameLabel?.text = nil
    }
    
    func setup() {
        userNameLabel?.text = mentionUser!.name
//        userImageView.setImageFromURL(mentionUser!.imageURL, styleActivityIndicator: .Gray)
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
//        contentView.backgroundColor = highlighted ? UIColor.betterWorksBlue() : UIColor.whiteColor()
//        userNameLabel.textColor = highlighted ? UIColor.whiteColor() : UIColor.betterWorksDarkTextColor()
    }
    
}
