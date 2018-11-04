//
//  ViewController.swift
//  Pantry Party
//
//  Created by Adriel AD Tan on 11/4/18.
//  Copyright © 2018 AD s2dios. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import UserNotifications


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var textView: UITextView!
    weak var imgPickerDelegate: (UINavigationControllerDelegate & UIImagePickerControllerDelegate)?
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imagePicker.delegate = self
        
//        // querying permission for notifications
//        let notificationCenter = UNUserNotificationCenter.current()
//
//        notificationCenter.getNotificationSettings { (settings) in
//            // Do not schedule notifications if not authorized.
//            guard settings.authorizationStatus == .authorized else {return}
//
//            if settings.alertSetting == .enabled {
//                // Schedule an alert-only notification.
//                // alertOnlyFunc()
//            }
//            else {
//                // Schedule a notification with a badge and sound.
//                // badgeAndSoundFunc()
//            }
//        }
    }
    
    @IBAction func clicked(_ sender: Any) {
        textView.text = "clicked"
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            textView.text = "yep theres a photo library"
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        textView.text = "cancelled"
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : AnyObject]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage
            textView.text = "loading..."
            let vision = Vision.vision()
            let textRecognizer = vision.cloudTextRecognizer()
            let img = VisionImage(image: pickedImage)
            
            // recognise
            textRecognizer.process(img) { result, error in
                guard error == nil, let r = result else {
                    // ...
                    self.textView.text = error?.localizedDescription
                    return
                }
                let resultText = r.text
                self.textView.text = resultText
                
                var resultArray = [String]()
                for block in r.blocks {
                    for line in block.lines {
                        for element in line.elements {
                            resultArray.append(element.text.lowercased())
                        }
                    }
                }
                
                let db = Firestore.firestore()
                var item : DocumentReference!
                let d : [String : Any] = ["expiration_date" : 1, "purchase_date" : 2, "expiration_time" : 0]
                db.collection("test").document("apple").setData(d)
                
                for word in resultArray {
                    item = db.collection("items").document(String(word))
                    var dataDescription = Dictionary<String, Any>()
                    item.getDocument { (document, error) in
                        if let document = document, document.exists {
                            let dataDescription = document.data() as! Dictionary<String, Any>
                            
                            let exp = dataDescription["expiration_time"]!
                            //print("Document data: \(dataDescription["exp_time"]!)")
                            
                            let date = Date()
                            //let formatter = DateFormatter()
                            //formatter.dateFormat = "MM.dd.yyyy"
                            //let result = formatter.string(from: date)
                            
                            var exp_days = DateComponents()
                            exp_days.day = exp as? Int
                            let exp_days_from_now = Calendar.current.date(byAdding: exp_days, to: Date())
                            
                            let dict : [String : Any] = ["expiration_date" : exp_days_from_now, "purchase_date" : date, "expiration_time" : exp]
                            db.collection("items").document(String(word)).setData(dict)
//                            let content = UNMutableNotificationContent()
//                            content.title = "Expired" // NSString.localizedUserNotificationStringForKey("Expiration", arguments: nil)
//                            content.body = "milk" // NSString.localizedUserNotificationStringForKey("Hello_message_body", arguments: nil)
//                            content.sound = UNNotificationSound.default
                            // Deliver the notification in five seconds.
//                            self.textView.text = "5 second timer started"
//                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
//                            let request = UNNotificationRequest(identifier: "FiveSecond", content: content, trigger: trigger)
//                            let center = UNUserNotificationCenter.current()
//                            center.add(request) { (error) in
//                                if error != nil {
//                                    // Handle any errors
//                                }
//                            }
                            
                        } else {
                            //print("Document does not exist")
                            //continue
                        }
                    }
                }
            }
            // do STUFF HERE
        }else if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage
            textView.text = "edited"
        }
        
        dismiss(animated: true, completion: nil)
    }
}
