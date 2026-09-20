extends Node

signal success(profile)
signal failure(message)

var http: HTTPRequest
var base_url := ""

func _ready() -> void:
    http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_request_completed)

func configure(url: String) -> void:
    base_url = url.trim_suffix("/")

func _is_allowed_transport() -> bool:
    if base_url.begins_with("https://"):
        return true
    if base_url.begins_with("http://127.0.0.1:") or base_url.begins_with("http://localhost:"):
        return true
    return false

func login(username: String, password: String) -> void:
    _post("/v1/auth/login", {"username": username, "password": password})

func register(username: String, password: String, character_id: String) -> void:
    _post("/v1/auth/register", {"username": username, "password": password, "character": character_id})

func logout(token: String) -> void:
    if base_url.is_empty() or token.is_empty():
        return
    if not _is_allowed_transport():
        failure.emit("Remote authentication must use HTTPS.")
        return
    var headers := PackedStringArray(["Accept: application/json", "Authorization: Bearer " + token])
    var err := http.request(base_url + "/v1/auth/logout", headers, HTTPClient.METHOD_POST)
    if err != OK:
        failure.emit("Logout request could not be sent.")

func _post(path: String, body: Dictionary) -> void:
    if base_url.is_empty():
        failure.emit("Authentication server is not configured.")
        return
    if not _is_allowed_transport():
        failure.emit("Remote authentication must use HTTPS.")
        return
    var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
    var err := http.request(base_url + path, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
    if err != OK:
        failure.emit("Request could not be sent.")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS:
        failure.emit("Authentication service unavailable.")
        return
    var payload = JSON.parse_string(body.get_string_from_utf8())
    if response_code >= 200 and response_code < 300 and payload is Dictionary:
        success.emit(payload)
    else:
        failure.emit(str(payload.get("error", "Authentication failed.")) if payload is Dictionary else "Authentication failed.")
