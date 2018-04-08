//
//  CodeManager.swift
//  AEXML iOS
//
//  Created by 王乐乐 on 2018/3/12.
//  Copyright © 2018年 AE. All rights reserved.
//

import Foundation
import  Blockly

class CodeManager{
    
    private var codeGeneratorService:CodeGeneratorService = {
        let service = CodeGeneratorService(jsCoreDependencies: [
            "blockly_web/blockly_compressed.js",
            "blockly_web/msg/js/en.js"
            ])
        
        let builder = CodeGeneratorServiceRequestBuilder(
            //This is the name of the JS object that will generate JavaScript code
            jsGeneratorObject: "Blockly.JavaScript")
        // Load  the block defintions for all default blocks
        builder.addJSONBlockDefinitionFiles(fromDefaultFiles: .allDefault)
        // Load the block definitions for our custom sound block
        builder.addJSONBlockDefinitionFiles(["sound_blocks.json"])
        builder.addJSBlockGeneratorFiles([
            // Use JavaScript code generators for the default blocks
            "blockly_web/javascript_compressed.js",
            //Use JavaScript code generators for our custom sound block
            "sound_block_generators.js"
            ])
        //Assign the request builder to the service and cache it so subsequent
        //code generation runs are immediate
        service.setRequestBuilder(builder, shouldCache: true)
        
        return service
    }()
    
    ///Stores JS code for a unique key (ie. a button ID)
    private var savedCode = [String:String]()
    
    func generateCode(forKey key:String, workspaceXML:String)  {
        do {
            self.savedCode[key] = nil
            
            let _ = try codeGeneratorService.generateCode(forWorkspaceXML: workspaceXML, onCompletion: { (requestUUID, code) in
                self.savedCode[key] = code
            }, onError: { (requestUUID, error) in
                print("An error occurred generating code - \(error)\n" +
                    "key: \(key)\n" +
                    "workspaceXML: \(workspaceXML)\n")
            })
        }catch let error {
            print("An error occurred generating code - \(error)\n" +
                "key: \(key)\n" +
                "workspaceXML: \(workspaceXML)\n")
        }
    }
    
    /**
     Retrieves code for a given 'key'
     */
    func code(forKey key:String) -> String? {
        return savedCode[key]
    }
    /**
     析构
     */
    deinit {
        codeGeneratorService.cancelAllRequests()
    }
    
    
    
    
    
    
    
    
    
    
}
