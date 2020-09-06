public struct CodeChallengeTestCases<Input, Output> {
    public var title: String?
    public var expected: KeyValuePairs<Input, Output>
    public var solution: (Input) -> Output

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

    func evaluate(_ outputEqualsExpected: (Output, Output) -> Bool) -> [Failure] {
        expected.compactMap { ioPair -> Failure? in
            let o = output(for: ioPair.key)
            let e = ioPair.value

            if outputEqualsExpected(o, e) {
                return nil
            } else {
                return Failure(input: ioPair.key, expectedOutput: e, actualOutput: o)
            }
        }
    }

    func printFailures(_ outputEqualsExpected: (Output, Output) -> Bool) {
        printFailures(evaluate(outputEqualsExpected))
    }

    func printFailures(_ failures: [Failure]) {
        let titleText = title ?? "\(Input.self) -> \(Output.self)"

        if failures.isEmpty {
            print("All tests passed for '\(titleText)'!\n")
            return
        }

        print("Tests failed for '\(titleText)':")
        for f in failures {
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
    func evaluate() -> [Failure] {
        evaluate { $0 == $1 }
    }

    func printFailures() {
        printFailures { $0 == $1 }
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

public extension Array {
    func print<I, O>() where Element == CodeChallengeTestCases<I, O>.Failure {
        let titleText = "\(I.self) -> \(O.self)"

        if self.isEmpty {
            Swift.print("All tests passed for '\(titleText)'!\n")
            return
        }

        Swift.print("Tests failed for '\(titleText)':")
        self.forEach { $0.print() }
        Swift.print("\n----------------\n")
    }
}

