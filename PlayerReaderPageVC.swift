
import UIKit
import FolioReaderKit

protocol PlayerReaderPageVCDelegate: class {
    func playerReaderPageVCDidClose(sender:PlayerReaderPageVC)
    func playerReaderPageVCDidPlay(sender:PlayerReaderPageVC)
    func playerReaderPageVCDidReader(sender:PlayerReaderPageVC)
    func playerReaderPageVCDidChangeCurrentTime(sender:PlayerReaderPageVC, currentTime:Float)
    func playerReaderPageVCDidChangeCurrentSpeedMode(sender:PlayerReaderPageVC, currentSpeedMode:Int)
    func playerReaderPageVCDidSkipBefor(sender:PlayerReaderPageVC)
    func playerReaderPageVCDidSkipAfter(sender:PlayerReaderPageVC)
}

class PlayerReaderPageVC: UIPageViewController {

    enum PlayerReaderPageVCType: Int {
        case player = 0
        case reader = 1
    }
    
    public weak var actionDelegate:PlayerReaderPageVCDelegate?{
        didSet{
            if nil == actionDelegate {
                print("actionDelegate = nil")
            }
        }
    }
    
    public var readerCanClose:Bool = false
    
    public var book:BookMVVM?
    
    public var isPlayMode:Bool = false {
        didSet{
            self.bookPlayerVC?.isPlayMode = isPlayMode
        }
    }
    
    public var duration:Float = 0 {
        didSet{
            bookPlayerVC?.duration = duration
        }
    }
    
    public var currentTime:Float = 0 {
        didSet{
            bookPlayerVC?.currentTime = currentTime
        }
    }

    public var currentSpeedMode:Int = 2 {
        didSet{
            bookPlayerVC?.currentSpeedMode = currentSpeedMode
        }
    }

    private var controllers:[UINavigationController]?
    private let folioReader = FolioReader()
    private var bookPlayerVC:BookPlayerVC?
    private var bookReaderVC:BookReaderVC?
    
    public var playerReaderPageType:PlayerReaderPageVCType = .player {
        didSet{
            if let firstVC = self.controllers?[playerReaderPageType.rawValue] {
                setViewController(firstVC, animated: false)
            }
        }
    }
    
    public func getCurrentType() -> PlayerReaderPageVCType {
        if let firstController = self.controllers?.first {
            return self.viewControllers?.first == firstController ? .player : .reader
        }
        else{
            return .player
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        self.dataSource = self
        
        bookPlayerVC = Books.instantiateViewController(withIdentifier: ViewControllerName.BookPlayer.rawValue) as? BookPlayerVC
        bookPlayerVC?.book = book
        bookPlayerVC?.actionDelegate = self
        bookPlayerVC?.isPlayMode = isPlayMode
        bookPlayerVC?.currentSpeedMode = currentSpeedMode
        
        bookReaderVC = Books.instantiateViewController(withIdentifier: ViewControllerName.BookReader.rawValue) as? BookReaderVC
        bookReaderVC?.actionDelegate = self

        if let bookPlayer = bookPlayerVC, let bookReader = bookReaderVC {
            self.controllers = [CustomNVC(rootViewController: bookPlayer), CustomNVC(rootViewController: bookReader)]
        }
        
        switch playerReaderPageType {
        case .player:
            if let firstVC = self.controllers?.first {
                setViewController(firstVC, animated: false)
            }
            
        case .reader:
            if let lastVC = self.controllers?.last {
                setViewController(lastVC, animated: false)
            }
        }
        
        for item in self.gestureRecognizers {
            if let item = item as? UITapGestureRecognizer {
                item.isEnabled = false
            }
        }
    }
    
    private func setViewController(_ viewController: UIViewController, animated: Bool){
        setViewControllers([viewController], direction: .forward, animated: animated)
        let isAudio = (viewController == controllers?[0])
        bookPlayerVC?.book?.saveHistory(isAudio: isAudio, completion: {(isSuccess:Bool, message:String?) in print(isAudio ? ("Set Audio - " + (message ?? "")) : ("Set Reader - " + (message ?? "")))})
    }
}

extension PlayerReaderPageVC: UIPageViewControllerDataSource{
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController == self.controllers?.last {
            return self.controllers?.first
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController == self.controllers?.first {
            return self.controllers?.last
        }
        
        return nil
    }
}

extension PlayerReaderPageVC: UIPageViewControllerDelegate{
    
}

extension PlayerReaderPageVC: BookReaderVCDelegate{
    func bookReaderVCDidClose(sender: BookReaderVC) {
        self.actionDelegate?.playerReaderPageVCDidClose(sender: self)
        
        if playerReaderPageType == .reader {
            self.actionDelegate?.playerReaderPageVCDidClose(sender: self)
        }
        else{
            if let firstVC = self.controllers?.first {
                setViewController(firstVC, animated: true)
            }
        }
    }
    
    func bookReaderVCDidReader(sender: BookReaderVC) {
        if let firstVC = self.controllers?.first {
            setViewController(firstVC, animated: false)
        }
    }
}

extension PlayerReaderPageVC: BookPlayerVCDelegate{
    func bookPlayerVCDidSkipBefor(sender: BookPlayerVC) {
        self.actionDelegate?.playerReaderPageVCDidSkipBefor(sender: self)
    }
    
    func bookPlayerVCDidSkipAfter(sender: BookPlayerVC) {
        self.actionDelegate?.playerReaderPageVCDidSkipAfter(sender: self)
    }
    
    func bookPlayerVCDidChangeCurrentSpeed(sender: BookPlayerVC, currentSpeedMode: Int) {
        self.actionDelegate?.playerReaderPageVCDidChangeCurrentSpeedMode(sender: self, currentSpeedMode: currentSpeedMode)
    }
    
    func bookPlayerVCDidChangeCurrentTime(sender: BookPlayerVC, currentTime: Float) {
        self.actionDelegate?.playerReaderPageVCDidChangeCurrentTime(sender: self, currentTime: currentTime)
    }
    
    func bookPlayerVCDidReader(sender: BookPlayerVC) {
        if let lastVC = self.controllers?.last {
            setViewController(lastVC, animated: false)
        }
    }
    
    func bookPlayerVCDidClose(sender: BookPlayerVC) {
        self.actionDelegate?.playerReaderPageVCDidClose(sender: self)
    }
    
    func bookPlayerVCDidPlay(sender: BookPlayerVC) {
        self.actionDelegate?.playerReaderPageVCDidPlay(sender: self)
    }
}

