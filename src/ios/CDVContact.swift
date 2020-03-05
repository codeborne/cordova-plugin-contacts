//
//  CDVContact.swift
//  Timothy Holbrook
//
//

import Foundation
import Contacts
import ContactsUI

enum CDVContactError : Int32 {
    case UNKNOWN_ERROR = 0
    case INVALID_ARGUMENT_ERROR = 1
    case TIMEOUT_ERROR = 2
    case PENDING_OPERATION_ERROR = 3
    case IO_ERROR = 4
    case NOT_SUPPORTED_ERROR = 5
    case OPERATION_CANCELLED_ERROR = 6
    case PERMISSION_DENIED_ERROR = 20
}

// generic ContactField types
let kW3ContactFieldType = "type"
let kW3ContactFieldValue = "value"
let kW3ContactFieldPrimary = "pref"

// Various labels for ContactField types
let kW3ContactWorkLabel = "work"
let kW3ContactHomeLabel = "home"
let kW3ContactOtherLabel = "other"
let kW3ContactPhoneWorkFaxLabel = "work fax"
let kW3ContactPhoneHomeFaxLabel = "home fax"
let kW3ContactPhoneMobileLabel = "mobile"
let kW3ContactPhonePagerLabel = "pager"
let kW3ContactPhoneIPhoneLabel = "iphone"
let kW3ContactPhoneMainLabel = "main"
let kW3ContactUrlBlog = "blog"
let kW3ContactUrlProfile = "profile"
let kW3ContactImAIMLabel = "aim"
let kW3ContactImICQLabel = "icq"
let kW3ContactImMSNLabel = "msn"
let kW3ContactImYahooLabel = "yahoo"
let kW3ContactImSkypeLabel = "skype"
let kW3ContactImFacebookMessengerLabel = "facebook"
let kW3ContactImGoogleTalkLabel = "gtalk"
let kW3ContactImJabberLabel = "jabber"
let kW3ContactImQQLabel = "qq"
let kW3ContactImGaduLabel = "gadu"
let kW3ContactFieldId = "id"

// special translation for IM field value and type
let kW3ContactImType = "type"
let kW3ContactImValue = "value"

// Contact object
let kW3ContactId = "id"
let kW3ContactName = "name"
let kW3ContactFormattedName = "formatted"
let kW3ContactGivenName = "givenName"
let kW3ContactFamilyName = "familyName"
let kW3ContactMiddleName = "middleName"
let kW3ContactHonorificPrefix = "honorificPrefix"
let kW3ContactHonorificSuffix = "honorificSuffix"
let kW3ContactDisplayName = "displayName"
let kW3ContactNickname = "nickname"
let kW3ContactPhoneNumbers = "phoneNumbers"
let kW3ContactAddresses = "addresses"
let kW3ContactAddressFormatted = "formatted"
let kW3ContactStreetAddress = "streetAddress"
let kW3ContactLocality = "locality"
let kW3ContactRegion = "region"
let kW3ContactPostalCode = "postalCode"
let kW3ContactCountry = "country"
let kW3ContactEmails = "emails"
let kW3ContactIms = "ims"
let kW3ContactOrganizations = "organizations"
let kW3ContactOrganizationName = "name"
let kW3ContactTitle = "title"
let kW3ContactDepartment = "department"
let kW3ContactBirthday = "birthday"
let kW3ContactNote = "note"
let kW3ContactPhotos = "photos"
let kW3ContactCategories = "categories"
let kW3ContactUrls = "urls"

@objc(CDVContact) class CDVContact: NSObject {
    var mutableRecord: CNMutableContact? // the CNMutableContact associated with this contact
    var nonMutableRecord: CNContact? // the CNContact associated with this contact
    var returnFields: [AnyHashable: Any]? // dictionary of fields to return when performing search
    
    override init() {
        let rec: CNMutableContact = CNMutableContact()
        self.mutableRecord = rec
    }
    
    init(fromCNContact aRecord: CNContact) {
        self.nonMutableRecord = aRecord
        self.mutableRecord = (aRecord.mutableCopy() as! CNMutableContact)
    }
    
    init(fromCNMutableContact aRecord: CNMutableContact) {
        self.mutableRecord = aRecord
    }
    
    /* Rather than creating getters and setters for each AddressBook (AB) Property, generic methods are used to deal with
     * simple properties,  MultiValue properties( phone numbers and emails) and MultiValueDictionary properties (Ims and addresses).
     * The dictionaries below are used to translate between the W3C identifiers and the AB properties.   Using the dictionaries,
     * allows looping through sets of properties to extract from or set into the W3C dictionary to/from the ABRecord.
     */
    
    /* The two following dictionaries translate between W3C properties and AB properties.  It currently mixes both
     * Properties (kABPersonAddressProperty for example) and Strings (kABPersonAddressStreetKey) so users should be aware of
     * what types of values are expected.
     * a bit.
     */
    class func defaultABtoW3C() -> [String: String] {
        return [
            CNContactNicknameKey : kW3ContactNickname,
            CNContactGivenNameKey : kW3ContactGivenName,
            CNContactFamilyNameKey : kW3ContactFamilyName,
            CNContactMiddleNameKey : kW3ContactMiddleName,
            CNContactNamePrefixKey : kW3ContactHonorificPrefix,
            CNContactNameSuffixKey : kW3ContactHonorificSuffix,
            CNContactPhoneNumbersKey : kW3ContactPhoneNumbers
        ]
    }

    class func defaultW3CtoAB() -> [String: String] {
        return [
            kW3ContactNickname : CNContactNicknameKey,
            kW3ContactGivenName : CNContactGivenNameKey,
            kW3ContactFamilyName : CNContactFamilyNameKey,
            kW3ContactMiddleName : CNContactMiddleNameKey,
            kW3ContactHonorificPrefix : CNContactNamePrefixKey,
            kW3ContactHonorificSuffix : CNContactNameSuffixKey,
            kW3ContactPhoneNumbers : CNContactPhoneNumbersKey,
            kW3ContactAddresses : CNContactPostalAddressesKey,
            kW3ContactStreetAddress : CNPostalAddressStreetKey,
            kW3ContactLocality : CNPostalAddressCityKey,
            kW3ContactRegion : CNPostalAddressStateKey,
            kW3ContactPostalCode : CNPostalAddressPostalCodeKey,
            kW3ContactCountry : CNPostalAddressCountryKey,
            kW3ContactEmails : CNContactEmailAddressesKey,
            kW3ContactIms : CNContactInstantMessageAddressesKey,
            kW3ContactOrganizations : CNContactOrganizationNameKey,
            kW3ContactTitle : CNContactJobTitleKey,
            kW3ContactDepartment : CNContactDepartmentNameKey,
            kW3ContactBirthday : CNContactBirthdayKey,
            kW3ContactNote : CNContactNoteKey,
            kW3ContactUrls : CNContactUrlAddressesKey,
            //kW3ContactImValue : CNInstantMessageAddressUsernameKey,
            //kW3ContactImType : CNInstantMessageAddressServiceKey,
            kW3ContactFieldType : "", /* include entries in dictionary to indicate ContactField properties */
            kW3ContactFieldValue : "",
            kW3ContactFieldPrimary : "",
            kW3ContactFieldId : "",
            kW3ContactOrganizationName : CNContactOrganizationNameKey
        ]
    }

    class func defaultW3CtoNull() -> Set<AnyHashable> {
        // these are values that have no AddressBook Equivalent OR have not been implemented yet
        return Set<AnyHashable>([kW3ContactDisplayName, kW3ContactCategories, kW3ContactFormattedName])
    }

    /*
     *    The objectAndProperties dictionary contains the all of the properties of the W3C Contact Objects specified by the key
     *    Used in calcReturnFields, and various extract<Property> methods
     */
    class func defaultObjectAndProperties() -> [String: [String]] {
        return [
            kW3ContactName : [kW3ContactGivenName, kW3ContactFamilyName, kW3ContactMiddleName, kW3ContactHonorificPrefix, kW3ContactHonorificSuffix, kW3ContactFormattedName],
            kW3ContactAddresses : [kW3ContactStreetAddress, kW3ContactLocality, kW3ContactRegion, kW3ContactPostalCode, kW3ContactCountry         /*kW3ContactAddressFormatted,*/],
            kW3ContactOrganizations : [kW3ContactOrganizationName, kW3ContactTitle, kW3ContactDepartment],
            kW3ContactPhoneNumbers : [kW3ContactFieldType, kW3ContactFieldValue, kW3ContactFieldPrimary],
            kW3ContactEmails : [kW3ContactFieldType, kW3ContactFieldValue, kW3ContactFieldPrimary],
            kW3ContactPhotos : [kW3ContactFieldType, kW3ContactFieldValue, kW3ContactFieldPrimary],
            kW3ContactUrls : [kW3ContactFieldType, kW3ContactFieldValue, kW3ContactFieldPrimary],
            kW3ContactIms : [kW3ContactImValue, kW3ContactImType]
        ]
    }

    class func defaultFields() -> [String: [String]] {
        return [
            kW3ContactName : CDVContact.defaultObjectAndProperties()[kW3ContactName]!,
            kW3ContactNickname : [],
            kW3ContactAddresses : CDVContact.defaultObjectAndProperties()[kW3ContactAddresses]!,
            kW3ContactOrganizations : CDVContact.defaultObjectAndProperties()[kW3ContactOrganizations]!,
            kW3ContactPhoneNumbers : CDVContact.defaultObjectAndProperties()[kW3ContactPhoneNumbers]!,
            kW3ContactEmails : CDVContact.defaultObjectAndProperties()[kW3ContactEmails]!,
            kW3ContactIms : CDVContact.defaultObjectAndProperties()[kW3ContactIms]!,
            kW3ContactPhotos : CDVContact.defaultObjectAndProperties()[kW3ContactPhotos]!,
            kW3ContactUrls : CDVContact.defaultObjectAndProperties()[kW3ContactUrls]!,
            kW3ContactBirthday : [],
            kW3ContactNote : []
        ]
    }

    /*  Translate W3C Contact data into ABRecordRef
     *
     *    New contact information comes in as a NSMutableDictionary.  All Null entries in Contact object are set
     *    as [NSNull null] in the dictionary when translating from the JSON input string of Contact data. However, if
     *  user did not set a value within a Contact object or sub-object (by not using the object constructor) some data
     *    may not exist.
     *  bUpdate = YES indicates this is a save of an existing record
     */
    func setFromContactDict(_ aContact: [AnyHashable: Any], asUpdate bUpdate: Bool) -> Bool {
        var errorCount = 0
        // set name info
        // iOS doesn't have displayName - might have to pull parts from it to create name
        var bName = false
        if let dict = aContact[kW3ContactName] as? [AnyHashable: Any] {
            bName = true
            let propArray = CDVContact.defaultObjectAndProperties()[kW3ContactName]!
            for i in propArray {
                if !(i == kW3ContactFormattedName) {
                    if let val = dict[i] as? String {
                        if let prop = CDVContact.defaultW3CtoAB()[i] {
                            // kW3ContactFormattedName is generated from ABRecordCopyCompositeName() and can't be set
                            if !setValue(val, forStringProperty: prop, asUpdate: bUpdate) {
                                errorCount += 1
                            }
                        }
                    }
                }
            }
        }
        if let nn = aContact[kW3ContactNickname] as? String {
            bName = true
            if !setValue(nn, forStringProperty: CNContactNicknameKey, asUpdate: bUpdate) {
                errorCount += 1
            }
        }
        if !bName {
            // if no name or nickname - try and use displayName as W3Contact must have displayName or ContactName
            if let val = aContact[kW3ContactDisplayName] as? String {
                if !setValue(val, forStringProperty: CNContactNicknameKey, asUpdate: bUpdate) {
                    errorCount += 1
                }
            }
        }

        // set phoneNumbers
        // NSLog(@"setting phoneNumbers");
        if let array = aContact[kW3ContactPhoneNumbers] as? [[AnyHashable: Any]] {
            if !setMultiValueStrings(array, forProperty: CNContactPhoneNumbersKey, asUpdate: bUpdate) {
                errorCount += 1
            }
        }
        // TODO WebURLs

        // TODO timezone
        print("The count of errors in setFromContactDict were: \(errorCount)")
        return true
    }

    /* Set item into an AddressBook Record for the specified property.
     * aValue - the value to set into the address book (code checks for null or [NSNull null]
     * aProperty - AddressBook property ID
     * aRecord - the record to update
     * bUpdate - whether this is a possible update vs a new entry
     * RETURN
     *    true - property was set (or input value as null)
     *    false - property was not set
     */
    func setValue(_ aValue: String, forStringProperty aProperty: String, asUpdate bUpdate: Bool) -> Bool {
        var bSuccess = true
        switch aProperty {
        case CNContactDepartmentNameKey:
            mutableRecord?.departmentName = aValue
        case CNContactGivenNameKey:
            mutableRecord?.givenName = aValue
        case CNContactMiddleNameKey:
            mutableRecord?.middleName = aValue
        case CNContactFamilyNameKey:
            mutableRecord?.familyName = aValue
        case CNContactNameSuffixKey:
            mutableRecord?.nameSuffix = aValue
        case CNContactNamePrefixKey:
            mutableRecord?.namePrefix = aValue
        case CNContactNicknameKey:
            mutableRecord?.nickname = aValue
        case CNContactJobTitleKey:
            mutableRecord?.jobTitle = aValue
        case CNContactNoteKey:
            mutableRecord?.note = aValue
        case CNContactOrganizationNameKey:
            mutableRecord?.organizationName = aValue
        default:
            bSuccess = false
        }
        if !bSuccess {
            print("error setting \(aProperty) property")
        }
        return bSuccess
    }

    func setValue(_ aValue: Date, forDateProperty aProperty: String, asUpdate bUpdate: Bool) -> Bool {
        var bSuccess = true
        switch aProperty {
        case CNContactBirthdayKey:
            let calendar = NSCalendar.current
            let dateComponents = calendar.dateComponents([.month,.day,.year], from: aValue)
            mutableRecord?.birthday = dateComponents
        default:
            bSuccess = false
        }
        if !bSuccess {
            print("error setting \(aProperty) property")
        }
        return bSuccess
    }

    /* Set MultiValue string properties into Address Book Record.
     * NSArray* fieldArray - array of dictionaries containing W3C properties to be set into record
     * ABPropertyID prop - the property to be set (generally used for phones and emails)
     * ABRecordRef  person - the record to set values into
     * BOOL bUpdate - whether or not to update date or set as new.
     *    When updating:
     *      empty array indicates to remove entire property
     *      empty string indicates to remove
     *    [NSNull null] do not modify (keep existing record value)
     * RETURNS
     * bool false indicates error
     *
     * used for phones and emails
     */
    func setMultiValueStrings(_ fieldArray: [[AnyHashable: Any]], forProperty prop: String, asUpdate bUpdate: Bool) -> Bool {
        var bSuccess = true
        switch prop {
        case CNContactPhoneNumbersKey:
            if !bUpdate {
                var numbers = [CNLabeledValue<CNPhoneNumber>]()
                for dict: [AnyHashable: Any] in fieldArray {
                    var successfulSet = false
                    if let value = dict[kW3ContactFieldValue] as? String {
                        if let type = dict[kW3ContactFieldType] as? String {
                            let label = CDVContact.convertType(toContactLabel: type)
                            numbers.append(CNLabeledValue(label: label, value: CNPhoneNumber(stringValue: value)))
                            successfulSet = true
                        }
                    }
                    if !successfulSet {
                        bSuccess = false
                        print("Error setting Value and label for dict: \(dict)")
                    }
                }
                mutableRecord?.phoneNumbers = numbers
            } else if bUpdate && (fieldArray.count == 0) {
                mutableRecord?.phoneNumbers = []
            } else {
                // check for and apply changes
                if let numbers = mutableRecord?.phoneNumbers {
                    if numbers.count > 0 {
                        for dict: [AnyHashable: Any] in fieldArray {
                            if let val = dict[kW3ContactFieldValue] as? String {
                                if let type = dict[kW3ContactFieldType] as? String {
                                    let label = CDVContact.convertType(toContactLabel: type)
                                    // is an update,  find index of entry with matching id, if values are different, update.
                                    if let idValue = dict[kW3ContactFieldId] as? String {
                                        if let match = mutableRecord?.phoneNumbers.first(where: { $0.identifier == idValue }) {
                                            if val.count == 0 {
                                                // remove both value and label
                                                if let index = mutableRecord?.phoneNumbers.index(of: match) {
                                                    mutableRecord?.phoneNumbers.remove(at: index)
                                                }
                                            } else {
                                                if let index = mutableRecord?.phoneNumbers.index(of: match) {
                                                    var newVal = match.value.stringValue
                                                    var newLabel = match.label
                                                    if match.value.stringValue != val {
                                                        newVal = val
                                                    }
                                                    if match.label != label {
                                                        newLabel = label
                                                    }
                                                    mutableRecord?.phoneNumbers[index] = CNLabeledValue(label: newLabel, value: CNPhoneNumber(stringValue: newVal))
                                                }
                                            }
                                        } else {
                                            // is a new value - insert
                                            mutableRecord?.phoneNumbers.append(CNLabeledValue(label: label, value: CNPhoneNumber(stringValue: val)))
                                        }
                                    }
                                }
                            }
                        } // end of for
                    }
                } else {
                    // adding all new value(s)
                    var numbers = [CNLabeledValue<CNPhoneNumber>]()
                    for dict: [AnyHashable: Any] in fieldArray {
                        var successfulSet = false
                        if let value = dict[kW3ContactFieldValue] as? String {
                            if let type = dict[kW3ContactFieldType] as? String {
                                let label = CDVContact.convertType(toContactLabel: type)
                                numbers.append(CNLabeledValue(label: label, value: CNPhoneNumber(stringValue: value)))
                                successfulSet = true
                            }
                        }
                        if !successfulSet {
                            bSuccess = false
                            print("Error setting Value and label for dict: \(dict)")
                        }
                    }
                    mutableRecord?.phoneNumbers = numbers
                }
            }
        case CNContactEmailAddressesKey:
            if !bUpdate {
                var emails = [CNLabeledValue<NSString>]()
                for dict: [AnyHashable: Any] in fieldArray {
                    var successfulSet = false
                    if let value = dict[kW3ContactFieldValue] as? String {
                        if let type = dict[kW3ContactFieldType] as? String {
                            let label = CDVContact.convertType(toContactLabel: type)
                            emails.append(CNLabeledValue(label: label, value: NSString(string: value)))
                            successfulSet = true
                        }
                    }
                    if !successfulSet {
                        bSuccess = false
                        print("Error setting Value and label for dict: \(dict)")
                    }
                }
                mutableRecord?.emailAddresses = emails
            } else if bUpdate && (fieldArray.count == 0) {
                mutableRecord?.emailAddresses = []
            } else {
                // check for and apply changes
                if let emails = mutableRecord?.emailAddresses {
                    if emails.count > 0 {
                        for dict: [AnyHashable: Any] in fieldArray {
                            if let val = dict[kW3ContactFieldValue] as? String {
                                if let type = dict[kW3ContactFieldType] as? String {
                                    let label = CDVContact.convertType(toContactLabel: type)
                                    // is an update,  find index of entry with matching id, if values are different, update.
                                    if let idValue = dict[kW3ContactFieldId] as? String {
                                        if let match = mutableRecord?.emailAddresses.first(where: { $0.identifier == idValue }) {
                                            if val.count == 0 {
                                                // remove both value and label
                                                if let index = mutableRecord?.emailAddresses.index(of: match) {
                                                    mutableRecord?.emailAddresses.remove(at: index)
                                                }
                                            } else {
                                                if let index = mutableRecord?.emailAddresses.index(of: match) {
                                                    var newVal = match.value as String
                                                    var newLabel = match.label
                                                    if match.value as String != val {
                                                        newVal = val
                                                    }
                                                    if match.label != label {
                                                        newLabel = label
                                                    }
                                                    mutableRecord?.emailAddresses[index] = CNLabeledValue(label: newLabel, value: NSString(string: newVal))
                                                }
                                            }
                                        } else {
                                            // is a new value - insert
                                            mutableRecord?.emailAddresses.append(CNLabeledValue(label: label, value: NSString(string: val)))
                                        }
                                    }
                                }
                            }
                        } // end of for
                    }
                } else {
                    // adding all new value(s)
                    var emails = [CNLabeledValue<NSString>]()
                    for dict: [AnyHashable: Any] in fieldArray {
                        var successfulSet = false
                        if let value = dict[kW3ContactFieldValue] as? String {
                            if let type = dict[kW3ContactFieldType] as? String {
                                let label = CDVContact.convertType(toContactLabel: type)
                                emails.append(CNLabeledValue(label: label, value: NSString(string: value)))
                                successfulSet = true
                            }
                        }
                        if !successfulSet {
                            bSuccess = false
                            print("Error setting Value and label for dict: \(dict)")
                        }
                    }
                    mutableRecord?.emailAddresses = emails
                }
            }
        case CNContactUrlAddressesKey:
            if !bUpdate {
                var urls = [CNLabeledValue<NSString>]()
                for dict: [AnyHashable: Any] in fieldArray {
                    var successfulSet = false
                    if let value = dict[kW3ContactFieldValue] as? String {
                        if let type = dict[kW3ContactFieldType] as? String {
                            let label = CDVContact.convertType(toContactLabel: type)
                            urls.append(CNLabeledValue(label: label, value: NSString(string: value)))
                            successfulSet = true
                        }
                    }
                    if !successfulSet {
                        bSuccess = false
                        print("Error setting Value and label for dict: \(dict)")
                    }
                }
                mutableRecord?.urlAddresses = urls
            } else if bUpdate && (fieldArray.count == 0) {
                mutableRecord?.urlAddresses = []
            } else {
                // check for and apply changes
                if let urls = mutableRecord?.urlAddresses {
                    if urls.count > 0 {
                        for dict: [AnyHashable: Any] in fieldArray {
                            if let val = dict[kW3ContactFieldValue] as? String {
                                if let type = dict[kW3ContactFieldType] as? String {
                                    let label = CDVContact.convertType(toContactLabel: type)
                                    // is an update,  find index of entry with matching id, if values are different, update.
                                    if let idValue = dict[kW3ContactFieldId] as? String {
                                        if let match = mutableRecord?.urlAddresses.first(where: { $0.identifier == idValue }) {
                                            if val.count == 0 {
                                                // remove both value and label
                                                if let index = mutableRecord?.urlAddresses.index(of: match) {
                                                    mutableRecord?.urlAddresses.remove(at: index)
                                                }
                                            } else {
                                                if let index = mutableRecord?.urlAddresses.index(of: match) {
                                                    var newVal = match.value as String
                                                    var newLabel = match.label
                                                    if match.value as String != val {
                                                        newVal = val
                                                    }
                                                    if match.label != label {
                                                        newLabel = label
                                                    }
                                                    mutableRecord?.urlAddresses[index] = CNLabeledValue(label: newLabel, value: NSString(string: newVal))
                                                }
                                            }
                                        } else {
                                            // is a new value - insert
                                            mutableRecord?.urlAddresses.append(CNLabeledValue(label: label, value: NSString(string: val)))
                                        }
                                    }
                                }
                            }
                        } // end of for
                    }
                } else {
                    // adding all new value(s)
                    var urls = [CNLabeledValue<NSString>]()
                    for dict: [AnyHashable: Any] in fieldArray {
                        var successfulSet = false
                        if let value = dict[kW3ContactFieldValue] as? String {
                            if let type = dict[kW3ContactFieldType] as? String {
                                let label = CDVContact.convertType(toContactLabel: type)
                                urls.append(CNLabeledValue(label: label, value: NSString(string: value)))
                                successfulSet = true
                            }
                        }
                        if !successfulSet {
                            bSuccess = false
                            print("Error setting Value and label for dict: \(dict)")
                        }
                    }
                    mutableRecord?.urlAddresses = urls
                }
            }
        case CNContactPostalAddressesKey:
            if !bUpdate {
                var addresses = [CNLabeledValue<CNPostalAddress>]()
                for dict: [AnyHashable: Any] in fieldArray {
                    var successfulSet = true
                    if let type = dict[kW3ContactFieldType] as? String {
                        let label = CDVContact.convertType(toContactLabel: type)
                        let address = CNMutablePostalAddress()
                        if let city = dict[kW3ContactLocality] as? String {
                            address.city = city
                        } else {
                            successfulSet = false
                        }
                        if let state = dict[kW3ContactRegion] as? String {
                            address.state = state
                        } else {
                            successfulSet = false
                        }
                        if let country = dict[kW3ContactCountry] as? String {
                            address.country = country
                        } else {
                            successfulSet = false
                        }
                        if let streetAddress = dict[kW3ContactStreetAddress] as? String {
                            address.street = streetAddress
                        } else {
                            successfulSet = false
                        }
                        if let postalCode = dict[kW3ContactPostalCode] as? String {
                            address.postalCode = postalCode
                        } else {
                            successfulSet = false
                        }
                        addresses.append(CNLabeledValue(label: label, value: address))
                    }
                    if !successfulSet {
                        bSuccess = false
                        print("Error setting Value and label for dict: \(dict)")
                    }
                }
                mutableRecord?.postalAddresses = addresses
            } else if bUpdate && (fieldArray.count == 0) {
                mutableRecord?.postalAddresses = []
            } else {
                // check for and apply changes
                if let addresses = mutableRecord?.postalAddresses {
                    if addresses.count > 0 {
                        for dict: [AnyHashable: Any] in fieldArray {
                            if let type = dict[kW3ContactFieldType] as? String {
                                let label = CDVContact.convertType(toContactLabel: type)
                                // is an update,  find index of entry with matching id, if values are different, update.
                                if let idValue = dict[kW3ContactFieldId] as? String {
                                    if let match = mutableRecord?.postalAddresses.first(where: { $0.identifier == idValue }) {
                                        let address = match.mutableCopy() as! CNMutablePostalAddress
                                        var count = 0
                                        if let city = dict[kW3ContactLocality] as? String {
                                            address.city = city
                                            count += 1
                                        }
                                        if let state = dict[kW3ContactRegion] as? String {
                                            address.state = state
                                            count += 1
                                        }
                                        if let country = dict[kW3ContactCountry] as? String {
                                            address.country = country
                                            count += 1
                                        }
                                        if let streetAddress = dict[kW3ContactStreetAddress] as? String {
                                            address.street = streetAddress
                                            count += 1
                                        }
                                        if let postalCode = dict[kW3ContactPostalCode] as? String {
                                            address.postalCode = postalCode
                                            count += 1
                                        }
                                        if count == 0 {
                                            // remove both value and label
                                            if let index = mutableRecord?.postalAddresses.index(of: match) {
                                                mutableRecord?.postalAddresses.remove(at: index)
                                            }
                                        } else {
                                            if let index = mutableRecord?.postalAddresses.index(of: match) {
                                                mutableRecord?.postalAddresses[index] = CNLabeledValue(label: label, value: address)
                                            }
                                        }
                                    } else {
                                        // is a new value - insert
                                        let address = CNMutablePostalAddress()
                                        var count = 0
                                        if let city = dict[kW3ContactLocality] as? String {
                                            address.city = city
                                            count += 1
                                        }
                                        if let state = dict[kW3ContactRegion] as? String {
                                            address.state = state
                                            count += 1
                                        }
                                        if let country = dict[kW3ContactCountry] as? String {
                                            address.country = country
                                            count += 1
                                        }
                                        if let streetAddress = dict[kW3ContactStreetAddress] as? String {
                                            address.street = streetAddress
                                            count += 1
                                        }
                                        if let postalCode = dict[kW3ContactPostalCode] as? String {
                                            address.postalCode = postalCode
                                            count += 1
                                        }
                                        if count > 0 {
                                            mutableRecord?.postalAddresses.append(CNLabeledValue(label: label, value: address))
                                        }
                                    }
                                }
                            }
                        } // end of for
                    }
                } else {
                    // adding all new value(s)
                    var addresses = [CNLabeledValue<CNPostalAddress>]()
                    for dict: [AnyHashable: Any] in fieldArray {
                        var successfulSet = true
                        if let type = dict[kW3ContactFieldType] as? String {
                            let label = CDVContact.convertType(toContactLabel: type)
                            let address = CNMutablePostalAddress()
                            if let city = dict[kW3ContactLocality] as? String {
                                address.city = city
                            } else {
                                successfulSet = false
                            }
                            if let state = dict[kW3ContactRegion] as? String {
                                address.state = state
                            } else {
                                successfulSet = false
                            }
                            if let country = dict[kW3ContactCountry] as? String {
                                address.country = country
                            } else {
                                successfulSet = false
                            }
                            if let streetAddress = dict[kW3ContactStreetAddress] as? String {
                                address.street = streetAddress
                            } else {
                                successfulSet = false
                            }
                            if let postalCode = dict[kW3ContactPostalCode] as? String {
                                address.postalCode = postalCode
                            } else {
                                successfulSet = false
                            }
                            addresses.append(CNLabeledValue(label: label, value: address))
                        }
                        if !successfulSet {
                            bSuccess = false
                            print("Error setting Value and label for dict: \(dict)")
                        }
                    }
                    mutableRecord?.postalAddresses = addresses
                }
            }
        case CNContactInstantMessageAddressesKey:
            if !bUpdate {
                var addresses = [CNLabeledValue<CNInstantMessageAddress>]()
                for dict: [AnyHashable: Any] in fieldArray {
                    var successfulSet = false
                    if let type = dict[kW3ContactFieldType] as? String {
                        let label = CDVContact.convertType(toContactLabel: type)
                        if let service = dict[kW3ContactImType] as? String {
                            if let username = dict[kW3ContactImValue] as? String {
                                addresses.append(CNLabeledValue(label: label, value: CNInstantMessageAddress(username: username, service: service)))
                                successfulSet = true
                            }
                        }
                    }
                    if !successfulSet {
                        bSuccess = false
                        print("Error setting Value and label for dict: \(dict)")
                    }
                }
                mutableRecord?.instantMessageAddresses = addresses
            } else if bUpdate && (fieldArray.count == 0) {
                mutableRecord?.instantMessageAddresses = []
            } else {
                // check for and apply changes
                if let addresses = mutableRecord?.instantMessageAddresses {
                    if addresses.count > 0 {
                        for dict: [AnyHashable: Any] in fieldArray {
                            if let type = dict[kW3ContactFieldType] as? String {
                                let label = CDVContact.convertType(toContactLabel: type)
                                // is an update,  find index of entry with matching id, if values are different, update.
                                if let idValue = dict[kW3ContactFieldId] as? String {
                                    if let match = mutableRecord?.instantMessageAddresses.first(where: { $0.identifier == idValue }) {
                                        var successfulSet = false
                                        if let service = dict[kW3ContactImType] as? String {
                                            if let username = dict[kW3ContactImValue] as? String {
                                                if let index = mutableRecord?.instantMessageAddresses.index(of: match) {
                                                    mutableRecord?.instantMessageAddresses[index] = CNLabeledValue(label: label, value: CNInstantMessageAddress(username: username, service: service))
                                                    successfulSet = true
                                                }
                                            }
                                        }
                                        if !successfulSet {
                                            // remove both value and label
                                            if let index = mutableRecord?.instantMessageAddresses.index(of: match) {
                                                mutableRecord?.instantMessageAddresses.remove(at: index)
                                            }
                                        }
                                    } else {
                                        // is a new value - insert
                                        if let service = dict[kW3ContactImType] as? String {
                                            if let username = dict[kW3ContactImValue] as? String {
                                                mutableRecord?.instantMessageAddresses.append(CNLabeledValue(label: label, value: CNInstantMessageAddress(username: username, service: service)))
                                            }
                                        }
                                    }
                                }
                            }
                        } // end of for
                    }
                } else {
                    // adding all new value(s)
                    var addresses = [CNLabeledValue<CNInstantMessageAddress>]()
                    for dict: [AnyHashable: Any] in fieldArray {
                        var successfulSet = false
                        if let type = dict[kW3ContactFieldType] as? String {
                            let label = CDVContact.convertType(toContactLabel: type)
                            if let service = dict[kW3ContactImType] as? String {
                                if let username = dict[kW3ContactImValue] as? String {
                                    addresses.append(CNLabeledValue(label: label, value: CNInstantMessageAddress(username: username, service: service)))
                                    successfulSet = true
                                }
                            }
                        }
                        if !successfulSet {
                            bSuccess = false
                            print("Error setting Value and label for dict: \(dict)")
                        }
                    }
                    mutableRecord?.instantMessageAddresses = addresses
                }
            }
        case CNContactOrganizationNameKey:
            // TODO this may need work - should Organization information be removed when array is empty??
            // iOS only supports one organization - use first one
            var bRemove = false
            var dict: [AnyHashable: Any]? = nil
            if fieldArray.count > 0 {
                dict = fieldArray[0]
            }
            else {
                // remove the organization info entirely
                bRemove = true
            }
            if bRemove == true {
                if !(setValue("", forStringProperty: CNContactOrganizationNameKey, asUpdate: bUpdate)) {
                    bSuccess = false
                }
                if !(setValue("", forStringProperty: CNContactJobTitleKey, asUpdate: bUpdate)) {
                    bSuccess = false
                }
                if !(setValue("", forStringProperty: CNContactDepartmentNameKey, asUpdate: bUpdate)) {
                    bSuccess = false
                }
            } else if let org = dict {
                if let name = org[kW3ContactOrganizationName] as? String {
                    if !(setValue(name, forStringProperty: CNContactOrganizationNameKey, asUpdate: bUpdate)) {
                        bSuccess = false
                    }
                }
                if let title = org[kW3ContactTitle] as? String {
                    if !(setValue(title, forStringProperty: CNContactJobTitleKey, asUpdate: bUpdate)) {
                        bSuccess = false
                    }
                }
                if let dept = org[kW3ContactDepartment] as? String {
                    if !(setValue(dept, forStringProperty: CNContactDepartmentNameKey, asUpdate: bUpdate)) {
                        bSuccess = false
                    }
                }
            }
        default:
            bSuccess = false
        }

        return bSuccess
    }

    /* Determine which W3C labels need to be converted
     */
    class func needsConversion(_ W3Label: String) -> Bool {
        var bConvert = false
        if (W3Label == kW3ContactFieldType) || (W3Label == kW3ContactImType) {
            bConvert = true
        }
        return bConvert
    }

    /* Return dictionary where key is contact api label, value is iPhone constant
     */
    class func getTypeLabelConversionTable() -> [String: String] {
        return [kW3ContactWorkLabel: CNLabelWork, kW3ContactHomeLabel: CNLabelHome, kW3ContactOtherLabel: CNLabelOther, kW3ContactPhoneMobileLabel: CNLabelPhoneNumberMobile, kW3ContactPhonePagerLabel: CNLabelPhoneNumberPager, kW3ContactPhoneWorkFaxLabel: CNLabelPhoneNumberWorkFax, kW3ContactPhoneHomeFaxLabel: CNLabelPhoneNumberHomeFax, kW3ContactPhoneIPhoneLabel: CNLabelPhoneNumberiPhone, kW3ContactPhoneMainLabel: CNLabelPhoneNumberMain, kW3ContactImAIMLabel: CNInstantMessageServiceAIM, kW3ContactImICQLabel: CNInstantMessageServiceQQ, kW3ContactImMSNLabel: CNInstantMessageServiceMSN, kW3ContactImYahooLabel: CNInstantMessageServiceYahoo, kW3ContactImSkypeLabel: CNInstantMessageServiceSkype, kW3ContactImGoogleTalkLabel: CNInstantMessageServiceGoogleTalk, kW3ContactImFacebookMessengerLabel: CNInstantMessageServiceFacebook, kW3ContactImJabberLabel: CNInstantMessageServiceJabber, kW3ContactImQQLabel: CNInstantMessageServiceQQ, kW3ContactImGaduLabel: CNInstantMessageServiceGaduGadu, kW3ContactUrlProfile: CNLabelURLAddressHomePage]
    }

    /* Translation of property type labels  contact API ---> iPhone
     *
     *    phone:  work, home, other, mobile, home fax, work fax, main, iphone, pager -->
     *        kABWorkLabel, kABHomeLabel, kABOtherLabel, kABPersonPhoneMobileLabel, kABPersonHomeFAXLabel, kABPersonHomeFAXLabel, kABPersonPhonePagerLabel, kABPersonPhoneIPhoneLabel, kABPersonPhoneMainLabel
     *    emails:  work, home, other ---> kABWorkLabel, kABHomeLabel, kABOtherLabel
     *    ims: aim, gtalk, icq, xmpp, msn, skype, qq, yahoo, gadu --> kABPersonInstantMessageService + (AIM, ICG, MSN, Yahoo, Gtalk, Skype, QQ, Gadu).  No support for xmpp
     * addresses: work, home, other --> kABWorkLabel, kABHomeLabel, kABOtherLabel
     *
     *
     */
    class func convertLabel(toContactType label: String) -> String {
        var type: String = ""
        let table = CDVContact.getTypeLabelConversionTable()
        let result = table.filter { $0.value.lowercased() == label.lowercased() }
        if let valueFound = result.first?.key {
            // CB-3950 If label is not one of kW3*Label constants, threat it as custom label,
            // otherwise fetching contact and then saving it will break this label in address book.
            type = valueFound
        } else {
            if let match = label.range(of: "(?<=')[^']+", options: .regularExpression) {
                type = label.substring(with: match)
            } else {
                type = label
            }
        }
        return type
    }

    class func convertType(toContactLabel type: String) -> String {
        var label: String = ""
        let table = CDVContact.getTypeLabelConversionTable()
        let result = table.filter { $0.key.lowercased() == type.lowercased() }
        if let valueFound = result.first?.value {
            // CB-3950 If label is not one of kW3*Label constants, threat it as custom label,
            // otherwise fetching contact and then saving it will break this label in address book.
            label = valueFound
        } else {
            label = type
        }
        return label
    }

    /* Check if the input label is a valid W3C ContactField.type. This is used when searching,
     * only search field types if the search string is a valid type.  If we converted any search
     * string to a ABPropertyLabel it could convert to kABOtherLabel which is probably not want
     * the user wanted to search for and could skew the results.
     */
    class func isValidW3ContactType(_ type: String) -> Bool {
        var isValid = false
        let table = CDVContact.getTypeLabelConversionTable()
        let result = table.filter { $0.key.lowercased() == type.lowercased() }
        if result.first?.value != nil {
            isValid = true
        }
        return isValid
    }

    /* Create a new Contact Dictionary object from an ABRecordRef that contains information in a format such that
     * it can be returned to JavaScript callback as JSON object string.
     * Uses:
     * ABRecordRef set into Contact Object
     * NSDictionary withFields indicates which fields to return from the AddressBook Record
     *
     * JavaScript Contact:
     * @param {DOMString} id unique identifier
     * @param {DOMString} displayName
     * @param {ContactName} name
     * @param {DOMString} nickname
     * @param {ContactField[]} phoneNumbers array of phone numbers
     * @param {ContactField[]} emails array of email addresses
     * @param {ContactAddress[]} addresses array of addresses
     * @param {ContactField[]} ims instant messaging user ids
     * @param {ContactOrganization[]} organizations
     * @param {DOMString} published date contact was first created
     * @param {DOMString} updated date contact was last updated
     * @param {DOMString} birthday contact's birthday
     * @param (DOMString} anniversary contact's anniversary
     * @param {DOMString} gender contact's gender
     * @param {DOMString} note user notes about contact
     * @param {DOMString} preferredUsername
     * @param {ContactField[]} photos
     * @param {ContactField[]} tags
     * @param {ContactField[]} relationships
     * @param {ContactField[]} urls contact's web sites
     * @param {ContactAccounts[]} accounts contact's online accounts
     * @param {DOMString} timezone UTC time zone offset
     * @param {DOMString} connected
     */

    func toDictionary(_ withFields: [AnyHashable: Any]) -> [AnyHashable: Any] {
        // if not a person type record bail out for now
        if nonMutableRecord?.contactType != CNContactType.person {
            return [NSNull() : NSNull()]
        }
        var value: Any? = nil
        returnFields = withFields
        var nc = [AnyHashable: Any](minimumCapacity: 1) // new contact dictionary to fill in from ABRecordRef

        // id
        nc[kW3ContactId] = nonMutableRecord?.identifier
        if let fields = returnFields {
            if fields[kW3ContactDisplayName] != nil {
                // displayname requested -  iOS doesn't have so return null
                nc[kW3ContactDisplayName] = NSNull()
                // may overwrite below if requested ContactName and there are no values
            }

            // nickname
            if fields[kW3ContactNickname] != nil {
                value = nonMutableRecord?.nickname
                nc[kW3ContactNickname] = (value != nil) ? value : NSNull()
            }

            // name dictionary
            // NSLog(@"getting name info");
            let data: NSObject? = extractName()
            if data != nil {
                nc[kW3ContactName] = data
            }
            if fields[kW3ContactDisplayName] != nil {
                if ((data == nil) || ((data as? [AnyHashable: Any])?[kW3ContactFormattedName] == nil)) {
                    // user asked for displayName which iOS doesn't support but there is no other name data being returned
                    // try and use Nickname so some name is returned
                    value = nonMutableRecord?.nickname
                    nc[kW3ContactDisplayName] = (value != nil) ? value : ""
                }
            }

            // phoneNumbers array
            // NSLog(@"getting phoneNumbers");
            value = extractMultiValue(kW3ContactPhoneNumbers)
            if value != nil {
                nc[kW3ContactPhoneNumbers] = value
            }

            // emails array
            // NSLog(@"getting emails");
            value = extractMultiValue(kW3ContactEmails)
            if value != nil {
                nc[kW3ContactEmails] = value
            }
            return nc
        } else {
            // if no returnFields specified, W3C says to return empty contact (but Cordova will at least return id)
            return nc
        }
    }
    
    func getDateAsNumber(_ datePropId: String) -> NSNumber {
        var msDate: NSNumber? = nil
        if let aDate = nonMutableRecord?.birthday?.date {
            msDate = (aDate.timeIntervalSince1970 * 1000) as NSNumber
        }
        return msDate ?? 0
    }
    
    /* Create Dictionary to match JavaScript ContactName object:
     *    formatted - ABRecordCopyCompositeName
     *    familyName
     *    givenName
     *    middleName
     *    honorificPrefix
     *    honorificSuffix
     */
    
    func extractName() -> NSObject {
        var newName = [AnyHashable: Any](minimumCapacity: 6)
        if let fields = returnFields?[kW3ContactName] as? [String] {
            for i in fields {
                var value: String = ""
                switch i {
                case kW3ContactFormattedName:
                    if let prefix = nonMutableRecord?.namePrefix {
                        if prefix.count > 0 {
                            value = value + prefix + " "
                        }
                    }
                    if let firstName = nonMutableRecord?.givenName {
                        if firstName.count > 0 {
                            value = value + firstName + " "
                        }
                    }
                    if let middleName = nonMutableRecord?.middleName {
                        if middleName.count > 0 {
                            value = value + middleName + " "
                        }
                    }
                    if let lastName = nonMutableRecord?.familyName {
                        if lastName.count > 0 {
                            value = value + lastName + " "
                        }
                    }
                    if let suffix = nonMutableRecord?.nameSuffix {
                        if suffix.count > 0 {
                            value = value + suffix
                        }
                    }
                    value = value.trimmingCharacters(in: .whitespaces)
                case kW3ContactHonorificPrefix:
                    value = nonMutableRecord?.namePrefix ?? ""
                case kW3ContactGivenName:
                    value = nonMutableRecord?.givenName ?? ""
                case kW3ContactMiddleName:
                    value = nonMutableRecord?.middleName ?? ""
                case kW3ContactFamilyName:
                    value = nonMutableRecord?.familyName ?? ""
                case kW3ContactHonorificSuffix:
                    value = nonMutableRecord?.nameSuffix ?? ""
                default:
                    value = ""
                }
                newName[i] = (value.count > 0) ? value : NSNull()
            }
        } else {
            return NSNull()
        }
        return newName as NSObject
    }
    
    /* Create array of Dictionaries to match JavaScript ContactField object for simple multiValue properties phoneNumbers, emails
     * Input: (NSString*) W3Contact Property name
     * type
     *        for phoneNumbers type is one of (work,home,other, mobile, fax, pager)
     *        for emails type is one of (work,home, other)
     * value - phone number or email address
     * (bool) primary (not supported on iphone)
     * id
     */
    func extractMultiValue(_ propertyId: String) -> NSObject {
        var valuesArray: NSObject? = nil
        if let contact = nonMutableRecord {
            if let fields = returnFields?[propertyId] as? [String] {
                var newValues = [[AnyHashable: Any]]()
                switch propertyId {
                case kW3ContactPhoneNumbers:
                    for number in contact.phoneNumbers {
                        var newValue = [AnyHashable: Any]()
                        for i in fields {
                            switch i {
                            case kW3ContactFieldType:
                                if let label = number.label {
                                    newValue[i] = CDVContact.self.convertLabel(toContactType: label) as NSObject
                                } else {
                                    newValue[i] = NSNull()
                                }
                            case kW3ContactFieldValue:
                                newValue[i] = number.value.stringValue
                            case kW3ContactFieldPrimary:
                                newValue[i] = false
                            default:
                                newValue[i] = NSNull()
                            }
                            newValue[kW3ContactFieldId] = number.identifier
                        }
                        newValues.append(newValue)
                    }
                case kW3ContactEmails:
                    for email in contact.emailAddresses {
                        var newValue = [AnyHashable: Any]()
                        for i in fields {
                            switch i {
                            case kW3ContactFieldType:
                                if let label = email.label {
                                    newValue[i] = CDVContact.self.convertLabel(toContactType: label) as NSObject
                                } else {
                                    newValue[i] = NSNull()
                                }
                            case kW3ContactFieldValue:
                                newValue[i] = email.value
                            case kW3ContactFieldPrimary:
                                newValue[i] = false
                            default:
                                newValue[i] = NSNull()
                            }
                            newValue[kW3ContactFieldId] = email.identifier
                        }
                        newValues.append(newValue)
                    }
                case kW3ContactUrls:
                    for url in contact.urlAddresses {
                        var newValue = [AnyHashable: Any]()
                        for i in fields {
                            switch i {
                            case kW3ContactFieldType:
                                if let label = url.label {
                                    newValue[i] = CDVContact.self.convertLabel(toContactType: label) as NSObject
                                } else {
                                    newValue[i] = NSNull()
                                }
                            case kW3ContactFieldValue:
                                newValue[i] = url.value
                            case kW3ContactFieldPrimary:
                                newValue[i] = false
                            default:
                                newValue[i] = NSNull()
                            }
                            newValue[kW3ContactFieldId] = url.identifier
                        }
                        newValues.append(newValue)
                    }
                default:
                    return NSNull() as NSObject
                }
                if newValues.count > 0 {
                    valuesArray = newValues as NSObject
                } else {
                    return NSNull() as NSObject
                }
            } else {
                return NSNull() as NSObject
            }
        } else {
            return NSNull() as NSObject
        }
        return valuesArray ?? NSNull() as NSObject
    }
    
    /* Create array of Dictionaries to match JavaScript ContactAddress object for addresses
     *  pref - not supported
     *  type - address type
     *    formatted  - formatted for mailing label (what about localization?)
     *    streetAddress
     *    locality
     *    region;
     *    postalCode
     *    country
     *    id
     *
     *    iOS addresses are a MultiValue Properties with label, value=dictionary of address info, and id
     */
    func extractAddresses() -> NSObject {
        var values: NSObject?
        if let fields = returnFields?[kW3ContactAddresses] as? [String] {
            if let addresses = nonMutableRecord?.postalAddresses {
                if addresses.count > 0 {
                    var newAddresses = [[AnyHashable: Any]]()
                    for i in 0..<addresses.count {
                        var newAddress = [AnyHashable: Any](minimumCapacity: 7)
                        // if we got this far, at least some address info is being requested.
                        // Always set id
                        let identifier = addresses[i].identifier
                        newAddress[kW3ContactFieldId] = identifier
                        // set the type label
                        if let label = addresses[i].label {
                            newAddress[kW3ContactFieldType] = CDVContact.self.convertLabel(toContactType: label) as NSObject
                        } else {
                            newAddress[kW3ContactFieldType] = NSNull()
                        }
                        // set the pref - iOS doesn't support so set to default of false
                        newAddress[kW3ContactFieldPrimary] = "false"
                        // get dictionary of values for this address
                        for k in fields {
                            var value: String = ""
                            switch k {
                            case kW3ContactStreetAddress:
                                value = addresses[i].value.street
                            case kW3ContactLocality:
                                value = addresses[i].value.city
                            case kW3ContactRegion:
                                value = addresses[i].value.state
                            case kW3ContactPostalCode:
                                value = addresses[i].value.postalCode
                            case kW3ContactCountry:
                                value = addresses[i].value.country
                            default:
                                newAddress[k] = NSNull()
                            }
                            newAddress[k] = (value.count > 0) ? value : NSNull()
                        }
                        if newAddress.count > 0 {
                            // ?? this will always be true since we set id,label,primary field??
                            newAddresses.append(newAddress)
                        }
                    } // end of loop through addresses
                    if newAddresses.count > 0 {
                        values = newAddresses as NSObject
                    } else {
                        values = NSNull() as NSObject
                    }
                } else {
                    values = NSNull() as NSObject
                }
            } else {
                return NSNull() as NSObject
            }
        } else {
            return NSNull() as NSObject
        }
        return values ?? NSNull() as NSObject
    }
    
    /* Create array of Dictionaries to match JavaScript ContactField object for ims
     * type one of [aim, gtalk, icq, xmpp, msn, skype, qq, yahoo] needs other as well
     * value
     * (bool) primary
     * id
     *
     *    iOS IMs are a MultiValue Properties with label, value=dictionary of IM details (service, username), and id
     */
    func extractIms() -> NSObject {
        var imArray: NSObject?
        if let fields = returnFields?[kW3ContactIms] as? [String] {
            if let ims = nonMutableRecord?.instantMessageAddresses {
                if ims.count > 0 {
                    var newIms = [[AnyHashable: Any]]()
                    for i in 0..<ims.count {
                        var newIm = [AnyHashable: Any](minimumCapacity: 3)
                        // iOS has label property (work, home, other) for each IM but W3C contact API doesn't use
                        for k in fields {
                            switch k {
                            case kW3ContactFieldValue:
                                newIm[k] = ims[i].value.username
                            case kW3ContactFieldType:
                                newIm[k] = CDVContact.self.convertLabel(toContactType: ims[i].value.service) as NSObject
                            default:
                                newIm[k] = NSNull()
                            }
                        }
                        // always set ID
                        newIm[kW3ContactFieldId] = ims[i].identifier
                        newIms.append(newIm)
                    }
                    if newIms.count > 0 {
                        imArray = newIms as NSObject
                    }
                }
                else {
                    imArray = NSNull() as NSObject
                }
            } else {
                imArray = NSNull()
            }
            
        } else {
            // no name fields requested
            return NSNull()
        }
        return imArray ?? NSObject()
    }
    
    /* Create array of Dictionaries to match JavaScript ContactOrganization object
     *    pref - not supported in iOS
     *  type - not supported in iOS
     *  name
     *    department
     *    title
     */
    func extractOrganizations() -> NSObject {
        var array: NSObject?
        if let fields = returnFields?[kW3ContactOrganizations] as? [String] {
            var newOrg = [AnyHashable: Any](minimumCapacity: 5)
            var validValueCount: Int = 0
            for i in fields {
                switch i {
                case kW3ContactOrganizationName:
                    if let count = nonMutableRecord?.organizationName.count {
                        if count > 0 {
                            newOrg[i] = nonMutableRecord?.organizationName
                            validValueCount += 1
                        } else {
                            newOrg[i] = NSNull()
                        }
                    } else {
                        newOrg[i] = NSNull()
                    }
                case kW3ContactTitle:
                    if let count = nonMutableRecord?.jobTitle.count {
                        if count > 0 {
                            newOrg[i] = nonMutableRecord?.jobTitle
                            validValueCount += 1
                        } else {
                            newOrg[i] = NSNull()
                        }
                    } else {
                        newOrg[i] = NSNull()
                    }
                case kW3ContactDepartment:
                    if let count = nonMutableRecord?.departmentName.count {
                        if count > 0 {
                            newOrg[i] = nonMutableRecord?.departmentName
                            validValueCount += 1
                        } else {
                            newOrg[i] = NSNull()
                        }
                    } else {
                        newOrg[i] = NSNull()
                    }
                default:
                    newOrg[i] = NSNull()
                }
            }
            if newOrg.count > 0 && validValueCount > 0 {
                // add pref and type
                // they are not supported by iOS and thus these values never change
                newOrg[kW3ContactFieldPrimary] = "false"
                newOrg[kW3ContactFieldType] = NSNull()
                var newOrgs = [[AnyHashable: Any]]()
                newOrgs.append(newOrg)
                array = newOrgs as NSObject
            } else {
                array = NSNull() as NSObject
            }
        } else {
            // no name fields requested
            return NSNull() as NSObject
        }
        return array ?? NSNull() as NSObject
    }
    
    // W3C Contacts expects an array of photos.  Can return photos in more than one format, currently
    // just returning the default format
    // Save the photo data into tmp directory and return FileURI - temp directory is deleted upon application exit
    func extractPhotos() -> NSObject {
        var photos: [[AnyHashable: Any]]? = nil
        if let hasImage = nonMutableRecord?.imageDataAvailable {
            if hasImage {
                if let photoId = nonMutableRecord?.identifier {
                    if let photoData = nonMutableRecord?.imageData {
                        // write to temp directory and store URI in photos array
                        // get the temp directory path
                        let photoPath = "\(NSTemporaryDirectory())/contact_photo_\(photoId)"
                        let filePath = URL(fileURLWithPath: photoPath)
                        // save file
                        var written = false
                        do {
                            try photoData.write(to: filePath, options: .atomic)
                            written = true
                        } catch {
                            //Do nothing
                        }
                        if written {
                            photos = [[AnyHashable: Any]]() /* TODO: .reserveCapacity(1) */
                            var newDict = [AnyHashable: Any](minimumCapacity: 2)
                            newDict[kW3ContactFieldValue] = filePath.absoluteString
                            newDict[kW3ContactFieldType] = "url"
                            newDict[kW3ContactFieldPrimary] = "false"
                            photos?.append(newDict)
                        }
                    }
                }
            }
        }
        return photos as NSObject? ?? NSNull() as NSObject
    }
    
    /**
     *    given an array of W3C Contact field names, create a dictionary of field names to extract
     *    if field name represents an object, return all properties for that object:  "name" - returns all properties in ContactName
     *    if field name is an explicit property, return only those properties:  "name.givenName - returns a ContactName with only ContactName.givenName
     *  if field contains ONLY ["*"] return all fields
     *    dictionary format:
     *    key is W3Contact #define
     *        value is NSMutableArray* for complex keys:  name,addresses,organizations, phone, emails, ims
     *        value is [NSNull null] for simple keys
     */
    class func calcReturnFields(_ fieldsArray: [Any]) -> [AnyHashable: Any] {
        // NSLog(@"getting self.returnFields");
        var d = [AnyHashable: Any](minimumCapacity: 1)
        if (fieldsArray.count > 0) {
            if (fieldsArray.count == 1) && (fieldsArray[0] as? String == "*") {
                return CDVContact.defaultFields()
                // return all fields
            }
            for i: Any in fieldsArray {
                // CB-7906 ignore NULL desired fields to avoid fatal exception
                if (i is NSNull) {
                    continue
                }
                var keys: [Any]? = nil
                var fieldStr: String? = nil
                if (i is NSNumber) {
                    fieldStr = "\((i as? String ?? ""))"
                }
                else {
                    fieldStr = i as? String
                }
                // see if this is specific property request in object - object.property
                let parts = fieldStr?.components(separatedBy: ".")
                // returns original string if no separator found
                let name: String? = parts?[0]
                var property: String? = nil
                if let part = parts {
                    if part.count > 1 {
                        property = part[1]
                    }
                }
                // see if this is a complex field by looking for its array of properties in objectAndProperties dictionary
                let fields: [String]?
                if let n = name {
                    fields = CDVContact.defaultObjectAndProperties()[n]
                    // if find complex name (name,addresses,organizations, phone, emails, ims) in fields, add name as key
                    // with array of associated properties as the value
                    if (fields != nil) && (property == nil) {
                        // request was for full object
                        keys = fields ?? [Any]()
                        if keys != nil {
                            d[n] = keys
                            // will replace if prop array already exists
                        }
                    } else if (fields != nil) && (property != nil) {
                        // found an individual property request  in form of name.property
                        // verify is real property name by using it as key in W3CtoAB
                        var abEquiv: String = ""
                        if let prop = property {
                            if let ab = CDVContact.defaultW3CtoAB()[prop] {
                                abEquiv = ab
                            }
                        }
                        if abEquiv != "" || CDVContact.defaultW3CtoNull().contains(property ?? "") {
                            // if existing array add to it
                            if (keys = d[n] as? [AnyHashable]) != nil {
                                keys?.append(property ?? "")
                            } else {
                                keys = [property!]
                                d[n] = keys
                            }
                        } else {
                            print("Contacts.find -- request for invalid property ignored: \(n).\(property!)")
                        }
                    } else {
                        // is an individual property, verify is real property name by using it as key in W3CtoAB
                        let valid = CDVContact.defaultW3CtoAB()[n]
                        if valid != nil || CDVContact.defaultW3CtoNull().contains(n) {
                            d[n] = NSNull()
                        }
                    }
                }
            }
        }
        if d.count == 0 {
            // no array or nothing in the array. W3C spec says to return nothing
            return [AnyHashable: Any]()
            // [Contact defaultFields];
        }
        return d
    }
    
    func value(forKeyIsArray dict: [AnyHashable: Any], key: String) -> Bool {
        var bArray = false
        let value = dict[key]
        if value != nil {
            bArray = value is [Any]
        }
        return bArray
    }
    
    /*
     * Search for the specified value in each of the fields specified in the searchFields dictionary.
     * NSString* value - the string value to search for (need clarification from W3C on how to search for dates)
     * NSDictionary* searchFields - a dictionary created via calcReturnFields where the key is the top level W3C
     *    object and the object is the array of specific fields within that object or null if it is a single property
     * RETURNS
     *    YES as soon as a match is found in any of the fields
     *    NO - the specified value does not exist in any of the fields in this contact
     *
     *  Note: I'm not a fan of returning in the middle of methods but have done it some in this method in order to
     *    keep the code simpler. bgibson
     */
    func foundValue(_ testValue: String, inFields searchFields: [AnyHashable: Any]) -> Bool {
        var bFound = false
        if (testValue.count == 0) {
            // nothing to find so return NO
            return false
        }
        // per W3C spec, always include id in search
        let recordId: String? = nonMutableRecord?.identifier
        if let rId = recordId {
            if (rId == testValue) {
                return true
            }
        }
        if searchFields == nil {
            // no fields to search
            return false
        }
        let containPred = NSPredicate(format: "SELF contains[cd] %@", testValue)
        if searchFields[kW3ContactNickname] != nil {
            bFound = containPred.evaluate(with: nonMutableRecord?.nickname)
            if bFound == true {
                return bFound
            }
        }
        if value(forKeyIsArray: searchFields, key: kW3ContactName) {
            // test name fields.  All are string properties obtained via ABRecordCopyValue except kW3ContactFormattedName
            if let fields = searchFields[kW3ContactName] as? [String] {
                for testItem: String in fields {
                    switch testItem {
                    case kW3ContactFormattedName:
                        var propValue: String = ""
                        if let prefix = nonMutableRecord?.namePrefix {
                            propValue = propValue + prefix + " "
                        }
                        if let firstName = nonMutableRecord?.givenName {
                            propValue = propValue + firstName + " "
                        }
                        if let middleName = nonMutableRecord?.middleName {
                            propValue = propValue + middleName + " "
                        }
                        if let lastName = nonMutableRecord?.familyName {
                            propValue = propValue + lastName + " "
                        }
                        if let suffix = nonMutableRecord?.nameSuffix {
                            propValue = propValue + suffix
                        }
                        if (propValue.count > 0) {
                            let range: NSRange? = (propValue as NSString?)?.range(of: testValue, options: .caseInsensitive)
                            bFound = range?.location != NSNotFound
                        }
                    case kW3ContactGivenName:
                        bFound = containPred.evaluate(with: nonMutableRecord?.givenName)
                    case kW3ContactFamilyName:
                        bFound = containPred.evaluate(with: nonMutableRecord?.familyName)
                    case kW3ContactMiddleName:
                        bFound = containPred.evaluate(with: nonMutableRecord?.middleName)
                    case kW3ContactHonorificPrefix:
                        bFound = containPred.evaluate(with: nonMutableRecord?.namePrefix)
                    case kW3ContactHonorificSuffix:
                        bFound = containPred.evaluate(with: nonMutableRecord?.nameSuffix)
                    default:
                        bFound = false
                    }
                    if bFound {
                        break
                    }
                }
            }
        }
        if !bFound && value(forKeyIsArray: searchFields, key: kW3ContactPhoneNumbers) {
            if let fields = searchFields[kW3ContactPhoneNumbers] as? [String] {
                if let numbers = nonMutableRecord?.phoneNumbers {
                    for number in numbers {
                        for testItem: String in fields {
                            switch testItem {
                            case kW3ContactFieldType:
                                bFound = containPred.evaluate(with: number.label)
                            case kW3ContactFieldValue:
                                bFound = containPred.evaluate(with: number.value.stringValue)
                            default:
                                bFound = false
                            }
                            if bFound {
                                break
                            }
                        }
                        if bFound {
                            break
                        }
                    }
                }
            }
        }
        if !bFound && value(forKeyIsArray: searchFields, key: kW3ContactEmails) {
            if let fields = searchFields[kW3ContactEmails] as? [String] {
                if let addresses = nonMutableRecord?.emailAddresses {
                    for address in addresses {
                        for testItem: String in fields {
                            var value: Any = ""
                            switch testItem {
                            case kW3ContactFieldType:
                                bFound = containPred.evaluate(with: address.label)
                                value = address.label
                            case kW3ContactFieldValue:
                                bFound = containPred.evaluate(with: address.value)
                                value = address.value
                            default:
                                bFound = false
                            }
                            if bFound {
                                break
                            }
                        }
                        if bFound {
                            break
                        }
                    }
                }
            }
        }
        if !bFound && value(forKeyIsArray: searchFields, key: kW3ContactAddresses) {
            if let fields = searchFields[kW3ContactAddresses] as? [String] {
                if let addresses = nonMutableRecord?.postalAddresses {
                    for address in addresses {
                        for testItem: String in fields {
                            switch testItem {
                            case kW3ContactStreetAddress:
                                bFound = containPred.evaluate(with: address.value.street)
                            case kW3ContactLocality:
                                bFound = containPred.evaluate(with: address.value.city)
                            case kW3ContactRegion:
                                bFound = containPred.evaluate(with: address.value.state)
                            case kW3ContactPostalCode:
                                bFound = containPred.evaluate(with: address.value.postalCode)
                            case kW3ContactCountry:
                                bFound = containPred.evaluate(with: address.value.country)
                            default:
                                bFound = false
                            }
                            if bFound {
                                break
                            }
                        }
                        if bFound {
                            break
                        }
                    }
                }
            }
        }
        if !bFound && value(forKeyIsArray: searchFields, key: kW3ContactIms) {
            if let fields = searchFields[kW3ContactIms] as? [String] {
                if let addresses = nonMutableRecord?.instantMessageAddresses {
                    for address in addresses {
                        for testItem: String in fields {
                            switch testItem {
                            case kW3ContactImType:
                                bFound = containPred.evaluate(with: address.label)
                            case kW3ContactImValue:
                                bFound = containPred.evaluate(with: address.value)
                            default:
                                bFound = false
                            }
                            if bFound {
                                break
                            }
                        }
                        if bFound {
                            break
                        }
                    }
                }
            }
        }
        if !bFound && value(forKeyIsArray: searchFields, key: kW3ContactOrganizations) {
            if let fields = searchFields[kW3ContactOrganizations] as? [String] {
                for testItem: String in fields {
                    switch testItem {
                    case kW3ContactOrganizationName:
                        bFound = containPred.evaluate(with: nonMutableRecord?.organizationName)
                    case kW3ContactTitle:
                        bFound = containPred.evaluate(with: nonMutableRecord?.jobTitle)
                    case kW3ContactDepartment:
                        bFound = containPred.evaluate(with: nonMutableRecord?.departmentName)
                    default:
                        break
                    }
                    if bFound == true {
                        break
                    }
                }
            }
        }
        if !bFound && searchFields[kW3ContactNote] != nil {
            bFound = containPred.evaluate(with: nonMutableRecord?.note)
        }
        // if searching for a date field is requested, get the date field as a localized string then look for match against testValue in date string
        // searching for photos is not supported
        if !bFound && searchFields[kW3ContactBirthday] != nil {
            if let bday = nonMutableRecord?.birthday {
                let dateString: String? = NSCalendar.current.date(from: bday)?.description(with: NSLocale.current)
                bFound = containPred.evaluate(with: dateString)
            }
        }
        if !bFound && value(forKeyIsArray: searchFields, key: kW3ContactUrls) {
            if let fields = searchFields[kW3ContactUrls] as? [String] {
                if let addresses = nonMutableRecord?.urlAddresses {
                    for address in addresses {
                        for testItem: String in fields {
                            switch testItem {
                            case kW3ContactFieldType:
                                bFound = containPred.evaluate(with: address.label)
                            case kW3ContactFieldValue:
                                bFound = containPred.evaluate(with: address.value)
                            default:
                                bFound = false
                            }
                            if bFound {
                                break
                            }
                        }
                        if bFound {
                            break
                        }
                    }
                }
            }
        }
        return bFound
    }
}

