//
//  Stem.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import SwiftUI

struct Stem: Identifiable {
  let id = UUID()
  var points: [CGPoint]
  var leaves: [Leaf]
  var creationTime: TimeInterval = Date().timeIntervalSince1970
  var thickness: CGFloat = 2.0

  struct Leaf: Identifiable {
    let id = UUID()
    var position: CGPoint
    var angle: Double
    var size: CGFloat
    var side: Side  // Left or Right

    enum Side {
      case left, right
    }
  }
}
