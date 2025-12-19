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

$stmt = $conn->prepare(
    "SELECT 
        o.order_id,
        o.customer_id,
        o.dealer_id,
        o.listing_id,
        o.driver_id,
        o.quantity,
        o.unit_price,
        o.total_amount,
        o.status AS order_status,
        o.delivery_address,
        o.delivery_phone,
        o.special_instructions,
        o.order_date,
        o.delivery_date,
        o.driver_assigned_at,
        o.driver_pickup_time,
        o.driver_delivery_time,
        o.created_at,
        o.updated_at,

        c.user_id AS customer_user_id,
        c.first_name AS customer_first_name,
        c.last_name AS customer_last_name,
        c.email AS customer_email,
        c.phone AS customer_phone,

        d.dealer_id AS dealer_dealer_id,
        d.business_name,
        d.business_address,
        d.business_phone,
        d.business_email,
        d.latitude AS dealer_latitude,
        d.longitude AS dealer_longitude,

        dr.driver_id AS driver_driver_id,
        dr.vehicle_type,
        dr.vehicle_plate,
        dr.license_number,
        dr.rating AS driver_rating,
        dr.current_latitude AS driver_latitude,
        dr.current_longitude AS driver_longitude,
        dr.availability_status,

        fl.listing_id AS food_listing_id,
        fl.title AS food_title,
        fl.description AS food_description,
        fl.price AS food_price,
        fl.preparation_time,

        fi.image_url AS food_image
     FROM orders o
     INNER JOIN users c ON o.customer_id = c.user_id
     INNER JOIN dealers d ON o.dealer_id = d.dealer_id
     LEFT JOIN drivers dr ON o.driver_id = dr.driver_id
     INNER JOIN food_listings fl ON o.listing_id = fl.listing_id
     LEFT JOIN food_images fi ON fl.listing_id = fi.listing_id AND fi.is_primary = 1
     WHERE o.driver_id = :driver_id
       AND o.status IN ('confirmed','preparing','ready','on_delivery')
     ORDER BY 
       CASE o.status 
         WHEN 'ready' THEN 1 
         WHEN 'preparing' THEN 2 
         WHEN 'confirmed' THEN 3 
         WHEN 'on_delivery' THEN 4 
         ELSE 5 
       END,
       o.order_date ASC"
);
$stmt->execute([':driver_id' => (int)$input['driver_id']]);
$rows = $stmt->fetchAll();

$grouped = [];
foreach ($rows as $row) {
    $oid = $row['order_id'];
    if (!isset($grouped[$oid])) {
        $grouped[$oid] = [
            'order_id' => $row['order_id'],
            'customer' => [
                'id' => $row['customer_user_id'],
                'first_name' => $row['customer_first_name'],
                'last_name' => $row['customer_last_name'],
                'email' => $row['customer_email'],
                'phone' => $row['customer_phone']
            ],
            'dealer' => [
                'id' => $row['dealer_dealer_id'],
                'business_name' => $row['business_name'],
                'business_address' => $row['business_address'],
                'business_phone' => $row['business_phone'],
                'business_email' => $row['business_email'],
                'latitude' => $row['dealer_latitude'],
                'longitude' => $row['dealer_longitude']
            ],
            'driver' => [
                'id' => $row['driver_driver_id'],
                'vehicle_type' => $row['vehicle_type'],
                'vehicle_plate' => $row['vehicle_plate'],
                'license_number' => $row['license_number'],
                'rating' => $row['driver_rating'],
                'current_latitude' => $row['driver_latitude'],
                'current_longitude' => $row['driver_longitude'],
                'availability_status' => $row['availability_status']
            ],
            'order_details' => [
                'status' => $row['order_status'],
                'quantity' => $row['quantity'],
                'unit_price' => $row['unit_price'],
                'total_amount' => $row['total_amount'],
                'delivery_address' => $row['delivery_address'],
                'delivery_phone' => $row['delivery_phone'],
                'special_instructions' => $row['special_instructions'],
                'order_date' => $row['order_date'],
                'delivery_date' => $row['delivery_date'],
                'driver_assigned_at' => $row['driver_assigned_at'],
                'driver_pickup_time' => $row['driver_pickup_time'],
                'driver_delivery_time' => $row['driver_delivery_time'],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at']
            ],
            'food' => [
                'listing_id' => $row['food_listing_id'],
                'title' => $row['food_title'],
                'description' => $row['food_description'],
                'price' => $row['food_price'],
                'preparation_time' => $row['preparation_time'],
                'image_url' => $row['food_image']
            ]
        ];
    }
}

sendResponse(200, 'OK', ['orders' => array_values($grouped)]);
