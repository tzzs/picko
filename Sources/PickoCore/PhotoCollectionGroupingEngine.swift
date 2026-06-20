import Foundation

public struct PhotoCollectionGroup: Equatable, Identifiable {
    public enum Kind: Equatable {
        case time
        case place
    }

    public var id: String
    public var kind: Kind
    public var title: String
    public var subtitle: String
    public var assetIds: [PhotoAsset.ID]
    public var previewAssetIds: [PhotoAsset.ID]
    public var similarGroupCount: Int
    public var sortDate: Date
    public var representativeLocation: PhotoAsset.Location?

    public init(
        id: String,
        kind: Kind,
        title: String,
        subtitle: String,
        assetIds: [PhotoAsset.ID],
        previewAssetIds: [PhotoAsset.ID],
        similarGroupCount: Int,
        sortDate: Date,
        representativeLocation: PhotoAsset.Location? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.assetIds = assetIds
        self.previewAssetIds = previewAssetIds
        self.similarGroupCount = similarGroupCount
        self.sortDate = sortDate
        self.representativeLocation = representativeLocation
    }
}

public protocol PlaceLabelResolving: Sendable {
    func label(for location: PhotoAsset.Location) async -> String?
}

public struct PhotoCollectionGroupingEngine: Sendable {
    public init() {}

    public func timeGroups(
        from assets: [PhotoAsset],
        similarGroups: [SimilarGroup] = [],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [PhotoCollectionGroup] {
        let unreviewedAssets = assets.filter { $0.status == .unreviewed }
        guard !unreviewedAssets.isEmpty else {
            return []
        }

        var buckets: [TimeBucket: [PhotoAsset]] = [:]
        for asset in unreviewedAssets {
            buckets[timeBucket(for: asset.creationDate, now: now, calendar: calendar), default: []].append(asset)
        }

        return buckets.map { bucket, assets in
            let sortedAssets = assets.sorted { $0.creationDate > $1.creationDate }
            let assetIds = sortedAssets.map(\.id)
            let similarCount = matchingSimilarGroupCount(in: assetIds, similarGroups: similarGroups)
            return PhotoCollectionGroup(
                id: bucket.id,
                kind: .time,
                title: bucket.title(calendar: calendar),
                subtitle: subtitle(assetCount: assetIds.count, similarGroupCount: similarCount),
                assetIds: assetIds,
                previewAssetIds: Array(assetIds.prefix(4)),
                similarGroupCount: similarCount,
                sortDate: sortedAssets.first?.creationDate ?? bucket.sortDate(calendar: calendar)
            )
        }
        .sorted { lhs, rhs in
            if lhs.sortDate == rhs.sortDate {
                return lhs.title < rhs.title
            }
            return lhs.sortDate > rhs.sortDate
        }
    }

    public func placeGroups(
        from assets: [PhotoAsset],
        similarGroups: [SimilarGroup] = [],
        resolver: any PlaceLabelResolving
    ) async -> [PhotoCollectionGroup] {
        let locatedAssets = assets.filter { $0.status == .unreviewed && $0.location != nil }
        guard !locatedAssets.isEmpty else {
            return []
        }

        var buckets: [PlaceBucket: [PhotoAsset]] = [:]
        for asset in locatedAssets {
            guard let location = asset.location else {
                continue
            }
            buckets[PlaceBucket(location: location), default: []].append(asset)
        }

        var groups: [PhotoCollectionGroup] = []
        for (bucket, assets) in buckets {
            let sortedAssets = assets.sorted { $0.creationDate > $1.creationDate }
            let assetIds = sortedAssets.map(\.id)
            let location = representativeLocation(for: assets)
            let resolvedTitle = await resolvedPlaceTitle(
                for: sortedAssets,
                representativeLocation: location,
                resolver: resolver
            )
            let similarCount = matchingSimilarGroupCount(in: assetIds, similarGroups: similarGroups)
            groups.append(PhotoCollectionGroup(
                id: bucket.id,
                kind: .place,
                title: resolvedTitle ?? fallbackPlaceTitle(for: location),
                subtitle: subtitle(assetCount: assetIds.count, similarGroupCount: similarCount),
                assetIds: assetIds,
                previewAssetIds: Array(assetIds.prefix(4)),
                similarGroupCount: similarCount,
                sortDate: sortedAssets.first?.creationDate ?? Date(timeIntervalSince1970: 0),
                representativeLocation: location
            ))
        }

        return groups.sorted { lhs, rhs in
            if lhs.assetIds.count == rhs.assetIds.count {
                if lhs.sortDate == rhs.sortDate {
                    return lhs.title < rhs.title
                }
                return lhs.sortDate > rhs.sortDate
            }
            return lhs.assetIds.count > rhs.assetIds.count
        }
    }

    private func subtitle(assetCount: Int, similarGroupCount: Int) -> String {
        "\(assetCount) 张 · \(similarGroupCount) 组相似"
    }

    private func matchingSimilarGroupCount(
        in assetIds: [PhotoAsset.ID],
        similarGroups: [SimilarGroup]
    ) -> Int {
        let ids = Set(assetIds)
        return similarGroups.filter { group in
            group.status == .unreviewed && group.assetIds.filter { ids.contains($0) }.count >= 2
        }.count
    }

    private func representativeLocation(for assets: [PhotoAsset]) -> PhotoAsset.Location {
        let locations = assets.compactMap(\.location)
        let latitude = locations.map(\.latitude).reduce(0, +) / Double(locations.count)
        let longitude = locations.map(\.longitude).reduce(0, +) / Double(locations.count)
        return PhotoAsset.Location(latitude: latitude, longitude: longitude)
    }

    private func resolvedPlaceTitle(
        for assets: [PhotoAsset],
        representativeLocation: PhotoAsset.Location,
        resolver: any PlaceLabelResolving
    ) async -> String? {
        for location in placeLabelCandidateLocations(for: assets, representativeLocation: representativeLocation) {
            if let label = await resolver.label(for: location) {
                return label
            }
        }

        return nil
    }

    private func placeLabelCandidateLocations(
        for assets: [PhotoAsset],
        representativeLocation: PhotoAsset.Location
    ) -> [PhotoAsset.Location] {
        var seenKeys = Set<String>()
        var locations: [PhotoAsset.Location] = []

        func appendIfNeeded(_ location: PhotoAsset.Location) {
            let key = String(format: "%.4f,%.4f", location.latitude, location.longitude)
            guard !seenKeys.contains(key) else {
                return
            }
            seenKeys.insert(key)
            locations.append(location)
        }

        for location in assets.compactMap(\.location) {
            appendIfNeeded(location)
        }
        appendIfNeeded(representativeLocation)

        return locations
    }

    private func fallbackPlaceTitle(for location: PhotoAsset.Location) -> String {
        if let region = localRegionTitle(for: location) {
            return region
        }

        return "附近地点"
    }

    private func localRegionTitle(for location: PhotoAsset.Location) -> String? {
        let latitude = location.latitude
        let longitude = location.longitude

        if (37.7...38.4).contains(latitude),
           (-123.2 ... -122.3).contains(longitude) {
            return "加州 · 马林县"
        }

        guard (63.0...67.0).contains(latitude),
              (-25.0 ... -13.0).contains(longitude) else {
            return nil
        }

        if latitude < 64.35 {
            return "冰岛南部"
        }

        if longitude > -16.7 {
            return "冰岛东部"
        }

        if latitude > 65.2 {
            return "冰岛北部"
        }

        if longitude < -21.0 {
            return "冰岛西部"
        }

        return "冰岛"
    }

    private func timeBucket(for date: Date, now: Date, calendar: Calendar) -> TimeBucket {
        if calendar.isDate(date, inSameDayAs: now) {
            return .today(calendar.startOfDay(for: date))
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return .yesterday(calendar.startOfDay(for: date))
        }

        let dateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let nowComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        if dateComponents.yearForWeekOfYear == nowComponents.yearForWeekOfYear,
           dateComponents.weekOfYear == nowComponents.weekOfYear,
           date < calendar.startOfDay(for: now) {
            return .thisWeek(startOfWeek(for: date, calendar: calendar))
        }

        if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now),
           calendar.component(.year, from: date) == calendar.component(.year, from: lastMonth),
           calendar.component(.month, from: date) == calendar.component(.month, from: lastMonth) {
            return .lastMonth(startOfMonth(for: date, calendar: calendar))
        }

        return .monthArchive(startOfMonth(for: date, calendar: calendar))
    }

    private func startOfWeek(for date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    private func startOfMonth(for date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }
}

private enum TimeBucket: Hashable {
    case today(Date)
    case yesterday(Date)
    case thisWeek(Date)
    case lastMonth(Date)
    case monthArchive(Date)

    static func == (lhs: TimeBucket, rhs: TimeBucket) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var id: String {
        switch self {
        case .today(let date):
            return "time:today:\(Self.dayKey(for: date))"
        case .yesterday(let date):
            return "time:yesterday:\(Self.dayKey(for: date))"
        case .thisWeek(let date):
            return "time:week:\(Self.weekKey(for: date))"
        case .lastMonth(let date):
            return "time:last-month:\(Self.monthKey(for: date))"
        case .monthArchive(let date):
            return "time:month:\(Self.monthKey(for: date))"
        }
    }

    func title(calendar: Calendar) -> String {
        switch self {
        case .today(let date):
            return "今天 · \(Self.weekdayText(for: date, calendar: calendar))"
        case .yesterday(let date):
            return "昨天 · \(Self.weekdayText(for: date, calendar: calendar))"
        case .thisWeek:
            return "本周早些"
        case .lastMonth(let date):
            return "上个月 · \(Self.monthText(for: date, calendar: calendar))"
        case .monthArchive(let date):
            return "\(calendar.component(.year, from: date))年\(calendar.component(.month, from: date))月"
        }
    }

    func sortDate(calendar: Calendar) -> Date {
        switch self {
        case .today(let date), .yesterday(let date), .thisWeek(let date), .lastMonth(let date), .monthArchive(let date):
            return date
        }
    }

    private static func dayKey(for date: Date) -> String {
        keyFormatter(format: "yyyy-MM-dd").string(from: date)
    }

    private static func weekKey(for date: Date) -> String {
        keyFormatter(format: "YYYY-'W'ww").string(from: date)
    }

    private static func monthKey(for date: Date) -> String {
        keyFormatter(format: "yyyy-MM").string(from: date)
    }

    private static func keyFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }

    private static func weekdayText(for date: Date, calendar: Calendar) -> String {
        let symbols = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let index = calendar.component(.weekday, from: date) - 1
        guard symbols.indices.contains(index) else {
            return "周末"
        }
        return symbols[index]
    }

    private static func monthText(for date: Date, calendar: Calendar) -> String {
        let month = calendar.component(.month, from: date)
        let symbols = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
        guard symbols.indices.contains(month - 1) else {
            return "\(month)月"
        }
        return symbols[month - 1]
    }
}

private struct PlaceBucket: Hashable {
    var latitudeKey: Int
    var longitudeKey: Int

    init(location: PhotoAsset.Location) {
        latitudeKey = Int((location.latitude / 0.02).rounded())
        longitudeKey = Int((location.longitude / 0.02).rounded())
    }

    var id: String {
        "place:\(latitudeKey):\(longitudeKey)"
    }
}
