//
//  FakeToolBar.swift
//  compilations
//
//  Created by Dmytro Ostapchenko on 10.05.2025.
//

import Foundation
import UIKit
import SwiftUI

class FakeToolBar: UIView {
    private var blurView: UIVisualEffectView!
    private let lineView = UIView()
    
    enum FakeToolBarStyle {
        enum AxisType {
            case bottom
            case top
            case both
        }
        
        case native(AxisType)
        case flyingCapsule
    }
    
    init(frame: CGRect = .zero, blurStyle: UIBlurEffect.Style = .systemMaterialDark, style: FakeToolBarStyle = .native(.bottom)) {
        super.init(frame: frame)
        let blurEffect = UIBlurEffect(style: blurStyle)
        self.blurView = UIVisualEffectView(effect: blurEffect)
        addSubview(blurView)
        backgroundColor = .clear
        switch style {
        case .native(let axisType):
            switch axisType {
            case .bottom:
                addLineViewToBottom()
            case .top:
                addLineView()
            case .both:
                addLineView()
                addLineViewToBottom()
            }
        case .flyingCapsule:
            layer.borderColor = UIColor.separator.cgColor
            layer.borderWidth = 0.4
            let cornerRadius: CGFloat = 25
            layer.cornerRadius = cornerRadius
            blurView.layer.cornerRadius = cornerRadius
            blurView.clipsToBounds = true
        }
    }
    
    private func addLineView() {
        lineView.backgroundColor = .separator
        lineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lineView)
        NSLayoutConstraint.activate([
            lineView.widthAnchor.constraint(equalTo: widthAnchor),
            lineView.heightAnchor.constraint(equalToConstant: 0.4),
            lineView.topAnchor.constraint(equalTo: topAnchor)
        ])
    }
    
    private func addLineViewToBottom() {
        lineView.backgroundColor = .separator
        lineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lineView)
        NSLayoutConstraint.activate([
            lineView.widthAnchor.constraint(equalTo: widthAnchor),
            lineView.heightAnchor.constraint(equalToConstant: 0.4),
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func addNewLineViewToBottom() {
        let lineView = UIView()
        lineView.backgroundColor = .separator
        lineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lineView)
        NSLayoutConstraint.activate([
            lineView.widthAnchor.constraint(equalTo: widthAnchor),
            lineView.heightAnchor.constraint(equalToConstant: 0.4),
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = self.bounds
    }
    
    static func suiRepresentable(blurStyle: UIBlurEffect.Style) -> FakeToolBarRepresentable {
        return FakeToolBarRepresentable(blurStyle: blurStyle)
    }
}

struct FakeToolBarRepresentable: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style = .systemMaterialDark
    
    func makeUIView(context: Context) -> FakeToolBar {
        return FakeToolBar(blurStyle: blurStyle)
    }
    
    func updateUIView(_ uiView: FakeToolBar, context: Context) {
        // Update the view if needed
    }
}
