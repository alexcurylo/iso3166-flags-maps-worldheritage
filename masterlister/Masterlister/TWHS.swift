// @copyright Trollwerks Inc.

import SWXMLHash

struct TWHS: Codable {

    private let id_number: String?
    private let iso_code: String?
    private let site: String?
    //private let submitted: String
    //private let category: String

    var name: String {
        guard let site = site,
            !site.isEmpty else {
                assertionFailure("invalid name field")
                return "<missing>"
        }
        return site
    }

    var siteId: Int {
        guard let idString = id_number,
            let id = Int(idString) else {
                assertionFailure("invalid ID field")
                return 0
        }
        return id
    }

    var countries: String {
        guard let codes = iso_code,
              !codes.isEmpty else {
            assertionFailure(("no countries for \(siteId): \(name)"))
            return ""
        }
        return codes
    }

    static var sitelist: [TWHS] = {
        sitesFromHTML(file: "twhs")
    }()

    private static func sitesFromHTML(file: String) -> [TWHS] {
        guard let path = Bundle.main.path(forResource: file, ofType: "html"),
              let page = try? String(contentsOfFile: path) else {
                assertionFailure("missing TWHS file: \(file).html")
                return []
        }

        do {
            let nsrange = NSRange(page.startIndex..<page.endIndex, in: page)
            // <span > <a href="/en/tentativelists/6339/" >Qajartalik  (13/04/2018)</a> Canada </span>
            let linkPattern = #"lists\/(?<id>[0-9]+)\/"\s*>"#
            let linkRegex = try NSRegularExpression(pattern: linkPattern, options: [])
            let ids = linkRegex.matches(in: page, options: [], range: nsrange)
                               .map { page.substring(with: $0.range(withName: "id")) }

            var sites: [TWHS] = []
            // swiftlint:disable:next line_length
            let pattern = #"lists\/(?<id>[0-9]+)\/"\s*>(?<site>.+)\s\([0-9\/]{10}\)<\/a>\s*(?<state>\S+.*\S)\s*<\/span>"#
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            regex.enumerateMatches(in: page,
                                   options: [],
                                   range: nsrange) { match, _, _ in
                guard let match = match else { return }

                let site = TWHS(
                    id_number: page.substring(with: match.range(withName: "id")),
                    iso_code: Country.iso(for: page.substring(with: match.range(withName: "state"))),
                    site: page.substring(with: match.range(withName: "site"))
                )
                sites.append(site)
            }

            if ids.count != sites.count {
                let diff = ids.difference(from: sites.map { $0.id_number })
                assertionFailure("ids (\(ids.count)) != sites (\(sites.count)): \(diff)")
            }

            return sorted(sites: sites)
        } catch {
            assertionFailure("scraping TWHS failed")
        }

        return []
    }

    private static func sitesFromJSON(file: String) -> [TWHS] {
        guard let path = Bundle.main.path(forResource: file, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                assertionFailure("missing TWHS file: \(file).json")
                return []
        }

        do {
            let sites = try JSONDecoder().decode([TWHS].self, from: data)
            return sorted(sites: sites)
        } catch DecodingError.dataCorrupted(let context) {
            print(context.debugDescription)
        } catch DecodingError.keyNotFound(let key, let context) {
            print("Key '\(key)' not Found")
            print("Debug Description:", context.debugDescription)
        } catch DecodingError.valueNotFound(let value, let context) {
            print("Value '\(value)' not Found")
            print("Debug Description:", context.debugDescription)
        } catch DecodingError.typeMismatch(let type, let context) {
            print("Type '\(type)' mismatch")
            print("Debug Description:", context.debugDescription)
        } catch {
            print("error: ", error)
        }

        return []
    }

    private static func sitesFromXML(file: String) -> [TWHS] {
        guard let path = Bundle.main.path(forResource: file, ofType: "xml"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                assertionFailure("missing TWHS file: \(file).xml")
                return []
        }

        let xml = SWXMLHash.parse(data)
        let document = xml["pkg:package"]["pkg:part"].all[2]
        let documentName = document.element?.attribute(by: "pkg:name")?.text
        assert(documentName == "/word/document.xml")
        let body = document["pkg:xmlData"]["w:document"]["w:body"]

        let rows = body["query"]["row"].all
        assert(rows.count == 1_700, "1700 TWHS on 2019.08.01")

        let sites: [TWHS] = rows.compactMap { TWHS(from: $0) }

        return sorted(sites: sites)
    }

    private static func sorted(sites: [TWHS]) -> [TWHS] {
        let sites = sites.sorted { lhs, rhs in
            lhs.name < rhs.name
        }

        // Should match http://whc.unesco.org/en/tentativelists/
        assert(sites.count == 1_700, "1700 TWHS on 2019.08.01")
        return sites
    }

    init?(from xml: XMLIndexer) {
        defer {
            assert(!id_number.isNilOrEmpty, "Missing id")
            assert(!site.isNilOrEmpty, "Missing name")
            assert(!iso_code.isNilOrEmpty, "Missing iso")
        }

        id_number = xml["id"].element?.text
        iso_code = xml["iso"].element?.text
        site = xml["site"].element?.text
    }

    init(id_number: String?,
         iso_code: String?,
         site: String?) {
        self.id_number = id_number
        self.iso_code = iso_code
        self.site = site
    }
}

extension String {

    func substring(with nsrange: NSRange) -> String? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return String(self[range])
    }
}

extension Array where Element: Hashable {

    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
