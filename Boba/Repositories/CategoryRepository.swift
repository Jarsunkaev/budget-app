import Foundation
import SwiftData

/// Data access layer for Category operations.
@Observable
final class CategoryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    func create(
        name: String,
        icon: String,
        colorHex: String = "d1603d",
        type: CategoryType = .want,
        isDefault: Bool = false
    ) -> Category {
        let category = Category(
            name: name,
            icon: icon,
            colorHex: colorHex,
            type: type,
            sortOrder: fetchAll().count,
            isDefault: isDefault
        )
        modelContext.insert(category)
        try? modelContext.save()
        return category
    }

    func delete(_ category: Category) {
        modelContext.delete(category)
        try? modelContext.save()
    }

    func save() {
        try? modelContext.save()
    }

    // MARK: - Queries

    func fetchAll() -> [Category] {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchByType(_ type: CategoryType) -> [Category] {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? modelContext.fetch(descriptor))?.filter { $0.type == type } ?? []
    }

    // MARK: - Seeding

    /// Seed default categories if none exist. Called during onboarding.
    func seedDefaults() {
        guard fetchAll().isEmpty else { return }

        for (index, def) in Category.defaults.enumerated() {
            let category = Category(
                name: def.name,
                icon: def.icon,
                colorHex: def.color,
                type: def.type,
                sortOrder: index,
                isDefault: true
            )
            modelContext.insert(category)
        }
        try? modelContext.save()
    }
}
