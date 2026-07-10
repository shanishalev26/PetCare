//
//  MyExtensions.swift
//  PetCare
//
//  Created by שני שלו on 22/06/2026.
//

import Foundation

extension String {

    func parsedAsBirthDate() -> Date? {
        guard self.count == 10 else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        /* en_US_POSIX forces the formatter to treat the format string literally,
         ignoring the device language/region settings (e.g. Hebrew locale).
         Without this, DateFormatter may fail to parse a valid date string on non-English devices.*/
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.isLenient = false
        return formatter.date(from: self)
    }
}

extension Date {

    func petAgeText() -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: self, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0
        let totalMonths = years * 12 + months
        if totalMonths < 1 {
            return "Less than a month"
        } else if totalMonths < 12 {
            return "\(totalMonths) months"
        } else if months == 0 {
            return "\(years) years"
        } else {
            return "\(years).\(months) years"
        }
    }
}
