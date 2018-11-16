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
    
    public func onLongPress(_ handler: ((UIGestureRecognizer) -> Void)?) {
        recognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handlePress(_:)))
        self.handler = handler
    }
    
    @objc func handlePress(_ gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            handler?(gesture)
        }
    }
}

private enum Actions: Selector {
    case copyText
    case copyImage
    case copyView

    var action: Selector {
        switch self {
        case .copyText:
            return #selector(ActionHolderView.copyTextAction(_:))
        case .copyImage:
            return #selector(ActionHolderView.copyImageAction(_:))
        case .copyView:
            return #selector(ActionHolderView.copyViewAction(_:))
        }
    }

    static var all: [Selector] {
        return [Actions.copyText.action, Actions.copyImage.action, Actions.copyView.action]
    }
}

private class ActionHolderView: UIView {
    typealias Action = () -> Void
    private var copyTextAction: Action?
    private var copyImageAction: Action?
    private var copyViewAction: Action?

    init(copyTextAction: Action?, copyImageAction: Action?, copyViewAction: Action?) {
        self.copyTextAction = copyTextAction
        self.copyImageAction = copyImageAction
        self.copyViewAction = copyViewAction
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func copyTextAction(_ controller: UIMenuController) {
        copyTextAction?()
        resignFirstResponder()
        removeFromSuperview()
    }

    @objc func copyImageAction(_ controller: UIMenuController) {
        copyImageAction?()
        resignFirstResponder()
        removeFromSuperview()
    }

    @objc func copyViewAction(_ controller: UIMenuController) {
        copyViewAction?()
        resignFirstResponder()
        removeFromSuperview()
    }
    
    override open var canBecomeFirstResponder: Bool {
        guard let _ = self.superview as? Copiable else { return false }
        return true
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return Actions.all.contains(action)
    }
}

private struct AssociatedKeys {
    static var gesture: UInt8 = 0
}

public enum CopiableOptions {
    case text
    case image
    case view

    public static var all: [CopiableOptions] {
        return [.text, .image, .view]
    }
}

public struct CopiableLocalization {
    let copyText: String
    let copyImage: String
    let copyView: String

    public init(copyText: String = "Copy text", copyImage: String = "Copy image", copyView: String = "Copy view") {
        self.copyText = copyText
        self.copyImage = copyImage
        self.copyView = copyView
    }
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

    public mutating func enableCopying<T>(_ content: ((Self?) -> T)?) {
        enableCopying(options: CopiableOptions.all, localization: CopiableLocalization(), content)
    }

    public mutating func enableCopying<T>(localization: CopiableLocalization, _ content: ((Self?) -> T)?) {
        enableCopying(options: CopiableOptions.all, localization: localization, content)
    }

    public mutating func enableCopying<T>(options: [CopiableOptions], localization: CopiableLocalization, _ content: ((Self?) -> T)?) {
        isUserInteractionEnabled = true
        
        gesture = GestureRecognizer()
        gesture?.onLongPress { [weak self] gesture in
            guard let gestureView = gesture.view, let superView = gestureView.superview else { return }

            var filteredOptions: [CopiableOptions] = options
            if self?.isMember(of: UILabel.self) == true || (self?.isKind(of: UIView.self) == true && self?.isMember(of: UIImageView.self) == false)     {
                filteredOptions.removeAll(where: { $0 == CopiableOptions.image })
            }
            if self?.isMember(of: UIImageView.self) == true {
                filteredOptions.removeAll(where: { $0 == CopiableOptions.text || $0 == CopiableOptions.view })
            }

            guard filteredOptions.count > 0 else { return }
            
            let menuController = UIMenuController.shared

            let release = {
                menuController.menuItems = nil
            }

            let copyText = {
                guard let content = content, let contentValue = content(self) as? String else { return }
                UIPasteboard.general.string = contentValue
                release()
            }

            let copyImage = {
                guard let content = content, let contentValue = content(self) as? UIImage else { return }
                UIPasteboard.general.image = contentValue
                release()
            }

            let copyView = {
                UIPasteboard.general.image = self?.asImage()
                release()
            }

            let actionHolderView = ActionHolderView(copyTextAction: copyText, copyImageAction: copyImage, copyViewAction: copyView)

            var items = [UIMenuItem]()
            filteredOptions.forEach { option in
                switch option {
                case .text:
                    items.append(UIMenuItem(title: "Copy text", action: Actions.copyText.action))
                case .image:
                    items.append(UIMenuItem(title: "Copy image", action: Actions.copyImage.action))
                case .view:
                    items.append(UIMenuItem(title: "Copy view", action: Actions.copyView.action))
                }
            }

            self?.addSubview(actionHolderView)

            guard !menuController.isMenuVisible, actionHolderView.canBecomeFirstResponder else { return }
            actionHolderView.becomeFirstResponder()
            menuController.menuItems = items
            
            menuController.setTargetRect(gestureView.frame, in: superView)
//            menuController.arrowDirection = self?.arrowDirection(for: gestureView) ?? .down
            menuController.setMenuVisible(true, animated: true)
        }
        
        guard let recognizer = gesture?.recognizer else { return }

        if (self.gestureRecognizers == nil) || (!gestureRecognizers!.contains(recognizer)) {
            self.addGestureRecognizer(recognizer)
        }
    }

//    private func arrowDirection(for view: UIView) -> UIMenuControllerArrowDirection {
//        let window = UIApplication.shared.keyWindow?.rootViewController?.view
//        let width = window?.frame.width
//        let height = window?.frame.height
//        let frame = view.superview?.convert(view.frame, to: window)
//
//        if height! - frame!.minY <= 10 {
//            return UIMenuControllerArrowDirection.up
//        }
//        return .up
//    }
}

extension UIView {
    func asImage() -> UIImage {
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        } else {
            UIGraphicsBeginImageContext(self.frame.size)
            self.layer.render(in:UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImage(cgImage: image!.cgImage!)
        }
    }
}
