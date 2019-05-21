//
//  ViewController.swift
//  JsonSyntaxExample
//
//  Created by Oleg Ketrar on 20/05/2019.
//  Copyright © 2019 Oleg Ketrar. All rights reserved.
//

import UIKit
import JsonSyntax

final class ViewController: UIViewController {

    private let codeView = CodeView(frame: .zero).with {
        $0.setTheme(.default)
        $0.setCode(sampleJson)
        $0.layer.cornerRadius = 5
        $0.layer.masksToBounds = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        codeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(codeView)

        NSLayoutConstraint.activate([
            codeView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            codeView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            codeView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            codeView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])

        view.backgroundColor = .white
        view.layoutIfNeeded()
    }
}

private let sampleJson: String = #"""
{
  "data" : {
    "isFreeDelivery": true,
    "price": 10,
    "currency": "EUR",
    "items" : [
      {
        "url": "https://www.autodoc.de/v6"
      }
    ]
  },
  "messages": {
    "error": null,
    "exception": {
      "title": "AAA",
      "code": 1002
    }
  },
  "success" : true
}
"""#
