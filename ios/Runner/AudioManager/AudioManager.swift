//
//  AudioManager.swift
//  Runner
//
//  Created by yuanyinhua on 2021/9/30.
//

import Foundation
import AVFoundation
import UIKit

class AudioManager: NSObject, AVAudioPlayerDelegate
{
    static let sharedInstance: AudioManager = { AudioManager() }()
    
    override init() {
        super.init()
        self.setup()
    }
    /// 是否开启后台自动播放无声音乐
    var openBackgroundAudioAutoPlay: Bool = false {
        didSet {
            self.updateOpenBackgroundAudioAutoPlay()
        }
    }
    /// 播放会话
    private var audioSession: AVAudioSession = { AVAudioSession.sharedInstance() }()
    /// 后台播放器
    private var backgroundAudioPlayer: AVAudioPlayer?
    /// 后台运行时间
    private var backgroundTimeInterval: Int = 0
    /// 定时器
    private var timer: Timer?
    /// 监听app状态和会话状态
    private func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(start), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopBackMode), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    /// 开始
    @objc private func start() {
        self.startTimer()
        if self.openBackgroundAudioAutoPlay {
            try? self.audioSession.setActive(false)
            self.backgroundAudioPlayer?.prepareToPlay()
            self.backgroundAudioPlayer?.play()
        }
    }
    
    // 开启定时器
    private func startTimer() {
        if timer == nil {
            timer = Timer.init(timeInterval: 1, target: self, selector: #selector(timerRun), userInfo: nil, repeats: true)
            RunLoop.current.add(timer!, forMode: .default)
        }
        timer?.fireDate = Date.distantPast
    }
    
    // MARK: 声音被打断
    @objc private func audioSessionInterruption(notify: Notification) {
        if !self.openBackgroundAudioAutoPlay {
            return
        }
        guard let userInfo = notify.userInfo else {
            return
        }
        guard let interruptionType: AVAudioSession.InterruptionType = userInfo[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType else {
            return
        }
        // 音乐被打断结束后，重新启动
        if interruptionType == .ended,
           let player = self.backgroundAudioPlayer,
           !player.isPlaying {
            try? self.audioSession.setActive(true)
            player.prepareToPlay()
            player.play()
        }
    }
    
    // MARK: 配置会话
    private func setupAudioSession() {
        do {
            try self.audioSession.setCategory(.playback, options: .mixWithOthers)
            try self.audioSession.setActive(false)
        } catch _ {
            
        }
    }
    
    // MARK: 配置音乐播放器
    private func setupbackgroundAudioPlayer() {
        guard let filePath = Bundle.main.path(forResource: "sound", ofType: "m4a") else {
            return
        }
        let fileURL = URL.init(fileURLWithPath: filePath)
        if self.backgroundAudioPlayer == nil {
            self.backgroundAudioPlayer = try! AVAudioPlayer(contentsOf: fileURL)
        }
        self.backgroundAudioPlayer?.numberOfLoops = -1
        self.backgroundAudioPlayer?.volume = 1
        self.backgroundAudioPlayer?.delegate = self
    }
    
    /// 更新播放器状态
    private func updateOpenBackgroundAudioAutoPlay() {
        if self.openBackgroundAudioAutoPlay {
            self.setupAudioSession()
            self.setupbackgroundAudioPlayer()
        } else {
            guard let player = self.backgroundAudioPlayer else {
                return
            }
            if player.isPlaying {
                player.stop()
            }
            self.backgroundAudioPlayer = nil
            try? self.audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
    
    // 注销定时器
    private func stopTimer() {
        if let timer = self.timer {
            timer.fireDate = Date.distantFuture
            timer.invalidate()
            self.timer = nil
        }
    }
    
    // 记录后台运行时间
    @objc private func timerRun(timer: Timer) {
        self.backgroundTimeInterval += 1
        print("后台活跃时间（秒）：\(self.backgroundTimeInterval)")
        if self.backgroundTimeInterval > 180 {
            self.stopBackMode()
        }
    }
    
    // MARK: 退出后台常驻模式
    @objc private func stopBackMode() {
        self.stopTimer()
        self.backgroundTimeInterval = 0
        if !self.openBackgroundAudioAutoPlay {
            return
        }
        self.backgroundAudioPlayer?.pause()
        try? self.audioSession.setActive(false)
    }
    
    // MARK: AVAudioDelegate
    internal func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
    }
    
    internal func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        
    }
}
