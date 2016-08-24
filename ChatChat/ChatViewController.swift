/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import Firebase
import JSQMessagesViewController


class ChatViewController: JSQMessagesViewController {
    
    var database : FIRDatabase?
    var ref : FIRDatabaseReference?
    var messages = [JSQMessage]()
    
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    var usersTypingQuery: FIRDatabaseQuery?
    
    var userIsTypingRef: FIRDatabaseReference? // 1
    private var localTyping = false // 2
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            // 3
            localTyping = newValue
            userIsTypingRef!.setValue(newValue)
        }
    }
    
    
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.database = FIRDatabase.database()
    self.ref = self.database?.reference()
    title = "Connected with Ticia!"
    setupBubbles()
  
    
    let button = UIButton()
    button.frame = CGRectMake(0, 0, 51, 51) //won't work if you don't set frame
    button.setImage(UIImage(named: "Ticia"), forState: .Normal)
    button.addTarget(self, action: Selector("fbButtonPressed"), forControlEvents: .TouchUpInside)
    
    let barButton = UIBarButtonItem()
    barButton.customView = button
    self.navigationItem.leftBarButtonItem = barButton
    
    let rightButton = UIButton()
    rightButton.frame = CGRectMake(0, 0, 51, 51)
    rightButton.setTitle("END", forState: .Normal)
    rightButton.addTarget(self, action: (#selector(ChatViewController.endButtonPressed)), forControlEvents: .TouchUpInside)
    
    
    let rightBarButton = UIBarButtonItem()
    rightBarButton.customView = rightButton
    self.navigationItem.rightBarButtonItem = rightBarButton
    
    
    

    }
  
    @IBAction func endButtonPressed(){
        displayAlert("Did Ticia Help?", message: "Guru's are rated and rewarded with Karma points for helping you successfully find a place in Brooklyn to go!")
        
    }
    
    
    func displayAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "No help", style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Killed it!", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    
        
    }
    
    
    
    
    
    override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    observeMessages()
    observeTyping()
    self.ref!.child("messages")

  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
  }
 
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!,
                                     senderDisplayName: String!, date: NSDate!) {
        
        let itemRef = ref!.child("messages").childByAutoId() // 1
        let messageItem = [ // 2
            "text": text,
            "senderId": senderId
        ]
        itemRef.setValue(messageItem) // 3
        
        // 4
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        // 5
        finishSendingMessage()
        isTyping = false

    }
    
    
    private func observeTyping() {
        let typingIndicatorRef = self.ref!.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef!.onDisconnectRemoveValue()
   
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqualToValue(true)
        
        // 2
        usersTypingQuery!.observeEventType(.Value, withBlock: { (data) in
            
            // 3 You're the only typing, don't show the indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            // 4 Are there others typing?
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottomAnimated(true)
        })

    
    }
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    
    
    //Set delegate methods
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    
    //set up bubbles and colors
    private func setupBubbles(){
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(UIColor.blackColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(UIColor.brooklynGuruBlue())
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
        override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
            let message = messages[indexPath.item]
            if message.senderId == senderId{
                return JSQMessagesAvatarImage.avatarWithImage(UIImage(named: "zainOval"))
            }else{
                return JSQMessagesAvatarImage.avatarWithImage(UIImage(named: "Ticia"))
            }
        }
    
    
    
    //add messages
    func addMessage(id: String, text: String) {
        let message = JSQMessage(senderId: id, displayName: "", text: text)
        messages.append(message)
    }
    
    
    
    // set text color for bubble
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
        } else {
            cell.textView!.textColor = UIColor.blackColor()
        }
        
        return cell
    }

    private func observeMessages() {
        // 1
        let messagesQuery = ref?.child("messages").queryLimitedToLast(25)
        // 2
        messagesQuery!.observeEventType(.ChildAdded, withBlock: { (snapshot) in
            // 3
            let id = snapshot.value!["senderId"] as! String
            let text = snapshot.value!["text"] as! String
            
            // 4
            self.addMessage(id, text: text)
            
            // 5
            self.finishReceivingMessage()
        })
    }


}


extension UIColor {
    
    class func brooklynGuruBlue()-> UIColor{
    return UIColor(red: 193/255.0, green: 223/255.0, blue: 211/255.0, alpha: 1)
    
    }

}