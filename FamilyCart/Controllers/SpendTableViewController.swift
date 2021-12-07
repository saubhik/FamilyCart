import UIKit
import Firebase

class SpendTableViewController: UITableViewController {
  let cartsRef = Database.database().reference(withPath: "grocery-carts")
  let usersRef = Database.database().reference(withPath: "online")
  
  var totalPriceOneWeek: Decimal = 0.0
  var totalPriceThreeWeeks: Decimal = 0.0
  var totalPriceThreeMonths: Decimal = 0.0
  var totalPriceByCurrentUser: Decimal = 0.0
  
  var user: User?
  var handle: AuthStateDidChangeListenerHandle?
  var carts: [GroceryCart]?
  
  @IBOutlet weak var firstCell: UITableViewCell!
  @IBOutlet weak var secondCell: UITableViewCell!
  @IBOutlet weak var thirdCell: UITableViewCell!
  @IBOutlet weak var fourthCell: UITableViewCell!
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(true)
    
    self.handle = Auth.auth().addStateDidChangeListener { _, user in
      guard let user = user else { return }
      self.user = User(authData: user)
      
      let currentUserRef = self.usersRef.child(user.uid)
      currentUserRef.setValue(user.email)
      currentUserRef.onDisconnectRemoveValue()
    }
    
    cartsRef.getData(completion: { error, snapshot in
      guard error == nil else {
        print(error!.localizedDescription)
        return
      }
      
      let now = Date()
      let startDateThreeMonthsBack = Calendar.current.date(byAdding: .month, value: -3, to: now)
      let startDateThreeWeeksBack = Calendar.current.date(byAdding: .weekOfMonth, value: -3, to: now)
      let startDateOneWeekBack = Calendar.current.date(byAdding: .weekOfMonth, value: -1, to: now)
      
      var totalPriceOneWeek: Decimal = 0.0
      var totalPriceThreeWeeks: Decimal = 0.0
      var totalPriceThreeMonths: Decimal = 0.0
      var totalPriceByCurrentUser: Decimal = 0.0
      
      var carts: [GroceryCart] = []
      
      for child in snapshot.children {
        if
          let snapshot = child as? DataSnapshot,
          let cart = GroceryCart(snapshot: snapshot) {
          
          if cart.addedOn > startDateOneWeekBack! {
            totalPriceOneWeek += cart.totalPrice
          }
          
          if cart.addedOn > startDateThreeWeeksBack! {
            totalPriceThreeWeeks += cart.totalPrice
          }
          
          if cart.addedOn > startDateThreeMonthsBack! {
            totalPriceThreeMonths += cart.totalPrice
          }
          
          carts.append(cart)
        }
      }
      
      self.totalPriceOneWeek = totalPriceOneWeek
      self.totalPriceThreeWeeks = totalPriceThreeWeeks
      self.totalPriceThreeMonths = totalPriceThreeMonths
      self.totalPriceByCurrentUser = totalPriceByCurrentUser
      self.carts = carts
    })
    
    firstCell.textLabel?.text = "Monthly Average (over last 3 months)"
    secondCell.textLabel?.text = "Weekly Average (over last 3 weeks)"
    thirdCell.textLabel?.text = "Last Week's Total"
    fourthCell.textLabel?.text = "Total Purchase By Current User"
    
    firstCell.detailTextLabel?.text = "..."
    secondCell.detailTextLabel?.text = "..."
    thirdCell.detailTextLabel?.text = "..."
    fourthCell.detailTextLabel?.text = "..."
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(true)
    
    let username = self.user?.email.components(separatedBy: "@").first
    fourthCell.textLabel?.text = "Total Purchase By \"\(username ?? "User")\""
    
    for cart in self.carts! {
      if cart.addedByUser == self.user?.email {
        self.totalPriceByCurrentUser += cart.totalPrice
      }
    }
    
    let averageThreeWeeks = self.totalPriceThreeWeeks / 3.0
    let averageThreeMonths = self.totalPriceThreeMonths / 3.0
    
    let priceFormatter = NumberFormatter()
    priceFormatter.numberStyle = .currency
    
    let averageThreeWeeksString = priceFormatter.string(from: averageThreeWeeks as NSNumber)
    let averageThreeMonthsString = priceFormatter.string(from: averageThreeMonths as NSNumber)
    let totalPriceOneWeekString = priceFormatter.string(from: self.totalPriceOneWeek as NSNumber)
    let totalPriceByCurrentUserString = priceFormatter.string(from: self.totalPriceByCurrentUser as NSNumber)
    
    firstCell.detailTextLabel?.text = averageThreeMonthsString
    secondCell.detailTextLabel?.text = averageThreeWeeksString
    thirdCell.detailTextLabel?.text = totalPriceOneWeekString
    fourthCell.detailTextLabel?.text = totalPriceByCurrentUserString
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(true)
    guard let handle = handle else { return }
    Auth.auth().removeStateDidChangeListener(handle)
  }
}
