-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 15, 2025 at 06:06 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `foodsale`
--

-- --------------------------------------------------------

--
-- Table structure for table `admin_settings`
--

CREATE TABLE `admin_settings` (
  `setting_id` int(11) NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `description` text DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin_settings`
--

INSERT INTO `admin_settings` (`setting_id`, `setting_key`, `setting_value`, `description`, `updated_at`) VALUES
(1, 'site_name', 'FoodHub', 'Website name', '2025-08-02 13:24:37'),
(2, 'commission_rate', '10.00', 'Default commission rate for dealers', '2025-08-02 13:24:37'),
(3, 'auto_approve_listings', '0', 'Auto approve new listings (0=no, 1=yes)', '2025-08-02 13:24:37'),
(4, 'max_images_per_listing', '5', 'Maximum images allowed per listing', '2025-08-02 13:24:37');

-- --------------------------------------------------------

--
-- Table structure for table `banner_advertisements`
--

CREATE TABLE `banner_advertisements` (
  `banner_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image_path` varchar(500) NOT NULL,
  `link_url` varchar(500) DEFAULT NULL,
  `position` enum('top','middle','bottom','box') DEFAULT 'top',
  `is_active` tinyint(1) DEFAULT 1,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `banner_advertisements`
--

INSERT INTO `banner_advertisements` (`banner_id`, `title`, `description`, `image_path`, `link_url`, `position`, `is_active`, `start_date`, `end_date`, `created_at`, `updated_at`, `created_by`) VALUES
(34, '.', '', 'uploads/banners/banner_69355f0f60b93.jpg', '', 'top', 1, '2025-12-07', '2026-01-06', '2025-12-07 11:03:43', '2025-12-07 11:03:43', NULL),
(35, '.', '', 'uploads/box_ads/box_69355f35335b2.jpg', '', 'box', 1, '2025-12-07', '2026-01-06', '2025-12-07 11:04:21', '2025-12-07 11:04:21', NULL),
(36, '', '', 'uploads/box_ads/box_69355f642c24e.jpg', '', 'box', 1, '2025-12-07', '2026-01-06', '2025-12-07 11:05:08', '2025-12-07 11:05:08', NULL),
(37, '', '', 'uploads/box_ads/box_69355f77240db.jpg', '', 'box', 1, '2025-12-07', '2026-01-06', '2025-12-07 11:05:27', '2025-12-07 11:05:27', NULL),
(38, '.', '', 'uploads/banners/banner_69355fedea203.jpg', '', 'top', 1, '2025-12-07', '2026-01-06', '2025-12-07 11:07:25', '2025-12-07 11:07:25', NULL),
(39, '.', '', 'uploads/banners/banner_693840dbc327f.jpg', '', 'top', 1, '2025-12-09', '2026-01-08', '2025-12-09 15:31:39', '2025-12-09 15:31:39', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `cart`
--

CREATE TABLE `cart` (
  `cart_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `listing_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cart`
--

INSERT INTO `cart` (`cart_id`, `customer_id`, `listing_id`, `quantity`, `added_at`) VALUES
(1, 2, 111, 1, '2025-12-13 09:24:55');

-- --------------------------------------------------------

--
-- Table structure for table `cities`
--

CREATE TABLE `cities` (
  `city_id` int(11) NOT NULL,
  `country_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cities`
--

INSERT INTO `cities` (`city_id`, `country_id`, `name`, `is_active`, `created_at`) VALUES
(1, 1, 'New York', 1, '2025-09-15 16:03:36'),
(2, 1, 'Los Angeles', 1, '2025-09-15 16:03:36'),
(3, 1, 'Chicago', 1, '2025-09-15 16:03:36'),
(4, 1, 'Houston', 1, '2025-09-15 16:03:36'),
(5, 2, 'London', 1, '2025-09-15 16:03:36'),
(6, 2, 'Manchester', 1, '2025-09-15 16:03:36'),
(7, 2, 'Birmingham', 1, '2025-09-15 16:03:36'),
(8, 3, 'Toronto', 1, '2025-09-15 16:03:36'),
(9, 3, 'Vancouver', 1, '2025-09-15 16:03:36'),
(10, 3, 'Montreal', 1, '2025-09-15 16:03:36'),
(11, 4, 'Sydney', 1, '2025-09-15 16:03:36'),
(12, 4, 'Melbourne', 1, '2025-09-15 16:03:36'),
(13, 5, 'Mumbai', 1, '2025-09-15 16:03:36'),
(14, 5, 'Delhi', 1, '2025-09-15 16:03:36'),
(15, 6, 'Beijing', 1, '2025-09-15 16:03:36'),
(16, 6, 'Shanghai', 1, '2025-09-15 16:03:36'),
(17, 7, 'Tokyo', 1, '2025-09-15 16:03:36'),
(18, 7, 'Osaka', 1, '2025-09-15 16:03:36'),
(19, 8, 'Berlin', 1, '2025-09-15 16:03:36'),
(20, 8, 'Munich', 1, '2025-09-15 16:03:36'),
(21, 9, 'Paris', 1, '2025-09-15 16:03:36'),
(22, 9, 'Marseille', 1, '2025-09-15 16:03:36'),
(23, 10, 'Rome', 1, '2025-09-15 16:03:36'),
(24, 10, 'Milan', 1, '2025-09-15 16:03:36'),
(25, 11, 'zambia', 1, '2025-09-15 16:12:28'),
(26, 11, 'lusaka', 1, '2025-12-11 14:57:44'),
(27, 11, 'mansa', 1, '2025-12-11 14:58:01');

-- --------------------------------------------------------

--
-- Table structure for table `countries`
--

CREATE TABLE `countries` (
  `country_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `code` varchar(3) NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `countries`
--

INSERT INTO `countries` (`country_id`, `name`, `code`, `is_active`, `created_at`) VALUES
(1, 'United States', 'USA', 1, '2025-09-15 16:03:36'),
(2, 'United Kingdom', 'GBR', 1, '2025-09-15 16:03:36'),
(3, 'Canada', 'CAN', 1, '2025-09-15 16:03:36'),
(4, 'Australia', 'AUS', 1, '2025-09-15 16:03:36'),
(5, 'India', 'IND', 1, '2025-09-15 16:03:36'),
(6, 'China', 'CHN', 1, '2025-09-15 16:03:36'),
(7, 'Japan', 'JPN', 1, '2025-09-15 16:03:36'),
(8, 'Germany', 'DEU', 1, '2025-09-15 16:03:36'),
(9, 'France', 'FRA', 1, '2025-09-15 16:03:36'),
(10, 'Italy', 'ITA', 1, '2025-09-15 16:03:36'),
(11, 'zambia', 'zam', 1, '2025-09-15 16:12:07');

-- --------------------------------------------------------

--
-- Table structure for table `cuisine_types`
--

CREATE TABLE `cuisine_types` (
  `cuisine_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cuisine_types`
--

INSERT INTO `cuisine_types` (`cuisine_id`, `name`, `description`, `is_active`, `created_at`) VALUES
(18, 'English', '', 1, '2025-10-07 23:07:32'),
(19, 'Indian', '', 1, '2025-10-07 23:07:40'),
(20, 'Portuguese', '', 1, '2025-10-07 23:07:51'),
(21, 'Chinese', '', 1, '2025-10-07 23:08:06'),
(22, 'Mexican', '', 1, '2025-10-07 23:08:33'),
(23, 'Italian', '', 1, '2025-10-07 23:08:41'),
(24, 'Middle Eastern', '', 1, '2025-10-07 23:08:55'),
(25, 'Thai', '', 1, '2025-10-07 23:09:02'),
(26, 'Sushi', '', 1, '2025-10-07 23:09:20'),
(27, 'African', '', 1, '2025-10-07 23:09:44'),
(28, 'None', '', 1, '2025-10-07 23:30:34'),
(29, 'Local', 'South African', 1, '2025-10-08 17:37:01');

-- --------------------------------------------------------

--
-- Table structure for table `dealers`
--

CREATE TABLE `dealers` (
  `dealer_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `business_name` varchar(255) NOT NULL,
  `business_type` varchar(100) DEFAULT NULL,
  `business_address` text DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `business_phone` varchar(20) DEFAULT NULL,
  `business_email` varchar(255) DEFAULT NULL,
  `tax_id` varchar(50) DEFAULT NULL,
  `license_number` varchar(100) DEFAULT NULL,
  `status` enum('pending','active','suspended') DEFAULT 'pending',
  `commission_rate` decimal(5,2) DEFAULT 10.00,
  `total_sales` decimal(10,2) DEFAULT 0.00,
  `rating` decimal(3,2) DEFAULT 0.00,
  `total_reviews` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `business_logo` varchar(255) DEFAULT NULL,
  `mission_statement` text DEFAULT NULL,
  `operating_hours` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`operating_hours`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `dealers`
--

INSERT INTO `dealers` (`dealer_id`, `user_id`, `business_name`, `business_type`, `business_address`, `latitude`, `longitude`, `business_phone`, `business_email`, `tax_id`, `license_number`, `status`, `commission_rate`, `total_sales`, `rating`, `total_reviews`, `created_at`, `updated_at`, `business_logo`, `mission_statement`, `operating_hours`) VALUES
(2, 3, 'Pepes on the Lake', 'restaurant', '2 Naigara Rd, Tyger Falls, Cape Town, 7530', -33.95530000, 18.37730000, '075 021 1867', 'info@pepe-s.co.za', NULL, NULL, 'active', 10.00, 0.00, 0.00, 0, '2025-08-04 12:17:53', '2025-12-11 15:20:09', 'uploads/logos/logo_2_68ed379a95e60.jpeg', 'Whether you’re looking for a tranquil lunch or an exciting evening out, it’s the ideal lakeside escape.', '{\"monday\":{\"open\":\"09:00\",\"close\":\"23:00\"},\"tuesday\":{\"open\":\"09:00\",\"close\":\"23:00\"},\"wednesday\":{\"open\":\"09:00\",\"close\":\"23:00\"},\"thursday\":{\"open\":\"09:00\",\"close\":\"23:00\"},\"friday\":{\"open\":\"09:00\",\"close\":\"23:00\"},\"saturday\":{\"open\":\"09:00\",\"close\":\"23:00\"},\"sunday\":{\"open\":\"09:00\",\"close\":\"23:00\"}}'),
(3, 4, 'u6u66u', 'restaurant', 'Matero, Lusaka, Zambia', -26.14450000, 28.04360000, '0770812506', 'c6hisalaluckyk5@gmail.com', NULL, NULL, 'active', 10.00, 0.00, 0.00, 0, '2025-09-15 09:29:13', '2025-09-21 21:18:47', 'uploads/logos/logo_3_68c8195a56eca.jpg', 'mk', '{\"monday\":{\"open\":\"09:00\",\"close\":\"17:00\"},\"tuesday\":{\"open\":\"09:00\",\"close\":\"17:00\"},\"wednesday\":{\"open\":\"09:00\",\"close\":\"17:00\"},\"thursday\":{\"open\":\"09:00\",\"close\":\"17:00\"},\"friday\":{\"open\":\"09:00\",\"close\":\"17:00\"},\"saturday\":{\"open\":\"09:00\",\"close\":\"17:00\"},\"sunday\":{\"open\":\"09:00\",\"close\":\"17:00\"}}'),
(10, 16, 'Hungry lion2', 'restaurant', NULL, NULL, NULL, '0771355473', 'mablechanda@351gmail.com', NULL, NULL, 'active', 10.00, 0.00, 0.00, 0, '2025-12-10 19:35:58', '2025-12-11 07:11:35', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `dealer_branches`
--

CREATE TABLE `dealer_branches` (
  `branch_id` int(11) NOT NULL,
  `dealer_id` int(11) NOT NULL,
  `branch_name` varchar(255) NOT NULL,
  `branch_address` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `dealer_branches`
--

INSERT INTO `dealer_branches` (`branch_id`, `dealer_id`, `branch_name`, `branch_address`, `created_at`) VALUES
(4, 2, 'pepesonthelake', 'cape town', '2025-10-09 15:22:35'),
(5, 2, 'chalala', '7878i', '2025-10-16 17:15:37');

-- --------------------------------------------------------

--
-- Table structure for table `dealer_sales_team`
--

CREATE TABLE `dealer_sales_team` (
  `id` int(11) NOT NULL,
  `dealer_id` int(11) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `position` varchar(100) NOT NULL,
  `hire_date` date NOT NULL,
  `status` enum('active','inactive','terminated') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `photo` varchar(255) DEFAULT NULL COMMENT 'Profile photo filename',
  `bio` text DEFAULT NULL COMMENT 'Team member biography'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `dealer_sales_team`
--

INSERT INTO `dealer_sales_team` (`id`, `dealer_id`, `first_name`, `last_name`, `email`, `phone`, `position`, `hire_date`, `status`, `created_at`, `updated_at`, `photo`, `bio`) VALUES
(5, 2, 'kisa', 'mula', 'ink@gmail.com', '(260) 993-8434', 'watress', '2000-09-18', 'active', '2025-10-24 09:24:15', '2025-10-24 10:01:46', 'team_68fb45bfae773.jpg', 'very good hard working man');

-- --------------------------------------------------------

--
-- Table structure for table `drivers`
--

CREATE TABLE `drivers` (
  `driver_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `status` enum('active','inactive','suspended') NOT NULL DEFAULT 'inactive',
  `vehicle_type` varchar(64) DEFAULT NULL,
  `vehicle_plate` varchar(32) DEFAULT NULL,
  `license_number` varchar(64) DEFAULT NULL,
  `rating` decimal(3,2) DEFAULT NULL,
  `earning_balance` decimal(10,2) NOT NULL DEFAULT 0.00,
  `current_latitude` decimal(10,8) DEFAULT NULL,
  `current_longitude` decimal(11,8) DEFAULT NULL,
  `availability_status` enum('offline','online','on_delivery') NOT NULL DEFAULT 'offline',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `drivers`
--

INSERT INTO `drivers` (`driver_id`, `user_id`, `status`, `vehicle_type`, `vehicle_plate`, `license_number`, `rating`, `earning_balance`, `current_latitude`, `current_longitude`, `availability_status`, `created_at`, `updated_at`) VALUES
(1, 18, 'active', 'motorbike', 'ABC123', 'LIC12345', NULL, 0.00, -33.92490000, 18.42410000, 'online', '2025-12-14 14:23:02', '2025-12-14 14:26:08'),
(2, 19, 'active', 'car', 'XYZ789', 'LIC67890', NULL, 0.00, -26.20410000, 28.04730000, 'online', '2025-12-14 14:23:04', '2025-12-14 14:26:09');

-- --------------------------------------------------------

--
-- Table structure for table `driver_earnings`
--

CREATE TABLE `driver_earnings` (
  `earning_id` int(11) NOT NULL,
  `driver_id` int(11) NOT NULL,
  `order_id` int(11) DEFAULT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `status` enum('pending','paid') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `paid_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `favorites`
--

CREATE TABLE `favorites` (
  `favorite_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `listing_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `food_categories`
--

CREATE TABLE `food_categories` (
  `category_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `subcategory` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `food_categories`
--

INSERT INTO `food_categories` (`category_id`, `name`, `subcategory`, `description`, `image_url`, `is_active`, `created_at`) VALUES
(1, 'Main Course', NULL, 'Full meals and main dishes', NULL, 1, '2025-08-02 13:24:36'),
(2, 'Starters', NULL, 'Starters and small plates', NULL, 1, '2025-08-02 13:24:36'),
(3, 'Desserts', NULL, 'Sweet treats and desserts', NULL, 1, '2025-08-02 13:24:36'),
(8, 'Breakfast', NULL, '', NULL, 1, '2025-08-05 15:56:52'),
(12, 'Snacks / light Meals', NULL, '', NULL, 1, '2025-09-19 07:23:21'),
(13, 'Street Foods', NULL, '', NULL, 1, '2025-09-19 07:23:46'),
(16, 'By Diet / Lifestyle', NULL, '', NULL, 1, '2025-09-19 08:10:14'),
(24, 'Platters', NULL, '', NULL, 1, '2025-10-07 22:33:31'),
(26, 'Beverages', NULL, 'All Drinks', NULL, 1, '2025-10-08 10:14:35'),
(28, 'Appetizers', NULL, NULL, NULL, 1, '2025-10-09 22:35:32'),
(29, 'Sides', NULL, 'all side items', NULL, 1, '2025-10-09 22:47:58'),
(30, 'Add Ons', NULL, 'such as rolls', NULL, 1, '2025-10-09 22:49:08'),
(31, 'Uncategorized', NULL, 'Auto-created fallback category', NULL, 1, '2025-10-11 06:34:15'),
(32, 'Combo Deals', NULL, 'Combos, Burger Deals and Platters', NULL, 1, '2025-10-11 07:19:48');

-- --------------------------------------------------------

--
-- Table structure for table `food_images`
--

CREATE TABLE `food_images` (
  `image_id` int(11) NOT NULL,
  `listing_id` int(11) NOT NULL,
  `image_url` varchar(255) NOT NULL,
  `alt_text` varchar(255) DEFAULT NULL,
  `is_primary` tinyint(1) DEFAULT 0,
  `sort_order` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `food_images`
--

INSERT INTO `food_images` (`image_id`, `listing_id`, `image_url`, `alt_text`, `is_primary`, `sort_order`, `created_at`) VALUES
(78, 71, 'uploads/dish_71_68e8a5d60472b.jpg', NULL, 1, 0, '2025-10-10 06:21:10'),
(79, 70, 'uploads/dish_70_68e8a62ff09a6.jpg', NULL, 1, 0, '2025-10-10 06:22:39'),
(80, 72, 'uploads/dish_72_68e8a6bfd1c0b.jpg', NULL, 1, 0, '2025-10-10 06:25:03'),
(81, 69, 'uploads/dish_69_68e8a72211718.jpg', NULL, 1, 0, '2025-10-10 06:26:42'),
(82, 68, 'uploads/dish_68_68e8a7637ab88.jpg', NULL, 1, 0, '2025-10-10 06:27:47'),
(83, 67, 'uploads/dish_67_68e8a7b4a5863.jpg', NULL, 1, 0, '2025-10-10 06:29:08'),
(84, 66, 'uploads/dish_66_68e8a7ca69ab9.jpg', NULL, 1, 0, '2025-10-10 06:29:30'),
(85, 65, 'uploads/dish_65_68e8a7f9e7d7e.jpg', NULL, 1, 0, '2025-10-10 06:30:17'),
(86, 64, 'uploads/dish_64_68e8a815b69ef.jpg', NULL, 1, 0, '2025-10-10 06:30:45'),
(87, 63, 'uploads/dish_63_68e8a83eb8ed3.jpg', NULL, 1, 0, '2025-10-10 06:31:26'),
(88, 62, 'uploads/dish_62_68e8a86a375af.jpg', NULL, 1, 0, '2025-10-10 06:32:10'),
(89, 61, 'uploads/dish_61_68e8a8a7511e3.jpg', NULL, 1, 0, '2025-10-10 06:33:11'),
(90, 60, 'uploads/dish_60_68e8a8bd63d03.jpg', NULL, 1, 0, '2025-10-10 06:33:33'),
(91, 59, 'uploads/dish_59_68e8a8e121dc9.jpg', NULL, 1, 0, '2025-10-10 06:34:09'),
(92, 58, 'uploads/dish_58_68e8a8fa095d2.jpg', NULL, 1, 0, '2025-10-10 06:34:34'),
(93, 57, 'uploads/dish_57_68e8a934bc6c3.jpg', NULL, 1, 0, '2025-10-10 06:35:32'),
(94, 56, 'uploads/dish_56_68e8a951cf4b2.jpg', NULL, 1, 0, '2025-10-10 06:36:01'),
(95, 55, 'uploads/dish_55_68e8a97009e1f.jpg', NULL, 1, 0, '2025-10-10 06:36:32'),
(96, 54, 'uploads/dish_54_68e8a9954688f.jpg', NULL, 1, 0, '2025-10-10 06:37:09'),
(97, 53, 'uploads/dish_53_68e8aa4d36670.jpg', NULL, 1, 0, '2025-10-10 06:40:13'),
(98, 52, 'uploads/dish_52_68e8aa74a9552.jpg', NULL, 1, 0, '2025-10-10 06:40:52'),
(99, 51, 'uploads/dish_51_68e8aa95f01ec.jpg', NULL, 1, 0, '2025-10-10 06:41:25'),
(100, 50, 'uploads/dish_50_68e8aab6506cc.jpg', NULL, 1, 0, '2025-10-10 06:41:58'),
(101, 49, 'uploads/dish_49_68e8aad939562.jpg', NULL, 1, 0, '2025-10-10 06:42:33'),
(102, 48, 'uploads/dish_48_68e8ab2c0d0cd.jpg', NULL, 1, 0, '2025-10-10 06:43:56'),
(103, 47, 'uploads/dish_47_68e8abee7cfc6.jpg', NULL, 1, 0, '2025-10-10 06:47:10'),
(104, 46, 'uploads/dish_46_68e8ac0f2025b.jpg', NULL, 1, 0, '2025-10-10 06:47:43'),
(105, 45, 'uploads/dish_45_68e8b58c7f0d6.jpg', NULL, 1, 0, '2025-10-10 07:28:12'),
(106, 44, 'uploads/dish_44_68e8b5f2efacd.jpg', NULL, 1, 0, '2025-10-10 07:29:54'),
(107, 42, 'uploads/dish_42_68e8b6879028d.jpg', NULL, 1, 0, '2025-10-10 07:32:23'),
(108, 41, 'uploads/dish_41_68e8b6d7b8361.jpg', NULL, 1, 0, '2025-10-10 07:33:43'),
(109, 40, 'uploads/dish_40_68e8b70b721ba.jpg', NULL, 1, 0, '2025-10-10 07:34:35'),
(110, 39, 'uploads/dish_39_68e8b7421e29c.jpg', NULL, 1, 0, '2025-10-10 07:35:30'),
(111, 38, 'uploads/dish_38_68e8b76cbac02.jpg', NULL, 1, 0, '2025-10-10 07:36:12'),
(112, 36, 'uploads/dish_36_68e8b79541880.jpg', NULL, 1, 0, '2025-10-10 07:36:53'),
(113, 35, 'uploads/dish_35_68e8b7c5e7d67.jpg', NULL, 1, 0, '2025-10-10 07:37:41'),
(114, 34, 'uploads/dish_34_68e8b7e44a241.jpg', NULL, 1, 0, '2025-10-10 07:38:12'),
(115, 43, 'uploads/dish_43_68e8b873dec21.jpg', NULL, 1, 0, '2025-10-10 07:40:35'),
(116, 74, 'uploads/dish_74_68e8bbd605cce.jpeg', NULL, 1, 0, '2025-10-10 07:55:02'),
(117, 75, 'uploads/dish_75_68e8bc25319a3.jpg', NULL, 1, 0, '2025-10-10 07:56:21'),
(118, 76, 'uploads/dish_76_68e8bc7995739.jpg', NULL, 1, 0, '2025-10-10 07:57:45'),
(119, 77, 'uploads/dish_77_68e8bd111f6b3.jpg', NULL, 1, 0, '2025-10-10 08:00:17'),
(120, 78, 'uploads/dish_78_68e8bd691db97.jpg', NULL, 1, 0, '2025-10-10 08:01:45'),
(121, 79, 'uploads/dish_79_68e8bdc5955e4.jpg', NULL, 1, 0, '2025-10-10 08:03:17'),
(122, 80, 'uploads/dish_80_68e8bef41c4f3.jpg', NULL, 1, 0, '2025-10-10 08:08:20'),
(123, 81, 'uploads/dish_81_68e8c04bc8d2e.jpeg', NULL, 1, 0, '2025-10-10 08:14:03'),
(124, 82, 'uploads/dish_82_68e8c11f53dde.jpg', NULL, 1, 0, '2025-10-10 08:17:35'),
(125, 83, 'uploads/dish_83_68e8c2eb82f9f.jpg', NULL, 1, 0, '2025-10-10 08:25:15'),
(126, 84, 'uploads/dish_84_68e8c41ce8709.jpeg', NULL, 1, 0, '2025-10-10 08:30:20'),
(127, 85, 'uploads/dish_85_68e8c549f3bc7.jpeg', NULL, 1, 0, '2025-10-10 08:35:22'),
(128, 86, 'uploads/dish_86_68e8c6395183f.jpg', NULL, 1, 0, '2025-10-10 08:39:21'),
(129, 87, 'uploads/dish_87_68e8c71098bbc.jpeg', NULL, 1, 0, '2025-10-10 08:42:56'),
(130, 88, 'uploads/dish_88_68e8c74f9266a.jpeg', NULL, 1, 0, '2025-10-10 08:43:59'),
(131, 89, 'uploads/dish_89_68e8c78cafdbd.jpeg', NULL, 1, 0, '2025-10-10 08:45:00'),
(132, 90, 'uploads/dish_90_68e8c8124f5c0.jpg', NULL, 1, 0, '2025-10-10 08:47:14'),
(133, 91, 'uploads/dish_91_68e8c87a6e2f9.jpg', NULL, 1, 0, '2025-10-10 08:48:58'),
(134, 92, 'uploads/dish_92_68e8c92b51d7f.jpg', NULL, 1, 0, '2025-10-10 08:51:55'),
(135, 93, 'uploads/dish_93_68e8ca328a8fb.jpg', NULL, 1, 0, '2025-10-10 08:56:18'),
(136, 94, 'uploads/dish_94_68e8ca5f64c1c.jpg', NULL, 1, 0, '2025-10-10 08:57:03'),
(137, 95, 'uploads/dish_95_68e8ca9106f6d.jpg', NULL, 1, 0, '2025-10-10 08:57:53'),
(138, 96, 'uploads/dish_96_68e8cab9d8645.jpg', NULL, 1, 0, '2025-10-10 08:58:33'),
(139, 97, 'uploads/dish_97_68e8cae800a1c.jpg', NULL, 1, 0, '2025-10-10 08:59:20'),
(140, 98, 'uploads/dish_98_68e8cb86646ab.jpeg', NULL, 1, 0, '2025-10-10 09:01:58'),
(141, 99, 'uploads/dish_99_68e8cbcbb35d4.jpeg', NULL, 1, 0, '2025-10-10 09:03:07'),
(142, 100, 'uploads/dish_100_68e8cc250ca12.jpeg', NULL, 1, 0, '2025-10-10 09:04:37'),
(143, 101, 'uploads/dish_101_68e8ccc4ed890.jpg', NULL, 1, 0, '2025-10-10 09:07:16'),
(144, 102, 'uploads/dish_102_68e8ccf55c13a.jpg', NULL, 1, 0, '2025-10-10 09:08:05'),
(145, 103, 'uploads/dish_103_68e8cd2f653e3.jpg', NULL, 1, 0, '2025-10-10 09:09:03'),
(146, 104, 'uploads/dish_104_68e8cd6db4712.jpg', NULL, 1, 0, '2025-10-10 09:10:05'),
(147, 105, 'uploads/dish_105_68e8cdc256d8b.jpeg', NULL, 1, 0, '2025-10-10 09:11:30'),
(148, 106, 'uploads/dish_106_68e8d2266f082.jpg', NULL, 1, 0, '2025-10-10 09:30:14'),
(149, 107, 'uploads/dish_107_68e8d2ba38ee4.jpg', NULL, 1, 0, '2025-10-10 09:32:42'),
(150, 108, 'uploads/dish_108_68e8d2f2919b5.jpg', NULL, 1, 0, '2025-10-10 09:33:38'),
(151, 109, 'uploads/dish_109_68e8d344f2cad.jpg', NULL, 1, 0, '2025-10-10 09:35:00'),
(152, 110, 'uploads/dish_110_68e8d39013849.jpg', NULL, 1, 0, '2025-10-10 09:36:16'),
(153, 111, 'uploads/dish_111_68e8d3cb9abc4.jpg', NULL, 1, 0, '2025-10-10 09:37:15'),
(154, 112, 'uploads/dish_112_68e8d3ee4e835.jpg', NULL, 1, 0, '2025-10-10 09:37:50'),
(155, 113, 'uploads/dish_113_68e8d43761293.jpeg', NULL, 1, 0, '2025-10-10 09:39:03'),
(157, 115, 'uploads/dish_115_68e8d53022624.jpg', NULL, 1, 0, '2025-10-10 09:43:12'),
(158, 116, 'uploads/dish_116_68e8d56a4a1be.jpeg', NULL, 1, 0, '2025-10-10 09:44:10'),
(159, 117, 'uploads/dish_117_68e8d5a388cf0.jpeg', NULL, 1, 0, '2025-10-10 09:45:07'),
(160, 118, 'uploads/dish_118_68e8d5da56e83.jpeg', NULL, 1, 0, '2025-10-10 09:46:02'),
(161, 119, 'uploads/dish_119_68e8d60af2e9b.jpeg', NULL, 1, 0, '2025-10-10 09:46:50'),
(162, 120, 'uploads/dish_120_68e8d6cee6433.jpg', NULL, 1, 0, '2025-10-10 09:50:06'),
(163, 121, 'uploads/dish_121_68e8d724306ac.jpeg', NULL, 1, 0, '2025-10-10 09:51:32'),
(164, 122, 'uploads/dish_122_68e8d75f5af43.jpeg', NULL, 1, 0, '2025-10-10 09:52:31'),
(165, 123, 'uploads/dish_123_68e8d7c9b35ea.jpg', NULL, 1, 0, '2025-10-10 09:54:17'),
(166, 124, 'uploads/dish_124_68e8d80297cc5.jpg', NULL, 1, 0, '2025-10-10 09:55:14'),
(167, 125, 'uploads/dish_125_68e8d8d78d3da.jpg', NULL, 1, 0, '2025-10-10 09:58:47'),
(168, 126, 'uploads/dish_126_68e8d929a4395.jpeg', NULL, 1, 0, '2025-10-10 10:00:09'),
(169, 127, 'uploads/dish_127_68e8d95d5da41.jpeg', NULL, 1, 0, '2025-10-10 10:01:01'),
(170, 128, 'uploads/dish_128_68e8d990ef948.jpg', NULL, 1, 0, '2025-10-10 10:01:52'),
(171, 129, 'uploads/dish_129_68e8d9c3ced31.jpg', NULL, 1, 0, '2025-10-10 10:02:43'),
(172, 130, 'uploads/dish_130_68e8da0a3c30c.jpg', NULL, 1, 0, '2025-10-10 10:03:54'),
(173, 131, 'uploads/dish_131_68e8da35960d0.jpg', NULL, 1, 0, '2025-10-10 10:04:37'),
(174, 132, 'uploads/dish_132_68e8db1e58a21.jpg', NULL, 1, 0, '2025-10-10 10:08:30'),
(175, 133, 'uploads/dish_133_68e8db4d746b0.jpg', NULL, 1, 0, '2025-10-10 10:09:17'),
(176, 134, 'uploads/dish_134_68e8db8af27e5.png', NULL, 1, 0, '2025-10-10 10:10:18'),
(177, 135, 'uploads/dish_135_68e8dbe9ad16f.jpg', NULL, 1, 0, '2025-10-10 10:11:53'),
(178, 136, 'uploads/dish_136_68e8dc40eb611.jpg', NULL, 1, 0, '2025-10-10 10:13:20'),
(179, 137, 'uploads/dish_137_68e8de7ba654b.jpg', NULL, 1, 0, '2025-10-10 10:22:51'),
(180, 138, 'uploads/dish_138_68e8df2e2f36b.jpeg', NULL, 1, 0, '2025-10-10 10:25:50'),
(181, 139, 'uploads/dish_139_68e8e01009f51.jpg', NULL, 1, 0, '2025-10-10 10:29:36'),
(182, 140, 'uploads/dish_140_68e8e08ade811.jpg', NULL, 1, 0, '2025-10-10 10:31:38'),
(183, 141, 'uploads/dish_141_68e8e13c65d35.jpg', NULL, 1, 0, '2025-10-10 10:34:36'),
(184, 142, 'uploads/dish_142_68e8e2bed1b4e.jpg', NULL, 1, 0, '2025-10-10 10:41:02'),
(185, 143, 'uploads/dish_143_68e8e32f14428.jpg', NULL, 1, 0, '2025-10-10 10:42:55'),
(186, 144, 'uploads/dish_144_68e8e39643ff6.jpg', NULL, 1, 0, '2025-10-10 10:44:38'),
(187, 145, 'uploads/dish_145_68e8e3f00deb2.jpg', NULL, 1, 0, '2025-10-10 10:46:08'),
(188, 146, 'uploads/dish_146_68e8e592e0a64.jpg', NULL, 1, 0, '2025-10-10 10:53:06'),
(189, 147, 'uploads/dish_147_68e8e6726b265.png', NULL, 1, 0, '2025-10-10 10:56:50'),
(190, 148, 'uploads/dish_148_68e8e8b029057.png', NULL, 1, 0, '2025-10-10 11:06:24'),
(191, 149, 'uploads/dish_149_68e8ec3dacfa4.jpeg', NULL, 1, 0, '2025-10-10 11:21:33'),
(192, 150, 'uploads/dish_150_68e8ec6e07c08.jpg', NULL, 1, 0, '2025-10-10 11:22:22'),
(193, 151, 'uploads/dish_151_68e8ecf51e60b.jpg', NULL, 1, 0, '2025-10-10 11:24:37'),
(194, 152, 'uploads/dish_152_68e8ef7073831.jpg', NULL, 1, 0, '2025-10-10 11:35:12'),
(195, 153, 'uploads/dish_153_68e8eff4124ac.jpg', NULL, 1, 0, '2025-10-10 11:37:24'),
(196, 154, 'uploads/dish_154_68ea06abbed8c.jpg', NULL, 1, 0, '2025-10-11 07:26:35'),
(197, 155, 'uploads/dish_155_68ead4fdaaf1b.jpg', NULL, 1, 0, '2025-10-11 22:06:53'),
(198, 156, 'uploads/dish_156_68ead59832009.jpeg', NULL, 1, 0, '2025-10-11 22:09:28'),
(199, 157, 'uploads/dish_157_68ead5f47d827.jpg', NULL, 1, 0, '2025-10-11 22:11:00'),
(200, 158, 'uploads/dish_158_68ead75686966.jpeg', NULL, 1, 0, '2025-10-11 22:16:54'),
(201, 159, 'uploads/dish_159_68eadb5fd87f2.jpeg', NULL, 1, 0, '2025-10-11 22:34:07'),
(202, 160, 'uploads/dish_160_68ed056f184d6.jpg', NULL, 1, 0, '2025-10-13 13:58:07'),
(203, 161, 'uploads/dish_161_68ed05f2b0b40.jpg', NULL, 1, 0, '2025-10-13 14:00:18'),
(204, 162, 'uploads/dish_162_68ed071e36c6d.jpg', NULL, 1, 0, '2025-10-13 14:05:18'),
(205, 163, 'uploads/dish_163_68ed071eac50a.jpg', NULL, 1, 0, '2025-10-13 14:05:18'),
(206, 164, 'uploads/dish_164_68ed07ad2c6e4.jpg', NULL, 1, 0, '2025-10-13 14:07:41'),
(207, 165, 'uploads/dish_165_68ed08dba9c29.jpg', NULL, 1, 0, '2025-10-13 14:12:43'),
(208, 166, 'uploads/dish_166_68ed0a7149e44.jpg', NULL, 1, 0, '2025-10-13 14:19:29'),
(209, 167, 'uploads/dish_167_68ed0acdbfe89.jpeg', NULL, 1, 0, '2025-10-13 14:21:01'),
(210, 168, 'uploads/dish_168_68ed0b35df02c.jpg', NULL, 1, 0, '2025-10-13 14:22:45'),
(211, 169, 'uploads/dish_169_68ed0c0216194.jpeg', NULL, 1, 0, '2025-10-13 14:26:10'),
(212, 170, 'uploads/dish_170_68ed0c7e0dd2e.jpeg', NULL, 1, 0, '2025-10-13 14:28:14'),
(213, 171, 'uploads/dish_171_68ed0ccb47cee.jpeg', NULL, 1, 0, '2025-10-13 14:29:31'),
(214, 172, 'uploads/dish_172_68ed0d1641a56.jpeg', NULL, 1, 0, '2025-10-13 14:30:46');

-- --------------------------------------------------------

--
-- Table structure for table `food_listings`
--

CREATE TABLE `food_listings` (
  `listing_id` int(11) NOT NULL,
  `dealer_id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL,
  `subcategory_id` int(11) DEFAULT NULL,
  `variant` varchar(100) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `country` varchar(100) DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `original_price` decimal(10,2) DEFAULT NULL,
  `preparation_time` int(11) DEFAULT NULL,
  `serves` int(11) DEFAULT NULL,
  `spice_level` enum('mild','medium','hot','very_hot') DEFAULT NULL,
  `cuisine_type` varchar(100) DEFAULT NULL,
  `dietary_info` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`dietary_info`)),
  `ingredients` text DEFAULT NULL,
  `nutrition_info` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`nutrition_info`)),
  `is_approved` tinyint(1) DEFAULT 0,
  `is_featured` tinyint(1) DEFAULT 0,
  `stock_quantity` int(11) DEFAULT 0,
  `views_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_daily_special` tinyint(1) DEFAULT 0,
  `has_video` tinyint(1) DEFAULT 0,
  `primary_video_id` int(11) DEFAULT NULL,
  `special_price` decimal(10,2) DEFAULT NULL,
  `special_end_date` date DEFAULT NULL,
  `country_id` int(11) DEFAULT NULL,
  `city_id` int(11) DEFAULT NULL,
  `cuisine_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `food_listings`
--

INSERT INTO `food_listings` (`listing_id`, `dealer_id`, `category_id`, `subcategory_id`, `variant`, `title`, `description`, `location`, `country`, `price`, `original_price`, `preparation_time`, `serves`, `spice_level`, `cuisine_type`, `dietary_info`, `ingredients`, `nutrition_info`, `is_approved`, `is_featured`, `stock_quantity`, `views_count`, `created_at`, `updated_at`, `is_daily_special`, `has_video`, `primary_video_id`, `special_price`, `special_end_date`, `country_id`, `city_id`, `cuisine_id`) VALUES
(34, 2, 2, 138, NULL, 'Beef Ribs', 'Prepared to perfection. 250 g', 'Cape Town', 'South Africa', 120.00, NULL, NULL, NULL, NULL, 'English', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 12:56:55', '2025-10-10 07:38:12', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(35, 2, 2, 140, NULL, 'Calamari', '120g', 'Cape Town', 'South Africa', 89.00, NULL, NULL, NULL, NULL, 'None', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 12:59:01', '2025-10-08 12:59:01', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(36, 2, 2, 140, NULL, 'Cheesy Garlic Prawn', 'Great Dish', 'Cape Town', 'South Africa', 120.00, NULL, NULL, NULL, NULL, 'None', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 13:00:29', '2025-10-10 07:36:53', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(38, 2, 2, 31, NULL, 'Chicken Strips', 'To perfection 125g', 'Cape Town', 'South Africa', 79.00, NULL, NULL, NULL, NULL, 'None', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 13:07:57', '2025-10-10 07:36:12', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(39, 2, 2, 139, NULL, 'Chicken Wings', 'Delightful  Basket', 'Cape Town', 'South Africa', 99.00, NULL, NULL, NULL, NULL, 'None', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 13:09:36', '2025-10-08 13:09:36', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(40, 2, 28, NULL, NULL, 'Chilli Bites', 'Its Hot', 'Cape Town', 'South Africa', 35.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 13:10:50', '2025-10-10 07:34:35', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(41, 2, 2, 31, NULL, 'Crumbed Mushroom', 'Delicious', 'Cape Town', 'South Africa', 69.00, NULL, NULL, NULL, NULL, 'None', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 13:12:22', '2025-10-08 13:12:22', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(42, 2, 1, 143, 'Meat', '2 Bunnys', 'Get 2', 'Cape Town', 'South Africa', 299.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 17:43:20', '2025-10-08 17:43:20', 1, 0, NULL, 289.00, '2025-11-30', NULL, NULL, NULL),
(43, 2, 31, NULL, NULL, 'Burger Combo', '3 Burgers with chips and coke,\r\n\r\nSit down only 4pm - 6pm', 'Cape Town', 'South Africa', 259.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 17:50:56', '2025-10-11 06:34:15', 1, 0, NULL, 229.00, '2025-11-30', NULL, NULL, NULL),
(44, 2, 26, 136, 'Cocktails', 'Cocktails Thursday', '2 Ice Tea, 2 Sex on the Lake, 2 Ginbull 2 Cosmopolitian', 'Cape Town', 'South Africa', 510.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 17:54:04', '2025-10-08 17:54:04', 1, 0, NULL, 510.00, '2025-11-30', NULL, NULL, NULL),
(45, 2, 1, 2, NULL, 'Chicken Schnitzel & Chips', '4pm - 7pm\r\n1 for R70\r\n2 for R120', 'Cape Town', 'South Africa', 70.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 18:06:43', '2025-10-08 18:06:43', 1, 0, NULL, 70.00, '2025-11-30', NULL, NULL, NULL),
(46, 2, 1, 4, NULL, 'Steak Special', 'for 2 with 2 Glasses of Red Wine', 'Cape Town', 'South Africa', 389.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 18:26:03', '2025-10-08 19:05:09', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(47, 2, 1, 4, NULL, 'Steaks with Chips', '2 Steaks 250g with Chips / Salad & Complementary Bottle of Spoer 1962', 'Cape Town', 'South Africa', 499.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 18:58:26', '2025-10-08 18:58:26', 1, 0, NULL, 499.00, '2025-10-30', NULL, NULL, NULL),
(48, 2, 28, 31, NULL, 'Samosa', '3 Lamb mince/ Chicken', 'Cape Town', 'South Africa', 39.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 19:14:53', '2025-10-10 06:43:56', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(49, 2, 28, 31, NULL, 'Samosa', '3 Corn/ Potato/ Fish', 'Cape Town', 'South Africa', 35.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 19:17:15', '2025-10-10 06:42:33', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(50, 2, 28, 4, NULL, 'Beef Ribs', '100% Beef. 0% Compromise', 'Cape Town', 'South Africa', 120.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 19:21:39', '2025-10-10 06:41:58', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(51, 2, 28, 31, NULL, 'Jalapeno Peppers', 'Turn Up the Heat!', 'Cape Town', 'South Africa', 79.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 19:23:18', '2025-10-10 06:41:25', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(52, 2, 28, 139, NULL, 'Peri Peri Chicken Livers', 'Spice That Bites Back!', 'Cape Town', 'South Africa', 89.00, NULL, NULL, NULL, NULL, 'Portuguese', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 19:24:54', '2025-10-10 06:40:52', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(53, 2, 28, 141, NULL, 'Grilled Chicken Salad', 'Where Fresh Greens Meet Juicy Chicken', 'Cape Town', 'South Africa', 149.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 19:34:33', '2025-10-10 06:40:13', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(54, 2, 1, 2, NULL, 'Chicken Curry', 'Light, Flavorful, and Simply Irresistible.\r\nMed  159  Large  185', 'Cape Town', 'South Africa', 139.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:09:51', '2025-10-08 20:12:16', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(55, 2, 1, 2, NULL, 'Lamb Curry', 'For every Tastebud\r\nMed    R159\r\nLarge  R169', 'Cape Town', 'South Africa', 159.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:11:51', '2025-10-08 20:11:51', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(56, 2, 1, 3, NULL, 'Prawn Curry', 'Freshness You Can Taste in Every Bite.', 'Cape Town', 'South Africa', 199.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:14:04', '2025-10-08 20:14:04', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(57, 2, 1, 2, NULL, 'Butter Chicken Curry', 'Freshness You Can Taste in Every Bite.', 'Cape Town', 'South Africa', 159.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:16:06', '2025-10-08 20:16:06', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(58, 2, 1, 4, NULL, 'Kebab Curry', 'Freshness You Can Taste in Every Bite.', 'Cape Town', 'South Africa', 139.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:17:30', '2025-10-08 20:17:30', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(59, 2, 1, 4, NULL, 'Roti Roll Lamb', 'Elegant, Simple, and Full of Flavor', 'Cape Town', 'South Africa', 119.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:21:33', '2025-10-08 20:21:33', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(60, 2, 1, 2, NULL, 'Roti Roll Chicken', 'Elegant, Simple, and Full of Flavor', 'Cape Town', 'South Africa', 95.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:22:57', '2025-10-08 20:22:57', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(61, 2, 1, 1, NULL, 'Roti Roll Beans', 'Elegant, Simple, and Full of Flavor', 'Cape Town', 'South Africa', 79.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:24:08', '2025-10-08 20:24:08', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(62, 2, 1, 4, NULL, 'Lamb Bunny', 'Real Durban Flavor — One Bite at a Time', 'Cape Town', 'South Africa', 125.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:29:19', '2025-10-08 20:29:19', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(63, 2, 1, 4, NULL, 'Lamb Bunny Half', 'Real Durban Flavor — One Bite at a Time', 'Cape Town', 'South Africa', 195.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:30:55', '2025-10-08 20:30:55', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(64, 2, 1, 2, NULL, 'Chicken Bunny Quarter', 'Real Durban Flavor — One Bite at a Time', 'Cape Town', 'South Africa', 110.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:32:53', '2025-10-08 20:32:53', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(65, 2, 1, 2, NULL, 'Chicken Bunny Half', 'Real Durban Flavor — One Bite at a Time', 'Cape Town', 'South Africa', 159.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:33:51', '2025-10-08 20:33:51', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(66, 2, 1, 2, NULL, 'Espatado Chicken', 'A Taste of Portugal in Every Bite.', 'Cape Town', 'South Africa', 119.00, NULL, NULL, NULL, NULL, 'Portuguese', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:36:47', '2025-10-08 20:36:47', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(67, 2, 1, 4, NULL, 'Espatado Beef', 'Savor the Soul of Portuguese Cooking', 'Cape Town', 'South Africa', 159.00, NULL, NULL, NULL, NULL, 'Portuguese', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:52:56', '2025-10-08 20:52:56', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(68, 2, 1, 4, NULL, 'Steak Egg & Chips', 'From Lisbon to Your Plate', 'Cape Town', 'South Africa', 189.00, NULL, NULL, NULL, NULL, 'Portuguese', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:54:27', '2025-10-08 20:54:27', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(69, 2, 1, 4, NULL, 'Trinchado Beef', 'Savor the Soul of Portuguese Cooking', 'Cape Town', 'South Africa', 129.00, NULL, NULL, NULL, NULL, 'Portuguese', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 20:56:03', '2025-10-08 20:56:03', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(70, 2, 1, 4, NULL, 'Sirloin', 'Grilled to Perfection. Savored with Passion', 'Cape Town', 'South Africa', 159.00, NULL, NULL, NULL, NULL, 'English', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 21:05:26', '2025-10-08 21:05:26', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(71, 2, 1, 4, NULL, 'Rump', 'Where Juicy Meets Legendary', 'Cape Town', 'South Africa', 149.00, NULL, NULL, NULL, NULL, 'English', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 21:06:59', '2025-10-08 21:06:59', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(72, 2, 1, 4, NULL, 'Beef Fillet', 'The Steak You’ve Been Waiting For', 'Cape Town', 'South Africa', 179.00, NULL, NULL, NULL, NULL, 'English', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-08 21:11:37', '2025-10-08 21:11:37', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(74, 2, 1, 4, NULL, 'Ribs 500g', 'Delectable', 'Cape Town', 'South Africa', 269.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 07:55:02', '2025-10-10 07:55:02', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(75, 2, 1, 4, NULL, 'Chops and Chicken', '3 Chops with Quarter Chicken', 'Cape Town', 'South Africa', 189.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 07:56:21', '2025-10-10 07:56:21', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(76, 2, 1, 4, NULL, 'Cjops and Chips', '6 chops 300g and Chips', 'Cape Town', 'South Africa', 239.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 07:57:45', '2025-10-10 07:57:45', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(77, 2, 24, 105, 'Platter for 1', 'Platter for 1', '1 Boerwor, 1 Chop, 1 Steak and 1 Chicken piece', 'Cape Town', 'South Africa', 239.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:00:17', '2025-10-10 08:00:17', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(78, 2, 24, 105, 'Platter for 2', 'Platter for 2 Meat', '2 Boerwors, 4 Chops, 4 Steak and 4 Chicken Pieces', 'Cape Town', 'South Africa', 529.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:01:45', '2025-10-10 08:01:45', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(79, 2, 24, 105, 'Platter for 4', 'Platter for 4 Meat', '4 Boerwors, 4 Chops, 4 Steak and 4 Chicken Pieces', 'Cape Town', 'South Africa', 699.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:03:17', '2025-10-10 08:03:17', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(80, 2, 1, 3, NULL, 'Hake and Chips', 'Hake with Chips', 'Cape Town', 'South Africa', 109.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:08:20', '2025-10-10 08:08:20', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(81, 2, 1, 3, NULL, 'Line Fish and Chips', 'From the deep ocean', 'Cape Town', 'South Africa', 139.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:14:03', '2025-10-10 08:14:03', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(82, 2, 1, 3, NULL, 'Salmon and Chips', '200 G', 'Cape Town', 'South Africa', 299.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:17:35', '2025-10-10 08:17:35', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(83, 2, 1, 4, NULL, 'Prawns Ribs Chips', '5 Prawns Ribs 250g and Chips', 'Cape Town', 'South Africa', 219.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:25:15', '2025-10-10 08:25:15', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(84, 2, 1, 3, NULL, 'Prawns Combo', '6 Prawns Muscles and Chips', 'Cape Town', 'South Africa', 170.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:30:20', '2025-10-11 21:58:45', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(85, 2, 24, 106, 'Platter for 1', 'Seafood Platter for 1', '5 Prawns Calamari Hake and 5 Mussels', 'Cape Town', 'South Africa', 235.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:35:21', '2025-10-10 08:35:21', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(86, 2, 24, 106, 'Platter for 2', 'Seafood Platter for 2', '12 Prawns, Calamari, Hake, 6 Mussels', 'Cape Town', 'South Africa', 489.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:39:21', '2025-10-10 08:39:21', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(87, 2, 1, 2, NULL, 'Chicken and Chips', 'Quarter chicken and chips', 'Cape Town', 'South Africa', 89.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:42:56', '2025-10-10 08:42:56', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(88, 2, 1, 2, NULL, 'Half Chicken and Chips', 'half chicken and chips', 'Cape Town', 'South Africa', 149.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:43:59', '2025-10-10 08:43:59', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(89, 2, 1, 2, NULL, 'Chicken Schnitzel', 'Chicken', 'Cape Town', 'South Africa', 120.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:45:00', '2025-10-10 08:45:00', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(90, 2, 1, 1, NULL, 'Broad Bean', 'Curry served with rice', 'Cape Town', 'South Africa', 79.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:47:14', '2025-10-10 08:47:14', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(91, 2, 1, 143, 'Vegetarian/Vegan', 'Quarter Broad Beans Bunny', 'Durban Style', 'Cape Town', 'South Africa', 85.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:48:58', '2025-10-10 08:48:58', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(92, 2, 1, 1, NULL, 'Curry and Roti', 'Mixed Veg with Roti', 'Cape Town', 'South Africa', 79.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:51:55', '2025-10-10 08:51:55', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(93, 2, 1, 1, NULL, 'Potato Curry', 'Served with rice', 'Cape Town', 'South Africa', 75.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:56:18', '2025-10-10 08:56:18', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(94, 2, 1, 1, NULL, 'Green Beans', 'Curry served with rice', 'Cape Town', 'South Africa', 75.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:57:03', '2025-10-10 08:57:03', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(95, 2, 1, 1, NULL, 'Cabbage', 'Curry served with rice', 'Cape Town', 'South Africa', 69.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:57:53', '2025-10-10 08:57:53', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(96, 2, 1, 1, NULL, 'Dhall', 'Curry served with rice', 'Cape Town', 'South Africa', 79.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:58:33', '2025-10-10 08:58:33', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(97, 2, 1, 1, NULL, 'Curry of Day', 'Curry served with rice', 'Cape Town', 'South Africa', 79.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 08:59:20', '2025-10-10 08:59:20', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(98, 2, 1, 97, NULL, 'Beef Burger', 'Delicious', 'Cape Town', 'South Africa', 119.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:01:58', '2025-10-10 09:01:58', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(99, 2, 1, 97, NULL, 'Chicken Burger', 'Sumptious', 'Cape Town', 'South Africa', 109.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:03:07', '2025-10-10 09:03:07', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(100, 2, 1, 97, NULL, 'Lamb Coconut Grove Burger', 'Durban Style Coconut Grove', 'Cape Town', 'South Africa', 129.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:04:37', '2025-10-10 09:04:37', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(101, 2, 3, 28, NULL, 'Brownie Ice Cream', 'Great Finish', 'Cape Town', 'South Africa', 69.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:07:16', '2025-10-10 09:07:16', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(102, 2, 3, 69, NULL, 'Soji', 'Classi Indian', 'Cape Town', 'South Africa', 45.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:08:05', '2025-10-10 09:08:05', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(103, 2, 3, 69, NULL, 'Vermicilli', 'Indian Delacacy', 'Cape Town', 'South Africa', 45.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:09:03', '2025-10-10 09:09:03', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(104, 2, 3, 28, NULL, 'Ice Cream and Choc Sauce', 'Ice cream and Chocolate Sauce', 'Cape Town', 'South Africa', 49.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:10:05', '2025-10-10 09:10:05', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(105, 2, 30, 151, NULL, 'Roti', 'Roti Local', 'Cape Town', 'South Africa', 18.00, NULL, NULL, NULL, NULL, 'Indian', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:11:30', '2025-10-10 09:11:30', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(106, 2, 30, 152, NULL, 'Chillies', 'Chopped', 'Cape Town', 'South Africa', 15.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:30:14', '2025-10-10 09:30:14', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(107, 2, 30, 153, NULL, 'Avo', 'Add on', 'Cape Town', 'South Africa', 25.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:32:42', '2025-10-10 09:32:42', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(108, 2, 30, 154, NULL, 'Chips', 'add on', 'Cape Town', 'South Africa', 35.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:33:38', '2025-10-10 09:33:38', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(109, 2, 30, 155, NULL, 'Mushroom Sauce', 'add on', 'Cape Town', 'South Africa', 29.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:35:00', '2025-10-10 09:35:00', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(110, 2, 30, 156, NULL, 'Pepper Sauce', 'Pepper add on', 'Cape Town', 'South Africa', 29.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:36:16', '2025-10-10 09:36:16', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(111, 2, 30, 157, NULL, 'Egg', 'add on', 'Cape Town', '', 29.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:37:15', '2025-10-10 09:37:15', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(112, 2, 30, 158, NULL, 'Cheese', 'Slice', 'Cape Town', 'South Africa', 15.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:37:50', '2025-10-10 09:37:50', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(113, 2, 30, 159, NULL, 'Rice', 'Bowl', 'Cape Town', 'South Africa', 29.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:39:03', '2025-10-10 09:39:03', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(115, 2, 30, 160, NULL, 'Salad', 'green add on', 'Cape Town', 'South Africa', 69.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:43:12', '2025-10-10 09:43:12', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(116, 2, 26, 144, 'Carbonated Drinks', 'Soft Carbonated', 'Cold drinks Cans', 'Cape Town', 'South Africa', 29.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:44:10', '2025-10-10 09:44:10', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(117, 2, 26, 132, 'Still & Spring', 'Valpre Still', 'still', 'Cape Town', 'South Africa', 25.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:45:07', '2025-10-10 09:45:07', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(118, 2, 26, 132, 'Sparkling & Flavoured', 'Valpre Sparkling', 'water', 'Cape Town', 'South Africa', 28.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:46:02', '2025-10-10 09:46:02', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(119, 2, 26, 137, NULL, 'Monster', 'boost yourself', 'Cape Town', 'South Africa', 38.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:46:50', '2025-10-10 09:46:50', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(120, 2, 26, 137, NULL, 'Red Bull', 'energy', 'Cape Town', 'South Africa', 38.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:50:06', '2025-10-10 09:50:06', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(121, 2, 26, 137, NULL, 'Grapetiser', 'tastebud', 'Cape Town', 'South Africa', 38.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:51:32', '2025-10-10 09:51:32', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(122, 2, 26, 146, NULL, 'Appletiser', 'refreshing', 'Cape Town', 'South Africa', 38.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:52:31', '2025-10-10 09:52:31', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(123, 2, 26, 144, 'Carbonated Drinks', 'Schweppes', 'chill', 'Cape Town', 'South Africa', 28.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:54:17', '2025-10-10 09:54:17', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(124, 2, 26, 146, NULL, 'Schweppes Pink', 'Tonic', 'Cape Town', 'South Africa', 28.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:55:14', '2025-10-10 09:55:14', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(125, 2, 26, 146, NULL, 'Steel Works', 'Refreshing', 'Cape Town', 'South Africa', 49.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 09:58:47', '2025-10-10 09:58:47', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(126, 2, 26, 146, NULL, 'Ice Tea', 'Chill', 'Cape Town', 'South Africa', 35.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:00:09', '2025-10-10 10:00:09', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(127, 2, 26, 146, NULL, 'Passion Fruit', 'Chill', 'Cape Town', 'South Africa', 16.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:01:01', '2025-10-10 10:01:01', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(128, 2, 26, 146, NULL, 'Cranberry', 'refreshing', 'Cape Town', 'South Africa', 29.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:01:52', '2025-10-10 10:01:52', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(129, 2, 26, 146, NULL, 'Fruit Cocktail', 'Chill', 'Cape Town', 'South Africa', 29.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:02:43', '2025-10-10 10:02:43', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(130, 2, 26, 146, NULL, 'Orange Juice', 'Fresh', 'Cape Town', 'South Africa', 29.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:03:54', '2025-10-10 10:03:54', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(131, 2, 26, 146, NULL, 'Mango Juice', 'Refreshing', 'Cape Town', '', 29.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:04:37', '2025-10-10 10:04:37', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(132, 2, 26, 136, 'Beers & Ciders', 'Carling Black Label', 'Refreshingly Cold', 'Cape Town', 'South Africa', 33.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:08:30', '2025-10-10 10:08:30', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(133, 2, 26, 136, 'Beers & Ciders', 'Castle', 'Refreshingly Cold', 'Cape Town', 'South Africa', 33.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:09:17', '2025-10-10 10:09:17', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(134, 2, 26, 136, 'Beers & Ciders', 'Castle Lite', 'Refreshingly Cold', 'Cape Town', 'South Africa', 39.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:10:18', '2025-10-10 10:10:18', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(135, 2, 26, 136, 'Beers & Ciders', 'Stella Artois', 'Refreshingly Cold', 'Cape Town', 'South Africa', 39.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:11:53', '2025-10-10 10:11:53', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(136, 2, 26, 136, 'Beers & Ciders', 'Corona', 'Refreshingly Cold', 'Cape Town', 'South Africa', 40.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:13:20', '2025-10-10 10:13:20', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(137, 2, 26, 136, 'Beers & Ciders', 'Windhoel Draught', 'Refreshingly Cold', 'Cape Town', 'South Africa', 45.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:22:51', '2025-10-10 10:22:51', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(138, 2, 26, 136, 'Beers & Ciders', 'Windhoel Draught', 'Refreshingly Cold', 'Cape Town', '', 45.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:25:50', '2025-10-10 10:25:50', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(139, 2, 26, 136, 'Beers & Ciders', 'Heiniken Silver', 'Refreshingly Cold', 'Cape Town', 'South Africa', 35.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:29:36', '2025-10-10 10:29:36', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(140, 2, 26, 136, 'Beers & Ciders', 'Heineken', 'Refreshingly Cold', 'Cape Town', 'South Africa', 35.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:31:38', '2025-10-10 10:31:38', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(141, 2, 26, 136, 'Beers & Ciders', 'Heineken Alcho Free', 'Refreshingly Cold', 'Cape Town', 'South Africa', 35.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:34:36', '2025-10-10 10:34:36', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(142, 2, 26, 136, 'Beers & Ciders', 'Brutal Fruit', 'Strawberry', 'Cape Town', 'South Africa', 35.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:41:02', '2025-10-10 10:41:02', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(143, 2, 26, 136, 'Beers & Ciders', 'Brutal Fruit Litchi', 'Refreshingly Cold', 'Cape Town', 'South Africa', 38.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:42:55', '2025-10-10 10:42:55', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(144, 2, 26, 136, 'Beers & Ciders', 'Brutal Fruit Apple', 'Refreshingly Cold', 'Cape Town', 'South Africa', 38.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:44:38', '2025-10-10 10:44:38', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(145, 2, 26, 136, 'Beers & Ciders', 'Smirnoff Vodka', 'Refreshingly Cold', 'Cape Town', 'South Africa', 39.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:46:08', '2025-10-10 10:46:08', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(146, 2, 26, 136, 'Beers & Ciders', 'Smirnoff Vodka', 'Refreshingly Cold', 'Cape Town', 'South Africa', 39.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:53:06', '2025-10-10 10:53:06', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(147, 2, 26, 136, 'Beers & Ciders', 'Rekorderlig', 'Refreshingly Cold', 'Cape Town', 'South Africa', 59.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 10:56:50', '2025-10-10 10:56:50', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(148, 2, 26, 136, 'Beers & Ciders', 'Belgravia', 'Refreshingly Cold', 'Cape Town', 'South Africa', 38.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 11:06:24', '2025-10-10 11:06:24', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(149, 2, 26, 136, 'Beers & Ciders', 'Jack Daniel & Coke', 'Refreshingly Cold', 'Cape Town', 'South Africa', 40.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 11:21:33', '2025-10-10 11:21:33', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(150, 2, 26, 136, 'Beers & Ciders', 'Flying Fish', 'Refreshingly Cold', 'Cape Town', 'South Africa', 30.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 11:22:22', '2025-10-10 11:22:22', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(151, 2, 26, 136, 'Beers & Ciders', 'Savana Dry', 'Refreshingly Cold', 'Cape Town', 'South Africa', 39.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 11:24:37', '2025-10-10 11:24:37', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(152, 2, 26, 136, 'Beers & Ciders', 'Savana Neat', 'Refreshingly Cold', 'Cape Town', 'South Africa', 39.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 11:35:12', '2025-10-10 11:35:12', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(153, 2, 26, 136, 'Beers & Ciders', 'Savana Alcohol Free', 'Refreshingly Cold', 'Cape Town', 'South Africa', 30.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-10 11:37:24', '2025-10-10 11:37:24', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(154, 2, 32, 164, NULL, 'Double Burgers', 'Three Burgers  Three 200m Cold drinks and chips', 'Cape Town', 'South Africa', 259.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-11 07:26:35', '2025-10-19 06:02:11', 1, 0, NULL, 4.00, '2025-10-22', NULL, NULL, NULL),
(155, 2, 26, 136, 'Cognac', 'Remi Martin XO', 'Taste the moment', 'Cape Town', 'South Africa', 135.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-11 22:06:53', '2025-10-11 22:06:53', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(156, 2, 26, 136, 'Cognac', 'Remi Martin VSOP  Tot', 'Taste the moment', 'Cape Town', 'South Africa', 75.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-11 22:09:28', '2025-10-19 08:01:43', 1, 0, NULL, 30.00, '2025-10-22', NULL, NULL, NULL),
(157, 2, 26, 136, 'Cognac', 'Remi Martin 1738  Tot', 'Taste the moment', '', 'South Africa', 95.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-11 22:11:00', '2025-10-11 22:11:00', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(158, 2, 26, 136, 'Cognac', 'Louis V111  10 ml', 'Cheers to the good life', 'Cape Town', 'South Africa', 1850.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-11 22:16:54', '2025-10-11 22:16:54', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(159, 2, 26, 136, 'Cognac', 'Louis V111  25 ml', 'Cheers to the good life', 'Cape Town', 'South Africa', 3500.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-11 22:34:07', '2025-10-11 22:34:07', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(160, 2, 32, 162, NULL, 'Meaty Meal for 2', '2 Wors,2 Chops, 2 Steaks and 2 P Chicken', 'Cape Town', 'South Africa', 529.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 13:58:07', '2025-10-13 13:58:07', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(161, 2, 32, 162, NULL, 'Meaty Platter for 4', '4 Wors, 4 Chops, 4 Steaks and 4 P Chicken', 'Cape Town', 'South Africa', 699.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:00:18', '2025-10-13 14:00:18', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(162, 2, 32, 162, NULL, 'Platter for 2', 'From the Ocean:12 Prawns, Calamari 300, Hake 200g, 6 Mussels', 'Cape Town', 'South Africa', 489.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:05:18', '2025-10-13 14:05:18', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(163, 2, 32, 162, NULL, 'Platter for 2', 'From the Ocean:12 Prawns, Calamari 300, Hake 200g, 6 Mussels', 'Cape Town', 'South Africa', 489.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:05:18', '2025-10-13 14:05:18', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(164, 2, 32, 162, NULL, 'Prawn Ribs', '6 Prawns, Ribs 250g, and Chips', 'Cape Town', 'South Africa', 219.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:07:41', '2025-10-13 14:07:41', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(165, 2, 8, 165, NULL, 'Hake & Rice', 'Fresh Hake with Rice to start your day', 'Cape Town', 'South Africa', 99.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:12:43', '2025-10-13 14:13:17', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(166, 2, 8, 165, NULL, 'Hake & Chips', 'Hake and Chips', 'Cape Town', 'South Africa', 99.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:19:29', '2025-10-13 14:19:29', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(167, 2, 8, 165, NULL, 'Line Fish', 'From the Ocean Served with Chips', 'Cape Town', 'South Africa', 139.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:21:01', '2025-10-13 14:21:01', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(168, 2, 8, 165, NULL, 'Salmon', 'Salmon served with Chips', 'Cape Town', 'South Africa', 299.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:22:45', '2025-10-13 14:22:45', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(169, 2, 8, 166, NULL, 'Beef Burger', 'Beef Burger', 'Cape Town', 'South Africa', 119.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:26:10', '2025-10-13 14:26:52', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(170, 2, 8, 166, NULL, 'Chicen Burger', 'Chicken Burger', 'Cape Town', 'South Africa', 109.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:28:14', '2025-10-13 14:28:14', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(171, 2, 8, 166, NULL, 'Coconut Grove', 'Lamb Burger', 'Cape Town', 'South Africa', 129.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:29:31', '2025-10-13 14:29:31', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL),
(172, 2, 8, 166, NULL, 'Veggy Burger', 'Vegetarian Burger', 'Cape Town', 'South Africa', 79.00, NULL, NULL, NULL, NULL, 'Local', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-13 14:30:46', '2025-10-13 14:30:46', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `food_subcategories`
--

CREATE TABLE `food_subcategories` (
  `subcategory_id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `food_subcategories`
--

INSERT INTO `food_subcategories` (`subcategory_id`, `category_id`, `name`, `description`, `is_active`, `created_at`) VALUES
(1, 1, 'Vegetarian Dishes', NULL, 1, '2025-08-02 13:24:37'),
(2, 1, 'Poultry Dishes', NULL, 1, '2025-08-02 13:24:37'),
(3, 1, 'Seafood & Sushi', NULL, 1, '2025-08-02 13:24:37'),
(4, 1, 'Meat Dishes', NULL, 1, '2025-08-02 13:24:37'),
(26, 3, 'Cakes & Gateaux', NULL, 1, '2025-09-19 07:46:00'),
(27, 3, 'Pudding & Warm', NULL, 1, '2025-09-19 07:46:00'),
(28, 3, 'Ice Creams & Frozen Treats', NULL, 1, '2025-09-19 07:46:00'),
(29, 3, 'Platters & Combos', NULL, 1, '2025-09-19 07:46:00'),
(31, 2, 'Side Dishes', NULL, 1, '2025-09-19 07:53:02'),
(32, 2, 'Soups', NULL, 1, '2025-09-19 07:53:02'),
(34, 2, 'Burgers', NULL, 1, '2025-09-19 07:53:02'),
(35, 2, 'Pastas', NULL, 1, '2025-09-19 07:53:02'),
(36, 2, 'Grill ? BBQ', NULL, 1, '2025-09-19 07:53:02'),
(37, 2, 'Rice Dishes', NULL, 1, '2025-09-19 07:54:47'),
(39, 2, 'Sushi', NULL, 1, '2025-09-19 07:54:48'),
(41, 3, 'Pastries & Tarts', NULL, 1, '2025-09-19 08:05:06'),
(44, 16, 'Vegetarain', NULL, 1, '2025-09-19 08:12:08'),
(45, 16, 'Vegain', NULL, 1, '2025-09-19 08:12:08'),
(46, 16, 'Halal', NULL, 1, '2025-09-19 08:12:08'),
(47, 16, 'Gluten-free', NULL, 1, '2025-09-19 08:12:08'),
(48, 16, 'Keto', NULL, 1, '2025-09-19 08:12:08'),
(49, 16, 'Low-Carb', NULL, 1, '2025-09-19 08:12:08'),
(58, 8, 'Classic/Traditional', NULL, 1, '2025-10-07 21:10:49'),
(59, 8, 'Egg dishes', NULL, 1, '2025-10-07 21:10:49'),
(60, 8, 'Healthy & Light', NULL, 1, '2025-10-07 21:10:49'),
(61, 8, 'Bakery & Pastry', NULL, 1, '2025-10-07 21:10:49'),
(62, 8, 'Pancakes & Waffles', NULL, 1, '2025-10-07 21:10:49'),
(63, 8, 'Sandwiches & Wraps', NULL, 1, '2025-10-07 21:10:49'),
(64, 8, 'Local & Specialty', NULL, 1, '2025-10-07 21:10:49'),
(65, 3, 'Custard, Mousses & Creamy', NULL, 1, '2025-10-07 21:16:10'),
(66, 3, 'Fruit Based', NULL, 1, '2025-10-07 21:16:10'),
(67, 16, 'Kosher', NULL, 1, '2025-10-07 21:42:55'),
(68, 16, 'Organic - Healthy', NULL, 1, '2025-10-07 21:42:55'),
(69, 3, 'Local Dessert', NULL, 1, '2025-10-07 21:44:16'),
(94, 1, 'Vegan Dishes', NULL, 1, '2025-10-07 22:12:28'),
(95, 1, 'Pizza, Pasta & Noodles', NULL, 1, '2025-10-07 22:12:28'),
(96, 1, 'Rice & Curry Dishes', NULL, 1, '2025-10-07 22:12:28'),
(97, 1, 'Burgers, Steaks & Grills', NULL, 1, '2025-10-07 22:12:28'),
(98, 1, 'International Cuisine', NULL, 1, '2025-10-07 22:12:28'),
(99, 1, 'Specialty / Signature Dishes', NULL, 1, '2025-10-07 22:12:28'),
(100, 1, 'Combo Meals', NULL, 1, '2025-10-07 22:12:28'),
(101, 1, 'Sides (Optional Add-ons)', NULL, 1, '2025-10-07 22:12:28'),
(102, 1, 'Portuguese', NULL, 1, '2025-10-07 22:12:28'),
(105, 24, 'Meat Platters', NULL, 1, '2025-10-07 22:34:10'),
(106, 24, 'Seafood Platters', NULL, 1, '2025-10-07 22:35:27'),
(107, 24, 'Vegetarian/ Vegan', NULL, 1, '2025-10-07 22:39:44'),
(108, 24, 'Snack/ Appetizers', NULL, 1, '2025-10-07 22:39:44'),
(109, 24, 'Breakfast/ Brunch Platters', NULL, 1, '2025-10-07 22:39:44'),
(110, 24, 'Family Sharing Platters', NULL, 1, '2025-10-07 22:39:44'),
(111, 12, 'Finger Foods', NULL, 1, '2025-10-07 22:44:53'),
(112, 12, 'Quick Bites', NULL, 1, '2025-10-07 22:44:53'),
(113, 12, 'Salads & Light Bowls', NULL, 1, '2025-10-07 22:44:53'),
(114, 12, 'Chips & Sides', NULL, 1, '2025-10-07 22:44:53'),
(115, 12, 'Healthy & Vegetarian Snacks', NULL, 1, '2025-10-07 22:44:53'),
(116, 12, 'Kids Snacks', NULL, 1, '2025-10-07 22:44:53'),
(117, 12, 'Signature House Specials', NULL, 1, '2025-10-07 22:44:53'),
(118, 13, 'Burgers & Sandwiches', NULL, 1, '2025-10-07 23:03:16'),
(119, 13, 'Wraps & Rolls', NULL, 1, '2025-10-07 23:03:16'),
(120, 13, 'Fried & Crispy Snacks', NULL, 1, '2025-10-07 23:03:16'),
(121, 13, 'Pizza & Flatbreads', NULL, 1, '2025-10-07 23:03:16'),
(122, 13, 'Tacos, Buritis & Quesadillas', NULL, 1, '2025-10-07 23:03:16'),
(123, 13, 'Bunny Chows', NULL, 1, '2025-10-07 23:03:16'),
(126, 26, 'Hot Drinks', NULL, 1, '2025-10-08 10:18:45'),
(129, 26, 'Specialty & Flavored Lattes', NULL, 1, '2025-10-08 10:18:45'),
(132, 26, 'Water', NULL, 1, '2025-10-08 10:18:45'),
(136, 26, 'Bar', NULL, 1, '2025-10-08 10:18:45'),
(137, 26, 'Energy & Health Drinks', NULL, 1, '2025-10-08 10:20:26'),
(138, 2, 'Beef', NULL, 1, '2025-10-08 12:54:22'),
(139, 2, 'Chicken', NULL, 1, '2025-10-08 12:54:22'),
(140, 2, 'Seafood', NULL, 1, '2025-10-08 12:54:22'),
(141, 2, 'Salads', NULL, 1, '2025-10-08 12:54:22'),
(142, 2, 'Chicken Strips Salad', NULL, 1, '2025-10-08 13:04:25'),
(143, 1, 'Bunnys', NULL, 1, '2025-10-08 17:40:16'),
(144, 26, 'Cold Drinks', NULL, 1, '2025-10-09 16:09:19'),
(145, 26, 'Hot Chocolate & Cocoa Drinks', NULL, 1, '2025-10-10 04:08:53'),
(146, 26, 'Juices & Fruit Drinks', NULL, 1, '2025-10-10 04:08:53'),
(147, 26, 'Mocktails (Non-Alcoholic Cocktails)', NULL, 1, '2025-10-10 04:08:53'),
(148, 26, 'Signature Hot Drinks', NULL, 1, '2025-10-10 04:08:53'),
(149, 26, 'Smoothies & Shakes', NULL, 1, '2025-10-10 04:08:53'),
(150, 26, 'Warm Milk & Non-Coffee Drinks', NULL, 1, '2025-10-10 04:08:53'),
(151, 30, 'Roti', NULL, 1, '2025-10-10 09:11:30'),
(152, 30, 'Chillies', NULL, 1, '2025-10-10 09:30:14'),
(153, 30, 'Avo', NULL, 1, '2025-10-10 09:32:42'),
(154, 30, 'Chips', NULL, 1, '2025-10-10 09:33:38'),
(155, 30, 'Mushroom Sauce', NULL, 1, '2025-10-10 09:35:00'),
(156, 30, 'Pepper Sauce', NULL, 1, '2025-10-10 09:36:16'),
(157, 30, 'Egg', NULL, 1, '2025-10-10 09:37:15'),
(158, 30, 'Cheese', NULL, 1, '2025-10-10 09:37:50'),
(159, 30, 'Rice', NULL, 1, '2025-10-10 09:39:03'),
(160, 30, 'Salad', NULL, 1, '2025-10-10 09:40:22'),
(161, 26, 'Steel Works', NULL, 1, '2025-10-10 09:57:11'),
(162, 32, 'Combos', NULL, 1, '2025-10-11 07:20:45'),
(163, 32, 'Platters', NULL, 1, '2025-10-11 07:20:45'),
(164, 32, 'Burger', NULL, 1, '2025-10-11 07:20:45'),
(165, 8, 'Something Fishy', NULL, 1, '2025-10-13 14:11:48'),
(166, 8, 'Burgers & Sandwiches', NULL, 1, '2025-10-13 14:25:38');

-- --------------------------------------------------------

--
-- Table structure for table `food_variants`
--

CREATE TABLE `food_variants` (
  `variant_id` int(11) NOT NULL,
  `subcategory_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `food_variants`
--

INSERT INTO `food_variants` (`variant_id`, `subcategory_id`, `name`, `created_at`) VALUES
(47, 105, 'Platter for 1', '2025-10-08 00:35:27'),
(48, 105, 'Platter for 2', '2025-10-08 00:35:27'),
(49, 105, 'Platter for 3', '2025-10-08 00:35:27'),
(50, 105, 'Platter for 4', '2025-10-08 00:35:27'),
(51, 105, 'Family Platters', '2025-10-08 00:39:44'),
(52, 106, 'Platter for 1', '2025-10-08 00:39:44'),
(53, 106, 'Platter for 2', '2025-10-08 00:39:44'),
(54, 106, 'Platter for 3', '2025-10-08 00:39:44'),
(55, 106, 'Platter for 4', '2025-10-08 00:39:44'),
(56, 106, 'Family Platters', '2025-10-08 00:39:44'),
(57, 136, 'Beers & Ciders', '2025-10-08 12:20:26'),
(58, 136, 'Wines', '2025-10-08 12:20:26'),
(59, 136, 'Cognac', '2025-10-08 12:22:53'),
(60, 136, 'Whiskey', '2025-10-08 12:22:53'),
(61, 136, 'Brandy', '2025-10-08 12:22:53'),
(62, 136, 'Bourbon', '2025-10-08 12:22:53'),
(63, 136, 'Vodka', '2025-10-08 12:22:53'),
(64, 136, 'Tequila', '2025-10-08 12:22:53'),
(65, 136, 'Gin', '2025-10-08 12:22:53'),
(66, 136, 'Rum', '2025-10-08 12:22:53'),
(67, 136, 'Liqueur', '2025-10-08 12:22:53'),
(68, 136, 'Shooters', '2025-10-08 12:22:53'),
(69, 136, 'Cocktails', '2025-10-08 12:22:53'),
(70, 143, 'Meat', '2025-10-08 19:41:05'),
(71, 143, 'Vegetarian/Vegan', '2025-10-08 19:41:05'),
(73, 144, 'Juices & Smoothies', '2025-10-09 18:26:48'),
(74, 144, 'Iced Teas and Coffee', '2025-10-09 18:26:48'),
(75, 144, 'Energy Drinks', '2025-10-09 18:26:48'),
(76, 144, 'Cordials', '2025-10-09 18:26:48'),
(77, 144, 'Mocktails/Non Alcoholic', '2025-10-09 18:26:48'),
(78, 132, 'Still & Spring', '2025-10-09 18:26:48'),
(79, 132, 'Sparkling & Flavoured', '2025-10-09 18:26:48'),
(89, 126, 'Hot Chocolate & Cocoa Drinks', '2025-10-09 23:23:09'),
(90, 126, 'Milk & Non-Coffee Drinks', '2025-10-09 23:28:06'),
(92, 126, 'Teas & Coffees', '2025-10-10 00:08:42'),
(93, 144, 'Carbonated Drinks', '2025-10-10 11:43:02');

-- --------------------------------------------------------

--
-- Table structure for table `food_videos`
--

CREATE TABLE `food_videos` (
  `video_id` int(11) NOT NULL,
  `listing_id` int(11) NOT NULL,
  `video_url` varchar(255) NOT NULL,
  `thumbnail_url` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `duration` int(11) DEFAULT NULL COMMENT 'Duration in seconds',
  `file_size` int(11) DEFAULT NULL COMMENT 'File size in bytes',
  `file_format` varchar(10) DEFAULT NULL,
  `is_primary` tinyint(1) DEFAULT 0,
  `sort_order` int(11) DEFAULT 0,
  `status` enum('processing','active','inactive','failed') DEFAULT 'processing',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `order_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `dealer_id` int(11) NOT NULL,
  `driver_id` int(11) DEFAULT NULL,
  `listing_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `status` enum('pending','confirmed','preparing','ready','delivered','cancelled') DEFAULT 'pending',
  `delivery_address` text DEFAULT NULL,
  `delivery_phone` varchar(20) DEFAULT NULL,
  `special_instructions` text DEFAULT NULL,
  `order_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `delivery_date` timestamp NULL DEFAULT NULL,
  `driver_assigned_at` datetime DEFAULT NULL,
  `driver_pickup_time` datetime DEFAULT NULL,
  `driver_delivery_time` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `token` varchar(128) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `dealer_id` int(11) DEFAULT NULL,
  `listing_id` int(11) DEFAULT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `cart_id` int(11) DEFAULT NULL,
  `payment_method` varchar(32) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currency` varchar(8) NOT NULL,
  `status` varchar(32) NOT NULL,
  `transaction_id` varchar(128) DEFAULT NULL,
  `payer_email` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `review_id` int(11) NOT NULL,
  `listing_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `order_id` int(11) DEFAULT NULL,
  `rating` int(11) NOT NULL CHECK (`rating` >= 1 and `rating` <= 5),
  `review_text` text DEFAULT NULL,
  `is_approved` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `table_bookings`
--

CREATE TABLE `table_bookings` (
  `booking_id` int(11) NOT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `dealer_id` int(11) NOT NULL,
  `dish_id` int(11) DEFAULT NULL,
  `customer_name` varchar(255) NOT NULL,
  `customer_email` varchar(255) NOT NULL,
  `customer_phone` varchar(20) NOT NULL,
  `booking_date` date NOT NULL,
  `booking_time` time NOT NULL,
  `party_size` int(11) NOT NULL,
  `special_requests` text DEFAULT NULL,
  `status` enum('pending','confirmed','rejected','completed','cancelled') DEFAULT 'pending',
  `delivery_required` tinyint(1) NOT NULL DEFAULT 0,
  `delivery_address` text DEFAULT NULL,
  `driver_id` int(11) DEFAULT NULL,
  `delivery_assigned_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `table_bookings`
--

INSERT INTO `table_bookings` (`booking_id`, `customer_id`, `dealer_id`, `dish_id`, `customer_name`, `customer_email`, `customer_phone`, `booking_date`, `booking_time`, `party_size`, `special_requests`, `status`, `delivery_required`, `delivery_address`, `driver_id`, `delivery_assigned_at`, `created_at`, `updated_at`) VALUES
(12, NULL, 2, NULL, 'chisala', 'vudo@gmail.com', '97987994', '2025-10-27', '18:00:00', 2, '', 'confirmed', 0, NULL, NULL, NULL, '2025-10-19 09:32:00', '2025-12-08 15:06:31'),
(15, NULL, 2, NULL, 'chisala', 'nine@gmail.com', '8080800', '2025-11-07', '18:00:00', 2, 'bba', 'confirmed', 0, NULL, NULL, NULL, '2025-11-06 06:42:15', '2025-11-06 06:42:15'),
(17, NULL, 2, NULL, 'Happy phiri', 'iboytecguy1@gmail.com', '0777860169', '2025-12-17', '21:00:00', 2, '', 'confirmed', 0, NULL, NULL, NULL, '2025-12-07 17:23:52', '2025-12-09 13:52:39'),
(18, NULL, 2, NULL, 'lesa', 'mutalemattlesa@gmail.com', '07709671', '2025-12-12', '14:16:00', 2, '', 'rejected', 0, NULL, NULL, NULL, '2025-12-09 14:34:03', '2025-12-09 15:41:16'),
(40, 2, 2, 108, 'Lackson chisala', 'chisalaluckyk5@gmail.com', '0770812506', '2025-12-25', '21:00:00', 6, '', 'pending', 0, NULL, NULL, NULL, '2025-12-14 14:33:17', '2025-12-14 14:33:17'),
(48, 2, 2, 107, 'Lackson chisala', 'chisalaluckyk5@gmail.com', '0771355473', '2025-12-14', '21:30:00', 1, '', 'confirmed', 1, '', NULL, NULL, '2025-12-14 15:09:03', '2025-12-14 15:52:43');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `business_name` varchar(255) DEFAULT NULL,
  `business_type` varchar(100) DEFAULT NULL,
  `role` enum('admin','business_owner','customer','driver') NOT NULL,
  `is_approved` tinyint(1) DEFAULT 0,
  `agreed_marketing` tinyint(1) DEFAULT 0,
  `remember_token` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `email_verified` tinyint(1) NOT NULL DEFAULT 0,
  `email_verified_at` datetime DEFAULT NULL,
  `email_verification_token` varchar(128) DEFAULT NULL,
  `reset_token` varchar(128) DEFAULT NULL,
  `reset_token_expiry` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `email`, `password_hash`, `first_name`, `last_name`, `phone`, `date_of_birth`, `business_name`, `business_type`, `role`, `is_approved`, `agreed_marketing`, `remember_token`, `created_at`, `updated_at`, `email_verified`, `email_verified_at`, `email_verification_token`, `reset_token`, `reset_token_expiry`) VALUES
(1, 'luckyk5', 'luckyk5@gmail.com', '$2y$10$VEUsABjlC0SgfgNPMK/3Be3/3ppHh.zGdDp/oeZRTYAyM6vRy0KRy', 'Lackson', 'chisala', '0770812506', '2000-12-09', 'lackson chisala', 'restaurant', 'business_owner', 0, 1, 'f037367a99f89584141bd5965170f68f835f6c3d6a1e773d606f8960017a857e', '2025-08-02 13:29:16', '2025-08-06 15:37:11', 0, NULL, NULL, NULL, NULL),
(2, 'chisalaluckyk5', 'chisalaluckyk5@gmail.com', '$2y$10$WIoJtbDSlWQJRioeDiNLlOGAkXL1K0FTSGoIbOZ3Lzv/rSTlaxzni', 'Lackson', 'chisala', '0770812506', '2001-12-03', 'lackson chisala', 'restaurant', 'customer', 1, 1, 'ad13c46cc49a9f42b15412d6204b34fe5d499bd8f628f5672e77527b8ae6123b', '2025-08-02 13:30:45', '2025-12-13 08:34:01', 0, NULL, NULL, '4b1b21c95c7be2c5de0d62c01dac077223e47b86d4208e0ad4f7837d79028fff', '2025-12-13 10:34:01'),
(3, 'lesa', 'Info@pepe-s.co.za', '$2y$10$.lyuxlecJrj500W29iIQO.uzwiGatzbsDKwL9SDyL.Xg54SjyLvYm', 'lesa', 'mutale', '0777757378', '2002-01-03', 'beans rice', 'restaurant', 'business_owner', 0, 1, 'b6319f09c1cbacb4e5d1fa05c797f82bdbd646b9a3f1283c81319b183d759a3f', '2025-08-04 12:17:53', '2025-12-12 16:27:50', 0, NULL, NULL, NULL, NULL),
(4, 'c6hisalaluckyk5', 'c6hisalaluckyk5@gmail.com', '$2y$10$cHsC8cYIBYNooCO5i8yR2u/.fJa8hsCXX8VnNlNHb9RQW9YnAcm4a', 'lackson', 'chisala', '0770812506', '2022-12-22', 'u6u66u', 'restaurant', 'business_owner', 0, 1, 'a87e93443c2e63cb01f8d63b660054d6202126a4fdc8c78e205fedc142606187', '2025-09-15 09:29:13', '2025-09-21 21:31:48', 0, NULL, NULL, NULL, NULL),
(5, 'c66hisalaluckyk5', 'c66hisalaluckyk5@gmail.com', '$2y$10$JBYADQ3Gmq29WEBxnejZpe.ukmVE.ju9kydntMdRzAIava6q3KRVa', 'lackson', 'chisala', '0770812506', '2022-12-22', 'ghhghggh', 'bakery', 'business_owner', 0, 1, NULL, '2025-09-15 09:59:01', '2025-09-15 09:59:01', 0, NULL, NULL, NULL, NULL),
(6, 'c186hisalaluckyk5', 'c186hisalaluckyk5@gmail.com', '$2y$10$1Zel/8nL05IsXyc8VLM/Cu5xZuyDtbF5u5ov/ighLbULXbTf6oJFe', 'lackson', 'chisala', '0770812508', '2022-12-22', 'yango', 'restaurant', 'business_owner', 0, 1, NULL, '2025-09-17 09:46:03', '2025-09-17 09:46:03', 0, NULL, NULL, NULL, NULL),
(7, 'papes', 'papes@gmail.com', '$2y$10$qvTtEx19U0vsUwD6PXMUWOAUaMxZIhb23ves3DgV50EPQ5jE2TqqW', 'papes', 'papes', '0770812508', '2022-12-22', 'papesonthelake', 'restaurant', 'business_owner', 0, 1, NULL, '2025-09-17 14:39:59', '2025-09-17 14:39:59', 0, NULL, NULL, NULL, NULL),
(8, 'dc', 'dc@gmail.com', '$2y$10$C96UjPgIoUbbimbW/iiwL.Vq4NEhfqNP2yQAVjfax8bESMK9MPdVy', 'dc', 'chisla', '0770812506', '2000-09-18', NULL, NULL, 'customer', 1, 1, NULL, '2025-09-18 19:38:50', '2025-12-11 14:58:22', 0, NULL, NULL, NULL, NULL),
(9, 'admin', 'admin@tastebud.com', '$2y$10$Vcmk7NzePgkYIJLVm6KDkunX2jq7pbycF9Kcas4lYT5qaA.Jabfw.', 'Admin', 'User', NULL, NULL, NULL, NULL, 'admin', 0, 0, NULL, '2025-09-19 09:37:43', '2025-09-19 09:37:43', 0, NULL, NULL, NULL, NULL),
(10, 'lesamuts', 'lesamuts@gmail.com', '$2y$10$vA2Y0ry7nbJ3X.GiWeSFnOISlBJQ6URwH8ZteK2a.awC0l/IhLufG', 'Tinkle', 'Lesa', '0987654219', '2025-11-11', 'Albun', 'restaurant', 'business_owner', 0, 1, NULL, '2025-11-11 08:30:05', '2025-11-11 08:30:05', 0, NULL, NULL, NULL, NULL),
(14, 'iinfo', 'Iinfo@pepe-s.co.za', '$2y$10$7ey3mnt0JS89x1YSe7IN7ebFE5KABiwkbFJ0EuePsrilYg02sU0FK', 'Lackson', 'Chisala', '0771355473', '2000-12-07', NULL, NULL, 'customer', 0, 1, NULL, '2025-12-07 12:01:29', '2025-12-07 12:01:29', 0, NULL, NULL, NULL, NULL),
(15, 'tastebud351', 'tastebud351@gmail.com', '$2y$10$ZqFuuzK.FPhCnmzeZRV2Y.7w5lC3KYNirpVSLfIpUgj9GosfSsxgq', 'Lackson', 'Chisala', '0771355473', '2002-12-09', NULL, NULL, 'customer', 1, 1, NULL, '2025-12-09 17:29:56', '2025-12-11 15:20:54', 0, NULL, NULL, NULL, NULL),
(16, 'mablechanda', 'mablechanda@351gmail.com', '$2y$10$cXnmeA060MJ.2sOfbMKbHu9WZONt/bBYUd/sshb7wMPLia9HRzv9O', 'Mable', 'Chanda', '0771355473', '2000-12-10', 'Hungry lion2', 'restaurant', 'business_owner', 0, 1, NULL, '2025-12-10 19:35:58', '2025-12-10 19:35:58', 0, NULL, NULL, NULL, NULL),
(17, 'chandamable15', 'chandamable15@gmail.com', '$2y$10$w3wdehK6/rM8vEcSXDhoTuzBWSGbXltiRlEYwYH8/GWWN9LhIHaGu', 'Chanda', 'Mable', '0771355473', '2000-12-10', 'Hungry lion23', 'restaurant', 'business_owner', 0, 1, NULL, '2025-12-10 19:38:48', '2025-12-10 19:38:48', 0, NULL, NULL, NULL, NULL),
(18, 'driver1', 'driver1@example.com', '$2y$10$DuB2AORqsBt74nQJ4IByGONZkFF6WExUmkNv.DMzeQ53CHetyVXYi', 'Demo', 'Driver', '0710000001', '1990-01-01', NULL, NULL, 'driver', 0, 1, NULL, '2025-12-14 14:23:02', '2025-12-14 14:23:02', 0, NULL, NULL, NULL, NULL),
(19, 'driver2', 'driver2@example.com', '$2y$10$5nv3tZEpiXuIKF8UxTfqg.ASNdR1LZHMMLMoPr1elHz5XIHnzj2tW', 'Demo', 'Driver', '0710000002', '1991-02-02', NULL, NULL, 'driver', 0, 0, NULL, '2025-12-14 14:23:04', '2025-12-14 14:23:04', 0, NULL, NULL, NULL, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin_settings`
--
ALTER TABLE `admin_settings`
  ADD PRIMARY KEY (`setting_id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`);

--
-- Indexes for table `banner_advertisements`
--
ALTER TABLE `banner_advertisements`
  ADD PRIMARY KEY (`banner_id`);

--
-- Indexes for table `cart`
--
ALTER TABLE `cart`
  ADD PRIMARY KEY (`cart_id`),
  ADD UNIQUE KEY `unique_customer_listing` (`customer_id`,`listing_id`),
  ADD KEY `listing_id` (`listing_id`);

--
-- Indexes for table `cities`
--
ALTER TABLE `cities`
  ADD PRIMARY KEY (`city_id`),
  ADD KEY `country_id` (`country_id`);

--
-- Indexes for table `countries`
--
ALTER TABLE `countries`
  ADD PRIMARY KEY (`country_id`),
  ADD UNIQUE KEY `unique_country_name` (`name`),
  ADD UNIQUE KEY `unique_country_code` (`code`);

--
-- Indexes for table `cuisine_types`
--
ALTER TABLE `cuisine_types`
  ADD PRIMARY KEY (`cuisine_id`),
  ADD UNIQUE KEY `unique_cuisine_name` (`name`);

--
-- Indexes for table `dealers`
--
ALTER TABLE `dealers`
  ADD PRIMARY KEY (`dealer_id`),
  ADD UNIQUE KEY `unique_user_dealer` (`user_id`),
  ADD KEY `idx_dealers_location` (`latitude`,`longitude`);

--
-- Indexes for table `dealer_branches`
--
ALTER TABLE `dealer_branches`
  ADD PRIMARY KEY (`branch_id`),
  ADD KEY `fk_branch_dealer` (`dealer_id`);

--
-- Indexes for table `dealer_sales_team`
--
ALTER TABLE `dealer_sales_team`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_dealer_sales_team_dealer_id` (`dealer_id`),
  ADD KEY `idx_dealer_sales_team_status` (`status`);

--
-- Indexes for table `drivers`
--
ALTER TABLE `drivers`
  ADD PRIMARY KEY (`driver_id`),
  ADD UNIQUE KEY `unique_user_driver` (`user_id`),
  ADD KEY `idx_driver_status` (`status`),
  ADD KEY `idx_driver_availability` (`availability_status`);

--
-- Indexes for table `driver_earnings`
--
ALTER TABLE `driver_earnings`
  ADD PRIMARY KEY (`earning_id`),
  ADD KEY `driver_id` (`driver_id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `status` (`status`);

--
-- Indexes for table `favorites`
--
ALTER TABLE `favorites`
  ADD PRIMARY KEY (`favorite_id`),
  ADD UNIQUE KEY `unique_customer_favorite` (`customer_id`,`listing_id`),
  ADD KEY `listing_id` (`listing_id`);

--
-- Indexes for table `food_categories`
--
ALTER TABLE `food_categories`
  ADD PRIMARY KEY (`category_id`);

--
-- Indexes for table `food_images`
--
ALTER TABLE `food_images`
  ADD PRIMARY KEY (`image_id`),
  ADD KEY `listing_id` (`listing_id`);

--
-- Indexes for table `food_listings`
--
ALTER TABLE `food_listings`
  ADD PRIMARY KEY (`listing_id`),
  ADD KEY `dealer_id` (`dealer_id`),
  ADD KEY `category_id` (`category_id`),
  ADD KEY `subcategory_id` (`subcategory_id`),
  ADD KEY `food_listings_ibfk_4` (`primary_video_id`),
  ADD KEY `country_id` (`country_id`),
  ADD KEY `city_id` (`city_id`),
  ADD KEY `cuisine_id` (`cuisine_id`);

--
-- Indexes for table `food_subcategories`
--
ALTER TABLE `food_subcategories`
  ADD PRIMARY KEY (`subcategory_id`),
  ADD KEY `category_id` (`category_id`);

--
-- Indexes for table `food_variants`
--
ALTER TABLE `food_variants`
  ADD PRIMARY KEY (`variant_id`),
  ADD KEY `idx_subcategory_id` (`subcategory_id`);

--
-- Indexes for table `food_videos`
--
ALTER TABLE `food_videos`
  ADD PRIMARY KEY (`video_id`),
  ADD KEY `listing_id` (`listing_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `customer_id` (`customer_id`),
  ADD KEY `dealer_id` (`dealer_id`),
  ADD KEY `listing_id` (`listing_id`),
  ADD KEY `driver_id` (`driver_id`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `token` (`token`),
  ADD KEY `email` (`email`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `dealer_id` (`dealer_id`),
  ADD KEY `listing_id` (`listing_id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `cart_id` (`cart_id`),
  ADD KEY `transaction_id` (`transaction_id`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`review_id`),
  ADD UNIQUE KEY `unique_customer_listing_review` (`customer_id`,`listing_id`),
  ADD KEY `listing_id` (`listing_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `table_bookings`
--
ALTER TABLE `table_bookings`
  ADD PRIMARY KEY (`booking_id`),
  ADD KEY `dealer_id` (`dealer_id`),
  ADD KEY `dish_id` (`dish_id`),
  ADD KEY `driver_id` (`driver_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin_settings`
--
ALTER TABLE `admin_settings`
  MODIFY `setting_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `banner_advertisements`
--
ALTER TABLE `banner_advertisements`
  MODIFY `banner_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `cart`
--
ALTER TABLE `cart`
  MODIFY `cart_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `cities`
--
ALTER TABLE `cities`
  MODIFY `city_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `countries`
--
ALTER TABLE `countries`
  MODIFY `country_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `cuisine_types`
--
ALTER TABLE `cuisine_types`
  MODIFY `cuisine_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT for table `dealers`
--
ALTER TABLE `dealers`
  MODIFY `dealer_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `dealer_branches`
--
ALTER TABLE `dealer_branches`
  MODIFY `branch_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `dealer_sales_team`
--
ALTER TABLE `dealer_sales_team`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `drivers`
--
ALTER TABLE `drivers`
  MODIFY `driver_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `driver_earnings`
--
ALTER TABLE `driver_earnings`
  MODIFY `earning_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `favorites`
--
ALTER TABLE `favorites`
  MODIFY `favorite_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `food_categories`
--
ALTER TABLE `food_categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `food_images`
--
ALTER TABLE `food_images`
  MODIFY `image_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=217;

--
-- AUTO_INCREMENT for table `food_listings`
--
ALTER TABLE `food_listings`
  MODIFY `listing_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=175;

--
-- AUTO_INCREMENT for table `food_subcategories`
--
ALTER TABLE `food_subcategories`
  MODIFY `subcategory_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=167;

--
-- AUTO_INCREMENT for table `food_variants`
--
ALTER TABLE `food_variants`
  MODIFY `variant_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=94;

--
-- AUTO_INCREMENT for table `food_videos`
--
ALTER TABLE `food_videos`
  MODIFY `video_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `review_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `table_bookings`
--
ALTER TABLE `table_bookings`
  MODIFY `booking_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=49;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `cart`
--
ALTER TABLE `cart`
  ADD CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_ibfk_2` FOREIGN KEY (`listing_id`) REFERENCES `food_listings` (`listing_id`) ON DELETE CASCADE;

--
-- Constraints for table `cities`
--
ALTER TABLE `cities`
  ADD CONSTRAINT `cities_country_fk` FOREIGN KEY (`country_id`) REFERENCES `countries` (`country_id`) ON DELETE CASCADE;

--
-- Constraints for table `dealers`
--
ALTER TABLE `dealers`
  ADD CONSTRAINT `dealers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `dealer_branches`
--
ALTER TABLE `dealer_branches`
  ADD CONSTRAINT `fk_branch_dealer` FOREIGN KEY (`dealer_id`) REFERENCES `dealers` (`dealer_id`) ON DELETE CASCADE;

--
-- Constraints for table `dealer_sales_team`
--
ALTER TABLE `dealer_sales_team`
  ADD CONSTRAINT `dealer_sales_team_ibfk_1` FOREIGN KEY (`dealer_id`) REFERENCES `dealers` (`dealer_id`) ON DELETE CASCADE;

--
-- Constraints for table `favorites`
--
ALTER TABLE `favorites`
  ADD CONSTRAINT `favorites_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `favorites_ibfk_2` FOREIGN KEY (`listing_id`) REFERENCES `food_listings` (`listing_id`) ON DELETE CASCADE;

--
-- Constraints for table `food_images`
--
ALTER TABLE `food_images`
  ADD CONSTRAINT `food_images_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `food_listings` (`listing_id`) ON DELETE CASCADE;

--
-- Constraints for table `food_listings`
--
ALTER TABLE `food_listings`
  ADD CONSTRAINT `food_listings_city_fk` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `food_listings_country_fk` FOREIGN KEY (`country_id`) REFERENCES `countries` (`country_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `food_listings_cuisine_fk` FOREIGN KEY (`cuisine_id`) REFERENCES `cuisine_types` (`cuisine_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `food_listings_ibfk_1` FOREIGN KEY (`dealer_id`) REFERENCES `dealers` (`dealer_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `food_listings_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `food_categories` (`category_id`),
  ADD CONSTRAINT `food_listings_ibfk_3` FOREIGN KEY (`subcategory_id`) REFERENCES `food_subcategories` (`subcategory_id`),
  ADD CONSTRAINT `food_listings_ibfk_4` FOREIGN KEY (`primary_video_id`) REFERENCES `food_videos` (`video_id`) ON DELETE SET NULL;

--
-- Constraints for table `food_subcategories`
--
ALTER TABLE `food_subcategories`
  ADD CONSTRAINT `food_subcategories_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `food_categories` (`category_id`) ON DELETE CASCADE;

--
-- Constraints for table `food_variants`
--
ALTER TABLE `food_variants`
  ADD CONSTRAINT `fk_variants_subcategory` FOREIGN KEY (`subcategory_id`) REFERENCES `food_subcategories` (`subcategory_id`) ON DELETE CASCADE;

--
-- Constraints for table `food_videos`
--
ALTER TABLE `food_videos`
  ADD CONSTRAINT `food_videos_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `food_listings` (`listing_id`) ON DELETE CASCADE;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`dealer_id`) REFERENCES `dealers` (`dealer_id`),
  ADD CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`listing_id`) REFERENCES `food_listings` (`listing_id`);

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `food_listings` (`listing_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`customer_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `reviews_ibfk_3` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`);

--
-- Constraints for table `table_bookings`
--
ALTER TABLE `table_bookings`
  ADD CONSTRAINT `table_bookings_ibfk_1` FOREIGN KEY (`dealer_id`) REFERENCES `dealers` (`dealer_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `table_bookings_ibfk_2` FOREIGN KEY (`dish_id`) REFERENCES `food_listings` (`listing_id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
