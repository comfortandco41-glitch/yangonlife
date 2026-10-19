extends Node
## Economy Manager — handles wallet, transactions, and financial state

signal money_changed(new_balance: int)
signal transaction_completed(amount: int, reason: String)

var balance: int = 50000 # Starting money: 50,000 MMK

func get_balance() -> int:
	return balance

func can_afford(amount: int) -> bool:
	return balance >= amount

func add_money(amount: int, reason: String = "") -> void:
	if amount <= 0:
		return
	balance += amount
	money_changed.emit(balance)
	transaction_completed.emit(amount, reason)

func spend_money(amount: int, reason: String = "") -> bool:
	if amount <= 0 or balance < amount:
		return false
	balance -= amount
	money_changed.emit(balance)
	transaction_completed.emit(-amount, reason)
	return true

func set_balance(new_balance: int) -> void:
	balance = max(0, new_balance)
	money_changed.emit(balance)

func get_save_data() -> Dictionary:
	return {"balance": balance}

func load_save_data(data: Dictionary) -> void:
	balance = data.get("balance", 50000)
	money_changed.emit(balance)
