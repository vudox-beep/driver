<?php

/**
 * DRIVER SIGNUP & LOGIN API
 * Secure against SQL Injection
 */

// ============================================
// 1. DATABASE CONNECTION
// ============================================
class Database
{
    private $host = 'localhost';
    private $db_name = 'foodsale';
    private $username = 'root';  // Change this
    private $password = '';      // Change this
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

// ============================================
// 2. SECURITY HELPER FUNCTIONS
// ============================================
class Security
{

    // Validate email
    public static function validateEmail($email)
    {
        return filter_var($email, FILTER_VALIDATE_EMAIL);
    }

    // Hash password
    public static function hashPassword($password)
    {
        return password_hash($password, PASSWORD_BCRYPT);
    }

    // Verify password
    public static function verifyPassword($password, $hash)
    {
        return password_verify($password, $hash);
    }

    // Check if username exists
    public static function usernameExists($conn, $username)
    {
        $stmt = $conn->prepare("SELECT user_id FROM users WHERE username = :username");
        $stmt->execute([':username' => $username]);
        return $stmt->rowCount() > 0;
    }

    // Check if email exists
    public static function emailExists($conn, $email)
    {
        $stmt = $conn->prepare("SELECT user_id FROM users WHERE email = :email");
        $stmt->execute([':email' => $email]);
        return $stmt->rowCount() > 0;
    }
}

// ============================================
// 3. API HEADERS & CONFIG
// ============================================
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ============================================
// 4. MAIN API FUNCTION
// ============================================
function handleRequest()
{
    // Get database connection
    $db = new Database();
    $conn = $db->getConnection();

    if (!$conn) {
        sendResponse(500, "Database connection failed");
        return;
    }

    // Get request data
    $input = json_decode(file_get_contents('php://input'), true);

    if (empty($input)) {
        sendResponse(400, "No data received");
        return;
    }

    // Get action
    $action = isset($_GET['action']) ? $_GET['action'] : '';

    if ($action === 'signup') {
        driverSignup($conn, $input);
    } elseif ($action === 'login') {
        driverLogin($conn, $input);
    } else {
        sendResponse(400, "Invalid action. Use 'signup' or 'login'");
    }
}

// ============================================
// 5. DRIVER SIGNUP FUNCTION
// ============================================
function driverSignup($conn, $data)
{
    try {
        // Required fields
        $required = [
            'username',
            'email',
            'password',
            'first_name',
            'last_name',
            'phone',
            'date_of_birth',
            'vehicle_type',
            'vehicle_plate',
            'license_number'
        ];

        // Check required fields
        foreach ($required as $field) {
            if (empty($data[$field])) {
                sendResponse(400, "Missing required field: $field");
                return;
            }
        }

        // Validate email
        if (!Security::validateEmail($data['email'])) {
            sendResponse(400, "Invalid email format");
            return;
        }

        // Check if username exists
        if (Security::usernameExists($conn, $data['username'])) {
            sendResponse(409, "Username already taken");
            return;
        }

        // Check if email exists
        if (Security::emailExists($conn, $data['email'])) {
            sendResponse(409, "Email already registered");
            return;
        }

        // Hash password
        $hashed_password = Security::hashPassword($data['password']);

        // Start transaction
        $conn->beginTransaction();

        // Insert into users table
        $stmt = $conn->prepare("
            INSERT INTO users 
            (username, email, password_hash, first_name, last_name, 
             phone, date_of_birth, role, is_approved, agreed_marketing, 
             email_verified, created_at, updated_at) 
            VALUES 
            (:username, :email, :password_hash, :first_name, :last_name, 
             :phone, :date_of_birth, 'driver', 0, :agreed_marketing, 
             0, NOW(), NOW())
        ");

        $agreed_marketing = isset($data['agreed_marketing']) ? (int)$data['agreed_marketing'] : 0;

        $stmt->execute([
            ':username' => $data['username'],
            ':email' => $data['email'],
            ':password_hash' => $hashed_password,
            ':first_name' => $data['first_name'],
            ':last_name' => $data['last_name'],
            ':phone' => $data['phone'],
            ':date_of_birth' => $data['date_of_birth'],
            ':agreed_marketing' => $agreed_marketing
        ]);

        $user_id = $conn->lastInsertId();

        // Insert into drivers table
        $stmt = $conn->prepare("
            INSERT INTO drivers 
            (user_id, status, vehicle_type, vehicle_plate, license_number, 
             earning_balance, availability_status, created_at, updated_at) 
            VALUES 
            (:user_id, 'inactive', :vehicle_type, :vehicle_plate, :license_number, 
             0.00, 'offline', NOW(), NOW())
        ");

        $stmt->execute([
            ':user_id' => $user_id,
            ':vehicle_type' => $data['vehicle_type'],
            ':vehicle_plate' => $data['vehicle_plate'],
            ':license_number' => $data['license_number']
        ]);

        $driver_id = $conn->lastInsertId();

        // Commit transaction
        $conn->commit();

        // Response
        $response = [
            'success' => true,
            'message' => 'Driver registered successfully. Awaiting admin approval.',
            'user_id' => $user_id,
            'driver_id' => $driver_id,
            'status' => 'inactive'
        ];

        sendResponse(201, "Registration successful", $response);
    } catch (PDOException $e) {
        if ($conn->inTransaction()) {
            $conn->rollBack();
        }
        sendResponse(500, "Database error: " . $e->getMessage());
    }
}

// ============================================
// 6. DRIVER LOGIN FUNCTION
// ============================================
function driverLogin($conn, $data)
{
    try {
        // Check required fields
        if (empty($data['username']) || empty($data['password'])) {
            sendResponse(400, "Username and password are required");
            return;
        }

        // Get user by username or email
        $stmt = $conn->prepare("
            SELECT u.user_id, u.username, u.email, u.password_hash, 
                   u.first_name, u.last_name, u.phone, u.is_approved,
                   d.driver_id, d.status as driver_status,
                   d.vehicle_type, d.vehicle_plate, d.license_number
            FROM users u
            LEFT JOIN drivers d ON u.user_id = d.user_id
            WHERE (u.username = :identifier OR u.email = :identifier)
            AND u.role = 'driver'
            LIMIT 1
        ");

        $stmt->execute([':identifier' => $data['username']]);

        if ($stmt->rowCount() === 0) {
            sendResponse(401, "Invalid username or password");
            return;
        }

        $user = $stmt->fetch();

        // Verify password
        if (!Security::verifyPassword($data['password'], $user['password_hash'])) {
            sendResponse(401, "Invalid username or password");
            return;
        }

        if (!$user['is_approved']) {
            sendResponse(403, "Account pending admin approval");
            return;
        }
        if (empty($user['driver_id']) || $user['driver_status'] !== 'active') {
            sendResponse(403, "Driver profile not activated");
            return;
        }

        // Remove password hash from response
        unset($user['password_hash']);

        // Response
        $response = [
            'success' => true,
            'message' => 'Login successful',
            'user' => $user
        ];

        sendResponse(200, "Login successful", $response);
    } catch (PDOException $e) {
        sendResponse(500, "Database error: " . $e->getMessage());
    }
}

// ============================================
// 7. RESPONSE HELPER FUNCTION
// ============================================
function sendResponse($code, $message, $data = null)
{
    http_response_code($code);

    $response = [
        'success' => $code >= 200 && $code < 300,
        'message' => $message
    ];

    if ($data !== null) {
        $response['data'] = $data;
    }

    echo json_encode($response, JSON_PRETTY_PRINT);
    exit();
}

// ============================================
// 8. EXECUTE THE API
// ============================================
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    handleRequest();
} else {
    sendResponse(405, "Method not allowed. Use POST.");
}
