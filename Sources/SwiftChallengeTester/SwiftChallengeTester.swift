public struct CodeChallengeTestCases<Input, Output> {
    public var title: String?
    public var expected: KeyValuePairs<Input, Output>
    public var solution: (Input) -> Output

    internal var failures: [Failure]?

    public init(
        title: String? = nil,
        expected: KeyValuePairs<Input, Output> = [:],
        solution: @escaping (Input) -> Output)
    {
        self.title = title
        self.expected = expected
        self.solution = solution
    }
}

public extension CodeChallengeTestCases {
    struct Failure {
        public let input: Input
        public let expectedOutput: Output
        public let actualOutput: Output

        public func print() {
            Swift.print("Input:        \t\(input)\n"
                            +  "Expected:     \t\(expectedOutput)\n"
                            +  "Actual output:\t\(actualOutput)"
            )
        }
    }

    var isEmpty: Bool { expected.isEmpty }

    mutating func evaluate(_ outputEqualsExpected: (Output, Output) -> Bool) -> Self {
        failures = expected.compactMap { ioPair -> Failure? in
            let o = output(for: ioPair.key)
            let e = ioPair.value

            if outputEqualsExpected(o, e) {
                return nil
            } else {
                return Failure(input: ioPair.key, expectedOutput: e, actualOutput: o)
            }
        }
        return self
    }

    func printFailures() {
        guard let evaluatedFailures = failures else {
            return print("Output must be evaluated before printing.")
        }

        let titleText = title ?? "\(Input.self) -> \(Output.self)"

        if evaluatedFailures.isEmpty {
            print("All tests passed for '\(titleText)'!\n")
            return
        }

        print("Tests failed for '\(titleText)':")
        for f in evaluatedFailures {
            printEvaluation(for: f.input,
                            expected: f.expectedOutput,
                            actual: f.actualOutput)
        }
        print("\n----------------\n")
    }

    func printEvaluations() {
        expected.forEach { ioPair in
            printEvaluation(for: ioPair.key,
                            expected: ioPair.value,
                            actual: solution(ioPair.key))
        }
    }
}

public extension CodeChallengeTestCases where Output: Equatable {
    mutating func evaluate() -> Self {
        evaluate { $0 == $1 }
    }
}

extension CodeChallengeTestCases {
    private func output(for input: Input) -> Output {
        solution(input)
    }

    private func printEvaluation(
        for input: Input,
        expected: Output,
        actual: Output)
    {
        print("Input:        \t\(input)\n"
           +  "Expected:     \t\(expected)\n"
           +  "Actual output:\t\(actual)"
        )
    }
}
