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
    private $host = '127.0.0.1';
    private $db_name = 'redt_tast';
    private $username = 'redt_admin';
    private $password = '*Bggkh4-C6LtjnIM';
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

// Delivered orders
$stmt = $conn->prepare(
    "SELECT o.order_id, COALESCE(o.delivery_fee, 0) AS amount, o.status, o.updated_at AS ts, o.delivery_address
     FROM orders o
     WHERE o.driver_id = :driver_id AND o.status = 'delivered'
     ORDER BY o.updated_at DESC
     LIMIT 200"
);
$stmt->execute([':driver_id' => (int)$input['driver_id']]);
$delivered = $stmt->fetchAll();

// Accepted (assigned) orders not yet delivered
$stmt2 = $conn->prepare(
    "SELECT o.order_id, COALESCE(o.delivery_fee, 0) AS amount, o.status, o.driver_assigned_at AS ts, o.delivery_address
     FROM orders o
     WHERE o.driver_id = :driver_id AND o.status IN ('preparing','ready','confirmed')
     ORDER BY o.driver_assigned_at DESC
     LIMIT 200"
);
$stmt2->execute([':driver_id' => (int)$input['driver_id']]);
$accepted = $stmt2->fetchAll();

// Booking deliveries (accepted/completed)
$stmt3 = $conn->prepare(
    "SELECT CONCAT('B', b.booking_id) AS order_id, COALESCE(b.delivery_fee, 0) AS amount, b.status, b.delivery_assigned_at AS ts, b.delivery_address
     FROM table_bookings b
     WHERE b.driver_id = :driver_id AND b.delivery_required = 1 AND b.status IN ('confirmed','completed')
     ORDER BY b.delivery_assigned_at DESC
     LIMIT 100"
);
$stmt3->execute([':driver_id' => (int)$input['driver_id']]);
$bookings = $stmt3->fetchAll();

$total = 0.0; // sum delivered amounts
$history = [];

foreach ($delivered as $row) {
    $amt = isset($row['amount']) ? (float)$row['amount'] : 0.0;
    $total += $amt;
    $history[] = [
        'order_id' => $row['order_id'],
        'date' => $row['ts'] ?? '',
        'summary' => 'Delivered: ' . (($row['delivery_address'] ?? '') ?: 'order'),
        'amount' => $amt,
        'status' => 'delivered'
    ];
}

foreach ($accepted as $row) {
    $amt = isset($row['amount']) ? (float)$row['amount'] : 0.0;
    $history[] = [
        'order_id' => $row['order_id'],
        'date' => $row['ts'] ?? '',
        'summary' => 'Accepted: ' . (($row['delivery_address'] ?? '') ?: 'order'),
        'amount' => $amt,
        'status' => $row['status'] ?? 'preparing'
    ];
}

foreach ($bookings as $row) {
    $amt = isset($row['amount']) ? (float)$row['amount'] : 0.0;
    $history[] = [
        'order_id' => $row['order_id'],
        'date' => $row['ts'] ?? '',
        'summary' => ($row['status'] === 'completed' ? 'Delivered booking' : 'Accepted booking') . ': ' . (($row['delivery_address'] ?? '') ?: 'booking'),
        'amount' => $amt,
        'status' => $row['status'] ?? 'confirmed'
    ];
}

sendResponse(200, 'OK', ['total' => $total, 'history' => $history]);
