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
if (empty($input) || empty($input['user_id'])) { sendResponse(400, 'user_id required'); }

$stmt = $conn->prepare(
    "SELECT u.user_id, u.username, u.email, u.first_name, u.last_name, u.phone,
            d.driver_id, d.status as driver_status, d.vehicle_type, d.vehicle_plate, d.license_number
     FROM users u
     LEFT JOIN drivers d ON u.user_id = d.user_id
     WHERE u.user_id = :uid AND u.role = 'driver'
     LIMIT 1"
);
$stmt->execute([':uid' => (int)$input['user_id']]);
if ($stmt->rowCount() === 0) { sendResponse(404, 'Driver not found'); }
$user = $stmt->fetch();
sendResponse(200, 'OK', [ 'user' => $user ]);

