extends Node

signal success(profile)
signal failure(message)
signal session_invalid

var base_url := ""
var active_requests: Array[HTTPRequest] = []

func _is_allowed_transport() -> bool:
    if base_url.begins_with("https://"):
        return true
    if base_url.begins_with("http://127.0.0.1:") or base_url.begins_with("http://localhost:"):
        return true
    return false

func configure(url: String) -> void:
    base_url = url.trim_suffix("/")

func login(username: String, password: String) -> void:
    _post("/v1/auth/login", {"username": username, "password": password}, "login")

func register(username: String, password: String, character_id: String, avatar_id: int = 0) -> void:
    _post("/v1/auth/register", {"username": username, "password": password, "character": character_id, "avatar_id": avatar_id}, "register")

func restore_session(token: String) -> void:
    if base_url.is_empty() or token.is_empty():
        return
    if not _is_allowed_transport():
        failure.emit("Remote authentication must use HTTPS.")
        return
    var headers := PackedStringArray(["Accept: application/json", "Authorization: Bearer " + token])
    _request("/v1/auth/verify", HTTPClient.METHOD_GET, headers, "", "restore", token)

func logout(token: String) -> void:
    if base_url.is_empty() or token.is_empty():
        return
    if not _is_allowed_transport():
        failure.emit("Remote authentication must use HTTPS.")
        return
    var headers := PackedStringArray(["Accept: application/json", "Authorization: Bearer " + token])
    _request("/v1/auth/logout", HTTPClient.METHOD_POST, headers, "", "logout", token)

func _post(path: String, body: Dictionary, operation: String) -> void:
    if base_url.is_empty():
        failure.emit("Authentication server is not configured.")
        return
    if not _is_allowed_transport():
        failure.emit("Remote authentication must use HTTPS.")
        return
    var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
    _request(path, HTTPClient.METHOD_POST, headers, JSON.stringify(body), operation)

func _request(path: String, method: HTTPClient.Method, headers: PackedStringArray, body: String, operation: String, session_token: String = "") -> void:
    var request := HTTPRequest.new()
    request.timeout = 10.0
    add_child(request)
    active_requests.append(request)
    request.request_completed.connect(
        func(result: int, response_code: int, response_headers: PackedStringArray, response_body: PackedByteArray) -> void:
            _on_request_completed(request, operation, session_token, result, response_code, response_headers, response_body),
        CONNECT_ONE_SHOT
    )
    var err := request.request(base_url + path, headers, method, body)
    if err != OK:
        _remove_request(request)
        failure.emit("Request could not be sent.")
        
func _remove_request(request: HTTPRequest) -> void:
    active_requests.erase(request)
    if is_instance_valid(request):
        request.queue_free()

func _on_request_completed(request: HTTPRequest, operation: String, session_token: String, result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    _remove_request(request)
    if result != HTTPRequest.RESULT_SUCCESS:
        failure.emit("Authentication service unavailable.")
        return

    var payload = JSON.parse_string(body.get_string_from_utf8())
    var message := str(payload.get("error", "Authentication failed.")) if payload is Dictionary else "Authentication failed."

    if operation == "logout":
        if response_code >= 200 and response_code < 300:
            return
        failure.emit(message)
        return

    if operation == "restore":
        if response_code >= 200 and response_code < 300 and payload is Dictionary:
            var restored: Dictionary = payload.duplicate(true)
            restored["token"] = session_token
            if str(restored.get("username", "")).is_empty():
                failure.emit("Saved session is invalid.")
                return
            restored["avatar_id"] = clampi(int(restored.get("avatar_id", 0)), 0, 29)
            success.emit(restored)
            return
        if response_code == 401 or response_code == 403:
            session_invalid.emit()
            return
        failure.emit(message)
        return

    if response_code >= 200 and response_code < 300 and payload is Dictionary:
        var token := str(payload.get("token", ""))
        var username := str(payload.get("username", ""))
        if token.is_empty() or username.is_empty():
            failure.emit("Authentication service returned an invalid session.")
            return
        success.emit(payload)
        return

    failure.emit(message)
