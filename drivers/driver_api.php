<?php
// redtags/drivers/driver_api.php

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

function respond($payload)
{
    $out = json_encode($payload);
    echo $out;
    if (function_exists('fastcgi_finish_request')) {
        fastcgi_finish_request();
    }
    exit;
}

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Database Configuration
define('DB_HOST', '127.0.0.1');
define('DB_NAME', 'redt_tast');
define('DB_USER', 'redt_admin');
define('DB_PASS', '*Bggkh4-C6LtjnIM');

// Upload configuration
define('UPLOAD_DIR', dirname(__DIR__) . '/uploads/driver_photos/');
define('MAX_FILE_SIZE', 5 * 1024 * 1024); // 5MB
define('ALLOWED_TYPES', ['image/jpeg', 'image/png', 'image/jpg', 'image/gif']);

/**
 * Get PDO database connection
 */
function getConnection()
{
    try {
        $conn = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
            DB_USER,
            DB_PASS,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false
            ]
        );
        return $conn;
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Database connection failed',
            'message' => $e->getMessage()
        ]);
        exit;
    }
}

/**
 * Validate authentication token
 */
function validateToken($conn, $token)
{
    if (empty($token)) {
        return null;
    }

    $tokenHash = hash('sha256', $token);
    $stmt = $conn->prepare("
        SELECT u.user_id, u.username, u.email, u.role,
               d.driver_id, d.status as driver_status
        FROM users u
        JOIN drivers d ON u.user_id = d.user_id
        WHERE u.remember_token = :token
        AND u.role = 'driver'
    ");

    $stmt->execute([':token' => $tokenHash]);

    if ($stmt->rowCount() === 0) {
        return null;
    }

    return $stmt->fetch();
}

/**
 * Driver Signup
 */
function driverSignup($conn, $data)
{
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
            return [
                'success' => false,
                'error' => "Missing required field: $field"
            ];
        }
    }

    // Validate email
    if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        return [
            'success' => false,
            'error' => "Invalid email format"
        ];
    }

    // Check if username exists
    $stmt = $conn->prepare("SELECT user_id FROM users WHERE username = :username");
    $stmt->execute([':username' => $data['username']]);
    if ($stmt->rowCount() > 0) {
        return [
            'success' => false,
            'error' => "Username already taken"
        ];
    }

    // Check if email exists
    $stmt = $conn->prepare("SELECT user_id FROM users WHERE email = :email");
    $stmt->execute([':email' => $data['email']]);
    if ($stmt->rowCount() > 0) {
        return [
            'success' => false,
            'error' => "Email already registered"
        ];
    }

    // Hash password
    $hashed_password = password_hash($data['password'], PASSWORD_BCRYPT);

    // Start transaction
    $conn->beginTransaction();

    try {
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

        $lat = null;
        $lng = null;
        if (isset($data['current_latitude']) && $data['current_latitude'] !== '') {
            $lat = (float)$data['current_latitude'];
        } elseif (isset($data['latitude']) && $data['latitude'] !== '') {
            $lat = (float)$data['latitude'];
        }
        if (isset($data['current_longitude']) && $data['current_longitude'] !== '') {
            $lng = (float)$data['current_longitude'];
        } elseif (isset($data['longitude']) && $data['longitude'] !== '') {
            $lng = (float)$data['longitude'];
        }

        $stmt = $conn->prepare("\n            INSERT INTO drivers \n            (user_id, status, vehicle_type, vehicle_plate, license_number, \n             earning_balance, availability_status, current_latitude, current_longitude, created_at, updated_at) \n            VALUES \n            (:user_id, 'inactive', :vehicle_type, :vehicle_plate, :license_number, \n             0.00, 'offline', :current_latitude, :current_longitude, NOW(), NOW())\n        ");

        $stmt->execute([
            ':user_id' => $user_id,
            ':vehicle_type' => $data['vehicle_type'],
            ':vehicle_plate' => $data['vehicle_plate'],
            ':license_number' => $data['license_number'],
            ':current_latitude' => $lat,
            ':current_longitude' => $lng
        ]);

        $driver_id = $conn->lastInsertId();

        $photoInfo = null;
        if (isset($_FILES['photo'])) {
            $upload = uploadDriverPhoto($conn, $driver_id, $_FILES['photo']);
            if ($upload && isset($upload['success']) && $upload['success']) {
                $photoInfo = $upload['photo_url'];
            }
        }

        $conn->commit();

        $respData = [
            'user_id' => $user_id,
            'driver_id' => $driver_id,
            'username' => $data['username'],
            'email' => $data['email'],
            'status' => 'inactive',
            'note' => 'Admin needs to approve your account'
        ];
        if ($lat !== null) {
            $respData['current_latitude'] = $lat;
        }
        if ($lng !== null) {
            $respData['current_longitude'] = $lng;
        }
        if ($photoInfo) {
            $respData['photo'] = $photoInfo;
        }

        return [
            'success' => true,
            'message' => 'Driver registered successfully. Awaiting admin approval.',
            'data' => $respData
        ];
    } catch (PDOException $e) {
        $conn->rollBack();
        return [
            'success' => false,
            'error' => 'Database error: ' . $e->getMessage()
        ];
    }
}

/**
 * Driver Login
 */
function driverLogin($conn, $data)
{
    try {
        // Check required fields
        if (empty($data['username']) || empty($data['password'])) {
            return [
                'success' => false,
                'error' => "Username and password are required"
            ];
        }

        $username = trim($data['username']);
        $password = $data['password'];

        $query = "SELECT u.user_id, u.username, u.email, u.password_hash, 
                         u.first_name, u.last_name, u.phone, u.is_approved,
                         d.driver_id, d.status as driver_status,
                         d.vehicle_type, d.vehicle_plate, d.license_number,
                         d.photo, d.current_latitude, d.current_longitude,
                         d.availability_status, d.earning_balance
                  FROM users u
                  LEFT JOIN drivers d ON u.user_id = d.user_id
                  WHERE (u.username = ? OR u.email = ?)
                  AND u.role = 'driver'
                  LIMIT 1";

        $stmt = $conn->prepare($query);
        $stmt->execute([$username, $username]);

        if ($stmt->rowCount() === 0) {
            return [
                'success' => false,
                'error' => "Invalid username or password"
            ];
        }

        $user = $stmt->fetch();

        // Verify password
        if (!password_verify($password, $user['password_hash'])) {
            return [
                'success' => false,
                'error' => "Invalid username or password"
            ];
        }

        // Check if approved
        if (!$user['is_approved']) {
            return [
                'success' => false,
                'error' => "Account pending admin approval"
            ];
        }

        // Check if driver profile exists
        if (empty($user['driver_id'])) {
            return [
                'success' => false,
                'error' => "Driver profile not found"
            ];
        }

        if ($user['driver_status'] !== 'active') {
            return [
                'success' => false,
                'error' => "Driver account is " . $user['driver_status']
            ];
        }

        // Generate token
        $token = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);

        $updateStmt = $conn->prepare("UPDATE users SET remember_token = :token WHERE user_id = :user_id");
        $updateStmt->execute([
            ':token' => $tokenHash,
            ':user_id' => $user['user_id']
        ]);

        // Remove sensitive data
        unset($user['password_hash']);

        return [
            'success' => true,
            'message' => 'Login successful',
            'token' => $token,
            'data' => $user
        ];
    } catch (PDOException $e) {
        return [
            'success' => false,
            'error' => 'Login failed. Database error.'
        ];
    }
}

/**
 * Upload Driver Photo
 */
function uploadDriverPhoto($conn, $driver_id, $file)
{
    if (!file_exists(UPLOAD_DIR)) {
        if (!@mkdir(UPLOAD_DIR, 0755, true)) {
            return [
                'success' => false,
                'error' => 'Upload directory unavailable'
            ];
        }
    }
    if (!is_dir(UPLOAD_DIR) || !is_writable(UPLOAD_DIR)) {
        return [
            'success' => false,
            'error' => 'Upload directory not writable'
        ];
    }

    $error = isset($file['error']) ? $file['error'] : UPLOAD_ERR_NO_FILE;
    if ($error !== UPLOAD_ERR_OK) {
        $map = [
            UPLOAD_ERR_INI_SIZE => 'File exceeds server limit',
            UPLOAD_ERR_FORM_SIZE => 'File exceeds form limit',
            UPLOAD_ERR_PARTIAL => 'File partially uploaded',
            UPLOAD_ERR_NO_FILE => 'No file uploaded',
            UPLOAD_ERR_NO_TMP_DIR => 'Missing temp directory',
            UPLOAD_ERR_CANT_WRITE => 'Failed to write file',
            UPLOAD_ERR_EXTENSION => 'Upload stopped by extension'
        ];
        $msg = isset($map[$error]) ? $map[$error] : 'Upload error';
        return [
            'success' => false,
            'error' => $msg
        ];
    }

    if (!isset($file['tmp_name']) || !is_uploaded_file($file['tmp_name'])) {
        return [
            'success' => false,
            'error' => 'Invalid upload'
        ];
    }

    if ((int)$file['size'] > MAX_FILE_SIZE) {
        return [
            'success' => false,
            'error' => 'File size exceeds maximum limit of 5MB'
        ];
    }

    $mime_type = '';
    if (function_exists('finfo_open')) {
        $f = @finfo_open(FILEINFO_MIME_TYPE);
        if ($f) {
            $mime_type = @finfo_file($f, $file['tmp_name']) ?: '';
            @finfo_close($f);
        }
    }
    if ($mime_type === '' && isset($file['type'])) {
        $mime_type = $file['type'];
    }

    $validMime = in_array($mime_type, ALLOWED_TYPES);
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $allowedExt = ['jpg', 'jpeg', 'png', 'gif'];
    if (!$validMime && !in_array($ext, $allowedExt)) {
        return [
            'success' => false,
            'error' => 'Invalid file type. Allowed: JPEG, PNG, GIF'
        ];
    }

    $extension = $ext ?: ($mime_type === 'image/png' ? 'png' : ($mime_type === 'image/gif' ? 'gif' : 'jpg'));
    $filename = 'driver_' . $driver_id . '_' . time() . '.' . $extension;
    $filepath = UPLOAD_DIR . $filename;

    if (!@move_uploaded_file($file['tmp_name'], $filepath)) {
        return [
            'success' => false,
            'error' => 'Failed to save uploaded file'
        ];
    }

    $relative_path = 'uploads/driver_photos/' . $filename;

    try {
        $stmt = $conn->prepare("UPDATE drivers SET photo = :photo WHERE driver_id = :driver_id");
        $stmt->execute([
            ':photo' => $relative_path,
            ':driver_id' => $driver_id
        ]);

        return [
            'success' => true,
            'message' => 'Photo uploaded successfully',
            'photo_url' => $relative_path
        ];
    } catch (PDOException $e) {
        if (file_exists($filepath)) {
            @unlink($filepath);
        }
        return [
            'success' => false,
            'error' => 'Failed to update database: ' . $e->getMessage()
        ];
    }
}

/**
 * Update Driver Location
 */
function updateDriverLocation($conn, $driver_id, $data)
{
    // Validate required fields
    if (empty($data['location_text'])) {
        return [
            'success' => false,
            'error' => 'Location text is required'
        ];
    }

    // Extract latitude and longitude if provided
    $latitude = isset($data['latitude']) ? (float)$data['latitude'] : null;
    $longitude = isset($data['longitude']) ? (float)$data['longitude'] : null;

    try {
        // Update driver's location
        $stmt = $conn->prepare("
            UPDATE drivers 
            SET current_latitude = :latitude, 
                current_longitude = :longitude,
                updated_at = NOW()
            WHERE driver_id = :driver_id
        ");

        $stmt->execute([
            ':latitude' => $latitude,
            ':longitude' => $longitude,
            ':driver_id' => $driver_id
        ]);

        return [
            'success' => true,
            'message' => 'Location updated successfully',
            'data' => [
                'location_text' => $data['location_text'],
                'latitude' => $latitude,
                'longitude' => $longitude,
                'updated_at' => date('Y-m-d H:i:s')
            ]
        ];
    } catch (PDOException $e) {
        return [
            'success' => false,
            'error' => 'Failed to update location: ' . $e->getMessage()
        ];
    }
}

/**
 * Get Driver Profile
 */
function getDriverProfile($conn, $driver_id)
{
    try {
        $stmt = $conn->prepare("
            SELECT 
                d.driver_id,
                d.status,
                d.vehicle_type,
                d.vehicle_plate,
                d.license_number,
                d.photo,
                d.rating,
                d.earning_balance,
                d.current_latitude,
                d.current_longitude,
                d.availability_status,
                d.created_at,
                d.updated_at,
                u.user_id,
                u.username,
                u.email,
                u.first_name,
                u.last_name,
                u.phone,
                u.date_of_birth
            FROM drivers d
            JOIN users u ON d.user_id = u.user_id
            WHERE d.driver_id = :driver_id
        ");

        $stmt->execute([':driver_id' => $driver_id]);

        if ($stmt->rowCount() === 0) {
            return [
                'success' => false,
                'error' => 'Driver not found'
            ];
        }

        $driver = $stmt->fetch();

        // Format the response
        unset($driver['password_hash']);

        return [
            'success' => true,
            'data' => $driver
        ];
    } catch (PDOException $e) {
        return [
            'success' => false,
            'error' => 'Failed to get profile: ' . $e->getMessage()
        ];
    }
}

/**
 * Update Availability Status
 */
function updateAvailabilityStatus($conn, $driver_id, $status)
{
    $allowed_statuses = ['offline', 'online', 'on_delivery'];

    if (!in_array($status, $allowed_statuses)) {
        return [
            'success' => false,
            'error' => 'Invalid status. Allowed: ' . implode(', ', $allowed_statuses)
        ];
    }

    try {
        $stmt = $conn->prepare("
            UPDATE drivers 
            SET availability_status = :status,
                updated_at = NOW()
            WHERE driver_id = :driver_id
        ");

        $stmt->execute([
            ':status' => $status,
            ':driver_id' => $driver_id
        ]);

        return [
            'success' => true,
            'message' => 'Availability status updated to ' . $status
        ];
    } catch (PDOException $e) {
        return [
            'success' => false,
            'error' => 'Failed to update status: ' . $e->getMessage()
        ];
    }
}

// Main execution
try {
    $conn = getConnection();

    // Get request method and path
    $method = $_SERVER['REQUEST_METHOD'];
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

    // Handle different endpoints
    if ($method === 'POST') {
        // Get input data (avoid reading raw body for multipart to reduce overhead)
        $contentType = isset($_SERVER['CONTENT_TYPE']) ? $_SERVER['CONTENT_TYPE'] : '';
        $isJson = stripos($contentType, 'application/json') !== false;
        if ($isJson) {
            $input = json_decode(file_get_contents('php://input'), true);
        } else {
            $input = $_POST;
        }

        // Check if it's signup or login
        if (isset($_GET['action'])) {
            $action = $_GET['action'];

            if ($action === 'signup') {
                $result = driverSignup($conn, $input);
                respond($result);
            } elseif ($action === 'login') {
                $result = driverLogin($conn, $input);
                respond($result);
            } else {
                respond([
                    'success' => false,
                    'error' => 'Invalid action'
                ]);
            }
        }
        // Handle photo upload (multipart form)
        elseif (isset($_FILES['photo']) && isset($_POST['token'])) {
            $user = validateToken($conn, $_POST['token']);
            if (!$user) {
                http_response_code(401);
                echo json_encode(['success' => false, 'error' => 'Invalid token']);
                exit;
            }

            $result = uploadDriverPhoto($conn, $user['driver_id'], $_FILES['photo']);
            respond($result);
        }
        // Handle location update
        elseif (isset($input['token']) && isset($input['location_text'])) {
            $user = validateToken($conn, $input['token']);
            if (!$user) {
                http_response_code(401);
                echo json_encode(['success' => false, 'error' => 'Invalid token']);
                exit;
            }

            $result = updateDriverLocation($conn, $user['driver_id'], $input);
            respond($result);
        }
        // Handle status update
        elseif (isset($input['token']) && isset($input['status'])) {
            $user = validateToken($conn, $input['token']);
            if (!$user) {
                http_response_code(401);
                echo json_encode(['success' => false, 'error' => 'Invalid token']);
                exit;
            }

            $result = updateAvailabilityStatus($conn, $user['driver_id'], $input['status']);
            respond($result);
        }
        // Default: try login
        else {
            if (isset($input['username']) && isset($input['password'])) {
                $result = driverLogin($conn, $input);
                respond($result);
            } else {
                respond([
                    'success' => false,
                    'error' => 'Invalid request'
                ]);
            }
        }
    } elseif ($method === 'GET') {
        // Get driver profile
        if (isset($_GET['token'])) {
            $user = validateToken($conn, $_GET['token']);
            if (!$user) {
                http_response_code(401);
                echo json_encode(['success' => false, 'error' => 'Invalid token']);
                exit;
            }

            $result = getDriverProfile($conn, $user['driver_id']);
            respond($result);
        }
        // Test endpoint
        elseif (isset($_GET['test'])) {
            // Show available drivers for testing
            $stmt = $conn->query("
                SELECT u.username, u.email, u.is_approved,
                       d.driver_id, d.status as driver_status,
                       CONCAT(u.first_name, ' ', u.last_name) as full_name
                FROM users u
                JOIN drivers d ON u.user_id = d.user_id
                WHERE u.role = 'driver'
                ORDER BY d.driver_id
            ");

            $drivers = $stmt->fetchAll();

            respond([
                'success' => true,
                'message' => 'Available drivers for testing',
                'drivers' => $drivers,
                'api_endpoints' => [
                    'POST /driver_api.php?action=login' => 'Login with username/password',
                    'POST /driver_api.php?action=signup' => 'Driver signup',
                    'POST /driver_api.php (with token and photo file)' => 'Upload photo',
                    'POST /driver_api.php (with token and location_text)' => 'Update location',
                    'POST /driver_api.php (with token and status)' => 'Update availability',
                    'GET /driver_api.php?token=YOUR_TOKEN' => 'Get driver profile'
                ]
            ]);
        }
        // Show API documentation
        else {
            respond([
                'success' => true,
                'message' => 'Driver Authentication API',
                'endpoints' => [
                    'POST /driver_api.php?action=login' => [
                        'description' => 'Driver login',
                        'parameters' => [
                            'username' => 'Driver username or email',
                            'password' => 'Password'
                        ]
                    ],
                    'POST /driver_api.php?action=signup' => [
                        'description' => 'Driver registration',
                        'required_fields' => [
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
                        ]
                    ],
                    'POST /driver_api.php (multipart/form-data)' => [
                        'description' => 'Upload driver photo',
                        'parameters' => [
                            'token' => 'Authentication token',
                            'photo' => 'Photo file (JPEG/PNG/GIF, max 5MB)'
                        ]
                    ],
                    'POST /driver_api.php (JSON)' => [
                        'description' => 'Update driver location',
                        'parameters' => [
                            'token' => 'Authentication token',
                            'location_text' => 'Location description (required)',
                            'latitude' => 'Latitude (optional)',
                            'longitude' => 'Longitude (optional)'
                        ]
                    ],
                    'GET /driver_api.php?token=TOKEN' => [
                        'description' => 'Get driver profile'
                    ]
                ]
            ]);
        }
    } else {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'error' => 'Method not allowed'
        ]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database error',
        'message' => $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Server error',
        'message' => $e->getMessage()
    ]);
}
