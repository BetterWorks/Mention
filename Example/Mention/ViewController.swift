//
//  ViewController.swift
//  Mention
//
//  Created by Connor Smith on 10/17/2015.
//  Copyright (c) 2015 Connor Smith. All rights reserved.
//

import UIKit
import Mention

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!

    private var textFieldMentionComposer: MentionComposer<UITextField>?
    private var textViewMentionComposer: MentionComposer<UITextView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        textFieldMentionComposer = MentionComposer<UITextField>(view: textField, searchResultsTableView: tableView, delegate: self)
//        textViewMentionComposer = MentionComposer<UITextView>(view: textView, searchResultsTableView: tableView, delegate: self)
    }

}

struct MentionUser: MentionUserType {
    var name: String
    var id: Int
}

extension ViewController: MentionComposerDelegate {
    func usersMatchingQuery(query: String, handler: MentionUserClosure) {
        // add delay to simulate network response time in the UI
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            handler(users: [MentionUser(name: "test user", id: 0)])
        }
    }
}
