<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

class Database {
    private $host = 'localhost';
    private $db_name = 'foodsale';
    private $username = 'root';
    private $password = '';
    private $conn;
    public function getConnection() {
        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8mb4",
                $this->username,
                $this->password,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false
                ]
            );
            return $this->conn;
        } catch (PDOException $e) { return null; }
    }
}

function sendResponse($code, $message, $data = null) {
    http_response_code($code);
    $r = [ 'success' => $code >= 200 && $code < 300, 'message' => $message ];
    if ($data !== null) { $r['data'] = $data; }
    echo json_encode($r, JSON_PRETTY_PRINT); exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') { sendResponse(405, 'Method not allowed'); }

$db = new Database();
$conn = $db->getConnection();
if (!$conn) { sendResponse(500, 'Database connection failed'); }

$input = json_decode(file_get_contents('php://input'), true);
if (empty($input) || empty($input['user_id']) || empty($input['old_password']) || empty($input['new_password'])) {
    sendResponse(400, 'user_id, old_password and new_password required');
}

$stmt = $conn->prepare("SELECT password_hash FROM users WHERE user_id = :uid AND role = 'driver' LIMIT 1");
$stmt->execute([':uid' => (int)$input['user_id']]);
if ($stmt->rowCount() === 0) { sendResponse(404, 'User not found'); }
$row = $stmt->fetch();

if (!password_verify($input['old_password'], $row['password_hash'])) {
    sendResponse(401, 'Current password incorrect');
}

$newHash = password_hash($input['new_password'], PASSWORD_BCRYPT);
$upd = $conn->prepare("UPDATE users SET password_hash = :ph, updated_at = NOW() WHERE user_id = :uid");
$upd->execute([':ph' => $newHash, ':uid' => (int)$input['user_id']]);

sendResponse(200, 'Password updated');

