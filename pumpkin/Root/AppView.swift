//
//  File.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 11/6/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import UIKit

public struct AppView: View {
  let store: Store<AppState, AppAction>

  public init(store: Store<AppState, AppAction>) {
    self.store = store
  }

  @ViewBuilder public var body: some View {
    IfLetStore(self.store.scope(state: { $0.login }, action: AppAction.login)) { store in
      NavigationView {
        LoginView(store: store)
      }
      .navigationViewStyle(StackNavigationViewStyle())
    }

    IfLetStore(self.store.scope(state: { $0.home }, action: AppAction.home)) { store in
      NavigationView {
         HomeView(
           store: Store(
             initialState: HomeState(),
             reducer: homeReducer,
             environment: HomeEnvironment()
           )
         )
      }
      .navigationViewStyle(StackNavigationViewStyle())
    }
  }
}
