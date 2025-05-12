//
//  KeyboardResponder.swift
//  Pulse
//
//  Created by Maury Alamin on 5/12/25.
//

import Foundation
import Combine
import SwiftUI

final class KeyboardResponder: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0

    private var cancellableSet: Set<AnyCancellable> = []

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .sink { notification in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    self.keyboardHeight = 0
                    return
                }
                self.keyboardHeight = notification.name == UIResponder.keyboardWillHideNotification ? 0 : frame.height
            }
            .store(in: &cancellableSet)
    }
}
