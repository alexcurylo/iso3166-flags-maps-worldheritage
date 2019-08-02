// @copyright Trollwerks Inc.

import Foundation

struct Country: Codable {

    enum Code: String {
        case israel = "IL"
    }

    private let alpha2: String
    private let alpha3: String
    private let name: String
    private let officialName: String
    private let numeric: String
    // all except Kosovo
    private let wikiUrl: URL?
    // Kosovo only
    // swiftlint:disable:next discouraged_optional_boolean
    private let unofficial: Bool?
    private let wikiEntry: URL?

    var iso: String { return alpha2 }
    var title: String { return name }

    static let countries: [Country] = {
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

    static func iso(for name: String?) -> String {
        let title: String
        switch name {
        case "Democratic People's Republic of Korea":
            title = "Korea (Democratic People's Republic of)"
        case "Democratic Republic of the Congo":
            title = "Congo (Democratic Republic of the)"
        case "Palestine":
            title = "Palestine, State of"
        case "Republic of Korea":
            title = "Korea (Republic of)"
        case "Republic of Moldova":
            title = "Moldova (Republic of)"
        case "United Republic of Tanzania":
            title = "Tanzania, United Republic of"
        default:
            title = name ?? "<missing>"
        }
        let matches = countries.filter { $0.name == title }
        guard let match = matches.first else {
            assertionFailure(("no countries for \(String(describing: title))"))
            return "<missing>"
        }
        return match.alpha2
    }
}
