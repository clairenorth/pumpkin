//
//  Animation.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 11/25/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import SwiftUI

/// Representing a purchased animation that can be used on any device.
struct Animation: Codable, Equatable, Identifiable {
  static func == (lhs: Animation, rhs: Animation) -> Bool {
    return lhs.id == rhs.id
  }

  let id: UUID
  var description = ""
}
