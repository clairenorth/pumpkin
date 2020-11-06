//
//  LandingView.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 10/31/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import Foundation
import ComposableArchitecture
import SwiftUI

private let welcomeCopy = """
  Welcome! Login or register a new pumpkin.
  """

enum LandingChoice: Identifiable {
  case login
  case register
  var id: Self { self }
}

struct LandingView: View {
  let store = Store(
    initialState: AppState(),
    reducer: appReducer.debug(),
    environment: AppEnvironment(
      authenticationClient: .live,
      mainQueue: DispatchQueue.main.eraseToAnyScheduler()
    )
  )

  @State var landingChoice: LandingChoice?

  var body: some View {
    NavigationView {
      Form {
        Section(
          header: Text(welcomeCopy).padding([.bottom], 16)
        ) {
          Button("Login") { self.landingChoice = .login }
          Button("Register") { self.landingChoice = .register }
        }
      }
//      .sheet(item: self.$landingChoice) { choice in
//        if choice == .login {
//          IfLetStore(self.store.scope(state: { $0.login }, action: AppAction.login)) { store in
//            NavigationView {
//              LoginView(store: store)
//            }
//            .navigationViewStyle(StackNavigationViewStyle())
//          }
//        } else {
//          IfLetStore(self.store.scope(state: { $0.register }, action: AppAction.register)) { store in
//            NavigationView {
//              RegisterView(store: store)
//            }
//            .navigationViewStyle(StackNavigationViewStyle())
//          }
//        }
//      }
      .navigationBarTitle("Jabberin Jack")
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
}
