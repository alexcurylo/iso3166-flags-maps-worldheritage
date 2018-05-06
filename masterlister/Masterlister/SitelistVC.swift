//
//  ViewController.swift
//  Masterlister
//
//  Created by Curylo, Alex (Agoda) on 7/20/17.
//  Copyright © 2017 Trollwerks Inc. All rights reserved.
//

import Cocoa

class SitelistVC: NSViewController {

    enum Visited: String {
        case yes = "✅"
        case no = "◻️"
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
    
    struct Member: Codable {
        let iso: String
        let name: String
        let joined: String
        let region: String
    }

    let members: [Member] = {
        let path = Bundle.main.path(forResource: "unesco_members", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let array = try! JSONDecoder().decode([Member].self, from: data)
        assert(array.count == 205, "Should be 195 states and 10 associates in 2017")
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

        var id: Int {
            return Int(id_no) ?? 0
        }
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
        let category: String

        var id: Int {
            return Int(id_no) ?? 0
        }
    }

    let tentatives: [Tentative] = {
        let path = Bundle.main.path(forResource: "whtl-20170806", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let jsonArray = try! JSONDecoder().decode([Tentative].self, from: data)
        let array = jsonArray.sorted { (lhs, rhs) in
            lhs.id_no < rhs.id_no
        }
        // Contrary to http://whc.unesco.org/en/tentativelists/
        // there does, in fact, appear to be 1696
        //assert(array.count == 1669, "Should be 1669 TWHS on 2017.08.06")
        return array
    }()

    struct Visit: Codable {
        let wonder: Int?
        let whs: Int?
        let twhs: Int?
        let visit: URL?
        let stay: URL?
        let eat: URL?
    }
    
    lazy var visits: [Visit] = {
        let path = Bundle.main.path(forResource: "visits", ofType: "json")
        var array: [Visit] = []
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path!))
            array = try JSONDecoder().decode([Visit].self, from: data)
        } catch let jsonErr {
            print("Error decoding visits", jsonErr)
        }
        return array
    }()
    lazy var whsVisits: [Visit] = {
        let array = visits.filter { $0.whs != nil }
        let ids = array.compactMap { $0.whs }
        let duplicates = Array(Set(ids.filter({ (i: Int) in ids.filter({ $0 == i }).count > 1})))
        assert(duplicates.isEmpty, "Should not have duplicate WHS visits \(duplicates)")
        return array
    }()
    lazy var twhsVisits: [Visit] = {
        let array = visits.filter { $0.twhs != nil }
        let ids = visits.compactMap { $0.twhs }
        let duplicates = Array(Set(ids.filter({ (i: Int) in ids.filter({ $0 == i }).count > 1})))
        assert(duplicates.isEmpty, "Should not have duplicate TWHS visits \(duplicates)")
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
            
            <p>Inscribed properties are in plain text<br />
            <i>Tentative properties are in italic text</i></p>
            \n
            """)
        output.textStorage?.append(textHeader)
    }

    func pageExists(at url: URL) -> Bool {
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
            guard members.contains(where: { country.alpha2 == $0.iso } ) else {
                //print("Filtering out " + country.name)
                continue
            }
            
            let countryLink = "http://whc.unesco.org/en/statesparties/\(country.alpha2)/"
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
            $0.iso.contains(country.alpha2)
        }

        guard !whsSites.isEmpty || !twhsSites.isEmpty else {
            let countryStart = NSAttributedString(string: """
                <i>no inscribed or tentative sites yet!</i><br />\n
                """)
            output.textStorage?.append(countryStart)
            return
        }

        for whs in whsSites {
            let link = """
                <a href="http://whc.unesco.org/en/list/\(whs.id_no)">\(whs.name_en)</a>
                """

            var mark = Visited.no.rawValue
            var visitLink = ""
            var stayLink = ""
            var eatLink = ""
            if let visited = whsVisits.first(where: { $0.whs == whs.id }) {
                whsVisited = whsVisited + 1
                mark = Visited.yes.rawValue
                if let visitURL = visited.visit {
                    visitLink = " — <a href=\"\(visitURL)\">Visit</a>"
                }
                if let stayURL = visited.stay {
                    stayLink = " — <a href=\"\(stayURL)\">Stay</a>"
                }
                if let eatURL = visited.eat {
                    eatLink = " — <a href=\"\(eatURL)\">Eat</a>"
                }
            }

            let whsLine = NSAttributedString(string: "\(mark) \(link)\(visitLink)\(stayLink)\(eatLink)<br />\n")
            output.textStorage?.append(whsLine)
        }

        if !twhsSites.isEmpty {
            output.textStorage?.append(NSAttributedString(string: "<i>"))
    
            for twhs in twhsSites {
                let link = """
                    <a href="http://whc.unesco.org/en/tentativelists/\(twhs.id_no)">\(twhs.name)</a>
                    """

                var mark = Visited.no.rawValue
                var visitLink = ""
                var stayLink = ""
                var eatLink = ""
                if let visited = twhsVisits.first(where: { $0.twhs == twhs.id }) {
                    twhsVisited = twhsVisited + 1
                    mark = Visited.yes.rawValue
                    if let visitURL = visited.visit {
                        visitLink = " — <a href=\"\(visitURL)\">Visit</a>"
                    }
                    if let stayURL = visited.stay {
                        stayLink = " — <a href=\"\(stayURL)\">Stay</a>"
                    }
                    if let eatURL = visited.eat {
                        eatLink = " — <a href=\"\(eatURL)\">Eat</a>"
                    }
                }

                let twhsLine = NSAttributedString(string: "\(mark) \(link)\(visitLink)\(stayLink)\(eatLink)<br />\n")
                output.textStorage?.append(twhsLine)
            }

            output.textStorage?.append(NSAttributedString(string: "</i>"))
        }
    }

    func writeFooter(for type: Document) {
        //assert(whsVisited == 16, "Should be 16 wonders visited (2018.05.05)")
        //assert(twhsVisited == 40, "Should be 40 finalists visited (2018.05.05)")

        let whsPercent = String(format: "%.1f", Float(whsVisited) / Float(sites.count) * 100)
        let twhsPercent = String(format: "%.1f", Float(twhsVisited) / Float(tentatives.count) * 100)

        let total = sites.count + tentatives.count
        let totalVisits = whsVisited + twhsVisited
        let totalPercent = String(format: "%.1f", Float(totalVisits) / Float(tentatives.count) * 100)
        let textFooter = NSAttributedString(string: """
            <p dir="ltr">WHS: \(whsVisited)/\(sites.count) (\(whsPercent)%) — TWHS: \(twhsVisited)/\(tentatives.count) (\(twhsPercent)%) — TOTAL: \(totalVisits)/\(total) (\(totalPercent)%)</p>\n
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

