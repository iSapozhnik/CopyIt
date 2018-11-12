//
//  CopyIt.swift
//  CopyIt
//
//  Created by Ivan Sapozhnik on 11/11/18.
//

import Foundation

public protocol Copiable {}

private class GestureRecognizer {
    private var handler: ((UIGestureRecognizer) -> Void)?
    var recognizer: UIGestureRecognizer?
    
    public func observe(with handler: ((UIGestureRecognizer) -> Void)?) {
        recognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handlePress(_:)))
        self.handler = handler
    }
    
    @objc func handlePress(_ gesture: UIGestureRecognizer) {
        handler?(gesture)
    }
}

private class ActionHolderView: UIView {
    private var action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func copyAction(_ controller: UIMenuController) {
        action()
        resignFirstResponder()
        removeFromSuperview()
    }
    
    override open var canBecomeFirstResponder: Bool {
        guard let _ = self.superview as? Copiable else { return false }
        return true
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copyAction(_:))
    }
}

private class CopyTextMenuItem: UIMenuItem {
    let actionHolderView: ActionHolderView
    
    init(title: String, block: @escaping () -> Void) {
        self.actionHolderView = ActionHolderView(action: block)
        super.init(title: title, action: #selector(ActionHolderView.copyAction(_:)))
    }
}

private struct AssociatedKeys {
    static var gesture: UInt8 = 0
}

public extension Copiable where Self: UIView {
    private var gesture: GestureRecognizer? {
        get {
            guard let value = objc_getAssociatedObject(self, &AssociatedKeys.gesture) as? GestureRecognizer else {
                return nil
            }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.gesture, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public mutating func enableCopying(with content: @escaping (Self?) -> String) {
        isUserInteractionEnabled = true
        
        gesture = GestureRecognizer()
        gesture?.observe(with: { [weak self] gesture in
            guard let gestureView = gesture.view, let superView = gestureView.superview else {
                return
            }
            
            let menuController = UIMenuController.shared
            
            let copyItem = CopyTextMenuItem(title: "COPY ME", block: {
                UIPasteboard.general.string = content(self)
            })
            self?.addSubview(copyItem.actionHolderView)
            
            guard !menuController.isMenuVisible, copyItem.actionHolderView.canBecomeFirstResponder else { return }
            copyItem.actionHolderView.becomeFirstResponder()
            menuController.menuItems = [copyItem]
            
            menuController.setTargetRect(gestureView.frame, in: superView)
            menuController.setMenuVisible(true, animated: true)
        })
        
        guard let recognizer = gesture?.recognizer else { return }

        if (self.gestureRecognizers == nil) || (!gestureRecognizers!.contains(recognizer)) {
            self.addGestureRecognizer(recognizer)
        }
    }
}

