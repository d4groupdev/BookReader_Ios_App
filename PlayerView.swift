import UIKit

protocol PlayerViewDelegate:class {
    func playerViewDidOpen(sender:PlayerView)
    func playerViewDidClose(sender:PlayerView)
    func playerViewDidPlay(sender:PlayerView)
}

class PlayerView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var openButton: UIButton!
    
    @IBOutlet weak var coverImageView: UIImageView!
    
    public static let fixedHeight:CGFloat = 64.0
    
    public weak var actionDlegate:PlayerViewDelegate?
    
    public var isPlayMode:Bool = false {
        didSet{
            playButton?.isSelected = isPlayMode
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXIB()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadXIB()
    }

    public func loadXIB(){
        Bundle.main.loadNibNamed("PlayerView", owner: self, options: nil)
        contentView.frame = self.bounds
        self.addSubview(contentView)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        playButton?.isSelected = isPlayMode
    }
    
    @IBAction func closeTapHandler(_ sender: Any) {
        actionDlegate?.playerViewDidClose(sender: self)
    }
    
    @IBAction func openTapHandler(_ sender: Any) {
        actionDlegate?.playerViewDidOpen(sender: self)
    }

    @IBAction func playTapHandler(_ sender: Any) {
        actionDlegate?.playerViewDidPlay(sender: self)
    }
}
