//
//  ViewController.swift
//  UIKit-Test
//
//  Created by Seb Vidal on 17/06/2023.
//

import UIKit
import SwiftUI

class ViewController: UIViewController {
    var visualEffectView: KBVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        UIView.swizzleLayoutSubviews()
        setupVisualEffectView()
        setupTextField()
        setupObservers()
    }
    
    private func setupVisualEffectView() {
        visualEffectView = KBVisualEffectView()
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(visualEffectView)
        
        NSLayoutConstraint.activate([
            visualEffectView.widthAnchor.constraint(equalToConstant: 100),
            visualEffectView.heightAnchor.constraint(equalToConstant: 100),
            visualEffectView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
    }
    
    private func setupTextField() {
        let textField = UITextField()
        textField.placeholder = "Present Keyboard"
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100)
        ])
    }
    
    private func setupObservers() {
        let name = NSNotification.Name("Test")
        
        /// Receive UIKBVisualEffectView's filters. Extract the colorMatrix filter. Apply it to visualEffectView.
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [unowned self] notification in
            let filters = notification.object as? [NSObject]
            
            let colorMatrix = filters?.first { filter in
                return filter.value(forKey: "name") as? String == "colorMatrix"
            }

            if let colorMatrix, visualEffectView.layer.filters?.count == 2 {
                visualEffectView.layer.filters?.append(colorMatrix)
            }
            
            /// This returns an NSConcreteValue, a subclass of NSValue
            let inputColorMatrix = colorMatrix!.value(forKey: "inputColorMatrix") as! NSObject
        }
    }
}

/// Swizzle UIView.layoutSubviews() just to extract UIKBVisualEffectView layer's filters.
/// Only temporary to get the colorMatrix CAFilter.
extension UIView {
    static func swizzleLayoutSubviews() {
        let originalSelector = #selector(UIView.layoutSubviews)
        let swizzledSelector = #selector(UIView._layoutSubviews)
        
        let originalMethod = class_getInstanceMethod(UIView.self, originalSelector)!
        let swizzledMethod = class_getInstanceMethod(UIView.self, swizzledSelector)!
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc dynamic func _layoutSubviews() {
        _layoutSubviews()
        
        if String(describing: type(of: self)) == "UIKBVisualEffectView" {
            guard let filters = subviews.first?.layer.filters else { return }
            NotificationCenter.default.post(name: NSNotification.Name("Test"), object: filters)
        }
    }
}

/// Simple view to replicate UIVisualEffectView without all off the fluff of
/// filters being reset when switching between light/dark mode.
class KBVisualEffectView: UIView {
    override class var layerClass: AnyClass {
        return NSClassFromString("CABackdropLayer")!
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let gaussianBlur = CAFilter.filter(withType: "gaussianBlur") as! NSObject
        gaussianBlur.setValue(true, forKey: "inputNormalizeEdges")
        gaussianBlur.setValue(20, forKey: "inputRadius")
        
        let colorSaturate = CAFilter.filter(withType: "colorSaturate") as! NSObject
        colorSaturate.setValue(1.8, forKey: "inputAmount")
        
        layer.filters = [gaussianBlur, colorSaturate]
        backgroundColor = .black.withAlphaComponent(0.1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
