<?php
// driver_available_orders.php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$host = '127.0.0.1';
$dbname = 'redt_tast'; // Changed to match your database name
$username = 'redt_admin'; // Use your actual MySQL username
$password = '*Bggkh4-C6LtjnIM';
$port = 3306;

try {
    // Create database connection
    $conn = new mysqli($host, $username, $password, $dbname, $port);

    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }

    // Set charset to UTF-8
    $conn->set_charset("utf8mb4");

    // Check if driver_id is provided
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $driver_id = isset($_GET['driver_id']) ? intval($_GET['driver_id']) : null;

        if ($driver_id) {
            // Fetch orders for a specific driver
            $response = getDriverOrders($conn, $driver_id);
        } else {
            // Fetch all available orders for drivers
            $response = getAvailableOrders($conn);
        }
    } elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Handle driver accepting an order or updating status
        $raw = file_get_contents('php://input');
        $data = json_decode($raw, true);
        // Fallback for form-encoded bodies
        if (!is_array($data) || empty($data)) {
            if (!empty($_POST)) {
                $data = $_POST;
            } else {
                $data = [];
            }
        }

        if (isset($data['action'])) {
            switch ($data['action']) {
                case 'accept':
                    if (isset($data['driver_id']) && isset($data['order_id'])) {
                        $response = acceptOrder($conn, $data['driver_id'], $data['order_id'], $data);
                    } else {
                        $response = [
                            'status' => 'error',
                            'message' => 'Missing required parameters for accept: driver_id and order_id'
                        ];
                    }
                    break;

                case 'update_status':
                    if (isset($data['driver_id']) && isset($data['order_id']) && isset($data['status'])) {
                        $response = updateOrderStatus($conn, $data['driver_id'], $data['order_id'], $data['status']);
                    } else {
                        $response = [
                            'status' => 'error',
                            'message' => 'Missing required parameters for update_status: driver_id, order_id, and status'
                        ];
                    }
                    break;

                case 'update_location':
                    if (isset($data['driver_id']) && isset($data['latitude']) && isset($data['longitude'])) {
                        $response = updateDriverLocation($conn, $data['driver_id'], $data['latitude'], $data['longitude']);
                    } else {
                        $response = [
                            'status' => 'error',
                            'message' => 'Missing required parameters for update_location: driver_id, latitude, and longitude'
                        ];
                    }
                    break;

                default:
                    $response = [
                        'status' => 'error',
                        'message' => 'Invalid action. Use: accept, update_status, or update_location'
                    ];
            }
        } else {
            $response = [
                'status' => 'error',
                'message' => 'No action specified'
            ];
        }
    } else {
        $response = [
            'status' => 'error',
            'message' => 'Invalid request method'
        ];
    }

    echo json_encode($response);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}

/**
 * Fetch all available orders that drivers can respond to
 */
function getAvailableOrders($conn)
{
    try {
        // Query to get orders that are ready for delivery or need a driver
        $sql = "
            SELECT 
                o.order_id,
                o.customer_id,
                o.dealer_id,
                o.driver_id,
                o.listing_id,
                o.quantity,
                o.unit_price,
                o.total_amount,
                o.delivery_fee,
                o.status,
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
                -- Calculate total with delivery fee
                (o.total_amount + COALESCE(o.delivery_fee, 0)) as total_with_delivery,
                -- Customer information
                u.first_name as customer_first_name,
                u.last_name as customer_last_name,
                u.email as customer_email,
                u.phone as customer_phone,
                -- Dealer information
                d.business_name,
                d.business_address,
                d.latitude,
                d.longitude,
                d.business_phone as dealer_phone,
                -- Food listing information
                fl.title as food_title,
                fl.description as food_description,
                fl.price,
                -- Driver information if assigned
                dr.status as driver_status,
                dr.vehicle_type,
                dr.vehicle_plate,
                du.first_name as driver_first_name,
                du.last_name as driver_last_name
            FROM orders o
            LEFT JOIN users u ON o.customer_id = u.user_id
            LEFT JOIN dealers d ON o.dealer_id = d.dealer_id
            LEFT JOIN food_listings fl ON o.listing_id = fl.listing_id
            LEFT JOIN drivers dr ON o.driver_id = dr.driver_id
            LEFT JOIN users du ON dr.user_id = du.user_id
            WHERE o.status IN ('confirmed', 'ready')
            AND o.driver_id IS NULL
            ORDER BY o.order_date ASC
            LIMIT 50
        ";

        $result = $conn->query($sql);

        if (!$result) {
            throw new Exception("Query failed: " . $conn->error);
        }

        $orders = [];
        while ($row = $result->fetch_assoc()) {
            // Format dates
            $row['order_date_formatted'] = date('Y-m-d H:i:s', strtotime($row['order_date']));
            $row['created_at_formatted'] = date('Y-m-d H:i:s', strtotime($row['created_at']));
            $row['updated_at_formatted'] = date('Y-m-d H:i:s', strtotime($row['updated_at']));

            if ($row['delivery_date']) {
                $row['delivery_date_formatted'] = date('Y-m-d H:i:s', strtotime($row['delivery_date']));
            }

            // Determine if order needs a driver
            $row['needs_driver'] = ($row['driver_id'] === null);

            // Add distance calculation (placeholder)
            $row['estimated_distance'] = 'To be calculated';
            $row['estimated_time'] = '15-30 minutes';

            // Ensure delivery fee is set
            $row['delivery_fee'] = $row['delivery_fee'] ?? 0.00;
            $row['total_with_delivery'] = $row['total_with_delivery'] ?? $row['total_amount'];

            $orders[] = $row;
        }

        // Also get bookings with delivery requirements
        $bookingsSql = "
            SELECT 
                b.booking_id,
                b.customer_id,
                b.dealer_id,
                b.dish_id as listing_id,
                b.customer_name,
                b.customer_email,
                b.customer_phone,
                b.booking_date,
                b.booking_time,
                b.party_size,
                b.special_requests,
                b.status,
                b.delivery_fee,
                b.delivery_required,
                b.delivery_address,
                b.driver_id,
                b.delivery_assigned_at,
                b.created_at,
                b.updated_at,
                -- Dealer information
                d.business_name,
                d.business_address,
                d.latitude,
                d.longitude,
                d.business_phone as dealer_phone,
                -- Food listing information if available
                fl.title as food_title,
                fl.description as food_description,
                fl.price
            FROM table_bookings b
            LEFT JOIN dealers d ON b.dealer_id = d.dealer_id
            LEFT JOIN food_listings fl ON b.dish_id = fl.listing_id
            WHERE b.delivery_required = 1 
            AND b.status = 'confirmed'
            AND b.driver_id IS NULL
            ORDER BY b.booking_date ASC, b.booking_time ASC
            LIMIT 20
        ";

        $bookingsResult = $conn->query($bookingsSql);
        $bookings = [];

        if ($bookingsResult) {
            while ($row = $bookingsResult->fetch_assoc()) {
                // Calculate total for booking (price from listing + delivery fee)
                $price = $row['price'] ?? 0.00;
                $delivery_fee = $row['delivery_fee'] ?? 0.00;
                $total_amount = $price + $delivery_fee;

                // Convert table booking to order format for consistency
                $order = [
                    'type' => 'booking',
                    'order_id' => 'B' . $row['booking_id'],
                    'booking_id' => $row['booking_id'],
                    'customer_id' => $row['customer_id'],
                    'dealer_id' => $row['dealer_id'],
                    'listing_id' => $row['listing_id'],
                    'customer_first_name' => $row['customer_name'],
                    'customer_email' => $row['customer_email'],
                    'customer_phone' => $row['customer_phone'],
                    'business_name' => $row['business_name'],
                    'business_address' => $row['business_address'],
                    'delivery_address' => $row['delivery_address'],
                    'delivery_phone' => $row['customer_phone'],
                    'food_title' => $row['food_title'],
                    'food_description' => $row['food_description'],
                    'price' => $price,
                    'delivery_fee' => $delivery_fee,
                    'quantity' => 1, // Default for bookings
                    'total_amount' => $price,
                    'total_with_delivery' => $total_amount,
                    'status' => 'ready_for_delivery',
                    'order_date' => $row['booking_date'] . ' ' . $row['booking_time'],
                    'order_date_formatted' => $row['booking_date'] . ' ' . $row['booking_time'],
                    'special_instructions' => $row['special_requests'],
                    'needs_driver' => true,
                    'estimated_distance' => 'To be calculated',
                    'estimated_time' => '15-30 minutes'
                ];
                $bookings[] = $order;
            }
        }

        // Combine orders and bookings
        $allDeliveries = array_merge($orders, $bookings);

        return [
            'status' => 'success',
            'count' => count($allDeliveries),
            'orders' => $allDeliveries,
            'summary' => [
                'total_available' => count($allDeliveries),
                'regular_orders' => count($orders),
                'booking_deliveries' => count($bookings)
            ]
        ];
    } catch (Exception $e) {
        throw $e;
    }
}

/**
 * Fetch orders assigned to a specific driver
 */
function getDriverOrders($conn, $driver_id)
{
    try {
        // Validate driver exists
        $driverCheck = $conn->prepare("SELECT * FROM drivers WHERE driver_id = ?");
        $driverCheck->bind_param("i", $driver_id);
        $driverCheck->execute();
        $driverResult = $driverCheck->get_result();

        if ($driverResult->num_rows === 0) {
            return [
                'status' => 'error',
                'message' => 'Driver not found'
            ];
        }

        $driver = $driverResult->fetch_assoc();

        // Get driver's current orders
        $sql = "
            SELECT 
                o.order_id,
                o.customer_id,
                o.dealer_id,
                o.driver_id,
                o.listing_id,
                o.quantity,
                o.unit_price,
                o.total_amount,
                o.delivery_fee,
                o.status,
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
                -- Calculate total with delivery fee
                (o.total_amount + COALESCE(o.delivery_fee, 0)) as total_with_delivery,
                -- Customer information
                u.first_name as customer_first_name,
                u.last_name as customer_last_name,
                u.email as customer_email,
                u.phone as customer_phone,
                -- Dealer information
                d.business_name,
                d.business_address,
                d.latitude as dealer_latitude,
                d.longitude as dealer_longitude,
                d.business_phone as dealer_phone,
                -- Food listing information
                fl.title as food_title,
                fl.description as food_description,
                fl.price,
                -- Driver information
                dr.status as driver_status,
                dr.vehicle_type,
                dr.vehicle_plate,
                dr.current_latitude,
                dr.current_longitude,
                dr.availability_status,
                dr.earning_balance
            FROM orders o
            LEFT JOIN users u ON o.customer_id = u.user_id
            LEFT JOIN dealers d ON o.dealer_id = d.dealer_id
            LEFT JOIN food_listings fl ON o.listing_id = fl.listing_id
            LEFT JOIN drivers dr ON o.driver_id = dr.driver_id
            WHERE o.driver_id = ? 
            AND o.status IN ('confirmed', 'ready', 'preparing')
            ORDER BY 
                CASE o.status
                    WHEN 'preparing' THEN 1
                    WHEN 'ready' THEN 2
                    WHEN 'confirmed' THEN 3
                    ELSE 4
                END,
                o.order_date ASC
        ";

        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $driver_id);
        $stmt->execute();
        $result = $stmt->get_result();

        $orders = [];
        while ($row = $result->fetch_assoc()) {
            // Add status information
            $row['order_status'] = $row['status'];
            $row['is_active'] = in_array($row['status'], ['confirmed', 'ready', 'preparing']);
            $row['can_pickup'] = $row['status'] === 'ready';
            $row['can_deliver'] = $row['status'] === 'preparing';

            // Format dates
            $row['order_date_formatted'] = date('Y-m-d H:i:s', strtotime($row['order_date']));

            // Ensure delivery fee is set
            $row['delivery_fee'] = $row['delivery_fee'] ?? 0.00;
            $row['total_with_delivery'] = $row['total_with_delivery'] ?? $row['total_amount'];

            // Calculate driver earnings for this order (80% of delivery fee as example)
            $row['driver_earnings'] = round($row['delivery_fee'] * 0.8, 2);

            $orders[] = $row;
        }

        // Also get driver's table booking deliveries
        $bookingsSql = "
            SELECT 
                b.booking_id,
                b.customer_id,
                b.dealer_id,
                b.dish_id as listing_id,
                b.customer_name,
                b.customer_email,
                b.customer_phone,
                b.booking_date,
                b.booking_time,
                b.party_size,
                b.special_requests,
                b.status,
                b.delivery_fee,
                b.delivery_required,
                b.delivery_address,
                b.driver_id,
                b.delivery_assigned_at,
                b.created_at,
                b.updated_at,
                -- Dealer information
                d.business_name,
                d.business_address,
                d.latitude as dealer_latitude,
                d.longitude as dealer_longitude,
                d.business_phone as dealer_phone,
                -- Food listing information
                fl.title as food_title,
                fl.description as food_description,
                fl.price
            FROM table_bookings b
            LEFT JOIN dealers d ON b.dealer_id = d.dealer_id
            LEFT JOIN food_listings fl ON b.dish_id = fl.listing_id
            WHERE b.driver_id = ?
            AND b.delivery_required = 1
            AND b.status = 'confirmed'
            ORDER BY b.booking_date ASC, b.booking_time ASC
        ";

        $bookingsStmt = $conn->prepare($bookingsSql);
        $bookingsStmt->bind_param("i", $driver_id);
        $bookingsStmt->execute();
        $bookingsResult = $bookingsStmt->get_result();

        $bookings = [];
        while ($row = $bookingsResult->fetch_assoc()) {
            // Calculate total for booking
            $price = $row['price'] ?? 0.00;
            $delivery_fee = $row['delivery_fee'] ?? 0.00;
            $total_amount = $price + $delivery_fee;

            $booking = [
                'type' => 'booking',
                'booking_id' => $row['booking_id'],
                'order_id' => 'B' . $row['booking_id'],
                'customer_id' => $row['customer_id'],
                'dealer_id' => $row['dealer_id'],
                'listing_id' => $row['listing_id'],
                'customer_first_name' => $row['customer_name'],
                'customer_email' => $row['customer_email'],
                'customer_phone' => $row['customer_phone'],
                'business_name' => $row['business_name'],
                'business_address' => $row['business_address'],
                'dealer_latitude' => $row['dealer_latitude'],
                'dealer_longitude' => $row['dealer_longitude'],
                'delivery_address' => $row['delivery_address'],
                'delivery_phone' => $row['customer_phone'],
                'food_title' => $row['food_title'],
                'food_description' => $row['food_description'],
                'price' => $price,
                'delivery_fee' => $delivery_fee,
                'total_with_delivery' => $total_amount,
                'status' => $row['status'],
                'order_date' => $row['booking_date'] . ' ' . $row['booking_time'],
                'order_date_formatted' => $row['booking_date'] . ' ' . $row['booking_time'],
                'special_instructions' => $row['special_requests'],
                'delivery_assigned_at' => $row['delivery_assigned_at'],
                'driver_earnings' => round($delivery_fee * 0.8, 2)
            ];
            $bookings[] = $booking;
        }

        // Combine orders and bookings
        $allAssignments = array_merge($orders, $bookings);

        // Get driver's completed orders for statistics
        $completedSql = "
            SELECT 
                COUNT(DISTINCT o.order_id) as total_completed_orders,
                COUNT(DISTINCT b.booking_id) as total_completed_bookings,
                SUM(COALESCE(o.delivery_fee, 0)) as total_delivery_fees,
                AVG(o.total_amount) as avg_order_value,
                dr.earning_balance as current_balance
            FROM drivers dr
            LEFT JOIN orders o ON dr.driver_id = o.driver_id AND o.status = 'delivered'
            LEFT JOIN table_bookings b ON dr.driver_id = b.driver_id AND b.status = 'completed'
            WHERE dr.driver_id = ?
            GROUP BY dr.driver_id
        ";

        $statsStmt = $conn->prepare($completedSql);
        $statsStmt->bind_param("i", $driver_id);
        $statsStmt->execute();
        $statsResult = $statsStmt->get_result();
        $stats = $statsResult->fetch_assoc();

        // Calculate estimated earnings (80% of delivery fees)
        if ($stats) {
            $total_delivery_fees = $stats['total_delivery_fees'] ?? 0;
            $stats['estimated_earnings'] = round($total_delivery_fees * 0.8, 2);
        }

        return [
            'status' => 'success',
            'driver_id' => $driver_id,
            'driver_info' => $driver,
            'current_assignments' => count($allAssignments),
            'assignments' => $allAssignments,
            'statistics' => $stats,
            'active_orders' => array_filter($allAssignments, function ($item) {
                return isset($item['status']) && in_array($item['status'], ['confirmed', 'ready', 'preparing']);
            }),
            'completed_orders' => array_filter($allAssignments, function ($item) {
                return isset($item['status']) && ($item['status'] === 'delivered' || $item['status'] === 'completed');
            })
        ];
    } catch (Exception $e) {
        throw $e;
    }
}

/**
 * Driver accepts an order
 */
function acceptOrder($conn, $driver_id, $order_id, $payload = [])
{
    try {
        $conn->autocommit(FALSE); // Start transaction

        // Check if driver exists and is available
        $driverCheck = $conn->prepare("
            SELECT * FROM drivers 
            WHERE driver_id = ? 
            AND status = 'active'
        ");
        $driverCheck->bind_param("i", $driver_id);
        $driverCheck->execute();
        $driverResult = $driverCheck->get_result();

        if ($driverResult->num_rows === 0) {
            $debugSql = "SELECT driver_id, status, availability_status FROM drivers WHERE driver_id = ?";
            $debugStmt = $conn->prepare($debugSql);
            $debugStmt->bind_param("i", $driver_id);
            $debugStmt->execute();
            $debugResult = $debugStmt->get_result();
            $debugDriver = $debugResult->fetch_assoc();
            return [
                'status' => 'error',
                'message' => 'Driver not found or not active.',
                'debug' => $debugDriver ?: ('No driver found with ID: ' . $driver_id)
            ];
        }

        $driver = $driverResult->fetch_assoc();

        // Check if it's a regular order
        $orderCheck = $conn->prepare("
            SELECT * FROM orders 
            WHERE order_id = ? 
            AND status IN ('confirmed', 'ready')
            AND driver_id IS NULL
        ");
        $orderCheck->bind_param("i", $order_id);
        $orderCheck->execute();
        $orderResult = $orderCheck->get_result();

        if ($orderResult->num_rows > 0) {
            $order = $orderResult->fetch_assoc();
            $type = 'order';

            // Update order with driver assignment - set to 'preparing' when driver accepts
            $hasFee = isset($payload['delivery_fee']) && $payload['delivery_fee'] !== '';
            $sql = "UPDATE orders SET driver_id = ?, driver_assigned_at = NOW(), status = 'preparing', updated_at = NOW()";
            if ($hasFee) {
                $sql .= ", delivery_fee = ?";
            }
            $sql .= " WHERE order_id = ?";
            $updateOrder = $conn->prepare($sql);
            if ($hasFee) {
                $fee = (float)$payload['delivery_fee'];
                $updateOrder->bind_param("idi", $driver_id, $fee, $order_id);
            } else {
                $updateOrder->bind_param("ii", $driver_id, $order_id);
            }

            if (!$updateOrder->execute()) {
                throw new Exception("Failed to assign order: " . $conn->error);
            }

            $target_id = $order_id;
            $delivery_fee = $order['delivery_fee'] ?? 0.00;
        } else {
            // Check if it's a booking (but handle booking_id format like 'B12')
            $booking_id = $order_id;
            if (strpos($order_id, 'B') === 0) {
                $booking_id = intval(substr($order_id, 1));
            }

            $bookingCheck = $conn->prepare("
                SELECT * FROM table_bookings 
                WHERE booking_id = ? 
                AND status = 'confirmed'
                AND delivery_required = 1
                AND driver_id IS NULL
            ");
            $bookingCheck->bind_param("i", $booking_id);
            $bookingCheck->execute();
            $bookingResult = $bookingCheck->get_result();

            if ($bookingResult->num_rows === 0) {
                return [
                    'status' => 'error',
                    'message' => 'Order/Booking not available or already assigned'
                ];
            }

            $booking = $bookingResult->fetch_assoc();
            $type = 'booking';

            // Update booking with driver assignment
            $hasFeeBk = isset($payload['delivery_fee']) && $payload['delivery_fee'] !== '';
            $bksql = "UPDATE table_bookings SET driver_id = ?, delivery_assigned_at = NOW(), updated_at = NOW()";
            if ($hasFeeBk) {
                $bksql .= ", delivery_fee = ?";
            }
            $bksql .= " WHERE booking_id = ?";
            $updateBooking = $conn->prepare($bksql);
            if ($hasFeeBk) {
                $bkfee = (float)$payload['delivery_fee'];
                $updateBooking->bind_param("idi", $driver_id, $bkfee, $booking_id);
            } else {
                $updateBooking->bind_param("ii", $driver_id, $booking_id);
            }

            if (!$updateBooking->execute()) {
                throw new Exception("Failed to assign booking: " . $conn->error);
            }

            $target_id = $booking_id;
            $delivery_fee = $booking['delivery_fee'] ?? 0.00;
        }

        // Update driver's availability status to 'on_delivery'
        $updateDriver = $conn->prepare("
            UPDATE drivers 
            SET availability_status = 'on_delivery',
                updated_at = NOW()
            WHERE driver_id = ?
        ");
        $updateDriver->bind_param("i", $driver_id);

        if (!$updateDriver->execute()) {
            throw new Exception("Failed to update driver status: " . $conn->error);
        }

        $conn->commit();

        // Get updated assignment info
        if ($type === 'order') {
            $getOrderSql = "SELECT * FROM orders WHERE order_id = ?";
            $getOrder = $conn->prepare($getOrderSql);
            $getOrder->bind_param("i", $target_id);
            $getOrder->execute();
            $orderDetails = $getOrder->get_result()->fetch_assoc();
        } else {
            $getBookingSql = "SELECT * FROM table_bookings WHERE booking_id = ?";
            $getBooking = $conn->prepare($getBookingSql);
            $getBooking->bind_param("i", $target_id);
            $getBooking->execute();
            $orderDetails = $getBooking->get_result()->fetch_assoc();
        }

        return [
            'status' => 'success',
            'message' => ucfirst($type) . ' successfully assigned to driver',
            'driver_id' => $driver_id,
            'order_id' => $target_id,
            'type' => $type,
            'delivery_fee' => $delivery_fee,
            'driver_earnings' => round($delivery_fee * 0.8, 2),
            'assigned_at' => date('Y-m-d H:i:s'),
            'details' => $orderDetails
        ];
    } catch (Exception $e) {
        $conn->rollback();
        throw $e;
    } finally {
        $conn->autocommit(TRUE);
    }
}

/**
 * Update order status (pickup, delivery, etc.)
 */
function updateOrderStatus($conn, $driver_id, $order_id, $status)
{
    try {
        $conn->autocommit(FALSE);

        // Check if it's a booking (starts with 'B') or regular order
        if (strpos($order_id, 'B') === 0) {
            $booking_id = intval(substr($order_id, 1));
            $type = 'booking';

            // Check if driver owns this booking
            $checkBookingSql = "SELECT * FROM table_bookings WHERE booking_id = ? AND driver_id = ?";
            $checkBookingStmt = $conn->prepare($checkBookingSql);
            $checkBookingStmt->bind_param("ii", $booking_id, $driver_id);
            $checkBookingStmt->execute();
            $bookingResult = $checkBookingStmt->get_result();

            if ($bookingResult->num_rows === 0) {
                return [
                    'status' => 'error',
                    'message' => 'Booking not found or not assigned to this driver'
                ];
            }

            $currentData = $bookingResult->fetch_assoc();
            $delivery_fee = $currentData['delivery_fee'] ?? 0.00;
        } else {
            $type = 'order';
            $order_id_int = intval($order_id);

            // Check if driver owns this order
            $checkSql = "SELECT * FROM orders WHERE order_id = ? AND driver_id = ?";
            $checkStmt = $conn->prepare($checkSql);
            $checkStmt->bind_param("ii", $order_id_int, $driver_id);
            $checkStmt->execute();
            $orderResult = $checkStmt->get_result();

            if ($orderResult->num_rows === 0) {
                return [
                    'status' => 'error',
                    'message' => 'Order not found or not assigned to this driver'
                ];
            }

            $currentData = $orderResult->fetch_assoc();
            $delivery_fee = $currentData['delivery_fee'] ?? 0.00;
        }

        $updates = [];

        // Handle different status updates
        switch ($status) {
            case 'picked_up':
                if ($type === 'order') {
                    $updates[] = "status = 'ready'";
                    $updates[] = "driver_pickup_time = NOW()";
                    $message = 'Order picked up successfully';
                } else {
                    // For bookings, update status
                    $updates[] = "status = 'confirmed'";
                    $message = 'Booking delivery picked up successfully';
                }
                break;

            case 'delivered':
                if ($type === 'order') {
                    $updates[] = "status = 'delivered'";
                    $updates[] = "driver_delivery_time = NOW()";
                    $updates[] = "delivery_date = NOW()";
                    $message = 'Order delivered successfully';

                    // Calculate driver earnings (80% of delivery fee)
                    $driver_earnings = round($delivery_fee * 0.8, 2);

                    // Add to driver_earnings table
                    $earningSql = "
                        INSERT INTO driver_earnings 
                        (driver_id, order_id, amount, status, created_at) 
                        VALUES (?, ?, ?, 'pending', NOW())
                    ";
                    $earningStmt = $conn->prepare($earningSql);
                    $earningStmt->bind_param("iid", $driver_id, $order_id_int, $driver_earnings);
                    $earningStmt->execute();

                    // Update driver's earning balance
                    $updateBalanceSql = "
                        UPDATE drivers 
                        SET earning_balance = earning_balance + ?,
                            updated_at = NOW()
                        WHERE driver_id = ?
                    ";
                    $updateBalanceStmt = $conn->prepare($updateBalanceSql);
                    $updateBalanceStmt->bind_param("di", $driver_earnings, $driver_id);
                    $updateBalanceStmt->execute();
                } else {
                    $updates[] = "status = 'completed'";
                    $message = 'Booking delivery completed successfully';

                    // For booking deliveries, also add to driver earnings
                    $driver_earnings = round($delivery_fee * 0.8, 2);

                    $earningSql = "
                        INSERT INTO driver_earnings 
                        (driver_id, booking_id, amount, status, created_at) 
                        VALUES (?, ?, ?, 'pending', NOW())
                    ";
                    $earningStmt = $conn->prepare($earningSql);
                    $earningStmt->bind_param("iid", $driver_id, $booking_id, $driver_earnings);
                    $earningStmt->execute();

                    $updateBalanceSql = "
                        UPDATE drivers 
                        SET earning_balance = earning_balance + ?,
                            updated_at = NOW()
                        WHERE driver_id = ?
                    ";
                    $updateBalanceStmt = $conn->prepare($updateBalanceSql);
                    $updateBalanceStmt->bind_param("di", $driver_earnings, $driver_id);
                    $updateBalanceStmt->execute();
                }
                break;

            default:
                return [
                    'status' => 'error',
                    'message' => 'Invalid status. Use: picked_up or delivered'
                ];
        }

        if (empty($updates)) {
            return [
                'status' => 'error',
                'message' => 'No updates to perform'
            ];
        }

        $updates[] = "updated_at = NOW()";

        // Build the update query
        if ($type === 'order') {
            $sql = "UPDATE orders SET " . implode(", ", $updates) . " WHERE order_id = ? AND driver_id = ?";
            $updateStmt = $conn->prepare($sql);
            $updateStmt->bind_param("ii", $order_id_int, $driver_id);
        } else {
            $sql = "UPDATE table_bookings SET " . implode(", ", $updates) . " WHERE booking_id = ? AND driver_id = ?";
            $updateStmt = $conn->prepare($sql);
            $updateStmt->bind_param("ii", $booking_id, $driver_id);
        }

        if (!$updateStmt->execute()) {
            throw new Exception("Failed to update status: " . $conn->error);
        }

        // If delivered, update driver status back to online
        if ($status === 'delivered') {
            $updateDriverSql = "
                UPDATE drivers 
                SET availability_status = 'online',
                    updated_at = NOW()
                WHERE driver_id = ?
            ";
            $updateDriverStmt = $conn->prepare($updateDriverSql);
            $updateDriverStmt->bind_param("i", $driver_id);
            $updateDriverStmt->execute();
        }

        $conn->commit();

        return [
            'status' => 'success',
            'message' => $message,
            'driver_id' => $driver_id,
            'order_id' => $order_id,
            'type' => $type,
            'new_status' => $status,
            'delivery_fee' => $delivery_fee,
            'driver_earnings' => isset($driver_earnings) ? round($driver_earnings, 2) : 0.00,
            'updated_at' => date('Y-m-d H:i:s')
        ];
    } catch (Exception $e) {
        $conn->rollback();
        throw $e;
    } finally {
        $conn->autocommit(TRUE);
    }
}

/**
 * Update driver's current location
 */
function updateDriverLocation($conn, $driver_id, $latitude, $longitude)
{
    try {
        $sql = "
            UPDATE drivers 
            SET current_latitude = ?,
                current_longitude = ?,
                updated_at = NOW()
            WHERE driver_id = ?
        ";

        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ddi", $latitude, $longitude, $driver_id);

        if (!$stmt->execute()) {
            throw new Exception("Failed to update location: " . $conn->error);
        }

        return [
            'status' => 'success',
            'message' => 'Location updated successfully',
            'driver_id' => $driver_id,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'updated_at' => date('Y-m-d H:i:s')
        ];
    } catch (Exception $e) {
        throw $e;
    }
}
