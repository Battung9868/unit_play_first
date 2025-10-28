//
//
//

import Foundation

extension Array where Element: Equatable {
    
    func removingDuplicates() -> [Element] {
        var result: [Element] = []
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}

extension Array where Element: Numeric {
    
    func sum() -> Element {
        return reduce(0, +)
    }
    
    func average() -> Double where Element: BinaryInteger {
        guard !isEmpty else { return 0 }
        return Double(sum()) / Double(count)
    }
    
    func average() -> Double where Element: BinaryFloatingPoint {
        guard !isEmpty else { return 0 }
        return Double(sum()) / Double(count)
    }
}

extension Array where Element == Date {
    
    func groupedByDay() -> [Date: [Date]] {
        let calendar = Calendar.current
        var grouped: [Date: [Date]] = [:]
        
        for date in self {
            let day = calendar.startOfDay(for: date)
            grouped[day, default: []].append(date)
        }
        
        return grouped
    }
    
    func mostRecent() -> Date? {
        return self.max()
    }
    
    func oldest() -> Date? {
        return self.min()
    }
}

