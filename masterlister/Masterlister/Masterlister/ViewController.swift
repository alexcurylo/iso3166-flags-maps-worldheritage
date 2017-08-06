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
    
    struct Tentative: Codable {
        let id_no: String
        let iso: String
        let submitted: String
        let name: String
    }

    let tentatives: [Tentative] = {
        let path = Bundle.main.path(forResource: "whtl-20170806", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let jsonArray = try! JSONDecoder().decode([Tentative].self, from: data)
        let array = jsonArray.sorted { (lhs, rhs) in
            lhs.id_no < rhs.id_no
        }
        //assert(array.count == 1669, "Should be 1669 TWHS on 2017.08.06")
        return array
    }()

    @IBOutlet var output: NSTextView!
    
    var whsVisited = 0
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

    func pageExists(at url: URL) -> Bool {
        // Disable online check for construction testing
        return true
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        var response: URLResponse?
        try! NSURLConnection.sendSynchronousRequest(request,
                                                    returning: &response)
        let httpResponse = response as! HTTPURLResponse
        if httpResponse.statusCode != 200 { return false }
        if httpResponse.url != url { return false }
        return true
    }

    func writeCountries() {
        for country in countries {
            let countryLink = "http://whc.unesco.org/en/statesparties/\(country.alpha2)/"
            
            // TODO: Filter construction by http://www.unesco.org/eri/cp/ListeMS_Indicators.asp
            guard pageExists(at: URL(string: countryLink)!) else {
                //print("Should have filtered out " + country.name)
                continue
            }
            
            let countryStart = NSAttributedString(string: """
                <p dir='ltr'><strong><a href="\(countryLink)">\(country.name)</a></strong><br />\n
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

        let twhsSites = tentatives.filter {
            $0.iso.contains(country.alpha2.lowercased())
        }

        guard !whsSites.isEmpty || !twhsSites.isEmpty else {
            let countryStart = NSAttributedString(string: """
                <em>no inscribed or tentative sites yet!</em><br />\n
                """)
            output.textStorage?.append(countryStart)
            return
        }
        
        for whs in whsSites {
            let whsLine = NSAttributedString(string: """
                <a href="http://whc.unesco.org/en/list/\(whs.id_no)">\(whs.name_en)</a> (\(whs.date_inscribed))<br />\n
                """)
            output.textStorage?.append(whsLine)
        }
        
        for twhs in twhsSites {
            let twhsLine = NSAttributedString(string: """
                <em><a href="http://whc.unesco.org/en/tentativelists/\(twhs.id_no)">\(twhs.name)</a> (\(twhs.submitted))</em><br />\n
                """)
            output.textStorage?.append(twhsLine)
        }
    }

    func writeFooter(for type: Document) {
        let total = sites.count + tentatives.count

        #if TODO_IMPLEMENT_VISITED
        let visited = whsVisited + twhsVisited
        let percent = total > 0 ? Double(visited / total) : 100
        let textFooter = NSAttributedString(string: """
            
            <p dir="ltr">WHS visited: \(whsVisited)/\(sites.count) — TWHS visited: \(twhsVisited)/\(tentatives.count) — TOTAL: \(visited)/\(total) (\(percent)%)</p>\n
            """)
        #else
        let textFooter = NSAttributedString(string: """
            
            <p dir="ltr">WHS: \(sites.count) — TWHS: \(tentatives.count) — TOTAL: \(total)</p>\n
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

