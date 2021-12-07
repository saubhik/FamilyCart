import UIKit
import Firebase

class GroceryCartTableViewController: UITableViewController {
  // MARK: Constants
  let cartsToUsers = "CartsToUsers"
  let cartsToSpend = "CartsToSpend"
  let ref = Database.database().reference(withPath: "grocery-carts")
  var refObservers: [DatabaseHandle] = []
  
  let usersRef = Database.database().reference(withPath: "online")
  var usersRefObservers: [DatabaseHandle] = []
  
  // MARK: Properties
  var carts: [GroceryCart] = []
  var user: User?
  var selectedCartName: String = ""
  var handle: AuthStateDidChangeListenerHandle?
  
  @IBOutlet weak var onlineUserCount: UIButton!
  
  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.allowsMultipleSelectionDuringEditing = false
    
    onlineUserCount.setTitle("1", for: .normal)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let completed = ref
      .queryOrdered(byChild: "addedOn")
      .observe(.value) { snapshot in
        var newCarts: [GroceryCart] = []
        for child in snapshot.children {
          if
            let snapshot = child as? DataSnapshot,
            let groceryCart = GroceryCart(snapshot: snapshot) {
            newCarts.append(groceryCart)
          }
        }
        newCarts = newCarts.reversed()
        self.carts = newCarts
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
    return carts.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryCart = carts[indexPath.row]
    
    let priceFormatter = NumberFormatter()
    priceFormatter.numberStyle = .currency
    let totalPriceString = priceFormatter.string(from: groceryCart.totalPrice as NSNumber)
    
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone.current
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    let dateString = dateFormatter.string(from: groceryCart.addedOn)
    
    cell.textLabel?.text = groceryCart.name
    cell.detailTextLabel?.text = groceryCart.addedByUser + ", " + dateString + ", " + (totalPriceString ?? "$0.00")
    
    toggleCellCheckbox(cell, isCompleted: groceryCart.completed)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let groceryCart = carts[indexPath.row]
      groceryCart.ref?.removeValue()
    }
  }
  
  override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
    guard let _ = tableView.cellForRow(at: indexPath) else { return }
    let groceryCart = carts[indexPath.row]
    selectedCartName = groceryCart.name
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "CartsToList" {
      let groceryListTableViewController: GroceryListTableViewController = segue.destination as! GroceryListTableViewController
      groceryListTableViewController.cartName = selectedCartName
    }
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
      title: "Grocery Cart",
      message: "Add a Cart",
      preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
      guard
        let textField = alert.textFields?.first,
        let text = textField.text,
        let user = self.user
      else { return }
      
      let groceryCart = GroceryCart(
        name: text,
        addedByUser: user.email,
        addedOn: Date()
      )
      
      let groceryCartRef = self.ref.child(text.lowercased())
      groceryCartRef.setValue(groceryCart.toAnyObject())
    }
    
    let cancelAction = UIAlertAction(
      title: "Cancel",
      style: .cancel)
    
    alert.addTextField()
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  @IBAction func onlineUserCountDidTouch(_ sender: Any) {
    performSegue(withIdentifier: cartsToUsers, sender: nil)
  }
  
  @IBAction func spendDidTouch(_ sender: Any) {
    performSegue(withIdentifier: cartsToSpend, sender: nil)
  }
}
