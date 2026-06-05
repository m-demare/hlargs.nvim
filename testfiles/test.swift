struct Binding<T> {}

enum Forms {
    struct Field {}
}

final class App {
    init(presentRegistration: Binding<Bool>, fields: [Forms.Field], onComplete: @escaping () -> Void) {
        _ = presentRegistration
        _ = fields
        onComplete()
    }

    func createRequest(endpoint: String, subpath: String? = nil, method: String? = nil) -> String? {
        let path = subpath ?? ""
        let verb = method ?? "GET"
        return endpoint + path + verb
    }

    func update(_ value: Int, with newValue: Int) -> Int {
        return value + newValue
    }

    func map(_ values: [Int], using transform: (Int) -> Int) -> [Int] {
        return values.map { item in
            transform(item)
        }
    }
}

func topLevel(label: String) -> String {
    return label
}
