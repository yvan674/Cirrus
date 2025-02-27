import Foundation
import Combine
import AVFoundation
import UserNotifications

class TimerViewModel: ObservableObject {
    /// Remaining time, rounded down to nearest minute, in seconds. E.g., 4.2 is rounded to 60 x 4 minutes
    @Published var remainingTime: Int
    
    /// Timer duration in minutes
    @Published var timerDuration: Double
    @Published var timerState: TimerState = .stopped
    private var timer: Timer?
    
    /// Initial duration of the timer, when it was started, for use by the notification system.
    private var initialDurationMinutes: Int
    
    private var center = UNUserNotificationCenter.current()

    init(duration: Double) {
        self.remainingTime = Int(duration * 60)
        self.timerDuration = duration
        self.initialDurationMinutes = Int(duration)
//        prepareAlarmSound()
    }

    func toggleTimer() {
        switch timerState {
        case .running:
            pauseTimer()
        case .paused:
            resumeTimer()
        case .stopped:
            startTimer()
        }
    }

    func startTimer() {
        timer?.invalidate()
        
        initialDurationMinutes = Int(timerDuration)
        print("Initial Duration is set to \(initialDurationMinutes)")
        
        timerState = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.resetTimer()
                self.sendNotification()
//                self.playAlarmSound()
            }
        }
    }

    func pauseTimer() {
        timer?.invalidate()
        timerState = .paused
    }

    func resumeTimer() {
        timerState = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.remainingTime == 1 {
                self.sendNotification()
            }
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.resetTimer()
//                self.playAlarmSound()
            }
        }
    }

    func resetTimer() {
        timerState = .stopped
        timer?.invalidate()
        updateRemainingTime()
    }

    func setPresetTimer(minutes: Int) {
        timer?.invalidate()
        timerState = .stopped
        timerDuration = Double(minutes)
        updateRemainingTime()
    }

    func updateRemainingTime() {
        remainingTime = Int(timerDuration) * 60
    }

    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

//    private func prepareAlarmSound() {
//        if let soundURL = Bundle.main.url(forResource: "alarm", withExtension: "mp3") {
//            do {
//                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
//                audioPlayer?.prepareToPlay()
//            } catch {
//                print("Failed to initialize audio player: \(error)")
//            }
//        }
//    }
//
//    func playAlarmSound() {
//        audioPlayer?.play()
//    }
    
    /// Sends a notification through the notification center, so that even when the audio is silenced,
    /// the user knows that the countdown has ended. This has a delay of 1 second.
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Timer Finished!", arguments: nil)
        
        let minuteString = initialDurationMinutes == 1 ? "minute" : "minutes"
        content.body = NSString.localizedUserNotificationString(forKey: "Your timer for \(initialDurationMinutes) \(minuteString) has ended.", arguments: nil)
        
        content.sound = UNNotificationSound.default
        
        // Trigger the notification _now_
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "CirrusCountdownEnded", content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error: Error?) in
            if let theError = error {
                print("Failed to schedule notification: \(theError)")
            }
        }
    }
}
