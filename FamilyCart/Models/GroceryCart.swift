import Firebase

struct GroceryCart {
  let ref: DatabaseReference?
  let key: String
  let name: String
  let addedByUser: String
  let addedOn: Date
  var completed: Bool
  var totalPrice: Decimal
  var groceryItems: [GroceryItem]
  
  // MARK: Initialize with Raw Data
  init(name: String, addedByUser: String, addedOn: Date, key: String = "") {
    self.ref = nil
    self.key = key
    self.name = name
    self.addedByUser = addedByUser
    self.groceryItems = []
    self.completed = false
    self.totalPrice = 0
    self.addedOn = addedOn
  }
  
  // MARK: Initialize with Firebase DataSnapshot
  init?(snapshot: DataSnapshot) {
    guard
      let value = snapshot.value as? [String: AnyObject],
      let name = value["name"] as? String,
      let addedByUser = value["addedByUser"] as? String,
      let completed = value["completed"] as? Bool,
      let totalPrice = value["totalPrice"] as? NSNumber,
      let addedOn = value["addedOn"] as? NSNumber
    else {
      return nil
    }
    
    self.ref = snapshot.ref
    self.key = snapshot.key
    self.name = name
    self.addedByUser = addedByUser
    self.completed = completed
    self.totalPrice = totalPrice.decimalValue
    self.addedOn = Date(timeIntervalSince1970: TimeInterval(truncating: addedOn))
    
    self.groceryItems = []
    for child in snapshot.childSnapshot(forPath: "grocery-items").children {
      if
        let snapshot = child as? DataSnapshot,
        let groceryItem = GroceryItem(snapshot: snapshot) {
        self.groceryItems.append(groceryItem)
      }
    }
  }
  
  // MARK: Convert GroceryCart to AnyObject
  func toAnyObject() -> Any {
    return [
      "name": name,
      "addedByUser": addedByUser,
      "completed": completed,
      "totalPrice": totalPrice,
      "addedOn": addedOn.timeIntervalSince1970,
      "grocery-items": groceryItems,
    ]
  }
}
