/// Copyright (c) 2024 Kodeco Inc.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

struct APIData: Encodable, Identifiable, Hashable {
  let id = UUID()
  let name: String?
  let description: String?
  let auth: String?
  let https: Bool?
  let cors: Bool?
  let url: String?
  let category: String?
  
  enum CodingKeys: String, CodingKey {
    case name = "API",
         description = "Description",
         auth = "Auth",
         https = "HTTPS",
         cors = "Cors",
         url = "Link",
         category = "Category"
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(description, forKey: .description)
    try container.encode(auth, forKey: .auth)
    try container.encode(https, forKey: .https)
    if let cors = cors {
      try container.encode(cors ? "yes" : "no", forKey: .cors)
    }
    try container.encode(url, forKey: .url)
    try container.encode(category, forKey: .category)
  }
}

extension APIData: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try? container.decode(String.self, forKey: .name)
    description = try? container.decode(String.self, forKey: .description)
    auth = try? container.decode(String.self, forKey: .auth)
    https = try? container.decode(Bool.self, forKey: .https)
    cors = try? container.decode(String.self, forKey: .cors) == "yes"
    url = try? container.decode(String.self, forKey: .url)
    category = try? container.decode(String.self, forKey: .category)
  }
}

extension APIData: Equatable {
  static func == (lhs: APIData, rhs: APIData) -> Bool {
    return lhs.name == rhs.name &&
    lhs.description == rhs.description &&
    lhs.auth == rhs.auth &&
    lhs.https == rhs.https &&
    lhs.cors == rhs.cors &&
    lhs.url == rhs.url &&
    lhs.category == rhs.category
  }
}

struct APIDataJSONContainer: Codable {
  let count: Int?
  let entries: [APIData]?
}


