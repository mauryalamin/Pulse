//
//  InsightsComputationService.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

protocol InsightsComputing {
    func makeSnapshot(from moments: [Moment], for period: InsightsPeriod, now: Date) -> InsightsSnapshot
}

struct InsightsComputationService: InsightsComputing {
    // Sparse-data thresholds.
    // We keep these conservative so Insights can appear early while still suppressing noisy claims.
    private let minimumMomentsForReadyState = 4
    private let minimumMomentsForComparisons = 3
    private let minimumContextMoments = 3

    func makeSnapshot(from moments: [Moment], for period: InsightsPeriod, now: Date = .now) -> InsightsSnapshot {
        let periodMoments = filterMoments(moments, for: period)
        let comparisonMoments = makeComparisonMoments(from: moments, for: period)
        let dataState = determineDataState(from: periodMoments)

        let timePattern = makeTimePattern(from: periodMoments)
        let topTags = makeTopTags(from: periodMoments)
        let urgeBreakdown = makeUrgeBreakdown(from: periodMoments)

        let factoids = makeFactoids(
            from: periodMoments,
            comparisonMoments: comparisonMoments,
            timePattern: timePattern,
            topTags: topTags
        )

        let observations = makeObservations(
            from: periodMoments,
            timePattern: timePattern,
            topTags: topTags,
            generatedAt: now
        )

        let summary = makeSummary(
            from: periodMoments,
            period: period,
            dataState: dataState,
            timePattern: timePattern,
            urgeBreakdown: urgeBreakdown,
            generatedAt: now
        )

        return InsightsSnapshot(
            period: period,
            summary: summary,
            factoids: factoids,
            activitySeries: makeActivitySeries(from: periodMoments, period: period),
            timePattern: timePattern,
            observations: observations,
            topTags: topTags,
            urgeBreakdown: urgeBreakdown,
            dataState: dataState,
            lastRefreshedAt: now
        )
    }

    private func filterMoments(_ moments: [Moment], for period: InsightsPeriod) -> [Moment] {
        moments
            .filter { moment in
                moment.timestamp >= period.startDate && moment.timestamp <= period.endDate
            }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private func makeComparisonMoments(from allMoments: [Moment], for period: InsightsPeriod) -> [Moment] {
        let interval = period.endDate.timeIntervalSince(period.startDate)
        guard interval > 0 else { return [] }

        let previousEnd = period.startDate
        let previousStart = previousEnd.addingTimeInterval(-interval)

        return allMoments
            .filter { $0.timestamp >= previousStart && $0.timestamp < previousEnd }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private func determineDataState(from moments: [Moment]) -> InsightsDataState {
        if moments.isEmpty {
            return .empty
        }

        if moments.count < minimumMomentsForReadyState {
            return .insufficientData
        }

        return .ready
    }

    private func makeFactoids(
        from moments: [Moment],
        comparisonMoments: [Moment],
        timePattern: TimePatternSummary?,
        topTags: [TagInsight]
    ) -> [InsightFactoid] {
        let total = moments.count
        let stayedPresentCount = moments.filter { !$0.gaveIn }.count
        let stayedPresentRate = total > 0 ? Double(stayedPresentCount) / Double(total) : 0

        let averageIntensity = total > 0
            ? Double(moments.reduce(0) { $0 + $1.intensity }) / Double(total)
            : 0

        let mostCommonUrge = makeTopNameCount(from: moments.map { normalizedName($0.urge.name) })
        let mostActiveDay = makeMostActiveWeekday(from: moments)
        let commonLocationType = makeMostCommonLocationType(from: moments)
        let highestIntensityPeriod = makeHighestIntensityTimeBucket(from: moments)

        let previousCount = comparisonMoments.count
        let hasEligibleComparison = previousCount >= minimumMomentsForComparisons
        let changeFraction = previousCount > 0
            ? (Double(total - previousCount) / Double(previousCount))
            : nil

        return [
            InsightFactoid(
                kind: .momentsLogged,
                title: "Moments Logged",
                valueText: "\(total)",
                subtitle: nil,
                priority: 1,
                isEligible: total > 0
            ),
            InsightFactoid(
                kind: .stayedPresentRate,
                title: "Stayed Present Rate",
                valueText: percentText(stayedPresentRate),
                subtitle: nil,
                priority: 2,
                isEligible: total > 0
            ),
            InsightFactoid(
                kind: .stayedPresentCount,
                title: "Stayed Present",
                valueText: "\(stayedPresentCount)",
                subtitle: "out of \(total) moments",
                priority: 3,
                isEligible: total > 0
            ),
            InsightFactoid(
                kind: .averageIntensity,
                title: "Average Intensity",
                valueText: total > 0 ? String(format: "%.1f/5", averageIntensity) : "—",
                subtitle: nil,
                priority: 4,
                isEligible: total > 0
            ),
            InsightFactoid(
                kind: .mostCommonTimeWindow,
                title: "Most Common Time",
                valueText: timePattern?.primaryBucket?.label ?? "—",
                subtitle: nil,
                priority: 5,
                isEligible: (timePattern?.primaryBucket?.count ?? 0) > 0
            ),
            InsightFactoid(
                kind: .mostCommonUrge,
                title: "Most Common Urge",
                valueText: mostCommonUrge?.name ?? "—",
                subtitle: mostCommonUrge.map { "\($0.count) moments" },
                priority: 6,
                isEligible: mostCommonUrge != nil
            ),
            InsightFactoid(
                kind: .topTag,
                title: "Top Tag",
                valueText: topTags.first?.name ?? "—",
                subtitle: topTags.first.map { "\($0.count) uses" },
                priority: 7,
                isEligible: !topTags.isEmpty
            ),
            InsightFactoid(
                kind: .changeVsLastWeek,
                title: "Change vs Previous Period",
                valueText: hasEligibleComparison ? (changeFraction.map(signedPercentText(_:)) ?? "—") : "—",
                subtitle: hasEligibleComparison ? "vs \(previousCount) moments" : nil,
                priority: 8,
                isEligible: hasEligibleComparison
            ),
            InsightFactoid(
                kind: .mostActiveDay,
                title: "Most Active Day",
                valueText: mostActiveDay?.dayName ?? "—",
                subtitle: mostActiveDay.map { "\($0.count) moments" },
                priority: 9,
                isEligible: mostActiveDay != nil
            ),
            InsightFactoid(
                kind: .commonLocationType,
                title: "Common Location Type",
                valueText: commonLocationType?.typeName ?? "—",
                subtitle: commonLocationType.map { "\($0.count) moments" },
                priority: 10,
                isEligible: commonLocationType != nil
            ),
            InsightFactoid(
                kind: .highestIntensityPeriod,
                title: "Highest Intensity Period",
                valueText: highestIntensityPeriod?.label ?? "—",
                subtitle: highestIntensityPeriod.map { String(format: "Avg %.1f/5", $0.average) },
                priority: 11,
                isEligible: highestIntensityPeriod != nil
            )
        ]
    }

    private func makeActivitySeries(from moments: [Moment], period: InsightsPeriod) -> [ActivityDataPoint] {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: period.startDate)
        let endDay = calendar.startOfDay(for: period.endDate)

        guard startDay <= endDay else { return [] }

        let countsByDay = Dictionary(grouping: moments) { calendar.startOfDay(for: $0.timestamp) }
            .mapValues(\.count)

        let dayCount = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        let useCompactDate = dayCount > 14
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = useCompactDate ? "M/d" : "E"

        var result: [ActivityDataPoint] = []
        var cursor = startDay

        while cursor <= endDay {
            result.append(
                ActivityDataPoint(
                    date: cursor,
                    label: formatter.string(from: cursor),
                    count: countsByDay[cursor, default: 0]
                )
            )
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return result
    }

    private func makeTimePattern(from moments: [Moment]) -> TimePatternSummary? {
        guard !moments.isEmpty else { return nil }

        var counts: [TimeBucket: Int] = [:]
        TimeBucket.allCases.forEach { counts[$0] = 0 }

        for moment in moments {
            let bucket = timeBucket(for: moment.timestamp)
            counts[bucket, default: 0] += 1
        }

        let total = Double(moments.count)
        let bucketInsights = TimeBucket.allCases.map { bucket in
            let count = counts[bucket, default: 0]
            return TimeBucketInsight(
                bucket: bucket,
                label: displayLabel(for: bucket),
                count: count,
                percentage: total > 0 ? Double(count) / total : 0
            )
        }

        let primary = bucketInsights
            .filter { $0.count > 0 }
            .max { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.bucket.rawValue > rhs.bucket.rawValue
                }
                return lhs.count < rhs.count
            }

        return TimePatternSummary(buckets: bucketInsights, primaryBucket: primary)
    }

    private func makeTopTags(from moments: [Moment]) -> [TagInsight] {
        let nameCount = moments
            .flatMap { $0.tags ?? [] }
            .map { normalizedName($0.name) }
            .reduce(into: [String: Int]()) { partial, name in
                guard !name.isEmpty else { return }
                partial[name, default: 0] += 1
            }

        return nameCount
            .map { TagInsight(name: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.name < rhs.name
                }
                return lhs.count > rhs.count
            }
            .prefix(5)
            .map { $0 }
    }

    private func makeUrgeBreakdown(from moments: [Moment]) -> [UrgeBreakdownItem] {
        guard !moments.isEmpty else { return [] }

        let total = Double(moments.count)
        let counts = moments
            .map { normalizedName($0.urge.name) }
            .reduce(into: [String: Int]()) { partial, name in
                guard !name.isEmpty else { return }
                partial[name, default: 0] += 1
            }

        return counts
            .map {
                UrgeBreakdownItem(
                    urgeName: $0.key,
                    count: $0.value,
                    percentage: Double($0.value) / total
                )
            }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.urgeName < rhs.urgeName
                }
                return lhs.count > rhs.count
            }
    }

    private func makeObservations(
        from moments: [Moment],
        timePattern: TimePatternSummary?,
        topTags: [TagInsight],
        generatedAt: Date
    ) -> [InsightObservation] {
        guard !moments.isEmpty else { return [] }

        var observations: [InsightObservation] = []

        if let primaryBucket = timePattern?.primaryBucket,
           primaryBucket.count >= minimumContextMoments,
           let topTag = topTags.first {
            observations.append(
                InsightObservation(
                    title: "Time + Tag Pattern",
                    body: "Most moments were in the \(primaryBucket.label.lowercased()) window, and \"\(topTag.name)\" was your most-used tag.",
                    source: .template,
                    signalKinds: [.timeOfDay, .tag],
                    priority: 1,
                    generatedAt: generatedAt
                )
            )
        }

        if let urgeTrend = makeTopUrgeWithIntensity(from: moments) {
            observations.append(
                InsightObservation(
                    title: "Urge + Intensity",
                    body: "\(urgeTrend.urgeName) appeared most often with an average intensity of \(String(format: "%.1f", urgeTrend.averageIntensity))/5.",
                    source: .template,
                    signalKinds: [.urgeType, .intensity],
                    priority: 2,
                    generatedAt: generatedAt
                )
            )
        }

        if let weekendComparison = makeWeekdayWeekendResponsePattern(from: moments) {
            observations.append(
                InsightObservation(
                    title: "Weekday vs Weekend Response",
                    body: "Stayed Present rate was \(percentText(weekendComparison.weekdayRate)) on weekdays and \(percentText(weekendComparison.weekendRate)) on weekends.",
                    source: .template,
                    signalKinds: [.weekdayWeekend, .responsePattern],
                    priority: 3,
                    generatedAt: generatedAt
                )
            )
        }

        if let locationPattern = makeLocationResponsePattern(from: moments) {
            observations.append(
                InsightObservation(
                    title: "Location + Response",
                    body: "In \(locationPattern.locationType.lowercased()) settings, your Stayed Present rate was \(percentText(locationPattern.stayedPresentRate)).",
                    source: .template,
                    signalKinds: [.location, .responsePattern],
                    priority: 4,
                    generatedAt: generatedAt
                )
            )
        }

        if let weatherTagPattern = makeWeatherTagPattern(from: moments) {
            observations.append(
                InsightObservation(
                    title: "Weather + Tag",
                    body: "\"\(weatherTagPattern.tag)\" appeared most often during \(weatherTagPattern.weatherDescription.lowercased()) conditions.",
                    source: .template,
                    signalKinds: [.weather, .tag],
                    priority: 5,
                    generatedAt: generatedAt
                )
            )
        }

        return observations
            .sorted { $0.priority < $1.priority }
            .prefix(4)
            .map { $0 }
    }

    private func makeSummary(
        from moments: [Moment],
        period: InsightsPeriod,
        dataState: InsightsDataState,
        timePattern: TimePatternSummary?,
        urgeBreakdown: [UrgeBreakdownItem],
        generatedAt: Date
    ) -> InsightsSummary {
        let title = "\(period.label) Summary"

        switch dataState {
        case .empty:
            return InsightsSummary(
                title: title,
                body: "No moments were logged in this period yet.",
                source: .template,
                generatedAt: generatedAt
            )

        case .insufficientData:
            let count = moments.count
            return InsightsSummary(
                title: title,
                body: "\(count) moments were logged in this period. Log a few more moments to unlock stronger trend signals.",
                source: .template,
                generatedAt: generatedAt
            )

        case .ready:
            let stayedPresentCount = moments.filter { !$0.gaveIn }.count
            let stayedPresentRate = Double(stayedPresentCount) / Double(max(moments.count, 1))
            let topUrge = urgeBreakdown.first?.urgeName.lowercased() ?? "urges"
            let timeLabel = timePattern?.primaryBucket?.label.lowercased() ?? "day"

            return InsightsSummary(
                title: title,
                body: "You logged \(moments.count) moments, with a Stayed Present rate of \(percentText(stayedPresentRate)). \(topUrge.capitalized) was most common, especially in the \(timeLabel).",
                source: .template,
                generatedAt: generatedAt
            )

        case .locked:
            // Locked state is controlled by premium access elsewhere and should not be produced here.
            return InsightsSummary(
                title: title,
                body: "Insights are unavailable right now.",
                source: .template,
                generatedAt: generatedAt
            )
        }
    }
}

private extension InsightsComputationService {
    func timeBucket(for timestamp: Date) -> TimeBucket {
        let hour = Calendar.current.component(.hour, from: timestamp)
        switch hour {
        case 5..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<22:
            return .evening
        default:
            return .lateNight
        }
    }

    func displayLabel(for bucket: TimeBucket) -> String {
        switch bucket {
        case .morning:
            return "Morning"
        case .afternoon:
            return "Afternoon"
        case .evening:
            return "Evening"
        case .lateNight:
            return "Late Night"
        }
    }

    func normalizedName(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func percentText(_ fraction: Double) -> String {
        let clamped = max(0, min(1, fraction))
        return String(format: "%.0f%%", clamped * 100)
    }

    func signedPercentText(_ fraction: Double) -> String {
        let value = fraction * 100
        if value > 0 {
            return String(format: "+%.0f%%", value)
        }
        return String(format: "%.0f%%", value)
    }

    func makeTopNameCount(from names: [String]) -> (name: String, count: Int)? {
        let counts = names.reduce(into: [String: Int]()) { partial, name in
            guard !name.isEmpty else { return }
            partial[name, default: 0] += 1
        }

        return counts.max { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }
            return lhs.value < rhs.value
        }.map { (name: $0.key, count: $0.value) }
    }

    func makeMostActiveWeekday(from moments: [Moment]) -> (dayName: String, count: Int)? {
        guard !moments.isEmpty else { return nil }

        let calendar = Calendar.current
        var counts: [Int: Int] = [:]
        for moment in moments {
            let weekday = calendar.component(.weekday, from: moment.timestamp)
            counts[weekday, default: 0] += 1
        }

        guard let top = counts.max(by: { $0.value < $1.value }) else { return nil }

        let formatter = DateFormatter()
        formatter.locale = .current
        let dayName = formatter.weekdaySymbols[top.key - 1]

        return (dayName: dayName, count: top.value)
    }

    func makeMostCommonLocationType(from moments: [Moment]) -> (typeName: String, count: Int)? {
        let types = moments.compactMap { moment -> String? in
            let value = normalizedName(moment.locationDescription ?? "")
            guard !value.isEmpty else { return nil }
            return locationType(for: value)
        }

        guard types.count >= minimumContextMoments else { return nil }
        guard let top = makeTopNameCount(from: types) else { return nil }
        return (typeName: top.name, count: top.count)
    }

    func locationType(for locationDescription: String) -> String {
        let lower = locationDescription.lowercased()

        if lower.contains("home") || lower.contains("house") || lower.contains("apartment") {
            return "Home"
        }

        if lower.contains("work") || lower.contains("office") || lower.contains("job") {
            return "Work"
        }

        if lower.contains("car") || lower.contains("bus") || lower.contains("train") || lower.contains("airport") || lower.contains("hotel") {
            return "Travel"
        }

        if lower.contains("bar") || lower.contains("restaurant") || lower.contains("store") || lower.contains("gym") || lower.contains("park") || lower.contains("cafe") {
            return "Out"
        }

        return "Named Place"
    }

    func makeHighestIntensityTimeBucket(from moments: [Moment]) -> (label: String, average: Double)? {
        guard !moments.isEmpty else { return nil }

        var buckets: [TimeBucket: [Int]] = [:]
        for moment in moments {
            let bucket = timeBucket(for: moment.timestamp)
            buckets[bucket, default: []].append(moment.intensity)
        }

        let averages: [(TimeBucket, Double)] = buckets.compactMap { key, values in
            guard !values.isEmpty else { return nil }
            let avg = Double(values.reduce(0, +)) / Double(values.count)
            return (key, avg)
        }

        guard let top = averages.max(by: { lhs, rhs in
            if lhs.1 == rhs.1 {
                return lhs.0.rawValue > rhs.0.rawValue
            }
            return lhs.1 < rhs.1
        }) else {
            return nil
        }

        return (label: displayLabel(for: top.0), average: top.1)
    }

    func makeTopUrgeWithIntensity(from moments: [Moment]) -> (urgeName: String, averageIntensity: Double)? {
        guard moments.count >= minimumContextMoments else { return nil }

        let grouped = Dictionary(grouping: moments) { normalizedName($0.urge.name) }
            .filter { !$0.key.isEmpty }

        guard let topEntry = grouped.max(by: { lhs, rhs in
            if lhs.value.count == rhs.value.count {
                return lhs.key > rhs.key
            }
            return lhs.value.count < rhs.value.count
        }) else {
            return nil
        }

        let average = Double(topEntry.value.reduce(0) { $0 + $1.intensity }) / Double(topEntry.value.count)
        return (urgeName: topEntry.key, averageIntensity: average)
    }

    func makeWeekdayWeekendResponsePattern(from moments: [Moment]) -> (weekdayRate: Double, weekendRate: Double)? {
        guard moments.count >= minimumContextMoments else { return nil }

        let calendar = Calendar.current
        let weekdayMoments = moments.filter { !calendar.isDateInWeekend($0.timestamp) }
        let weekendMoments = moments.filter { calendar.isDateInWeekend($0.timestamp) }

        guard weekdayMoments.count >= 2, weekendMoments.count >= 2 else { return nil }

        let weekdayStayed = weekdayMoments.filter { !$0.gaveIn }.count
        let weekendStayed = weekendMoments.filter { !$0.gaveIn }.count

        let weekdayRate = Double(weekdayStayed) / Double(weekdayMoments.count)
        let weekendRate = Double(weekendStayed) / Double(weekendMoments.count)

        return (weekdayRate, weekendRate)
    }

    func makeLocationResponsePattern(from moments: [Moment]) -> (locationType: String, stayedPresentRate: Double)? {
        let locationMoments = moments.filter {
            let location = normalizedName($0.locationDescription ?? "")
            return !location.isEmpty
        }

        guard locationMoments.count >= minimumContextMoments else { return nil }

        let grouped = Dictionary(grouping: locationMoments) { locationType(for: normalizedName($0.locationDescription ?? "")) }

        guard let top = grouped.max(by: { $0.value.count < $1.value.count }), top.value.count >= minimumContextMoments else {
            return nil
        }

        let stayedPresent = top.value.filter { !$0.gaveIn }.count
        let rate = Double(stayedPresent) / Double(top.value.count)

        return (locationType: top.key, stayedPresentRate: rate)
    }

    func makeWeatherTagPattern(from moments: [Moment]) -> (weatherDescription: String, tag: String)? {
        let pairs: [(String, String)] = moments.flatMap { moment -> [(String, String)] in
            guard let code = moment.weatherCode,
                  let description = WeatherSnapshot.codeDescription[code],
                  let tags = moment.tags,
                  !tags.isEmpty else {
                return []
            }

            return tags.compactMap { tag in
                let tagName = normalizedName(tag.name)
                guard !tagName.isEmpty else { return nil }
                return (description, tagName)
            }
        }

        guard pairs.count >= minimumContextMoments else { return nil }

        let pairCounts = pairs.reduce(into: [String: Int]()) { partial, pair in
            let key = "\(pair.0)||\(pair.1)"
            partial[key, default: 0] += 1
        }

        guard let top = pairCounts.max(by: { $0.value < $1.value }), top.value >= 2 else {
            return nil
        }

        let components = top.key.components(separatedBy: "||")
        guard components.count == 2 else { return nil }

        return (weatherDescription: components[0], tag: components[1])
    }
}
