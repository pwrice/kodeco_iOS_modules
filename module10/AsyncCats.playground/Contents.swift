import SwiftUI

struct CatFact: Codable {
  let fact: String
  let length: Int
}


struct CatFactSequence: AsyncSequence {
  typealias AsyncIterator = CatFactIterator
  typealias Element = CatFact

  let numFacts: Int
  
  func makeAsyncIterator() -> CatFactIterator {
    return CatFactIterator(numFacts: numFacts)
  }
}

struct CatFactIterator: AsyncIteratorProtocol {
  typealias Element = CatFact
  
  var factCount: Int = 0
  let numFacts: Int

  mutating func next() async throws -> CatFact? {
    guard let url = URL(string: "https://catfact.ninja/fact"),
            factCount < numFacts
    else { return nil }
    
    factCount += 1
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(CatFact.self, from: data)
  }
}

func fetchCatFacts(numFacts: Int) async throws {
  print("Fetching Cats")
  for try await catFact in CatFactSequence(numFacts: numFacts) {
    print(catFact)
  }
  print("Done")
}


Task {
  try await fetchCatFacts(numFacts: 3)
}

