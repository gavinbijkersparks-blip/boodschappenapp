import SwiftUI

struct ProductEditSheet: View {
    let product: Product
    var onSave: (String, Int) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var quantity: Int

    init(product: Product, onSave: @escaping (String, Int) -> Void) {
        self.product = product
        self.onSave = onSave
        _name = State(initialValue: product.name)
        _quantity = State(initialValue: product.quantity)
    }

    var body: some View {
        Form {
            Section("Product") {
                TextField("Naam", text: $name)
                HStack {
                    Text("Aantal")
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            quantity = max(1, quantity - 1)
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 28, height: 28)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Text("\(quantity)")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(minWidth: 32)

                        Button {
                            quantity = min(99, quantity + 1)
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 28, height: 28)
                                .background(Theme.accent.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Bewerk product")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuleer") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Bewaar") {
                    onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), quantity)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
