//
//  ViewController.swift
//  DemoTwo
//
//  Created by Neel on 14/10/20.
//  Copyright © 2020 Neel. All rights reserved.
//

import UIKit
import SQLite3

struct User {
    let id: Int
    let username: String
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    var sqliteDB: OpaquePointer? = nil
    var users: [User] = [User]()
    
    @IBOutlet weak var tableView: UITableView?
    @IBAction func addRowTapped(_ sender: UIButton) {
        
        let alertController = UIAlertController(title: "Add Name", message: nil, preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField(configurationHandler: nil)
        
        let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default) { (action) in
            
            let usernameString = alertController.textFields?[0].text
            guard let username = usernameString else {
                NSLog("Could not get username string from alert controller")
                return
            }
            
            var preparedStatement: OpaquePointer? = nil
            let sqliteStatement = "INSERT INTO usernames (username) values ('\(username)')"
            
            if sqlite3_prepare(self.sqliteDB, sqliteStatement, -1, &preparedStatement, nil) == SQLITE_OK {
                
                if sqlite3_step(preparedStatement) == SQLITE_DONE {
                    print("Inserted: \(username)")
                }
            }
            
            sqlite3_finalize(preparedStatement)
            
            self.populateData()
            self.tableView?.reloadData()
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var url: URL? = nil
        
        do {
            let baseURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            url = baseURL.appendingPathComponent("database.sqlite")
        } catch {
            NSLog(error.localizedDescription)
        }
        
        if let dbURL = url {
            if sqlite3_open_v2(dbURL.absoluteString.cString(using: String.Encoding.utf8), &sqliteDB, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil) == SQLITE_OK {
                
                let sqliteStatement = "CREATE TABLE IF NOT EXISTS usernames (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT);"
                
                let error: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>? = nil
                
                if sqlite3_exec(sqliteDB, sqliteStatement, nil, nil, error) == SQLITE_OK {
                    print("created/opened table")
                }
                
            }
        }
        
        populateData()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = "\(self.users[indexPath.row].id): \(self.users[indexPath.row].username)"
        return cell
    }
    
    private func populateData() {
                
        var preparedStatement: OpaquePointer? = nil
        let sqliteStatement = "SELECT * FROM usernames"
        
        self.users = [User]()
        if sqlite3_prepare(self.sqliteDB, sqliteStatement, -1, &preparedStatement, nil) == SQLITE_OK {
            
            while sqlite3_step(preparedStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(preparedStatement, 0)
                let usernameText: UnsafePointer<UInt8> = sqlite3_column_text(preparedStatement, 1)
                
                let usernameString = String(cString: usernameText)
                
                let newUser = User(id: Int(id), username: usernameString)
                self.users.append(newUser)
            }
            
        }
        
        sqlite3_finalize(preparedStatement)
    
    }
    

}

