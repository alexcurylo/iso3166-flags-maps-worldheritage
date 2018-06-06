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
        assert(array.count == 206, "Should be 195 states and 10 associates and 1 observer (VA) in 2017")
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
            lhs.name_en < rhs.name_en
        }
        assert(array.count == 1073, "Should be 1073 WHS in 2017")
        return array
    }()
    
    struct Tentative: Codable {
        let id_no: Int
        let iso: String
        let submitted: String
        let name: String
        let category: String

        var id: Int {
            return id_no
        }
    }

    let tentatives: [Tentative] = {
        let path = Bundle.main.path(forResource: "whtl-20180507", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let jsonArray = try! JSONDecoder().decode([Tentative].self, from: data)
        let array = jsonArray.sorted { (lhs, rhs) in
            lhs.name < rhs.name
        }
        // Should match http://whc.unesco.org/en/tentativelists/
        assert(array.count == 1706, "Should be 1706 TWHS on 2018.05.07")

        return array
    }()

    struct Visit: Codable {
        let wonder: Int?
        let whs: Int?
        let twhs: Int?
        let visit: URL?
        let stay: URL?
        let eat: URL?

        //var validVisit: Bool {
            //guard let visit = visit else { return true }
            //guard URL(string: visit) != nil else {
                //return false
            //}
            //return true
        //}
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
        
        //array.forEach { _ = $0.validVisit }

        return array
    }()
    lazy var whsVisits: [Visit] = {
        let array = visits.filter { $0.whs != nil }
        let ids = array.compactMap { $0.whs }
        let duplicates = Array(Set(ids.filter({ (i: Int) in ids.filter({ $0 == i }).count > 1})))
        assert(duplicates.isEmpty, "Should not have duplicate WHS visits \(duplicates)")
        let wrong = Set(ids).subtracting(Set(sites.map( { $0.id } )))
        assert(wrong.isEmpty, "Should not have wrong WHS visits \(wrong)")
        return array
    }()
    lazy var twhsVisits: [Visit] = {
        let array = visits.filter { $0.twhs != nil }
        let ids = visits.compactMap { $0.twhs }
        let duplicates = Array(Set(ids.filter({ (i: Int) in ids.filter({ $0 == i }).count > 1})))
        assert(duplicates.isEmpty, "Should not have duplicate TWHS visits \(duplicates)")
        let wrong = Set(ids).subtracting(Set(tentatives.map( { $0.id } )))
        assert(wrong.isEmpty, "Should not have wrong TWHS visits \(wrong)")
        return array
    }()

    struct CountryFile: Codable {
        let iso: String
        let file: URL?
        let name: String? // for easily locating unfiled countries
    }

    lazy var countryFiles: [CountryFile] = {
        let path = Bundle.main.path(forResource: "country-files", ofType: "json")
        var array: [CountryFile] = []
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path!))
            array = try JSONDecoder().decode([CountryFile].self, from: data)
        } catch let jsonErr {
            print("Error decoding country files", jsonErr)
        }
        return array
    }()

    @IBOutlet var output: NSTextView!
    
    var whsVisited = Set<Int>()
    var twhsVisited = Set<Int>()
    
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
            
            <p><small>Inscribed properties are in plain text<br />
            <i>Tentative properties are in italic text</i></small></p>
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
                continue
            }

            var whsSites = sites.filter {
                $0.iso_code.contains(country.alpha2.lowercased())
            }
            // Special Jerusalem handling, put it in Israel
            if country.alpha2 == "IL" {
                let countryless = sites.filter() { $0.iso_code.isEmpty }
                assert(countryless.count == 1, "Not exactly Jerusalem without a country?")
                whsSites.append(countryless.first!)
            }

            let twhsSites = tentatives.filter {
                $0.iso.contains(country.alpha2)
            }

            let unescoURL = "http://whc.unesco.org/en/statesparties/\(country.alpha2)/"
            let unescoLink = """
                <a href="\(unescoURL)">\(country.name)</a>
                """
            var fileLink = ""
            if let file = countryFiles.first(where: { country.alpha2 == $0.iso })?.file {
                fileLink = " — <a href=\"\(file)\">Country File</a>"
            }
            let countryStart = NSAttributedString(string: "<p dir='ltr'><strong>\(unescoLink)</strong> <small>(\(whsSites.count) WHS, \(twhsSites.count) TWHS)\(fileLink)</small><br />\n")
            output.textStorage?.append(countryStart)

            writeSites(in: country, whs: whsSites, twhs: twhsSites)

            let countryEnd = NSAttributedString(string: """
                </p>
                \n
                """)
            output.textStorage?.append(countryEnd)
        }
    }

    func writeSites(in country: Country,
                    whs whsSites: [Site],
                    twhs twhsSites: [Tentative]) {

        guard !whsSites.isEmpty || !twhsSites.isEmpty else {
            let countryStart = NSAttributedString(string: """
                <i><small>no inscribed or tentative sites yet!</small></i><br />\n
                """)
            output.textStorage?.append(countryStart)
            return
        }

        for whs in whsSites {
            let link = """
                <a href="http://whc.unesco.org/en/list/\(whs.id_no)">\(whs.name_en)</a>
                """

            var mark = Visited.no.rawValue
            var blogLinks = ""
            if let visited = whsVisits.first(where: { $0.whs == whs.id }) {
                whsVisited.insert(whs.id)
                
                mark = Visited.yes.rawValue
                
                var visitLink = ""
                var stayLink = ""
                var eatLink = ""
                if let visitURL = visited.visit {
                    visitLink = " — <a href=\"\(visitURL)\">Visit</a>"
                }
                if let stayURL = visited.stay {
                    stayLink = " — <a href=\"\(stayURL)\">Stay</a>"
                }
                if let eatURL = visited.eat {
                    eatLink = " — <a href=\"\(eatURL)\">Eat</a>"
                }
                if !visitLink.isEmpty || !stayLink.isEmpty || !eatLink.isEmpty {
                    blogLinks = "<small>\(visitLink)\(stayLink)\(eatLink)</small>"
                }
            }

            let whsLine = NSAttributedString(string: "\(mark) \(link)\(blogLinks)<br />\n")
            output.textStorage?.append(whsLine)
        }

        if !twhsSites.isEmpty {
            output.textStorage?.append(NSAttributedString(string: "<i>"))
    
            for twhs in twhsSites {
                let link = """
                    <a href="http://whc.unesco.org/en/tentativelists/\(twhs.id_no)">\(twhs.name)</a>
                    """

                var mark = Visited.no.rawValue
                var blogLinks = ""
                if let visited = twhsVisits.first(where: { $0.twhs == twhs.id }) {
                    twhsVisited.insert(twhs.id)

                    mark = Visited.yes.rawValue

                    var visitLink = ""
                    var stayLink = ""
                    var eatLink = ""
                    if let visitURL = visited.visit {
                        visitLink = " — <a href=\"\(visitURL)\">Visit</a>"
                    }
                    if let stayURL = visited.stay {
                        stayLink = " — <a href=\"\(stayURL)\">Stay</a>"
                    }
                    if let eatURL = visited.eat {
                        eatLink = " — <a href=\"\(eatURL)\">Eat</a>"
                    }
                    if !visitLink.isEmpty || !stayLink.isEmpty || !eatLink.isEmpty {
                        blogLinks = "<small>\(visitLink)\(stayLink)\(eatLink)</small>"
                    }
                }

                let twhsLine = NSAttributedString(string: "\(mark) \(link)\(blogLinks)<br />\n")
                output.textStorage?.append(twhsLine)
            }

            output.textStorage?.append(NSAttributedString(string: "</i>"))
        }
    }

    func writeFooter(for type: Document) {
        assert(whsVisited.count == 482, "Should be 482 WHS visited not \(whsVisited.count) (2018.05.07)")
        assert(twhsVisited.count == 340, "Should be 340 TWHS visited not \(twhsVisited.count) (2018.05.07)")
        let updatesURL = "http://whc.unesco.org/en/tentativelists/?action=listtentative&pattern=&state=&theme=&criteria_restrication=&date_start=21%2F05%2F2018&date_end=&order=year"

        let whsPercent = String(format: "%.1f", Float(whsVisited.count) / Float(sites.count) * 100)
        let twhsPercent = String(format: "%.1f", Float(twhsVisited.count) / Float(tentatives.count) * 100)

        let total = sites.count + tentatives.count
        let totalVisits = whsVisited.count + twhsVisited.count
        let totalPercent = String(format: "%.1f", Float(totalVisits) / Float(total) * 100)
        let textFooter = NSAttributedString(string: """
            <p dir="ltr"><small>WHS: \(whsVisited.count)/\(sites.count) \
            (\(whsPercent)%) — TWHS: \(twhsVisited.count)/\(tentatives.count) \
            (\(twhsPercent)%) — TOTAL: \(totalVisits)/\(total) (\(totalPercent)%)<br />\
            <i>Last compiled 2018.05.21  — <a href=\"\(updatesURL)\">Check for updates</a></i>\
            </small></p>\n
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

