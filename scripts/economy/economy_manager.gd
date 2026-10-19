extends Node
## Economy Manager — handles wallet, transactions, and financial state

signal money_changed(new_balance: int)
signal transaction_completed(amount: int, reason: String)

var balance: int = 50000 # Starting money: 50,000 MMK
var transactions: Array[Dictionary] = []

func _ready() -> void:
	if transactions.is_empty():
		record_transaction(balance, "Starting Capital (စတင်ငွေ)")

func get_balance() -> int:
	return balance

func can_afford(amount: int) -> bool:
	return balance >= amount

func record_transaction(amount: int, reason: String) -> void:
	var entry: Dictionary = {
		"amount": amount,
		"reason": reason if reason != "" else ("Income" if amount > 0 else "Expense"),
		"time": Time.get_time_string_from_system()
	}
	transactions.push_front(entry)
	if transactions.size() > 50:
		transactions.pop_back()

func get_transactions() -> Array[Dictionary]:
	return transactions

func add_money(amount: int, reason: String = "") -> void:
	if amount <= 0:
		return
	balance += amount
	record_transaction(amount, reason)
	money_changed.emit(balance)
	transaction_completed.emit(amount, reason)

func spend_money(amount: int, reason: String = "") -> bool:
	if amount <= 0 or balance < amount:
		return false
	balance -= amount
	record_transaction(-amount, reason)
	money_changed.emit(balance)
	transaction_completed.emit(-amount, reason)
	return true

func set_balance(new_balance: int) -> void:
	balance = max(0, new_balance)
	money_changed.emit(balance)

func get_save_data() -> Dictionary:
	return {"balance": balance, "transactions": transactions}

func load_save_data(data: Dictionary) -> void:
	balance = data.get("balance", 50000)
	transactions.clear()
	var tx_val: Variant = data.get("transactions", [])
	if tx_val is Array:
		for t in tx_val:
			if t is Dictionary:
				transactions.append(t)
	money_changed.emit(balance)
