import SwiftUI
import AppKit
import WebKit
import JavaScriptCore

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
}

struct PreAssessment: Codable, Equatable {
    var level = ""
    var bosy = ""
    var mosy = ""
    var eosy = ""
}

struct AssessmentEntry: Codable, Equatable {
    var result = ""
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

    enum CodingKeys: String, CodingKey {
        case id, lrn, fullName, firstName, middleInitial, lastName, nameExtension, sex, dateOfBirth, pre, preHistory, assessments
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
        assessments: [String: AssessmentEntry] = [:]
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
let results = ["", "READY", "NOT READY", "NLP"]
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

final class HTMLPrintCoordinator: NSObject, WKNavigationDelegate {
    private let webView: WKWebView
    private let orientation: NSPrintInfo.PaperOrientation
    private let completion: () -> Void

    init(html: String, orientation: NSPrintInfo.PaperOrientation, completion: @escaping () -> Void) {
        self.webView = WKWebView(frame: NSRect(x: 0, y: 0, width: orientation == .landscape ? 1120 : 790, height: 1100))
        self.orientation = orientation
        self.completion = completion
        super.init()
        self.webView.navigationDelegate = self
        self.webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let info = NSPrintInfo.shared.copy() as! NSPrintInfo
            info.paperSize = NSSize(width: 595.2, height: 841.8)
            info.orientation = self.orientation
            info.leftMargin = 36
            info.rightMargin = 36
            info.topMargin = 36
            info.bottomMargin = 36
            info.horizontalPagination = .fit
            info.verticalPagination = .automatic
            info.isHorizontallyCentered = true
            let op = webView.printOperation(with: info)
            op.showsPrintPanel = true
            op.showsProgressPanel = true
            op.run()
            self.completion()
        }
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published var data = AppData()
    @Published var selectedAP = "AP1"
    @Published var statusMessage = "Ready"
    private let appName = "BULIG RMS Teacher"
    private var printCoordinator: HTMLPrintCoordinator?

    init() { load(); migrateLearnerNameFields(); migratePreAssessmentHistory() }

    private var supportFolder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent(appName, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private var dataURL: URL { supportFolder.appendingPathComponent("data.json") }

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

    func levelBeforeAP(_ learner: Learner, ap: String) -> String {
        var level = preAssessment(for: learner).level
        guard !level.isEmpty else { return "" }
        let target = assessmentPeriods.firstIndex(of: ap) ?? 0
        if target == 0 { return level }
        for i in 0..<target {
            let key = assessmentPeriods[i]
            if learner.assessments[key]?.result == "READY" { level = nextLevel(level) }
        }
        return level
    }

    func levelAfterAP(_ learner: Learner, ap: String) -> String {
        let before = levelBeforeAP(learner, ap: ap)
        if learner.assessments[ap]?.result == "READY" { return nextLevel(before) }
        return before
    }

    func currentLevel(_ learner: Learner, through ap: String?) -> String {
        guard let ap else { return preAssessment(for: learner).level }
        var level = preAssessment(for: learner).level
        guard !level.isEmpty else { return "" }
        for key in assessmentPeriods {
            if learner.assessments[key]?.result == "READY" { level = nextLevel(level) }
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
            learner.sex == sex && preAssessment(for: learner)[keyPath: checkpoint] == target
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
        @page { size: A4 \(landscape ? "landscape" : "portrait"); margin: 0.5in; }
        * { box-sizing: border-box; }
        body { font-family: Arial, Helvetica, sans-serif; color:#000; margin:0; font-size:10px; }
        .brandrow { display:grid; grid-template-columns: 140px 1fr 260px; align-items:center; min-height:84px; }
        .deped-mark { text-align:center; font-size:17px; font-weight:800; color:#124b91; line-height:1.1; }
        .deped-mark span { font-size:10px; color:#333; }
        .bulig { width:245px; max-height:82px; object-fit:contain; display:block; margin-left:auto; }
        .agency { text-align:center; line-height:1.25; font-family:Georgia,serif; }
        .gateway { text-align:center; font-weight:700; font-family:Georgia,serif; font-size:14px; margin-top:2px; }
        .tagline { text-align:center; font-weight:700; font-family:Georgia,serif; font-size:12px; }
        .title { text-align:center; font-weight:800; font-family:Georgia,serif; font-size:18px; margin:5px 0 15px; }
        table { border-collapse:collapse; width:100%; }
        .meta td { border:1.4px solid #000; height:22px; padding:3px 6px; font-size:11px; }
        .meta .label { text-align:center; font-weight:600; width:18%; }
        .levels { margin-top:18px; table-layout:fixed; }
        .levels th,.levels td,.profile th,.profile td,.pupils th,.pupils td { border:1.35px solid #000; padding:4px 4px; text-align:center; }
        .levels th,.profile th,.pupils th { background:#d9d9d9; font-weight:700; }
        .levels .area { font-size:7.5px; line-height:1.12; }
        .left { text-align:left !important; }
        .profile-title { margin-top:18px; background:#d9d9d9; border:1.35px solid #000; border-bottom:0; text-align:center; font-weight:800; font-size:13px; padding:4px; }
        .profile { table-layout:fixed; }
        .signature-row { display:grid; grid-template-columns:1fr 1fr 150px; gap:45px; margin-top:34px; align-items:end; }
        .sig { text-align:center; font-size:10px; }
        .sig .name { border-bottom:1px solid #000; min-height:24px; padding-top:11px; font-weight:700; }
        .datebox { text-align:center; font-size:9px; }
        .datebox .date { border-bottom:1px solid #000; padding-bottom:3px; margin-bottom:3px; }
        .group { background:#e6e6e6; font-weight:800; text-align:center !important; }
        .pupils { margin-top:18px; table-layout:fixed; font-size:9px; }
        .pupils th:nth-child(1) { width:7%; }
        .pupils th:nth-child(2) { width:38%; }
        .pupils th:nth-child(3) { width:18%; }
        .pupils th:nth-child(4) { width:18%; }
        .pupils th:nth-child(5) { width:19%; }
        .summary { margin-top:14px; width:55%; font-size:10px; }
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

    func printReport(stage: String, type: PrintoutType) {
        let html: String
        let orientation: NSPrintInfo.PaperOrientation
        switch type {
        case .classroomMonitoring:
            html = classroomMonitoringHTML(stage: stage)
            orientation = .landscape
        case .pupilList:
            html = pupilListHTML(stage: stage)
            orientation = .portrait
        }
        printCoordinator = HTMLPrintCoordinator(html: html, orientation: orientation) { [weak self] in
            self?.printCoordinator = nil
        }
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

struct DashboardView: View {
    @ObservedObject var store: AppStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(title: "Dashboard", subtitle: "Bukidnon's Unified Literacy and Intervention Gateway")
                HStack(spacing: 14) {
                    StatCard(title: "Learners", value: "\(store.data.learners.count)", symbol: "person.2.fill")
                    StatCard(title: "Male", value: "\(store.data.learners.filter{$0.sex == "Male"}.count)", symbol: "person.fill")
                    StatCard(title: "Female", value: "\(store.data.learners.filter{$0.sex == "Female"}.count)", symbol: "person.fill")
                    StatCard(title: "Key Stage", value: store.keyStage() == 0 ? "—" : "KS \(store.keyStage())", symbol: "book.fill")
                }
                GroupBox("Current Class") {
                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                        GridRow { Text("School").foregroundStyle(.secondary); Text(store.data.settings.schoolName.isEmpty ? "Not configured" : store.data.settings.schoolName).bold() }
                        GridRow { Text("Class").foregroundStyle(.secondary); Text("Grade \(store.data.settings.gradeLevel) – \(store.data.settings.section)").bold() }
                        GridRow { Text("Adviser").foregroundStyle(.secondary); Text(store.data.settings.adviser).bold() }
                        GridRow { Text("Assessment Tool").foregroundStyle(.secondary); Text(store.data.settings.assessmentTool).bold() }
                    }
                    .padding(8)
                }
                GroupBox("Reading Level Snapshot") {
                    VStack(spacing: 8) {
                        ForEach(readingLevels) { level in
                            HStack {
                                Text(level.code).frame(width: 90, alignment: .leading).bold()
                                Text(level.area).font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text("\(store.data.learners.filter{$0.pre.level == level.code}.count)").monospacedDigit().bold()
                            }
                            Divider()
                        }
                    }
                    .padding(8)
                }
            }
            .padding(28)
        }
    }
}

struct SetupView: View {
    @ObservedObject var store: AppStore
    @State private var showSavedConfirmation = false
    let grades = (1...12).map(String.init)
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: "Setup", subtitle: "School and class information")
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
            Text("School and class information has been saved successfully.")
        }
    }
}

struct LearnersView: View {
    @ObservedObject var store: AppStore
    @State private var importMessage = ""
    @State private var showImportAlert = false
    @State private var editingLearnerID: UUID? = nil
    @State private var editLRN = ""
    @State private var editFirstName = ""
    @State private var editMiddleInitial = ""
    @State private var editLastName = ""
    @State private var editExtension = ""
    @State private var editSex = ""
    @State private var editDOB = ""
    @State private var learnerToRemove: Learner? = nil

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
        guard let learner = learnerToRemove,
              let index = store.data.learners.firstIndex(where: { $0.id == learner.id }) else {
            learnerToRemove = nil
            return
        }
        store.data.learners.remove(at: index)
        store.save()
        learnerToRemove = nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(title: "Learners", subtitle: "Learner master list and direct SF1 import")
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
                HStack(spacing: 7) {
                    Image(systemName: "person.fill")
                    Text("Male")
                    Text("\(store.data.learners.filter { $0.sex == "Male" }.count)")
                        .bold()
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 9))

                HStack(spacing: 7) {
                    Image(systemName: "person.fill")
                    Text("Female")
                    Text("\(store.data.learners.filter { $0.sex == "Female" }.count)")
                        .bold()
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.pink.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 9))

                HStack(spacing: 7) {
                    Image(systemName: "person.2.fill")
                    Text("Total")
                    Text("\(store.data.learners.count)")
                        .bold()
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 9))

                Spacer()
            }

            Text("SF1 NAME is automatically separated into Last Name, First Name, Middle Initial, and Extension. You can correct any unusual name through Edit.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Text("Last Name").bold().frame(width: 145, alignment: .leading)
                Text("First Name").bold().frame(width: 185, alignment: .leading)
                Text("MI").bold().frame(width: 38, alignment: .leading)
                Text("Ext.").bold().frame(width: 55, alignment: .leading)
                Text("LRN").bold().frame(width: 125, alignment: .leading)
                Text("Sex").bold().frame(width: 60, alignment: .leading)
                Text("Birth Date").bold().frame(width: 95, alignment: .leading)
                Spacer()
                Text("Actions").bold().frame(width: 165, alignment: .center)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)

            List {
                ForEach(store.data.learners) { learner in
                    HStack(spacing: 10) {
                        Text(learner.lastName.isEmpty ? "—" : learner.lastName)
                            .frame(width: 145, alignment: .leading)
                            .bold()
                        Text(learner.firstName.isEmpty ? "—" : learner.firstName)
                            .frame(width: 185, alignment: .leading)
                        Text(learner.middleInitial.isEmpty ? "—" : learner.middleInitial)
                            .frame(width: 38, alignment: .leading)
                        Text(learner.nameExtension.isEmpty ? "—" : learner.nameExtension)
                            .frame(width: 55, alignment: .leading)
                        Text(learner.lrn.isEmpty ? "—" : learner.lrn)
                            .font(.caption.monospacedDigit())
                            .frame(width: 125, alignment: .leading)
                        Text(learner.sex.isEmpty ? "—" : learner.sex)
                            .frame(width: 60, alignment: .leading)
                        Text(learner.dateOfBirth.isEmpty ? "—" : learner.dateOfBirth)
                            .frame(width: 95, alignment: .leading)

                        Spacer()

                        Button {
                            beginEdit(learner)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            learnerToRemove = learner
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
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
                    Button("Cancel") {
                        editingLearnerID = nil
                    }
                    Button("Save Changes") {
                        saveEdit()
                    }
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
        .alert("SF1 Import", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importMessage)
        }
        .alert("Remove Learner?", isPresented: Binding(
            get: { learnerToRemove != nil },
            set: { if !$0 { learnerToRemove = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                learnerToRemove = nil
            }
            Button("Remove", role: .destructive) {
                removeConfirmedLearner()
            }
        } message: {
            let name = learnerToRemove?.displayName.isEmpty == false ? learnerToRemove!.displayName : "this learner"
            Text("Remove \(name)? This will also delete the learner's pre-assessment and AP1–AP15 records.")
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

    func resultBinding(for learnerID: UUID) -> Binding<String> {
        Binding(
            get: {
                store.data.learners.first(where: {$0.id == learnerID})?.assessments[store.selectedAP]?.result ?? ""
            },
            set: { newValue in
                guard let index = store.data.learners.firstIndex(where: {$0.id == learnerID}) else { return }
                store.data.learners[index].assessments[store.selectedAP] = AssessmentEntry(result: newValue)
                store.save()
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageHeader(title: "Monitoring", subtitle: "AP1–AP15 reading progression")
            HStack(spacing: 14) {
                Picker("Assessment Period", selection: $store.selectedAP) {
                    ForEach(assessmentPeriods, id: \.self) { Text($0).tag($0) }
                }
                .frame(width: 210)
                Picker("Term", selection: Binding(
                    get: { store.data.assessmentTerms[store.selectedAP] ?? "1ST" },
                    set: { store.data.assessmentTerms[store.selectedAP] = $0; store.save() }
                )) {
                    ForEach(terms, id: \.self) { Text($0).tag($0) }
                }
                .frame(width: 150)
                Spacer()
                Text("READY advances one level • NOT READY/NLP retains level")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            List {
                ForEach(store.data.learners) { learner in
                    HStack(spacing: 12) {
                        Text(learner.displayName.isEmpty ? "Unnamed learner" : learner.displayName)
                            .frame(minWidth: 240, alignment: .leading)
                            .bold()
                        VStack(alignment: .leading) {
                            Text("Previous").font(.caption2).foregroundStyle(.secondary)
                            Text(store.levelBeforeAP(learner, ap: store.selectedAP).isEmpty ? "—" : store.levelBeforeAP(learner, ap: store.selectedAP))
                                .monospaced()
                        }
                        .frame(width: 115, alignment: .leading)
                        Picker("Result", selection: resultBinding(for: learner.id)) {
                            ForEach(results, id: \.self) { Text($0.isEmpty ? "Select Result" : $0).tag($0) }
                        }
                        .frame(width: 170)
                        Image(systemName: "arrow.right").foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text("New Level").font(.caption2).foregroundStyle(.secondary)
                            Text(store.levelAfterAP(learner, ap: store.selectedAP).isEmpty ? "—" : store.levelAfterAP(learner, ap: store.selectedAP))
                                .monospaced()
                                .bold()
                        }
                        .frame(width: 115, alignment: .leading)
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .padding(28)
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
                    Button { store.printReport(stage: stage, type: printout) } label: {
                        Label("Print / Save PDF", systemImage: "printer")
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
                Text("BULIG RMS Teacher v0.11 • Offline macOS App")
            }
        }
    }
}
