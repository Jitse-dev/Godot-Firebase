extends Control

var API_key = "AIzaSyC3EpQDnp9wxuRDr-NdrkmQOtn6w7jf5js"

var http_request: HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

# Sign up with email and password via REST API
func sign_up(email: String, password: String):
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + API_key
	var body = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	var headers = ["Content-Type: application/json"]
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# Sign in with email and password via REST API
func sign_in(email: String, password: String):
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + API_key
	var body = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	var headers = ["Content-Type: application/json"]
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# Handle completed HTTP requests
func _on_request_completed(_result, response_code, _headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		# Check if this was a sign-up or sign-in by the endpoint (not possible here, but you can track it yourself)
		%StateLabel.text = "Success! User logged in or signed up."
		Global.user_email = json.email if "email" in json else "User"
		Global.user_id = json.localId
		Global.idToken = json.idToken
		Global.refreshToken = json.refreshToken
		Global.api_KEY = str(API_key)
		get_tree().change_scene_to_file("res://game.tscn")
		print("Success: ", json)
	else:
		var error_msg = json.error.message if json and "error" in json and "message" in json.error else "Unknown error"
		%StateLabel.text = "Error: " + error_msg
		print("Failed: ", json)

# Button handlers
func _on_login_button_pressed():
	var email = %EmailLineEdit.text
	var password = %PasswordLineEdit.text
	sign_in(email, password)
	%StateLabel.text = "Logging in..."

func _on_sign_up_button_pressed():
	var email = %EmailLineEdit.text
	var password = %PasswordLineEdit.text
	sign_up(email, password)
	%StateLabel.text = "Signing up..."
