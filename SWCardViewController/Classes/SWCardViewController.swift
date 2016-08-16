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
    case Up
    case Down
    case None
    
    init(yVelocity: CGFloat) {
        if fabs(yVelocity) < 200 {
            self.init(rawValue: None.rawValue)!
        } else if yVelocity > 0 {
            self.init(rawValue: Down.rawValue)!
        } else {
            self.init(rawValue: Up.rawValue)!
        }
    }
}

@objc
public protocol SWCardViewControllerDelegate: class {
    optional func cardViewController(_ viewController: SWCardViewController, willShowViewControllers viewControllers: [UIViewController], animated: Bool)
    optional func cardViewController(_ viewController: SWCardViewController, didShowViewControllers viewControllers: [UIViewController], animated: Bool)
    optional func cardViewControllerDidRemoveAllViewControllers(_ viewController: SWCardViewController)
}

@objc
public protocol SWCardViewControllerDataSource: class {
    func cardViewController(_ viewController: SWCardViewController, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
}

public class SWCardViewController: UIViewController, UIGestureRecognizerDelegate {

    public var cardSize = CGSize(width: 300, height: 400)
    weak public var delegate: SWCardViewControllerDelegate? = nil
    weak public var dataSource: SWCardViewControllerDataSource? = nil
    
    lazy private var collectionView: UICollectionView = {
        // Make lazy load so any method that reference collection view won't crash
        // i.e. `setViewControllers`
        let layout = SWCardViewCollectionViewFlowLayout()
        layout.scrollDirection = .Horizontal
        
        let collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.alwaysBounceHorizontal = true
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let bundle = NSBundle(forClass: SWCardViewController.self)
        let nib = UINib(nibName: "SWCardCollectionViewCell", bundle: bundle)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        return collectionView
    }()
    private var viewControllers = [UIViewController]()
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        adjustInsets()
    }
    
    private func adjustInsets() {
        var firstCardSize = cardSize
        if let dataSource = dataSource {
            let indexPath = NSIndexPath(forItem: 0, inSection: 0)
            firstCardSize = dataSource.cardViewController(self, sizeForItemAtIndexPath: indexPath)
        }
        
        var insets = UIEdgeInsetsZero
        insets.top = (collectionView.bounds.size.height - firstCardSize.height) / 2
        insets.bottom = insets.top
        
        insets.left = (collectionView.bounds.size.width - firstCardSize.width) / 2
        insets.right = insets.left
        
        
        
        collectionView.contentInset = insets
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setup() {
        setupCollectionView()
        setupGestures()
    }
    
    private func setupCollectionView() {
        // Reference to view only when view did load
        view.addSubview(collectionView)
        if #available(iOS 9.0, *) {
            view.leftAnchor.constraintEqualToAnchor(collectionView.leftAnchor).active = true
            view.rightAnchor.constraintEqualToAnchor(collectionView.rightAnchor).active = true
            view.topAnchor.constraintEqualToAnchor(collectionView.topAnchor).active = true
            view.bottomAnchor.constraintEqualToAnchor(collectionView.bottomAnchor).active = true
        } else {
            // Fallback on earlier versions
            let views = ["collectionView": collectionView]
            
            let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|collectionView|", options: NSLayoutFormatOptions(), metrics: nil, views: views)
            let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|collectionView|", options: NSLayoutFormatOptions(), metrics: nil, views: views)
            
            view.addConstraints(hConstraints)
            view.addConstraints(vConstraints)
        }
    }
    
    private func setupGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        panGestureRecognizer.delegate = self
        
        self.collectionView.addGestureRecognizer(panGestureRecognizer)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     Returns the popped controller.
     
     - parameter animated: <#animated description#>
     
     - returns: <#return value description#>
     */
    public func dismissViewController(viewController: UIViewController, animated: Bool) {
        guard let index = viewControllers.indexOf(viewController) else {
            return
        }
        
        let indexPath = NSIndexPath(forItem: index, inSection: 0)
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        let remainingDistance = self.collectionView.bounds.size.height
        
        UIView.animateWithDuration(animationDuration, animations: { 
            
            cell?.transform = CGAffineTransformMakeTranslation(0, remainingDistance)
            
            }) { (finished) in
                self.deleteItem(atIndexPath: indexPath)
        }
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
    public func setViewControllers(viewControllers: [UIViewController], animated: Bool) {
        self.delegate?.cardViewController?(self, willShowViewControllers: viewControllers, animated: animated)
        self.viewControllers = viewControllers
        collectionView.reloadData()
        self.delegate?.cardViewController?(self, didShowViewControllers: viewControllers, animated: animated)
    }
    
    // MARK: - Actions
    private var swipingCell: UICollectionViewCell? = nil
    private var yVelocity: CGFloat = 0
    private var swipeDirection: SwipeDirection? = nil
    
    func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        let point = gestureRecognizer.locationInView(collectionView)
        var cell: UICollectionViewCell? = nil
        if let indexPath = collectionView.indexPathForItemAtPoint(point) {
            cell = collectionView.cellForItemAtIndexPath(indexPath)
        }
        
        switch gestureRecognizer.state {
        case .Began:
            swipingCell = cell
        case .Changed:
            let translation = gestureRecognizer.translationInView(collectionView)
            // added resistance
            var yTranslation = translation.y
            print("y tran \(yTranslation)")
            
            yTranslation -= yTranslation * 0.5
            
            print("become yy tran \(yTranslation)")
            
            yVelocity = gestureRecognizer.velocityInView(collectionView).y
            swipingCell?.transform = CGAffineTransformMakeTranslation(0, yTranslation)
            
            print("tran \(translation.y) veloc \(yVelocity)")
        case .Ended:
            
            let duration: CGFloat = 0.3
            
            let translation = gestureRecognizer.translationInView(collectionView)
            let yDistance = translation.y
            
            let targetVelocity = gestureRecognizer.velocityInView(collectionView).y
            
            var directionDetermine = yDistance
            if fabs(yDistance) < fabs(targetVelocity * 0.15) {
                directionDetermine = targetVelocity * 0.15
            }
            
            // A value of 1 corresponds to the total animation distance traversed in one second. For example, if the total animation distance is 200 points and you want the start of the animation to match a view velocity of 100 pt/s, use a value of 0.5.
            var initialSpringVelocity = targetVelocity / (yDistance / duration)
            
            let direction = SwipeDirection(yVelocity: directionDetermine)
        
            print("direction \(direction) initital \(initialSpringVelocity)")
            
            var shouldDelete = false
            
            UIView.animateWithDuration(animationDuration, delay: 0, usingSpringWithDamping: springDamping, initialSpringVelocity: 0, options: .BeginFromCurrentState, animations: {
                
                switch direction {
                case .Up:
                    let remainingDistance = self.collectionView.bounds.size.height
                    
                    self.swipingCell?.transform = CGAffineTransformMakeTranslation(0, -remainingDistance)
                    shouldDelete = true
                case .Down:
                    let remainingDistance = self.collectionView.bounds.size.height
                    
                    self.swipingCell?.transform = CGAffineTransformMakeTranslation(0, remainingDistance)
                    shouldDelete = true
                case .None:
                    self.swipingCell?.transform = CGAffineTransformIdentity
                }
                

                }, completion: { (finished) in
                    if shouldDelete {
                        if let swipingCell = self.swipingCell,
                        let indexPath = self.collectionView.indexPathForCell(swipingCell) {
                            self.deleteItem(atIndexPath: indexPath)
                        }
                        
                    } else {
                        gestureRecognizer.setTranslation(CGPointZero, inView: self.collectionView)
                    }
            })            
        default:
            break
        }
    }
    
    private func deleteItem(atIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.alpha = 0
        
        collectionView.performBatchUpdates({ [weak self] in
            self?.viewControllers.removeAtIndex(indexPath.item)
            self?.collectionView.deleteItemsAtIndexPaths([indexPath])
            }) { (finished) in
            cell?.alpha = 1
        
        }
        
        
        if viewControllers.count == 0 {
            delegate?.cardViewControllerDidRemoveAllViewControllers?(self)
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        
        let point = gestureRecognizer.locationInView(collectionView)
        guard
            let indexPath = collectionView.indexPathForItemAtPoint(point),
            let cell = collectionView.cellForItemAtIndexPath(indexPath)
        else {
            // If didn't touched on cell not begin
            return false
        }
        
        let translation = gestureRecognizer.translationInView(collectionView)
        let yDirectionMovement = fabs(translation.x) < fabs(translation.y)
        
        return yDirectionMovement
    }

}

extension SWCardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewControllers.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! SWCardCollectionViewCell
        
        let vc = viewControllers[indexPath.row]
        
        add(childViewController: vc, toCell: cell)
        
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
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
    
    private func add(childViewController childViewController: UIViewController, toCell cell: SWCardCollectionViewCell) {
        
        cell.viewController = childViewController
        
        addChildViewController(childViewController)
        let childView = childViewController.view
        
        childView.frame = cell.containerView.bounds
        
        cell.containerView.addSubview(childView)
        
        if #available(iOS 9.0, *) {
            cell.containerView.leftAnchor.constraintEqualToAnchor(childView.leftAnchor).active = true
            cell.containerView.rightAnchor.constraintEqualToAnchor(childView.rightAnchor).active = true
            cell.containerView.topAnchor.constraintEqualToAnchor(childView.topAnchor).active = true
            cell.containerView.bottomAnchor.constraintEqualToAnchor(childView.topAnchor).active = true
        } else {
            let views = ["childView": childView]
            
            let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|childView|", options: NSLayoutFormatOptions(), metrics: nil, views: views)
            let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|childView|", options: NSLayoutFormatOptions(), metrics: nil, views: views)
            
            cell.containerView.addConstraints(hConstraints)
            cell.containerView.addConstraints(vConstraints)
        }
        
        childViewController.didMoveToParentViewController(self)
    }
    
    private func remove(childViewController childViewController: UIViewController, fromCell cell: SWCardCollectionViewCell) {
        childViewController.willMoveToParentViewController(nil)
        let childView = childViewController.view
        childView.removeFromSuperview()
        childViewController.removeFromParentViewController()
    }
    
    public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        guard
            let cell = cell as? SWCardCollectionViewCell,
            let oldViewController = cell.viewController else {
            return
        }
        
        remove(childViewController: oldViewController, fromCell: cell)
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        return (collectionView.bounds.size.width - self.cardSize.width) / (2 * 2) // half the inset, so we can see the edge
    }
}

extension UIViewController {
    public var cardViewController: SWCardViewController? {
        if let parentViewController = parentViewController as? SWCardViewController {
            return parentViewController
        }
        
        return nil
    } // If this view controller has been pushed onto a card controller, return it.
}