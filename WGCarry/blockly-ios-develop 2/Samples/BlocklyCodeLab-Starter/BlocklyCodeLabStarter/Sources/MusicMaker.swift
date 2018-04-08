/*
 * Copyright 2017 Google Inc. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import JavaScriptCore

@objc protocol MusicMakerJSExports:JSExport{
    static func playSound(_ file:String)
}
/**
 Class exposed to a JS context.
 */
@objc class MusicMaker :NSObject,MusicMakerJSExports{
  /// Keeps track of all sounds currently being played.
  private static var audioPlayers = Set<AudioPlayer>()
 ///store all locks to ensure they stay in memory while the player is playing
    private static var conditionLocks = [String:NSConditionLock]()
  /**
   Play a specific sound.

   This method is exposed to a JS context as `MusicMaker.playSound(_)`.

   - parameter file: The sound file to play.
   */
  static func playSound(_ file: String) {
    guard let player = AudioPlayer(file: file) else {
      return
    }
    //Create a new lock ,and give it a unique ID. 创建一个锁 并给它一个独特的ID
    //Set its condition to '0' to signfiy "playback has not completed yet". 设置它的条件为‘0’ 表示播放回调并未完成
    let uuid = NSUUID().uuidString
    self.conditionLocks[uuid] = NSConditionLock(condition: 0)

    player.completion = { player, successfully in
      // Remove audio player so it is deallocated
      self.audioPlayers.remove(player)
        //Here is where the "resume" magic happens.
        //Playback has finished -- immediately acquire the lock ,to unlock it with its condition set to '1' (signifying "playback is complete"). This effectively unblocks the other thread.
        self.conditionLocks[uuid]?.lock()
        self.conditionLocks[uuid]?.unlock(withCondition: 1)
    }

    if player.play() {
      // Hold a reference to the audio player so it doesn't go out of memory.
      self.audioPlayers.insert(player)
        //Here is where the "pasue" magic happens 这个地方会出现“暂停”的魔法
        //Tell this thread to block execution only until it can acquire the lock when its condition is set to '1'(signifying "playback is complete"). 线程会一直锁着，直到这个锁的条件为1
        self.conditionLocks[uuid]?.lock(whenCondition: 1)
        //Once execution has made it here ,playback has completed . 一旦执行到这里说明播放回调完成
        //Unlock and dispose of the lock , in order to resume JavaScript execution. 解锁，继续恢复执行JavaScript
        self.conditionLocks[uuid]?.unlock()
        self.conditionLocks[uuid] = nil
        
    }
  }
}
