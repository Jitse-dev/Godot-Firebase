extends Sprite2D

var click_count: int = 0
var user_id = Global.user_id
var idToken = Global.idToken
var firestore_url = "https://firestore.googleapis.com/v1/projects/test-game-57b50/databases/(default)/documents/Player_data/{userId}"

var http_request: HTTPRequest
var token_refresh_request: HTTPRequest
var is_processing = false
var request_queue = []

func _ready():
	# Initialize HTTP requests
	http_request = HTTPRequest.new()
	token_refresh_request = HTTPRequest.new()
	add_child(http_request)
	add_child(token_refresh_request)
	http_request.request_completed.connect(_on_firestore_response)
	token_refresh_request.request_completed.connect(_on_token_refresh_response)
	
	load_click_count()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		if get_rect().has_point(to_local(mouse_pos)):
			click_count += 1
			%Clicks.text = "Clicks: " + str(click_count)
			save_click_count()

func save_click_count():
	if user_id == "" or idToken == "":
		print("Cannot save: Missing credentials")
		return
	
	var request = {
		"type": "save",
		"url": firestore_url.replace("{userId}", user_id),
		"headers": [
			"Content-Type: application/json",
			"Authorization: Bearer " + idToken
		],
		"method": HTTPClient.METHOD_PATCH,
		"body": JSON.stringify({
			"fields": {"Player_Clicks": {"integerValue": click_count}}
		})
	}
	queue_request(request)

func load_click_count():
	if user_id == "" or idToken == "":
		print("Cannot load: Missing credentials")
		return
	
	var request = {
		"type": "load",
		"url": firestore_url.replace("{userId}", user_id),
		"headers": [
			"Content-Type: application/json",
			"Authorization: Bearer " + idToken
		],
		"method": HTTPClient.METHOD_GET
	}
	queue_request(request)

func queue_request(request):
	request_queue.push_back(request)
	process_next_request()

func process_next_request():
	if is_processing or request_queue.is_empty():
		return
	
	is_processing = true
	var current_request = request_queue.pop_front()
	var error = http_request.request(
		current_request["url"],
		current_request["headers"],
		current_request["method"],
		current_request.get("body", "")
	)
	
	if error != OK:
		print("Request failed to start: ", error)
		is_processing = false
		process_next_request()

func refresh_auth_token():
	var url = "https://securetoken.googleapis.com/v1/token?key=" + Global.API_KEY
	var body = "grant_type=refresh_token&refresh_token=" + Global.refreshToken
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	token_refresh_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_firestore_response(_result, response_code, _headers, body):
	is_processing = false
	
	# Handle token expiration
	if response_code == 401:
		print("Token expired, refreshing...")
		refresh_auth_token()
		return
	
	var body_text = body.get_string_from_utf8()
	
	if response_code == 404:
		print("Document not found, creating initial record")
		click_count = 0
		%Clicks.text = "Clicks: 0"
		save_click_count()
		return
	
	if response_code != 200:
		print("Firestore error [", response_code, "]: ", body_text)
		process_next_request()
		return
	
	var json = JSON.parse_string(body_text)
	if json == null:
		print("JSON parse error")
		process_next_request()
		return
	
	# Handle GET response (load)
	if "fields" in json and "Player_Clicks" in json.fields:
		click_count = int(json.fields.Player_Clicks.integerValue)
		%Clicks.text = "Clicks: " + str(click_count)
	
	process_next_request()

func _on_token_refresh_response(_result, response_code, _headers, body):
	var body_text = body.get_string_from_utf8()
	
	if response_code != 200:
		print("Token refresh failed [", response_code, "]: ", body_text)
		return
	
	var json = JSON.parse_string(body_text)
	if json:
		# Update global tokens
		Global.idToken = json.get("id_token", "")
		Global.refreshToken = json.get("refresh_token", Global.refreshToken)
		idToken = Global.idToken
		print("Token refreshed successfully")
	
	# Retry requests after token refresh
	process_next_request()
