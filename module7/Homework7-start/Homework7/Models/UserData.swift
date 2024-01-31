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

struct UserData: Codable, Equatable {
  let name: Name?
  let gender: String
  let location: Location
  let email: String
  let login: Login
  let dob: DOB
  let registered: Registered
  let phone: String
  let cell: String
  let id: ID
  let picture: Picture
  let nat: String
  
  struct Name: Codable, Equatable {
    let title: String
    let first: String
    let last: String
    
    var fullName: String {
      get {
        title + " " + first + " " + last
      }
    }
  }
  
  struct Location: Codable, Equatable {
    let street: Street?
    let city: String?
    let state: String?
    let country: String?
    let postcode: String?
    let coordinates: LatLng?
    let timezone: Timezone?
    
    enum CodingKeys: String, CodingKey {
      case street, city, state, country, postcode, coordinates, timezone
    }
    
    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      
      street = try? container.decode(Street.self, forKey: .street)
      city = try? container.decode(String.self, forKey: .city)
      state = try? container.decode(String.self, forKey: .state)
      country = try? container.decode(String.self, forKey: .country)
      
      do {
        postcode = try container.decode(String.self, forKey: .postcode)
      } catch {
        do {
          let postcodeInt = try container.decode(Int.self, forKey: .postcode)
          postcode = String(postcodeInt)
        } catch {
          postcode = nil
        }
      }
      
      coordinates = try? container.decode(LatLng.self, forKey: .coordinates)
      timezone = try? container.decode(Timezone.self, forKey: .timezone)
    }
        
    struct Street: Codable, Equatable {
      let number: String?
      let name: String?
      
      var addressName: String {
        get {
          if let name = name, let number = number {
            return "\(number) \(name)"
          }
          return ""
        }
      }
      
      enum CodingKeys: String, CodingKey {
        case name, number
      }

      init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try? container.decode(String.self, forKey: .name)
        
        do {
          number = try container.decode(String.self, forKey: .number)
        } catch {
          do {
            let numberInt = try container.decode(Int.self, forKey: .number)
            number = String(numberInt)
          } catch {
              number = nil
          }
        }
      }
    }
    
    struct LatLng: Codable, Equatable {
      let latitude: String
      let longitude: String
      
      var displayName: String {
        get {
           "\(latitude) \(longitude)"
        }
      }
    }
    
    struct Timezone: Codable, Equatable {
      let offset: String
      let description: String
      
      var displayName: String {
        get {
           "\(offset) \(description)"
        }
      }

    }
  }
  
  struct Login: Codable, Equatable {
    let uuid: String
    let username: String
    let password: String
    let salt: String
    let md5: String
    let sha1: String
    let sha256: String
  }
  
  struct DOB: Codable, Equatable {
    let date: String
    let age: Int
  }
  
  struct Registered: Codable, Equatable {
    let date: String
    let age: Int
  }
  
  struct ID: Codable, Equatable {
    let name: String
    let value: String
  }
  
  struct Picture: Codable, Equatable {
    let large: String
    let medium: String
    let thumbnail: String
  }
}

struct UserDataJSONContainer: Codable, Equatable {
  let results: [UserData]?
  let info: Info?
  
  struct Info: Codable, Equatable {
    let seed: String?
    let results: Int?
    let page: Int?
    let version: String?

    init() {
      seed = ""
      results = 0
      page = 0
      version = ""
    }
  }  
}



/*
 "gender": "female",
 "name": {
     "title": "Mademoiselle",
     "first": "Paulina",
     "last": "Bonnet"
 },
 "location": {
     "street": {
         "number": 2201,
         "name": "Rue Bataille"
     },
     "city": "Thun",
     "state": "Zürich",
     "country": "Switzerland",
     "postcode": 2026,
     "coordinates": {
         "latitude": "-63.2827",
         "longitude": "92.1061"
     },
     "timezone": {
         "offset": "-3:00",
         "description": "Brazil, Buenos Aires, Georgetown"
     }
 },
 "email": "paulina.bonnet@example.com",
 "login": {
     "uuid": "c1c536df-fe86-4355-b8e2-f3e8d719cbfb",
     "username": "blackzebra293",
     "password": "tennesse",
     "salt": "6Gxmxt0F",
     "md5": "c5ec028f9f16902c0470f1ea0995f402",
     "sha1": "d67d46d98758c6623bb7e83a0257fdfd525352a8",
     "sha256": "f6d3778de7359a0fff513da0c6b91d26860e91dd66a2f405404200eddca365be"
 },
 "dob": {
     "date": "1995-12-26T15:28:55.724Z",
     "age": 27
 },
 "registered": {
     "date": "2012-07-11T09:08:49.195Z",
     "age": 11
 },
 "phone": "077 779 71 62",
 "cell": "079 391 44 10",
 "id": {
     "name": "AVS",
     "value": "756.5304.8739.26"
 },
 "picture": {
     "large": "https://randomuser.me/api/portraits/women/81.jpg",
     "medium": "https://randomuser.me/api/portraits/med/women/81.jpg",
     "thumbnail": "https://randomuser.me/api/portraits/thumb/women/81.jpg"
 },
 "nat": "CH"
}
 */
