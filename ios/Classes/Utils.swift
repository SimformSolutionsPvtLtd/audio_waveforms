enum DurationType {
    case Current
    case Max
}

enum ThrowError: Error {
    case runtimeError(String)
}
