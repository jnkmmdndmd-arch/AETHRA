extends Node

signal success(profile)
signal failure(message)
signal session_invalid

const LOCAL_ACCOUNTS_PATH := "user://aethra_accounts.json"
const LOCAL_HASH_ROUNDS := 10000
const ALLOWED_CHARACTERS := ["ranger", "engineer", "shadow", "grove"]

var base_url := ""
var active_requests: Array[HTTPRequest] = []

func _is_allowed_transport() -> bool:
    return base_url.begins_with("https://") or base_url.begins_with("http://127.0.0.1:") or base_url.begins_with("http://localhost:")

func _is_local_endpoint() -> bool:
    return base_url.is_empty() or base_url.begins_with("http://127.0.0.1:") or base_url.begins_with("http://localhost:")

func configure(url: String) -> void:
    base_url = url.strip_edges().trim_suffix("/")

func login(username: String, password: String) -> void:
    var normalized := username.strip_edges()
    if not _valid_credentials(normalized, password):
        failure.emit("اسم المستخدم يجب أن يكون 3-24 حرفًا، وكلمة المرور 8 أحرف على الأقل.")
        return
    if base_url.is_empty():
        _local_login(normalized, password)
        return
    _post("/v1/auth/login", {"username": normalized, "password": password}, "login")

func register(username: String, password: String, character_id: String, avatar_id: int = 0) -> void:
    var normalized := username.strip_edges()
    if not _valid_credentials(normalized, password):
        failure.emit("اسم المستخدم يجب أن يكون 3-24 حرفًا، وكلمة المرور 8 أحرف على الأقل.")
        return
    if base_url.is_empty():
        _local_register(normalized, password, character_id, avatar_id)
        return
    _post("/v1/auth/register", {"username": normalized, "password": password, "character": character_id, "avatar_id": clampi(avatar_id, 0, 29)}, "register")

func restore_session(token: String) -> void:
    if token.begins_with("local:"):
        _local_restore(token)
        return
    if token.is_empty():
        return
    if base_url.is_empty():
        session_invalid.emit()
        return
    if not _is_allowed_transport():
        failure.emit("خدمة الحساب البعيدة تحتاج HTTPS.")
        return
    var headers := PackedStringArray(["Accept: application/json", "Authorization: Bearer " + token])
    _request("/v1/auth/verify", HTTPClient.METHOD_GET, headers, "", "restore", token)

func update_profile(token: String, display_name: String, avatar_id: int) -> void:
    if token.begins_with("local:"):
        _local_update_profile(token, display_name, avatar_id)
        return
    if token.is_empty() or base_url.is_empty():
        failure.emit("خدمة الحساب غير مهيأة.")
        return
    if not _is_allowed_transport():
        failure.emit("تحديث الحساب البعيد يحتاج HTTPS.")
        return
    var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json", "Authorization: Bearer " + token])
    _request("/v1/profile", HTTPClient.METHOD_POST, headers, JSON.stringify({"username": display_name.strip_edges(), "avatar_id": clampi(avatar_id, 0, 29)}), "profile", token)

func logout(token: String) -> void:
    if token.begins_with("local:"):
        _local_logout(token)
        return
    if token.is_empty() or base_url.is_empty():
        return
    if not _is_allowed_transport():
        failure.emit("خدمة الحساب البعيدة تحتاج HTTPS.")
        return
    var headers := PackedStringArray(["Accept: application/json", "Authorization: Bearer " + token])
    _request("/v1/auth/logout", HTTPClient.METHOD_POST, headers, "", "logout", token)

func _valid_credentials(username: String, password: String) -> bool:
    return _validate_local_username(username) and password.length() >= 8 and password.length() <= 128

func _post(path: String, body: Dictionary, operation: String) -> void:
    if not _is_allowed_transport():
        if _is_local_endpoint():
            _local_dispatch(operation, body)
        else:
            failure.emit("خدمة الحساب البعيدة تحتاج HTTPS.")
        return
    var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
    _request(path, HTTPClient.METHOD_POST, headers, JSON.stringify(body), operation)

func _request(path: String, method: HTTPClient.Method, headers: PackedStringArray, body: String, operation: String, session_token: String = "") -> void:
    var request := HTTPRequest.new()
    request.timeout = 8.0
    add_child(request)
    active_requests.append(request)
    request.request_completed.connect(
        func(result: int, response_code: int, response_headers: PackedStringArray, response_body: PackedByteArray) -> void:
            _on_request_completed(request, operation, session_token, body, result, response_code, response_headers, response_body),
        CONNECT_ONE_SHOT
    )
    var err := request.request(base_url + path, headers, method, body)
    if err != OK:
        _remove_request(request)
        if _is_local_endpoint() and operation in ["login", "register"]:
            var payload := JSON.parse_string(body)
            _local_dispatch(operation, payload if payload is Dictionary else {})
        else:
            failure.emit("تعذر إرسال طلب الحساب.")

func _remove_request(request: HTTPRequest) -> void:
    active_requests.erase(request)
    if is_instance_valid(request):
        request.queue_free()

func _on_request_completed(request: HTTPRequest, operation: String, session_token: String, request_body: String, result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    _remove_request(request)
    if result != HTTPRequest.RESULT_SUCCESS:
        if _is_local_endpoint() and operation in ["login", "register"]:
            var fallback := JSON.parse_string(request_body)
            _local_dispatch(operation, fallback if fallback is Dictionary else {})
            return
        failure.emit("خدمة الحساب غير متاحة.")
        return

    var payload = JSON.parse_string(body.get_string_from_utf8())
    var message := str(payload.get("error", "فشل طلب الحساب.")) if payload is Dictionary else "فشل طلب الحساب."

    if operation == "logout":
        if response_code >= 200 and response_code < 300:
            return
        failure.emit(message)
        return

    if operation == "profile":
        if response_code >= 200 and response_code < 300 and payload is Dictionary:
            var updated: Dictionary = payload.duplicate(true)
            updated["token"] = session_token
            success.emit(updated)
            return
        if response_code == 401 or response_code == 403:
            session_invalid.emit()
            return
        failure.emit(message)
        return

    if operation == "restore":
        if response_code >= 200 and response_code < 300 and payload is Dictionary:
            var restored: Dictionary = payload.duplicate(true)
            restored["token"] = session_token
            if not str(restored.get("username", "")).is_empty():
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
            failure.emit("خدمة الحساب أعادت جلسة غير صالحة.")
            return
        success.emit(payload)
        return
    failure.emit(message)

func _load_local_accounts() -> Dictionary:
    if not FileAccess.file_exists(LOCAL_ACCOUNTS_PATH):
        return {}
    var file := FileAccess.open(LOCAL_ACCOUNTS_PATH, FileAccess.READ)
    if file == null:
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    return parsed if parsed is Dictionary else {}

func _save_local_accounts(accounts: Dictionary) -> bool:
    var file := FileAccess.open(LOCAL_ACCOUNTS_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(accounts))
    file.close()
    return true

func _validate_local_username(username: String) -> bool:
    if username.length() < 3 or username.length() > 24:
        return false
    for i in username.length():
        var code := username.unicode_at(i)
        var ok := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code == 95
        if not ok:
            return false
    return true

func _local_hash(password: String, salt: String) -> String:
    var digest := (salt + ":" + password).sha256_text()
    for _i in LOCAL_HASH_ROUNDS:
        digest = digest.sha256_text()
    return digest

func _new_local_token(username: String) -> String:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    return "local:%s:%d:%d" % [username, Time.get_ticks_usec(), rng.randi()]

func _local_register(username: String, password: String, character_id: String, avatar_id: int) -> void:
    if not _valid_credentials(username, password):
        failure.emit("بيانات الحساب غير صالحة.")
        return
    var accounts := _load_local_accounts()
    var key := username.to_lower()
    if accounts.has(key):
        failure.emit("اسم المستخدم مستخدم مسبقًا.")
        return
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var salt := "%016x%016x" % [rng.randi(), rng.randi()]
    var token := _new_local_token(username)
    accounts[key] = {
        "username": username,
        "password_hash": _local_hash(password, salt),
        "salt": salt,
        "character": character_id if character_id in ALLOWED_CHARACTERS else "ranger",
        "avatar_id": clampi(avatar_id, 0, 29),
        "session_token": token
    }
    if not _save_local_accounts(accounts):
        failure.emit("تعذر حفظ الحساب على الجهاز.")
        return
    _emit_local_profile(key, accounts[key], token)

func _local_login(username: String, password: String) -> void:
    var accounts := _load_local_accounts()
    var key := username.to_lower()
    if not accounts.has(key):
        failure.emit("الحساب غير موجود. أنشئ حسابًا أولًا.")
        return
    var account: Dictionary = accounts[key]
    if str(account.get("password_hash", "")) != _local_hash(password, str(account.get("salt", ""))):
        failure.emit("اسم المستخدم أو كلمة المرور غير صحيحة.")
        return
    var token := _new_local_token(str(account.get("username", username)))
    account["session_token"] = token
    accounts[key] = account
    if not _save_local_accounts(accounts):
        failure.emit("تعذر حفظ جلسة الحساب.")
        return
    _emit_local_profile(key, account, token)

func _local_restore(token: String) -> void:
    var parts := token.split(":")
    if parts.size() != 4 or parts[0] != "local":
        session_invalid.emit()
        return
    var accounts := _load_local_accounts()
    var key := parts[1].to_lower()
    if not accounts.has(key):
        session_invalid.emit()
        return
    var account: Dictionary = accounts[key]
    if str(account.get("session_token", "")) != token:
        session_invalid.emit()
        return
    _emit_local_profile(key, account, token)

func _local_update_profile(token: String, display_name: String, avatar_id: int) -> void:
    var parts := token.split(":")
    if parts.size() != 4 or parts[0] != "local":
        session_invalid.emit()
        return
    var accounts := _load_local_accounts()
    var old_key := parts[1].to_lower()
    if not accounts.has(old_key):
        session_invalid.emit()
        return
    var safe_name := display_name.strip_edges()
    if not _validate_local_username(safe_name):
        failure.emit("اسم المستخدم يجب أن يكون 3-24 حرفًا ورقمًا.")
        return
    var new_key := safe_name.to_lower()
    if new_key != old_key and accounts.has(new_key):
        failure.emit("اسم المستخدم مستخدم مسبقًا.")
        return
    var account: Dictionary = accounts[old_key]
    var new_token := _new_local_token(safe_name)
    account["username"] = safe_name
    account["avatar_id"] = clampi(avatar_id, 0, 29)
    account["session_token"] = new_token
    accounts.erase(old_key)
    accounts[new_key] = account
    if not _save_local_accounts(accounts):
        failure.emit("تعذر حفظ الملف الشخصي.")
        return
    _emit_local_profile(new_key, account, new_token)

func _local_logout(token: String) -> void:
    var parts := token.split(":")
    if parts.size() != 4:
        return
    var accounts := _load_local_accounts()
    var key := parts[1].to_lower()
    if accounts.has(key):
        var account: Dictionary = accounts[key]
        if str(account.get("session_token", "")) == token:
            account["session_token"] = ""
            accounts[key] = account
            _save_local_accounts(accounts)

func _local_dispatch(operation: String, body: Dictionary) -> void:
    if operation == "login":
        _local_login(str(body.get("username", "")), str(body.get("password", "")))
    elif operation == "register":
        _local_register(str(body.get("username", "")), str(body.get("password", "")), str(body.get("character", "ranger")), int(body.get("avatar_id", 0)))

func _emit_local_profile(key: String, account: Dictionary, token: String) -> void:
    success.emit({
        "user_id": "local-" + key,
        "username": str(account.get("username", key)),
        "character": str(account.get("character", "ranger")),
        "avatar_id": clampi(int(account.get("avatar_id", 0)), 0, 29),
        "token": token,
        "local": true
    })
