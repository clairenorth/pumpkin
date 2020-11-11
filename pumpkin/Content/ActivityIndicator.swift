//
//  ActivityIndicator.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 11/10/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct UIViewRepresented<UIViewType>: UIViewRepresentable where UIViewType: UIView {
  let makeUIView: (Context) -> UIViewType
  let updateUIView: (UIViewType, Context) -> Void = { _, _ in }

  func makeUIView(context: Context) -> UIViewType {
    self.makeUIView(context)
  }

  func updateUIView(_ uiView: UIViewType, context: Context) {
    self.updateUIView(uiView, context)
  }
}

struct ActivityIndicator: View {
  var body: some View {
    UIViewRepresented(makeUIView: { _ in
      let view = UIActivityIndicatorView()
      view.startAnimating()
      return view
    })
  }
}
