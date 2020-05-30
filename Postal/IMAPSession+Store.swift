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
        var givenIndexSet: IndexSet
        
        try select(folder)
        
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
        
        var newFlagList = mailimap_flag_list_new_empty()
        defer { mailimap_flag_list_free(newFlagList) }
        
        if flags.contains(.seen) {
            mailimap_flag_list_add(newFlagList, mailimap_flag_new_seen());
        }
        
        if flags.contains(.answered) {
            let f = mailimap_flag_new_answered();
            mailimap_flag_list_add(newFlagList, f);
        }
        
        if flags.contains(.flagged) {
            let f = mailimap_flag_new_flagged();
            mailimap_flag_list_add(newFlagList, f);
        }
        
        try store(newFlagList, set: set)
    }
    
    
    private func store(_ flags: UnsafeMutablePointer<mailimap_flag_list>?,  set: IMAPIndexes) throws {
        let storeFlagsSet = mailimap_store_att_flags_new_set_flags_silent(flags)
        
        typealias StoreFunc = (_ session: UnsafeMutablePointer<mailimap>?, _ set: UnsafeMutablePointer<mailimap_set>?, _ store_att_flags: UnsafeMutablePointer<mailimap_store_att_flags>?) -> Int32
        var storeFunc: StoreFunc
        
        var indexSet: IndexSet
        switch set {
            case .uid(let indxSet):
                indexSet = indxSet
                storeFunc = mailimap_uid_store
            
            case .indexes(let indxSet):
                indexSet = indxSet
                storeFunc = mailimap_store
        }
        
        let imapSet = indexSet.unreleasedMailimapSet
        defer { mailimap_set_free(imapSet) }
        
        try storeFunc(imap, imapSet, storeFlagsSet).toIMAPError?.check()
    }
}
