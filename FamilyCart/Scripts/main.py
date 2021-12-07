import json
import random
import time
from datetime import date, timedelta


def dateRange(startDate: date, endDate: date):
    # Iterator for every two days.
    for n in range(0, int((endDate - startDate).days), 2):
        yield startDate + timedelta(n)


def generateItemsForDate(date: date, user: str):
    items = {}
    totalPrice = 0.0
    for itemNum in range(1, random.randint(5, 20)):
        itemName = f"item-{itemNum}"
        itemPrice = round(random.uniform(5.0, 25.0), 2)
        totalPrice += itemPrice
        items[itemName] = {
            "addedByUser": user,
            "addedOn": time.mktime(date.timetuple()),
            "completed": True,
            "name": itemName,
            "price": itemPrice
        }
    return items, round(totalPrice, 2)


def generateSyntheticData():
    # Generate data since last 3 months, with 1 cart every 2 days.
    data = dict()
    data["online"] = {"FrGpkXStpdTBHNl8to76P9GteHY2": "saubhik@gatech.edu"}

    cartData = dict()
    startDate = date(2021, 9, 1)  # From September 1, 2021
    endDate = date(2021, 12, 6)  # Till December 6, 2021
    users = ["saubhik@gatech.edu", "ankita@gatech.edu"]

    cartNum = 0
    for singleDate in dateRange(startDate=startDate, endDate=endDate):
        cartName = f"cart-{cartNum}"
        user = random.choice(users)
        groceryItems, totalPrice = generateItemsForDate(date=singleDate, user=user)
        cartData[cartName] = {
            "addedByUser": user,
            "addedOn": time.mktime(singleDate.timetuple()),
            "completed": True,
            "name": cartName,
            "grocery-items": groceryItems,
            "totalPrice": totalPrice
        }
        cartNum += 1

    data["grocery-carts"] = cartData

    jsonFile = open("dataToImport.json", "w")
    jsonFile.write(json.dumps(data))
    jsonFile.close()


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    generateSyntheticData()
