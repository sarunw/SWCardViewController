//
//  SWCardViewController.swift
//  Pods
//
//  Created by Sarun Wongpatcharapฟakorn on 8/5/16.
//
//

import UIKit

private let cellIdentifier = "SWCardCollectionViewCell"

private let springDamping: CGFloat = 0.8
private let animationDuration = 0.3

private enum SwipeDirection: CGFloat {
    case up
    case down
    case none
    
    init(yVelocity: CGFloat) {
        if fabs(yVelocity) < 200 {
            self.init(rawValue: SwipeDirection.none.rawValue)!
        } else if yVelocity > 0 {
            self.init(rawValue: SwipeDirection.down.rawValue)!
        } else {
            self.init(rawValue: SwipeDirection.up.rawValue)!
        }
    }
}

@objc
public protocol SWCardViewControllerDelegate: class {
    @objc optional func cardViewController(_ viewController: SWCardViewController, willShowViewControllers viewControllers: [UIViewController], animated: Bool)
    @objc optional func cardViewController(_ viewController: SWCardViewController, didShowViewControllers viewControllers: [UIViewController], animated: Bool)
    @objc optional func cardViewControllerDidRemoveAllViewControllers(_ viewController: SWCardViewController)
    @objc optional func cardViewControllerDidTapDismiss(_ viewController: SWCardViewController)
    
    @objc optional func cardViewController(_ viewController: SWCardViewController, willDisplayViewController: UIViewController)
}

@objc
public protocol SWCardViewControllerDataSource: class {
    func cardViewController(_ viewController: SWCardViewController, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
}

open class SWCardViewController: UIViewController, UIGestureRecognizerDelegate {

    open var cardSize = CGSize(width: 300, height: 400)
    weak open var delegate: SWCardViewControllerDelegate? = nil
    weak open var dataSource: SWCardViewControllerDataSource? = nil
    
    lazy fileprivate var collectionView: UICollectionView = {
        // Make lazy load so any method that reference collection view won't crash
        // i.e. `setViewControllers`
        let layout = SWCardViewCollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        if #available(iOS 10.0, *) {
            // TODO: find the cause of ghost view and reenable this
            collectionView.isPrefetchingEnabled = false
        }
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.alwaysBounceHorizontal = true
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let bundle = Bundle(for: SWCardViewController.self)
        let nib = UINib(nibName: "SWCardCollectionViewCell", bundle: bundle)
        collectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        return collectionView
    }()
    fileprivate var viewControllers = [UIViewController]()
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        adjustInsets()
    }
    
    fileprivate func adjustInsets() {
        var firstCardSize = cardSize
        if let dataSource = dataSource {
            let indexPath = IndexPath(item: 0, section: 0)
            firstCardSize = dataSource.cardViewController(self, sizeForItemAtIndexPath: indexPath)
        }
        
        var insets = UIEdgeInsets.zero
        insets.top = (collectionView.bounds.size.height - firstCardSize.height) / 2
        insets.bottom = insets.top
        
        insets.left = (collectionView.bounds.size.width - firstCardSize.width) / 2
        insets.right = insets.left
        
        
        
        collectionView.contentInset = insets
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    fileprivate func setup() {
        setupCollectionView()
        setupGestures()
    }
    
    fileprivate func setupCollectionView() {
        // Reference to view only when view did load
        view.addSubview(collectionView)
        if #available(iOS 9.0, *) {
            view.leftAnchor.constraint(equalTo: collectionView.leftAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: collectionView.rightAnchor).isActive = true
            view.topAnchor.constraint(equalTo: collectionView.topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor).isActive = true
        } else {
            // Fallback on earlier versions
            let views = ["collectionView": collectionView]
            
            let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|collectionView|", options: NSLayoutFormatOptions(), metrics: nil, views: views)
            let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|collectionView|", options: NSLayoutFormatOptions(), metrics: nil, views: views)
            
            view.addConstraints(hConstraints)
            view.addConstraints(vConstraints)
        }
    }
    
    fileprivate func setupGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        panGestureRecognizer.delegate = self
        
        self.collectionView.addGestureRecognizer(panGestureRecognizer)
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.cancelsTouchesInView = false
        
        self.collectionView.addGestureRecognizer(tapGestureRecognizer)
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open func indexForViewController(_ viewController: UIViewController) -> Int {
        if let index = viewControllers.index(of: viewController) {
            return index
        }
        
        return NSNotFound
    }
    
    /**
     Dismiss view controller.
     
     - parameter animated: enable animation
     */
    open func dismissViewController(_ viewController: UIViewController, animated: Bool) {
        guard let index = viewControllers.index(of: viewController) else {
            return
        }
        
        let indexPath = IndexPath(item: index, section: 0)
        let cell = collectionView.cellForItem(at: indexPath)
        let remainingDistance = self.collectionView.bounds.size.height
        
        UIView.animate(withDuration: animationDuration, animations: { 
            
            cell?.transform = CGAffineTransform(translationX: 0, y: remainingDistance)
            
            }, completion: { (finished) in
                self.deleteItem(atIndexPath: indexPath)
        }) 
//        UIView.animateWithDuration(animationDuration, delay: 0, usingSpringWithDamping: springDamping, initialSpringVelocity: 0, options: .BeginFromCurrentState, animations: {
//            
//            cell?.transform = CGAffineTransformMakeTranslation(0, remainingDistance)
//            
//            }, completion: { (finished) in
//                self.deleteItem(atIndexPath: indexPath)
//        })
    }
    
    /**
     Sets the root view controllers of the card view controller.
     
     - parameter viewControllers: The array of custom view controllers to display in the card interface.
     - parameter animated:        if `true`, the card items for the view controllers are animated into the position. If `false`, changes are reflected immediately.
     */
    open func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        self.delegate?.cardViewController?(self, willShowViewControllers: viewControllers, animated: animated)
        self.viewControllers = viewControllers
        collectionView.reloadData()
        self.delegate?.cardViewController?(self, didShowViewControllers: viewControllers, animated: animated)
    }
    
    // MARK: - Actions
    fileprivate var swipingCell: UICollectionViewCell? = nil
    fileprivate var yVelocity: CGFloat = 0
    fileprivate var swipeDirection: SwipeDirection? = nil
    
    func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.cardViewControllerDidTapDismiss?(self)
    }
    
    func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        let point = gestureRecognizer.location(in: collectionView)
        var cell: UICollectionViewCell? = nil
        if let indexPath = collectionView.indexPathForItem(at: point) {
            cell = collectionView.cellForItem(at: indexPath)
        }
        
        switch gestureRecognizer.state {
        case .began:
            swipingCell = cell
        case .changed:
            let translation = gestureRecognizer.translation(in: collectionView)
            // added resistance
            var yTranslation = translation.y
            print("y tran \(yTranslation)")
            
            yTranslation -= yTranslation * 0.5
            
            print("become yy tran \(yTranslation)")
            
            yVelocity = gestureRecognizer.velocity(in: collectionView).y
            swipingCell?.transform = CGAffineTransform(translationX: 0, y: yTranslation)
            
            print("tran \(translation.y) veloc \(yVelocity)")
        case .ended:
            
            let duration: CGFloat = 0.3
            
            let translation = gestureRecognizer.translation(in: collectionView)
            let yDistance = translation.y
            
            let targetVelocity = gestureRecognizer.velocity(in: collectionView).y
            
            var directionDetermine = yDistance
            if fabs(yDistance) < fabs(targetVelocity * 0.15) {
                directionDetermine = targetVelocity * 0.15
            }
            
            // A value of 1 corresponds to the total animation distance traversed in one second. For example, if the total animation distance is 200 points and you want the start of the animation to match a view velocity of 100 pt/s, use a value of 0.5.
            let initialSpringVelocity = targetVelocity / (yDistance / duration)
            
            let direction = SwipeDirection(yVelocity: directionDetermine)
        
            print("direction \(direction) initital \(initialSpringVelocity)")
            
            var shouldDelete = false
            
            UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: springDamping, initialSpringVelocity: 0, options: .beginFromCurrentState, animations: {
                
                switch direction {
                case .up:
                    let remainingDistance = self.collectionView.bounds.size.height
                    
                    self.swipingCell?.transform = CGAffineTransform(translationX: 0, y: -remainingDistance)
                    shouldDelete = true
                case .down:
                    let remainingDistance = self.collectionView.bounds.size.height
                    
                    self.swipingCell?.transform = CGAffineTransform(translationX: 0, y: remainingDistance)
                    shouldDelete = true
                case .none:
                    self.swipingCell?.transform = CGAffineTransform.identity
                }
                

                }, completion: { (finished) in
                    if shouldDelete {
                        if let swipingCell = self.swipingCell,
                        let indexPath = self.collectionView.indexPath(for: swipingCell) {
                            self.deleteItem(atIndexPath: indexPath)
                        }
                        
                    } else {
                        gestureRecognizer.setTranslation(CGPoint.zero, in: self.collectionView)
                    }
            })            
        default:
            break
        }
    }
    
    fileprivate func deleteItem(atIndexPath indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.alpha = 0
        
        collectionView.performBatchUpdates({ [weak self] in
            self?.viewControllers.remove(at: (indexPath as NSIndexPath).item)
            self?.collectionView.deleteItems(at: [indexPath])
            }) { (finished) in
            cell?.alpha = 1
        
        }
        
        
        if viewControllers.count == 0 {
            delegate?.cardViewControllerDidRemoveAllViewControllers?(self)
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let point = gestureRecognizer.location(in: collectionView)
            guard
                let indexPath = collectionView.indexPathForItem(at: point),
                let cell = collectionView.cellForItem(at: indexPath)
                else {
                    // If didn't touched on cell not begin
                    return false
            }
            
            let translation = gestureRecognizer.translation(in: collectionView)
            let yDirectionMovement = fabs(translation.x) < fabs(translation.y)
            
            return yDirectionMovement
        
        }
        
        if let tapGesture = gestureRecognizer as? UITapGestureRecognizer {
            let point = gestureRecognizer.location(in: collectionView)
            guard
                let indexPath = collectionView.indexPathForItem(at: point),
                let cell = collectionView.cellForItem(at: indexPath)
                else {
                    // If didn't touched on cell not begin
                    return true
            }
            
            return false
        }
        
        
        return false
    }
}

extension SWCardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let vc = viewControllers[(indexPath as NSIndexPath).row]
        
        delegate?.cardViewController?(self, willDisplayViewController: vc)
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewControllers.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! SWCardCollectionViewCell
        
        print("viewController \(viewControllers)")
        print("indexPath \(indexPath)")
        
        let vc = viewControllers[(indexPath as NSIndexPath).row]
        
        add(childViewController: vc, toCell: cell)
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let dataSource = dataSource {
            return dataSource.cardViewController(self, sizeForItemAtIndexPath: indexPath)
        }
        
        return cardSize
        
//        let rect = collectionView.bounds
//        let insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
//        let rectWithInsets = UIEdgeInsetsInsetRect(rect, insets)
//        
//        return rectWithInsets.size
    }
    
    fileprivate func add(childViewController: UIViewController, toCell cell: SWCardCollectionViewCell) {
        
        cell.viewController = childViewController
        
        addChildViewController(childViewController)
        let childView = childViewController.view
        
        childView?.frame = cell.containerView.bounds
        
        cell.containerView.addSubview(childView!)
        
        if #available(iOS 9.0, *) {
            cell.containerView.leftAnchor.constraint(equalTo: (childView?.leftAnchor)!).isActive = true
            cell.containerView.rightAnchor.constraint(equalTo: (childView?.rightAnchor)!).isActive = true
            cell.containerView.topAnchor.constraint(equalTo: (childView?.topAnchor)!).isActive = true
            cell.containerView.bottomAnchor.constraint(equalTo: (childView?.topAnchor)!).isActive = true
        } else {
            let views = ["childView": childView]
            
            let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|childView|", options: NSLayoutFormatOptions(), metrics: nil, views: views)
            let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|childView|", options: NSLayoutFormatOptions(), metrics: nil, views: views)
            
            cell.containerView.addConstraints(hConstraints)
            cell.containerView.addConstraints(vConstraints)
        }
        
        childViewController.didMove(toParentViewController: self)
    }
    
    fileprivate func remove(childViewController: UIViewController, fromCell cell: SWCardCollectionViewCell) {
        childViewController.willMove(toParentViewController: nil)
        let childView = childViewController.view
        childView?.removeFromSuperview()
        childViewController.removeFromParentViewController()
    }
    
    
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard
            let cell = cell as? SWCardCollectionViewCell,
            let oldViewController = cell.viewController else {
            return
        }
        
        remove(childViewController: oldViewController, fromCell: cell)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return (collectionView.contentInset.left) / 2 // half the inset, so we can see the edge
    }
}

extension UIViewController {
    public var cardViewController: SWCardViewController? {
        if let parentViewController = parent as? SWCardViewController {
            return parentViewController
        }
        
        return nil
    } // If this view controller has been pushed onto a card controller, return it.
}
