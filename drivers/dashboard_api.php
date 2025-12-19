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
if (empty($input) || empty($input['driver_id'])) { sendResponse(400, 'driver_id required'); }

$driverId = (int)$input['driver_id'];

$stmt1 = $conn->prepare("SELECT COALESCE(SUM(o.payout),0) AS total FROM orders o WHERE o.driver_id=:d AND o.status='delivered'");
$stmt1->execute([':d' => $driverId]);
$total = (float)$stmt1->fetchColumn();

$stmt2 = $conn->prepare("SELECT COUNT(*) FROM orders o WHERE o.driver_id=:d AND o.status='delivered'");
$stmt2->execute([':d' => $driverId]);
$delivered = (int)$stmt2->fetchColumn();

$stmt3 = $conn->prepare("SELECT COUNT(*) FROM orders o WHERE o.driver_id=:d AND o.status <> 'delivered'");
$stmt3->execute([':d' => $driverId]);
$active = (int)$stmt3->fetchColumn();

sendResponse(200, 'OK', [
    'total_earnings' => $total,
    'deliveries_count' => $delivered,
    'active_orders' => $active
]);

