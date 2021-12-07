import Firebase

struct GroceryItem {
  let ref: DatabaseReference?
  let key: String
  let name: String
  let addedByUser: String
  let price: Decimal
  let addedOn: Date
  var completed: Bool
  
  // MARK: Initialize with Raw Data
  init(name: String, addedByUser: String, price: Decimal, completed: Bool, addedOn: Date, key: String = "") {
    self.ref = nil
    self.key = key
    self.name = name
    self.addedByUser = addedByUser
    self.price = price
    self.completed = completed
    self.addedOn = addedOn
  }
  
  // MARK: Initialize with Firebase DataSnapshot
  init?(snapshot: DataSnapshot) {
    guard
      let value = snapshot.value as? [String: AnyObject],
      let name = value["name"] as? String,
      let addedByUser = value["addedByUser"] as? String,
      let completed = value["completed"] as? Bool,
      let price = value["price"] as? NSNumber,
      let addedOn = value["addedOn"] as? NSNumber
    else {
      return nil
    }
    
    self.ref = snapshot.ref
    self.key = snapshot.key
    self.name = name
    self.addedByUser = addedByUser
    self.price = price.decimalValue
    self.completed = completed
    self.addedOn = Date(timeIntervalSince1970: TimeInterval(truncating: addedOn))
  }
  
  // MARK: Convert GroceryItem to AnyObject
  func toAnyObject() -> Any {
    return [
      "name": name,
      "addedByUser": addedByUser,
      "price": price,
      "completed": completed,
      "addedOn": addedOn.timeIntervalSince1970
    ]
  }
}
