import Foundation

public struct CodeChallengeTestCases<Input: Hashable, Output> {
    public var title: String
    public var expected: [Input: [Output]]
    public var solution: (Input) -> Output

    public init(
        title: String? = nil,
        expected: KeyValuePairs<Input, Output> = [:],
        solution: @escaping (Input) -> Output
    ) {
        self.title = title ?? "\(Input.self) -> \(Output.self)"
        self.expected = [:]
        for (i, o) in expected {
            self.expected[i, default: []].append(o)
        }
        self.solution = solution
    }

    public mutating func append(_ input: Input, expecting output: Output) {
        self.expected[input, default: []].append(output)
    }

    public mutating func append(_ pairs: KeyValuePairs<Input, Output>) {
        for (i, o) in pairs {
            self.expected[i, default: []].append(o)
        }
    }
}

extension CodeChallengeTestCases {
    public var isEmpty: Bool { expected.isEmpty }

    @discardableResult
    public func evaluate(
        _ outputEqualsExpected: (Output, Output) -> Bool,
        evaluationCount: Int = 1
    ) -> CodeChallengeEvaluation<Input, Output> {
        CodeChallengeEvaluation(
            title: title,
            results: expected.map { (input, possibleOutputs) in
                let start = CFAbsoluteTimeGetCurrent()
                let actualOutput = solution(input)
                let timeAllotted = CFAbsoluteTimeGetCurrent() - start

                let success = possibleOutputs.reduce(false) { didSucceed, expectedOutput in
                    outputEqualsExpected(actualOutput, expectedOutput) || didSucceed
                }
                if success {
                    return .success(
                        CodeChallengeSuccess(
                            input: input,
                            output: actualOutput,
                            time: timeAllotted))
                } else {
                    return .failure(
                        CodeChallengeFailure(
                            input: input,
                            expected: possibleOutputs,
                            actual: actualOutput,
                            time: timeAllotted))
                }
            }
        )
    }

    public func printFailures(evaluating outputEqualsExpected: (Output, Output) -> Bool) {
        let failures = evaluate(outputEqualsExpected).failures

        if failures.isEmpty {
            print("All tests passed for '\(title)'!\n")
            return
        }

        print("Tests failed for '\(title)':")
        for f in failures {
            f.print()
        }
        print("\n----------------\n")
    }
}

public extension CodeChallengeTestCases where Output: Equatable {
    func evaluate() -> CodeChallengeEvaluation<Input, Output> {
        evaluate { $0 == $1 }
    }

    func printFailures() {
        printFailures(evaluating: { $0 == $1 })
    }
}

// MARK: - Results

public struct CodeChallengeSuccess<Input, Output> {
    public let input: Input
    public let output: Output
    public let time: Double

    public func print() {
        Swift.print("Input:        \t\(input)\n"
                        +  "Output:       \t\(output)\n"
                        +  "Time to solve:\t\(time)"
        )
    }
}

public struct CodeChallengeFailure<Input, Output>: Error {
    public let input: Input
    public let expected: [Output]
    public let actual: Output
    public let time: Double

    public func print() {
        Swift.print("Input:        \t\(input)\n"
                        +  "Expected:     \t\(expected)\n"
                        +  "Actual output:\t\(actual)\n"
                        +  "Time to solve:\t\(time)"
        )
    }
}

public typealias CodeChallengeResult<I, O> = Result<CodeChallengeSuccess<I, O>, CodeChallengeFailure<I, O>>

public struct CodeChallengeEvaluation<I, O> {
    public let title: String
    public let results: [CodeChallengeResult<I, O>]

    public var allSuccess: Bool {
        for result in results {
            if case .failure = result {
                return false
            }
        }
        return true
    }

    public var failures: [CodeChallengeFailure<I, O>] {
        results.compactMap {
            if case .failure(let fail) = $0 {
                return fail
            } else { return nil }
        }
    }

    public var successes: [CodeChallengeSuccess<I, O>] {
        results.compactMap {
            if case .success(let success) = $0 {
                return success
            } else { return nil }
        }
    }

    public var totalTime: Double {
        results.lazy
            .map { $0.time() }
            .reduce(0, +)
    }

    public func printSuccesses() {
        let scs = successes
        if scs.isEmpty {
            return Swift.print("All tests failed for '\(title)'.\n")
        }
        Swift.print("Tests suceeeded for '\(title)':")
        for s in scs { s.print() }
        Swift.print("\n----------------\n")
    }

    public func printFailures() {
        if allSuccess {
            return Swift.print("All tests passed for '\(title)'!\n")
        }

        Swift.print("Tests failed for '\(title)':")
        for f in failures { f.print() }
        Swift.print("\n----------------\n")
    }

    public func print() {
        Swift.print("Test results for '\(title)':")
        for r in results {
            switch r {
            case .success(let s):
                s.print()
            case .failure(let f):
                f.print()
            }
        }
        Swift.print("\n----------------\n")
    }
}


extension Result {
    public func time<I, O>() -> Double where Success == CodeChallengeSuccess<I, O>, Failure == CodeChallengeFailure<I, O> {
        switch self {
        case .success(let success):
            return success.time
        case .failure(let failure):
            return failure.time
        }
    }
}
