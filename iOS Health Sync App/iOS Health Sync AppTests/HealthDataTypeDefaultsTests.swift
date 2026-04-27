// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Testing
@testable import iOS_Health_Sync_App

/// Pins the invariants of the default-on / sensitive-off policy so a future
/// addition to `HealthDataType` cannot silently flip a sensitive type into
/// the default-enabled set.
@Suite("HealthDataType defaults")
struct HealthDataTypeDefaultsTests {
    @Test
    func defaultEnabledExcludesEverySensitiveType() {
        let sensitive = Set(HealthDataType.allCases.filter { $0.isSensitive })
        let intersection = HealthDataType.defaultEnabled.intersection(sensitive)
        #expect(intersection.isEmpty, "Sensitive types must be off by default. Leaked: \(intersection.map(\.rawValue).sorted())")
    }

    @Test
    func defaultEnabledContainsEveryNonSensitiveType() {
        let nonSensitive = Set(HealthDataType.allCases.filter { !$0.isSensitive })
        #expect(HealthDataType.defaultEnabled == nonSensitive,
                "defaultEnabled should equal allCases minus sensitive types")
    }

    @Test
    func defaultEnabledIsNotEmpty() {
        #expect(!HealthDataType.defaultEnabled.isEmpty)
        #expect(HealthDataType.defaultEnabled.count > 100,
                "Sanity: there should be ~150 non-sensitive types — got \(HealthDataType.defaultEnabled.count)")
    }

    @Test
    func generalPresetMatchesDefaultEnabled() {
        #expect(HealthDataType.Preset.general.types == HealthDataType.defaultEnabled,
                "The General preset must equal the default-enabled set so the user can recover the default with one tap")
    }

    @Test
    func everyTypeHasACategory() {
        // Compiler enforces this via the exhaustive switch in `category`, but
        // a runtime test guards against future `default:` regressions.
        for type in HealthDataType.allCases {
            _ = type.category  // Will fatalError if anything is missed in category().
        }
    }

    @Test
    func everyCategoryHasAtLeastOneType() {
        for category in HealthDataType.Category.allCases {
            let types = HealthDataType.allCases.filter { $0.category == category }
            #expect(!types.isEmpty, "Category \(category.displayName) has no types")
        }
    }

    @Test
    func sensitiveTypesAreInExpectedCategories() {
        // Sensitive types should only appear in reproductive, mental health,
        // lifestyle (alcohol), cardiovascular (cardiac event alerts), or
        // symptoms (mental-health-adjacent like moodChanges).
        let allowedCategories: Set<HealthDataType.Category> = [
            .reproductiveHealth, .mentalHealth, .lifestyle,
            .cardiovascular, .symptoms
        ]
        for type in HealthDataType.allCases where type.isSensitive {
            #expect(allowedCategories.contains(type.category),
                    "Sensitive type \(type.rawValue) is in unexpected category \(type.category)")
        }
    }
}
