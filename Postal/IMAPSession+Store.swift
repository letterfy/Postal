//
//  The MIT License (MIT)
//
//  Copyright (c) 2017 Snips
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import libetpan

public enum IMAPStoreFlagsRequestKind: Int {
    case IMAPStoreFlagsRequestKindAdd = 0
    case IMAPStoreFlagsRequestKindRemove = 1
    case IMAPStoreFlagsRequestKindSet = 2
}

extension IMAPSession {
    func storeFlagsAndCustomFlags(_ folder: String, set: IMAPIndexes, kind: IMAPStoreFlagsRequestKind, flags: MessageFlag, customFlags: Array<String>) throws {
        // let unsafeSet: UnsafeMutablePointer<mailimap_set> = UnsafeMutablePointer<mailimap_set>.
        //let unsafeFlags: UnsafeMutablePointer<mailimap_store_att_flags> = UnsafeMutablePointer<mailimap_store_att_flags>()
        let flagList: UnsafeMutablePointer<mailimap_flag_list>? = UnsafeMutablePointer<mailimap_flag_list>.init(bitPattern: 0)
        var storeAttFlags: UnsafeMutablePointer<mailimap_store_att_flags>? = nil
        let givenIndexSet: IndexSet
        
        typealias StoreFunc = (_ session: UnsafeMutablePointer<mailimap>?, _ set: UnsafeMutablePointer<mailimap_set>?, _ store_att_flags: UnsafeMutablePointer<mailimap_store_att_flags>?) -> Int32
        var storeFunc: StoreFunc
        
        switch set {
            case .uid(let indexSet):
                givenIndexSet = indexSet
                storeFunc = mailimap_uid_store
            
            case .indexes(let indexSet):
                givenIndexSet = indexSet
                storeFunc = mailimap_store
        }
        
        if flags.contains(.seen) {
            let f = mailimap_flag_new_seen();
            mailimap_flag_list_add(flagList, f);
        }
        
        if flags.contains(.answered) {
            let f = mailimap_flag_new_answered();
            mailimap_flag_list_add(flagList, f);
        }
        
        if flags.contains(.flagged) {
            let f = mailimap_flag_new_flagged();
            mailimap_flag_list_add(flagList, f);
        }
        
        for indexSet in givenIndexSet.enumerate(batchSize: configuration.batchSize) {
            let imapSet = indexSet.unreleasedMailimapSet
            defer { mailimap_set_free(imapSet) }
            
            switch kind {
                case .IMAPStoreFlagsRequestKindAdd:
                    storeAttFlags = mailimap_store_att_flags_new_remove_flags_silent(flagList)
                    break;
                
                case .IMAPStoreFlagsRequestKindRemove:
                    storeAttFlags = mailimap_store_att_flags_new_remove_flags_silent(flagList)
                    break;
                
                case .IMAPStoreFlagsRequestKindSet:
                    storeAttFlags = mailimap_store_att_flags_new_set_flags_silent(flagList)
                    break;
            }
            
            try storeFunc(self.imap, imapSet, storeAttFlags).toIMAPError?.check()
        }
        
        
        mailimap_store_att_flags_free(storeAttFlags)
    }
}
