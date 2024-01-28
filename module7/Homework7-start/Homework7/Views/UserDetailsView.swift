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

import SwiftUI

struct UserDetailsView: View {
  @ObservedObject var userStore = UserStore()
  @Binding var showingErrorView: Bool
  
  var body: some View {
    NavigationStack {
      VStack {
        Form {
          Section()
          {
            DataRowView(label: "Name", dataValue: userStore.userData?.name.fullName)
            DataRowView(label: "Gender", dataValue: userStore.userData?.gender)
            DataRowView(label: "DOB", dataValue: userStore.userData?.dob.date)
            DataRowView(label: "Age", intVal: userStore.userData?.dob.age)
            DataRowView(label: "Nationality", dataValue: userStore.userData?.nat)
          }

          Section(header:Text("Contact"))
          {
            DataRowView(label: "Email", dataValue: userStore.userData?.email)
            DataRowView(label: "Phone", dataValue: userStore.userData?.phone)
            DataRowView(label: "Cell", dataValue: userStore.userData?.cell)
          }

          Section(header:Text("Location"))
          {
            DataRowView(label: "Street", dataValue: userStore.userData?.location.street.addressName)
            DataRowView(label: "City", dataValue: userStore.userData?.location.city)
            DataRowView(label: "State", dataValue: userStore.userData?.location.state)
            DataRowView(label: "Post Code", intVal: userStore.userData?.location.postcode)
            DataRowView(label: "Lat / Lng", dataValue: userStore.userData?.location.coordinates.displayName)
            DataRowView(label: "Timezone", dataValue: userStore.userData?.location.timezone.displayName)
          }

          Section(header:Text("Account"))
          {
            DataRowView(label: "Username", dataValue: userStore.userData?.login.username)
            DataRowView(label: "Password", dataValue: userStore.userData?.login.password)
            DataRowView(label: "Date Registered", dataValue: userStore.userData?.registered.date)
            DataRowView(label: "Age Registered", intVal: userStore.userData?.registered.age)
          }
          
          Section(header:Text("Picture"))
          {
            DataRowView(label: "large", dataValue: userStore.userData?.picture.large)
            DataRowView(label: "medium", dataValue: userStore.userData?.picture.medium)
            DataRowView(label: "thumbnail", dataValue: userStore.userData?.picture.thumbnail)
          }
        }
      }      
      .listStyle(.plain)
      .navigationTitle(Text("User Details"))
    }
    .onAppear {
      userStore.readJSON()
    }
    .sheet(isPresented: $showingErrorView) {
      ErrorSheet(showErrorView: $showingErrorView)
    }
  }
}

struct UserDetailsView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      UserDetailsView(showingErrorView: .constant(false))
      
      UserDetailsView(showingErrorView: .constant(true))
    }
  }
}
