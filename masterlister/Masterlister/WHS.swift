// @copyright Trollwerks Inc.

import SWXMLHash

struct WHS: Codable {

    private let id_number: String?
    private let iso_code: String?
    private let site: String?
    /* all XML fields:
    category
    criteria_txt
    danger
    date_inscribed
    extension
    http_url
    id_number
    image_url
    image_url
    iso_code
    justification
    latitude
    location
    longitude
    region
    revision
    secondary_dates
    short_description
    site
    states
    transboundary
    unique_number
    */

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
                switch siteId {
                case 148: // Old City of Jerusalem and its Walls
                    break
                default:
                    assertionFailure(("no countries for \(siteId): \(name)"))
                }
            return ""
        }
        return codes
    }

    static var sitelist: [WHS] = {
         sitesFromXML(file: "whc-en")
    }()

    private static func sitesFromJSON(file: String) -> [WHS] {
        guard let path = Bundle.main.path(forResource: file, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                assertionFailure("missing WHS file: \(file).json")
                return []
        }

        do {
            let whsFile = try JSONDecoder().decode(WHSFile.self, from: data)
            let sites = whsFile.query.sites
            assert(sites.count == Int(whsFile.query.rows), "Inconsistent WHS count and rows")
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

    private static func sitesFromXML(file: String) -> [WHS] {
        guard let path = Bundle.main.path(forResource: file, ofType: "xml"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                assertionFailure("missing WHS file: \(file).xml")
                return []
        }

        let xml = SWXMLHash.parse(data)
        let rows = xml["query"]["row"].all
        assert(rows.count == 1_121, "1121 inscribed WHS in July 2019")

        let sites: [WHS] = rows.compactMap { WHS(from: $0) }

        return sorted(sites: sites)
    }

    private static func sorted(sites: [WHS]) -> [WHS] {
        let sites = sites.sorted { lhs, rhs in
            lhs.name < rhs.name
        }
        assert(sites.count == 1_121, "1121 inscribed WHS in July 2019")
        return sites
    }

    init?(from xml: XMLIndexer) {
        do {
            id_number = try xml["id_number"].value()
            iso_code = try xml["iso_code"].value()
            site = try xml["site"].value()
        } catch {
            print("Failure \(error) parsing \(xml)")
            return nil
        }
    }
}

private struct WHSFile: Codable {

    struct Query: Codable {

        let rows: String
        let columns: String
        let sites: [WHS]

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case rows = "@rows"
            case columns = "@columns"
            case sites = "row"
        }
    }

    let query: Query
}

extension XMLIndexer {

    func enumerate() {
        enumerate(indexer: self, level: 0)
    }

    // enumerate all child elements (procedurally)
    func enumerate(indexer: XMLIndexer, level: Int) {
        for child in indexer.children {
            // swiftlint:disable:next force_unwrapping
            let name = child.element!.name
            print("\(level) \(name)")

            enumerate(indexer: child, level: level + 1)
        }
    }
}
