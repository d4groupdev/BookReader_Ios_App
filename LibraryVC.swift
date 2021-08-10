
import UIKit

protocol LibraryVCDelegate: class {
    func libraryVCDelegateDidDownloadingFinishedNoticed(sender:LibraryVC)
}

class LibraryVC: PlayerVC {
    
    enum LibraryContentType : Int {
        case history = 0
        case downloads = 1
    }
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var historyContainerView: UIView!
    @IBOutlet weak var downloadsContainerView: UIView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var searchTextField: SearchTextField!
    @IBOutlet weak var libraryTabbarItem: UITabBarItem!
    @IBOutlet weak var downloadsContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var historyBottomConstraint: NSLayoutConstraint!
    
    public weak var actionDelegate:LibraryVCDelegate?
    
    private var contentFilter:Set<BookHistoryFilterType> = [.notStarted, .processing, .finished]
    private var historyVC:HistoryVC?
    private var downloadsVC:DownloadsVC?
    
    @IBSegueAction func historySegueInstantiation(_ coder: NSCoder) -> HistoryVC? {
        historyVC = HistoryVC(coder: coder)
        historyVC?.contentFilter = contentFilter
        historyVC?.searchText = searchTextField?.text
        return historyVC
    }
    
    @IBSegueAction func downloadsSegueInstantiation(_ coder: NSCoder) -> DownloadsVC? {
        downloadsVC = DownloadsVC(coder: coder)
        downloadsVC?.actionDelegate = self
        downloadsVC?.contentFilter = contentFilter
        downloadsVC?.searchText = searchTextField?.text
        return downloadsVC
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

        historyContainerView.isHidden = (LibraryContentType.history.rawValue != segmentedControl.selectedSegmentIndex)
        downloadsContainerView.isHidden = (LibraryContentType.downloads.rawValue != segmentedControl.selectedSegmentIndex)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateContentDependOfPlayer()
    }
    
    override func updateContentWithPlayer(_ view:UIView) {
        super.updateContentWithPlayer(view)
        downloadsContainerBottomConstraint.constant = view.frame.size.height
        historyBottomConstraint.constant = view.frame.size.height
    }
    
    override func updateContentWithoutPlayer() {
        super.updateContentWithoutPlayer()
        downloadsContainerBottomConstraint.constant = 0
        historyBottomConstraint.constant = 0
    }
    
    @IBAction func segmentedControlValueHandler(_ sender: UISegmentedControl) {
        historyContainerView.isHidden = (LibraryContentType.history.rawValue != segmentedControl.selectedSegmentIndex)
        downloadsContainerView.isHidden = (LibraryContentType.downloads.rawValue != segmentedControl.selectedSegmentIndex)
    }
    
    @IBAction func searchButtonTapHandler(_ sender: Any) {
        controlView.isHidden = true
        searchView.isHidden = false
    }
    
    var customControllerTransitioning:CustomControllerTransitioning?
    @IBAction func filterButtonTapHandler(_ sender: Any) {
        let vc = Books.VC(.LibraryFilter) as! LibraryFilterVC
        vc.contentFilter = contentFilter
        vc.actionDelegate = self
        vc.modalPresentationStyle = .custom
        customControllerTransitioning = CustomControllerTransitioning(animationController: vc)
        vc.transitioningDelegate = customControllerTransitioning
        present(vc, animated: true, completion: nil)

    }
}

extension LibraryVC: UITextFieldDelegate{
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        controlView.isHidden = false
        searchView.isHidden = true
        
        historyVC?.searchText = nil
        downloadsVC?.searchText = nil

        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let searchText = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        historyVC?.searchText = searchText
        downloadsVC?.searchText = searchText
        return true
    }
}

extension LibraryVC: LibraryFilterVCDelegate {
    func libraryFilterVCDidClose(sender: LibraryFilterVC) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func libraryFilterVCDidChange(sender: LibraryFilterVC) {
        contentFilter = sender.contentFilter
        historyVC?.contentFilter = contentFilter
        downloadsVC?.contentFilter = contentFilter
    }
}

extension LibraryVC: DownloadsVCDelegate{
    func downloadsVCDidDownloadingFinishedNoticed(sender: DownloadsVC) {
        self.actionDelegate?.libraryVCDelegateDidDownloadingFinishedNoticed(sender: self)
    }
}
