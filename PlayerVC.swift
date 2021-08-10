
import UIKit
import AVFoundation

class PlayerVC: UIViewController, UpdateContentDependOfPlayerProtocol {
    public static var currentPlayerView: PlayerView?
    public static var player:AVPlayer?
    public static var playerObserver:Any?
    public static var currentBook:BookMVVM?
    public static var playerReaderPageVC:PlayerReaderPageVC?
    
    public static let kAudioSaveHistoryPeriod = 200
    private static let kAudioDefaultSpeedMode = 2
    public static var audioSaveHistoryPeriod:Int = kAudioSaveHistoryPeriod
    public static var currentSpeedMode:Int = kAudioDefaultSpeedMode
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let currentPlayer = PlayerVC.currentPlayerView {
            currentPlayer.actionDlegate = self
            currentPlayer.frame = self.playerFrame()
            UIApplication.shared.keyWindow?.bringSubviewToFront(currentPlayer)
            updateContentWithPlayer(currentPlayer)
        }
        else{
            updateContentWithoutPlayer()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        PlayerVC.currentPlayerView?.isHidden = false
        PlayerVC.currentPlayerView?.actionDlegate = self
    }

    static let kShiftPlayerView:CGFloat = 0.0
    func playerFrame(height:CGFloat = (MainTabBarVC.main?.tabBar.frame.minY ?? 0) - kShiftPlayerView) -> CGRect {
        let window = UIApplication.shared.keyWindow!
        return CGRect(x: 0, y: height - PlayerView.fixedHeight, width: window.bounds.size.width, height: PlayerView.fixedHeight)
    }
    
    
    func bookPlayerRollDown(){
        if let playerReaderPageType = type(of: self).playerReaderPageVC?.getCurrentType() {
            if let player = PlayerVC.currentPlayerView {
                player.playButton.isHidden = (playerReaderPageType == .reader)
                updateContentWithPlayer(player)
            }
        }
    }
    
    let skipTime = 10.0
    func skipBefore(){
        if let currentTime = type(of: self).player?.currentTime() {
            type(of: self).player?.seek(to: CMTime(seconds: currentTime.seconds - skipTime, preferredTimescale: currentTime.timescale))
        }
    }
    
    func skipAfter(){
        if let currentTime = type(of: self).player?.currentTime() {
            type(of: self).player?.seek(to: CMTime(seconds: currentTime.seconds + skipTime, preferredTimescale: currentTime.timescale))
        }
    }
    
    func updateContentWithPlayer(_ view:UIView){
        // for succesors
    }

    func updateContentWithoutPlayer(){
        // for succesors
    }
}

extension PlayerVC {
    public func showPlayer(underView view:UIView?){
        
    }
    
    public func hidePlayer(){
        
    }
    
    public func playerUp(){
        
    }
    
    public func playerDown(){
        
    }
    
    public func openPlayer(withBook book:AnyObject?){
       closePlayer()

        if let book = book as? String  {
            PlayerVC.currentBook = book
           let url = URL(fileURLWithPath: book)
            let player = AVPlayer(url: url)
            PlayerVC.player = player
            let playerView = PlayerView(frame: self.playerFrame())
            PlayerVC.currentPlayerView = playerView
            playerView.actionDlegate = self
            UIApplication.shared.keyWindow!.addSubview(playerView)

            player.play()
            playerView.isPlayMode = true
        }
    }
    
    public func closePlayer(){
        if let currentPlayer = PlayerVC.currentPlayerView {
            currentPlayer.actionDlegate = nil
            currentPlayer.removeFromSuperview()
            updateContentWithoutPlayer()
        }
        
        type(of:self).playerReaderPageVC?.actionDelegate = nil
        type(of:self).playerReaderPageVC = nil
        
        type(of: self).currentPlayerView = nil;
        type(of: self).currentBook = nil
        
        if let playerObserver = type(of:self).playerObserver {
            type(of: self).player?.removeTimeObserver(playerObserver)
        }
        
        type(of:self).playerObserver = nil
        type(of: self).player = nil
        type(of: self).currentSpeedMode = type(of: self).kAudioDefaultSpeedMode
   }
    
    public func play(){
        type(of: self).player?.play()
        type(of: self).player?.rate = kPlayerSpeeds[type(of: self).currentSpeedMode]
        type(of: self).currentPlayerView?.isPlayMode = true
        
        if let time = type(of: self).player?.currentTime().seconds, let duration = type(of: self).player?.currentItem?.duration.seconds, 0 < duration {
            let percent = time / duration * 100.0
            type(of: self).currentBook?.bookModel.history?.timeAudio = time
            type(of: self).currentBook?.saveHistory(time_audio: time, audioPercent: percent) { (success:Bool, message:String?) in
                if success {print("-Play---------Second " + String(time) + " is saved OK")}
                else {print("-Play---------Fail of saving of second " + String(time) + " with message: <" + (message ?? "") + ">")}
            }
        }
    }
    
    public func pause(){
        type(of: self).player?.pause()
        type(of: self).currentPlayerView?.isPlayMode = false
        
        if let time = type(of: self).player?.currentTime().seconds, let duration = type(of: self).player?.currentItem?.duration.seconds, 0 < duration {
            let percent = time / duration * 100.0
            type(of: self).currentBook?.bookModel.history?.timeAudio = time
            type(of: self).currentBook?.saveHistory(time_audio: time, audioPercent: percent) { (success:Bool, message:String?) in
                if success {print("-Pause---------Second " + String(time) + " is saved OK")}
                else {print("-Pause---------Fail of saving of second " + String(time) + " with message: <" + (message ?? "") + ">")}
            }
        }
    }
    
}

extension PlayerVC:PlayerViewDelegate {
    
    func playerViewDidOpen(sender: PlayerView) {
        type(of: self).currentPlayerView?.isHidden = true
        
        if nil == type(of:self).playerReaderPageVC {
            let bookPlayerVC = Books.VC(.PlayerReaderPage) as! PlayerReaderPageVC
            bookPlayerVC.isPlayMode = (0 < (PlayerVC.player?.rate ?? 0))
            bookPlayerVC.actionDelegate = self
            bookPlayerVC.modalPresentationStyle = .fullScreen
            type(of:self).playerReaderPageVC = bookPlayerVC
        }
        
        if let playerReaderPageVC = type(of:self).playerReaderPageVC {
            playerReaderPageVC.isPlayMode = (0 < (PlayerVC.player?.rate ?? 0))
            playerReaderPageVC.actionDelegate = self
            self.present(playerReaderPageVC, animated: true, completion: {})
        }
    }
    
    func playerViewDidClose(sender: PlayerView) {
        self.closePlayer()
    }
    
    func playerViewDidPlay(sender: PlayerView) {
        if sender.isPlayMode {
            self.pause()
        }
        else{
            self.play()
        }
    }
}

extension PlayerVC: PlayerReaderPageVCDelegate{
    func playerReaderPageVCDidSkipBefor(sender: PlayerReaderPageVC) {
        skipBefore()
    }
    
    func playerReaderPageVCDidSkipAfter(sender: PlayerReaderPageVC) {
        skipAfter()
    }
    
    func playerReaderPageVCDidChangeCurrentSpeedMode(sender: PlayerReaderPageVC, currentSpeedMode: Int) {
        type(of: self).currentSpeedMode = currentSpeedMode
        let isPlaying = (0 < (PlayerVC.player?.rate ?? 0))
        if isPlaying {
            type(of: self).player?.rate = kPlayerSpeeds[currentSpeedMode]
        }
    }
    
    func playerReaderPageVCDidChangeCurrentTime(sender: PlayerReaderPageVC, currentTime: Float) {
        type(of: self).player?.seek(to: CMTime(seconds: Double(currentTime), preferredTimescale: 60))
    }
    
    func playerReaderPageVCDidClose(sender: PlayerReaderPageVC) {
        bookPlayerRollDown()
        
        if !sender.readerCanClose {
            PlayerVC.currentPlayerView?.isHidden = false
            PlayerVC.currentPlayerView?.alpha = 0
            UIView.animate(withDuration: 0.6) {
                PlayerVC.currentPlayerView?.alpha = 1
            }
        }
        
        self.dismiss(animated: true, completion: {})
    }
    
    func playerReaderPageVCDidPlay(sender: PlayerReaderPageVC) {
            let isPlaying = (0 < (PlayerVC.player?.rate ?? 0))
            sender.isPlayMode = !isPlaying
            if isPlaying {
                self.pause()
            }
            else{
                self.play()
            }
        }

    func playerReaderPageVCDidReader(sender: PlayerReaderPageVC) {
        
        }
}
