//
//  ViewController.swift
//  e-Token
//
//  Created by Léo Sarochar on 31/08/2021.
//

import UIKit
import CoreNFC
import SearchTextField

class ViewController: UIViewController, NFCTagReaderSessionDelegate {
    @IBOutlet weak var UIDLabel: UILabel!
    let loginField = SearchTextField(frame: CGRect(x: 0, y: 90, width: 414, height: 40))

    var mode = 1
    
    var session: NFCTagReaderSession?
    var token: String = ""
    var users: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        print(token)

        loginField.placeholder = "Login"
        loginField.autocorrectionType = UITextAutocorrectionType.no
        loginField.keyboardType = UIKeyboardType.default
        loginField.returnKeyType = UIReturnKeyType.done
        loginField.autocapitalizationType = UITextAutocapitalizationType.none
        loginField.clearButtonMode = UITextField.ViewMode.whileEditing
        loginField.borderStyle = UITextField.BorderStyle.roundedRect
        self.view.addSubview(loginField)
        // Do any additional setup after loading the view.
        let url = URL(string: "https://whatsupdoc.epitech.eu/card")!
        var request = URLRequest(url: url)
        request.setValue("Baerer " + token, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) {(response, data, error) in
            guard let data = data else { return }
            var jsonString = String(data: data, encoding: .utf8)!
            jsonString = jsonString.replacingOccurrences(of: "\"", with: "")
            jsonString = jsonString.replacingOccurrences(of: "[", with: "")
            jsonString = jsonString.replacingOccurrences(of: "]", with: "")
            self.users = jsonString.split(separator: ",").map { String($0) }
            self.loginField.filterStrings(self.users)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    @IBAction func CaptureBtn(_ sender: Any) {
        self.mode = 1
        self.session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        self.session?.alertMessage = "Approchez la carte étudiante sur le haut de l'iPhone"
        self.session?.begin()
        
    }
    @IBAction func VerifBtn(_ sender: Any) {
        self.mode = 2
        self.session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        self.session?.alertMessage = "Approchez la carte étudiante sur le haut de l'iPhone"
        self.session?.begin()
    }
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("Session Begun!")
    }
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("Error with Launching Session")
    }
 
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
     print("Connecting To Tag")
        if tags.count > 1{
            session.alertMessage = "Plus de une carte ont été détectées, réessayez"
            session.invalidate()
        }
        let tag = tags.first!
        session.connect(to: tag) { (error) in
            if nil != error{
                session.invalidate(errorMessage: "La lecture echouée")
            }
            if case let .miFare(sTag) = tag {
                let UID = sTag.identifier.map{ String(format: "%.2hhx", $0)}.joined()
                print("UID:", UID)
                print(sTag.identifier)
                if self.mode == 1 {
                    session.alertMessage = "Carte associée"
                } else {
                    session.alertMessage = "Carte valide"
                }
                session.invalidate()
                DispatchQueue.main.async {
                    if self.mode == 1 {
                        self.UIDLabel.text = "\(UID)"
                        let url = URL(string: "https://whatsupdoc.epitech.eu/card/" + UID)!
                        var request = URLRequest(url: url)
                        request.setValue("Baerer " + self.token, forHTTPHeaderField: "Authorization")
                        request.httpMethod = "PUT"
                        var login = self.loginField.text!
                        login = login.replacingOccurrences(of: "@epitech.eu", with: "")
                        let parameters = "login=" + login + "%40epitech.eu"
                        let postData =  parameters.data(using: .utf8)
                        request.httpBody = postData
                        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main){(response, data, error) in
                            guard let data = data else { return }
                            print(String(data: data, encoding: .utf8)!)
                        }
                        print("Associating " + UID + " with " + login)
                        self.loginField.text = ""
                    } else {
                        let url = URL(string: "https://whatsupdoc.epitech.eu/card/" + UID)!
                        var request = URLRequest(url: url)
                        request.setValue("Baerer " + self.token, forHTTPHeaderField: "Authorization")
                        request.httpMethod = "GET"
                        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) {(response, data, error) in
                            guard let data = data else { return }
                            var jsonString = String(data: data, encoding: .utf8)!
                            jsonString = jsonString.replacingOccurrences(of: "{\"login\":\"", with: "")
                            jsonString = jsonString.replacingOccurrences(of: "\"}", with: "")
                            if jsonString == "{\"error\":\"Wrong Request" {
                                let alert = UIAlertController(title: "Cette carte n'est associée à aucun login", message: "", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "Fermer", style: .cancel, handler: nil))
                                self.present(alert, animated: true)
                                return
                            }
                            let alert = UIAlertController(title: "Cette carte est associée à", message: jsonString, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Supprimer", style: .default, handler: { action in
                                let url = URL(string: "https://whatsupdoc.epitech.eu/card/" + UID)!
                                var request = URLRequest(url: url)
                                request.setValue("Baerer " + self.token, forHTTPHeaderField: "Authorization")
                                request.httpMethod = "DELETE"
                                NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) {(response, data, error) in
                                }
                            }))
                            alert.addAction(UIAlertAction(title: "Fermer", style: .cancel, handler: nil))
                            self.present(alert, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func disconnect(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "token")
        exit(0)
    }
    
}

