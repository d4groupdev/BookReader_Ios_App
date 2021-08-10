
import UIKit

protocol BookReaderVCDelegate : class {
    func bookReaderVCDidClose(sender: BookReaderVC)
    func bookReaderVCDidReader(sender: BookReaderVC)
}

class BookReaderVC: UIViewController {

    @IBOutlet weak var bookmarkImageView: UIImageView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var listenTab: UITabBarItem!
    @IBOutlet weak var viewTab: UITabBarItem!
    @IBOutlet weak var bookmarkTab: UITabBarItem!
    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    
    public weak var actionDelegate:BookReaderVCDelegate?
    
    private var bookReader:StoryboardFolioReaderContrainer?
    private var customControllerTransitioning:CustomControllerTransitioning?
    
    private var isNightMode = false {
        willSet{
            if newValue != isNightMode {
                if let snapshot = self.view.snapshotView(afterScreenUpdates: false){
                    self.view.addSubview(snapshot)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                        snapshot.removeFromSuperview()
                    }
                }
           }
        }
        
        didSet{
            if isNightMode {
                setNightMode()
            }
            else{
                setDayMode()
            }
        }
    }
    
    private func setNightMode(){
        self.view?.backgroundColor = UIColor(named: "FolioBGColorDark")
        self.tabBar?.backgroundColor = UIColor(named: "FolioBGColorDark")
        self.tabBar?.barTintColor = UIColor(named: "FolioBGColorDark") //#1E2D34
        self.tabBar?.tintColor = UIColor(named: "Brand1Color")
        self.backButton.tintColor = .white
        self.moreButton.tintColor = .white
        self.bookReader?.isNightNode = true
        self.bookReader?.view.backgroundColor = UIColor(named: "FolioBGColorDark")
        self.bookReader?.centerViewController?.view.backgroundColor = UIColor(named: "FolioBGColorDark")
        self.bookReader?.centerViewController?.collectionView.backgroundColor = UIColor(named: "FolioBGColorDark")
        self.navigationController?.navigationBar.barStyle = .black
        self.setNeedsStatusBarAppearanceUpdate()
        self.titleLabel.textColor = .white
        self.spinner.backgroundColor = UIColor(named: "FolioBGColorDark")
        self.spinner.style = .white
        self.spinner.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.spinner.stopAnimating()
        }
        
        
    }
    
    private func setDayMode(){
        self.view?.backgroundColor = .white
        self.tabBar?.backgroundColor = .white
        self.tabBar?.barTintColor = .white
        self.tabBar?.tintColor = UIColor(named: "Brand2Color")
        self.backButton.tintColor = UIColor(named: "Brand2Color")
        self.moreButton.tintColor = UIColor(named: "Brand2Color")
        self.titleLabel.textColor = UIColor(named: "Brand2Color")
        self.bookReader?.isNightNode = false
        
        self.bookReader?.view.backgroundColor = .white
        self.bookReader?.centerViewController?.view.backgroundColor = .white
        self.bookReader?.centerViewController?.collectionView.backgroundColor = .white
        self.bookReader?.centerViewController?.currentPage?.webView?.backgroundColor = .white
        self.bookReader?.centerViewController?.currentPage?.webView?.tintColor = .white
        self.navigationController?.navigationBar.barStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
        self.spinner.backgroundColor = .white
        self.spinner.style = .gray
        self.spinner.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.spinner.stopAnimating()
        }
    }
    
    @IBSegueAction func createBookReader(_ coder: NSCoder) -> StoryboardFolioReaderContrainer? {
        bookReader = StoryboardFolioReaderContrainer(coder: coder)
        bookReader?.actionDelegate = self
        return bookReader
    }
    
    @IBAction func rateTapHandler(_ sender: Any) {
        if let currentBook = PlayerVC.currentBook {
            let bookRateVC = Books.VC(.BookRate) as! BookRateVC
            bookRateVC.book = currentBook
            bookRateVC.actionDelegate = self
            bookRateVC.modalPresentationStyle = .fullScreen
            bookRateVC.title = currentBook.bookModel.title
            self.present(bookRateVC, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.titleLabel.text = PlayerVC.currentBook?.bookModel.title
        
        tabBar.selectedItem = listenTab
        if UserDefaults.standard.object(forKey: "IS_NIGHT_MODE") != nil {
            self.isNightMode = UserDefaults.standard.bool(forKey: "IS_NIGHT_MODE")
        }
        if isNightMode {
            setNightMode()
        }
        else{
            setDayMode()
        }
        
        
        if bookReader?.isLastPageEnd() ?? false {
            rateButton.isHidden = PlayerVC.currentBook?.bookModel.isLoves ?? false
        }
        
        pageLabel?.text = pageString()
        progressSlider?.setThumbImage(UIImage(), for: .normal)
        progressSlider?.value = bookReader?.currentPageProgress() ?? 0
    }
    
    @IBAction func backTapHandler(_ sender: Any) {
        self.actionDelegate?.bookReaderVCDidClose(sender: self)
    }
    
    @IBAction func moreTapHandler(_ sender: Any) {
        
        let menuVC = Books.VC(.BookMenu) as! BookMenuVC
        menuVC.isNightMode = isNightMode
        menuVC.actionDelegate = self
        menuVC.modalPresentationStyle = .overCurrentContext
        menuVC.modalTransitionStyle = .crossDissolve
        self.present(menuVC, animated: true)

        
        let menuSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        menuSheet.view.tintColor = isNightMode ? UIColor(named: "Brand3Color") : UIColor(named: "Brand2Color")
        menuSheet.setBackgroundColor(isNightMode ? UIColor(named: "MenuColor") : UIColor(named: "WhiteColor"))

       let shareMenuItem = UIAlertAction(title: NSLocalizedString("Share", comment: ""), style: .default, handler: { (UIAlertAction) in

        })

        shareMenuItem.setValue(CATextLayerAlignmentMode.left, forKey:"titleTextAlignment");        shareMenuItem.setValue(isNightMode ? UIImage(named: "ShareMenuItemNight") : UIImage(named: "ShareMenuItemDay"), forKey: "image")
        menuSheet.addAction(shareMenuItem)

        let bookMarksMenuItem = UIAlertAction(title: NSLocalizedString("Go to Bookmark", comment: ""), style: .default, handler: { (UIAlertAction) in

        })

        bookMarksMenuItem.setValue(CATextLayerAlignmentMode.left, forKey:"titleTextAlignment");
        bookMarksMenuItem.setValue(isNightMode ? UIImage(named: "BookmarkMenuItemNight") : UIImage(named: "BookmarkMenuItemDay"), forKey: "image")
        menuSheet.addAction(bookMarksMenuItem)

        let notesMenuItem = UIAlertAction(title: NSLocalizedString("Notes", comment: ""), style: .default, handler: { (UIAlertAction) in

        })

        notesMenuItem.setValue(CATextLayerAlignmentMode.left, forKey:"titleTextAlignment");
       notesMenuItem.setValue(isNightMode ? UIImage(named: "NotesMenuItemNight") : UIImage(named: "NotesMenuItemDay"), forKey: "image")
       menuSheet.addAction(notesMenuItem)

        menuSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (UIAlertAction) in

        }))

        self.present(menuSheet, animated: true, completion: nil)
    }
    
    private func pageString()->String {
        if let page = bookReader?.currentPage(), let totalPages = bookReader?.totalPages() {
                return String(format: "%d/%d", page, totalPages)
        }
        
        return ""
    }
}

extension BookReaderVC: UITabBarDelegate{
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item == listenTab {
            self.actionDelegate?.bookReaderVCDidReader(sender: self)
        }
        else if item == viewTab {
            tabBar.selectedItem = listenTab
            let bookFontsVC = Books.instantiateViewController(withIdentifier: ViewControllerName.BookFontsVC.rawValue) as? BookFontsVC
            if let bookFontsVC = bookFontsVC {
                bookFontsVC.isNightMode = self.isNightMode
                bookFontsVC.modalPresentationStyle = .overCurrentContext
                bookFontsVC.modalPresentationStyle = .custom
                customControllerTransitioning = CustomControllerTransitioning(animationController: bookFontsVC)
                bookFontsVC.transitioningDelegate = customControllerTransitioning
                bookFontsVC.actionDelegate = self
                present(bookFontsVC, animated: true, completion: nil)
            }
        }
        else if item == bookmarkTab {
            if let currentBook = PlayerVC.currentBook, let page = bookReader?.centerViewController?.getCurrentPageItemNumber() {
                spinner?.startAnimating()
                currentBook.setBookmark(page_read: page) {[weak self] (bookmark:BookmarkModel?, message:String?) in
                    guard let self = self else {return}
                    self.spinner?.stopAnimating()
                    
                    if let bookmark = bookmark {
                        if page == bookmark.pageRead, let currentBook = PlayerVC.currentBook {
                            currentBook.bookModel.bookmark = bookmark
                            self.bookmarkImageView?.isHidden = false
                        }
                    }
                    else{
                        self.showAlert(withMessage: message ?? kDefaultErrorMessage)
                    }
                }
            }
            
            tabBar.selectedItem = listenTab
        }
    }
}

extension BookReaderVC: BookFontsVCDelegate {
    func bookFontsVCDidClose(sender: BookFontsVC) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func bookFontsVCDidChangeMode(sender: BookFontsVC, nightMode: Bool) {
        self.isNightMode = nightMode
    }
    
    func bookFontsVCDidChangeFontSize(sender: BookFontsVC, fontSize: Int) {
        self.bookReader?.fontSize = fontSize
    }
    
    func bookFontsVCDidChangeFontType(sender: BookFontsVC, fontType:Int) {
        self.bookReader?.fontType = fontType
    }
}

extension BookReaderVC: StoryboardFolioReaderContrainerDelegate{
    func storyboardFolioReaderContrainerDidTap(sender: StoryboardFolioReaderContrainer) {
        tabBar.isHidden = !tabBar.isHidden
        progressSlider?.isHidden = !tabBar.isHidden
    }
    
    func storyboardFolioReaderContrainerDidAddNote(sender: StoryboardFolioReaderContrainer) {
        
    }
    
    func storyboardFolioReaderContrainerDidChangePage(sender: StoryboardFolioReaderContrainer, page: Int, isLastPageEnd:Bool) {
        if let currentBook = PlayerVC.currentBook?.bookModel, isLastPageEnd {
            rateButton.isHidden = currentBook.isLoves
        }
        else{
            rateButton.isHidden = true
        }
        
        let book = PlayerVC.currentBook?.bookModel
        
        if(book != nil && !book!.isLoves && bookReader!.currentPage() == bookReader!.totalPages()){
            rateButton.isHidden = false
        }else{
            rateButton.isHidden = true
        }
        
        pageLabel?.text = pageString()
        progressSlider?.value = bookReader?.currentPageProgress() ?? 0
        
        if let bookmarkedPage = PlayerVC.currentBook?.bookModel.bookmark?.pageRead {
            bookmarkImageView?.isHidden = (page != bookmarkedPage)
        }
    }
}

extension BookReaderVC: BookRateVCDelegate {
    func bookRateVCDidRate(sender: BookRateVC, isRated:Bool) {
        rateButton.isHidden = isRated
        self.dismiss(animated: true, completion: nil)
    }
    
    func bookRateVCDidClose(sender: BookRateVC) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension BookReaderVC: BookMenuVCDelegate {
    func bookMenuVCDidClose(sender: BookMenuVC) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func bookMenuVCDidShare(sender: BookMenuVC) {
        if let sharedBook = PlayerVC.currentBook?.bookModel {
            let message = "I would share the book ".localized + (sharedBook.title ?? "") + " of " + (sharedBook.author() ?? "")
            var items: [Any] = [message]
            if let publicUrl = URL(string: sharedBook.publicUrl) {
                items.append(publicUrl)
            }

            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            present(ac, animated: true)
        }

        self.dismiss(animated: true, completion: nil)
    }
    
    func bookMenuVCDidBookmark(sender: BookMenuVC) {
        if let bookmarkedPage = PlayerVC.currentBook?.bookModel.bookmark.pageRead {
            bookReader?.showPage(bookmarkedPage)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func bookMenuVCDidNotes(sender: BookMenuVC) {
        self.dismiss(animated: true) {
            if let notesListVC = Books.VC(.NotesList) as? NotesListVC, let currentBook = PlayerVC.currentBook {
                notesListVC.book = currentBook
                notesListVC.actionDelegate = self
                self.navigationController?.pushViewController(notesListVC, animated: true)
            }
        }
    }
}

extension BookReaderVC: NotesListVCDelegate{
    func noteEditingVCDidClose(sender: NotesListVC) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func NoteEditingVCDidChange(sender: NotesListVC, note: NoteModel) {
        
    }
}
