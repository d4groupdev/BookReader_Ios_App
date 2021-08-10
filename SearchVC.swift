
import UIKit

class SearchVC: PlayerVC {
    @IBOutlet weak var searchTextField: SearchTextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterCategoryLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    private var books:[BookMVVM]?
    
    private var currentBookCategory: BookCategoryModel = kDefaultBookCategory {
        didSet {
            self.filterCategoryLabel?.text = currentBookCategory.name
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
        
        navigationController?.isNavigationBarHidden = true
        self.filterCategoryLabel?.text = currentBookCategory.name
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onRefreshHandler), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.registerCell(BookTVCell.self)
        
        getFirstBooks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateContentDependOfPlayer()
    }
    
    @IBAction func filterCategoriesTapHandler(_ sender: Any) {
        let bookCategoriesVC = Books.VC(.BookCategories) as! BookCategoriesVC
        bookCategoriesVC.actionDelegate = self
        bookCategoriesVC.modalPresentationStyle = .fullScreen
        self.present(bookCategoriesVC, animated: true, completion: {})
    }
    
    @objc func onRefreshHandler(refreshControl: UIRefreshControl) {
        refreshControl.endRefreshing()
        getFirstBooks()
    }
    
    override func updateContentWithPlayer(_ view:UIView) {
        super.updateContentWithPlayer(view)
        tableViewBottomConstraint.constant = view.frame.size.height
    }
    
    override func updateContentWithoutPlayer() {
        super.updateContentWithoutPlayer()
        tableViewBottomConstraint.constant = 0
    }
    
    private var searchText:String?
    private var pages:ResponseMetaModel?
    private var booksPage:Int?
    private var booksRequestCancell:(()->())?
    private var requestID:NSUUID?
    private func getBooks(text:String? = nil){
        spinner.startAnimating()
        booksRequestCancell?()
        let requestID = NSUUID()
        self.requestID = requestID
        booksRequestCancell = BookMVVM.getBooks(title: text ?? self.searchTextField.text,
                                                category: (0 < currentBookCategory.id) ? currentBookCategory.name : nil,
                                                page: booksPage)
        {[weak self] (books:[BookMVVM]?, pages:ResponseMetaModel?, message:String?) in
            guard let self = self else {return}
            if requestID != self.requestID {return}
            
            self.spinner.stopAnimating()

            self.booksRequestCancell = nil
            
            if let books = books {
                print(books)
                
                self.books = (nil == self.pages) ? books : (self.books ?? []) + books
                self.pages = pages
                self.tableView.reloadData()
            }
            else{
                self.showAlert(withMessage: message ?? "")
            }
        }
    }
    
    private func getFirstBooks(text:String? = nil){
        booksPage = nil
        pages = nil
        self.searchText = text
        getBooks(text:text)
    }
    
    private func getNextBooks(){
        if pages?.isLast ?? true {return}
        if let pages = pages, let booksPage = booksPage, pages.currentPage != booksPage {return}
        
        booksPage = (booksPage ?? 1) + 1
        getBooks(text: self.searchText)
    }

    deinit {
        booksRequestCancell?()
    }
}

extension SearchVC : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: BookTVCell.self)) as! BookTVCell
        if let bookMVVM = books?[indexPath.row]{
            let book = bookMVVM.bookModel
            cell.authorLabel.text = book.author()
            cell.titleLabel.text = book.title
            cell.rateLabel.text = String(book.rating ?? 0)
            cell.freeView.isHidden = !(book.isFree ?? false)
            cell.isFavorite = book.isFavorites ?? false
            bookMVVM.isFavoriteProcessing() ? cell.favoriteSpinner.startAnimating() : cell.favoriteSpinner.stopAnimating()
            cell.favoriteButton.isHidden = bookMVVM.isFavoriteProcessing()
            cell.actionDelegate = self
            cell.imageURL = book.imageSmall
        }
        
        if let books = books, books.last == books[indexPath.row] {
            DispatchQueue.main.async{[weak self]in self?.getNextBooks()}
        }
        
        return cell
    }
}

extension SearchVC : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let book = self.books?[indexPath.row]{
            self.showBook(book: book).navigationDelegate = self
        }
    }
}

extension SearchVC : BookCategoriesVCDelegate {
    func BookCategoriesVCDidClose(sender: BookCategoriesVC) {
        self.dismiss(animated: true, completion: {})
    }
    
    func BookCategoriesVCDidSelect(sender: BookCategoriesVC, category: BookCategoryModel) {
        currentBookCategory = category
        getFirstBooks()
        self.dismiss(animated: true, completion: {})
    }
}

extension SearchVC : BookTVCellDelegate{
    func bookTVCellDidBookmarked(sender: BookTVCell) {
        if let indexPath = tableView.indexPath(for: sender), let book = books?[indexPath.row]{
            sender.favoriteSpinner.startAnimating()
            sender.favoriteButton.isHidden = true
            let isFavorite = !sender.isFavorite
            book.setFavorite(isFavorite: isFavorite) {[weak self] (success:Bool, message:String?) in
                guard let self = self else {return}
                
                if let cell = self.tableView.cellForRow(at: indexPath) as? BookTVCell {
                    cell.isFavorite = isFavorite
                    cell.favoriteSpinner.stopAnimating()
                    cell.favoriteButton.isHidden = false
                }
            }
        }
    }
}

extension SearchVC: UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let searchText = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        getFirstBooks(text:searchText)
        
        return true
    }
}

extension SearchVC: NavigationDelegate {
    func backAction(_ sender: UIViewController) {
        self.navigationController?.popViewController(animated: true)
        self.navigationController?.isNavigationBarHidden = true
        self.updateContentDependOfPlayer()
    }
}
