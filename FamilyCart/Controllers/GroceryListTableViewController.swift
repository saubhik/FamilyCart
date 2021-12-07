import UIKit
import Firebase

class GroceryListTableViewController: UITableViewController {
  // MARK: Constants
  let listToUsers = "ListToUsers"
  
  var cartRef = Database.database().reference(withPath: "grocery-carts")
  
  var ref = Database.database().reference(withPath: "grocery-carts")
  var refObservers: [DatabaseHandle] = []
  
  let usersRef = Database.database().reference(withPath: "online")
  var usersRefObservers: [DatabaseHandle] = []
  
  // MARK: Properties
  var items: [GroceryItem] = []
  var user: User?
  var handle: AuthStateDidChangeListenerHandle?
  var cartName: String = ""
  
  @IBOutlet weak var onlineUserCount: UIButton!
  
  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.allowsMultipleSelectionDuringEditing = false
    
    self.onlineUserCount.setTitle("1", for: .normal)
    
    navigationItem.title = "Cart (\(cartName))"
    
    ref = ref.child(cartName).child("grocery-items")
    cartRef = cartRef.child(cartName)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let completed = ref
      .queryOrdered(byChild: "completed")
      .observe(.value) { snapshot in
        var newItems: [GroceryItem] = []
        for child in snapshot.children {
          if
            let snapshot = child as? DataSnapshot,
            let groceryItem = GroceryItem(snapshot: snapshot) {
            newItems.append(groceryItem)
          }
        }
        self.items = newItems
        self.tableView.reloadData()
      }
    refObservers.append(completed)
    
    handle = Auth.auth().addStateDidChangeListener { _, user in
      guard let user = user else { return }
      self.user = User(authData: user)
      
      let currentUserRef = self.usersRef.child(user.uid)
      currentUserRef.setValue(user.email)
      currentUserRef.onDisconnectRemoveValue()
    }
    
    let users = usersRef.observe(.value) { snapshot in
      if snapshot.exists() {
        self.onlineUserCount.setTitle(snapshot.childrenCount.description, for: .normal)
      } else {
        self.onlineUserCount.setTitle("0", for: .normal)
      }
    }
    usersRefObservers.append(users)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(true)
    refObservers.forEach(ref.removeObserver(withHandle:))
    refObservers = []
    usersRefObservers.forEach(usersRef.removeObserver(withHandle:))
    usersRefObservers = []
    guard let handle = handle else { return }
    Auth.auth().removeStateDidChangeListener(handle)
  }
  
  // MARK: UITableView Delegate methods
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryItem = items[indexPath.row]
    
    let priceFormatter = NumberFormatter()
    priceFormatter.numberStyle = .currency
    let priceString = priceFormatter.string(from: groceryItem.price as NSNumber)
    
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone.current
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    let dateString = dateFormatter.string(from: groceryItem.addedOn)
    
    cell.textLabel?.text = groceryItem.name
    cell.detailTextLabel?.text = groceryItem.addedByUser + ", " + dateString + ", " + (priceString ?? "$0.00")
    
    toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let groceryItem = items[indexPath.row]
      groceryItem.ref?.removeValue()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    let groceryItem = items[indexPath.row]
    let toggledCompletion = !groceryItem.completed
    toggleCellCheckbox(cell, isCompleted: toggledCompletion)
    groceryItem.ref?.updateChildValues(["completed": toggledCompletion])
    items[indexPath.row].completed = toggledCompletion
    
    var allCompleted: Bool = true
    for item in self.items {
      allCompleted = allCompleted && item.completed
    }
    self.cartRef.updateChildValues(["completed": allCompleted])
  }
  
  func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
    if !isCompleted {
      cell.accessoryType = .none
      cell.textLabel?.textColor = .black
      cell.detailTextLabel?.textColor = .black
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = .gray
      cell.detailTextLabel?.textColor = .gray
    }
  }
  
  // MARK: Add Item
  @IBAction func addItemDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(
      title: "Grocery Item",
      message: "Add an Item",
      preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
      guard
        let itemNameField = alert.textFields?[0],
        let itemName = itemNameField.text,
        let itemPriceField = alert.textFields?[1],
        let itemPrice = Decimal(string: itemPriceField.text!),
        let user = self.user
      else { return }
      
      let groceryItem = GroceryItem(
        name: itemName,
        addedByUser: user.email,
        price: itemPrice,
        completed: false,
        addedOn: Date()
      )
      
      let groceryItemRef = self.ref.child(itemName.lowercased())
      groceryItemRef.setValue(groceryItem.toAnyObject())
      
      var totalPrice: Decimal = itemPrice
      for item in self.items {
        totalPrice += item.price
      }
      self.cartRef.updateChildValues(["totalPrice": totalPrice, "completed": false])
    }
    
    let cancelAction = UIAlertAction(
      title: "Cancel",
      style: .cancel)
    
    alert.addTextField { (textField) in
      textField.placeholder = "Enter item name"
    }
    
    alert.addTextField { (textField) in
      textField.placeholder = "Enter item price"
    }
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  @IBAction func onlineUserCountDidTouch(_ sender: Any) {
    performSegue(withIdentifier: listToUsers, sender: nil)
  }
}
