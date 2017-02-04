//  Copyright © 2016  Alex Gibson. oakmonttech@gmail.com
/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import Foundation



extension String {
    
    var lastPathComponent: String {
        
        get {
            return (self as NSString).lastPathComponent
        }
    }
    var pathExtension: String {
        
        get {
            
            return (self as NSString).pathExtension
        }
    }
    var stringByDeletingLastPathComponent: String {
        
        get {
            
            return (self as NSString).deletingLastPathComponent
        }
    }
    var stringByDeletingPathExtension: String {
        
        get {
            
            return (self as NSString).deletingPathExtension
        }
    }
    var pathComponents: [String] {
        
        get {
            
            return (self as NSString).pathComponents
        }
    }
    
    func stringByAppendingPathComponent(_ path: String) -> String {
        
        let nsSt = self as NSString
        
        return nsSt.appendingPathComponent(path)
    }
    
    func stringByAppendingPathExtension(_ ext: String) -> String? {
        
        let nsSt = self as NSString
        
        return nsSt.appendingPathExtension(ext)
    }
}
