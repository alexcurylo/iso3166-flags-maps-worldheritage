//
//  ViewController.swift
//  Masterlister
//
//  Created by Curylo, Alex (Agoda) on 7/20/17.
//  Copyright © 2017 Trollwerks Inc. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    enum Document {
        case html
        case wordpress
    }
    
    struct Country: Codable {
        var alpha2: String
        var alpha3: String
        var name: String
        var officialName: String
        var numeric: String
        // all except Kosovo
        var wikiUrl: URL?
        // Kosovo only
        var unofficial: Bool?
        var wikiEntry: URL?
    }

    let countries: [Country] = {
        let path = Bundle.main.path(forResource: "iso_3166-1", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let dict = try! JSONDecoder().decode([String: Country].self, from: data)
        let array = Array(dict.values).sorted { (lhs, rhs) in
            lhs.name < rhs.name
        }
        return array
    }()
    
    @IBOutlet var output: NSTextView!
    
    var whs = 0
    var whsVisited = 0
    var twhs = 0
    var twhsVisited = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        generate(for: .wordpress)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func generate(for type: Document) {
        writeHeader(for: type)
        writeCountries()
        writeFooter(for: type)
    }
    
    func writeHeader(for type: Document) {
        if type == .html {
            let htmlHeader = NSAttributedString(string: """
                <!DOCTYPE html>
                <html lang="en">
                    <head>
                        <meta charset="UTF-8">
                            <title>Sitelist</title>
                    </head>
                    <body>\n
                """)
            output.textStorage?.append(htmlHeader)
        }
        
        let textHeader = NSAttributedString(string: """
            <p dir="ltr"><strong>The UNESCO World Heritage Site Master Sitelist</strong></p>
            
            <p>Inscribed properties are in plain text with (year of inscription)<br />
            <i>Tentative properties are in italic text with (date of submission)</i></p>
            \n
            """)
        output.textStorage?.append(textHeader)
    }

    func writeCountries() {
        for country in countries {
            let countryStart = NSAttributedString(string: """
                <p dir='ltr'><strong>\(country.name)</strong><br />\n
                """)
            output.textStorage?.append(countryStart)

            writeSites(in: country)

            let countryEnd = NSAttributedString(string: """
                </p>
                \n
                """)
            output.textStorage?.append(countryEnd)
        }
    }

    func writeSites(in country: Country) {
        let whsSites = [String]()
        let twhsSites = [String]()

        guard !whsSites.isEmpty || !twhsSites.isEmpty else {
            let countryStart = NSAttributedString(string: """
                <em>no inscribed or tentative sites yet!</em><br />\n
                """)
            output.textStorage?.append(countryStart)
            return
        }
    }

    func writeFooter(for type: Document) {
        let total = whs + twhs
        let visited = whsVisited + twhsVisited
        let percent = total > 0 ? Double(visited / total) : 100
        let textFooter = NSAttributedString(string: """
            
            <p dir="ltr">WHS visited: \(whsVisited)/\(whs) — TWHS visited: \(twhsVisited)/\(whs) — TOTAL: \(visited)/\(total) (\(percent)%)</p>\n
            """)
        output.textStorage?.append(textFooter)

        if type == .html {
            let htmlFooter = NSAttributedString(string: """
                    </body>
                </html>
                """)
            output.textStorage?.append(htmlFooter)
        }
    }
}

