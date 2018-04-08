//
//  CodeRunner.swift
//  AEXML iOS
//
//  Created by 王乐乐 on 2018/3/12.
//  Copyright © 2018年 AE. All rights reserved.
//

import Foundation
import JavaScriptCore

class CodeRunner {
    private var context:JSContext?
    private let jsThread = DispatchQueue(label: "jsContext")
    init() {
        jsThread.async {
            self.context = JSContext()
            self.context?.exceptionHandler = {context,exception in
                let error = exception?.description ?? "unknown error"
                print("JS Error:\(error)")
            }
            self.context?.setObject(MusicMaker.self, forKeyedSubscript: "MusicMaker" as NSString)
        }
    }
 
    func runJavascriptCode(_ code:String,completion:@escaping ()->())  {
        jsThread.async {
            _ = self.context?.evaluateScript(code)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
