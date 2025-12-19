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
if (empty($input) || empty($input['order_id'])) { sendResponse(400, 'order_id required'); }

$stmt = $conn->prepare(
    "SELECT o.order_id, o.customer_name, o.pickup_address, o.delivery_address, o.status, o.payout, o.created_at
     FROM orders o
     WHERE o.order_id = :oid
     LIMIT 1"
);
$stmt->execute([':oid' => (int)$input['order_id']]);
if ($stmt->rowCount() === 0) { sendResponse(404, 'Order not found'); }
$row = $stmt->fetch();
$order = [
    'order_id' => $row['order_id'],
    'customer_name' => $row['customer_name'] ?? '',
    'pickup_address' => $row['pickup_address'] ?? '',
    'delivery_address' => $row['delivery_address'] ?? '',
    'status' => $row['status'] ?? 'awaiting',
    'payout' => isset($row['payout']) ? (float)$row['payout'] : 0.0,
    'created_at' => $row['created_at'] ?? ''
];

sendResponse(200, 'OK', [ 'order' => $order ]);

