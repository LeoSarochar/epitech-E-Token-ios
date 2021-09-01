//
//  TokenViewController.swift
//  TokenViewController
//
//  Created by Léo Sarochar on 31/08/2021.
//

import UIKit
import WebKit

class TokenViewController: UIViewController {

    @IBOutlet weak var tokenTextField: UITextField!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var validButton: UIButton!
    
    var token = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        let userDefaults = UserDefaults.standard
        
        if keyExists(key: "token") {
            self.token = userDefaults.string(forKey: "token")!
            self.validButton.sendActions(for: .touchUpInside)
            return
        }
        let myURL = URL(string:"https://login.microsoftonline.com/common/oauth2/authorize?response_type=code&client_id=e05d4149-1624-4627-a5ba-7472a39e43ab&redirect_uri=https%3A%2F%2Fintra.epitech.eu%2Fauth%2Foffice365&state=/")
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                if cookie.name == "user" {
                    self.webView.configuration.websiteDataStore.httpCookieStore.delete(cookie)
                }
            }
        }
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)


        // Do any additional setup after loading the view.
    }
    
    func keyExists(key: String) -> Bool {
        guard let _ = UserDefaults.standard.object(forKey: key) else {
         return false;
        }

       return true;
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "title" {
            if let title = webView.title {
                if (title == "Epitech Intra") {
                    webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                        for cookie in cookies {
                            if cookie.name == "user" {
                                self.token = cookie.value
                                let userDefaults = UserDefaults.standard
                                userDefaults.set(self.token, forKey: "token")
                                self.validButton.sendActions(for: .touchUpInside)
                            }
                        }
                    }
                }
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.destination is ViewController {
            let vc = segue.destination as? ViewController
            vc?.token = token
        }
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
