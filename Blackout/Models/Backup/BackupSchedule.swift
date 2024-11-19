import Foundation

public struct ScheduleSettings: Codable {
    var monday: Bool = false
    var tuesday: Bool = false
    var wednesday: Bool = false
    var thursday: Bool = false
    var friday: Bool = false
    var saturday: Bool = false
    var sunday: Bool = false
    
    public init() {}
    
    var selectedDays: [Int] {
        var days: [Int] = []
        if monday { days.append(2) }
        if tuesday { days.append(3) }
        if wednesday { days.append(4) }
        if thursday { days.append(5) }
        if friday { days.append(6) }
        if saturday { days.append(7) }
        if sunday { days.append(1) }
        return days
    }
} 