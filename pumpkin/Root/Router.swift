//
//  Router.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 10/31/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct RouterView: View {

  let store: Store<AppState, AppAction>
  var body: some View {
    WithViewStore(store) { viewStore in
      self.view(for: viewStore.route)
    }
  }

  func view(for route: Route) -> AnyView {
    switch route {
    case .home:
      return WithViewStore(self.store) { viewStore in
        HomeView(store: self.store)
      }.erase()
    case .loggedOut:
      return LandingView().erase()
    }
  }
}

extension SwiftUI.View {
  func erase() -> AnyView {
    return AnyView(self)
  }
}
