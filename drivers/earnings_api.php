<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

class Database
{
    private $host = 'localhost';
    private $db_name = 'foodsale';
    private $username = 'root';
    private $password = '';
    private $conn;
    public function getConnection()
    {
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
        } catch (PDOException $e) {
            return null;
        }
    }
}

function sendResponse($code, $message, $data = null)
{
    http_response_code($code);
    $r = ['success' => $code >= 200 && $code < 300, 'message' => $message];
    if ($data !== null) {
        $r['data'] = $data;
    }
    echo json_encode($r, JSON_PRETTY_PRINT);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(405, 'Method not allowed');
}

$db = new Database();
$conn = $db->getConnection();
if (!$conn) {
    sendResponse(500, 'Database connection failed');
}

$input = json_decode(file_get_contents('php://input'), true);
if (empty($input) || empty($input['driver_id'])) {
    sendResponse(400, 'driver_id required');
}

$stmt = $conn->prepare(
    "SELECT o.order_id, o.payout, o.status, o.created_at, o.customer_name
     FROM orders o
     WHERE o.driver_id = :driver_id AND o.status = 'delivered'
     ORDER BY o.created_at DESC
     LIMIT 200"
);
$stmt->execute([':driver_id' => (int)$input['driver_id']]);
$rows = $stmt->fetchAll();

$total = 0.0;
$history = [];
foreach ($rows as $row) {
    $amt = isset($row['payout']) ? (float)$row['payout'] : 0.0;
    $total += $amt;
    $history[] = [
        'order_id' => $row['order_id'],
        'date' => $row['created_at'] ?? '',
        'summary' => ($row['customer_name'] ?? '') . ' delivery',
        'amount' => $amt
    ];
}

sendResponse(200, 'OK', ['total' => $total, 'history' => $history]);
