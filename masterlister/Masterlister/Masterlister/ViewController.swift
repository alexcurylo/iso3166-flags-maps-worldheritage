//
//  ViewController.swift
//  Masterlister
//
//  Created by Curylo, Alex (Agoda) on 7/20/17.
//  Copyright © 2017 Trollwerks Inc. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    enum Visited: String {
        case yes = "✅"
        case no = "🔲"
    }

    enum Document {
        case html
        case wordpress
    }
    
    struct Country: Codable {
        let alpha2: String
        let alpha3: String
        let name: String
        let officialName: String
        let numeric: String
        // all except Kosovo
        let wikiUrl: URL?
        // Kosovo only
        let unofficial: Bool?
        let wikiEntry: URL?
    }

    let countries: [Country] = {
        let path = Bundle.main.path(forResource: "iso_3166-1", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let dict = try! JSONDecoder().decode([String: Country].self, from: data)
        let array = Array(dict.values).sorted { (lhs, rhs) in
            lhs.name < rhs.name
        }
        // TODO: Filter for UNESCO membership
        return array
    }()
    
    // NB whc-en has other fields:
    // historical_description, long_description
    // "http_url": "http://whc.unesco.org/en/list/208",
    // "image_url": "http://whc.unesco.org/uploads/sites/site_208.jpg",
    struct Site: Codable {
        let id_no: String
        let iso_code: String
        let category: String
        let region_en: String
        let date_inscribed: String
        let name_en: String
        let short_description_en: String
        let justification_en: String
    }
    
    let sites: [Site] = {
        let path = Bundle.main.path(forResource: "whc-sites-2017", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let jsonArray = try! JSONDecoder().decode([Site].self, from: data)
        let array = jsonArray.sorted { (lhs, rhs) in
            lhs.id_no < rhs.id_no
        }
        assert(array.count == 1073, "Should be 1073 WHS in 2017")
        return array
    }()

    @IBOutlet var output: NSTextView!
    
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
        let whsSites = sites.filter {
            $0.iso_code.contains(country.alpha2.lowercased())
        }

        let twhsSites = [String]()

        guard !whsSites.isEmpty || !twhsSites.isEmpty else {
            let countryStart = NSAttributedString(string: """
                <em>no inscribed or tentative sites yet!</em><br />\n
                """)
            output.textStorage?.append(countryStart)
            return
        }
        
        for whsSite in whsSites {
            let whsLine = NSAttributedString(string: """
                <a href="http://whc.unesco.org/en/list/\(whsSite.id_no)">\(whsSite.name_en)</a> (\(whsSite.date_inscribed))<br />\n
                """)
            output.textStorage?.append(whsLine)
        }
    }

    func writeFooter(for type: Document) {
        let total = sites.count + twhs

        #if TODO_IMPLEMENT_VISITED
        let visited = whsVisited + twhsVisited
        let percent = total > 0 ? Double(visited / total) : 100
        let textFooter = NSAttributedString(string: """
            
            <p dir="ltr">WHS visited: \(whsVisited)/\(sites.count) — TWHS visited: \(twhsVisited)/\(twhs) — TOTAL: \(visited)/\(total) (\(percent)%)</p>\n
            """)
        #else
        let textFooter = NSAttributedString(string: """
            
            <p dir="ltr">WHS: \(sites.count) — TWHS: \(twhs) — TOTAL: \(total)</p>\n
            """)
        #endif
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

