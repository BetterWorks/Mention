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

        textFieldMentionComposer = MentionComposer<UITextField>(view: textField, searchResultsTableView: tableView, delegate: nil)
        textViewMentionComposer = MentionComposer<UITextView>(view: textView, searchResultsTableView: tableView, delegate: nil)
    }

}

