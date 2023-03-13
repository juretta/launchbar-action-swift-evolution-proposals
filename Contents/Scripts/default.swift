#!/usr/bin/env swift

// LaunchBar Action Script to look up Swift Evolution Proposals.

// This is more or less a copy of https://github.com/attaswift/alfred-swift-evolution/blob/master/se-lookup.swift adjusted for LaunchBar.
// The original Alfred action is MIT Licensed: https://github.com/attaswift/alfred-swift-evolution/blob/master/LICENSE.md

// LaunchBar Actions documentation:
// https://developer.obdev.at/resources/documentation/launchbar-developer-documentation/#/welcome

import Foundation

/// Data transfer object definition for a Swift Evolution proposal in the
/// JSON format used by swift.org.
struct ProposalDTO: Decodable {
    static let dataURL = URL(string: "https://download.swift.org/swift-evolution/proposals.json")!

    var id: String
    var title: String
    var link: String
    var status: Status

    struct Status: Decodable {
        var state: String
    }
}

struct Proposal {
    let baseURL = URL(string: "https://github.com/apple/swift-evolution/blob/main/proposals")!

    var id: String
    var title: String
    var url: URL
    var status: Status

    var number: Int? {
        guard let digits = id.split(separator: "-").last else { return nil }
        return Int(digits)
    }

    var searchText: String {
        "\(id) \(number.map(String.init(describing:)) ?? "") \(title) \(status.description) \(status.description)"
            .lowercased()
    }

    func matches(_ query: String) -> Bool {
        let words = query
            .split { $0.isWhitespace || $0.isNewline }
            .map { $0.lowercased() }
        if words.count == 0 { return true }
        if words.count == 1, let number = Int(words[0]) {
            return self.number == number
        }
        return words.contains { searchText.contains($0) }
    }
}

extension Proposal {
    init(dto: ProposalDTO) {
        self.id = dto.id
        self.title = dto.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.url = baseURL.appendingPathComponent(dto.link)
        self.status = Status(dto: dto.status)
    }
}

extension Proposal {
    enum Status: CustomStringConvertible {
        case awaitingReview
        case scheduledForReview
        case activeReview
        case returnedForRevision
        case withdrawn
        case deferred // status is no longer in use
        case accepted
        case acceptedWithRevisions
        case rejected
        case implemented
        case previewing
        case error
        case unknown(status: String)

        init(dto: ProposalDTO.Status) {
            switch dto.state {
            case ".awaitingReview": self = .awaitingReview
            case ".scheduledForReview": self = .scheduledForReview
            case ".activeReview": self = .activeReview
            case ".returnedForRevision": self = .returnedForRevision
            case ".withdrawn": self = .withdrawn
            case ".deferred": self = .deferred
            case ".accepted": self = .accepted
            case ".acceptedWithRevisions": self = .acceptedWithRevisions
            case ".rejected": self = .rejected
            case ".implemented": self = .implemented
            case ".previewing": self = .previewing
            case ".error": self = .error
            default: self = .unknown(status: dto.state)
            }
        }

        var description: String {
            switch self {
            case .awaitingReview: return "Awaiting Review"
            case .scheduledForReview: return "Scheduled for Review"
            case .activeReview: return "Active Review"
            case .returnedForRevision: return "Returned for Revision"
            case .withdrawn: return "Withdrawn"
            case .deferred: return "Deferred"
            case .accepted: return "Accepted"
            case .acceptedWithRevisions: return "Accepted with Revisions"
            case .rejected: return "Rejected"
            case .implemented: return "Implemented"
            case .previewing: return "Previewing"
            case .error: return "Error"
            case .unknown(let underlying): return "Unknown status: \(underlying)"
            }
        }
    }
}

/// Represents one row in a LaunchBar result set.
///
/// Documentation: <https://developer.obdev.at/resources/documentation/launchbar-developer-documentation/#/script-output>
struct Item: Encodable {
    /// The item’s title. This key is required, except when one of the following is present: path, url or actionBundleIdentifier.
    var title: String

    /// An optional subtitle that appears below or next to the title (depending on the user’s selected theme).
    var subtitle: String?

    /// An optional text that appears right–aligned.
    var label: String?

    /// An optional text that appears right–aligned. Similar to label, but with a rounded rectangle behind the text.
    /// If both label and badge are set, label appears to the left of badge.
    var badge: String?

    /// The icon for the item. This is a string that is interpreted the same way as CFBundleIconFile in the action’s Info.plist.
    var icon: String?

    /// A URL that the item represents. When the user selects the item and hits Enter, this URL is opened.
    /// Items that have a path or url property automatically support QuickLook and do not need to set the `quickLookURL` property too.
    var url: String?
}

extension Item {
    init(proposal: Proposal) {
        self.title = "\(proposal.id): \(proposal.title)"
        self.subtitle = "\(proposal.status.description) • \(proposal.title)"
        self.label = proposal.id
        self.url = proposal.url.absoluteString
        self.badge = proposal.status.description
        self.icon = "Swift-Logo"
    }

    init(error: Error) {
        // Dumping an `Error`’s contents seems to be the best way to extract all the
        // salient error information into a semi-readable string. This obviously isn’t
        // ideal for user-facing error messages, but I think it’s acceptable for a
        // developer tool such as this.
        // Unfortunately, `error.localizedDescription` or the various `LocalizedError`
        // properties carry little to no actionable information about the failure reason
        // for typical library errors such as Foundation.CocoaError or Swift.DecodingError.
        let title = "Error: \(error.localizedDescription)"
        var errorInfo = ""
        dump(error, to: &errorInfo)
        self.init(
            title: title,
            subtitle: errorInfo
        )
    }
}

// MARK: - Main program

let query = CommandLine.arguments.dropFirst().joined(separator: " ")
let result: [Item]
do {
    let data = try Data(contentsOf: ProposalDTO.dataURL)
    let decoder = JSONDecoder()
    let allProposals = try decoder.decode([ProposalDTO].self, from: data)
    result = allProposals
        .map(Proposal.init(dto:))
        .filter { $0.matches(query) }
        .sorted { ($0.number ?? 0) > ($1.number ?? 0) }
        .map(Item.init(proposal:))
} catch {
    result = [Item(error: error)]
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let resultData = try encoder.encode(result)
print(String(decoding: resultData, as: UTF8.self))
