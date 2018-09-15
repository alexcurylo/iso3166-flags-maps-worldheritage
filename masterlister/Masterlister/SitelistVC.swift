// @copyright Trollwerks Inc.

import Cocoa

final class SitelistVC: NSViewController {

    private let countries: [Country] = {
        let path = Bundle.main.path(forResource: "iso_3166-1", ofType: "json")
        // swiftlint:disable:next force_try force_unwrapping
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        // swiftlint:disable:next force_try
        let dict = try! JSONDecoder().decode([String: Country].self, from: data)
        let array = Array(dict.values).sorted { lhs, rhs in
            lhs.name < rhs.name
        }
        return array
    }()

    private let members: [Member] = {
        let path = Bundle.main.path(forResource: "unesco_members", ofType: "json")
        // swiftlint:disable:next force_try force_unwrapping
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        // swiftlint:disable:next force_try
        let array = try! JSONDecoder().decode([Member].self, from: data)
        assert(array.count == 206, "Should be 195 states and 10 associates and 1 observer (VA) in 2017")
        return array
    }()

    let sites = WHS.sitelist
    let tentatives = TWHS.sitelist

    private lazy var visits: [Visit] = {
        let path = Bundle.main.path(forResource: "visits", ofType: "json")
        var array: [Visit] = []
        do {
            // swiftlint:disable:next force_unwrapping
            let data = try Data(contentsOf: URL(fileURLWithPath: path!))
            array = try JSONDecoder().decode([Visit].self, from: data)
        } catch {
            print("Error decoding visits", error)
        }

        return array
    }()

    private lazy var whsVisits: [Visit] = {
        let array = visits.filter { $0.whs != nil }
        let ids = array.compactMap { $0.whs }
        let duplicates = Array(Set(ids.filter { (i: Int) in ids.filter { $0 == i }.count > 1 }))
        assert(duplicates.isEmpty, "Should not have duplicate WHS visits \(duplicates)")
        let wrong = Set(ids).subtracting(Set(sites.map { $0.siteID }))
        assert(wrong.isEmpty, "Should not have wrong WHS visits \(wrong)")
        return array
    }()

    private lazy var twhsVisits: [Visit] = {
        let array = visits.filter { $0.twhs != nil }
        let ids = visits.compactMap { $0.twhs }
        let duplicates = Array(Set(ids.filter { (i: Int) in ids.filter { $0 == i }.count > 1 }))
        assert(duplicates.isEmpty, "Should not have duplicate TWHS visits \(duplicates)")
        let wrong = Set(ids).subtracting(Set(tentatives.map { $0.siteID }))
        assert(wrong.isEmpty, "Should not have wrong TWHS visits \(wrong)")
        return array
    }()

    private lazy var countryFiles: [CountryFile] = {
        let path = Bundle.main.path(forResource: "country-files", ofType: "json")
        var array: [CountryFile] = []
        do {
            // swiftlint:disable:next force_unwrapping
            let data = try Data(contentsOf: URL(fileURLWithPath: path!))
            array = try JSONDecoder().decode([CountryFile].self, from: data)
        } catch {
            print("Error decoding country files", error)
        }
        return array
    }()

    @IBOutlet private var output: NSTextView!

    private var whsVisited = Set<Int>()
    private var twhsVisited = Set<Int>()

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

    //    private func pageExists(at url: URL) -> Bool {
    //        var request = URLRequest(url: url)
    //        request.httpMethod = "HEAD"
    //        request.timeoutInterval = 10
    //        var response: URLResponse?
    //        try! NSURLConnection.sendSynchronousRequest(request,
    //                                                    returning: &response)
    //        let httpResponse = response as! HTTPURLResponse
    //        if httpResponse.statusCode != 200 { return false }
    //        if httpResponse.url != url { return false }
    //        return true
    //    }

    private func writeCountries() {
        for country in countries {
            guard members.contains(where: { country.alpha2 == $0.iso }) else {
                continue
            }

            var whsSites = sites.filter {
                $0.countries.contains(country.alpha2.lowercased())
            }
            // Special Jerusalem handling, put it in Israel
            if country.alpha2 == "IL" {
                let countryless = sites.filter { $0.countries.isEmpty }
                assert(countryless.count == 1, "Not exactly Jerusalem without a country?")
                // swiftlint:disable:next force_unwrapping
                whsSites.append(countryless.first!)
            }

            let twhsSites = tentatives.filter {
                $0.countries.contains(country.alpha2)
            }

            let unescoURL = "http://whc.unesco.org/en/statesparties/\(country.alpha2)/"
            let unescoLink = """
            <a href="\(unescoURL)">\(country.name)</a>
            """
            var fileLink = ""
            if let file = countryFiles.first(where: { country.alpha2 == $0.iso })?.file {
                fileLink = " — <a href=\"\(file)\">Country File</a>"
            }
            // swiftlint:disable:next line_length
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

    private func writeSites(in country: Country,
                            whs whsSites: [WHS],
                            twhs twhsSites: [TWHS]) {
        guard !whsSites.isEmpty || !twhsSites.isEmpty else {
            let countryStart = NSAttributedString(string: """
                <i><small>no inscribed or tentative sites yet!</small></i><br />\n
                """)
            output.textStorage?.append(countryStart)
            return
        }

        for whs in whsSites {
            output.textStorage?.append(whsLine(whs: whs))
        }

        if !twhsSites.isEmpty {
            output.textStorage?.append(NSAttributedString(string: "<i>"))

            for twhs in twhsSites {
                output.textStorage?.append(twhsLine(twhs: twhs))
            }

            output.textStorage?.append(NSAttributedString(string: "</i>"))
        }
    }

    private func whsLine(whs: WHS) -> NSAttributedString {
        let link = """
        <a href="http://whc.unesco.org/en/list/\(whs.siteID)">\(whs.name)</a>
        """

        var mark = Visited.no.rawValue
        var blogLinks = ""
        if let visited = whsVisits.first(where: { $0.whs == whs.siteID }) {
            whsVisited.insert(whs.siteID)

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
        return whsLine
    }

    private func twhsLine(twhs: TWHS) -> NSAttributedString {
        let link = """
        <a href="http://whc.unesco.org/en/tentativelists/\(twhs.siteID)">\(twhs.name)</a>
        """

        var mark = Visited.no.rawValue
        var blogLinks = ""
        if let visited = twhsVisits.first(where: { $0.twhs == twhs.siteID }) {
            twhsVisited.insert(twhs.siteID)

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
        return twhsLine
    }

    private func writeFooter(for type: Document) {
        assert(whsVisited.count == 485, "Should be 485 WHS visited not \(whsVisited.count) (2018.07.08)")
        assert(twhsVisited.count == 338, "Should be 338 TWHS visited not \(twhsVisited.count) (2018.07.21)")
        // swiftlint:disable:next line_length
        let updatesURL = "http://whc.unesco.org/en/tentativelists/?action=listtentative&pattern=&state=&theme=&criteria_restrication=&date_start=07%2F07%2F2018&date_end=&order=year"

        let whsPercent = String(format: "%.1f", Float(whsVisited.count) / Float(sites.count) * 100)
        let twhsPercent = String(format: "%.1f", Float(twhsVisited.count) / Float(tentatives.count) * 100)

        let total = sites.count + tentatives.count
        let totalVisits = whsVisited.count + twhsVisited.count
        let totalPercent = String(format: "%.1f", Float(totalVisits) / Float(total) * 100)
        let textFooter = NSAttributedString(string: """
            <p dir="ltr"><small>WHS: \(whsVisited.count)/\(sites.count) \
            (\(whsPercent)%) — TWHS: \(twhsVisited.count)/\(tentatives.count) \
            (\(twhsPercent)%) — TOTAL: \(totalVisits)/\(total) (\(totalPercent)%)<br />\
            <i>Last compiled 2018.07.08  — <a href=\"\(updatesURL)\">Check for updates</a></i>\
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

private struct CountryFile: Codable {
    let iso: String
    let file: URL?
    let name: String? // for easily locating unfiled countries
}

private struct Country: Codable {
    let alpha2: String
    let alpha3: String
    let name: String
    let officialName: String
    let numeric: String
    // all except Kosovo
    let wikiUrl: URL?
    // Kosovo only
    // swiftlint:disable:next discouraged_optional_boolean
    let unofficial: Bool?
    let wikiEntry: URL?
}

private struct Member: Codable {
    let iso: String
    let name: String
    let joined: String
    let region: String
}

private struct Visit: Codable {
    let wonder: Int?
    let whs: Int?
    let twhs: Int?
    let visit: URL?
    let stay: URL?
    let eat: URL?
}
