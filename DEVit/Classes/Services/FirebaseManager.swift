//
//  FirebaseManager.swift
//  DEVit
//
//  Created by Athanasios Theodoridis on 27/10/2016.
//  Copyright © 2016 devitconf. All rights reserved.
//

import Foundation

import Firebase
import FirebaseDatabase
import ObjectMapper

public class FirebaseManager {
    
    let rootDbRef = FIRDatabase.database().reference()
    let attendeesDbRef = FIRDatabase.database().reference(withPath: "attendees")
    
    // MARK: - Singleton
    static let sharedInstance = FirebaseManager()
    public init() {}
    
    // MARK: - Public Properties
    public var user:FIRUser? = nil
    
    // MARK: - Private Properties
    private lazy var Defaults = {
        return UserDefaults.standard
    }()
    
    private var attendees: [Attendee] = []
    
    public func getAttendeesEmails(withCompletionHandler handler: @escaping (_ attendees: [Attendee]?, _ error: Error? )-> Void) {
        
        l.verbose("Downloading atteendees list")
        
        attendeesDbRef.observeSingleEvent(of: .value, with: { (snapshot) in
        
            guard let attendeesJSON = snapshot.value as? NSArray else {
                handler([], nil)
                return
            }
            
            let attendees = Mapper<Attendee>().mapArray(JSONArray: attendeesJSON as! [[String : Any]])
            self.attendees = attendees!
            
            handler(attendees, nil)
            
        }) { (error) in
            handler(nil, error)
        }
    
    }
    
    public func performLogin(withEmail email: String?, handler: @escaping (_ isLoggedIn: Bool) -> Void) {
        
        l.verbose("Performing login")
        
        getAttendeesEmails { attendees, error in
            
            guard let attendees = attendees,
                    let currentEmail = email,
                    error == nil,
                    attendees.count > 0 else
            {
                    handler(false)
                    return
            }
            
            let tmp = attendees.filter { $0.email! == currentEmail && $0.isLoggedIn == false }
            
            // Atttendee e-mail found
            if tmp.count == 1 {
                
                // Sign-in anonymously just to have a token
                FIRAuth.auth()?.signInAnonymously { (user, error) in
                    
                    l.verbose("Signing in anonymously with Firebase")
                    
                    if (error != nil) {
                        handler(false)
                    } else {
                        self.user = user
                        handler(true)
                    }
                
                }
                
            } else {
                handler(false)
            }
            
        }
        
    }
    
    

       
}
