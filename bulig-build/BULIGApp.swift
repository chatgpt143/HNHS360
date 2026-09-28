import SwiftUI
import AppKit
import WebKit
import JavaScriptCore
import PDFKit

struct SchoolSettings: Codable, Equatable {
    var schoolName = ""
    var schoolId = ""
    var schoolHead = ""
    var schoolHeadPosition = ""
    var district = ""
    var division = "Bukidnon"
    var region = "Region X - Northern Mindanao"
    var schoolYear = "2026-2027"
    var gradeLevel = ""
    var section = ""
    var adviser = ""
    var assessmentTool = "CRLA"
    var subject = "ENGLISH"
    var leftReportLogoFile: String? = nil
    var rightReportLogoFile: String? = nil
}

struct PreAssessment: Codable, Equatable {
    var level = ""
    var bosy = ""
    var mosy = ""
    var eosy = ""
}

struct AssessmentEntry: Codable, Equatable {
    var result = ""
    var overrideLevel = ""
    var note = ""
    var effectiveDate = ""

    enum CodingKeys: String, CodingKey {
        case result, overrideLevel, note, effectiveDate
    }

    init(result: String = "", overrideLevel: String = "", note: String = "", effectiveDate: String = "") {
        self.result = result
        self.overrideLevel = overrideLevel
        self.note = note
        self.effectiveDate = effectiveDate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        result = try c.decodeIfPresent(String.self, forKey: .result) ?? ""
        overrideLevel = try c.decodeIfPresent(String.self, forKey: .overrideLevel) ?? ""
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        effectiveDate = try c.decodeIfPresent(String.self, forKey: .effectiveDate) ?? ""
    }
}

struct Learner: Identifiable, Codable, Equatable {
    var id = UUID()
    var lrn = ""
    var fullName = ""
    var firstName = ""
    var middleInitial = ""
    var lastName = ""
    var nameExtension = ""
    var sex = ""
    var dateOfBirth = ""
    var pre = PreAssessment()
    var preHistory: [String: PreAssessment] = [:]
    var assessments: [String: AssessmentEntry] = [:]
    var reactivationAPs: [String] = []

    enum CodingKeys: String, CodingKey {
        case id, lrn, fullName, firstName, middleInitial, lastName, nameExtension, sex, dateOfBirth, pre, preHistory, assessments, reactivationAPs
    }

    init(
        id: UUID = UUID(),
        lrn: String = "",
        fullName: String = "",
        firstName: String = "",
        middleInitial: String = "",
        lastName: String = "",
        nameExtension: String = "",
        sex: String = "",
        dateOfBirth: String = "",
        pre: PreAssessment = PreAssessment(),
        preHistory: [String: PreAssessment] = [:],
        assessments: [String: AssessmentEntry] = [:],
        reactivationAPs: [String] = []
    ) {
        self.id = id
        self.lrn = lrn
        self.fullName = fullName
        self.firstName = firstName
        self.middleInitial = middleInitial
        self.lastName = lastName
        self.nameExtension = nameExtension
        self.sex = sex
        self.dateOfBirth = dateOfBirth
        self.pre = pre
        self.preHistory = preHistory
        self.assessments = assessments
        self.reactivationAPs = reactivationAPs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        lrn = try c.decodeIfPresent(String.self, forKey: .lrn) ?? ""
        fullName = try c.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        firstName = try c.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        middleInitial = try c.decodeIfPresent(String.self, forKey: .middleInitial) ?? ""
        lastName = try c.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        nameExtension = try c.decodeIfPresent(String.self, forKey: .nameExtension) ?? ""
        sex = try c.decodeIfPresent(String.self, forKey: .sex) ?? ""
        dateOfBirth = try c.decodeIfPresent(String.self, forKey: .dateOfBirth) ?? ""
        pre = try c.decodeIfPresent(PreAssessment.self, forKey: .pre) ?? PreAssessment()
        preHistory = try c.decodeIfPresent([String: PreAssessment].self, forKey: .preHistory) ?? [:]
        assessments = try c.decodeIfPresent([String: AssessmentEntry].self, forKey: .assessments) ?? [:]
        reactivationAPs = try c.decodeIfPresent([String].self, forKey: .reactivationAPs) ?? []
    }

    var displayName: String {
        let mi = middleInitial.trimmingCharacters(in: .whitespacesAndNewlines)
        let ext = nameExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        if !lastName.isEmpty || !firstName.isEmpty {
            var pieces: [String] = []
            if !lastName.isEmpty { pieces.append(lastName.uppercased() + ",") }
            if !firstName.isEmpty { pieces.append(firstName.uppercased()) }
            if !mi.isEmpty { pieces.append(String(mi.uppercased().prefix(1)) + ".") }
            if !ext.isEmpty { pieces.append(ext.uppercased()) }
            return pieces.joined(separator: " ")
        }
        return fullName
    }
}

struct AppData: Codable, Equatable {
    var settings = SchoolSettings()
    var assessmentTerms: [String: String] = ["PRETEST": "1ST"]
        .merging(Dictionary(uniqueKeysWithValues: (1...15).map { ("AP\($0)", "1ST") })) { current, _ in current }
    var learners: [Learner] = []
}

struct RestorePointInfo: Identifiable {
    let id: String
    let url: URL
    let title: String
    let date: Date
}

struct SchoolYearArchiveInfo: Identifiable {
    let id: String
    let url: URL
    let schoolYear: String
    let date: Date
}

struct ReadingLevel: Identifiable, Hashable {
    var id: String { code }
    let code: String
    let label: String
    let area: String
}

let readingLevels: [ReadingLevel] = [
    .init(code: "LEVEL 1", label: "Orientation to Print", area: "ORAL LANGUAGE"),
    .init(code: "LEVEL 2A", label: "Letter and Initial Sound", area: "PHONOLOGICAL AWARENESS"),
    .init(code: "LEVEL 2B", label: "Letter and Initial Sound", area: "PHONOLOGICAL AWARENESS"),
    .init(code: "LEVEL 3A", label: "Letter Name Knowledge", area: "WORD RECOGNITION"),
    .init(code: "LEVEL 3B", label: "Letter Name Knowledge", area: "WORD RECOGNITION"),
    .init(code: "LEVEL 4", label: "Invented Word Reading", area: "FLUENCY"),
    .init(code: "LEVEL 5", label: "Familiar Word Reading", area: "VOCABULARY AND LISTENING COMPREHENSION"),
    .init(code: "LEVEL 6", label: "Listening Comprehension", area: "GRADED READING COMPREHENSION"),
    .init(code: "LEVEL 7", label: "Dictation", area: "GENUINE LOVE FOR READING AND WRITING")
]

let assessmentPeriods = (1...15).map { "AP\($0)" }
let terms = ["1ST", "2ND", "3RD", "4TH", "SUMMER"]
let results = ["", "READY", "NOT READY", "REVERTED", "NLS", "NLP", "TRANSFER OUT"]
let preAssessmentPeriods = ["BOSY", "MOSY", "EOSY"]

struct SF1ParsedSheet: Decodable {
    let name: String
    let rows: [[String]]
}

enum SF1ImportError: LocalizedError {
    case parserMissing
    case javascript(String)
    case noSF1Sheet
    case unreadable

    var errorDescription: String? {
        switch self {
        case .parserMissing:
            return "The SF1 spreadsheet reader is missing from this app build."
        case .javascript(let message):
            return "The SF1 file could not be read. \(message)"
        case .noSF1Sheet:
            return "No SF1 table with LRN, NAME, Sex, and BIRTH DATE columns was found."
        case .unreadable:
            return "The selected SF1 file could not be opened."
        }
    }
}

enum PrintoutType: String, CaseIterable, Identifiable {
    case classroomMonitoring = "Classroom Reading Monitoring Report"
    case pupilList = "List of Pupils"
    var id: String { rawValue }
}

func reportLevelColor(_ level: String) -> NSColor {
    switch level {
    case "LEVEL 1": return NSColor(calibratedRed: 1.0, green: 0.84, blue: 0.82, alpha: 1)
    case "LEVEL 2A": return NSColor(calibratedRed: 1.0, green: 0.90, blue: 0.72, alpha: 1)
    case "LEVEL 2B": return NSColor(calibratedRed: 1.0, green: 0.94, blue: 0.66, alpha: 1)
    case "LEVEL 3A": return NSColor(calibratedRed: 0.88, green: 0.95, blue: 0.72, alpha: 1)
    case "LEVEL 3B": return NSColor(calibratedRed: 0.79, green: 0.93, blue: 0.76, alpha: 1)
    case "LEVEL 4": return NSColor(calibratedRed: 0.75, green: 0.91, blue: 0.94, alpha: 1)
    case "LEVEL 5": return NSColor(calibratedRed: 0.80, green: 0.86, blue: 0.97, alpha: 1)
    case "LEVEL 6": return NSColor(calibratedRed: 0.84, green: 0.81, blue: 0.96, alpha: 1)
    case "LEVEL 7": return NSColor(calibratedRed: 0.92, green: 0.82, blue: 0.95, alpha: 1)
    default: return .white
    }
}


struct NativeCRMLevelRow {
    let level: String
    let area: String
    let male: Int
    let female: Int
    let total: Int
}

struct NativeProfileRow {
    let label: String
    let bosyMale: Int
    let bosyFemale: Int
    let mosyMale: Int
    let mosyFemale: Int
    let eosyMale: Int
    let eosyFemale: Int
}

struct NativePupilRow {
    let lrn: String
    let name: String
    let sex: String
    let previousLevel: String
    let currentLevel: String
    let area: String
    let status: String
}

struct NativeReportSnapshot {
    let settings: SchoolSettings
    let stage: String
    let term: String
    let keyStage: Int
    let crmRows: [NativeCRMLevelRow]
    let profileRows: [NativeProfileRow]
    let bosyTotal: Int
    let mosyTotal: Int
    let eosyTotal: Int
    let pupils: [NativePupilRow]
    let maleCount: Int
    let femaleCount: Int
    let generatedAt: String
    let leftLogoData: Data?
    let rightLogoData: Data?
}

final class NativeReportView: NSView {
    let type: PrintoutType
    let snapshot: NativeReportSnapshot
    let paperSize: NSSize
    let pageCount: Int
    private let pupilPageCounts: [Int]

    private let leftMargin: CGFloat = 72      // 1 inch
    private let rightMargin: CGFloat = 72     // 1 inch
    private let topMargin: CGFloat = 36       // 0.5 inch
    private let bottomMargin: CGFloat = 36    // 0.5 inch

    init(type: PrintoutType, snapshot: NativeReportSnapshot) {
        self.type = type
        self.snapshot = snapshot

        if type == .classroomMonitoring {
            self.paperSize = NSSize(width: 841.89, height: 595.28)
            self.pupilPageCounts = []
            self.pageCount = 1
        } else {
            self.paperSize = NSSize(width: 841.89, height: 595.28)
            let entryCount = snapshot.pupils.count + 2 // Male/Female group rows
            let counts = NativeReportView.makePupilPageCounts(entryCount: entryCount)
            self.pupilPageCounts = counts
            self.pageCount = max(1, counts.count)
        }

        super.init(frame: NSRect(
            x: 0,
            y: 0,
            width: paperSize.width,
            height: paperSize.height * CGFloat(pageCount)
        ))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { true }

    private static func makePupilPageCounts(entryCount: Int) -> [Int] {
        guard entryCount > 0 else { return [0] }

        // A4 landscape. First page contains the full institutional header.
        // Final page reserves space for enrollment totals and signatories.
        if entryCount <= 9 { return [entryCount] }

        let pageCount: Int
        if entryCount <= 36 {
            pageCount = 2
        } else {
            pageCount = 2 + Int(ceil(Double(entryCount - 36) / 27.0))
        }

        var capacities: [Int] = []
        for i in 0..<pageCount {
            if i == 0 {
                capacities.append(15)
            } else if i == pageCount - 1 {
                capacities.append(21)
            } else {
                capacities.append(27)
            }
        }

        // Balance the learner rows while respecting the space available
        // on the first and final pages.
        var remaining = entryCount
        var counts: [Int] = []
        for i in 0..<pageCount {
            let pagesLeft = pageCount - i
            let balancedTarget = Int(ceil(Double(remaining) / Double(pagesLeft)))
            let value = min(capacities[i], balancedTarget)
            counts.append(value)
            remaining -= value
        }

        var i = pageCount - 1
        while remaining > 0 {
            if counts[i] < capacities[i] {
                counts[i] += 1
                remaining -= 1
            }
            i -= 1
            if i < 0 { i = pageCount - 1 }
        }
        return counts
    }

    private func font(_ size: CGFloat, bold: Bool = false) -> NSFont {
        let name = bold ? "Arial-BoldMT" : "Arial"
        return NSFont(name: name, size: size) ?? (bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size))
    }

    private func paragraph(_ alignment: NSTextAlignment) -> NSMutableParagraphStyle {
        let p = NSMutableParagraphStyle()
        p.alignment = alignment
        p.lineBreakMode = .byWordWrapping
        p.lineSpacing = -1
        return p
    }

    private func drawText(
        _ text: String,
        in rect: NSRect,
        size: CGFloat = 12,
        bold: Bool = false,
        alignment: NSTextAlignment = .left,
        color: NSColor = .black,
        verticalCenter: Bool = true
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font(size, bold: bold),
            .foregroundColor: color,
            .paragraphStyle: paragraph(alignment)
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let options: NSString.DrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let measured = str.boundingRect(
            with: NSSize(width: rect.width, height: .greatestFiniteMagnitude),
            options: options
        )
        let y = verticalCenter ? rect.minY + max(0, (rect.height - measured.height) / 2) : rect.minY
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: rect).addClip()
        str.draw(
            with: NSRect(x: rect.minX, y: y, width: rect.width, height: rect.height),
            options: options
        )
        NSGraphicsContext.restoreGraphicsState()
    }

    private func stroke(_ rect: NSRect, width: CGFloat = 1.0) {
        NSColor.black.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = width
        path.stroke()
    }

    private func fill(_ rect: NSRect, color: NSColor) {
        color.setFill()
        NSBezierPath(rect: rect).fill()
    }

    private func cell(
        _ text: String,
        rect: NSRect,
        fillColor: NSColor? = nil,
        bold: Bool = false,
        alignment: NSTextAlignment = .center,
        size: CGFloat = 12,
        borderWidth: CGFloat = 1.0
    ) {
        if let fillColor { fill(rect, color: fillColor) }
        stroke(rect, width: borderWidth)
        if !text.isEmpty {
            drawText(text, in: rect.insetBy(dx: 3, dy: 2), size: size, bold: bold, alignment: alignment)
        }
    }

    private func drawImage(resource: String, ext: String, in rect: NSRect) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext),
              let image = NSImage(contentsOf: url) else { return }

        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }
        let scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
        let drawSize = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawRect = NSRect(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        image.draw(
            in: drawRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: true,
            hints: nil
        )
    }

    private func drawImage(data: Data?, fallbackResource: String, fallbackExtension: String, in rect: NSRect) {
        let image: NSImage?
        if let data, let uploaded = NSImage(data: data) {
            image = uploaded
        } else if let url = Bundle.main.url(forResource: fallbackResource, withExtension: fallbackExtension) {
            image = NSImage(contentsOf: url)
        } else {
            image = nil
        }

        guard let image else { return }
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
        let drawSize = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawRect = NSRect(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )

        image.draw(
            in: drawRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: true,
            hints: nil
        )
    }

    private func drawHeader(pageOriginY: CGFloat, title: String) -> CGFloat {
        let x = leftMargin
        let w = paperSize.width - leftMargin - rightMargin
        var y = pageOriginY + topMargin
        let landscape = paperSize.width > paperSize.height

        // Complete institutional header. Text remains centered on the page;
        // logo sizes never determine the text center.
        let bandH: CGFloat = landscape ? 70 : 84
        let leftBoxW: CGFloat = landscape ? 92 : 78
        let rightBoxW: CGFloat = landscape ? 180 : 130
        let symmetricInset = max(leftBoxW, rightBoxW) + 8

        drawImage(
            data: snapshot.leftLogoData,
            fallbackResource: "DepEdBukidnonSeal",
            fallbackExtension: "jpg",
            in: NSRect(x: x, y: y, width: leftBoxW, height: bandH)
        )

        drawImage(
            data: snapshot.rightLogoData,
            fallbackResource: "ReportBuligLogo",
            fallbackExtension: "jpg",
            in: NSRect(x: x + w - rightBoxW, y: y, width: rightBoxW, height: bandH)
        )

        let centerRect = NSRect(
            x: x + symmetricInset,
            y: y,
            width: max(80, w - symmetricInset * 2),
            height: bandH
        )

        let headerLines = [
            "Department of Education",
            snapshot.settings.region,
            snapshot.settings.division,
            snapshot.settings.schoolName
        ].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let lineH = bandH / CGFloat(max(headerLines.count, 1))
        for (index, line) in headerLines.enumerated() {
            drawText(
                line,
                in: NSRect(
                    x: centerRect.minX,
                    y: centerRect.minY + CGFloat(index) * lineH,
                    width: centerRect.width,
                    height: lineH
                ),
                size: landscape ? 10.8 : 10.2,
                bold: index == headerLines.count - 1,
                alignment: .center
            )
        }
        y += bandH

        drawText(
            "BUKIDNON'S UNIFIED LITERACY AND INTERVENTION GATEWAY",
            in: NSRect(x: x, y: y, width: w, height: 16),
            size: landscape ? 12 : 10.5,
            bold: true,
            alignment: .center
        )
        y += 16

        drawText(
            "Building Up Literacy, Inspiring Growth",
            in: NSRect(x: x, y: y, width: w, height: 15),
            size: landscape ? 11.5 : 10.5,
            bold: true,
            alignment: .center
        )
        y += 15

        drawText(
            title,
            in: NSRect(x: x, y: y, width: w, height: 22),
            size: landscape ? 15 : 14,
            bold: true,
            alignment: .center
        )
        y += 25

        let rowH: CGFloat = landscape ? 20 : 24
        let widths = [w * 0.18, w * 0.32, w * 0.20, w * 0.30]
        let rows: [[String]] = [
            ["Adviser", snapshot.settings.adviser, "ASSESSMENT\nPERIOD", snapshot.stage],
            ["Grade Level", snapshot.settings.gradeLevel, "Term", snapshot.term],
            ["Section", snapshot.settings.section, "Assessment Tool", snapshot.settings.assessmentTool],
            ["", "", "SUBJECT", snapshot.settings.subject]
        ]

        for r in rows {
            var cx = x
            for i in 0..<4 {
                let isLabel = i == 0 || i == 2
                cell(
                    r[i],
                    rect: NSRect(x: cx, y: y, width: widths[i], height: rowH),
                    bold: isLabel,
                    alignment: isLabel ? .center : .left,
                    size: isLabel ? 10.2 : 12,
                    borderWidth: 1.1
                )
                cx += widths[i]
            }
            y += rowH
        }

        return y
    }

    private func crmAreaLabel(_ area: String) -> String {
        switch area.uppercased() {
        case "ORAL LANGUAGE":
            return "Oral Language"
        case "PHONOLOGICAL AWARENESS":
            return "Phonological\nAwareness"
        case "WORD RECOGNITION":
            return "Word Recognition"
        case "FLUENCY":
            return "Fluency"
        case "VOCABULARY AND LISTENING COMPREHENSION":
            return "Vocabulary And\nListening\nComprehension"
        case "GRADED READING COMPREHENSION":
            return "Graded Reading\nComprehension"
        case "GENUINE LOVE FOR READING AND WRITING":
            return "Genuine Love For\nReading And Writing"
        default:
            return area.capitalized
        }
    }

    private func pupilAreaLabel(_ area: String) -> String {
        switch area.uppercased() {
        case "ORAL LANGUAGE": return "Oral Language"
        case "PHONOLOGICAL AWARENESS": return "Phonological\nAwareness"
        case "WORD RECOGNITION": return "Word Recognition"
        case "FLUENCY": return "Fluency"
        case "VOCABULARY AND LISTENING COMPREHENSION": return "Vocabulary &\nListening Comp."
        case "GRADED READING COMPREHENSION": return "Graded Reading\nComprehension"
        case "GENUINE LOVE FOR READING AND WRITING": return "Love for Reading\n& Writing"
        default: return area.capitalized
        }
    }

    private func drawSignatureBlock(
        pageY: CGFloat,
        y requestedY: CGFloat,
        x: CGFloat,
        width: CGFloat,
        includeDate: Bool
    ) {
        let sigW = (width - 30) / 2
        let blockHeight: CGFloat = 68
        let maxY = pageY + paperSize.height - bottomMargin - blockHeight
        let y = min(requestedY, maxY)

        drawText("Submitted by:", in: NSRect(x: x, y: y, width: sigW, height: 14), size: 10)
        drawText("Noted by:", in: NSRect(x: x + sigW + 30, y: y, width: sigW, height: 14), size: 10)

        // Small blank area specifically reserved for the actual signature.
        let nameY = y + 31
        drawText(
            snapshot.settings.adviser,
            in: NSRect(x: x, y: nameY, width: sigW, height: 16),
            size: 10.5, bold: true, alignment: .center
        )
        drawText(
            snapshot.settings.schoolHead,
            in: NSRect(x: x + sigW + 30, y: nameY, width: sigW, height: 16),
            size: 10.5, bold: true, alignment: .center
        )

        NSColor.black.setStroke()
        let lineY = nameY + 17
        let p1 = NSBezierPath()
        p1.move(to: NSPoint(x: x + 10, y: lineY))
        p1.line(to: NSPoint(x: x + sigW - 10, y: lineY))
        p1.stroke()

        let p2 = NSBezierPath()
        p2.move(to: NSPoint(x: x + sigW + 40, y: lineY))
        p2.line(to: NSPoint(x: x + sigW * 2 + 20, y: lineY))
        p2.stroke()

        drawText(
            "Class Adviser",
            in: NSRect(x: x, y: lineY + 2, width: sigW, height: 13),
            size: 9.5, alignment: .center
        )
        drawText(
            snapshot.settings.schoolHeadPosition,
            in: NSRect(x: x + sigW + 30, y: lineY + 2, width: sigW, height: 13),
            size: 9.5, alignment: .center
        )

        if includeDate {
            drawText(
                snapshot.generatedAt,
                in: NSRect(
                    x: x,
                    y: pageY + paperSize.height - bottomMargin - 14,
                    width: width,
                    height: 12
                ),
                size: 8.5,
                alignment: .right
            )
        }
    }

    private func drawCRM(pageIndex: Int) {
        let pageY = CGFloat(pageIndex) * paperSize.height
        let x = leftMargin
        let w = paperSize.width - leftMargin - rightMargin
        var y = drawHeader(pageOriginY: pageY, title: "CLASSROOM READING MONITORING REPORT") + 6

        let labelW: CGFloat = 50
        let totalW: CGFloat = 46
        let levelW = (w - labelW - totalW) / CGFloat(max(snapshot.crmRows.count, 1))
        let headerH: CGFloat = 36

        cell("", rect: NSRect(x: x, y: y, width: labelW, height: headerH),
             fillColor: NSColor(calibratedWhite: 0.85, alpha: 1))
        var cx = x + labelW
        for row in snapshot.crmRows {
            cell("", rect: NSRect(x: cx, y: y, width: levelW, height: headerH),
                 fillColor: NSColor(calibratedWhite: 0.85, alpha: 1))
            drawText(
                row.level.replacingOccurrences(of: "LEVEL", with: "Level"),
                in: NSRect(x: cx + 2, y: y + 2, width: levelW - 4, height: 11),
                size: 8.2, bold: true, alignment: .center
            )
            drawText(
                crmAreaLabel(row.area),
                in: NSRect(x: cx + 2, y: y + 13, width: levelW - 4, height: 21),
                size: 5.4, alignment: .center
            )
            cx += levelW
        }
        cell("Total", rect: NSRect(x: cx, y: y, width: totalW, height: headerH),
             fillColor: NSColor(calibratedWhite: 0.85, alpha: 1), bold: true, size: 10)
        y += headerH

        let dataH: CGFloat = 17
        let totalMale = snapshot.crmRows.reduce(0) { $0 + $1.male }
        let totalFemale = snapshot.crmRows.reduce(0) { $0 + $1.female }
        let rowDefs: [(String, [Int], Int, Bool)] = [
            ("Male", snapshot.crmRows.map { $0.male }, totalMale, false),
            ("Female", snapshot.crmRows.map { $0.female }, totalFemale, false),
            ("Total", snapshot.crmRows.map { $0.total }, totalMale + totalFemale, true)
        ]
        for def in rowDefs {
            cell(def.0, rect: NSRect(x: x, y: y, width: labelW, height: dataH),
                 bold: def.3, alignment: .left, size: 10)
            cx = x + labelW
            for v in def.1 {
                cell(String(v), rect: NSRect(x: cx, y: y, width: levelW, height: dataH),
                     bold: def.3, size: 10)
                cx += levelW
            }
            cell(String(def.2), rect: NSRect(x: cx, y: y, width: totalW, height: dataH),
                 bold: true, size: 10)
            y += dataH
        }

        y += 8

        if snapshot.keyStage > 0 {
            let groupW = w / 3
            let profileW = groupW * 0.50
            let countW = groupW * 0.25

            cell(
                "KEY STAGE \(snapshot.keyStage)",
                rect: NSRect(x: x, y: y, width: w, height: 14),
                fillColor: NSColor(calibratedWhite: 0.85, alpha: 1),
                bold: true,
                size: 10
            )
            y += 14

            cx = x
            for heading in ["BOSY", "MOSY", "EOSY"] {
                cell(
                    heading,
                    rect: NSRect(x: cx, y: y, width: groupW, height: 14),
                    fillColor: NSColor(calibratedWhite: 0.85, alpha: 1),
                    bold: true,
                    size: 9.2
                )
                cx += groupW
            }
            y += 14

            cx = x
            for _ in 0..<3 {
                cell("Reading Profile", rect: NSRect(x: cx, y: y, width: profileW, height: 18),
                     fillColor: NSColor(calibratedWhite: 0.85, alpha: 1), bold: true, size: 8.2)
                cx += profileW
                cell("Male", rect: NSRect(x: cx, y: y, width: countW, height: 18),
                     fillColor: NSColor(calibratedWhite: 0.85, alpha: 1), bold: true, size: 8.2)
                cx += countW
                cell("Female", rect: NSRect(x: cx, y: y, width: countW, height: 18),
                     fillColor: NSColor(calibratedWhite: 0.85, alpha: 1), bold: true, size: 8.2)
                cx += countW
            }
            y += 18

            let profileH: CGFloat = 13
            for p in snapshot.profileRows {
                let values: [(String, Int, Int)] = [
                    (p.label, p.bosyMale, p.bosyFemale),
                    (p.label, p.mosyMale, p.mosyFemale),
                    (p.label, p.eosyMale, p.eosyFemale)
                ]
                cx = x
                for v in values {
                    cell(v.0, rect: NSRect(x: cx, y: y, width: profileW, height: profileH),
                         alignment: .left, size: 9.5)
                    cx += profileW
                    cell(String(v.1), rect: NSRect(x: cx, y: y, width: countW, height: profileH), size: 10)
                    cx += countW
                    cell(String(v.2), rect: NSRect(x: cx, y: y, width: countW, height: profileH), size: 10)
                    cx += countW
                }
                y += profileH
            }

            let totals = [snapshot.bosyTotal, snapshot.mosyTotal, snapshot.eosyTotal]
            cx = x
            for total in totals {
                cell("Total", rect: NSRect(x: cx, y: y, width: profileW, height: profileH),
                     bold: true, alignment: .left, size: 10)
                cx += profileW
                cell(String(total), rect: NSRect(x: cx, y: y, width: countW * 2, height: profileH),
                     bold: true, size: 10)
                cx += countW * 2
            }
            y += profileH
        } else {
            cell(
                "Set the Grade Level in Setup. Only the applicable Key Stage is printed.",
                rect: NSRect(x: x, y: y, width: w, height: 32),
                fillColor: NSColor(calibratedRed: 1, green: 0.92, blue: 0.92, alpha: 1),
                bold: true, alignment: .left, size: 10
            )
            y += 32
        }

        drawSignatureBlock(pageY: pageY, y: y + 12, x: x, width: w, includeDate: true)
    }

    private enum ListEntry {
        case group(String)
        case pupil(Int, NativePupilRow)
    }

    private func allListEntries() -> [ListEntry] {
        var entries: [ListEntry] = []
        var maleNo = 0
        var femaleNo = 0

        entries.append(.group("MALE"))
        for p in snapshot.pupils.filter({ $0.sex == "Male" }) {
            maleNo += 1
            entries.append(.pupil(maleNo, p))
        }

        entries.append(.group("FEMALE"))
        for p in snapshot.pupils.filter({ $0.sex == "Female" }) {
            femaleNo += 1
            entries.append(.pupil(femaleNo, p))
        }
        return entries
    }

    private func drawPupilList(pageIndex: Int) {
        let pageY = CGFloat(pageIndex) * paperSize.height
        let x = leftMargin
        let w = paperSize.width - leftMargin - rightMargin

        // Full institutional header appears on the first page only.
        var y: CGFloat
        if pageIndex == 0 {
            y = drawHeader(pageOriginY: pageY, title: "LIST OF PUPILS") + 4
        } else {
            y = pageY + topMargin
        }

        let fixedWidths: [CGFloat] = [
            26,   // No.
            78,   // LRN
            160,  // Learner
            38,   // Sex
            63,   // Previous
            63,   // Current
            105,  // Component / Reading Area
            80    // Status
        ]
        let usedWidth = fixedWidths.reduce(0, +)
        let widths = fixedWidths + [max(55, w - usedWidth)] // Color Coding

        let headerH: CGFloat = 24
        let headers = [
            "NO.",
            "LRN",
            "LEARNER",
            "SEX",
            "PREVIOUS\nLEVEL",
            "CURRENT\nLEVEL",
            "COMPONENT /\nREADING AREA",
            "STATUS",
            "COLOR\nCODING"
        ]

        var cx = x
        for i in 0..<headers.count {
            cell(
                headers[i],
                rect: NSRect(x: cx, y: y, width: widths[i], height: headerH),
                fillColor: NSColor(calibratedWhite: 0.85, alpha: 1),
                bold: true,
                size: i == 2 ? 8.8 : 8.0
            )
            cx += widths[i]
        }
        y += headerH

        let entries = allListEntries()
        let start = pupilPageCounts.prefix(pageIndex).reduce(0, +)
        let count = pageIndex < pupilPageCounts.count ? pupilPageCounts[pageIndex] : 0
        let end = min(entries.count, start + count)
        let rowH: CGFloat = 18

        if start < end {
            for entry in entries[start..<end] {
                switch entry {
                case .group(let label):
                    cell(
                        label,
                        rect: NSRect(x: x, y: y, width: w, height: rowH),
                        fillColor: NSColor(calibratedWhite: 0.90, alpha: 1),
                        bold: true,
                        size: 9.5
                    )

                case .pupil(let n, let pupil):
                    // Color Coding remains color-only.
                    let values = [
                        String(n),
                        pupil.lrn,
                        pupil.name,
                        pupil.sex,
                        pupil.previousLevel,
                        pupil.currentLevel,
                        pupilAreaLabel(pupil.area),
                        pupil.status,
                        ""
                    ]

                    cx = x
                    for i in 0..<values.count {
                        let fillColor: NSColor? = i == 8 ? reportLevelColor(pupil.currentLevel) : nil
                        let fontSize: CGFloat
                        switch i {
                        case 1: fontSize = 7.8       // LRN
                        case 2: fontSize = 8.6       // Learner
                        case 6: fontSize = 6.6       // Reading area
                        case 7: fontSize = 7.2       // Status
                        default: fontSize = 8.2
                        }

                        cell(
                            values[i],
                            rect: NSRect(x: cx, y: y, width: widths[i], height: rowH),
                            fillColor: fillColor,
                            bold: i == 2,
                            alignment: i == 2 ? .left : .center,
                            size: fontSize
                        )
                        cx += widths[i]
                    }
                }
                y += rowH
            }
        }

        if pageIndex == pageCount - 1 {
            y += 6

            let summaryW: CGFloat = 350
            let labelW: CGFloat = 150
            let totalW: CGFloat = 45
            let sexLabelW: CGFloat = 55
            let sexCountW: CGFloat = 45

            cell(
                "TOTAL ENROLLMENT:",
                rect: NSRect(x: x, y: y, width: labelW, height: 20),
                bold: true, alignment: .left, size: 9.5
            )
            cell(
                String(snapshot.maleCount + snapshot.femaleCount),
                rect: NSRect(x: x + labelW, y: y, width: totalW, height: 20),
                bold: true, size: 9.5
            )
            cell(
                "MALE:",
                rect: NSRect(x: x + labelW + totalW, y: y, width: sexLabelW, height: 20),
                bold: true, size: 8.5
            )
            cell(
                String(snapshot.maleCount),
                rect: NSRect(x: x + labelW + totalW + sexLabelW, y: y, width: sexCountW, height: 20),
                size: 9
            )
            cell(
                "FEMALE:",
                rect: NSRect(x: x + labelW + totalW + sexLabelW + sexCountW, y: y, width: sexLabelW, height: 20),
                bold: true, size: 8.5
            )
            cell(
                String(snapshot.femaleCount),
                rect: NSRect(x: x + labelW + totalW + sexLabelW * 2 + sexCountW, y: y, width: sexCountW, height: 20),
                size: 9
            )
            y += 24

            drawSignatureBlock(pageY: pageY, y: y, x: x, width: w, includeDate: true)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.white.setFill()
        dirtyRect.fill()

        for pageIndex in 0..<pageCount {
            let pageRect = NSRect(
                x: 0,
                y: CGFloat(pageIndex) * paperSize.height,
                width: paperSize.width,
                height: paperSize.height
            )
            guard dirtyRect.intersects(pageRect) else { continue }

            if type == .classroomMonitoring {
                drawCRM(pageIndex: pageIndex)
            } else {
                drawPupilList(pageIndex: pageIndex)
            }
        }
    }

    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        range.pointee = NSRange(location: 1, length: pageCount)
        return true
    }

    override func rectForPage(_ page: Int) -> NSRect {
        let index = max(0, min(page - 1, pageCount - 1))
        return NSRect(
            x: 0,
            y: CGFloat(index) * paperSize.height,
            width: paperSize.width,
            height: paperSize.height
        )
    }

    func pdfData() -> Data? {
        let output = PDFDocument()
        for pageIndex in 0..<pageCount {
            let rect = rectForPage(pageIndex + 1)
            let onePageData = dataWithPDF(inside: rect)
            guard let onePageDocument = PDFDocument(data: onePageData),
                  let page = onePageDocument.page(at: 0) else {
                return nil
            }
            output.insert(page, at: output.pageCount)
        }
        return output.dataRepresentation()
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published var data = AppData()
    @Published var selectedAP = "AP1"
    @Published var statusMessage = "Ready"
    @Published var assessmentLocks: [String: Bool] = [:]
    private let appName = "BULIG RMS Teacher"

    init() {
        load()
        loadAssessmentLocks()
        migrateLearnerNameFields()
        migratePreAssessmentHistory()
    }

    private var supportFolder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent(appName, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private var dataURL: URL { supportFolder.appendingPathComponent("data.json") }

    private var locksURL: URL { supportFolder.appendingPathComponent("assessment-locks.json") }

    private var restoreFolder: URL {
        let folder = supportFolder.appendingPathComponent("Restore Points", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private var archiveFolder: URL {
        let folder = supportFolder.appendingPathComponent("School Year Archives", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func safeFilePart(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return value.unicodeScalars.map { allowed.contains($0) ? String($0) : "_" }.joined()
    }

    private func fileTimestamp(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }

    private func loadAssessmentLocks() {
        guard let raw = try? Data(contentsOf: locksURL),
              let decoded = try? JSONDecoder().decode([String: Bool].self, from: raw) else {
            assessmentLocks = [:]
            return
        }
        assessmentLocks = decoded
    }

    private func saveAssessmentLocks() {
        if let raw = try? JSONEncoder.pretty.encode(assessmentLocks) {
            try? raw.write(to: locksURL, options: .atomic)
        }
    }

    func isAssessmentLocked(_ ap: String) -> Bool {
        assessmentLocks[ap] == true
    }

    func setAssessmentLocked(_ ap: String, locked: Bool) {
        createRestorePoint(reason: locked ? "Before finalizing \(ap)" : "Before unlocking \(ap)")
        assessmentLocks[ap] = locked
        saveAssessmentLocks()
        statusMessage = locked ? "\(ap) finalized and locked" : "\(ap) unlocked"
    }

    func createRestorePoint(reason: String) {
        do {
            let raw = try JSONEncoder.pretty.encode(data)
            let name = "\(fileTimestamp())_\(safeFilePart(reason)).json"
            let url = restoreFolder.appendingPathComponent(name)
            try raw.write(to: url, options: .atomic)

            let files = (try? FileManager.default.contentsOfDirectory(
                at: restoreFolder,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )) ?? []

            let sorted = files.sorted {
                let l = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let r = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return l > r
            }
            if sorted.count > 10 {
                for old in sorted.dropFirst(10) {
                    try? FileManager.default.removeItem(at: old)
                }
            }
        } catch {
            statusMessage = "Restore point could not be created"
        }
    }

    func restorePoints() -> [RestorePointInfo] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: restoreFolder,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return files.compactMap { url in
            guard url.pathExtension.lowercased() == "json" else { return nil }
            let date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let raw = url.deletingPathExtension().lastPathComponent
            let pieces = raw.split(separator: "_", maxSplits: 1).map(String.init)
            let title = pieces.count > 1 ? pieces[1].replacingOccurrences(of: "_", with: " ") : "Restore Point"
            return RestorePointInfo(id: url.path, url: url, title: title, date: date)
        }
        .sorted { $0.date > $1.date }
    }

    func restoreFromPoint(_ point: RestorePointInfo) {
        do {
            let decoded = try JSONDecoder().decode(AppData.self, from: Data(contentsOf: point.url))
            createRestorePoint(reason: "Before restoring older version")
            data = decoded
            save()
            statusMessage = "Restore point loaded"
        } catch {
            statusMessage = "Restore point is invalid"
        }
    }

    func schoolYearArchives() -> [SchoolYearArchiveInfo] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: archiveFolder,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return files.compactMap { url in
            guard url.pathExtension.lowercased() == "json" else { return nil }
            let date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let base = url.deletingPathExtension().lastPathComponent
            let year = base.components(separatedBy: "__").first ?? base
            return SchoolYearArchiveInfo(id: url.path, url: url, schoolYear: year, date: date)
        }
        .sorted { $0.date > $1.date }
    }

    func archiveAndStartNewSchoolYear(_ newSchoolYear: String) -> String {
        let cleaned = newSchoolYear.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "Enter the new school year first." }

        do {
            createRestorePoint(reason: "Before starting school year \(cleaned)")
            let currentYear = data.settings.schoolYear.isEmpty ? "Unspecified" : data.settings.schoolYear
            let archiveURL = archiveFolder.appendingPathComponent(
                "\(safeFilePart(currentYear))__\(fileTimestamp()).json"
            )
            try JSONEncoder.pretty.encode(data).write(to: archiveURL, options: .atomic)

            var newData = AppData()
            newData.settings = data.settings
            newData.settings.schoolYear = cleaned
            newData.settings.gradeLevel = ""
            newData.settings.section = ""
            newData.settings.adviser = ""
            newData.assessmentTerms = ["PRETEST": "1ST"]
                .merging(Dictionary(uniqueKeysWithValues: (1...15).map { ("AP\($0)", "1ST") })) { current, _ in current }
            newData.learners = []

            data = newData
            assessmentLocks = [:]
            saveAssessmentLocks()
            save()
            return "School year \(currentYear) was archived. BULIG is ready for \(cleaned)."
        } catch {
            return "The new school year could not be started."
        }
    }

    func openSchoolYearArchive(_ archive: SchoolYearArchiveInfo) {
        do {
            createRestorePoint(reason: "Before opening archived school year")
            let decoded = try JSONDecoder().decode(AppData.self, from: Data(contentsOf: archive.url))
            data = decoded
            assessmentLocks = [:]
            saveAssessmentLocks()
            save()
            statusMessage = "Opened archived school year \(archive.schoolYear)"
        } catch {
            statusMessage = "Archive could not be opened"
        }
    }

    func removeLearner(_ learnerID: UUID) {
        guard let index = data.learners.firstIndex(where: { $0.id == learnerID }) else { return }
        createRestorePoint(reason: "Before removing learner")
        data.learners.remove(at: index)
        save()
    }

    func reactivateLearner(_ learnerID: UUID, at ap: String) {
        guard let index = data.learners.firstIndex(where: { $0.id == learnerID }) else { return }
        createRestorePoint(reason: "Before reactivating learner")
        if !data.learners[index].reactivationAPs.contains(ap) {
            data.learners[index].reactivationAPs.append(ap)
        }
        save()
    }

    func setInactiveDetails(learnerID: UUID, ap: String, note: String, effectiveDate: String) {
        guard let index = data.learners.firstIndex(where: { $0.id == learnerID }),
              var entry = data.learners[index].assessments[ap] else { return }
        entry.note = note
        entry.effectiveDate = effectiveDate
        data.learners[index].assessments[ap] = entry
        save()
    }

    func completedReportStages() -> [String] {
        var stages = ["PRETEST"]
        for ap in assessmentPeriods {
            if data.learners.contains(where: { !($0.assessments[ap]?.result ?? "").isEmpty }) {
                stages.append(ap)
            }
        }
        return stages
    }

    private func logoURL(fileName: String?) -> URL? {
        guard let fileName, !fileName.isEmpty else { return nil }
        return supportFolder.appendingPathComponent(fileName)
    }

    func reportLogoImage(left: Bool) -> NSImage? {
        let fileName = left ? data.settings.leftReportLogoFile : data.settings.rightReportLogoFile
        guard let url = logoURL(fileName: fileName) else { return nil }
        return NSImage(contentsOf: url)
    }

    func reportLogoData(left: Bool) -> Data? {
        let fileName = left ? data.settings.leftReportLogoFile : data.settings.rightReportLogoFile
        guard let url = logoURL(fileName: fileName) else { return nil }
        return try? Data(contentsOf: url)
    }

    func chooseReportLogo(left: Bool) -> String? {
        let panel = NSOpenPanel()
        panel.title = left ? "Choose Left Report Logo" : "Choose Right Report Logo"
        panel.message = "Choose a PNG, JPG, or JPEG image to use on all printed BULIG reports."
        panel.allowedFileTypes = ["png", "jpg", "jpeg"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let sourceURL = panel.url else { return nil }
        guard let image = NSImage(contentsOf: sourceURL) else {
            return "The selected file could not be opened as an image."
        }

        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            return "The selected image could not be prepared for the report."
        }

        let fileName = left ? "ReportLeftLogo.png" : "ReportRightLogo.png"
        let destination = supportFolder.appendingPathComponent(fileName)

        do {
            try png.write(to: destination, options: .atomic)
            if left {
                data.settings.leftReportLogoFile = fileName
            } else {
                data.settings.rightReportLogoFile = fileName
            }
            save()
            return left ? "Left report logo saved." : "Right report logo saved."
        } catch {
            return "The logo could not be saved."
        }
    }

    func clearReportLogo(left: Bool) {
        let fileName = left ? data.settings.leftReportLogoFile : data.settings.rightReportLogoFile
        if let url = logoURL(fileName: fileName) {
            try? FileManager.default.removeItem(at: url)
        }
        if left {
            data.settings.leftReportLogoFile = nil
        } else {
            data.settings.rightReportLogoFile = nil
        }
        save()
    }

    func save() {
        do {
            let encoded = try JSONEncoder.pretty.encode(data)
            try encoded.write(to: dataURL, options: .atomic)
            statusMessage = "Saved"
        } catch {
            statusMessage = "Save failed"
        }
    }

    func load() {
        guard let raw = try? Data(contentsOf: dataURL),
              let decoded = try? JSONDecoder().decode(AppData.self, from: raw) else { return }
        data = decoded
    }

    func addLearner() {
        data.learners.append(Learner())
        save()
    }

    func deleteLearners(at offsets: IndexSet) {
        data.learners.remove(atOffsets: offsets)
        save()
    }

    func keyStage() -> Int {
        guard let g = Int(data.settings.gradeLevel) else { return 0 }
        if g <= 3 { return 1 }
        if g <= 6 { return 2 }
        if g <= 10 { return 3 }
        return 4
    }

    func profileOptions() -> [String] {
        switch keyStage() {
        case 1: return ["", "Low Emerging", "High Emerging", "Developing", "Transitioning", "Grade Level Ready"]
        default: return ["", "Frustration", "Instructional", "Independent"]
        }
    }

    func schoolYearOptions() -> [String] {
        var years = Set<String>()
        if !data.settings.schoolYear.isEmpty { years.insert(data.settings.schoolYear) }
        for learner in data.learners {
            for year in learner.preHistory.keys { years.insert(year) }
        }

        let current = Calendar.current.component(.year, from: Date())
        for start in (current - 5)...(current + 5) {
            years.insert("\(start)-\(start + 1)")
        }

        return years.sorted {
            let lhs = Int($0.split(separator: "-").first ?? "") ?? 0
            let rhs = Int($1.split(separator: "-").first ?? "") ?? 0
            return lhs > rhs
        }
    }

    func preAssessment(for learner: Learner, schoolYear: String? = nil) -> PreAssessment {
        let year = schoolYear ?? data.settings.schoolYear
        if let saved = learner.preHistory[year] { return saved }
        if learner.preHistory.isEmpty && year == data.settings.schoolYear { return learner.pre }
        return PreAssessment()
    }

    private func setPreAssessment(_ value: PreAssessment, learnerID: UUID, schoolYear: String) {
        guard let index = data.learners.firstIndex(where: { $0.id == learnerID }) else { return }
        data.learners[index].preHistory[schoolYear] = value
        if schoolYear == data.settings.schoolYear {
            data.learners[index].pre = value
        }
        save()
    }

    func preLevelBinding(for learnerID: UUID, schoolYear: String) -> Binding<String> {
        Binding(
            get: {
                guard let learner = self.data.learners.first(where: { $0.id == learnerID }) else { return "" }
                return self.preAssessment(for: learner, schoolYear: schoolYear).level
            },
            set: { newValue in
                guard let learner = self.data.learners.first(where: { $0.id == learnerID }) else { return }
                var value = self.preAssessment(for: learner, schoolYear: schoolYear)
                value.level = newValue
                self.setPreAssessment(value, learnerID: learnerID, schoolYear: schoolYear)
            }
        )
    }

    func preProfileBinding(for learnerID: UUID, schoolYear: String, period: String) -> Binding<String> {
        Binding(
            get: {
                guard let learner = self.data.learners.first(where: { $0.id == learnerID }) else { return "" }
                let value = self.preAssessment(for: learner, schoolYear: schoolYear)
                switch period {
                case "MOSY": return value.mosy
                case "EOSY": return value.eosy
                default: return value.bosy
                }
            },
            set: { newValue in
                guard let learner = self.data.learners.first(where: { $0.id == learnerID }) else { return }
                var value = self.preAssessment(for: learner, schoolYear: schoolYear)
                switch period {
                case "MOSY": value.mosy = newValue
                case "EOSY": value.eosy = newValue
                default: value.bosy = newValue
                }
                self.setPreAssessment(value, learnerID: learnerID, schoolYear: schoolYear)
            }
        )
    }

    private func migratePreAssessmentHistory() {
        let year = data.settings.schoolYear
        guard !year.isEmpty else { return }

        var changed = false
        for index in data.learners.indices {
            if data.learners[index].preHistory[year] == nil {
                let legacy = data.learners[index].pre
                if !legacy.level.isEmpty || !legacy.bosy.isEmpty || !legacy.mosy.isEmpty || !legacy.eosy.isEmpty {
                    data.learners[index].preHistory[year] = legacy
                    changed = true
                }
            }
        }
        if changed { save() }
    }

    func nextLevel(_ level: String) -> String {
        guard let idx = readingLevels.firstIndex(where: { $0.code == level }) else { return level }
        return readingLevels[min(idx + 1, readingLevels.count - 1)].code
    }

    func previousLevel(_ level: String) -> String {
        guard let idx = readingLevels.firstIndex(where: { $0.code == level }) else { return level }
        return readingLevels[max(idx - 1, 0)].code
    }

    func isInactiveStatus(_ result: String) -> Bool {
        ["NLS", "NLP", "TRANSFER OUT"].contains(result)
    }

    func defaultLevelAfter(result: String, from level: String) -> String {
        guard !level.isEmpty else { return "" }
        switch result {
        case "READY":
            return nextLevel(level)
        case "REVERTED":
            return previousLevel(level)
        default:
            return level
        }
    }

    func appliedLevel(for entry: AssessmentEntry?, from level: String) -> String {
        guard let entry else { return level }
        if !entry.overrideLevel.isEmpty {
            return entry.overrideLevel
        }
        return defaultLevelAfter(result: entry.result, from: level)
    }

    func inactiveStatusBeforeAP(_ learner: Learner, ap: String) -> (period: String, status: String)? {
        guard let target = assessmentPeriods.firstIndex(of: ap) else { return nil }

        var latestInactive: (index: Int, period: String, status: String)? = nil
        for i in 0..<target {
            let key = assessmentPeriods[i]
            if let entry = learner.assessments[key], isInactiveStatus(entry.result) {
                latestInactive = (i, key, entry.result)
            }
        }

        guard let inactive = latestInactive else { return nil }

        let latestReactivation = learner.reactivationAPs.compactMap { key -> Int? in
            guard let index = assessmentPeriods.firstIndex(of: key), index <= target else { return nil }
            return index
        }.max()

        if let latestReactivation, latestReactivation > inactive.index {
            return nil
        }
        return (inactive.period, inactive.status)
    }

    func levelBeforeAP(_ learner: Learner, ap: String) -> String {
        var level = preAssessment(for: learner).level
        guard !level.isEmpty else { return "" }
        guard let target = assessmentPeriods.firstIndex(of: ap), target > 0 else { return level }

        var inactive = false
        for i in 0..<target {
            let key = assessmentPeriods[i]
            if learner.reactivationAPs.contains(key) {
                inactive = false
            }

            guard let entry = learner.assessments[key] else { continue }
            if inactive { continue }

            level = appliedLevel(for: entry, from: level)
            if isInactiveStatus(entry.result) {
                inactive = true
            }
        }
        return level
    }

    func levelAfterAP(_ learner: Learner, ap: String) -> String {
        let before = levelBeforeAP(learner, ap: ap)
        guard inactiveStatusBeforeAP(learner, ap: ap) == nil else { return before }
        return appliedLevel(for: learner.assessments[ap], from: before)
    }

    func currentLevel(_ learner: Learner, through ap: String?) -> String {
        guard let ap else { return preAssessment(for: learner).level }
        var level = preAssessment(for: learner).level
        guard !level.isEmpty else { return "" }

        var inactive = false
        for key in assessmentPeriods {
            if learner.reactivationAPs.contains(key) {
                inactive = false
            }

            if let entry = learner.assessments[key], !inactive {
                level = appliedLevel(for: entry, from: level)
                if isInactiveStatus(entry.result) {
                    inactive = true
                }
            }

            if key == ap { break }
        }
        return level
    }

    private func cleanedNameText(_ value: String) -> String {
        value.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedNameExtension(_ value: String) -> String? {
        let token = value.uppercased()
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let extensions = ["JR", "SR", "I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
        guard extensions.contains(token) else { return nil }
        return token
    }

    private func splitSF1Name(_ rawValue: String) -> (firstName: String, middleInitial: String, lastName: String, extensionName: String) {
        let raw = cleanedNameText(rawValue)
        guard !raw.isEmpty else { return ("", "", "", "") }

        let commaParts = raw.split(separator: ",", omittingEmptySubsequences: false)
            .map { cleanedNameText(String($0)) }

        let lastName = commaParts.first ?? ""

        // Standard SF1 header:
        // Last Name, First Name, Name Extension, Middle Name
        if commaParts.count >= 4 {
            let first = commaParts[1]
            let ext = normalizedNameExtension(commaParts[2]) ?? commaParts[2].uppercased()
            let middle = commaParts[3]
            let mi = middle.first.map { String($0).uppercased() } ?? ""
            return (first.uppercased(), mi, lastName.uppercased(), ext)
        }

        if commaParts.count == 3 {
            let first = commaParts[1]
            let third = commaParts[2]
            if let ext = normalizedNameExtension(third) {
                return (first.uppercased(), "", lastName.uppercased(), ext)
            }
            let mi = third.first.map { String($0).uppercased() } ?? ""
            return (first.uppercased(), mi, lastName.uppercased(), "")
        }

        let remainder = commaParts.count >= 2 ? commaParts.dropFirst().joined(separator: " ") : raw
        var tokens = cleanedNameText(remainder).split(separator: " ").map(String.init)
        guard !tokens.isEmpty else { return ("", "", lastName.uppercased(), "") }

        var extensionName = ""
        if let extIndex = tokens.firstIndex(where: { normalizedNameExtension($0) != nil }) {
            extensionName = normalizedNameExtension(tokens[extIndex]) ?? ""
            tokens.remove(at: extIndex)
        }

        if tokens.count == 1 {
            return (tokens[0].uppercased(), "", lastName.uppercased(), extensionName)
        }

        // In SF1, the middle name follows the first name and extension.
        // Keep all preceding words as the first name so compound first names remain intact.
        let middleName = tokens.removeLast()
        let middleInitial = middleName.first.map { String($0).uppercased() } ?? ""
        let firstName = tokens.joined(separator: " ").uppercased()
        return (firstName, middleInitial, lastName.uppercased(), extensionName)
    }

    private func canonicalFullName(firstName: String, middleInitial: String, lastName: String, extensionName: String) -> String {
        var pieces: [String] = []
        if !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pieces.append(lastName.uppercased() + ",")
        }
        if !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pieces.append(firstName.uppercased())
        }
        if !nameExtensionSafe(extensionName).isEmpty {
            pieces.append(nameExtensionSafe(extensionName))
        }
        if !middleInitial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pieces.append(String(middleInitial.uppercased().prefix(1)) + ".")
        }
        return pieces.joined(separator: " ")
    }

    private func nameExtensionSafe(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedNameExtension(trimmed) ?? trimmed.uppercased()
    }

    private func migrateLearnerNameFields() {
        var changed = false
        for index in data.learners.indices {
            let learner = data.learners[index]
            if learner.firstName.isEmpty && learner.lastName.isEmpty && !learner.fullName.isEmpty {
                let parts = splitSF1Name(learner.fullName)
                data.learners[index].firstName = parts.firstName
                data.learners[index].middleInitial = parts.middleInitial
                data.learners[index].lastName = parts.lastName
                data.learners[index].nameExtension = parts.extensionName
                changed = true
            }
        }
        if changed { save() }
    }

    func importFromClipboard() -> Int {
        guard let text = NSPasteboard.general.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        createRestorePoint(reason: "Before clipboard SF1 import")
        var added = 0
        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            let cols = line.split(separator: "\t", omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespaces) }
            guard cols.count >= 2 else { continue }
            let maybeLRN = cols[0].filter(\.isNumber)
            guard maybeLRN.count == 12 else { continue }
            if data.learners.contains(where: { $0.lrn == maybeLRN }) { continue }
            let sexRaw = cols.count > 2 ? cols[2].uppercased() : ""
            let sex = ["M", "MALE"].contains(sexRaw) ? "Male" : (["F", "FEMALE"].contains(sexRaw) ? "Female" : "")
            let dob = cols.count > 3 ? cols[3] : ""
            let nameParts = splitSF1Name(cols[1])
            data.learners.append(Learner(
                lrn: maybeLRN,
                fullName: cols[1],
                firstName: nameParts.firstName,
                middleInitial: nameParts.middleInitial,
                lastName: nameParts.lastName,
                nameExtension: nameParts.extensionName,
                sex: sex,
                dateOfBirth: dob
            ))
            added += 1
        }
        save()
        return added
    }

    private func normalizeSF1Header(_ value: String) -> String {
        value.uppercased()
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sf1HeaderColumns(in rows: [[String]]) -> (row: Int, lrn: Int, name: Int, sex: Int, birth: Int)? {
        for (rowIndex, row) in rows.enumerated() {
            var lrnColumn: Int?
            var nameColumn: Int?
            var sexColumn: Int?
            var birthColumn: Int?

            for (columnIndex, raw) in row.enumerated() {
                let value = normalizeSF1Header(raw)
                if lrnColumn == nil && value.contains("LRN") {
                    lrnColumn = columnIndex
                }
                if nameColumn == nil && (value == "NAME" || value.hasPrefix("NAME ") || value.contains("LAST NAME")) {
                    nameColumn = columnIndex
                }
                if sexColumn == nil && value.contains("SEX") {
                    sexColumn = columnIndex
                }
                if birthColumn == nil && value.contains("BIRTH") && value.contains("DATE") {
                    birthColumn = columnIndex
                }
            }

            if let lrnColumn, let nameColumn, let sexColumn, let birthColumn {
                return (rowIndex, lrnColumn, nameColumn, sexColumn, birthColumn)
            }
        }
        return nil
    }

    private func parseSpreadsheetSheets(at url: URL) throws -> [SF1ParsedSheet] {
        guard let parserURL = Bundle.main.url(forResource: "xlsx.full.min", withExtension: "js") else {
            throw SF1ImportError.parserMissing
        }
        guard let context = JSContext() else {
            throw SF1ImportError.unreadable
        }

        var javascriptError = ""
        context.exceptionHandler = { _, exception in
            javascriptError = exception?.toString() ?? "Unknown spreadsheet parsing error."
        }

        let parserScript = try String(contentsOf: parserURL, encoding: .utf8)
        context.evaluateScript(parserScript)
        if !javascriptError.isEmpty {
            throw SF1ImportError.javascript(javascriptError)
        }

        let fileData = try Data(contentsOf: url)
        context.setObject(fileData.base64EncodedString(), forKeyedSubscript: "__bulig_sf1_base64" as NSString)

        let conversionScript = """
        (function () {
          try {
            var wb = XLSX.read(__bulig_sf1_base64, { type: 'base64', cellDates: false });
            var output = wb.SheetNames.map(function (sheetName) {
              var ws = wb.Sheets[sheetName];
              var rows = XLSX.utils.sheet_to_json(ws, { header: 1, raw: false, defval: '' });
              rows = rows.map(function (row) {
                return row.map(function (value) {
                  return value == null ? '' : String(value);
                });
              });
              return { name: String(sheetName), rows: rows };
            });
            return JSON.stringify(output);
          } catch (e) {
            throw e;
          }
        })();
        """

        guard let jsonValue = context.evaluateScript(conversionScript),
              javascriptError.isEmpty,
              let json = jsonValue.toString(),
              let jsonData = json.data(using: .utf8) else {
            throw SF1ImportError.javascript(javascriptError.isEmpty ? "Invalid spreadsheet data." : javascriptError)
        }

        return try JSONDecoder().decode([SF1ParsedSheet].self, from: jsonData)
    }

    func importSF1File() -> String? {
        let panel = NSOpenPanel()
        panel.title = "Import School Form 1 (SF1)"
        panel.message = "Select the DepEd SF1 Excel file. BULIG will import LRN, learner name, sex, and birth date."
        panel.allowedFileTypes = ["xls", "xlsx", "xlsm"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        do {
            let sheets = try parseSpreadsheetSheets(at: url)

            var selectedSheet: SF1ParsedSheet?
            var header: (row: Int, lrn: Int, name: Int, sex: Int, birth: Int)?

            for sheet in sheets {
                if let found = sf1HeaderColumns(in: sheet.rows) {
                    selectedSheet = sheet
                    header = found
                    break
                }
            }

            guard let sheet = selectedSheet, let columns = header else {
                throw SF1ImportError.noSF1Sheet
            }

            createRestorePoint(reason: "Before SF1 import")
            var foundCount = 0
            var importedCount = 0
            var duplicateCount = 0
            var invalidCount = 0
            var seenLRNs = Set(data.learners.map { $0.lrn.filter(\.isNumber) })

            for row in sheet.rows.dropFirst(columns.row + 1) {
                func cell(_ index: Int) -> String {
                    guard index >= 0, index < row.count else { return "" }
                    return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
                }

                let lrn = cell(columns.lrn).filter(\.isNumber)
                let name = cell(columns.name)
                let rawSex = cell(columns.sex).uppercased()
                let birthDate = cell(columns.birth)

                // Actual learner records in SF1 have a 12-digit LRN.
                guard !lrn.isEmpty || !name.isEmpty else { continue }
                guard lrn.count == 12 else {
                    if !name.isEmpty && !normalizeSF1Header(name).contains("TOTAL") {
                        invalidCount += 1
                    }
                    continue
                }

                foundCount += 1

                if seenLRNs.contains(lrn) {
                    duplicateCount += 1
                    continue
                }

                let sex: String
                if rawSex == "M" || rawSex == "MALE" {
                    sex = "Male"
                } else if rawSex == "F" || rawSex == "FEMALE" {
                    sex = "Female"
                } else {
                    sex = ""
                }

                let nameParts = splitSF1Name(name)
                data.learners.append(
                    Learner(
                        lrn: lrn,
                        fullName: name,
                        firstName: nameParts.firstName,
                        middleInitial: nameParts.middleInitial,
                        lastName: nameParts.lastName,
                        nameExtension: nameParts.extensionName,
                        sex: sex,
                        dateOfBirth: birthDate
                    )
                )
                seenLRNs.insert(lrn)
                importedCount += 1
            }

            save()

            var lines = [
                "SF1 import completed.",
                "Worksheet: \(sheet.name)",
                "Learners found: \(foundCount)",
                "New learners imported: \(importedCount)"
            ]
            if duplicateCount > 0 { lines.append("Existing LRNs skipped: \(duplicateCount)") }
            if invalidCount > 0 { lines.append("Rows skipped because the LRN was invalid or incomplete: \(invalidCount)") }
            return lines.joined(separator: "\n")
        } catch {
            return "SF1 import failed.\n\(error.localizedDescription)"
        }
    }

    func exportBackup() {
        let panel = NSSavePanel()
        panel.title = "Save BULIG Backup"
        panel.nameFieldStringValue = "BULIG_RMS_Backup.json"
        panel.allowedFileTypes = ["json"]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try JSONEncoder.pretty.encode(data).write(to: url, options: .atomic)
                statusMessage = "Backup saved"
            } catch {
                statusMessage = "Backup failed"
            }
        }
    }

    func restoreBackup() {
        let panel = NSOpenPanel()
        panel.title = "Restore BULIG Backup"
        panel.allowedFileTypes = ["json"]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            createRestorePoint(reason: "Before restoring backup")
            let decoded = try JSONDecoder().decode(AppData.self, from: Data(contentsOf: url))
            data = decoded
            save()
            statusMessage = "Backup restored"
        } catch {
            statusMessage = "Invalid backup file"
        }
    }

    func reportRows(stage: String) -> [(String, Int, Int, Int)] {
        readingLevels.map { level in
            let matches = data.learners.filter { learner in
                let current = stage == "PRETEST" ? preAssessment(for: learner).level : currentLevel(learner, through: stage)
                return current == level.code
            }
            let male = matches.filter { $0.sex == "Male" }.count
            let female = matches.filter { $0.sex == "Female" }.count
            return (level.code, male, female, male + female)
        }
    }

    func learnersForStage(_ stage: String) -> [(Learner, String)] {
        data.learners.map { learner in
            let level = stage == "PRETEST" ? preAssessment(for: learner).level : currentLevel(learner, through: stage)
            return (learner, level)
        }
    }

    func profileLabelsForCurrentKeyStage() -> [String] {
        keyStage() == 1
            ? ["Low Emerging", "High Emerging", "Developing", "Transitioning", "Grade Level Ready"]
            : ["Frustration", "Instructional", "Independent"]
    }

    func storedProfileValue(_ plain: String) -> String {
        guard keyStage() > 1 else { return plain }
        return "KS\(keyStage())_\(plain)"
    }

    func profileCount(_ profile: String, checkpoint: KeyPath<PreAssessment, String>, sex: String) -> Int {
        let target = storedProfileValue(profile)
        return data.learners.filter { learner in
            let value = preAssessment(for: learner)[keyPath: checkpoint]
            return learner.sex == sex && (value == target || value == profile)
        }.count
    }

    func reportText(stage: String) -> String {
        let s = data.settings
        var lines: [String] = []
        lines.append("BULIG RMS – TEACHER")
        lines.append("Bukidnon's Unified Literacy and Intervention Gateway")
        lines.append("")
        lines.append("School: \(s.schoolName)")
        lines.append("School ID: \(s.schoolId)    School Year: \(s.schoolYear)")
        lines.append("Grade & Section: Grade \(s.gradeLevel) – \(s.section)")
        lines.append("Adviser: \(s.adviser)    Subject: \(s.subject)")
        lines.append("Assessment: \(stage == "PRETEST" ? "PRETEST" : stage)")
        lines.append("")
        lines.append("LEVEL\tMALE\tFEMALE\tTOTAL")
        for row in reportRows(stage: stage) { lines.append("\(row.0)\t\(row.1)\t\(row.2)\t\(row.3)") }
        lines.append("")
        if keyStage() > 0 { lines.append("KEY STAGE \(keyStage()) only") }
        lines.append("TOTAL LEARNERS: \(data.learners.count)")
        return lines.joined(separator: "\n")
    }

    private func htmlEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private func termFor(_ stage: String) -> String {
        data.assessmentTerms[stage] ?? "1ST"
    }

    private func levelColor(_ level: String) -> String {
        switch level {
        case "LEVEL 1": return "#ffd7d2"
        case "LEVEL 2A": return "#ffe6b8"
        case "LEVEL 2B": return "#fff0a8"
        case "LEVEL 3A": return "#e1f3b8"
        case "LEVEL 3B": return "#c9ecc2"
        case "LEVEL 4": return "#bee9ef"
        case "LEVEL 5": return "#cbdcf7"
        case "LEVEL 6": return "#d6cef5"
        case "LEVEL 7": return "#ead0f2"
        default: return "#ffffff"
        }
    }

    private func reportHeaderHTML(stage: String, title: String) -> String {
        let s = data.settings
        return """
        <div class="brandrow">
          <div class="deped-mark">DepEd<br><span>Bukidnon</span></div>
          <div class="agency">
            <div>Department of Education</div>
            <div>\(htmlEscape(s.region))</div>
            <div>\(htmlEscape(s.division))</div>
            <div><b>\(htmlEscape(s.schoolName))</b></div>
          </div>
          <div><img class="bulig" src="BuligLogo.jpg"></div>
        </div>
        <div class="gateway">BUKIDNON'S UNIFIED LITERACY AND INTERVENTION GATEWAY</div>
        <div class="tagline">Building Up Literacy, Inspiring Growth</div>
        <div class="title">\(title)</div>
        <table class="meta">
          <tr><td class="label">Adviser</td><td>\(htmlEscape(s.adviser))</td><td class="label">ASSESSMENT PERIOD</td><td>\(htmlEscape(stage))</td></tr>
          <tr><td class="label">Grade Level</td><td>\(htmlEscape(s.gradeLevel))</td><td class="label">Term</td><td>\(htmlEscape(termFor(stage)))</td></tr>
          <tr><td class="label">Section</td><td>\(htmlEscape(s.section))</td><td class="label">Assessment Tool</td><td>\(htmlEscape(s.assessmentTool))</td></tr>
          <tr><td></td><td></td><td class="label">SUBJECT</td><td>\(htmlEscape(s.subject))</td></tr>
        </table>
        """
    }

    private func sharedReportCSS(landscape: Bool) -> String {
        """
        <style>
        @page { size: A4 \(landscape ? "landscape" : "portrait"); margin: 0.5in 1in; }
        * { box-sizing: border-box; }
        body { font-family: Arial, Helvetica, sans-serif; color:#000; margin:0; font-size:12pt; }
        .brandrow { display:grid; grid-template-columns: 140px 1fr 260px; align-items:center; min-height:84px; }
        .deped-mark { text-align:center; font-size:17px; font-weight:800; color:#124b91; line-height:1.1; }
        .deped-mark span { font-size:10px; color:#333; }
        .bulig { width:245px; max-height:82px; object-fit:contain; display:block; margin-left:auto; }
        .agency { text-align:center; line-height:1.25; font-family:Georgia,serif; }
        .gateway { text-align:center; font-weight:700; font-family:Georgia,serif; font-size:14px; margin-top:2px; }
        .tagline { text-align:center; font-weight:700; font-family:Georgia,serif; font-size:12px; }
        .title { text-align:center; font-weight:800; font-family:Georgia,serif; font-size:18px; margin:5px 0 15px; }
        table { border-collapse:collapse; width:100%; }
        .meta td { border:1.4px solid #000; min-height:22px; padding:4px 6px; font-size:12pt; }
        .meta .label { text-align:center; font-weight:600; width:18%; }
        .levels { margin-top:18px; table-layout:fixed; }
        .levels th,.levels td,.profile th,.profile td,.pupils th,.pupils td { border:1.35px solid #000; padding:4px 4px; text-align:center; }
        .levels th,.profile th,.pupils th { background:#d9d9d9; font-weight:700; }
        .levels .area { font-size:9pt; line-height:1.12; }
        .left { text-align:left !important; }
        .profile-title { margin-top:18px; background:#d9d9d9; border:1.35px solid #000; border-bottom:0; text-align:center; font-weight:800; font-size:13px; padding:4px; }
        .profile { table-layout:fixed; }
        .signature-row { display:grid; grid-template-columns:1fr 1fr 150px; gap:45px; margin-top:34px; align-items:end; font-size:12pt; }
        .sig { text-align:center; font-size:12pt; }
        .sig .name { border-bottom:1px solid #000; min-height:24px; padding-top:11px; font-weight:700; }
        .datebox { text-align:center; font-size:12pt; }
        .datebox .date { border-bottom:1px solid #000; padding-bottom:3px; margin-bottom:3px; }
        .group { background:#e6e6e6; font-weight:800; text-align:center !important; }
        .pupils { margin-top:18px; table-layout:fixed; font-size:12pt; }
        .pupils th:nth-child(1) { width:7%; }
        .pupils th:nth-child(2) { width:38%; }
        .pupils th:nth-child(3) { width:18%; }
        .pupils th:nth-child(4) { width:18%; }
        .pupils th:nth-child(5) { width:19%; }
        .summary { margin-top:14px; width:55%; font-size:12pt; }
        .summary td { border:1.2px solid #000; padding:4px 6px; }
        .warn { margin:18px 0; border:1px solid #b00; padding:10px; font-weight:700; color:#800; }
        </style>
        """
    }

    func classroomMonitoringHTML(stage: String) -> String {
        let rows = reportRows(stage: stage)
        let totalMale = rows.reduce(0) { $0 + $1.1 }
        let totalFemale = rows.reduce(0) { $0 + $1.2 }
        let levelHeader = readingLevels.map { level in
            "<th>\(htmlEscape(level.code.replacingOccurrences(of: "LEVEL", with: "Level")))<div class=\"area\">\(htmlEscape(level.area.capitalized))</div></th>"
        }.joined()
        let maleCells = rows.map { "<td>\($0.1)</td>" }.joined()
        let femaleCells = rows.map { "<td>\($0.2)</td>" }.joined()
        let totalCells = rows.map { "<td><b>\($0.3)</b></td>" }.joined()

        var profileHTML = ""
        if keyStage() > 0 {
            let labels = profileLabelsForCurrentKeyStage()
            let profileRows = labels.map { profile -> String in
                let bm = profileCount(profile, checkpoint: \.bosy, sex: "Male")
                let bf = profileCount(profile, checkpoint: \.bosy, sex: "Female")
                let mm = profileCount(profile, checkpoint: \.mosy, sex: "Male")
                let mf = profileCount(profile, checkpoint: \.mosy, sex: "Female")
                let em = profileCount(profile, checkpoint: \.eosy, sex: "Male")
                let ef = profileCount(profile, checkpoint: \.eosy, sex: "Female")
                return "<tr><td>\(htmlEscape(profile))</td><td>\(bm)</td><td>\(bf)</td><td>\(htmlEscape(profile))</td><td>\(mm)</td><td>\(mf)</td><td>\(htmlEscape(profile))</td><td>\(em)</td><td>\(ef)</td></tr>"
            }.joined()
            let bosyTotal = data.learners.filter { !preAssessment(for: $0).bosy.isEmpty }.count
            let mosyTotal = data.learners.filter { !preAssessment(for: $0).mosy.isEmpty }.count
            let eosyTotal = data.learners.filter { !preAssessment(for: $0).eosy.isEmpty }.count
            profileHTML = """
            <div class="profile-title">KEY STAGE \(keyStage())</div>
            <table class="profile">
              <tr><th colspan="3">BOSY</th><th colspan="3">MOSY</th><th colspan="3">EOSY</th></tr>
              <tr><th>Reading Profile</th><th>Male</th><th>Female</th><th>Reading Profile</th><th>Male</th><th>Female</th><th>Reading Profile</th><th>Male</th><th>Female</th></tr>
              \(profileRows)
              <tr><td><b>Total</b></td><td colspan="2"><b>\(bosyTotal)</b></td><td><b>Total</b></td><td colspan="2"><b>\(mosyTotal)</b></td><td><b>Total</b></td><td colspan="2"><b>\(eosyTotal)</b></td></tr>
            </table>
            """
        } else {
            profileHTML = "<div class=\"warn\">Set the Grade Level in Setup. The report prints only the applicable Key Stage table.</div>"
        }

        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        return """
        <!doctype html><html><head><meta charset="utf-8">\(sharedReportCSS(landscape: true))</head><body>
        \(reportHeaderHTML(stage: stage, title: "CLASSROOM READING MONITORING REPORT"))
        <table class="levels">
          <tr><th></th>\(levelHeader)<th>Total</th></tr>
          <tr><td class="left">Male</td>\(maleCells)<td><b>\(totalMale)</b></td></tr>
          <tr><td class="left">Female</td>\(femaleCells)<td><b>\(totalFemale)</b></td></tr>
          <tr><td><b>Total</b></td>\(totalCells)<td><b>\(totalMale + totalFemale)</b></td></tr>
        </table>
        \(profileHTML)
        <div class="signature-row">
          <div class="sig"><div>Submitted by:</div><div class="name">\(htmlEscape(data.settings.adviser))</div><div>Class Adviser</div></div>
          <div class="sig"><div>Noted by:</div><div class="name">\(htmlEscape(data.settings.schoolHead))</div><div>\(htmlEscape(data.settings.schoolHeadPosition))</div></div>
          <div class="datebox"><div class="date">\(htmlEscape(date))</div><div>Date Generated</div></div>
        </div>
        </body></html>
        """
    }

    func pupilListHTML(stage: String) -> String {
        let staged = learnersForStage(stage)
        func groupRows(_ sex: String) -> String {
            var number = 0
            let rows = staged.filter { $0.0.sex == sex }.map { learner, level -> String in
                number += 1
                let info = readingLevels.first(where: { $0.code == level })
                return "<tr><td>\(number)</td><td class=\"left\">\(htmlEscape(learner.displayName))</td><td>\(htmlEscape(info?.area.capitalized ?? ""))</td><td>\(htmlEscape(level))</td><td style=\"background:\(levelColor(level))\">\(htmlEscape(level))</td></tr>"
            }.joined()
            return "<tr><td colspan=\"5\" class=\"group\">\(sex.uppercased())</td></tr>" + (rows.isEmpty ? "<tr><td colspan=\"5\">—</td></tr>" : rows)
        }
        let male = data.learners.filter { $0.sex == "Male" }.count
        let female = data.learners.filter { $0.sex == "Female" }.count
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        return """
        <!doctype html><html><head><meta charset="utf-8">\(sharedReportCSS(landscape: false))</head><body>
        \(reportHeaderHTML(stage: stage, title: "LIST OF PUPILS"))
        <table class="pupils">
          <tr><th>NO.</th><th>LEARNER</th><th>Reading Level</th><th>Component/Level</th><th>Color Coding</th></tr>
          \(groupRows("Male"))
          \(groupRows("Female"))
        </table>
        <table class="summary">
          <tr><td><b>TOTAL ENROLLMENT:</b></td><td><b>\(data.learners.count)</b></td><td><b>MALE:</b></td><td>\(male)</td></tr>
          <tr><td></td><td></td><td><b>FEMALE:</b></td><td>\(female)</td></tr>
        </table>
        <div class="signature-row">
          <div class="sig"><div>Submitted by:</div><div class="name">\(htmlEscape(data.settings.adviser))</div><div>Class Adviser</div></div>
          <div class="sig"><div>Noted by:</div><div class="name">\(htmlEscape(data.settings.schoolHead))</div><div>\(htmlEscape(data.settings.schoolHeadPosition))</div></div>
          <div class="datebox"><div class="date">\(htmlEscape(date))</div><div>Date Generated</div></div>
        </div>
        </body></html>
        """
    }

    private func nativeReportSnapshot(stage: String) -> NativeReportSnapshot {
        let crm = reportRows(stage: stage).compactMap { row -> NativeCRMLevelRow? in
            guard let info = readingLevels.first(where: { $0.code == row.0 }) else { return nil }
            return NativeCRMLevelRow(
                level: row.0,
                area: info.area,
                male: row.1,
                female: row.2,
                total: row.3
            )
        }

        let profiles = profileLabelsForCurrentKeyStage().map { label in
            NativeProfileRow(
                label: label,
                bosyMale: profileCount(label, checkpoint: \.bosy, sex: "Male"),
                bosyFemale: profileCount(label, checkpoint: \.bosy, sex: "Female"),
                mosyMale: profileCount(label, checkpoint: \.mosy, sex: "Male"),
                mosyFemale: profileCount(label, checkpoint: \.mosy, sex: "Female"),
                eosyMale: profileCount(label, checkpoint: \.eosy, sex: "Male"),
                eosyFemale: profileCount(label, checkpoint: \.eosy, sex: "Female")
            )
        }

        let pupils = data.learners.map { learner -> NativePupilRow in
            let previousLevel: String
            let currentLevelValue: String
            let status: String

            if stage == "PRETEST" {
                previousLevel = "—"
                currentLevelValue = preAssessment(for: learner).level
                status = "—"
            } else {
                previousLevel = levelBeforeAP(learner, ap: stage)
                currentLevelValue = levelAfterAP(learner, ap: stage)

                if let entry = learner.assessments[stage], !entry.result.isEmpty {
                    status = entry.result
                } else if let inactive = inactiveStatusBeforeAP(learner, ap: stage) {
                    status = inactive.status
                } else {
                    status = "—"
                }
            }

            let info = readingLevels.first(where: { $0.code == currentLevelValue })
            return NativePupilRow(
                lrn: learner.lrn,
                name: learner.displayName,
                sex: learner.sex,
                previousLevel: previousLevel.isEmpty ? "—" : previousLevel,
                currentLevel: currentLevelValue.isEmpty ? "—" : currentLevelValue,
                area: info?.area ?? "",
                status: status
            )
        }

        let activePre = data.learners.map { preAssessment(for: $0) }

        return NativeReportSnapshot(
            settings: data.settings,
            stage: stage,
            term: termFor(stage),
            keyStage: keyStage(),
            crmRows: crm,
            profileRows: profiles,
            bosyTotal: activePre.filter { !$0.bosy.isEmpty }.count,
            mosyTotal: activePre.filter { !$0.mosy.isEmpty }.count,
            eosyTotal: activePre.filter { !$0.eosy.isEmpty }.count,
            pupils: pupils,
            maleCount: data.learners.filter { $0.sex == "Male" }.count,
            femaleCount: data.learners.filter { $0.sex == "Female" }.count,
            generatedAt: DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short),
            leftLogoData: reportLogoData(left: true),
            rightLogoData: reportLogoData(left: false)
        )
    }

    private func nativeReportView(stage: String, type: PrintoutType) -> NativeReportView {
        NativeReportView(type: type, snapshot: nativeReportSnapshot(stage: stage))
    }

    func previewReport(stage: String, type: PrintoutType) {
        let view = nativeReportView(stage: stage, type: type)
        guard let data = view.pdfData() else {
            statusMessage = "Preview failed"
            return
        }

        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("BULIG_Report_Preview_\(UUID().uuidString).pdf")
        do {
            try data.write(to: temp, options: .atomic)
            NSWorkspace.shared.open(temp)
            statusMessage = "Preview opened"
        } catch {
            statusMessage = "Preview failed"
        }
    }

    func printReport(stage: String, type: PrintoutType) {
        let view = nativeReportView(stage: stage, type: type)
        let info = NSPrintInfo.shared.copy() as! NSPrintInfo
        info.paperSize = view.paperSize
        info.leftMargin = 0
        info.rightMargin = 0
        info.topMargin = 0
        info.bottomMargin = 0
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        info.isHorizontallyCentered = true
        info.isVerticallyCentered = false

        let op = NSPrintOperation(view: view, printInfo: info)
        op.showsPrintPanel = true
        op.showsProgressPanel = true
        statusMessage = op.run() ? "Report sent to print" : "Printing cancelled or failed"
    }

    func savePDFReport(stage: String, type: PrintoutType) {
        let view = nativeReportView(stage: stage, type: type)
        guard let data = view.pdfData() else {
            statusMessage = "PDF generation failed"
            return
        }

        let panel = NSSavePanel()
        panel.title = "Save BULIG Report as PDF"
        let reportName = type == .classroomMonitoring ? "Classroom_Reading_Monitoring_Report" : "List_of_Pupils"
        panel.nameFieldStringValue = "BULIG_\(stage)_\(reportName).pdf"
        panel.allowedFileTypes = ["pdf"]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try data.write(to: url, options: .atomic)
            statusMessage = "PDF saved"
        } catch {
            statusMessage = "PDF save failed"
        }
    }

    func exportAllReports() {
        let panel = NSOpenPanel()
        panel.title = "Choose Folder for BULIG Reports"
        panel.message = "BULIG will create both official PDF reports for PRETEST and every AP with encoded data."
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let folder = panel.url else { return }

        var saved = 0
        for stage in completedReportStages() {
            for type in PrintoutType.allCases {
                let view = nativeReportView(stage: stage, type: type)
                guard let pdf = view.pdfData() else { continue }
                let name = type == .classroomMonitoring
                    ? "\(stage)_Classroom_Reading_Monitoring_Report.pdf"
                    : "\(stage)_List_of_Pupils.pdf"
                do {
                    try pdf.write(to: folder.appendingPathComponent(name), options: .atomic)
                    saved += 1
                } catch { }
            }
        }
        statusMessage = "Batch export saved \(saved) PDF report(s)"
        NSWorkspace.shared.open(folder)
    }

    func exportCSV(stage: String) {
        let panel = NSSavePanel()
        panel.title = "Export CRM Summary"
        panel.nameFieldStringValue = "BULIG_\(stage)_Summary.csv"
        panel.allowedFileTypes = ["csv"]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        var csv = "Level,Male,Female,Total\n"
        for row in reportRows(stage: stage) {
            csv += "\(row.0),\(row.1),\(row.2),\(row.3)\n"
        }
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            statusMessage = "CSV exported"
        } catch {
            statusMessage = "Export failed"
        }
    }
}

extension JSONEncoder {
    static var pretty: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}

enum AppPage: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case setup = "Setup"
    case learners = "Learners"
    case pre = "Pre-Assessment"
    case monitoring = "Monitoring"
    case reports = "Reports"
    case backup = "Backup & Restore"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .dashboard: return "house.fill"
        case .setup: return "gearshape.fill"
        case .learners: return "person.2.fill"
        case .pre: return "doc.text.magnifyingglass"
        case .monitoring: return "checkmark.circle.fill"
        case .reports: return "chart.bar.doc.horizontal.fill"
        case .backup: return "externaldrive.fill.badge.timemachine"
        }
    }
}

struct RootView: View {
    @StateObject var store = AppStore()
    @State private var selection: AppPage? = .dashboard

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                BrandView()
                    .padding(.top, 14)
                    .padding(.bottom, 10)
                List(AppPage.allCases, selection: $selection) { page in
                    Label(page.rawValue, systemImage: page.symbol)
                        .tag(page)
                        .padding(.vertical, 4)
                }
                .listStyle(.sidebar)
                HStack {
                    Circle().fill(Color.green).frame(width: 7, height: 7)
                    Text(store.statusMessage).font(.caption).foregroundStyle(.secondary)
                }
                .padding(12)
            }
            .frame(minWidth: 230)
        } detail: {
            Group {
                switch selection ?? .dashboard {
                case .dashboard: DashboardView(store: store)
                case .setup: SetupView(store: store)
                case .learners: LearnersView(store: store)
                case .pre: PreAssessmentView(store: store)
                case .monitoring: MonitoringView(store: store)
                case .reports: ReportsView(store: store)
                case .backup: BackupView(store: store)
                }
            }
            .frame(minWidth: 850, minHeight: 620)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .onChange(of: store.data) { _ in store.save() }
    }
}

struct BrandView: View {
    var body: some View {
        HStack(spacing: 12) {
            if let url = Bundle.main.url(forResource: "BuligLogo", withExtension: "jpg"),
               let ns = NSImage(contentsOf: url) {
                Image(nsImage: ns)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "book.fill").font(.largeTitle).foregroundStyle(.green)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("BULIG RMS").font(.title2.bold())
                Text("Teacher • macOS").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
    }
}

struct PageHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.largeTitle.bold())
            Text(subtitle).foregroundStyle(.secondary)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 38, height: 38)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading) {
                Text(value).font(.title2.bold())
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}


struct DashboardProgressPoint: Identifiable {
    let id = UUID()
    let ap: String
    let ready: Int
    let notReady: Int
    let reverted: Int
}

struct DashboardAttentionItem: Identifiable {
    let id: UUID
    let learnerName: String
    let level: String
    let status: String
    let reason: String
}

struct DashboardMetricCard: View {
    let title: String
    let value: String
    let symbol: String
    var tint: Color = .blue

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .monospacedDigit()
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}

struct DashboardDonutChart: View {
    let labels: [String]
    let values: [Int]

    private let palette: [Color] = [.blue, .green, .orange, .purple, .pink, .teal]

    var total: Int { values.reduce(0, +) }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = min(size.width, size.height) * 0.36
                    let lineWidth = min(size.width, size.height) * 0.18

                    if total == 0 {
                        var circle = Path()
                        circle.addEllipse(in: CGRect(
                            x: center.x - radius,
                            y: center.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        ))
                        context.stroke(circle, with: .color(.secondary.opacity(0.2)), lineWidth: lineWidth)
                    } else {
                        var start = -Double.pi / 2
                        for index in values.indices {
                            let fraction = Double(values[index]) / Double(total)
                            guard fraction > 0 else { continue }
                            let end = start + fraction * Double.pi * 2
                            var path = Path()
                            path.addArc(
                                center: center,
                                radius: radius,
                                startAngle: .radians(start),
                                endAngle: .radians(end),
                                clockwise: false
                            )
                            context.stroke(
                                path,
                                with: .color(palette[index % palette.count]),
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                            )
                            start = end
                        }
                    }
                }
                .frame(width: 180, height: 180)

                VStack(spacing: 0) {
                    Text("\(total)")
                        .font(.title2.bold())
                        .monospacedDigit()
                    Text("Profiled")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(labels.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(palette[index % palette.count])
                            .frame(width: 9, height: 9)
                        Text(labels[index])
                            .font(.caption)
                            .lineLimit(1)
                        Spacer(minLength: 10)
                        Text("\(values[index])")
                            .font(.caption.bold())
                            .monospacedDigit()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DashboardProgressChart: View {
    let points: [DashboardProgressPoint]

    private var maximum: Int {
        max(1, points.flatMap { [$0.ready, $0.notReady, $0.reverted] }.max() ?? 1)
    }

    private func path(for values: [Int], size: CGSize) -> Path {
        var path = Path()
        guard !values.isEmpty else { return path }
        let left: CGFloat = 26
        let right: CGFloat = 10
        let top: CGFloat = 14
        let bottom: CGFloat = 26
        let usableW = max(1, size.width - left - right)
        let usableH = max(1, size.height - top - bottom)

        for index in values.indices {
            let x = left + usableW * CGFloat(index) / CGFloat(max(1, values.count - 1))
            let y = top + usableH * (1 - CGFloat(values[index]) / CGFloat(maximum))
            if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Label("READY", systemImage: "circle.fill").foregroundStyle(.green)
                Label("NOT READY", systemImage: "circle.fill").foregroundStyle(.orange)
                Label("REVERTED", systemImage: "circle.fill").foregroundStyle(.red)
                Spacer()
            }
            .font(.caption)

            GeometryReader { geo in
                ZStack {
                    Canvas { context, size in
                        let left: CGFloat = 26
                        let right: CGFloat = 10
                        let top: CGFloat = 14
                        let bottom: CGFloat = 26
                        let usableH = max(1, size.height - top - bottom)

                        for step in 0...4 {
                            let y = top + usableH * CGFloat(step) / 4
                            var grid = Path()
                            grid.move(to: CGPoint(x: left, y: y))
                            grid.addLine(to: CGPoint(x: size.width - right, y: y))
                            context.stroke(grid, with: .color(.secondary.opacity(0.12)), lineWidth: 1)
                        }

                        context.stroke(
                            path(for: points.map(\.ready), size: size),
                            with: .color(.green),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                        context.stroke(
                            path(for: points.map(\.notReady), size: size),
                            with: .color(.orange),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                        context.stroke(
                            path(for: points.map(\.reverted), size: size),
                            with: .color(.red),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                    }

                    VStack {
                        Spacer()
                        HStack {
                            Text("AP1")
                            Spacer()
                            Text("AP5")
                            Spacer()
                            Text("AP10")
                            Spacer()
                            Text("AP15")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 26)
                        .padding(.trailing, 10)
                    }
                }
            }
            .frame(height: 190)
        }
    }
}

struct DashboardView: View {
    @ObservedObject var store: AppStore
    @State private var selectedStage = "PRETEST"
    @State private var selectedProfilePeriod = "BOSY"
    @State private var selectedLevel: String? = nil
    @State private var drilldownTitle = ""
    @State private var drilldownLearnerIDs: [UUID] = []

    private var stageOptions: [String] { ["PRETEST"] + assessmentPeriods }

    private func stageLevel(_ learner: Learner, stage: String) -> String {
        stage == "PRETEST"
            ? store.preAssessment(for: learner).level
            : store.currentLevel(learner, through: stage)
    }

    private func inactiveStatus(_ learner: Learner, stage: String) -> (period: String, status: String)? {
        guard stage != "PRETEST" else { return nil }

        if let entry = learner.assessments[stage], store.isInactiveStatus(entry.result) {
            return (stage, entry.result)
        }
        return store.inactiveStatusBeforeAP(learner, ap: stage)
    }

    private var activeCount: Int {
        store.data.learners.filter { inactiveStatus($0, stage: selectedStage) == nil }.count
    }

    private func resultCount(_ result: String) -> Int {
        guard selectedStage != "PRETEST" else { return 0 }
        return store.data.learners.filter { $0.assessments[selectedStage]?.result == result }.count
    }

    private var inactiveCount: Int {
        store.data.learners.filter { inactiveStatus($0, stage: selectedStage) != nil }.count
    }

    private func levelCount(_ level: String) -> Int {
        store.data.learners.filter { stageLevel($0, stage: selectedStage) == level }.count
    }

    private var maxLevelCount: Int {
        max(1, readingLevels.map { levelCount($0.code) }.max() ?? 1)
    }

    private func normalizedProfile(_ raw: String) -> String {
        if raw.hasPrefix("KS"), let underscore = raw.firstIndex(of: "_") {
            return String(raw[raw.index(after: underscore)...])
        }
        return raw
    }

    private func profileValue(_ learner: Learner) -> String {
        let pre = store.preAssessment(for: learner)
        switch selectedProfilePeriod {
        case "MOSY": return normalizedProfile(pre.mosy)
        case "EOSY": return normalizedProfile(pre.eosy)
        default: return normalizedProfile(pre.bosy)
        }
    }

    private var profileLabels: [String] {
        store.profileLabelsForCurrentKeyStage()
    }

    private var profileValues: [Int] {
        profileLabels.map { label in
            store.data.learners.filter { profileValue($0) == label }.count
        }
    }

    private var progressPoints: [DashboardProgressPoint] {
        assessmentPeriods.map { ap in
            DashboardProgressPoint(
                ap: ap,
                ready: store.data.learners.filter { $0.assessments[ap]?.result == "READY" }.count,
                notReady: store.data.learners.filter { $0.assessments[ap]?.result == "NOT READY" }.count,
                reverted: store.data.learners.filter { $0.assessments[ap]?.result == "REVERTED" }.count
            )
        }
    }

    private func levelIndex(_ value: String) -> Int? {
        readingLevels.firstIndex(where: { $0.code == value })
    }

    private var movementSummary: (advanced: Int, same: Int, reverted: Int, manual: Int) {
        guard selectedStage != "PRETEST" else { return (0, 0, 0, 0) }

        var advanced = 0
        var same = 0
        var reverted = 0
        var manual = 0

        for learner in store.data.learners {
            guard let entry = learner.assessments[selectedStage],
                  !entry.result.isEmpty,
                  !store.isInactiveStatus(entry.result) else { continue }

            let previous = store.levelBeforeAP(learner, ap: selectedStage)
            let current = store.levelAfterAP(learner, ap: selectedStage)

            if !entry.overrideLevel.isEmpty { manual += 1 }

            if let beforeIndex = levelIndex(previous), let afterIndex = levelIndex(current) {
                if afterIndex > beforeIndex { advanced += 1 }
                else if afterIndex < beforeIndex { reverted += 1 }
                else { same += 1 }
            }
        }
        return (advanced, same, reverted, manual)
    }

    private func consecutiveNotReady(_ learner: Learner, through stage: String) -> Int {
        guard stage != "PRETEST",
              let target = assessmentPeriods.firstIndex(of: stage) else { return 0 }

        var count = 0
        var index = target
        while index >= 0 {
            let ap = assessmentPeriods[index]
            if learner.assessments[ap]?.result == "NOT READY" {
                count += 1
            } else {
                break
            }
            if index == 0 { break }
            index -= 1
        }
        return count
    }

    private func statusDisplay(_ value: String) -> String {
        switch value {
        case "NLS": return "No Longer in School"
        case "NLP": return "No Longer Participating"
        case "TRANSFER OUT": return "Transfer Out"
        default: return value
        }
    }

    private var attentionItems: [DashboardAttentionItem] {
        guard selectedStage != "PRETEST" else {
            return store.data.learners.compactMap { learner in
                let level = store.preAssessment(for: learner).level
                guard level.isEmpty else { return nil }
                return DashboardAttentionItem(
                    id: learner.id,
                    learnerName: learner.displayName,
                    level: "—",
                    status: "PRETEST",
                    reason: "Initial reading level not yet encoded"
                )
            }
        }

        return store.data.learners.compactMap { learner in
            var reasons: [String] = []
            var status = learner.assessments[selectedStage]?.result ?? "—"

            if let inactive = inactiveStatus(learner, stage: selectedStage) {
                status = inactive.status
                reasons.append("\(statusDisplay(inactive.status)) since \(inactive.period)")
            }

            if learner.assessments[selectedStage]?.result == "REVERTED" {
                reasons.append("Reading level reverted")
            }

            if let entry = learner.assessments[selectedStage], !entry.overrideLevel.isEmpty {
                reasons.append("Manual level adjustment")
            }

            let consecutive = consecutiveNotReady(learner, through: selectedStage)
            if consecutive >= 2 {
                reasons.append("\(consecutive) consecutive NOT READY results")
            }

            guard !reasons.isEmpty else { return nil }

            return DashboardAttentionItem(
                id: learner.id,
                learnerName: learner.displayName,
                level: stageLevel(learner, stage: selectedStage),
                status: statusDisplay(status),
                reason: reasons.joined(separator: " • ")
            )
        }
    }

    private var selectedLevelLearners: [Learner] {
        guard let selectedLevel else { return [] }
        return store.data.learners
            .filter { stageLevel($0, stage: selectedStage) == selectedLevel }
            .sorted { $0.displayName < $1.displayName }
    }

    private var requiredForSelectedStage: [Learner] {
        if selectedStage == "PRETEST" { return store.data.learners }
        return store.data.learners.filter {
            store.inactiveStatusBeforeAP($0, ap: selectedStage) == nil
        }
    }

    private var encodedForSelectedStage: [Learner] {
        if selectedStage == "PRETEST" {
            return requiredForSelectedStage.filter { !store.preAssessment(for: $0).level.isEmpty }
        }
        return requiredForSelectedStage.filter {
            !($0.assessments[selectedStage]?.result ?? "").isEmpty
        }
    }

    private var missingForSelectedStage: [Learner] {
        requiredForSelectedStage.filter { learner in
            if selectedStage == "PRETEST" {
                return store.preAssessment(for: learner).level.isEmpty
            }
            return (learner.assessments[selectedStage]?.result ?? "").isEmpty
        }
    }

    private var dashboardWarnings: [String] {
        var warnings: [String] = []

        let lrns = store.data.learners.map { $0.lrn }.filter { !$0.isEmpty }
        let duplicates = Dictionary(grouping: lrns, by: { $0 }).filter { $0.value.count > 1 }
        if !duplicates.isEmpty {
            warnings.append("\(duplicates.count) duplicate LRN value(s) detected")
        }

        let invalidLRN = store.data.learners.filter {
            !$0.lrn.isEmpty && $0.lrn.filter(\.isNumber).count != 12
        }.count
        if invalidLRN > 0 {
            warnings.append("\(invalidLRN) learner(s) have an invalid LRN length")
        }

        let missingSex = store.data.learners.filter { $0.sex.isEmpty }.count
        if missingSex > 0 {
            warnings.append("\(missingSex) learner(s) have no sex encoded")
        }

        let missingPre = store.data.learners.filter {
            store.preAssessment(for: $0).level.isEmpty
        }.count
        if missingPre > 0 {
            warnings.append("\(missingPre) learner(s) have no Pre-Assessment reading level")
        }

        let manual = store.data.learners.filter { learner in
            learner.assessments.values.contains { !$0.overrideLevel.isEmpty }
        }.count
        if manual > 0 {
            warnings.append("\(manual) learner(s) have manual reading-level adjustments")
        }

        if !missingForSelectedStage.isEmpty {
            warnings.append("\(missingForSelectedStage.count) required learner(s) are not yet encoded in \(selectedStage)")
        }

        var laterAfterInactive = 0
        for learner in store.data.learners {
            var inactiveIndex: Int? = nil
            for (index, ap) in assessmentPeriods.enumerated() {
                if let entry = learner.assessments[ap], store.isInactiveStatus(entry.result) {
                    inactiveIndex = index
                } else if let inactiveIndex,
                          index > inactiveIndex,
                          let entry = learner.assessments[ap],
                          !entry.result.isEmpty,
                          !store.isInactiveStatus(entry.result) {
                    let hasReactivation = learner.reactivationAPs.contains { key in
                        guard let reactIndex = assessmentPeriods.firstIndex(of: key) else { return false }
                        return reactIndex > inactiveIndex && reactIndex <= index
                    }
                    if !hasReactivation {
                        laterAfterInactive += 1
                        break
                    }
                }
            }
        }
        if laterAfterInactive > 0 {
            warnings.append("\(laterAfterInactive) learner(s) have assessment data after an inactive status without reactivation")
        }

        return warnings
    }

    private func openDrilldown(_ title: String, learners: [Learner]) {
        drilldownTitle = title
        drilldownLearnerIDs = learners.map(\.id)
    }

    private var drilldownLearners: [Learner] {
        store.data.learners
            .filter { drilldownLearnerIDs.contains($0.id) }
            .sorted { $0.displayName < $1.displayName }
    }

    private var classContext: String {
        let grade = store.data.settings.gradeLevel.isEmpty ? "Grade —" : "Grade \(store.data.settings.gradeLevel)"
        let section = store.data.settings.section.isEmpty ? "Section —" : store.data.settings.section
        let sy = store.data.settings.schoolYear.isEmpty ? "SY —" : "SY \(store.data.settings.schoolYear)"
        let term = selectedStage == "PRETEST"
            ? (store.data.assessmentTerms["PRETEST"] ?? "1ST")
            : (store.data.assessmentTerms[selectedStage] ?? "1ST")
        let keyStage = store.keyStage() == 0 ? "Key Stage —" : "Key Stage \(store.keyStage())"
        return "\(grade) – \(section)  •  \(sy)  •  \(term) Term  •  \(keyStage)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    PageHeader(
                        title: "Dashboard",
                        subtitle: store.data.settings.schoolName.isEmpty
                            ? "Bukidnon's Unified Literacy and Intervention Gateway"
                            : store.data.settings.schoolName
                    )

                    Spacer()

                    Picker("View Data From", selection: $selectedStage) {
                        ForEach(stageOptions, id: \.self) { Text($0).tag($0) }
                    }
                    .frame(width: 220)
                }

                Text(classContext)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button {
                        openDrilldown("Total Learners", learners: store.data.learners)
                    } label: {
                        DashboardMetricCard(
                            title: "Total Learners",
                            value: "\(store.data.learners.count)",
                            symbol: "person.2.fill",
                            tint: .blue
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        openDrilldown("Male Learners", learners: store.data.learners.filter { $0.sex == "Male" })
                    } label: {
                        DashboardMetricCard(
                            title: "Male",
                            value: "\(store.data.learners.filter { $0.sex == "Male" }.count)",
                            symbol: "person.fill",
                            tint: .indigo
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        openDrilldown("Female Learners", learners: store.data.learners.filter { $0.sex == "Female" })
                    } label: {
                        DashboardMetricCard(
                            title: "Female",
                            value: "\(store.data.learners.filter { $0.sex == "Female" }.count)",
                            symbol: "person.fill",
                            tint: .purple
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        openDrilldown(
                            "Active Learners – \(selectedStage)",
                            learners: store.data.learners.filter { inactiveStatus($0, stage: selectedStage) == nil }
                        )
                    } label: {
                        DashboardMetricCard(
                            title: "Active Learners",
                            value: "\(activeCount)",
                            symbol: "person.crop.circle.badge.checkmark",
                            tint: .green
                        )
                    }
                    .buttonStyle(.plain)
                }

                if selectedStage != "PRETEST" {
                    HStack(spacing: 12) {
                        Button {
                            openDrilldown(
                                "READY – \(selectedStage)",
                                learners: store.data.learners.filter { $0.assessments[selectedStage]?.result == "READY" }
                            )
                        } label: {
                            DashboardMetricCard(
                                title: "Ready",
                                value: "\(resultCount("READY"))",
                                symbol: "arrow.up.circle.fill",
                                tint: .green
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            openDrilldown(
                                "NOT READY – \(selectedStage)",
                                learners: store.data.learners.filter { $0.assessments[selectedStage]?.result == "NOT READY" }
                            )
                        } label: {
                            DashboardMetricCard(
                                title: "Not Ready",
                                value: "\(resultCount("NOT READY"))",
                                symbol: "minus.circle.fill",
                                tint: .orange
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            openDrilldown(
                                "REVERTED – \(selectedStage)",
                                learners: store.data.learners.filter { $0.assessments[selectedStage]?.result == "REVERTED" }
                            )
                        } label: {
                            DashboardMetricCard(
                                title: "Reverted",
                                value: "\(resultCount("REVERTED"))",
                                symbol: "arrow.down.circle.fill",
                                tint: .red
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            openDrilldown(
                                "Inactive – \(selectedStage)",
                                learners: store.data.learners.filter {
                                    inactiveStatus($0, stage: selectedStage) != nil ||
                                    store.isInactiveStatus($0.assessments[selectedStage]?.result ?? "")
                                }
                            )
                        } label: {
                            DashboardMetricCard(
                                title: "Inactive",
                                value: "\(inactiveCount)",
                                symbol: "person.crop.circle.badge.xmark",
                                tint: .secondary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(alignment: .top, spacing: 16) {
                    GroupBox("Encoding Status – \(selectedStage)") {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(encodedForSelectedStage.count) / \(requiredForSelectedStage.count)")
                                    .font(.title2.bold())
                                    .monospacedDigit()
                                Text("required learners encoded")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            ProgressView(
                                value: Double(encodedForSelectedStage.count),
                                total: Double(max(requiredForSelectedStage.count, 1))
                            )
                            .frame(maxWidth: .infinity)

                            Button {
                                openDrilldown("Missing Encoding – \(selectedStage)", learners: missingForSelectedStage)
                            } label: {
                                Label("\(missingForSelectedStage.count) Missing", systemImage: "exclamationmark.circle")
                            }
                            .buttonStyle(.bordered)
                            .disabled(missingForSelectedStage.isEmpty)
                        }
                        .padding(10)
                    }
                    .frame(maxWidth: .infinity)

                    GroupBox("Data Warnings") {
                        if dashboardWarnings.isEmpty {
                            Label("No data warnings detected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(dashboardWarnings, id: \.self) { warning in
                                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding(10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                HStack(alignment: .top, spacing: 16) {
                    GroupBox("Reading Level Distribution – \(selectedStage)") {
                        VStack(spacing: 8) {
                            ForEach(readingLevels) { level in
                                Button {
                                    selectedLevel = level.code
                                } label: {
                                    HStack(spacing: 10) {
                                        Text(level.code)
                                            .font(.caption.bold())
                                            .frame(width: 68, alignment: .leading)

                                        GeometryReader { geo in
                                            let count = levelCount(level.code)
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.secondary.opacity(0.09))
                                                Capsule()
                                                    .fill(Color(nsColor: reportLevelColor(level.code)))
                                                    .frame(
                                                        width: count == 0
                                                            ? 0
                                                            : max(4, geo.size.width * CGFloat(count) / CGFloat(maxLevelCount))
                                                    )
                                            }
                                        }
                                        .frame(height: 15)

                                        Text("\(levelCount(level.code))")
                                            .font(.caption.bold())
                                            .monospacedDigit()
                                            .frame(width: 30, alignment: .trailing)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .help("Show learners in \(level.code)")
                            }
                        }
                        .padding(10)
                    }
                    .frame(maxWidth: .infinity)

                    GroupBox("Reading Profile") {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("Profile Period", selection: $selectedProfilePeriod) {
                                ForEach(preAssessmentPeriods, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.segmented)

                            DashboardDonutChart(
                                labels: profileLabels,
                                values: profileValues
                            )
                        }
                        .padding(10)
                    }
                    .frame(maxWidth: .infinity)
                }

                GroupBox("Class Progress – AP1 to AP15") {
                    DashboardProgressChart(points: progressPoints)
                        .padding(10)
                }

                HStack(alignment: .top, spacing: 16) {
                    GroupBox("Movement Summary – \(selectedStage)") {
                        let movement = movementSummary
                        VStack(spacing: 12) {
                            HStack {
                                Label("Advanced", systemImage: "arrow.up.right")
                                Spacer()
                                Text("\(movement.advanced)").bold().monospacedDigit()
                            }
                            Divider()
                            HStack {
                                Label("Stayed at Same Level", systemImage: "arrow.right")
                                Spacer()
                                Text("\(movement.same)").bold().monospacedDigit()
                            }
                            Divider()
                            HStack {
                                Label("Reverted", systemImage: "arrow.down.right")
                                Spacer()
                                Text("\(movement.reverted)").bold().monospacedDigit()
                            }
                            Divider()
                            HStack {
                                Label("Manual Level Changes", systemImage: "pencil")
                                Spacer()
                                Text("\(movement.manual)").bold().monospacedDigit()
                            }
                        }
                        .padding(10)
                    }
                    .frame(width: 330)

                    GroupBox("Learners Needing Attention") {
                        if attentionItems.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.green)
                                Text("No Attention Flags")
                                    .font(.headline)
                                Text("No learners currently meet the dashboard attention rules for \(selectedStage).")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 180)
                        } else {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Learner").frame(maxWidth: .infinity, alignment: .leading)
                                    Text("Level").frame(width: 80, alignment: .leading)
                                    Text("Status").frame(width: 120, alignment: .leading)
                                    Text("Reason").frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.bottom, 7)

                                Divider()

                                ForEach(attentionItems.prefix(12)) { item in
                                    HStack(alignment: .top) {
                                        Text(item.learnerName)
                                            .font(.caption)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(item.level.isEmpty ? "—" : item.level)
                                            .font(.caption)
                                            .frame(width: 80, alignment: .leading)
                                        Text(item.status)
                                            .font(.caption)
                                            .frame(width: 120, alignment: .leading)
                                        Text(item.reason)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 7)

                                    Divider()
                                }

                                if attentionItems.count > 12 {
                                    Text("+ \(attentionItems.count - 12) more learner(s)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 8)
                                }
                            }
                            .padding(10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(28)
        }
        .sheet(isPresented: Binding(
            get: { selectedLevel != nil },
            set: { if !$0 { selectedLevel = nil } }
        )) {
            if let selectedLevel {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(selectedLevel) Learners")
                                .font(.title2.bold())
                            Text("\(selectedStage) • \(selectedLevelLearners.count) learner(s)")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Close") { self.selectedLevel = nil }
                    }

                    List(selectedLevelLearners) { learner in
                        HStack {
                            Text(learner.displayName).bold()
                            Spacer()
                            Text(learner.sex)
                                .foregroundStyle(.secondary)
                            Text(learner.lrn)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(22)
                .frame(width: 620, height: 480)
            }
        }
    }
}

struct SetupView: View {
    @ObservedObject var store: AppStore
    @State private var showSavedConfirmation = false
    @State private var logoMessage = ""
    @State private var showLogoMessage = false
    let grades = (1...12).map(String.init)

    @ViewBuilder
    private func logoPreview(left: Bool, title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).bold()

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.06))
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)

                if let image = store.reportLogoImage(left: left) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Using built-in default")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 115)

            HStack {
                Button {
                    if let message = store.chooseReportLogo(left: left) {
                        logoMessage = message
                        showLogoMessage = true
                    }
                } label: {
                    Label("Choose Logo", systemImage: "photo.badge.plus")
                }
                .buttonStyle(.borderedProminent)

                if store.reportLogoImage(left: left) != nil {
                    Button("Use Default") {
                        store.clearReportLogo(left: left)
                        logoMessage = "\(title) reset to the built-in default."
                        showLogoMessage = true
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: "Setup", subtitle: "School, class, and report information")

                GroupBox("School Information") {
                    Form {
                        TextField("School Name", text: $store.data.settings.schoolName)
                        TextField("School ID", text: $store.data.settings.schoolId)
                        TextField("School Head", text: $store.data.settings.schoolHead)
                        TextField("Position", text: $store.data.settings.schoolHeadPosition)
                        TextField("District", text: $store.data.settings.district)
                        TextField("Division", text: $store.data.settings.division)
                        TextField("Region", text: $store.data.settings.region)
                    }
                    .padding(8)
                }

                GroupBox("Report Logos") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose the logos that will appear on every printed report. The left and right images are saved locally on this Mac.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .top, spacing: 20) {
                            logoPreview(left: true, title: "Left Report Logo")
                            Divider()
                            logoPreview(left: false, title: "Right Report Logo")
                        }
                        .padding(8)
                    }
                }

                GroupBox("Class Information") {
                    Form {
                        TextField("School Year", text: $store.data.settings.schoolYear)
                        Picker("Grade Level", selection: $store.data.settings.gradeLevel) {
                            Text("Select").tag("")
                            ForEach(grades, id: \.self) { Text("Grade \($0)").tag($0) }
                        }
                        TextField("Section", text: $store.data.settings.section)
                        TextField("Adviser", text: $store.data.settings.adviser)
                        Picker("Assessment Tool", selection: $store.data.settings.assessmentTool) {
                            Text("CRLA").tag("CRLA")
                            Text("PHIL-IRI").tag("PHIL-IRI")
                        }
                        Picker("Subject", selection: $store.data.settings.subject) {
                            Text("ENGLISH").tag("ENGLISH")
                            Text("FILIPINO").tag("FILIPINO")
                        }
                        HStack {
                            Text("Automatic Key Stage")
                            Spacer()
                            Text(store.keyStage() == 0 ? "—" : "Key Stage \(store.keyStage())").bold()
                        }
                    }
                    .padding(8)
                }

                HStack {
                    Spacer()
                    Button("Save Setup") {
                        store.save()
                        showSavedConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(28)
        }
        .alert("Setup Saved", isPresented: $showSavedConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("School, class, and report settings have been saved successfully.")
        }
        .alert("Report Logo", isPresented: $showLogoMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(logoMessage)
        }
    }
}


struct LearnerProgressChart: View {
    let store: AppStore
    let learner: Learner

    private var points: [(String, Int)] {
        var output: [(String, Int)] = []
        let pre = store.preAssessment(for: learner).level
        if let index = readingLevels.firstIndex(where: { $0.code == pre }) {
            output.append(("PRE", index + 1))
        }
        for ap in assessmentPeriods {
            let hasEntry = learner.assessments[ap] != nil || learner.reactivationAPs.contains(ap)
            guard hasEntry else { continue }
            let level = store.currentLevel(learner, through: ap)
            if let index = readingLevels.firstIndex(where: { $0.code == level }) {
                output.append((ap, index + 1))
            }
        }
        return output
    }

    var body: some View {
        if points.count < 2 {
            Text("More assessment data is needed to draw the progress graph.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 110)
        } else {
            GeometryReader { geo in
                Canvas { context, size in
                    let left: CGFloat = 30
                    let right: CGFloat = 12
                    let top: CGFloat = 10
                    let bottom: CGFloat = 24
                    let w = max(1, size.width - left - right)
                    let h = max(1, size.height - top - bottom)

                    for row in 0..<9 {
                        let y = top + h * CGFloat(row) / 8
                        var line = Path()
                        line.move(to: CGPoint(x: left, y: y))
                        line.addLine(to: CGPoint(x: size.width - right, y: y))
                        context.stroke(line, with: .color(.secondary.opacity(0.10)), lineWidth: 1)
                    }

                    var path = Path()
                    for i in points.indices {
                        let x = left + w * CGFloat(i) / CGFloat(max(1, points.count - 1))
                        let value = points[i].1
                        let y = top + h * (1 - CGFloat(value - 1) / 8)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }

                        let dot = CGRect(x: x - 3, y: y - 3, width: 6, height: 6)
                        context.fill(Path(ellipseIn: dot), with: .color(.blue))
                    }
                    context.stroke(path, with: .color(.blue), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }

                VStack {
                    Spacer()
                    HStack {
                        Text(points.first?.0 ?? "")
                        Spacer()
                        if points.count > 2 {
                            Text(points[points.count / 2].0)
                            Spacer()
                        }
                        Text(points.last?.0 ?? "")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 30)
                    .padding(.trailing, 12)
                }
            }
            .frame(height: 150)
        }
    }
}

struct LearnerProgressSheet: View {
    @ObservedObject var store: AppStore
    let learner: Learner
    @Environment(\.dismiss) private var dismiss

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "NLS": return "No Longer in School"
        case "NLP": return "No Longer Participating"
        case "TRANSFER OUT": return "Transfer Out"
        default: return status
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(learner.displayName)
                        .font(.title2.bold())
                    Text("LRN \(learner.lrn.isEmpty ? "—" : learner.lrn) • \(learner.sex.isEmpty ? "Sex not set" : learner.sex)")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Close") { dismiss() }
            }

            GroupBox("Reading Progress") {
                LearnerProgressChart(store: store, learner: learner)
                    .padding(8)
            }

            List {
                HStack {
                    Text("Period").frame(width: 70, alignment: .leading)
                    Text("Previous").frame(width: 95, alignment: .leading)
                    Text("Result").frame(width: 145, alignment: .leading)
                    Text("Current").frame(width: 95, alignment: .leading)
                    Text("Notes").frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.caption.bold())

                let pre = store.preAssessment(for: learner)
                HStack {
                    Text("PRETEST").frame(width: 70, alignment: .leading).bold()
                    Text("—").frame(width: 95, alignment: .leading)
                    Text("Initial").frame(width: 145, alignment: .leading)
                    Text(pre.level.isEmpty ? "—" : pre.level).frame(width: 95, alignment: .leading)
                    Text("BOSY: \(pre.bosy.isEmpty ? "—" : pre.bosy) • MOSY: \(pre.mosy.isEmpty ? "—" : pre.mosy) • EOSY: \(pre.eosy.isEmpty ? "—" : pre.eosy)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(assessmentPeriods, id: \.self) { ap in
                    if let entry = learner.assessments[ap] {
                        HStack(alignment: .top) {
                            Text(ap).frame(width: 70, alignment: .leading).bold()
                            Text(store.levelBeforeAP(learner, ap: ap).isEmpty ? "—" : store.levelBeforeAP(learner, ap: ap))
                                .frame(width: 95, alignment: .leading)
                            Text(statusLabel(entry.result.isEmpty ? "—" : entry.result))
                                .frame(width: 145, alignment: .leading)
                            Text(store.levelAfterAP(learner, ap: ap).isEmpty ? "—" : store.levelAfterAP(learner, ap: ap))
                                .frame(width: 95, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                if !entry.overrideLevel.isEmpty {
                                    Text("Manual level adjustment")
                                        .font(.caption.bold())
                                }
                                if !entry.effectiveDate.isEmpty {
                                    Text("Effective: \(entry.effectiveDate)")
                                        .font(.caption)
                                }
                                if !entry.note.isEmpty {
                                    Text(entry.note)
                                        .font(.caption)
                                }
                                if learner.reactivationAPs.contains(ap) {
                                    Text("Reactivated in \(ap)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.green)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else if learner.reactivationAPs.contains(ap) {
                        HStack {
                            Text(ap).frame(width: 70, alignment: .leading).bold()
                            Text("—").frame(width: 95, alignment: .leading)
                            Text("REACTIVATED").frame(width: 145, alignment: .leading)
                            Text(store.levelBeforeAP(learner, ap: ap)).frame(width: 95, alignment: .leading)
                            Text("Learner returned to active monitoring.")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .padding(22)
        .frame(width: 900, height: 650)
    }
}

struct LearnersView: View {
    @ObservedObject var store: AppStore
    @State private var importMessage = ""
    @State private var showImportAlert = false
    @State private var editingLearnerID: UUID? = nil
    @State private var progressLearnerID: UUID? = nil
    @State private var editLRN = ""
    @State private var editFirstName = ""
    @State private var editMiddleInitial = ""
    @State private var editLastName = ""
    @State private var editExtension = ""
    @State private var editSex = ""
    @State private var editDOB = ""
    @State private var learnerToRemove: Learner? = nil
    @State private var searchText = ""
    @State private var sexFilter = "All"

    private var filteredLearners: [Learner] {
        store.data.learners.filter { learner in
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesSearch = query.isEmpty ||
                learner.displayName.lowercased().contains(query) ||
                learner.lrn.lowercased().contains(query)
            let matchesSex = sexFilter == "All" || learner.sex == sexFilter
            return matchesSearch && matchesSex
        }
    }

    private var progressLearner: Learner? {
        guard let id = progressLearnerID else { return nil }
        return store.data.learners.first(where: { $0.id == id })
    }

    private func beginEdit(_ learner: Learner) {
        editingLearnerID = learner.id
        editLRN = learner.lrn
        editFirstName = learner.firstName
        editMiddleInitial = learner.middleInitial
        editLastName = learner.lastName
        editExtension = learner.nameExtension
        editSex = learner.sex
        editDOB = learner.dateOfBirth
    }

    private func saveEdit() {
        guard let id = editingLearnerID,
              let index = store.data.learners.firstIndex(where: { $0.id == id }) else { return }

        let first = editFirstName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let mi = String(editMiddleInitial.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().prefix(1))
        let last = editLastName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let ext = editExtension.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        store.data.learners[index].lrn = editLRN.filter(\.isNumber)
        store.data.learners[index].firstName = first
        store.data.learners[index].middleInitial = mi
        store.data.learners[index].lastName = last
        store.data.learners[index].nameExtension = ext
        store.data.learners[index].fullName = [last.isEmpty ? "" : last + ",", first, ext, mi.isEmpty ? "" : mi + "."]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        store.data.learners[index].sex = editSex
        store.data.learners[index].dateOfBirth = editDOB.trimmingCharacters(in: .whitespacesAndNewlines)
        store.save()
        editingLearnerID = nil
    }

    private func removeConfirmedLearner() {
        guard let learner = learnerToRemove else {
            learnerToRemove = nil
            return
        }
        store.removeLearner(learner.id)
        learnerToRemove = nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(title: "Learners", subtitle: "Learner master list, progress profiles, and direct SF1 import")

            HStack {
                Button { store.addLearner() } label: {
                    Label("Add Learner", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    if let message = store.importSF1File() {
                        importMessage = message + "\nNames were organized into First Name, Middle Initial, Last Name, and Extension."
                        showImportAlert = true
                    }
                } label: {
                    Label("Import SF1", systemImage: "square.and.arrow.down.on.square")
                }
                .buttonStyle(.bordered)

                Button {
                    let n = store.importFromClipboard()
                    importMessage = n > 0
                        ? "Paste import completed.\nImported \(n) learner(s).\nNames were organized into separate name fields."
                        : "No valid new learners found. Copy tab-separated SF1 rows first."
                    showImportAlert = true
                } label: {
                    Label("Paste from SF1", systemImage: "doc.on.clipboard")
                }

                Spacer()
            }

            HStack(spacing: 12) {
                DashboardMetricCard(
                    title: "Male",
                    value: "\(store.data.learners.filter { $0.sex == "Male" }.count)",
                    symbol: "person.fill",
                    tint: .blue
                )
                DashboardMetricCard(
                    title: "Female",
                    value: "\(store.data.learners.filter { $0.sex == "Female" }.count)",
                    symbol: "person.fill",
                    tint: .purple
                )
                DashboardMetricCard(
                    title: "Total",
                    value: "\(store.data.learners.count)",
                    symbol: "person.2.fill",
                    tint: .secondary
                )
            }

            HStack(spacing: 12) {
                TextField("Search learner name or LRN", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)

                Picker("Sex", selection: $sexFilter) {
                    Text("All").tag("All")
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                }
                .frame(width: 150)

                Text("\(filteredLearners.count) shown")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            HStack(spacing: 10) {
                Text("Last Name").bold().frame(width: 130, alignment: .leading)
                Text("First Name").bold().frame(width: 160, alignment: .leading)
                Text("MI").bold().frame(width: 32, alignment: .leading)
                Text("Ext.").bold().frame(width: 45, alignment: .leading)
                Text("LRN").bold().frame(width: 115, alignment: .leading)
                Text("Sex").bold().frame(width: 55, alignment: .leading)
                Text("Birth Date").bold().frame(width: 85, alignment: .leading)
                Spacer()
                Text("Actions").bold().frame(width: 260, alignment: .center)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)

            List {
                ForEach(filteredLearners) { learner in
                    HStack(spacing: 10) {
                        Text(learner.lastName.isEmpty ? "—" : learner.lastName)
                            .frame(width: 130, alignment: .leading)
                            .bold()
                        Text(learner.firstName.isEmpty ? "—" : learner.firstName)
                            .frame(width: 160, alignment: .leading)
                        Text(learner.middleInitial.isEmpty ? "—" : learner.middleInitial)
                            .frame(width: 32, alignment: .leading)
                        Text(learner.nameExtension.isEmpty ? "—" : learner.nameExtension)
                            .frame(width: 45, alignment: .leading)
                        Text(learner.lrn.isEmpty ? "—" : learner.lrn)
                            .font(.caption.monospacedDigit())
                            .frame(width: 115, alignment: .leading)
                        Text(learner.sex.isEmpty ? "—" : learner.sex)
                            .frame(width: 55, alignment: .leading)
                        Text(learner.dateOfBirth.isEmpty ? "—" : learner.dateOfBirth)
                            .frame(width: 85, alignment: .leading)

                        Spacer()

                        Button {
                            progressLearnerID = learner.id
                        } label: {
                            Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            beginEdit(learner)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            learnerToRemove = learner
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                        .help("Remove learner")
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .padding(28)
        .sheet(isPresented: Binding(
            get: { editingLearnerID != nil },
            set: { if !$0 { editingLearnerID = nil } }
        )) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Edit Learner")
                    .font(.title2.bold())

                Form {
                    TextField("LRN", text: $editLRN)
                    TextField("First Name", text: $editFirstName)
                    TextField("Middle Initial", text: $editMiddleInitial)
                    TextField("Last Name", text: $editLastName)
                    TextField("Extension (Jr., Sr., II, III, etc.)", text: $editExtension)
                    Picker("Sex", selection: $editSex) {
                        Text("Select").tag("")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                    }
                    TextField("Date of Birth", text: $editDOB)
                }

                HStack {
                    Spacer()
                    Button("Cancel") { editingLearnerID = nil }
                    Button("Save Changes") { saveEdit() }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            editFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            editLastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                }
            }
            .padding(24)
            .frame(width: 560, height: 430)
        }
        .sheet(isPresented: Binding(
            get: { progressLearnerID != nil },
            set: { if !$0 { progressLearnerID = nil } }
        )) {
            if let learner = progressLearner {
                LearnerProgressSheet(store: store, learner: learner)
            }
        }
        .alert("SF1 Import", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
        .alert("Remove Learner?", isPresented: Binding(
            get: { learnerToRemove != nil },
            set: { if !$0 { learnerToRemove = nil } }
        )) {
            Button("Cancel", role: .cancel) { learnerToRemove = nil }
            Button("Remove", role: .destructive) { removeConfirmedLearner() }
        } message: {
            let name = learnerToRemove?.displayName.isEmpty == false ? learnerToRemove!.displayName : "this learner"
            Text("Remove \(name)? A restore point will be created automatically before the learner is deleted.")
        }
    }
}

struct PreAssessmentView: View {
    @ObservedObject var store: AppStore
    @State private var selectedSchoolYear = ""
    @State private var selectedPeriod = "BOSY"

    private var activeSchoolYear: String {
        selectedSchoolYear.isEmpty ? store.data.settings.schoolYear : selectedSchoolYear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(
                title: "Pre-Assessment",
                subtitle: "Choose the school year and encoding period, then encode only that assessment."
            )

            HStack(spacing: 18) {
                HStack(spacing: 6) {
                    Text("Automatic Key Stage:")
                        .foregroundStyle(.secondary)
                    Text(store.keyStage() == 0 ? "Select a grade level in Setup" : "Key Stage \(store.keyStage())")
                        .bold()
                }

                Spacer()

                Picker("School Year", selection: Binding(
                    get: { activeSchoolYear },
                    set: { selectedSchoolYear = $0 }
                )) {
                    ForEach(store.schoolYearOptions(), id: \.self) { year in
                        Text(year).tag(year)
                    }
                }
                .frame(width: 205)

                Picker("Encoding Period", selection: $selectedPeriod) {
                    ForEach(preAssessmentPeriods, id: \.self) { period in
                        Text(period).tag(period)
                    }
                }
                .frame(width: 185)
            }

            HStack {
                Label("\(activeSchoolYear) • \(selectedPeriod) Encoding", systemImage: "square.and.pencil")
                    .font(.headline)
                Spacer()
                Text("Only \(selectedPeriod) is shown below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            HStack(spacing: 12) {
                Text("Learner").bold().frame(minWidth: 280, alignment: .leading)
                Text("Initial Level").bold().frame(width: 170, alignment: .leading)
                Text("Reading Component").bold().frame(minWidth: 230, alignment: .leading)
                Text("\(selectedPeriod) Profile").bold().frame(width: 220, alignment: .leading)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)

            List {
                ForEach(store.data.learners) { learner in
                    let pre = store.preAssessment(for: learner, schoolYear: activeSchoolYear)

                    HStack(spacing: 12) {
                        Text(learner.displayName.isEmpty ? "Unnamed learner" : learner.displayName)
                            .bold()
                            .frame(minWidth: 280, alignment: .leading)

                        Picker("Initial Level", selection: store.preLevelBinding(
                            for: learner.id,
                            schoolYear: activeSchoolYear
                        )) {
                            Text("Select Level").tag("")
                            ForEach(readingLevels) { level in
                                Text(level.code).tag(level.code)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 170)

                        Text(readingLevels.first(where: { $0.code == pre.level })?.area.capitalized ?? "—")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 230, alignment: .leading)

                        Picker(selectedPeriod, selection: store.preProfileBinding(
                            for: learner.id,
                            schoolYear: activeSchoolYear,
                            period: selectedPeriod
                        )) {
                            ForEach(store.profileOptions(), id: \.self) { option in
                                Text(option.isEmpty ? "Select \(selectedPeriod)" : option).tag(option)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 220)
                    }
                    .padding(.vertical, 7)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .padding(28)
        .onAppear {
            if selectedSchoolYear.isEmpty {
                selectedSchoolYear = store.data.settings.schoolYear
            }
        }
    }
}


struct MonitoringView: View {
    @ObservedObject var store: AppStore

    @State private var editingLearnerID: UUID? = nil
    @State private var manualLevel = ""
    @State private var manualNote = ""
    @State private var showOverrideConfirmation = false
    @State private var searchText = ""
    @State private var statusFilter = "All"
    @State private var showLockConfirmation = false

    private var isLocked: Bool {
        store.isAssessmentLocked(store.selectedAP)
    }

    private var requiredLearners: [Learner] {
        store.data.learners.filter { learner in
            store.inactiveStatusBeforeAP(learner, ap: store.selectedAP) == nil
        }
    }

    private var encodedCount: Int {
        requiredLearners.filter { learner in
            !(learner.assessments[store.selectedAP]?.result ?? "").isEmpty
        }.count
    }

    private var missingCount: Int {
        max(0, requiredLearners.count - encodedCount)
    }

    private var filteredLearners: [Learner] {
        store.data.learners.filter { learner in
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesSearch = query.isEmpty ||
                learner.displayName.lowercased().contains(query) ||
                learner.lrn.lowercased().contains(query)

            let entryResult = learner.assessments[store.selectedAP]?.result ?? ""
            let inactivePrior = store.inactiveStatusBeforeAP(learner, ap: store.selectedAP)

            let matchesStatus: Bool
            switch statusFilter {
            case "Missing":
                matchesStatus = inactivePrior == nil && entryResult.isEmpty
            case "Inactive":
                matchesStatus = inactivePrior != nil || store.isInactiveStatus(entryResult)
            case "All":
                matchesStatus = true
            default:
                matchesStatus = entryResult == statusFilter
            }
            return matchesSearch && matchesStatus
        }
    }

    func resultBinding(for learnerID: UUID) -> Binding<String> {
        Binding(
            get: {
                store.data.learners.first(where: { $0.id == learnerID })?
                    .assessments[store.selectedAP]?.result ?? ""
            },
            set: { newValue in
                guard !isLocked,
                      let index = store.data.learners.firstIndex(where: { $0.id == learnerID }) else { return }

                var entry = store.data.learners[index].assessments[store.selectedAP] ?? AssessmentEntry()
                entry.result = newValue
                entry.overrideLevel = ""

                if !store.isInactiveStatus(newValue) {
                    entry.effectiveDate = ""
                }

                store.data.learners[index].assessments[store.selectedAP] = entry
                store.save()
            }
        )
    }

    private func noteBinding(for learnerID: UUID) -> Binding<String> {
        Binding(
            get: {
                store.data.learners.first(where: { $0.id == learnerID })?
                    .assessments[store.selectedAP]?.note ?? ""
            },
            set: { value in
                guard !isLocked,
                      let index = store.data.learners.firstIndex(where: { $0.id == learnerID }),
                      var entry = store.data.learners[index].assessments[store.selectedAP] else { return }
                entry.note = value
                store.data.learners[index].assessments[store.selectedAP] = entry
                store.save()
            }
        )
    }

    private func effectiveDateBinding(for learnerID: UUID) -> Binding<String> {
        Binding(
            get: {
                store.data.learners.first(where: { $0.id == learnerID })?
                    .assessments[store.selectedAP]?.effectiveDate ?? ""
            },
            set: { value in
                guard !isLocked,
                      let index = store.data.learners.firstIndex(where: { $0.id == learnerID }),
                      var entry = store.data.learners[index].assessments[store.selectedAP] else { return }
                entry.effectiveDate = value
                store.data.learners[index].assessments[store.selectedAP] = entry
                store.save()
            }
        )
    }

    private var editingLearner: Learner? {
        guard let id = editingLearnerID else { return nil }
        return store.data.learners.first(where: { $0.id == id })
    }

    private func beginLevelEdit(_ learner: Learner) {
        guard !isLocked else { return }
        editingLearnerID = learner.id
        manualLevel = store.levelAfterAP(learner, ap: store.selectedAP)
        manualNote = learner.assessments[store.selectedAP]?.note ?? ""
    }

    private func saveManualLevel() {
        guard !isLocked,
              let learner = editingLearner,
              let index = store.data.learners.firstIndex(where: { $0.id == learner.id }),
              !manualLevel.isEmpty else { return }

        var entry = store.data.learners[index].assessments[store.selectedAP] ?? AssessmentEntry()
        entry.overrideLevel = manualLevel
        entry.note = manualNote.trimmingCharacters(in: .whitespacesAndNewlines)
        store.data.learners[index].assessments[store.selectedAP] = entry
        store.save()
        editingLearnerID = nil
        showOverrideConfirmation = false
    }

    private func clearManualOverride(_ learner: Learner) {
        guard !isLocked,
              let index = store.data.learners.firstIndex(where: { $0.id == learner.id }),
              var entry = store.data.learners[index].assessments[store.selectedAP] else { return }
        entry.overrideLevel = ""
        store.data.learners[index].assessments[store.selectedAP] = entry
        store.save()
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "NLS": return "NLS – No Longer in School"
        case "NLP": return "NLP – No Longer Participating"
        case "TRANSFER OUT": return "Transfer Out"
        default: return status
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                PageHeader(title: "Monitoring", subtitle: "AP1–AP15 reading progression")
                Spacer()
                Button {
                    showLockConfirmation = true
                } label: {
                    Label(
                        isLocked ? "Unlock \(store.selectedAP)" : "Finalize \(store.selectedAP)",
                        systemImage: isLocked ? "lock.open.fill" : "lock.fill"
                    )
                }
                .buttonStyle(isLocked ? .bordered : .borderedProminent)
            }

            HStack(spacing: 14) {
                Picker("Assessment Period", selection: $store.selectedAP) {
                    ForEach(assessmentPeriods, id: \.self) { Text($0).tag($0) }
                }
                .frame(width: 210)

                Picker("Term", selection: Binding(
                    get: { store.data.assessmentTerms[store.selectedAP] ?? "1ST" },
                    set: {
                        guard !isLocked else { return }
                        store.data.assessmentTerms[store.selectedAP] = $0
                        store.save()
                    }
                )) {
                    ForEach(terms, id: \.self) { Text($0).tag($0) }
                }
                .frame(width: 150)
                .disabled(isLocked)

                Spacer()

                if isLocked {
                    Label("FINALIZED", systemImage: "lock.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }

            HStack(spacing: 12) {
                DashboardMetricCard(
                    title: "Required",
                    value: "\(requiredLearners.count)",
                    symbol: "person.2.fill",
                    tint: .blue
                )
                DashboardMetricCard(
                    title: "Encoded",
                    value: "\(encodedCount)",
                    symbol: "checkmark.circle.fill",
                    tint: .green
                )
                DashboardMetricCard(
                    title: "Missing",
                    value: "\(missingCount)",
                    symbol: "exclamationmark.circle.fill",
                    tint: missingCount == 0 ? .green : .orange
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Encoding Progress")
                        .font(.caption.bold())
                    ProgressView(value: Double(encodedCount), total: Double(max(requiredLearners.count, 1)))
                    Text("\(encodedCount) of \(requiredLearners.count) required learners encoded")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 12) {
                TextField("Search learner name or LRN", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)

                Picker("Filter", selection: $statusFilter) {
                    Text("All").tag("All")
                    Text("Missing").tag("Missing")
                    Divider()
                    Text("READY").tag("READY")
                    Text("NOT READY").tag("NOT READY")
                    Text("REVERTED").tag("REVERTED")
                    Text("Inactive").tag("Inactive")
                    Text("NLS").tag("NLS")
                    Text("NLP").tag("NLP")
                    Text("TRANSFER OUT").tag("TRANSFER OUT")
                }
                .frame(width: 190)

                Text("\(filteredLearners.count) shown")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("READY +1 • NOT READY stays • REVERTED −1 • Edit Level for special cases")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            List {
                ForEach(filteredLearners) { learner in
                    let inactive = store.inactiveStatusBeforeAP(learner, ap: store.selectedAP)
                    let entry = learner.assessments[store.selectedAP]
                    let previous = store.levelBeforeAP(learner, ap: store.selectedAP)
                    let newLevel = store.levelAfterAP(learner, ap: store.selectedAP)
                    let hasOverride = !(entry?.overrideLevel ?? "").isEmpty

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(learner.displayName.isEmpty ? "Unnamed learner" : learner.displayName)
                                    .bold()
                                Text(learner.lrn)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            .frame(minWidth: 225, alignment: .leading)

                            VStack(alignment: .leading) {
                                Text("Previous").font(.caption2).foregroundStyle(.secondary)
                                Text(previous.isEmpty ? "—" : previous)
                                    .monospaced()
                            }
                            .frame(width: 105, alignment: .leading)

                            if let inactive {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(statusLabel(inactive.status)).bold()
                                    Text("Inactive since \(inactive.period)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(minWidth: 220, alignment: .leading)

                                Button {
                                    store.reactivateLearner(learner.id, at: store.selectedAP)
                                } label: {
                                    Label("Reactivate", systemImage: "person.crop.circle.badge.checkmark")
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isLocked)
                            } else {
                                Picker("Status", selection: resultBinding(for: learner.id)) {
                                    Text("Select Status").tag("")
                                    Text("READY").tag("READY")
                                    Text("NOT READY").tag("NOT READY")
                                    Text("REVERTED").tag("REVERTED")
                                    Divider()
                                    Text("NLS – No Longer in School").tag("NLS")
                                    Text("NLP – No Longer Participating").tag("NLP")
                                    Text("TRANSFER OUT").tag("TRANSFER OUT")
                                }
                                .frame(width: 230)
                                .disabled(isLocked)

                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading) {
                                    HStack(spacing: 5) {
                                        Text("New Level").font(.caption2).foregroundStyle(.secondary)
                                        if hasOverride {
                                            Text("MANUAL")
                                                .font(.system(size: 8, weight: .bold))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text(newLevel.isEmpty ? "—" : newLevel)
                                        .monospaced()
                                        .bold()
                                }
                                .frame(width: 112, alignment: .leading)

                                Button {
                                    beginLevelEdit(learner)
                                } label: {
                                    Label("Edit Level", systemImage: "pencil")
                                }
                                .buttonStyle(.bordered)
                                .disabled(
                                    isLocked ||
                                    entry?.result.isEmpty != false ||
                                    store.isInactiveStatus(entry?.result ?? "")
                                )

                                if hasOverride {
                                    Button {
                                        clearManualOverride(learner)
                                    } label: {
                                        Image(systemName: "arrow.uturn.backward")
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(isLocked)
                                    .help("Restore automatic level")
                                }
                            }

                            Spacer()
                        }

                        if let entry, store.isInactiveStatus(entry.result), inactive == nil {
                            HStack(spacing: 10) {
                                Label("\(statusLabel(entry.result)) starts in \(store.selectedAP)", systemImage: "person.crop.circle.badge.xmark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                TextField("Effective date (optional)", text: effectiveDateBinding(for: learner.id))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 165)
                                    .disabled(isLocked)

                                TextField("Reason / note (optional)", text: noteBinding(for: learner.id))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 320)
                                    .disabled(isLocked)
                            }
                            .padding(.leading, 342)
                        } else if hasOverride, let note = entry?.note, !note.isEmpty {
                            Text("Manual adjustment note: \(note)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 342)
                        }

                        if learner.reactivationAPs.contains(store.selectedAP) {
                            Label("Reactivated in \(store.selectedAP)", systemImage: "person.crop.circle.badge.checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                                .padding(.leading, 342)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .padding(28)
        .sheet(isPresented: Binding(
            get: { editingLearnerID != nil },
            set: { if !$0 { editingLearnerID = nil } }
        )) {
            if let learner = editingLearner {
                let previous = store.levelBeforeAP(learner, ap: store.selectedAP)
                let status = learner.assessments[store.selectedAP]?.result ?? ""
                let automatic = store.defaultLevelAfter(result: status, from: previous)

                VStack(alignment: .leading, spacing: 18) {
                    Text("Edit Reading Level")
                        .font(.title2.bold())

                    Text(learner.displayName)
                        .font(.headline)

                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 9) {
                        GridRow {
                            Text("Assessment Period").foregroundStyle(.secondary)
                            Text(store.selectedAP).bold()
                        }
                        GridRow {
                            Text("Previous Level").foregroundStyle(.secondary)
                            Text(previous.isEmpty ? "—" : previous).bold()
                        }
                        GridRow {
                            Text("Status").foregroundStyle(.secondary)
                            Text(statusLabel(status)).bold()
                        }
                        GridRow {
                            Text("Automatic Level").foregroundStyle(.secondary)
                            Text(automatic.isEmpty ? "—" : automatic).bold()
                        }
                    }

                    Divider()

                    Picker("Manual Level", selection: $manualLevel) {
                        ForEach(readingLevels) { level in
                            Text(level.code).tag(level.code)
                        }
                    }

                    TextField("Reason / Note (optional)", text: $manualNote)

                    Text("Use this only for special cases, such as a learner jumping several levels forward or reverting more than one level.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Spacer()
                        Button("Cancel") { editingLearnerID = nil }
                        Button("Apply Manual Level") { showOverrideConfirmation = true }
                            .buttonStyle(.borderedProminent)
                            .disabled(manualLevel.isEmpty || isLocked)
                    }
                }
                .padding(24)
                .frame(width: 520, height: 410)
                .alert("Confirm Manual Level Change", isPresented: $showOverrideConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Confirm") { saveManualLevel() }
                } message: {
                    Text("\(learner.displayName)\n\(previous) → \(manualLevel)\n\nThis overrides the normal automatic progression for \(store.selectedAP).")
                }
            }
        }
        .alert(isLocked ? "Unlock Assessment Period?" : "Finalize Assessment Period?", isPresented: $showLockConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(isLocked ? "Unlock" : "Finalize") {
                store.setAssessmentLocked(store.selectedAP, locked: !isLocked)
            }
        } message: {
            if isLocked {
                Text("\(store.selectedAP) is currently locked. Unlocking will allow its encoded results to be edited again.")
            } else if missingCount > 0 {
                Text("\(store.selectedAP) still has \(missingCount) required learner(s) without an encoded result. You can finalize it, but the missing records will remain visible when you unlock it later.")
            } else {
                Text("All required learners are encoded. Finalizing \(store.selectedAP) will lock its term, results, notes, and manual level changes.")
            }
        }
    }
}

struct ReportsView: View {
    @ObservedObject var store: AppStore
    @State private var stage = "PRETEST"
    @State private var printout: PrintoutType = .classroomMonitoring

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(title: "Reports", subtitle: "Two official BULIG print-outs based on the Excel forms")

                HStack(spacing: 14) {
                    Picker("Print-out", selection: $printout) {
                        ForEach(PrintoutType.allCases) { item in Text(item.rawValue).tag(item) }
                    }
                    .frame(width: 330)

                    Picker("Assessment Period", selection: $stage) {
                        Text("PRETEST").tag("PRETEST")
                        ForEach(assessmentPeriods, id: \.self) { Text($0).tag($0) }
                    }
                    .frame(width: 210)

                    Spacer()
                    Button { store.previewReport(stage: stage, type: printout) } label: {
                        Label("Preview", systemImage: "eye")
                    }
                    Button { store.printReport(stage: stage, type: printout) } label: {
                        Label("Print", systemImage: "printer")
                    }
                    Button { store.savePDFReport(stage: stage, type: printout) } label: {
                        Label("Save as PDF", systemImage: "arrow.down.doc")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if printout == .classroomMonitoring {
                    GroupBox("CLASSROOM READING MONITORING REPORT") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Assessment Period").foregroundStyle(.secondary)
                                Text(stage).bold()
                                Spacer()
                                Text("Term").foregroundStyle(.secondary)
                                Text(store.data.assessmentTerms[stage] ?? "1ST").bold()
                            }
                            Grid(alignment: .leading, horizontalSpacing: 34, verticalSpacing: 8) {
                                GridRow { Text("LEVEL").bold(); Text("MALE").bold(); Text("FEMALE").bold(); Text("TOTAL").bold() }
                                Divider()
                                ForEach(store.reportRows(stage: stage), id: \.0) { row in
                                    GridRow { Text(row.0).bold(); Text("\(row.1)"); Text("\(row.2)"); Text("\(row.3)").bold() }
                                }
                            }
                            Divider()
                            if store.keyStage() > 0 {
                                Text("KEY STAGE \(store.keyStage()) ONLY").font(.headline)
                                Text("The print/PDF will include only this Key Stage table. Key Stages not applicable to Grade \(store.data.settings.gradeLevel) will not be printed.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Label("Set the Grade Level in Setup before printing.", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(12)
                    }
                } else {
                    GroupBox("LIST OF PUPILS") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("The print-out follows the PRETEST LIPS / APLIST format and is printed in A4 portrait.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("Male").bold(); Text("\(store.data.learners.filter { $0.sex == "Male" }.count)")
                                Text("Female").bold(); Text("\(store.data.learners.filter { $0.sex == "Female" }.count)")
                                Spacer()
                                Text("Total Enrollment").bold(); Text("\(store.data.learners.count)")
                            }
                            Divider()
                            ForEach(store.learnersForStage(stage).prefix(12), id: \.0.id) { learner, level in
                                HStack {
                                    Text(learner.displayName.isEmpty ? "Unnamed learner" : learner.displayName).frame(minWidth: 300, alignment: .leading)
                                    Text(learner.sex).frame(width: 70, alignment: .leading)
                                    Text(level.isEmpty ? "—" : level).monospaced().bold()
                                }
                            }
                            if store.data.learners.count > 12 {
                                Text("… and \(store.data.learners.count - 12) more learner(s) in the printed report.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                    }
                }

                GroupBox("Color Legend") {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        alignment: .leading,
                        spacing: 10
                    ) {
                        ForEach(readingLevels) { level in
                            HStack(spacing: 9) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(nsColor: reportLevelColor(level.code)))
                                    .frame(width: 34, height: 22)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.secondary.opacity(0.45), lineWidth: 1)
                                    )
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(level.code).bold()
                                    Text(level.area.capitalized)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(10)
                }
            }
            .padding(28)
        }
    }
}

struct BackupView: View {
    @ObservedObject var store: AppStore
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PageHeader(title: "Backup & Restore", subtitle: "Keep an offline copy of your BULIG data")
            HStack(spacing: 18) {
                GroupBox("Backup") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Save school setup, learners, pre-assessment, and AP1–AP15 entries into one JSON backup file.")
                            .foregroundStyle(.secondary)
                        Button { store.exportBackup() } label: {
                            Label("Save Backup", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                GroupBox("Restore") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Restore a previously saved BULIG backup. The current data will be replaced by the selected backup.")
                            .foregroundStyle(.secondary)
                        Button { store.restoreBackup() } label: {
                            Label("Restore Backup", systemImage: "arrow.counterclockwise")
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer()
        }
        .padding(28)
    }
}

@main
struct BULIGRMSTeacherApp: App {
    var body: some Scene {
        WindowGroup("BULIG RMS Teacher") {
            RootView()
        }
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .appInfo) {
                Divider()
                Text("BULIG RMS Teacher v0.22 • Offline macOS App")
            }
        }
    }
}
