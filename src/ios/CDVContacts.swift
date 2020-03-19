//
//  CDVContacts.swift
//  Timothy Holbrook
//
//
/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

import Foundation
import Contacts
import ContactsUI
import UIKit

class CDVContactsPicker: CNContactPickerViewController {
    var callbackId: String = ""
    var allowsEditing: Bool?
    var fields: [Any] = ["*"]
    var pickedContactDictionary: [AnyHashable: Any] = [AnyHashable: Any]()
}

class CDVNewContactsController: CNContactViewController {
    var callbackId: String = ""
}

@objc(CDVContacts) class CDVContacts: CDVPlugin, CNContactViewControllerDelegate, CNContactPickerDelegate {
    
    //    var status: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    
    static let allContactKeys: [CNKeyDescriptor] = [CNContactIdentifierKey as CNKeyDescriptor,
                                                    CNContactNicknameKey as CNKeyDescriptor,
                                                    CNContactGivenNameKey as CNKeyDescriptor,
                                                    CNContactFamilyNameKey as CNKeyDescriptor,
                                                    CNContactMiddleNameKey as CNKeyDescriptor,
                                                    CNContactNamePrefixKey as CNKeyDescriptor,
                                                    CNContactNameSuffixKey as CNKeyDescriptor,
                                                    CNContactPhoneNumbersKey as CNKeyDescriptor,
                                                    CNContactTypeKey as CNKeyDescriptor]
    
    // overridden to clean up Contact statics
    override func onAppTerminate() {
        // NSLog(@"Contacts::onAppTerminate");
    }
    
    func checkContactPermission(command: CDVInvokedUrlCommand, accessGrantedCallback: @escaping (CDVInvokedUrlCommand)->()) {
        // if no permissions granted try to request them first
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .notDetermined {
            CNContactStore().requestAccess(for: CNEntityType.contacts, completionHandler: {(_ granted: Bool, _ error: Error?) -> Void in
                if granted {
                    print("Access granted.")
                    accessGrantedCallback(command)
                }
            })
        }
    }
    
    // iPhone only method to create a new contact through the GUI
    func newContact(_ command: CDVInvokedUrlCommand) {
        checkContactPermission(command: command, accessGrantedCallback: { (command) in
            let callbackId: String = command.callbackId
            let weakSelf: CDVContacts? = self
            
            if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                let npController = CDVNewContactsController()
                npController.contactStore = CNContactStore()

                npController.delegate = self
                npController.callbackId = callbackId
                let navController = UINavigationController(rootViewController: npController as UIViewController)
                weakSelf?.viewController.present(navController, animated: true) {() -> Void in }
            }
        })
    }
    
    func existsValue(_ dict: [AnyHashable: Any], val expectedValue: String, forKey key: String) -> Bool {
        let val = dict[key]
        var exists = false
        if val != nil {
            exists = ((val as? String)?.caseInsensitiveCompare(expectedValue) == ComparisonResult.orderedSame)
        }
        return exists
    }
    
    func displayContact(_ command: CDVInvokedUrlCommand) {
        checkContactPermission(command: command, accessGrantedCallback: { (command) in
            let callbackId: String = command.callbackId
            let weakSelf: CDVContacts? = self
            
            if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                let recordID = command.argument(at: 0) as? String
                var lookupError: Bool = true

                if let id = recordID {
                    if let rec: CNContact = try? CNContactStore().unifiedContact(withIdentifier: id, keysToFetch: CDVContacts.allContactKeys) {
                        let options = command.argument(at: 1, withDefault: NSNull()) as! [AnyHashable: Any]
                        let bEdit: Bool = (options.count > 0) ? false : (weakSelf?.existsValue(options, val: "true", forKey: "allowsEditing"))!

                        lookupError = false
                        let personController = CDVDisplayContactViewController(for: rec)
                        personController.delegate = self
                        personController.allowsEditing = false
                        // create this so DisplayContactViewController will have a "back" button.
                        let parentController = UIViewController()
                        let navController = UINavigationController(rootViewController: parentController)
                        navController.pushViewController(personController, animated: true)
                        self.viewController.present(navController, animated: true) {() -> Void in }
                        if bEdit {
                            // create the editing controller and push it onto the stack
                            let editPersonController = CNContactViewController(for: rec)
                            editPersonController.delegate = self
                            editPersonController.allowsEditing = true
                            navController.pushViewController(editPersonController, animated: true)
                        }
                    }
                }
                if lookupError {
                    // no record, return error
                    let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: CDVContactError.UNKNOWN_ERROR.rawValue)
                    weakSelf?.commandDelegate.send(result, callbackId: callbackId)
                }
            } else {
                // permission was denied or other error - return error
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageToErrorObject: CDVContactError.UNKNOWN_ERROR.rawValue)
                weakSelf?.commandDelegate.send(result, callbackId: callbackId)
                return
            }
        })
    }
    
//    func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
//        checkContactPermission()
//        return true
//    }
    
    func chooseContact(_ command: CDVInvokedUrlCommand) {
        checkContactPermission(command: command, accessGrantedCallback: { (command) in
            let weakSelf: CDVContacts? = self
            let callbackId: String = command.callbackId
            let commandFields = command.argument(at: 0, withDefault: [Any]()) as? [Any]
            let commandOptions = command.argument(at: 1, withDefault: [AnyHashable: Any]()) as? [AnyHashable: Any]

            let pickerController = CDVContactsPicker()
            pickerController.delegate = self
            pickerController.callbackId = callbackId
            pickerController.pickedContactDictionary = [
                kW3ContactId : ""
            ]

            //        pickerController.predicateForSelectionOfContact = NSPredicate(value: true)

            if let fields = commandFields {
                pickerController.fields = fields
                for field in fields {
                    if let string = field as? String {
                        if string == "emails" {
                            pickerController.displayedPropertyKeys = [CNContactEmailAddressesKey];
                            pickerController.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0 || phoneNumbers.@count > 0")
                            pickerController.predicateForSelectionOfContact = NSPredicate(format: "emailAddresses.@count == 1")
                            pickerController.predicateForSelectionOfProperty = NSPredicate(format: "key == 'emailAddresses'")
                        }
                    }
                }
            }
            if let options = commandOptions {
                pickerController.allowsEditing = (options.count > 0) ? false : weakSelf?.existsValue(options, val: "true", forKey: "allowsEditing")
            } else {
                pickerController.allowsEditing = false
            }

            UISearchBar.appearance().isHidden = true
            weakSelf?.viewController.present(pickerController, animated: true) {() -> Void in }
        })
    }
    
    func pickContact(_ command: CDVInvokedUrlCommand) {
        checkContactPermission(command: command, accessGrantedCallback: { (command) in
            let weakSelf: CDVContacts? = self
            let newCommand = CDVInvokedUrlCommand(arguments: command.arguments, callbackId: command.callbackId, className: command.className, methodName: command.methodName)
            // First check for Address book permissions
            let status = CNContactStore.authorizationStatus(for: .contacts)
            if status == .authorized {
                if let cmd = newCommand {
                    weakSelf?.chooseContact(cmd)
                }
                return
            }
            let errorResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: CDVContactError.PERMISSION_DENIED_ERROR.rawValue)
            // if the access is already restricted/denied the only way is to fail
            if status == .restricted || status == .denied {
                weakSelf?.commandDelegate.send(errorResult, callbackId: command.callbackId)
                return
            }
            // if no permissions granted try to request them first
            if status == .notDetermined {
                CNContactStore().requestAccess(for: .contacts, completionHandler: {(_ granted: Bool, _ error: Error?) -> Void in
                    if granted {
                        if let cmd = newCommand {
                            weakSelf?.chooseContact(cmd)
                        }
                        return
                    }
                    weakSelf?.commandDelegate.send(errorResult, callbackId: command.callbackId)
                })
            }
        })
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        // return contactId or invalid if none picked
        let ctctPicker: CDVContactsPicker = picker as! CDVContactsPicker
        
        if let allowEditing = ctctPicker.allowsEditing {
            if allowEditing {
                // get the info after possible edit
                // if we got this far, user has already approved/ disapproved contactStore access
                if let id = ctctPicker.pickedContactDictionary[kW3ContactId] as? String {
                    if let person: CNContact = try? CNContactStore().unifiedContact(withIdentifier: id, keysToFetch: CDVContacts.allContactKeys) {
                        let pickedContact = CDVContact(fromCNContact: person)
                        let returnFields = CDVContact.self.calcReturnFields(ctctPicker.fields)
                        ctctPicker.pickedContactDictionary = pickedContact.toDictionary(returnFields)
                    }
                }
            }
        }
        
        let recordId = ctctPicker.pickedContactDictionary[kW3ContactId] as? String
        picker.presentingViewController?.dismiss(animated: true, completion: {() -> Void in
            var result: CDVPluginResult? = nil
            let invalidId = ""
            if (recordId == invalidId) {
                result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: CDVContactError.OPERATION_CANCELLED_ERROR.rawValue)
            }
            else {
                result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ctctPicker.pickedContactDictionary)
            }
            self.commandDelegate.send(result, callbackId: ctctPicker.callbackId)
        })
    }
    
    // Called after a person has been selected by the user.
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let ctctPicker = picker as! CDVContactsPicker
        
        if (ctctPicker.allowsEditing == nil || ctctPicker.allowsEditing == true) {
            let contact = contacts[0]
            let pickedId = contact.identifier
            
            let personController = CNContactViewController(for: contact)
            personController.delegate = self
            personController.allowsEditing = ctctPicker.allowsEditing ?? false
            // store id so can get info in peoplePickerNavigationControllerDidCancel
            ctctPicker.pickedContactDictionary = [
                kW3ContactId : pickedId
            ]
            picker.navigationController?.pushViewController(personController, animated: true)
        } else {
            // Retrieve and return pickedContacts information
            var returnContacts = [[AnyHashable: Any]]()
            var result: [CDVContact] = [CDVContact]()
            
            
            for contact in contacts {
                result.append(CDVContact(fromCNContact: contact))
            }
            
            let returnFields = CDVContact.self.calcReturnFields(ctctPicker.fields)
            
            if (result.count > 0) {
                // convert to JS Contacts format and return in callback
                // - returnFields  determines what properties to return
                autoreleasepool {
                    let count = Int(result.count)
                    for i in 0..<count {
                        returnContacts.append(result[i].toDictionary(returnFields))
                    }
                }
            }
            
            ctctPicker.presentingViewController?.dismiss(animated: true, completion: {() -> Void in
                // return found contacts (array is empty if no contacts found)
                let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: returnContacts)
                self.commandDelegate.send(result, callbackId: ctctPicker.callbackId)
            })
        }
    }
    
    // Called after a property has been selected by the user.
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        let ctctPicker = picker as! CDVContactsPicker
        let pickedContact = CDVContact(fromCNContact: contactProperty.contact)
        let returnFields = CDVContact.self.calcReturnFields(ctctPicker.fields)
        ctctPicker.pickedContactDictionary = pickedContact.toDictionary(returnFields)
        if contactProperty.key == CNContactEmailAddressesKey {
            if let emails = ctctPicker.pickedContactDictionary[kW3ContactEmails] as? NSArray {
                for email in emails {
                    if let e = email as? [AnyHashable:Any] {
                        if let val = contactProperty.value as? String {
                            if  let emailValue = e[kW3ContactFieldValue] as? String {
                                if emailValue == val {
                                    ctctPicker.pickedContactDictionary[kW3ContactEmails] = [email]
                                }
                            }
                        }
                    }
                }
            }
        }
        ctctPicker.presentingViewController?.dismiss(animated: true, completion: {() -> Void in
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ctctPicker.pickedContactDictionary)
            self.commandDelegate.send(result, callbackId: ctctPicker.callbackId)
        })
    }
    
    @objc func search(_ command: CDVInvokedUrlCommand) {
        checkContactPermission(command: command, accessGrantedCallback: { (command) in
            let callbackId: String = command.callbackId
            let commandFields = command.argument(at: 0) as? [Any]
            let findOptions = command.argument(at: 1, withDefault: [AnyHashable: Any]()) as? [AnyHashable: Any]
            if let fields = commandFields {
                let weakSelf: CDVContacts? = self
                weakSelf?.commandDelegate.run(inBackground: {() -> Void in
                    if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                        // get the findOptions values
                        var multiple = false
                        // default is false
                        var filter: String = ""
                        var desiredFields: [Any] = ["*"]
                        if let opts = findOptions {
                            if (opts.count > 0) {
                                var value: Any? = nil
                                let filterValue = opts["filter"]
                                if let f = filterValue as? String {
                                    filter = f
                                }
                                value = opts["multiple"]
                                if (value is NSNumber) {
                                    // multiple is a boolean that will come through as an NSNumber
                                    multiple = (value as? NSNumber) != 0
                                    // NSLog(@"multiple is: %d", multiple);
                                }
                                if let dFields = opts["desiredFields"] as? [Any] {
                                    // return all fields if desired fields are not explicitly defined
                                    if dFields.count > 0 {
                                        desiredFields = dFields
                                    }
                                }
                            }
                        }
                        let searchFields = CDVContact.self.calcReturnFields(fields)
                        let returnFields = CDVContact.self.calcReturnFields(desiredFields)
                        var matches: [CDVContact] = [CDVContact]()
                        if (filter == "") {
                            // get all records
                            let fetchRequest = CNContactFetchRequest.init(keysToFetch: CDVContacts.allContactKeys)
                            fetchRequest.predicate = nil
                            try? CNContactStore().enumerateContacts(with: fetchRequest, usingBlock: {(contact: CNContact, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                                // create Contacts and put into matches array
                                // doesn't make sense to ask for all records when multiple == NO but better check
                                if !multiple {
                                    if matches.count == 1 {
                                        return
                                    }
                                }
                                matches.append(CDVContact(fromCNContact: contact))
                            })
                        } else {
                            let fetchRequest = CNContactFetchRequest.init(keysToFetch: CDVContacts.allContactKeys)
                            fetchRequest.predicate = nil
                            try? CNContactStore().enumerateContacts(with: fetchRequest, usingBlock: {(contact: CNContact, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                                let testContact = CDVContact(fromCNContact: contact)
                                let match = testContact.foundValue(filter, inFields: searchFields)
                                if match {
                                    matches.append(testContact)
                                }
                            })
                        }
                        var returnContacts = [[AnyHashable: Any]]()
                        if (matches.count > 0) {
                            // convert to JS Contacts format and return in callback
                            // - returnFields  determines what properties to return
                            autoreleasepool {
                                let count = multiple == true ? Int(matches.count) : 1
                                for i in 0..<count {
                                    let contact = matches[i].toDictionary(returnFields)
                                    if contact[NSNull()] == nil {
                                        returnContacts.append(contact)
                                    }
                                }
                            }
                        }
                        // return found contacts (array is empty if no contacts found)
                        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: returnContacts)
                        weakSelf?.commandDelegate.send(result, callbackId: callbackId)
                        // NSLog(@"findCallback string: %@", jsString);
                    } else {
                        // permission was denied or other error - return error
                        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageToErrorObject: CDVContactError.UNKNOWN_ERROR.rawValue)
                        weakSelf?.commandDelegate.send(result, callbackId: callbackId)
                        return
                    }
                })
            }
            return
        })
    }
    
    func save(_ command: CDVInvokedUrlCommand) {
        checkContactPermission(command: command, accessGrantedCallback: { (command) in
            let callbackId: String = command.callbackId
            let commandContactDict = command.argument(at: 0) as? [AnyHashable: Any]

            let weakSelf: CDVContacts? = self
            if let contactDict = commandContactDict {
                weakSelf?.commandDelegate.run(inBackground: {() -> Void in
                    var result: CDVPluginResult? = nil

                    if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                        var bIsError = false
                        var bSuccess = false
                        var bUpdate = false
                        var errCode: CDVContactError = CDVContactError.UNKNOWN_ERROR
                        if let cId = contactDict[kW3ContactId] as? String {
                            var aContact: CDVContact? = nil
                            if let rec = try? CNContactStore().unifiedContact(withIdentifier: cId, keysToFetch: CDVContacts.allContactKeys) {
                                aContact = CDVContact(fromCNContact: rec)
                                bUpdate = true
                            }
                            if aContact == nil {
                                aContact = CDVContact()
                            }
                            bSuccess = aContact?.setFromContactDict(contactDict, asUpdate: bUpdate) ?? false
                            if bSuccess {
                                if !bUpdate {
                                    if let record = aContact?.mutableRecord {
                                        let saveRequest = CNSaveRequest()
                                        saveRequest.add(record, toContainerWithIdentifier: nil)
                                        do {
                                            try CNContactStore().execute(saveRequest)
                                            bSuccess = true
                                        } catch {
                                            bSuccess = false
                                        }
                                    } else {
                                        bSuccess = false
                                    }
                                }
                                if bSuccess && bUpdate {
                                    if let record = aContact?.mutableRecord {
                                        let saveRequest = CNSaveRequest()
                                        saveRequest.update(record)
                                        do {
                                            try CNContactStore().execute(saveRequest)
                                            bSuccess = true
                                        } catch {
                                            bSuccess = false
                                        }
                                    } else {
                                        bSuccess = false
                                    }
                                }
                                if !bSuccess {
                                    // need to provide error codes
                                    bIsError = true
                                    errCode = CDVContactError.IO_ERROR
                                }
                                else {
                                    // give original dictionary back?  If generate dictionary from saved contact, have no returnFields specified
                                    // so would give back all fields (which W3C spec. indicates is not desired)
                                    // for now (while testing) give back saved, full contact
                                    let newContact = aContact?.toDictionary(CDVContact.defaultFields())
                                    // NSString* contactStr = [newContact JSONRepresentation];
                                    result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: newContact)
                                }
                            } else {
                                bIsError = true
                                errCode = CDVContactError.IO_ERROR
                            }
                            if bIsError {
                                result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: (errCode).rawValue)
                            }
                            if result != nil {
                                weakSelf?.commandDelegate.send(result, callbackId: callbackId)
                            }
                        }
                    } else {
                        // permission was denied or other error - return error
                        result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: CDVContactError.UNKNOWN_ERROR.rawValue)
                        weakSelf?.commandDelegate.send(result, callbackId: callbackId)
                        return
                    }
                }) // end of  queue
            }
        })
    }
    
    func remove(_ command: CDVInvokedUrlCommand) {
        checkContactPermission(command: command, accessGrantedCallback: { (command) in
            let callbackId: String = command.callbackId
            let commandcId = command.argument(at: 0) as? String
            let weakSelf: CDVContacts? = self
            var result: CDVPluginResult? = nil

            if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                var bIsError = false
                var errCode: CDVContactError = CDVContactError.UNKNOWN_ERROR
                if let cId = commandcId { //TODO: Check for invalid record id
                    if let rec = try? CNContactStore().unifiedContact(withIdentifier: cId, keysToFetch: CDVContacts.allContactKeys).mutableCopy() as! CNMutableContact  {
                        let saveRequest = CNSaveRequest()
                        saveRequest.delete(rec)
                        do {
                            try CNContactStore().execute(saveRequest)
                            // set id to null
                            // [contactDict setObject:[NSNull null] forKey:kW3ContactId];
                            // result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAs: contactDict];
                            result = CDVPluginResult(status: CDVCommandStatus_OK)
                            // NSString* contactStr = [contactDict JSONRepresentation];
                        } catch {
                            bIsError = true
                            errCode = CDVContactError.IO_ERROR
                        }
                    } else {
                        // no record found return error
                        bIsError = true
                        errCode = CDVContactError.UNKNOWN_ERROR
                    }
                } else {
                    // invalid contact id provided
                    bIsError = true
                    errCode = CDVContactError.INVALID_ARGUMENT_ERROR
                }
                if bIsError {
                    result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: errCode.rawValue)
                }
                if result != nil {
                    weakSelf?.commandDelegate.send(result, callbackId: callbackId)
                }
            } else {
                // permission was denied or other error - return error
                result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: CDVContactError.UNKNOWN_ERROR.rawValue)
                weakSelf?.commandDelegate.send(result, callbackId: callbackId)
                return
            }
            return
        })
    }
    
}

/* ABPersonViewController does not have any UI to dismiss.  Adding navigationItems to it does not work properly
 * The navigationItems are lost when the app goes into the background.  The solution was to create an empty
 * NavController in front of the ABPersonViewController. This will cause the ABPersonViewController to have a back button. By subclassing the ABPersonViewController, we can override viewDidDisappear and take down the entire NavigationController.
 */
class CDVDisplayContactViewController: CNContactViewController {
    var contactsPlugin: CDVPlugin!
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presentingViewController?.dismiss(animated: true) {() -> Void in }
    }
}

