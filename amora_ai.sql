-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 07, 2026 at 12:19 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.1.25

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `amora_ai`
--

-- --------------------------------------------------------

--
-- Table structure for table `accountdeletionconfirmations`
--

CREATE TABLE `accountdeletionconfirmations` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `tokenSelector` varchar(32) NOT NULL,
  `tokenHash` varchar(64) NOT NULL,
  `purpose` varchar(64) NOT NULL DEFAULT 'account_deletion',
  `expiresAt` datetime NOT NULL,
  `consumedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `accountdeletionrequests`
--

CREATE TABLE `accountdeletionrequests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userId` int(11) DEFAULT NULL,
  `status` enum('PENDING','VERIFIED','PROCESSING','COMPLETED','FAILED','BLOCKED_BY_RETENTION_DECISION') NOT NULL DEFAULT 'PENDING',
  `requestedAt` datetime NOT NULL DEFAULT current_timestamp(),
  `verifiedAt` datetime DEFAULT NULL,
  `processingStartedAt` datetime DEFAULT NULL,
  `completedAt` datetime DEFAULT NULL,
  `failedAt` datetime DEFAULT NULL,
  `failureCode` varchar(80) DEFAULT NULL,
  `legalHold` tinyint(1) NOT NULL DEFAULT 0,
  `legalHoldReason` varchar(120) DEFAULT NULL,
  `correlationId` varchar(36) NOT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  `updatedAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `adminauditlogs`
--

CREATE TABLE `adminauditlogs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `administratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `action` varchar(160) NOT NULL,
  `targetType` varchar(80) DEFAULT NULL,
  `targetId` varchar(191) DEFAULT NULL,
  `oldValue` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`oldValue`)),
  `newValue` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`newValue`)),
  `reason` varchar(500) DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `ipAddress` varchar(64) DEFAULT NULL,
  `userAgent` varchar(500) DEFAULT NULL,
  `correlationId` varchar(80) DEFAULT NULL,
  `createdAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `adminauditlogs`
--

INSERT INTO `adminauditlogs` (`id`, `administratorId`, `action`, `targetType`, `targetId`, `oldValue`, `newValue`, `reason`, `metadata`, `ipAddress`, `userAgent`, `correlationId`, `createdAt`) VALUES
(16, 6, 'administrator.created', 'administrator', '6', NULL, '{\"name\":\"yash andrapiya\",\"email\":\"yashandrapiya1@gmail.com\",\"role\":\"super_admin\",\"status\":\"active\"}', NULL, '{\"source\":\"admin_create_cli\"}', NULL, NULL, NULL, '2026-08-21 12:14:38'),
(17, 6, 'admin.auth.login_succeeded', 'administrator', '6', NULL, NULL, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', 'b76796e4-1849-47a6-b6de-e2a499446386', '2026-08-21 12:43:06'),
(18, 6, 'admin.auth.session_refreshed', 'administrator', '6', NULL, NULL, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '8562e16a-7770-4595-88b7-269ed608265c', '2026-08-21 13:00:26'),
(19, 6, 'admin.auth.session_refreshed', 'administrator', '6', NULL, NULL, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', 'a63cc9a1-711a-40ae-a2e3-339d152a00c5', '2026-08-21 13:15:56'),
(20, 6, 'admin.auth.login_succeeded', 'administrator', '6', NULL, NULL, NULL, NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2d12a123-a3ec-44a1-b215-b26811991892', '2026-08-24 07:48:53');

-- --------------------------------------------------------

--
-- Table structure for table `admindiscoverfilterfields`
--

CREATE TABLE `admindiscoverfilterfields` (
  `id` varchar(80) NOT NULL,
  `key` varchar(80) NOT NULL,
  `label` varchar(120) NOT NULL,
  `type` varchar(40) NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `visible` tinyint(1) NOT NULL DEFAULT 1,
  `required` tinyint(1) NOT NULL DEFAULT 0,
  `displayOrder` int(10) UNSIGNED NOT NULL,
  `maximumSelections` int(10) UNSIGNED DEFAULT NULL,
  `minimumValue` decimal(10,2) DEFAULT NULL,
  `maximumValue` decimal(10,2) DEFAULT NULL,
  `sensitive` tinyint(1) NOT NULL DEFAULT 0,
  `editable` tinyint(1) NOT NULL DEFAULT 1,
  `version` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `updatedByAdministratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `updatedAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admindiscoverfilterfields`
--

INSERT INTO `admindiscoverfilterfields` (`id`, `key`, `label`, `type`, `enabled`, `visible`, `required`, `displayOrder`, `maximumSelections`, `minimumValue`, `maximumValue`, `sensitive`, `editable`, `version`, `updatedByAdministratorId`, `updatedAt`) VALUES
('city', 'city', 'City', 'text', 1, 1, 0, 5, NULL, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('communication_styles', 'communicationStyles', 'Communication styles', 'multiple_selection', 1, 1, 0, 20, 10, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('community', 'community', 'Community', 'single_selection', 1, 1, 0, 12, 1, NULL, NULL, 1, 1, 1, NULL, '2026-09-01 06:20:13'),
('dating_intentions', 'datingIntentions', 'Dating intentions', 'multiple_selection', 1, 1, 0, 8, 10, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('drinking', 'drinking', 'Drinking', 'single_selection', 1, 1, 0, 22, 1, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('education', 'education', 'Education', 'single_selection', 1, 1, 0, 10, 1, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('event_interest', 'hasEventInterest', 'Has event interest', 'boolean', 1, 1, 0, 27, NULL, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('has_prompts', 'hasPrompts', 'Has prompts', 'boolean', 1, 1, 0, 26, NULL, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('hometown', 'hometown', 'Hometown', 'multiple_selection', 1, 1, 0, 7, 10, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('languages', 'languages', 'Languages', 'multiple_selection', 1, 1, 0, 14, 10, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('lifestyle_tags', 'lifestyleTags', 'Lifestyle', 'multiple_selection', 1, 1, 0, 9, 10, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('love_languages', 'loveLanguages', 'Love languages', 'multiple_selection', 1, 1, 0, 19, 10, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('max_age', 'maxAge', 'Maximum age', 'number', 1, 1, 1, 2, NULL, 18.00, 99.00, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('max_distance_km', 'maxDistanceKm', 'Maximum distance', 'number', 1, 1, 0, 3, NULL, 1.00, 500.00, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('minimum_height', 'minHeight', 'Minimum height', 'number', 1, 1, 0, 6, NULL, 0.00, 300.00, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('minimum_score', 'minScore', 'Minimum compatibility score', 'number', 1, 1, 0, 4, NULL, 0.00, 100.00, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('min_age', 'minAge', 'Minimum age', 'number', 1, 1, 1, 1, NULL, 18.00, 99.00, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('online_now', 'onlineNow', 'Online now', 'boolean', 1, 1, 0, 25, NULL, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('preferred_talking_hours', 'preferredTalkingHours', 'Preferred talking hours', 'multiple_selection', 1, 1, 0, 18, 10, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('profession', 'profession', 'Occupation', 'single_selection', 1, 1, 0, 11, 1, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('pronouns', 'pronouns', 'Pronouns', 'multiple_selection', 1, 1, 0, 15, 5, NULL, NULL, 1, 1, 1, NULL, '2026-09-01 06:20:13'),
('qualities', 'qualities', 'Valued qualities', 'multiple_selection', 1, 1, 0, 17, 10, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('religion', 'religion', 'Religion', 'single_selection', 1, 1, 0, 13, 1, NULL, NULL, 1, 1, 1, NULL, '2026-09-01 06:20:13'),
('sexuality', 'sexuality', 'Sexuality', 'single_selection', 1, 1, 0, 16, 1, NULL, NULL, 1, 1, 1, NULL, '2026-09-01 06:20:13'),
('smoking', 'smoking', 'Smoking', 'single_selection', 1, 1, 0, 21, 1, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('verified_only', 'verifiedOnly', 'Verified profiles only', 'boolean', 1, 1, 0, 24, NULL, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13'),
('weed', 'weed', 'Cannabis', 'single_selection', 1, 1, 0, 23, 1, NULL, NULL, 0, 1, 1, NULL, '2026-09-01 06:20:13');

-- --------------------------------------------------------

--
-- Table structure for table `admindiscoversettings`
--

CREATE TABLE `admindiscoversettings` (
  `key` varchar(80) NOT NULL,
  `value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`value`)),
  `version` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `updatedByAdministratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `updatedAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admindiscoversettings`
--

INSERT INTO `admindiscoversettings` (`key`, `value`, `version`, `updatedByAdministratorId`, `updatedAt`) VALUES
('default_max_age', '45', 1, NULL, '2026-09-01 06:20:13'),
('default_max_distance_km', '80', 1, NULL, '2026-09-01 06:20:13'),
('default_minimum_score', '0', 1, NULL, '2026-09-01 06:20:13'),
('default_min_age', '18', 1, NULL, '2026-09-01 06:20:13'),
('online_now_window_minutes', '5', 1, NULL, '2026-09-01 06:20:13');

-- --------------------------------------------------------

--
-- Table structure for table `adminidempotencykeys`
--

CREATE TABLE `adminidempotencykeys` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `administratorId` bigint(20) UNSIGNED NOT NULL,
  `scope` varchar(120) NOT NULL,
  `idempotencyKey` varchar(160) NOT NULL,
  `requestHash` varchar(64) NOT NULL,
  `responseStatus` smallint(5) UNSIGNED NOT NULL,
  `responseBody` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`responseBody`)),
  `expiresAt` datetime NOT NULL,
  `createdAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `admininvitations`
--

CREATE TABLE `admininvitations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `administratorId` bigint(20) UNSIGNED NOT NULL,
  `invitedByAdministratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `selector` varchar(32) NOT NULL,
  `tokenHash` varchar(64) NOT NULL,
  `expiresAt` datetime NOT NULL,
  `consumedAt` datetime DEFAULT NULL,
  `revokedAt` datetime DEFAULT NULL,
  `deliveryStatus` enum('not_requested','pending','provider_accepted','failed') NOT NULL DEFAULT 'not_requested',
  `deliveryAttempts` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `providerMessageId` varchar(191) DEFAULT NULL,
  `deliveryErrorCode` varchar(80) DEFAULT NULL,
  `deliveryAttemptedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `administratorroles`
--

CREATE TABLE `administratorroles` (
  `administratorId` bigint(20) UNSIGNED NOT NULL,
  `roleId` int(10) UNSIGNED NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `administratorroles`
--

INSERT INTO `administratorroles` (`administratorId`, `roleId`, `createdAt`, `updatedAt`) VALUES
(6, 1, '2026-08-21 12:14:38', '2026-08-21 12:14:38');

-- --------------------------------------------------------

--
-- Table structure for table `administrators`
--

CREATE TABLE `administrators` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(120) NOT NULL,
  `email` varchar(191) NOT NULL,
  `passwordHash` varchar(255) DEFAULT NULL,
  `status` enum('active','suspended','disabled') NOT NULL DEFAULT 'active',
  `tokenVersion` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `failedLoginAttempts` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `lockedUntil` datetime DEFAULT NULL,
  `lastLoginAt` datetime DEFAULT NULL,
  `lastActiveAt` datetime DEFAULT NULL,
  `createdByAdministratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `version` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `locale` varchar(20) NOT NULL DEFAULT 'en-IN',
  `timezone` varchar(80) NOT NULL DEFAULT 'Asia/Kolkata',
  `invitationStatus` enum('not_required','pending','accepted','expired','revoked') NOT NULL DEFAULT 'not_required',
  `activatedAt` datetime DEFAULT NULL,
  `suspendedAt` datetime DEFAULT NULL,
  `suspendedByAdministratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `suspensionReasonCode` varchar(40) DEFAULT NULL,
  `suspensionReasonDetail` varchar(500) DEFAULT NULL,
  `suspensionEndsAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `administrators`
--

INSERT INTO `administrators` (`id`, `name`, `email`, `passwordHash`, `status`, `tokenVersion`, `failedLoginAttempts`, `lockedUntil`, `lastLoginAt`, `lastActiveAt`, `createdByAdministratorId`, `createdAt`, `updatedAt`, `version`, `locale`, `timezone`, `invitationStatus`, `activatedAt`, `suspendedAt`, `suspendedByAdministratorId`, `suspensionReasonCode`, `suspensionReasonDetail`, `suspensionEndsAt`) VALUES
(6, 'yash andrapiya', 'yashandrapiya1@gmail.com', '$2b$12$yv8uww8qfoD8Uhso1SlKGOXp/GUEPiICTJ7CeRDhOvlBSFvcIwOgG', 'active', 0, 0, NULL, '2026-08-24 07:48:53', '2026-08-24 07:50:06', NULL, '2026-08-21 12:14:38', '2026-08-24 07:50:06', 1, 'en-IN', 'Asia/Kolkata', 'not_required', '2026-08-21 12:43:06', NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `adminmfachallenges`
--

CREATE TABLE `adminmfachallenges` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `administratorId` bigint(20) UNSIGNED NOT NULL,
  `selector` varchar(32) NOT NULL,
  `tokenHash` varchar(64) NOT NULL,
  `rememberMe` tinyint(1) NOT NULL DEFAULT 0,
  `expiresAt` datetime NOT NULL,
  `consumedAt` datetime DEFAULT NULL,
  `attempts` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `requestedByIp` varchar(64) DEFAULT NULL,
  `userAgent` varchar(500) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `adminmfacredentials`
--

CREATE TABLE `adminmfacredentials` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `administratorId` bigint(20) UNSIGNED NOT NULL,
  `encryptedSecret` text NOT NULL,
  `secretIv` varchar(24) NOT NULL,
  `secretTag` varchar(32) NOT NULL,
  `enabledAt` datetime DEFAULT NULL,
  `disabledAt` datetime DEFAULT NULL,
  `lastUsedCounter` bigint(20) UNSIGNED DEFAULT NULL,
  `recoveryCodeGeneration` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `adminmfarecoverycodes`
--

CREATE TABLE `adminmfarecoverycodes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `administratorId` bigint(20) UNSIGNED NOT NULL,
  `generation` int(10) UNSIGNED NOT NULL,
  `codeHash` varchar(64) NOT NULL,
  `consumedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `adminpasswordresettokens`
--

CREATE TABLE `adminpasswordresettokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `administratorId` bigint(20) UNSIGNED NOT NULL,
  `selector` varchar(32) NOT NULL,
  `tokenHash` varchar(64) NOT NULL,
  `expiresAt` datetime NOT NULL,
  `consumedAt` datetime DEFAULT NULL,
  `requestedByIp` varchar(64) DEFAULT NULL,
  `createdAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `adminpermissions`
--

CREATE TABLE `adminpermissions` (
  `id` int(10) UNSIGNED NOT NULL,
  `key` varchar(160) NOT NULL,
  `name` varchar(200) NOT NULL,
  `module` varchar(80) NOT NULL,
  `description` varchar(500) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `adminpermissions`
--

INSERT INTO `adminpermissions` (`id`, `key`, `name`, `module`, `description`) VALUES
(1, 'dashboard.view', 'Dashboard View', 'dashboard', 'Allows the administrator to perform the Dashboard View operation.'),
(2, 'users.view', 'Users View', 'users', 'Allows the administrator to perform the Users View operation.'),
(3, 'users.details.view', 'Users Details View', 'users', 'Allows the administrator to perform the Users Details View operation.'),
(4, 'users.profile.view', 'Users Profile View', 'users', 'Allows the administrator to perform the Users Profile View operation.'),
(5, 'users.sessions.view', 'Users Sessions View', 'users', 'Allows the administrator to perform the Users Sessions View operation.'),
(6, 'users.loginHistory.view', 'Users Login History View', 'users', 'Allows the administrator to perform the Users Login History View operation.'),
(7, 'users.notes.view', 'Users Notes View', 'users', 'Allows the administrator to perform the Users Notes View operation.'),
(8, 'users.notes.manage', 'Users Notes Manage', 'users', 'Allows the administrator to perform the Users Notes Manage operation.'),
(9, 'users.timeline.view', 'Users Timeline View', 'users', 'Allows the administrator to perform the Users Timeline View operation.'),
(10, 'users.manage', 'Users Manage', 'users', 'Allows the administrator to perform the Users Manage operation.'),
(11, 'users.suspend', 'Users Suspend', 'users', 'Allows the administrator to perform the Users Suspend operation.'),
(12, 'users.activate', 'Users Activate', 'users', 'Allows the administrator to perform the Users Activate operation.'),
(13, 'users.delete', 'Users Delete', 'users', 'Allows the administrator to perform the Users Delete operation.'),
(14, 'users.forceLogout', 'Users Force Logout', 'users', 'Allows the administrator to perform the Users Force Logout operation.'),
(15, 'users.resetPassword', 'Users Reset Password', 'users', 'Allows the administrator to perform the Users Reset Password operation.'),
(16, 'profiles.view', 'Profiles View', 'profiles', 'Allows the administrator to perform the Profiles View operation.'),
(17, 'profiles.details.view', 'Profiles Details View', 'profiles', 'Allows the administrator to perform the Profiles Details View operation.'),
(18, 'profiles.preview', 'Profiles Preview', 'profiles', 'Allows the administrator to perform the Profiles Preview operation.'),
(19, 'profiles.edit', 'Profiles Edit', 'profiles', 'Allows the administrator to perform the Profiles Edit operation.'),
(20, 'profiles.photos.view', 'Profiles Photos View', 'profiles', 'Allows the administrator to perform the Profiles Photos View operation.'),
(21, 'profiles.photos.manage', 'Profiles Photos Manage', 'profiles', 'Allows the administrator to perform the Profiles Photos Manage operation.'),
(22, 'profiles.verification.view', 'Profiles Verification View', 'profiles', 'Allows the administrator to perform the Profiles Verification View operation.'),
(23, 'profiles.verification.manage', 'Profiles Verification Manage', 'profiles', 'Allows the administrator to perform the Profiles Verification Manage operation.'),
(24, 'profiles.audit.view', 'Profiles Audit View', 'profiles', 'Allows the administrator to perform the Profiles Audit View operation.'),
(25, 'verifications.view', 'Verifications View', 'verifications', 'Allows the administrator to perform the Verifications View operation.'),
(26, 'verifications.pending.view', 'Verifications Pending View', 'verifications', 'Allows the administrator to perform the Verifications Pending View operation.'),
(27, 'verifications.approved.view', 'Verifications Approved View', 'verifications', 'Allows the administrator to perform the Verifications Approved View operation.'),
(28, 'verifications.rejected.view', 'Verifications Rejected View', 'verifications', 'Allows the administrator to perform the Verifications Rejected View operation.'),
(29, 'verifications.details.view', 'Verifications Details View', 'verifications', 'Allows the administrator to perform the Verifications Details View operation.'),
(30, 'verifications.aadhaar.view', 'Verifications Aadhaar View', 'verifications', 'Allows the administrator to perform the Verifications Aadhaar View operation.'),
(31, 'verifications.selfie.view', 'Verifications Selfie View', 'verifications', 'Allows the administrator to perform the Verifications Selfie View operation.'),
(32, 'verifications.approve', 'Verifications Approve', 'verifications', 'Allows the administrator to perform the Verifications Approve operation.'),
(33, 'verifications.reject', 'Verifications Reject', 'verifications', 'Allows the administrator to perform the Verifications Reject operation.'),
(34, 'verifications.resubmit', 'Verifications Resubmit', 'verifications', 'Allows the administrator to perform the Verifications Resubmit operation.'),
(35, 'verifications.history.view', 'Verifications History View', 'verifications', 'Allows the administrator to perform the Verifications History View operation.'),
(36, 'discover.settings.view', 'Discover Settings View', 'discover', 'Allows the administrator to perform the Discover Settings View operation.'),
(37, 'discover.settings.manage', 'Discover Settings Manage', 'discover', 'Allows the administrator to perform the Discover Settings Manage operation.'),
(38, 'discover.filters.view', 'Discover Filters View', 'discover', 'Allows the administrator to perform the Discover Filters View operation.'),
(39, 'discover.filters.manage', 'Discover Filters Manage', 'discover', 'Allows the administrator to perform the Discover Filters Manage operation.'),
(40, 'matching.likes.view', 'Matching Likes View', 'matching', 'Allows the administrator to perform the Matching Likes View operation.'),
(41, 'matching.superLikes.view', 'Matching Super Likes View', 'matching', 'Allows the administrator to perform the Matching Super Likes View operation.'),
(42, 'matching.roses.view', 'Matching Roses View', 'matching', 'Allows the administrator to perform the Matching Roses View operation.'),
(43, 'matching.matches.view', 'Matching Matches View', 'matching', 'Allows the administrator to perform the Matching Matches View operation.'),
(44, 'matching.actions.failed.view', 'Matching Actions Failed View', 'matching', 'Allows the administrator to perform the Matching Actions Failed View operation.'),
(45, 'matching.actions.details.view', 'Matching Actions Details View', 'matching', 'Allows the administrator to perform the Matching Actions Details View operation.'),
(46, 'matching.audit.view', 'Matching Audit View', 'matching', 'Allows the administrator to perform the Matching Audit View operation.'),
(47, 'chatModeration.view', 'Chat Moderation View', 'chatModeration', 'Allows the administrator to perform the Chat Moderation View operation.'),
(48, 'chatModeration.conversations.view', 'Chat Moderation Conversations View', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Conversations View operation.'),
(49, 'chatModeration.messages.view', 'Chat Moderation Messages View', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Messages View operation.'),
(50, 'chatModeration.reports.view', 'Chat Moderation Reports View', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Reports View operation.'),
(51, 'chatModeration.reports.manage', 'Chat Moderation Reports Manage', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Reports Manage operation.'),
(52, 'chatModeration.reports.assign', 'Chat Moderation Reports Assign', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Reports Assign operation.'),
(53, 'chatModeration.actions.review', 'Chat Moderation Actions Review', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Actions Review operation.'),
(54, 'chatModeration.actions.dismiss', 'Chat Moderation Actions Dismiss', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Actions Dismiss operation.'),
(55, 'chatModeration.actions.removeMessage', 'Chat Moderation Actions Remove Message', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Actions Remove Message operation.'),
(56, 'chatModeration.actions.restoreMessage', 'Chat Moderation Actions Restore Message', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Actions Restore Message operation.'),
(57, 'chatModeration.actions.escalate', 'Chat Moderation Actions Escalate', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Actions Escalate operation.'),
(58, 'chatModeration.notes.view', 'Chat Moderation Notes View', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Notes View operation.'),
(59, 'chatModeration.notes.manage', 'Chat Moderation Notes Manage', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Notes Manage operation.'),
(60, 'chatModeration.history.view', 'Chat Moderation History View', 'chatModeration', 'Allows the administrator to perform the Chat Moderation History View operation.'),
(61, 'events.view', 'Events View', 'events', 'Allows the administrator to perform the Events View operation.'),
(62, 'events.manage', 'Events Manage', 'events', 'Allows the administrator to perform the Events Manage operation.'),
(63, 'events.details.view', 'Events Details View', 'events', 'Allows the administrator to perform the Events Details View operation.'),
(64, 'events.create', 'Events Create', 'events', 'Allows the administrator to perform the Events Create operation.'),
(65, 'events.update', 'Events Update', 'events', 'Allows the administrator to perform the Events Update operation.'),
(66, 'events.publish', 'Events Publish', 'events', 'Allows the administrator to perform the Events Publish operation.'),
(67, 'events.cancel', 'Events Cancel', 'events', 'Allows the administrator to perform the Events Cancel operation.'),
(68, 'events.capacity.view', 'Events Capacity View', 'events', 'Allows the administrator to perform the Events Capacity View operation.'),
(69, 'events.capacity.manage', 'Events Capacity Manage', 'events', 'Allows the administrator to perform the Events Capacity Manage operation.'),
(70, 'events.featured.view', 'Events Featured View', 'events', 'Allows the administrator to perform the Events Featured View operation.'),
(71, 'events.featured.manage', 'Events Featured Manage', 'events', 'Allows the administrator to perform the Events Featured Manage operation.'),
(72, 'events.waitlist.view', 'Events Waitlist View', 'events', 'Allows the administrator to perform the Events Waitlist View operation.'),
(73, 'events.waitlist.manage', 'Events Waitlist Manage', 'events', 'Allows the administrator to perform the Events Waitlist Manage operation.'),
(74, 'events.attendees.view', 'Events Attendees View', 'events', 'Allows the administrator to perform the Events Attendees View operation.'),
(75, 'events.reminders.view', 'Events Reminders View', 'events', 'Allows the administrator to perform the Events Reminders View operation.'),
(76, 'events.reminders.manage', 'Events Reminders Manage', 'events', 'Allows the administrator to perform the Events Reminders Manage operation.'),
(77, 'events.analytics.view', 'Events Analytics View', 'events', 'Allows the administrator to perform the Events Analytics View operation.'),
(78, 'events.media.view', 'Events Media View', 'events', 'Allows the administrator to perform the Events Media View operation.'),
(79, 'events.media.manage', 'Events Media Manage', 'events', 'Allows the administrator to perform the Events Media Manage operation.'),
(80, 'events.audit.view', 'Events Audit View', 'events', 'Allows the administrator to perform the Events Audit View operation.'),
(81, 'notifications.view', 'Notifications View', 'notifications', 'Allows the administrator to perform the Notifications View operation.'),
(82, 'notifications.manage', 'Notifications Manage', 'notifications', 'Allows the administrator to perform the Notifications Manage operation.'),
(83, 'notifications.deliveryLogs.view', 'Notifications Delivery Logs View', 'notifications', 'Allows the administrator to perform the Notifications Delivery Logs View operation.'),
(84, 'notifications.deliveryLogs.details.view', 'Notifications Delivery Logs Details View', 'notifications', 'Allows the administrator to perform the Notifications Delivery Logs Details View operation.'),
(85, 'notifications.retry', 'Notifications Retry', 'notifications', 'Allows the administrator to perform the Notifications Retry operation.'),
(86, 'notifications.analytics.view', 'Notifications Analytics View', 'notifications', 'Allows the administrator to perform the Notifications Analytics View operation.'),
(87, 'notifications.push.view', 'Notifications Push View', 'notifications', 'Allows the administrator to perform the Notifications Push View operation.'),
(88, 'membership.view', 'Membership View', 'membership', 'Allows the administrator to perform the Membership View operation.'),
(89, 'membership.manage', 'Membership Manage', 'membership', 'Allows the administrator to perform the Membership Manage operation.'),
(90, 'membership.plans.view', 'Membership Plans View', 'membership', 'Allows the administrator to perform the Membership Plans View operation.'),
(91, 'membership.plans.create', 'Membership Plans Create', 'membership', 'Allows the administrator to perform the Membership Plans Create operation.'),
(92, 'membership.plans.update', 'Membership Plans Update', 'membership', 'Allows the administrator to perform the Membership Plans Update operation.'),
(93, 'membership.plans.activate', 'Membership Plans Activate', 'membership', 'Allows the administrator to perform the Membership Plans Activate operation.'),
(94, 'membership.plans.versions.view', 'Membership Plans Versions View', 'membership', 'Allows the administrator to perform the Membership Plans Versions View operation.'),
(95, 'payments.transactions.view', 'Payments Transactions View', 'payments', 'Allows the administrator to perform the Payments Transactions View operation.'),
(96, 'payments.transactions.details.view', 'Payments Transactions Details View', 'payments', 'Allows the administrator to perform the Payments Transactions Details View operation.'),
(97, 'payments.refunds.view', 'Payments Refunds View', 'payments', 'Allows the administrator to perform the Payments Refunds View operation.'),
(98, 'payments.refunds.create', 'Payments Refunds Create', 'payments', 'Allows the administrator to perform the Payments Refunds Create operation.'),
(99, 'payments.reports.view', 'Payments Reports View', 'payments', 'Allows the administrator to perform the Payments Reports View operation.'),
(100, 'payments.audit.view', 'Payments Audit View', 'payments', 'Allows the administrator to perform the Payments Audit View operation.'),
(101, 'revenue.view', 'Revenue View', 'revenue', 'Allows the administrator to perform the Revenue View operation.'),
(102, 'reports.view', 'Reports View', 'reports', 'Allows the administrator to perform the Reports View operation.'),
(103, 'reports.manage', 'Reports Manage', 'reports', 'Allows the administrator to perform the Reports Manage operation.'),
(104, 'safety.view', 'Safety View', 'safety', 'Allows the administrator to perform the Safety View operation.'),
(105, 'safety.reports.view', 'Safety Reports View', 'safety', 'Allows the administrator to perform the Safety Reports View operation.'),
(106, 'safety.reports.details.view', 'Safety Reports Details View', 'safety', 'Allows the administrator to perform the Safety Reports Details View operation.'),
(107, 'safety.reports.assign', 'Safety Reports Assign', 'safety', 'Allows the administrator to perform the Safety Reports Assign operation.'),
(108, 'safety.reports.resolve', 'Safety Reports Resolve', 'safety', 'Allows the administrator to perform the Safety Reports Resolve operation.'),
(109, 'safety.queue.view', 'Safety Queue View', 'safety', 'Allows the administrator to perform the Safety Queue View operation.'),
(110, 'safety.queue.manage', 'Safety Queue Manage', 'safety', 'Allows the administrator to perform the Safety Queue Manage operation.'),
(111, 'safety.actions.warn', 'Safety Actions Warn', 'safety', 'Allows the administrator to perform the Safety Actions Warn operation.'),
(112, 'safety.actions.suspend', 'Safety Actions Suspend', 'safety', 'Allows the administrator to perform the Safety Actions Suspend operation.'),
(113, 'safety.actions.escalate', 'Safety Actions Escalate', 'safety', 'Allows the administrator to perform the Safety Actions Escalate operation.'),
(114, 'analytics.view', 'Analytics View', 'analytics', 'Allows the administrator to perform the Analytics View operation.'),
(115, 'analytics.users.view', 'Analytics Users View', 'analytics', 'Allows the administrator to perform the Analytics Users View operation.'),
(116, 'analytics.memberships.view', 'Analytics Memberships View', 'analytics', 'Allows the administrator to perform the Analytics Memberships View operation.'),
(117, 'analytics.events.view', 'Analytics Events View', 'analytics', 'Allows the administrator to perform the Analytics Events View operation.'),
(118, 'analytics.revenue.view', 'Analytics Revenue View', 'analytics', 'Allows the administrator to perform the Analytics Revenue View operation.'),
(119, 'analytics.notifications.view', 'Analytics Notifications View', 'analytics', 'Allows the administrator to perform the Analytics Notifications View operation.'),
(120, 'administrators.view', 'Administrators View', 'administrators', 'Allows the administrator to perform the Administrators View operation.'),
(121, 'administrators.details.view', 'Administrators Details View', 'administrators', 'Allows the administrator to perform the Administrators Details View operation.'),
(122, 'administrators.create', 'Administrators Create', 'administrators', 'Allows the administrator to perform the Administrators Create operation.'),
(123, 'administrators.update', 'Administrators Update', 'administrators', 'Allows the administrator to perform the Administrators Update operation.'),
(124, 'administrators.assignRoles', 'Administrators Assign Roles', 'administrators', 'Allows the administrator to perform the Administrators Assign Roles operation.'),
(125, 'administrators.suspend', 'Administrators Suspend', 'administrators', 'Allows the administrator to perform the Administrators Suspend operation.'),
(126, 'administrators.reactivate', 'Administrators Reactivate', 'administrators', 'Allows the administrator to perform the Administrators Reactivate operation.'),
(127, 'administrators.sessions.view', 'Administrators Sessions View', 'administrators', 'Allows the administrator to perform the Administrators Sessions View operation.'),
(128, 'administrators.sessions.revoke', 'Administrators Sessions Revoke', 'administrators', 'Allows the administrator to perform the Administrators Sessions Revoke operation.'),
(129, 'administrators.audit.view', 'Administrators Audit View', 'administrators', 'Allows the administrator to perform the Administrators Audit View operation.'),
(130, 'roles.view', 'Roles View', 'roles', 'Allows the administrator to perform the Roles View operation.'),
(131, 'roles.details.view', 'Roles Details View', 'roles', 'Allows the administrator to perform the Roles Details View operation.'),
(132, 'roles.assign', 'Roles Assign', 'roles', 'Allows the administrator to perform the Roles Assign operation.'),
(133, 'roles.manage', 'Roles Manage', 'roles', 'Allows the administrator to perform the Roles Manage operation.'),
(134, 'permissions.view', 'Permissions View', 'permissions', 'Allows the administrator to perform the Permissions View operation.'),
(135, 'permissions.matrix.view', 'Permissions Matrix View', 'permissions', 'Allows the administrator to perform the Permissions Matrix View operation.'),
(136, 'permissions.matrix.manage', 'Permissions Matrix Manage', 'permissions', 'Allows the administrator to perform the Permissions Matrix Manage operation.'),
(137, 'permissions.catalog.view', 'Permissions Catalog View', 'permissions', 'Allows the administrator to perform the Permissions Catalog View operation.'),
(138, 'auditLogs.view', 'Audit Logs View', 'auditLogs', 'Allows the administrator to perform the Audit Logs View operation.'),
(139, 'auditLogs.details.view', 'Audit Logs Details View', 'auditLogs', 'Allows the administrator to perform the Audit Logs Details View operation.'),
(140, 'auditLogs.changes.view', 'Audit Logs Changes View', 'auditLogs', 'Allows the administrator to perform the Audit Logs Changes View operation.'),
(141, 'auditLogs.metadata.view', 'Audit Logs Metadata View', 'auditLogs', 'Allows the administrator to perform the Audit Logs Metadata View operation.'),
(142, 'auditLogs.requestContext.view', 'Audit Logs Request Context View', 'auditLogs', 'Allows the administrator to perform the Audit Logs Request Context View operation.'),
(143, 'auditLogs.actorDetails.view', 'Audit Logs Actor Details View', 'auditLogs', 'Allows the administrator to perform the Audit Logs Actor Details View operation.'),
(144, 'auditLogs.linkedEntities.view', 'Audit Logs Linked Entities View', 'auditLogs', 'Allows the administrator to perform the Audit Logs Linked Entities View operation.'),
(145, 'settings.manage', 'Settings Manage', 'settings', 'Allows the administrator to perform the Settings Manage operation.'),
(153, 'content.moderate', 'Content Moderate', 'content', 'Allows the administrator to perform the Content Moderate operation.'),
(159, 'analytics.users.sensitiveDimensions.view', 'Analytics Users Sensitive Dimensions View', 'analytics', 'Allows the administrator to perform the Analytics Users Sensitive Dimensions View operation.'),
(160, 'analytics.users.retention.view', 'Analytics Users Retention View', 'analytics', 'Allows the administrator to perform the Analytics Users Retention View operation.'),
(161, 'analytics.users.funnels.view', 'Analytics Users Funnels View', 'analytics', 'Allows the administrator to perform the Analytics Users Funnels View operation.'),
(163, 'analytics.memberships.planBreakdown.view', 'Analytics Memberships Plan Breakdown View', 'analytics', 'Allows the administrator to perform the Analytics Memberships Plan Breakdown View operation.'),
(164, 'analytics.memberships.retention.view', 'Analytics Memberships Retention View', 'analytics', 'Allows the administrator to perform the Analytics Memberships Retention View operation.'),
(166, 'analytics.events.attendance.view', 'Analytics Events Attendance View', 'analytics', 'Allows the administrator to perform the Analytics Events Attendance View operation.'),
(167, 'analytics.events.conversion.view', 'Analytics Events Conversion View', 'analytics', 'Allows the administrator to perform the Analytics Events Conversion View operation.'),
(169, 'analytics.revenue.net.view', 'Analytics Revenue Net View', 'analytics', 'Allows the administrator to perform the Analytics Revenue Net View operation.'),
(170, 'analytics.revenue.fees.view', 'Analytics Revenue Fees View', 'analytics', 'Allows the administrator to perform the Analytics Revenue Fees View operation.'),
(171, 'analytics.revenue.refunds.view', 'Analytics Revenue Refunds View', 'analytics', 'Allows the administrator to perform the Analytics Revenue Refunds View operation.'),
(172, 'analytics.revenue.multiCurrency.view', 'Analytics Revenue Multi Currency View', 'analytics', 'Allows the administrator to perform the Analytics Revenue Multi Currency View operation.'),
(174, 'analytics.notifications.engagement.view', 'Analytics Notifications Engagement View', 'analytics', 'Allows the administrator to perform the Analytics Notifications Engagement View operation.'),
(175, 'analytics.notifications.failureBreakdown.view', 'Analytics Notifications Failure Breakdown View', 'analytics', 'Allows the administrator to perform the Analytics Notifications Failure Breakdown View operation.'),
(176, 'analytics.savedFilters.view', 'Analytics Saved Filters View', 'analytics', 'Allows the administrator to perform the Analytics Saved Filters View operation.'),
(177, 'analytics.savedFilters.manage', 'Analytics Saved Filters Manage', 'analytics', 'Allows the administrator to perform the Analytics Saved Filters Manage operation.'),
(178, 'analytics.savedFilters.share', 'Analytics Saved Filters Share', 'analytics', 'Allows the administrator to perform the Analytics Saved Filters Share operation.'),
(179, 'analytics.exports.csv', 'Analytics Exports Csv', 'analytics', 'Allows the administrator to perform the Analytics Exports Csv operation.'),
(180, 'analytics.exports.excel', 'Analytics Exports Excel', 'analytics', 'Allows the administrator to perform the Analytics Exports Excel operation.'),
(181, 'analytics.exports.sensitiveData', 'Analytics Exports Sensitive Data', 'analytics', 'Allows the administrator to perform the Analytics Exports Sensitive Data operation.'),
(182, 'analytics.drillDown.view', 'Analytics Drill Down View', 'analytics', 'Allows the administrator to perform the Analytics Drill Down View operation.'),
(183, 'analytics.audit.view', 'Analytics Audit View', 'analytics', 'Allows the administrator to perform the Analytics Audit View operation.'),
(186, 'verification.view', 'Verification View', 'verification', 'Allows the administrator to perform the Verification View operation.'),
(187, 'presence.view', 'Presence View', 'presence', 'Allows the administrator to perform the Presence View operation.'),
(202, 'cases.assign', 'Cases Assign', 'cases', 'Allows the administrator to perform the Cases Assign operation.'),
(212, 'profiles.contact.view', 'Profiles Contact View', 'profiles', 'Allows the administrator to perform the Profiles Contact View operation.'),
(213, 'profiles.sensitiveFields.view', 'Profiles Sensitive Fields View', 'profiles', 'Allows the administrator to perform the Profiles Sensitive Fields View operation.'),
(221, 'verifications.compare', 'Verifications Compare', 'verifications', 'Allows the administrator to perform the Verifications Compare operation.'),
(226, 'verifications.sensitiveData.view', 'Verifications Sensitive Data View', 'verifications', 'Allows the administrator to perform the Verifications Sensitive Data View operation.'),
(234, 'matching.gifts.view', 'Matching Gifts View', 'matching', 'Allows the administrator to perform the Matching Gifts View operation.'),
(238, 'matching.aiScore.view', 'Matching Ai Score View', 'matching', 'Allows the administrator to perform the Matching Ai Score View operation.'),
(239, 'matching.aiScore.explanation.view', 'Matching Ai Score Explanation View', 'matching', 'Allows the administrator to perform the Matching Ai Score Explanation View operation.'),
(241, 'matching.sensitiveFields.view', 'Matching Sensitive Fields View', 'matching', 'Allows the administrator to perform the Matching Sensitive Fields View operation.'),
(244, 'chatModeration.conversations.content.view', 'Chat Moderation Conversations Content View', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Conversations Content View operation.'),
(246, 'chatModeration.messages.content.view', 'Chat Moderation Messages Content View', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Messages Content View operation.'),
(247, 'chatModeration.messages.search', 'Chat Moderation Messages Search', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Messages Search operation.'),
(248, 'chatModeration.messages.content.search', 'Chat Moderation Messages Content Search', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Messages Content Search operation.'),
(249, 'chatModeration.messages.metadata.view', 'Chat Moderation Messages Metadata View', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Messages Metadata View operation.'),
(258, 'chatModeration.attachments.view', 'Chat Moderation Attachments View', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Attachments View operation.'),
(262, 'chatModeration.sensitiveMetadata.view', 'Chat Moderation Sensitive Metadata View', 'chatModeration', 'Allows the administrator to perform the Chat Moderation Sensitive Metadata View operation.'),
(275, 'events.attendees.sensitiveFields.view', 'Events Attendees Sensitive Fields View', 'events', 'Allows the administrator to perform the Events Attendees Sensitive Fields View operation.'),
(282, 'notifications.templates.view', 'Notifications Templates View', 'notifications', 'Allows the administrator to perform the Notifications Templates View operation.'),
(283, 'notifications.templates.create', 'Notifications Templates Create', 'notifications', 'Allows the administrator to perform the Notifications Templates Create operation.'),
(284, 'notifications.templates.update', 'Notifications Templates Update', 'notifications', 'Allows the administrator to perform the Notifications Templates Update operation.'),
(285, 'notifications.templates.archive', 'Notifications Templates Archive', 'notifications', 'Allows the administrator to perform the Notifications Templates Archive operation.'),
(286, 'notifications.templates.preview', 'Notifications Templates Preview', 'notifications', 'Allows the administrator to perform the Notifications Templates Preview operation.'),
(287, 'notifications.templates.versions.view', 'Notifications Templates Versions View', 'notifications', 'Allows the administrator to perform the Notifications Templates Versions View operation.'),
(288, 'notifications.campaigns.view', 'Notifications Campaigns View', 'notifications', 'Allows the administrator to perform the Notifications Campaigns View operation.'),
(289, 'notifications.campaigns.create', 'Notifications Campaigns Create', 'notifications', 'Allows the administrator to perform the Notifications Campaigns Create operation.'),
(290, 'notifications.campaigns.update', 'Notifications Campaigns Update', 'notifications', 'Allows the administrator to perform the Notifications Campaigns Update operation.'),
(291, 'notifications.campaigns.schedule', 'Notifications Campaigns Schedule', 'notifications', 'Allows the administrator to perform the Notifications Campaigns Schedule operation.'),
(292, 'notifications.campaigns.launch', 'Notifications Campaigns Launch', 'notifications', 'Allows the administrator to perform the Notifications Campaigns Launch operation.'),
(293, 'notifications.campaigns.cancel', 'Notifications Campaigns Cancel', 'notifications', 'Allows the administrator to perform the Notifications Campaigns Cancel operation.'),
(296, 'notifications.deliveryLogs.sensitiveFields.view', 'Notifications Delivery Logs Sensitive Fields View', 'notifications', 'Allows the administrator to perform the Notifications Delivery Logs Sensitive Fields View operation.'),
(299, 'notifications.audit.view', 'Notifications Audit View', 'notifications', 'Allows the administrator to perform the Notifications Audit View operation.'),
(301, 'notifications.push.manage', 'Notifications Push Manage', 'notifications', 'Allows the administrator to perform the Notifications Push Manage operation.'),
(302, 'notifications.email.view', 'Notifications Email View', 'notifications', 'Allows the administrator to perform the Notifications Email View operation.'),
(303, 'notifications.email.manage', 'Notifications Email Manage', 'notifications', 'Allows the administrator to perform the Notifications Email Manage operation.'),
(304, 'notifications.sms.view', 'Notifications Sms View', 'notifications', 'Allows the administrator to perform the Notifications Sms View operation.'),
(305, 'notifications.sms.manage', 'Notifications Sms Manage', 'notifications', 'Allows the administrator to perform the Notifications Sms Manage operation.'),
(311, 'membership.offers.view', 'Membership Offers View', 'membership', 'Allows the administrator to perform the Membership Offers View operation.'),
(312, 'membership.offers.create', 'Membership Offers Create', 'membership', 'Allows the administrator to perform the Membership Offers Create operation.'),
(313, 'membership.offers.update', 'Membership Offers Update', 'membership', 'Allows the administrator to perform the Membership Offers Update operation.'),
(314, 'membership.offers.activate', 'Membership Offers Activate', 'membership', 'Allows the administrator to perform the Membership Offers Activate operation.'),
(317, 'payments.transactions.sensitiveFields.view', 'Payments Transactions Sensitive Fields View', 'payments', 'Allows the administrator to perform the Payments Transactions Sensitive Fields View operation.'),
(329, 'safety.cases.view', 'Safety Cases View', 'safety', 'Allows the administrator to perform the Safety Cases View operation.'),
(330, 'safety.cases.create', 'Safety Cases Create', 'safety', 'Allows the administrator to perform the Safety Cases Create operation.'),
(331, 'safety.cases.update', 'Safety Cases Update', 'safety', 'Allows the administrator to perform the Safety Cases Update operation.'),
(332, 'safety.cases.assign', 'Safety Cases Assign', 'safety', 'Allows the administrator to perform the Safety Cases Assign operation.'),
(333, 'safety.cases.resolve', 'Safety Cases Resolve', 'safety', 'Allows the administrator to perform the Safety Cases Resolve operation.'),
(334, 'safety.evidence.view', 'Safety Evidence View', 'safety', 'Allows the administrator to perform the Safety Evidence View operation.'),
(335, 'safety.evidence.sensitive.view', 'Safety Evidence Sensitive View', 'safety', 'Allows the administrator to perform the Safety Evidence Sensitive View operation.'),
(339, 'safety.notes.view', 'Safety Notes View', 'safety', 'Allows the administrator to perform the Safety Notes View operation.'),
(340, 'safety.notes.manage', 'Safety Notes Manage', 'safety', 'Allows the administrator to perform the Safety Notes Manage operation.'),
(341, 'safety.history.view', 'Safety History View', 'safety', 'Allows the administrator to perform the Safety History View operation.'),
(342, 'content.view', 'Content View', 'content', 'Allows the administrator to perform the Content View operation.'),
(343, 'content.create', 'Content Create', 'content', 'Allows the administrator to perform the Content Create operation.'),
(344, 'content.update', 'Content Update', 'content', 'Allows the administrator to perform the Content Update operation.'),
(345, 'content.publish', 'Content Publish', 'content', 'Allows the administrator to perform the Content Publish operation.'),
(346, 'content.history.view', 'Content History View', 'content', 'Allows the administrator to perform the Content History View operation.'),
(347, 'content.media.manage', 'Content Media Manage', 'content', 'Allows the administrator to perform the Content Media Manage operation.'),
(348, 'content.terms.view', 'Content Terms View', 'content', 'Allows the administrator to perform the Content Terms View operation.'),
(349, 'content.terms.manage', 'Content Terms Manage', 'content', 'Allows the administrator to perform the Content Terms Manage operation.'),
(350, 'content.privacy.view', 'Content Privacy View', 'content', 'Allows the administrator to perform the Content Privacy View operation.'),
(351, 'content.privacy.manage', 'Content Privacy Manage', 'content', 'Allows the administrator to perform the Content Privacy Manage operation.'),
(352, 'content.faqs.view', 'Content Faqs View', 'content', 'Allows the administrator to perform the Content Faqs View operation.'),
(353, 'content.faqs.manage', 'Content Faqs Manage', 'content', 'Allows the administrator to perform the Content Faqs Manage operation.'),
(354, 'content.faqs.publish', 'Content Faqs Publish', 'content', 'Allows the administrator to perform the Content Faqs Publish operation.'),
(355, 'content.safetyCenter.view', 'Content Safety Center View', 'content', 'Allows the administrator to perform the Content Safety Center View operation.'),
(356, 'content.safetyCenter.manage', 'Content Safety Center Manage', 'content', 'Allows the administrator to perform the Content Safety Center Manage operation.'),
(357, 'content.communityGuidelines.view', 'Content Community Guidelines View', 'content', 'Allows the administrator to perform the Content Community Guidelines View operation.'),
(358, 'content.communityGuidelines.manage', 'Content Community Guidelines Manage', 'content', 'Allows the administrator to perform the Content Community Guidelines Manage operation.'),
(359, 'support.view', 'Support View', 'support', 'Allows the administrator to perform the Support View operation.'),
(360, 'support.tickets.view', 'Support Tickets View', 'support', 'Allows the administrator to perform the Support Tickets View operation.'),
(361, 'support.tickets.details.view', 'Support Tickets Details View', 'support', 'Allows the administrator to perform the Support Tickets Details View operation.'),
(362, 'support.tickets.content.view', 'Support Tickets Content View', 'support', 'Allows the administrator to perform the Support Tickets Content View operation.'),
(363, 'support.tickets.assign', 'Support Tickets Assign', 'support', 'Allows the administrator to perform the Support Tickets Assign operation.'),
(364, 'support.tickets.resolve', 'Support Tickets Resolve', 'support', 'Allows the administrator to perform the Support Tickets Resolve operation.'),
(365, 'support.tickets.escalate', 'Support Tickets Escalate', 'support', 'Allows the administrator to perform the Support Tickets Escalate operation.'),
(366, 'support.tickets.reply', 'Support Tickets Reply', 'support', 'Allows the administrator to perform the Support Tickets Reply operation.'),
(367, 'support.categories.view', 'Support Categories View', 'support', 'Allows the administrator to perform the Support Categories View operation.'),
(368, 'support.categories.manage', 'Support Categories Manage', 'support', 'Allows the administrator to perform the Support Categories Manage operation.'),
(369, 'support.templates.view', 'Support Templates View', 'support', 'Allows the administrator to perform the Support Templates View operation.'),
(370, 'support.templates.manage', 'Support Templates Manage', 'support', 'Allows the administrator to perform the Support Templates Manage operation.'),
(371, 'support.notes.view', 'Support Notes View', 'support', 'Allows the administrator to perform the Support Notes View operation.'),
(372, 'support.notes.manage', 'Support Notes Manage', 'support', 'Allows the administrator to perform the Support Notes Manage operation.'),
(373, 'support.attachments.view', 'Support Attachments View', 'support', 'Allows the administrator to perform the Support Attachments View operation.'),
(374, 'support.history.view', 'Support History View', 'support', 'Allows the administrator to perform the Support History View operation.'),
(375, 'support.faqs.view', 'Support Faqs View', 'support', 'Allows the administrator to perform the Support Faqs View operation.'),
(393, 'permissions.highRisk.manage', 'Permissions High Risk Manage', 'permissions', 'Allows the administrator to perform the Permissions High Risk Manage operation.'),
(399, 'auditLogs.integrity.view', 'Audit Logs Integrity View', 'auditLogs', 'Allows the administrator to perform the Audit Logs Integrity View operation.'),
(400, 'auditLogs.retention.view', 'Audit Logs Retention View', 'auditLogs', 'Allows the administrator to perform the Audit Logs Retention View operation.'),
(402, 'auditLogs.sensitiveFields.view', 'Audit Logs Sensitive Fields View', 'auditLogs', 'Allows the administrator to perform the Audit Logs Sensitive Fields View operation.'),
(404, 'auditLogs.export.csv', 'Audit Logs Export Csv', 'auditLogs', 'Allows the administrator to perform the Audit Logs Export Csv operation.'),
(405, 'auditLogs.export.excel', 'Audit Logs Export Excel', 'auditLogs', 'Allows the administrator to perform the Audit Logs Export Excel operation.'),
(406, 'auditLogs.export.sensitiveFields', 'Audit Logs Export Sensitive Fields', 'auditLogs', 'Allows the administrator to perform the Audit Logs Export Sensitive Fields operation.'),
(407, 'auditLogs.export.largeRange', 'Audit Logs Export Large Range', 'auditLogs', 'Allows the administrator to perform the Audit Logs Export Large Range operation.'),
(408, 'auditLogs.accessHistory.view', 'Audit Logs Access History View', 'auditLogs', 'Allows the administrator to perform the Audit Logs Access History View operation.'),
(409, 'systemSettings.view', 'System Settings View', 'systemSettings', 'Allows the administrator to perform the System Settings View operation.'),
(410, 'systemSettings.update', 'System Settings Update', 'systemSettings', 'Allows the administrator to perform the System Settings Update operation.'),
(411, 'safety.reports.personalData.view', 'Safety Reports Personal Data View', 'safety', 'Allows the administrator to perform the Safety Reports Personal Data View operation.');

-- --------------------------------------------------------

--
-- Table structure for table `adminrefreshtokens`
--

CREATE TABLE `adminrefreshtokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `administratorId` bigint(20) UNSIGNED NOT NULL,
  `selector` varchar(32) NOT NULL,
  `tokenHash` varchar(64) NOT NULL,
  `expiresAt` datetime NOT NULL,
  `revokedAt` datetime DEFAULT NULL,
  `createdByIp` varchar(64) DEFAULT NULL,
  `userAgent` varchar(500) DEFAULT NULL,
  `lastUsedAt` datetime DEFAULT NULL,
  `persistent` tinyint(1) NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL,
  `sessionFamilyId` varchar(36) NOT NULL,
  `revokedReason` varchar(40) DEFAULT NULL,
  `replacedByTokenId` bigint(20) UNSIGNED DEFAULT NULL,
  `mfaVerifiedAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `adminrefreshtokens`
--

INSERT INTO `adminrefreshtokens` (`id`, `administratorId`, `selector`, `tokenHash`, `expiresAt`, `revokedAt`, `createdByIp`, `userAgent`, `lastUsedAt`, `persistent`, `createdAt`, `sessionFamilyId`, `revokedReason`, `replacedByTokenId`, `mfaVerifiedAt`) VALUES
(11, 6, '2c3ce717d8f7bdb5aa4bba1bfddbf01a', '088ffddd84fadf4606c46c29904e2191b61b609ba7e59c58c17435a383988ab9', '2026-09-20 12:43:06', '2026-08-21 13:00:24', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-21 13:00:24', 1, '2026-08-21 12:43:06', '6acb3667-9d68-11f1-9d35-536e31abc4d7', NULL, NULL, NULL),
(12, 6, '295fcfe50e438b9f2054ce31c3d94d14', '39d2259562597e497675bf9d8f77ba4c092e1ea726379305a11a4459c654f8ad', '2026-09-20 13:00:24', '2026-08-21 13:15:56', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-21 13:15:56', 1, '2026-08-21 13:00:24', '6acb37cc-9d68-11f1-9d35-536e31abc4d7', NULL, NULL, NULL),
(13, 6, '267ef01812a5c728769acd46c14d006f', '4295157b89311a16df5d15edf10b2fe435b98c20c2e00f97f5d2e9e8d2de48b7', '2026-09-20 13:15:56', NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', NULL, 1, '2026-08-21 13:15:56', '6acb3828-9d68-11f1-9d35-536e31abc4d7', NULL, NULL, NULL),
(14, 6, '38035c1878a0b49670606cb8e5d827fd', '1b743706c4c79f322a1d4ee05eb19392a362b076795d2a80c7760c8fdd8511c0', '2026-09-23 07:48:53', NULL, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', NULL, 1, '2026-08-24 07:48:53', '2f863218-fce6-4b28-84ec-e2a2b2e7a6e7', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `adminreportcases`
--

CREATE TABLE `adminreportcases` (
  `reportId` int(11) NOT NULL,
  `status` varchar(24) NOT NULL DEFAULT 'open',
  `severity` varchar(16) NOT NULL DEFAULT 'medium',
  `assignedAdministratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `resolution` text DEFAULT NULL,
  `resolvedAt` datetime DEFAULT NULL,
  `resolvedByAdministratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  `updatedAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `adminreportnotes`
--

CREATE TABLE `adminreportnotes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `reportId` int(11) NOT NULL,
  `authorAdministratorId` bigint(20) UNSIGNED NOT NULL,
  `text` text NOT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `adminrolepermissions`
--

CREATE TABLE `adminrolepermissions` (
  `roleId` int(10) UNSIGNED NOT NULL,
  `permissionId` int(10) UNSIGNED NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `adminrolepermissions`
--

INSERT INTO `adminrolepermissions` (`roleId`, `permissionId`, `createdAt`, `updatedAt`) VALUES
(1, 1, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 2, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 3, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 4, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 5, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 6, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 7, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 8, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 9, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 10, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 11, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 12, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 13, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 14, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 15, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 16, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 17, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 18, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 19, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 20, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 21, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 22, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 23, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 24, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 25, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 26, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 27, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 28, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 29, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 30, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 31, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 32, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 33, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 34, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 35, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 36, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 37, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 38, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 39, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 40, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 41, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 42, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 43, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 44, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 45, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 46, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 47, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 48, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 49, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 50, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 51, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 52, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 53, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 54, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 55, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 56, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 57, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 58, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 59, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 60, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 61, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 62, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 63, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 64, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 65, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 66, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 67, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 68, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 69, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 70, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 71, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 72, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 73, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 74, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 75, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 76, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 77, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 78, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 79, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 80, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 81, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 82, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 83, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 84, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 85, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 86, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 87, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 88, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 89, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 90, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 91, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 92, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 93, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 94, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 95, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 96, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 97, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 98, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 99, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 100, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 101, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 102, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 103, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 104, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 105, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 106, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 107, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 108, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 109, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 110, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 111, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 112, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 113, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 114, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 115, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 116, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 117, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 118, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 119, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 120, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 121, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 122, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 123, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 124, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 125, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 126, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 127, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 128, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 129, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 130, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 131, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 132, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 133, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 134, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 135, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 136, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 137, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 138, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 139, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 140, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 141, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 142, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 143, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 144, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 145, '2026-08-21 12:01:03', '2026-08-21 12:01:03'),
(1, 153, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 159, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 160, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 161, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 163, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 164, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 166, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 167, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 169, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 170, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 171, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 172, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 174, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 175, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 176, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 177, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 178, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 179, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 180, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 181, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 182, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 183, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 186, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 187, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 202, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 212, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 213, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 221, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 226, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 234, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 238, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 239, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 241, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 244, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 246, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 247, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 248, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 249, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 258, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 262, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 275, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 282, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 283, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 284, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 285, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 286, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 287, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 288, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 289, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 290, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 291, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 292, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 293, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 296, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 299, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 301, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 302, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 303, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 304, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 305, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 311, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 312, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 313, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 314, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 317, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 329, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 330, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 331, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 332, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 333, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 334, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 335, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 339, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 340, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 341, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 342, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 343, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 344, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 345, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 346, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 347, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 348, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 349, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 350, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 351, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 352, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 353, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 354, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 355, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 356, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 357, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 358, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 359, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 360, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 361, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 362, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 363, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 364, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 365, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 366, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 367, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 368, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 369, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 370, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 371, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 372, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 373, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 374, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 375, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 393, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 399, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 400, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 402, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 404, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 405, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 406, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 407, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 408, '2026-08-21 13:58:41', '2026-08-21 13:58:41'),
(1, 409, '2026-09-02 06:49:33', '2026-09-02 06:49:33'),
(1, 410, '2026-09-02 06:49:33', '2026-09-02 06:49:33'),
(1, 411, '2026-09-02 07:10:26', '2026-09-02 07:10:26');

-- --------------------------------------------------------

--
-- Table structure for table `adminroles`
--

CREATE TABLE `adminroles` (
  `id` int(10) UNSIGNED NOT NULL,
  `key` varchar(80) NOT NULL,
  `name` varchar(120) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `isSystem` tinyint(1) NOT NULL DEFAULT 0,
  `isActive` tinyint(1) NOT NULL DEFAULT 1,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `version` int(10) UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `adminroles`
--

INSERT INTO `adminroles` (`id`, `key`, `name`, `description`, `isSystem`, `isActive`, `createdAt`, `updatedAt`, `version`) VALUES
(1, 'super_admin', 'Super Admin', 'System role with the complete administrator permission catalog.', 1, 1, '2026-08-21 12:01:03', '2026-08-21 12:01:03', 1);

-- --------------------------------------------------------

--
-- Table structure for table `adminusernotes`
--

CREATE TABLE `adminusernotes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userId` int(11) NOT NULL,
  `authorAdministratorId` bigint(20) UNSIGNED NOT NULL,
  `text` text NOT NULL,
  `category` varchar(40) NOT NULL DEFAULT 'general',
  `version` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `deletedAt` datetime DEFAULT NULL,
  `deletedByAdministratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `adminusernoteversions`
--

CREATE TABLE `adminusernoteversions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `noteId` bigint(20) UNSIGNED NOT NULL,
  `version` int(10) UNSIGNED NOT NULL,
  `action` enum('created','updated','deleted') NOT NULL,
  `text` text DEFAULT NULL,
  `administratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `createdAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `blocks`
--

CREATE TABLE `blocks` (
  `id` int(11) NOT NULL,
  `blockerUserId` int(11) NOT NULL,
  `blockedUserId` int(11) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `blocks`
--

INSERT INTO `blocks` (`id`, `blockerUserId`, `blockedUserId`, `createdAt`, `updatedAt`) VALUES
(1, 1, 10, '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(12, 85, 12, '2026-08-13 06:48:37', '2026-08-13 06:48:37'),
(55, 1474, 1487, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(56, 1511, 1524, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(57, 1548, 1561, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(58, 1585, 1598, '2026-08-27 12:00:00', '2026-08-29 12:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `conversationparticipants`
--

CREATE TABLE `conversationparticipants` (
  `id` int(11) NOT NULL,
  `conversationId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `lastReadMessageId` int(11) DEFAULT NULL,
  `lastReadAt` datetime DEFAULT NULL,
  `draftText` text DEFAULT NULL,
  `joinedAt` datetime NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `mutedAt` datetime DEFAULT NULL,
  `mutedUntil` datetime DEFAULT NULL,
  `hiddenAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `conversationparticipants`
--

INSERT INTO `conversationparticipants` (`id`, `conversationId`, `userId`, `lastReadMessageId`, `lastReadAt`, `draftText`, `joinedAt`, `createdAt`, `updatedAt`, `mutedAt`, `mutedUntil`, `hiddenAt`) VALUES
(1, 1, 1, 2, '2026-08-11 22:02:21', NULL, '2026-07-30 22:27:21', '2026-08-11 18:50:36', '2026-08-11 22:27:22', NULL, NULL, NULL),
(2, 1, 3, 4, '2026-08-13 07:06:02', NULL, '2026-07-30 22:27:21', '2026-08-11 18:50:36', '2026-08-13 07:06:02', NULL, NULL, NULL),
(3, 2, 1, 8, '2026-08-11 22:02:21', NULL, '2026-07-30 22:27:21', '2026-08-11 18:50:36', '2026-08-11 22:27:22', NULL, NULL, NULL),
(4, 2, 6, 9, '2026-08-11 22:12:21', NULL, '2026-07-30 22:27:21', '2026-08-11 18:50:36', '2026-08-11 22:27:22', NULL, NULL, NULL),
(33, 15, 3, NULL, NULL, NULL, '2026-08-13 07:06:43', '2026-08-13 07:06:43', '2026-08-13 07:08:03', NULL, NULL, NULL),
(34, 15, 85, 37, '2026-08-17 08:03:25', NULL, '2026-08-13 07:06:43', '2026-08-13 07:06:43', '2026-08-17 08:03:25', NULL, NULL, NULL),
(608, 300, 1454, NULL, NULL, NULL, '2026-08-28 12:00:00', '2026-08-28 12:00:00', '2026-08-28 12:00:00', NULL, NULL, NULL),
(609, 300, 1461, NULL, NULL, NULL, '2026-08-28 12:00:00', '2026-08-28 12:00:00', '2026-08-28 12:00:00', NULL, NULL, NULL),
(610, 301, 1454, 3748, '2026-08-27 12:18:00', NULL, '2026-08-27 12:00:00', '2026-08-27 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(611, 301, 1468, 3748, '2026-08-27 12:18:00', NULL, '2026-08-27 12:00:00', '2026-08-27 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(612, 302, 1454, 3754, '2026-08-26 13:48:00', NULL, '2026-08-26 12:00:00', '2026-08-26 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(613, 302, 1475, 3752, '2026-08-26 13:12:00', NULL, '2026-08-26 12:00:00', '2026-08-26 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(614, 303, 1454, 3769, '2026-08-24 16:30:00', NULL, '2026-08-24 12:00:00', '2026-08-24 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(615, 303, 1489, 3767, '2026-08-24 15:54:00', 'That sounds like a lovely plan…', '2026-08-24 12:00:00', '2026-08-24 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(616, 304, 1454, 3785, '2026-08-23 16:48:00', NULL, '2026-08-23 12:00:00', '2026-08-23 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(617, 304, 1496, 3783, '2026-08-23 16:12:00', 'That sounds like a lovely plan…', '2026-08-23 12:00:00', '2026-08-23 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(618, 305, 1454, 3802, '2026-08-21 17:06:00', NULL, '2026-08-21 12:00:00', '2026-08-21 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(619, 305, 1510, 3800, '2026-08-21 16:30:00', 'That sounds like a lovely plan…', '2026-08-21 12:00:00', '2026-08-21 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(620, 306, 1454, 3857, '2026-08-16 04:30:00', NULL, '2026-08-15 12:00:00', '2026-08-15 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(621, 306, 1456, 3855, '2026-08-16 03:54:00', 'That sounds like a lovely plan…', '2026-08-15 12:00:00', '2026-08-15 12:00:00', '2026-08-29 12:52:35', '2026-08-28 12:00:00', NULL, NULL),
(622, 307, 1457, NULL, NULL, NULL, '2026-08-26 12:00:00', '2026-08-26 12:00:00', '2026-08-26 12:00:00', NULL, NULL, NULL),
(623, 307, 1458, NULL, NULL, NULL, '2026-08-26 12:00:00', '2026-08-26 12:00:00', '2026-08-26 12:00:00', NULL, NULL, NULL),
(624, 308, 1463, 3858, '2026-08-20 12:18:00', NULL, '2026-08-20 12:00:00', '2026-08-20 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(625, 308, 1464, 3858, '2026-08-20 12:18:00', NULL, '2026-08-20 12:00:00', '2026-08-20 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(626, 309, 1469, 3864, '2026-08-14 13:48:00', NULL, '2026-08-14 12:00:00', '2026-08-14 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(627, 309, 1470, 3862, '2026-08-14 13:12:00', NULL, '2026-08-14 12:00:00', '2026-08-14 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(628, 310, 1475, 3886, '2026-08-08 18:36:00', NULL, '2026-08-08 12:00:00', '2026-08-08 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(629, 310, 1476, 3884, '2026-08-08 18:00:00', 'That sounds like a lovely plan…', '2026-08-08 12:00:00', '2026-08-08 12:00:00', '2026-08-29 12:52:35', '2026-08-28 12:00:00', NULL, NULL),
(630, 311, 1481, 3909, '2026-08-02 18:54:00', NULL, '2026-08-02 12:00:00', '2026-08-02 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(631, 311, 1482, 3907, '2026-08-02 18:18:00', 'That sounds like a lovely plan…', '2026-08-02 12:00:00', '2026-08-02 12:00:00', '2026-08-29 12:52:35', '2026-08-28 12:00:00', NULL, NULL),
(632, 312, 1487, 3933, '2026-07-27 19:12:00', NULL, '2026-07-27 12:00:00', '2026-07-27 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(633, 312, 1488, 3931, '2026-07-27 18:36:00', 'That sounds like a lovely plan…', '2026-07-27 12:00:00', '2026-07-27 12:00:00', '2026-08-29 12:52:35', '2026-08-28 12:00:00', NULL, NULL),
(634, 313, 1493, 3958, '2026-07-21 19:30:00', NULL, '2026-07-21 12:00:00', '2026-07-21 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(635, 313, 1494, 3956, '2026-07-21 18:54:00', 'That sounds like a lovely plan…', '2026-07-21 12:00:00', '2026-07-21 12:00:00', '2026-08-29 12:52:35', '2026-08-28 12:00:00', NULL, NULL),
(636, 314, 1499, NULL, NULL, NULL, '2026-07-15 12:00:00', '2026-07-15 12:00:00', '2026-07-15 12:00:00', NULL, NULL, NULL),
(637, 314, 1500, NULL, NULL, NULL, '2026-07-15 12:00:00', '2026-07-15 12:00:00', '2026-07-15 12:00:00', NULL, NULL, NULL),
(638, 315, 1505, 3959, '2026-07-09 12:18:00', NULL, '2026-07-09 12:00:00', '2026-07-09 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(639, 315, 1506, 3959, '2026-07-09 12:18:00', NULL, '2026-07-09 12:00:00', '2026-07-09 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(640, 316, 1511, 3965, '2026-07-03 13:48:00', NULL, '2026-07-03 12:00:00', '2026-07-03 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(641, 316, 1512, 3963, '2026-07-03 13:12:00', NULL, '2026-07-03 12:00:00', '2026-07-03 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(642, 317, 1517, 3994, '2026-06-27 20:42:00', NULL, '2026-06-27 12:00:00', '2026-06-27 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(643, 317, 1518, 3992, '2026-06-27 20:06:00', 'That sounds like a lovely plan…', '2026-06-27 12:00:00', '2026-06-27 12:00:00', '2026-08-29 12:52:35', '2026-08-28 12:00:00', NULL, NULL),
(644, 318, 1523, 4024, '2026-06-21 21:00:00', NULL, '2026-06-21 12:00:00', '2026-06-21 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(645, 318, 1524, 4022, '2026-06-21 20:24:00', 'That sounds like a lovely plan…', '2026-06-21 12:00:00', '2026-06-21 12:00:00', '2026-08-29 12:52:35', '2026-08-28 12:00:00', NULL, NULL),
(646, 319, 1529, 4055, '2026-06-15 21:18:00', NULL, '2026-06-15 12:00:00', '2026-06-15 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(647, 319, 1530, 4053, '2026-06-15 20:42:00', 'That sounds like a lovely plan…', '2026-06-15 12:00:00', '2026-06-15 12:00:00', '2026-08-29 12:52:35', '2026-08-28 12:00:00', NULL, NULL),
(648, 320, 1535, 4087, '2026-06-09 21:36:00', NULL, '2026-06-09 12:00:00', '2026-06-09 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(649, 320, 1536, 4085, '2026-06-09 21:00:00', 'That sounds like a lovely plan…', '2026-06-09 12:00:00', '2026-06-09 12:00:00', '2026-08-29 12:52:35', '2026-08-28 12:00:00', NULL, NULL),
(650, 321, 1541, NULL, NULL, NULL, '2026-06-03 12:00:00', '2026-06-03 12:00:00', '2026-06-03 12:00:00', NULL, NULL, NULL),
(651, 321, 1542, NULL, NULL, NULL, '2026-06-03 12:00:00', '2026-06-03 12:00:00', '2026-06-03 12:00:00', NULL, NULL, NULL),
(652, 322, 1547, 4088, '2026-08-26 12:18:00', NULL, '2026-08-26 12:00:00', '2026-08-26 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(653, 322, 1548, 4088, '2026-08-26 12:18:00', NULL, '2026-08-26 12:00:00', '2026-08-26 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(654, 323, 1553, 4094, '2026-08-20 13:48:00', NULL, '2026-08-20 12:00:00', '2026-08-20 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(655, 323, 1554, 4092, '2026-08-20 13:12:00', NULL, '2026-08-20 12:00:00', '2026-08-20 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(656, 324, 1559, 4106, '2026-08-14 15:36:00', NULL, '2026-08-14 12:00:00', '2026-08-14 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(657, 324, 1560, 4104, '2026-08-14 15:00:00', 'That sounds like a lovely plan…', '2026-08-14 12:00:00', '2026-08-14 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(658, 325, 1565, 4119, '2026-08-08 15:54:00', NULL, '2026-08-08 12:00:00', '2026-08-08 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(659, 325, 1566, 4117, '2026-08-08 15:18:00', 'That sounds like a lovely plan…', '2026-08-08 12:00:00', '2026-08-08 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(660, 326, 1571, 4133, '2026-08-02 16:12:00', NULL, '2026-08-02 12:00:00', '2026-08-02 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(661, 326, 1572, 4131, '2026-08-02 15:36:00', 'That sounds like a lovely plan…', '2026-08-02 12:00:00', '2026-08-02 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(662, 327, 1577, 4148, '2026-07-27 16:30:00', NULL, '2026-07-27 12:00:00', '2026-07-27 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(663, 327, 1578, 4146, '2026-07-27 15:54:00', 'That sounds like a lovely plan…', '2026-07-27 12:00:00', '2026-07-27 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(664, 328, 1583, NULL, NULL, NULL, '2026-07-21 12:00:00', '2026-07-21 12:00:00', '2026-07-21 12:00:00', NULL, NULL, NULL),
(665, 328, 1584, NULL, NULL, NULL, '2026-07-21 12:00:00', '2026-07-21 12:00:00', '2026-07-21 12:00:00', NULL, NULL, NULL),
(666, 329, 1589, 4149, '2026-07-15 12:18:00', NULL, '2026-07-15 12:00:00', '2026-07-15 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(667, 329, 1590, 4149, '2026-07-15 12:18:00', NULL, '2026-07-15 12:00:00', '2026-07-15 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(668, 330, 1595, 4155, '2026-07-09 13:48:00', NULL, '2026-07-09 12:00:00', '2026-07-09 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(669, 330, 1596, 4153, '2026-07-09 13:12:00', NULL, '2026-07-09 12:00:00', '2026-07-09 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(670, 331, 1601, 4174, '2026-07-03 17:42:00', NULL, '2026-07-03 12:00:00', '2026-07-03 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL),
(671, 331, 1602, 4172, '2026-07-03 17:06:00', 'That sounds like a lovely plan…', '2026-07-03 12:00:00', '2026-07-03 12:00:00', '2026-08-29 12:52:35', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `conversations`
--

CREATE TABLE `conversations` (
  `id` int(11) NOT NULL,
  `pairKey` varchar(64) NOT NULL,
  `type` enum('direct') NOT NULL DEFAULT 'direct',
  `lastMessageId` int(11) DEFAULT NULL,
  `lastMessageAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `conversations`
--

INSERT INTO `conversations` (`id`, `pairKey`, `type`, `lastMessageId`, `lastMessageAt`, `createdAt`, `updatedAt`) VALUES
(1, '1:3', 'direct', 4, '2026-08-11 18:30:36', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(2, '1:6', 'direct', 10, '2026-08-11 18:30:36', '2026-08-11 18:50:36', '2026-08-11 22:27:22'),
(15, '3:85', 'direct', 37, '2026-08-17 08:03:07', '2026-08-13 07:06:43', '2026-08-17 08:03:07'),
(300, '1454:1461', 'direct', NULL, '2026-08-28 12:00:00', '2026-08-28 12:00:00', '2026-08-28 12:00:00'),
(301, '1454:1468', 'direct', 3748, '2026-08-27 12:18:00', '2026-08-27 12:00:00', '2026-08-29 12:52:35'),
(302, '1454:1475', 'direct', 3754, '2026-08-26 13:48:00', '2026-08-26 12:00:00', '2026-08-29 12:52:35'),
(303, '1454:1489', 'direct', 3769, '2026-08-24 16:30:00', '2026-08-24 12:00:00', '2026-08-29 12:52:35'),
(304, '1454:1496', 'direct', 3785, '2026-08-23 16:48:00', '2026-08-23 12:00:00', '2026-08-29 12:52:35'),
(305, '1454:1510', 'direct', 3802, '2026-08-21 17:06:00', '2026-08-21 12:00:00', '2026-08-29 12:52:35'),
(306, '1454:1456', 'direct', 3857, '2026-08-16 04:30:00', '2026-08-15 12:00:00', '2026-08-29 12:52:35'),
(307, '1457:1458', 'direct', NULL, '2026-08-26 12:00:00', '2026-08-26 12:00:00', '2026-08-26 12:00:00'),
(308, '1463:1464', 'direct', 3858, '2026-08-20 12:18:00', '2026-08-20 12:00:00', '2026-08-29 12:52:35'),
(309, '1469:1470', 'direct', 3864, '2026-08-14 13:48:00', '2026-08-14 12:00:00', '2026-08-29 12:52:35'),
(310, '1475:1476', 'direct', 3886, '2026-08-08 18:36:00', '2026-08-08 12:00:00', '2026-08-29 12:52:35'),
(311, '1481:1482', 'direct', 3909, '2026-08-02 18:54:00', '2026-08-02 12:00:00', '2026-08-29 12:52:35'),
(312, '1487:1488', 'direct', 3933, '2026-07-27 19:12:00', '2026-07-27 12:00:00', '2026-08-29 12:52:35'),
(313, '1493:1494', 'direct', 3958, '2026-07-21 19:30:00', '2026-07-21 12:00:00', '2026-08-29 12:52:35'),
(314, '1499:1500', 'direct', NULL, '2026-07-15 12:00:00', '2026-07-15 12:00:00', '2026-07-15 12:00:00'),
(315, '1505:1506', 'direct', 3959, '2026-07-09 12:18:00', '2026-07-09 12:00:00', '2026-08-29 12:52:35'),
(316, '1511:1512', 'direct', 3965, '2026-07-03 13:48:00', '2026-07-03 12:00:00', '2026-08-29 12:52:35'),
(317, '1517:1518', 'direct', 3994, '2026-06-27 20:42:00', '2026-06-27 12:00:00', '2026-08-29 12:52:35'),
(318, '1523:1524', 'direct', 4024, '2026-06-21 21:00:00', '2026-06-21 12:00:00', '2026-08-29 12:52:35'),
(319, '1529:1530', 'direct', 4055, '2026-06-15 21:18:00', '2026-06-15 12:00:00', '2026-08-29 12:52:35'),
(320, '1535:1536', 'direct', 4087, '2026-06-09 21:36:00', '2026-06-09 12:00:00', '2026-08-29 12:52:35'),
(321, '1541:1542', 'direct', NULL, '2026-06-03 12:00:00', '2026-06-03 12:00:00', '2026-06-03 12:00:00'),
(322, '1547:1548', 'direct', 4088, '2026-08-26 12:18:00', '2026-08-26 12:00:00', '2026-08-29 12:52:35'),
(323, '1553:1554', 'direct', 4094, '2026-08-20 13:48:00', '2026-08-20 12:00:00', '2026-08-29 12:52:35'),
(324, '1559:1560', 'direct', 4106, '2026-08-14 15:36:00', '2026-08-14 12:00:00', '2026-08-29 12:52:35'),
(325, '1565:1566', 'direct', 4119, '2026-08-08 15:54:00', '2026-08-08 12:00:00', '2026-08-29 12:52:35'),
(326, '1571:1572', 'direct', 4133, '2026-08-02 16:12:00', '2026-08-02 12:00:00', '2026-08-29 12:52:35'),
(327, '1577:1578', 'direct', 4148, '2026-07-27 16:30:00', '2026-07-27 12:00:00', '2026-08-29 12:52:35'),
(328, '1583:1584', 'direct', NULL, '2026-07-21 12:00:00', '2026-07-21 12:00:00', '2026-07-21 12:00:00'),
(329, '1589:1590', 'direct', 4149, '2026-07-15 12:18:00', '2026-07-15 12:00:00', '2026-08-29 12:52:35'),
(330, '1595:1596', 'direct', 4155, '2026-07-09 13:48:00', '2026-07-09 12:00:00', '2026-08-29 12:52:35'),
(331, '1601:1602', 'direct', 4174, '2026-07-03 17:42:00', '2026-07-03 12:00:00', '2026-08-29 12:52:35');

-- --------------------------------------------------------

--
-- Table structure for table `discoveractions`
--

CREATE TABLE `discoveractions` (
  `id` int(11) NOT NULL,
  `actorUserId` int(11) NOT NULL,
  `targetUserId` int(11) NOT NULL,
  `action` enum('pass','like','superLike') NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `discoveractions`
--

INSERT INTO `discoveractions` (`id`, `actorUserId`, `targetUserId`, `action`, `createdAt`, `updatedAt`) VALUES
(1, 1, 3, 'like', '2026-08-01 18:50:36', '2026-08-11 18:50:36'),
(2, 3, 1, 'like', '2026-08-01 18:51:36', '2026-08-11 18:50:36'),
(3, 1, 4, 'pass', '2026-08-04 18:50:36', '2026-08-11 18:50:36'),
(4, 5, 1, 'like', '2026-08-11 16:50:36', '2026-08-11 18:50:36'),
(5, 1, 6, 'superLike', '2026-07-22 18:50:36', '2026-08-11 18:50:36'),
(6, 6, 1, 'like', '2026-07-22 18:51:36', '2026-08-11 18:50:36'),
(7, 1, 12, 'superLike', '2026-08-10 18:50:36', '2026-08-11 18:50:36'),
(8, 14, 1, 'like', '2026-08-11 18:20:36', '2026-08-11 18:50:36'),
(17, 49, 1, 'pass', '2026-08-12 10:32:28', '2026-08-12 10:32:28'),
(18, 49, 2, 'pass', '2026-08-12 10:33:08', '2026-08-12 10:33:08'),
(19, 49, 3, 'pass', '2026-08-12 10:33:11', '2026-08-12 10:33:11'),
(20, 49, 4, 'pass', '2026-08-12 10:33:12', '2026-08-12 10:33:12'),
(28, 49, 14, 'pass', '2026-08-12 10:44:17', '2026-08-12 10:44:17'),
(29, 49, 15, 'pass', '2026-08-12 10:44:20', '2026-08-12 10:44:20'),
(56, 85, 2, 'pass', '2026-08-13 06:43:05', '2026-08-13 06:43:05'),
(57, 85, 3, 'like', '2026-08-13 06:43:09', '2026-08-13 06:43:09'),
(58, 85, 5, 'like', '2026-08-13 06:44:50', '2026-08-13 06:44:50'),
(60, 85, 6, 'like', '2026-08-13 06:46:58', '2026-08-13 06:46:58'),
(62, 85, 11, 'pass', '2026-08-13 06:48:32', '2026-08-13 06:48:32'),
(63, 85, 14, 'like', '2026-08-13 06:57:50', '2026-08-13 06:57:50'),
(64, 85, 15, 'like', '2026-08-13 07:00:05', '2026-08-13 07:00:05'),
(65, 85, 1, 'like', '2026-08-13 07:04:19', '2026-08-13 07:04:19'),
(66, 3, 2, 'pass', '2026-08-13 07:05:29', '2026-08-13 07:05:29'),
(67, 3, 85, 'like', '2026-08-13 07:06:31', '2026-08-13 07:06:31'),
(68, 85, 4, 'like', '2026-08-13 07:08:47', '2026-08-13 07:08:47'),
(78, 85, 10, 'pass', '2026-08-17 08:01:22', '2026-08-17 08:01:22'),
(79, 85, 13, 'like', '2026-08-17 08:01:23', '2026-08-17 08:01:23'),
(16379, 1454, 1461, 'like', '2026-08-28 12:00:00', '2026-08-28 12:00:00'),
(16380, 1454, 1468, 'like', '2026-08-27 12:00:00', '2026-08-27 12:00:00'),
(16381, 1454, 1475, 'superLike', '2026-08-26 12:00:00', '2026-08-26 12:00:00'),
(16382, 1454, 1482, 'pass', '2026-08-25 12:00:00', '2026-08-25 12:00:00'),
(16383, 1454, 1489, 'like', '2026-08-24 12:00:00', '2026-08-24 12:00:00'),
(16384, 1454, 1496, 'like', '2026-08-23 12:00:00', '2026-08-23 12:00:00'),
(16385, 1454, 1503, 'pass', '2026-08-22 12:00:00', '2026-08-22 12:00:00'),
(16386, 1454, 1510, 'like', '2026-08-21 12:00:00', '2026-08-21 12:00:00'),
(16387, 1455, 1462, 'pass', '2026-08-28 11:59:00', '2026-08-28 11:59:00'),
(16388, 1455, 1469, 'like', '2026-08-27 11:59:00', '2026-08-27 11:59:00'),
(16389, 1455, 1476, 'like', '2026-08-26 11:59:00', '2026-08-26 11:59:00'),
(16390, 1455, 1483, 'superLike', '2026-08-25 11:59:00', '2026-08-25 11:59:00'),
(16391, 1455, 1490, 'pass', '2026-08-24 11:59:00', '2026-08-24 11:59:00'),
(16392, 1455, 1497, 'like', '2026-08-23 11:59:00', '2026-08-23 11:59:00'),
(16393, 1455, 1504, 'like', '2026-08-22 11:59:00', '2026-08-22 11:59:00'),
(16394, 1455, 1511, 'pass', '2026-08-21 11:59:00', '2026-08-21 11:59:00'),
(16395, 1455, 1518, 'like', '2026-08-20 11:59:00', '2026-08-20 11:59:00'),
(16396, 1456, 1463, 'like', '2026-08-28 11:58:00', '2026-08-28 11:58:00'),
(16397, 1456, 1470, 'pass', '2026-08-27 11:58:00', '2026-08-27 11:58:00'),
(16398, 1456, 1477, 'like', '2026-08-26 11:58:00', '2026-08-26 11:58:00'),
(16399, 1456, 1484, 'like', '2026-08-25 11:58:00', '2026-08-25 11:58:00'),
(16400, 1456, 1491, 'superLike', '2026-08-24 11:58:00', '2026-08-24 11:58:00'),
(16401, 1456, 1498, 'pass', '2026-08-23 11:58:00', '2026-08-23 11:58:00'),
(16402, 1456, 1505, 'like', '2026-08-22 11:58:00', '2026-08-22 11:58:00'),
(16403, 1456, 1512, 'like', '2026-08-21 11:58:00', '2026-08-21 11:58:00'),
(16404, 1456, 1519, 'pass', '2026-08-20 11:58:00', '2026-08-20 11:58:00'),
(16405, 1456, 1526, 'like', '2026-08-19 11:58:00', '2026-08-19 11:58:00'),
(16406, 1457, 1464, 'like', '2026-08-28 11:57:00', '2026-08-28 11:57:00'),
(16407, 1457, 1471, 'like', '2026-08-27 11:57:00', '2026-08-27 11:57:00'),
(16408, 1457, 1478, 'pass', '2026-08-26 11:57:00', '2026-08-26 11:57:00'),
(16409, 1457, 1485, 'like', '2026-08-25 11:57:00', '2026-08-25 11:57:00'),
(16410, 1457, 1492, 'like', '2026-08-24 11:57:00', '2026-08-24 11:57:00'),
(16411, 1457, 1499, 'superLike', '2026-08-23 11:57:00', '2026-08-23 11:57:00'),
(16412, 1457, 1506, 'pass', '2026-08-22 11:57:00', '2026-08-22 11:57:00'),
(16413, 1457, 1513, 'like', '2026-08-21 11:57:00', '2026-08-21 11:57:00'),
(16414, 1457, 1520, 'like', '2026-08-20 11:57:00', '2026-08-20 11:57:00'),
(16415, 1457, 1527, 'pass', '2026-08-19 11:57:00', '2026-08-19 11:57:00'),
(16416, 1457, 1534, 'like', '2026-08-18 11:57:00', '2026-08-18 11:57:00'),
(16417, 1458, 1465, 'pass', '2026-08-28 11:56:00', '2026-08-28 11:56:00'),
(16418, 1458, 1472, 'like', '2026-08-27 11:56:00', '2026-08-27 11:56:00'),
(16419, 1458, 1479, 'like', '2026-08-26 11:56:00', '2026-08-26 11:56:00'),
(16420, 1458, 1486, 'pass', '2026-08-25 11:56:00', '2026-08-25 11:56:00'),
(16421, 1458, 1493, 'like', '2026-08-24 11:56:00', '2026-08-24 11:56:00'),
(16422, 1458, 1500, 'like', '2026-08-23 11:56:00', '2026-08-23 11:56:00'),
(16423, 1458, 1507, 'superLike', '2026-08-22 11:56:00', '2026-08-22 11:56:00'),
(16424, 1458, 1514, 'pass', '2026-08-21 11:56:00', '2026-08-21 11:56:00'),
(16425, 1458, 1521, 'like', '2026-08-20 11:56:00', '2026-08-20 11:56:00'),
(16426, 1458, 1528, 'like', '2026-08-19 11:56:00', '2026-08-19 11:56:00'),
(16427, 1458, 1535, 'pass', '2026-08-18 11:56:00', '2026-08-18 11:56:00'),
(16428, 1458, 1542, 'like', '2026-08-17 11:56:00', '2026-08-17 11:56:00'),
(16429, 1459, 1466, 'like', '2026-08-28 11:55:00', '2026-08-28 11:55:00'),
(16430, 1459, 1473, 'pass', '2026-08-27 11:55:00', '2026-08-27 11:55:00'),
(16431, 1459, 1480, 'like', '2026-08-26 11:55:00', '2026-08-26 11:55:00'),
(16432, 1459, 1487, 'like', '2026-08-25 11:55:00', '2026-08-25 11:55:00'),
(16433, 1459, 1494, 'pass', '2026-08-24 11:55:00', '2026-08-24 11:55:00'),
(16434, 1459, 1501, 'like', '2026-08-23 11:55:00', '2026-08-23 11:55:00'),
(16435, 1459, 1508, 'like', '2026-08-22 11:55:00', '2026-08-22 11:55:00'),
(16436, 1459, 1515, 'superLike', '2026-08-21 11:55:00', '2026-08-21 11:55:00'),
(16437, 1459, 1522, 'pass', '2026-08-20 11:55:00', '2026-08-20 11:55:00'),
(16438, 1459, 1529, 'like', '2026-08-19 11:55:00', '2026-08-19 11:55:00'),
(16439, 1459, 1536, 'like', '2026-08-18 11:55:00', '2026-08-18 11:55:00'),
(16440, 1459, 1543, 'pass', '2026-08-17 11:55:00', '2026-08-17 11:55:00'),
(16441, 1459, 1550, 'like', '2026-08-16 11:55:00', '2026-08-16 11:55:00'),
(16442, 1460, 1467, 'like', '2026-08-28 11:54:00', '2026-08-28 11:54:00'),
(16443, 1460, 1474, 'like', '2026-08-27 11:54:00', '2026-08-27 11:54:00'),
(16444, 1460, 1481, 'pass', '2026-08-26 11:54:00', '2026-08-26 11:54:00'),
(16445, 1460, 1488, 'like', '2026-08-25 11:54:00', '2026-08-25 11:54:00'),
(16446, 1460, 1495, 'like', '2026-08-24 11:54:00', '2026-08-24 11:54:00'),
(16447, 1460, 1502, 'pass', '2026-08-23 11:54:00', '2026-08-23 11:54:00'),
(16448, 1460, 1509, 'like', '2026-08-22 11:54:00', '2026-08-22 11:54:00'),
(16449, 1460, 1516, 'like', '2026-08-21 11:54:00', '2026-08-21 11:54:00'),
(16450, 1460, 1523, 'superLike', '2026-08-20 11:54:00', '2026-08-20 11:54:00'),
(16451, 1460, 1530, 'pass', '2026-08-19 11:54:00', '2026-08-19 11:54:00'),
(16452, 1460, 1537, 'like', '2026-08-18 11:54:00', '2026-08-18 11:54:00'),
(16453, 1460, 1544, 'like', '2026-08-17 11:54:00', '2026-08-17 11:54:00'),
(16454, 1460, 1551, 'pass', '2026-08-16 11:54:00', '2026-08-16 11:54:00'),
(16455, 1460, 1558, 'like', '2026-08-15 11:54:00', '2026-08-15 11:54:00'),
(16456, 1461, 1468, 'pass', '2026-08-28 11:53:00', '2026-08-28 11:53:00'),
(16457, 1461, 1475, 'like', '2026-08-27 11:53:00', '2026-08-27 11:53:00'),
(16458, 1461, 1482, 'like', '2026-08-26 11:53:00', '2026-08-26 11:53:00'),
(16459, 1461, 1489, 'pass', '2026-08-25 11:53:00', '2026-08-25 11:53:00'),
(16460, 1461, 1496, 'like', '2026-08-24 11:53:00', '2026-08-24 11:53:00'),
(16461, 1461, 1503, 'like', '2026-08-23 11:53:00', '2026-08-23 11:53:00'),
(16462, 1461, 1510, 'pass', '2026-08-22 11:53:00', '2026-08-22 11:53:00'),
(16463, 1461, 1517, 'like', '2026-08-21 11:53:00', '2026-08-21 11:53:00'),
(16464, 1461, 1524, 'like', '2026-08-20 11:53:00', '2026-08-20 11:53:00'),
(16465, 1461, 1531, 'superLike', '2026-08-19 11:53:00', '2026-08-19 11:53:00'),
(16466, 1461, 1538, 'pass', '2026-08-18 11:53:00', '2026-08-18 11:53:00'),
(16467, 1461, 1545, 'like', '2026-08-17 11:53:00', '2026-08-17 11:53:00'),
(16468, 1461, 1552, 'like', '2026-08-16 11:53:00', '2026-08-16 11:53:00'),
(16469, 1461, 1559, 'pass', '2026-08-15 11:53:00', '2026-08-15 11:53:00'),
(16470, 1461, 1566, 'like', '2026-08-14 11:53:00', '2026-08-14 11:53:00'),
(16471, 1462, 1469, 'superLike', '2026-08-28 11:52:00', '2026-08-28 11:52:00'),
(16472, 1462, 1476, 'pass', '2026-08-27 11:52:00', '2026-08-27 11:52:00'),
(16473, 1462, 1483, 'like', '2026-08-26 11:52:00', '2026-08-26 11:52:00'),
(16474, 1462, 1490, 'like', '2026-08-25 11:52:00', '2026-08-25 11:52:00'),
(16475, 1462, 1497, 'pass', '2026-08-24 11:52:00', '2026-08-24 11:52:00'),
(16476, 1462, 1504, 'like', '2026-08-23 11:52:00', '2026-08-23 11:52:00'),
(16477, 1462, 1511, 'like', '2026-08-22 11:52:00', '2026-08-22 11:52:00'),
(16478, 1462, 1518, 'pass', '2026-08-21 11:52:00', '2026-08-21 11:52:00'),
(16479, 1463, 1470, 'like', '2026-08-28 11:51:00', '2026-08-28 11:51:00'),
(16480, 1463, 1477, 'superLike', '2026-08-27 11:51:00', '2026-08-27 11:51:00'),
(16481, 1463, 1484, 'pass', '2026-08-26 11:51:00', '2026-08-26 11:51:00'),
(16482, 1463, 1491, 'like', '2026-08-25 11:51:00', '2026-08-25 11:51:00'),
(16483, 1463, 1498, 'like', '2026-08-24 11:51:00', '2026-08-24 11:51:00'),
(16484, 1463, 1505, 'pass', '2026-08-23 11:51:00', '2026-08-23 11:51:00'),
(16485, 1463, 1512, 'like', '2026-08-22 11:51:00', '2026-08-22 11:51:00'),
(16486, 1463, 1519, 'like', '2026-08-21 11:51:00', '2026-08-21 11:51:00'),
(16487, 1463, 1526, 'pass', '2026-08-20 11:51:00', '2026-08-20 11:51:00'),
(16488, 1464, 1471, 'like', '2026-08-28 11:50:00', '2026-08-28 11:50:00'),
(16489, 1464, 1478, 'like', '2026-08-27 11:50:00', '2026-08-27 11:50:00'),
(16490, 1464, 1485, 'superLike', '2026-08-26 11:50:00', '2026-08-26 11:50:00'),
(16491, 1464, 1492, 'pass', '2026-08-25 11:50:00', '2026-08-25 11:50:00'),
(16492, 1464, 1499, 'like', '2026-08-24 11:50:00', '2026-08-24 11:50:00'),
(16493, 1464, 1506, 'like', '2026-08-23 11:50:00', '2026-08-23 11:50:00'),
(16494, 1464, 1513, 'pass', '2026-08-22 11:50:00', '2026-08-22 11:50:00'),
(16495, 1464, 1520, 'like', '2026-08-21 11:50:00', '2026-08-21 11:50:00'),
(16496, 1464, 1527, 'like', '2026-08-20 11:50:00', '2026-08-20 11:50:00'),
(16497, 1464, 1534, 'pass', '2026-08-19 11:50:00', '2026-08-19 11:50:00'),
(16498, 1465, 1472, 'pass', '2026-08-28 11:49:00', '2026-08-28 11:49:00'),
(16499, 1465, 1479, 'like', '2026-08-27 11:49:00', '2026-08-27 11:49:00'),
(16500, 1465, 1486, 'like', '2026-08-26 11:49:00', '2026-08-26 11:49:00'),
(16501, 1465, 1493, 'superLike', '2026-08-25 11:49:00', '2026-08-25 11:49:00'),
(16502, 1465, 1500, 'pass', '2026-08-24 11:49:00', '2026-08-24 11:49:00'),
(16503, 1465, 1507, 'like', '2026-08-23 11:49:00', '2026-08-23 11:49:00'),
(16504, 1465, 1514, 'like', '2026-08-22 11:49:00', '2026-08-22 11:49:00'),
(16505, 1465, 1521, 'pass', '2026-08-21 11:49:00', '2026-08-21 11:49:00'),
(16506, 1465, 1528, 'like', '2026-08-20 11:49:00', '2026-08-20 11:49:00'),
(16507, 1465, 1535, 'like', '2026-08-19 11:49:00', '2026-08-19 11:49:00'),
(16508, 1465, 1542, 'pass', '2026-08-18 11:49:00', '2026-08-18 11:49:00'),
(16509, 1466, 1473, 'like', '2026-08-28 11:48:00', '2026-08-28 11:48:00'),
(16510, 1466, 1480, 'pass', '2026-08-27 11:48:00', '2026-08-27 11:48:00'),
(16511, 1466, 1487, 'like', '2026-08-26 11:48:00', '2026-08-26 11:48:00'),
(16512, 1466, 1494, 'like', '2026-08-25 11:48:00', '2026-08-25 11:48:00'),
(16513, 1466, 1501, 'superLike', '2026-08-24 11:48:00', '2026-08-24 11:48:00'),
(16514, 1466, 1508, 'pass', '2026-08-23 11:48:00', '2026-08-23 11:48:00'),
(16515, 1466, 1515, 'like', '2026-08-22 11:48:00', '2026-08-22 11:48:00'),
(16516, 1466, 1522, 'like', '2026-08-21 11:48:00', '2026-08-21 11:48:00'),
(16517, 1466, 1529, 'pass', '2026-08-20 11:48:00', '2026-08-20 11:48:00'),
(16518, 1466, 1536, 'like', '2026-08-19 11:48:00', '2026-08-19 11:48:00'),
(16519, 1466, 1543, 'like', '2026-08-18 11:48:00', '2026-08-18 11:48:00'),
(16520, 1466, 1550, 'pass', '2026-08-17 11:48:00', '2026-08-17 11:48:00'),
(16521, 1467, 1474, 'like', '2026-08-28 11:47:00', '2026-08-28 11:47:00'),
(16522, 1467, 1481, 'like', '2026-08-27 11:47:00', '2026-08-27 11:47:00'),
(16523, 1467, 1488, 'pass', '2026-08-26 11:47:00', '2026-08-26 11:47:00'),
(16524, 1467, 1495, 'like', '2026-08-25 11:47:00', '2026-08-25 11:47:00'),
(16525, 1467, 1502, 'like', '2026-08-24 11:47:00', '2026-08-24 11:47:00'),
(16526, 1467, 1509, 'superLike', '2026-08-23 11:47:00', '2026-08-23 11:47:00'),
(16527, 1467, 1516, 'pass', '2026-08-22 11:47:00', '2026-08-22 11:47:00'),
(16528, 1467, 1523, 'like', '2026-08-21 11:47:00', '2026-08-21 11:47:00'),
(16529, 1467, 1530, 'like', '2026-08-20 11:47:00', '2026-08-20 11:47:00'),
(16530, 1467, 1537, 'pass', '2026-08-19 11:47:00', '2026-08-19 11:47:00'),
(16531, 1467, 1544, 'like', '2026-08-18 11:47:00', '2026-08-18 11:47:00'),
(16532, 1467, 1551, 'like', '2026-08-17 11:47:00', '2026-08-17 11:47:00'),
(16533, 1467, 1558, 'pass', '2026-08-16 11:47:00', '2026-08-16 11:47:00'),
(16534, 1468, 1475, 'pass', '2026-08-28 11:46:00', '2026-08-28 11:46:00'),
(16535, 1468, 1482, 'like', '2026-08-27 11:46:00', '2026-08-27 11:46:00'),
(16536, 1468, 1489, 'like', '2026-08-26 11:46:00', '2026-08-26 11:46:00'),
(16537, 1468, 1496, 'pass', '2026-08-25 11:46:00', '2026-08-25 11:46:00'),
(16538, 1468, 1503, 'like', '2026-08-24 11:46:00', '2026-08-24 11:46:00'),
(16539, 1468, 1510, 'like', '2026-08-23 11:46:00', '2026-08-23 11:46:00'),
(16540, 1468, 1517, 'superLike', '2026-08-22 11:46:00', '2026-08-22 11:46:00'),
(16541, 1468, 1524, 'pass', '2026-08-21 11:46:00', '2026-08-21 11:46:00'),
(16542, 1468, 1531, 'like', '2026-08-20 11:46:00', '2026-08-20 11:46:00'),
(16543, 1468, 1538, 'like', '2026-08-19 11:46:00', '2026-08-19 11:46:00'),
(16544, 1468, 1545, 'pass', '2026-08-18 11:46:00', '2026-08-18 11:46:00'),
(16545, 1468, 1552, 'like', '2026-08-17 11:46:00', '2026-08-17 11:46:00'),
(16546, 1468, 1559, 'like', '2026-08-16 11:46:00', '2026-08-16 11:46:00'),
(16547, 1468, 1566, 'pass', '2026-08-15 11:46:00', '2026-08-15 11:46:00'),
(16548, 1469, 1476, 'like', '2026-08-28 11:45:00', '2026-08-28 11:45:00'),
(16549, 1469, 1483, 'pass', '2026-08-27 11:45:00', '2026-08-27 11:45:00'),
(16550, 1469, 1490, 'like', '2026-08-26 11:45:00', '2026-08-26 11:45:00'),
(16551, 1469, 1497, 'like', '2026-08-25 11:45:00', '2026-08-25 11:45:00'),
(16552, 1469, 1504, 'pass', '2026-08-24 11:45:00', '2026-08-24 11:45:00'),
(16553, 1469, 1511, 'like', '2026-08-23 11:45:00', '2026-08-23 11:45:00'),
(16554, 1469, 1518, 'like', '2026-08-22 11:45:00', '2026-08-22 11:45:00'),
(16555, 1469, 1525, 'superLike', '2026-08-21 11:45:00', '2026-08-21 11:45:00'),
(16556, 1469, 1532, 'pass', '2026-08-20 11:45:00', '2026-08-20 11:45:00'),
(16557, 1469, 1539, 'like', '2026-08-19 11:45:00', '2026-08-19 11:45:00'),
(16558, 1469, 1546, 'like', '2026-08-18 11:45:00', '2026-08-18 11:45:00'),
(16559, 1469, 1553, 'pass', '2026-08-17 11:45:00', '2026-08-17 11:45:00'),
(16560, 1469, 1560, 'like', '2026-08-16 11:45:00', '2026-08-16 11:45:00'),
(16561, 1469, 1567, 'like', '2026-08-15 11:45:00', '2026-08-15 11:45:00'),
(16562, 1469, 1574, 'pass', '2026-08-14 11:45:00', '2026-08-14 11:45:00'),
(16563, 1470, 1477, 'like', '2026-08-28 11:44:00', '2026-08-28 11:44:00'),
(16564, 1470, 1484, 'like', '2026-08-27 11:44:00', '2026-08-27 11:44:00'),
(16565, 1470, 1491, 'pass', '2026-08-26 11:44:00', '2026-08-26 11:44:00'),
(16566, 1470, 1498, 'like', '2026-08-25 11:44:00', '2026-08-25 11:44:00'),
(16567, 1470, 1505, 'like', '2026-08-24 11:44:00', '2026-08-24 11:44:00'),
(16568, 1470, 1512, 'pass', '2026-08-23 11:44:00', '2026-08-23 11:44:00'),
(16569, 1470, 1519, 'like', '2026-08-22 11:44:00', '2026-08-22 11:44:00'),
(16570, 1470, 1526, 'like', '2026-08-21 11:44:00', '2026-08-21 11:44:00'),
(16571, 1471, 1478, 'pass', '2026-08-28 11:43:00', '2026-08-28 11:43:00'),
(16572, 1471, 1485, 'like', '2026-08-27 11:43:00', '2026-08-27 11:43:00'),
(16573, 1471, 1492, 'like', '2026-08-26 11:43:00', '2026-08-26 11:43:00'),
(16574, 1471, 1499, 'pass', '2026-08-25 11:43:00', '2026-08-25 11:43:00'),
(16575, 1471, 1506, 'like', '2026-08-24 11:43:00', '2026-08-24 11:43:00'),
(16576, 1471, 1513, 'like', '2026-08-23 11:43:00', '2026-08-23 11:43:00'),
(16577, 1471, 1520, 'pass', '2026-08-22 11:43:00', '2026-08-22 11:43:00'),
(16578, 1471, 1527, 'like', '2026-08-21 11:43:00', '2026-08-21 11:43:00'),
(16579, 1471, 1534, 'like', '2026-08-20 11:43:00', '2026-08-20 11:43:00'),
(16580, 1472, 1479, 'superLike', '2026-08-28 11:42:00', '2026-08-28 11:42:00'),
(16581, 1472, 1486, 'pass', '2026-08-27 11:42:00', '2026-08-27 11:42:00'),
(16582, 1472, 1493, 'like', '2026-08-26 11:42:00', '2026-08-26 11:42:00'),
(16583, 1472, 1500, 'like', '2026-08-25 11:42:00', '2026-08-25 11:42:00'),
(16584, 1472, 1507, 'pass', '2026-08-24 11:42:00', '2026-08-24 11:42:00'),
(16585, 1472, 1514, 'like', '2026-08-23 11:42:00', '2026-08-23 11:42:00'),
(16586, 1472, 1521, 'like', '2026-08-22 11:42:00', '2026-08-22 11:42:00'),
(16587, 1472, 1528, 'pass', '2026-08-21 11:42:00', '2026-08-21 11:42:00'),
(16588, 1472, 1535, 'like', '2026-08-20 11:42:00', '2026-08-20 11:42:00'),
(16589, 1472, 1542, 'like', '2026-08-19 11:42:00', '2026-08-19 11:42:00'),
(16590, 1473, 1480, 'like', '2026-08-28 11:41:00', '2026-08-28 11:41:00'),
(16591, 1473, 1487, 'superLike', '2026-08-27 11:41:00', '2026-08-27 11:41:00'),
(16592, 1473, 1494, 'pass', '2026-08-26 11:41:00', '2026-08-26 11:41:00'),
(16593, 1473, 1501, 'like', '2026-08-25 11:41:00', '2026-08-25 11:41:00'),
(16594, 1473, 1508, 'like', '2026-08-24 11:41:00', '2026-08-24 11:41:00'),
(16595, 1473, 1515, 'pass', '2026-08-23 11:41:00', '2026-08-23 11:41:00'),
(16596, 1473, 1522, 'like', '2026-08-22 11:41:00', '2026-08-22 11:41:00'),
(16597, 1473, 1529, 'like', '2026-08-21 11:41:00', '2026-08-21 11:41:00'),
(16598, 1473, 1536, 'pass', '2026-08-20 11:41:00', '2026-08-20 11:41:00'),
(16599, 1473, 1543, 'like', '2026-08-19 11:41:00', '2026-08-19 11:41:00'),
(16600, 1473, 1550, 'like', '2026-08-18 11:41:00', '2026-08-18 11:41:00'),
(16601, 1474, 1481, 'like', '2026-08-28 11:40:00', '2026-08-28 11:40:00'),
(16602, 1474, 1488, 'like', '2026-08-27 11:40:00', '2026-08-27 11:40:00'),
(16603, 1474, 1495, 'superLike', '2026-08-26 11:40:00', '2026-08-26 11:40:00'),
(16604, 1474, 1502, 'pass', '2026-08-25 11:40:00', '2026-08-25 11:40:00'),
(16605, 1474, 1509, 'like', '2026-08-24 11:40:00', '2026-08-24 11:40:00'),
(16606, 1474, 1516, 'like', '2026-08-23 11:40:00', '2026-08-23 11:40:00'),
(16607, 1474, 1523, 'pass', '2026-08-22 11:40:00', '2026-08-22 11:40:00'),
(16608, 1474, 1530, 'like', '2026-08-21 11:40:00', '2026-08-21 11:40:00'),
(16609, 1474, 1537, 'like', '2026-08-20 11:40:00', '2026-08-20 11:40:00'),
(16610, 1474, 1544, 'pass', '2026-08-19 11:40:00', '2026-08-19 11:40:00'),
(16611, 1474, 1551, 'like', '2026-08-18 11:40:00', '2026-08-18 11:40:00'),
(16612, 1474, 1558, 'like', '2026-08-17 11:40:00', '2026-08-17 11:40:00'),
(16613, 1475, 1482, 'pass', '2026-08-28 11:39:00', '2026-08-28 11:39:00'),
(16614, 1475, 1489, 'like', '2026-08-27 11:39:00', '2026-08-27 11:39:00'),
(16615, 1475, 1496, 'like', '2026-08-26 11:39:00', '2026-08-26 11:39:00'),
(16616, 1475, 1503, 'superLike', '2026-08-25 11:39:00', '2026-08-25 11:39:00'),
(16617, 1475, 1510, 'pass', '2026-08-24 11:39:00', '2026-08-24 11:39:00'),
(16618, 1475, 1517, 'like', '2026-08-23 11:39:00', '2026-08-23 11:39:00'),
(16619, 1475, 1524, 'like', '2026-08-22 11:39:00', '2026-08-22 11:39:00'),
(16620, 1475, 1531, 'pass', '2026-08-21 11:39:00', '2026-08-21 11:39:00'),
(16621, 1475, 1538, 'like', '2026-08-20 11:39:00', '2026-08-20 11:39:00'),
(16622, 1475, 1545, 'like', '2026-08-19 11:39:00', '2026-08-19 11:39:00'),
(16623, 1475, 1552, 'pass', '2026-08-18 11:39:00', '2026-08-18 11:39:00'),
(16624, 1475, 1559, 'like', '2026-08-17 11:39:00', '2026-08-17 11:39:00'),
(16625, 1475, 1566, 'like', '2026-08-16 11:39:00', '2026-08-16 11:39:00'),
(16626, 1476, 1483, 'like', '2026-08-28 11:38:00', '2026-08-28 11:38:00'),
(16627, 1476, 1490, 'pass', '2026-08-27 11:38:00', '2026-08-27 11:38:00'),
(16628, 1476, 1497, 'like', '2026-08-26 11:38:00', '2026-08-26 11:38:00'),
(16629, 1476, 1504, 'like', '2026-08-25 11:38:00', '2026-08-25 11:38:00'),
(16630, 1476, 1511, 'superLike', '2026-08-24 11:38:00', '2026-08-24 11:38:00'),
(16631, 1476, 1518, 'pass', '2026-08-23 11:38:00', '2026-08-23 11:38:00'),
(16632, 1476, 1525, 'like', '2026-08-22 11:38:00', '2026-08-22 11:38:00'),
(16633, 1476, 1532, 'like', '2026-08-21 11:38:00', '2026-08-21 11:38:00'),
(16634, 1476, 1539, 'pass', '2026-08-20 11:38:00', '2026-08-20 11:38:00'),
(16635, 1476, 1546, 'like', '2026-08-19 11:38:00', '2026-08-19 11:38:00'),
(16636, 1476, 1553, 'like', '2026-08-18 11:38:00', '2026-08-18 11:38:00'),
(16637, 1476, 1560, 'pass', '2026-08-17 11:38:00', '2026-08-17 11:38:00'),
(16638, 1476, 1567, 'like', '2026-08-16 11:38:00', '2026-08-16 11:38:00'),
(16639, 1476, 1574, 'like', '2026-08-15 11:38:00', '2026-08-15 11:38:00'),
(16640, 1477, 1484, 'like', '2026-08-28 11:37:00', '2026-08-28 11:37:00'),
(16641, 1477, 1491, 'like', '2026-08-27 11:37:00', '2026-08-27 11:37:00'),
(16642, 1477, 1498, 'pass', '2026-08-26 11:37:00', '2026-08-26 11:37:00'),
(16643, 1477, 1505, 'like', '2026-08-25 11:37:00', '2026-08-25 11:37:00'),
(16644, 1477, 1512, 'like', '2026-08-24 11:37:00', '2026-08-24 11:37:00'),
(16645, 1477, 1519, 'superLike', '2026-08-23 11:37:00', '2026-08-23 11:37:00'),
(16646, 1477, 1526, 'pass', '2026-08-22 11:37:00', '2026-08-22 11:37:00'),
(16647, 1477, 1533, 'like', '2026-08-21 11:37:00', '2026-08-21 11:37:00'),
(16648, 1477, 1540, 'like', '2026-08-20 11:37:00', '2026-08-20 11:37:00'),
(16649, 1477, 1547, 'pass', '2026-08-19 11:37:00', '2026-08-19 11:37:00'),
(16650, 1477, 1554, 'like', '2026-08-18 11:37:00', '2026-08-18 11:37:00'),
(16651, 1477, 1561, 'like', '2026-08-17 11:37:00', '2026-08-17 11:37:00'),
(16652, 1477, 1568, 'pass', '2026-08-16 11:37:00', '2026-08-16 11:37:00'),
(16653, 1477, 1575, 'like', '2026-08-15 11:37:00', '2026-08-15 11:37:00'),
(16654, 1477, 1582, 'like', '2026-08-14 11:37:00', '2026-08-14 11:37:00'),
(16655, 1478, 1485, 'pass', '2026-08-28 11:36:00', '2026-08-28 11:36:00'),
(16656, 1478, 1492, 'like', '2026-08-27 11:36:00', '2026-08-27 11:36:00'),
(16657, 1478, 1499, 'like', '2026-08-26 11:36:00', '2026-08-26 11:36:00'),
(16658, 1478, 1506, 'pass', '2026-08-25 11:36:00', '2026-08-25 11:36:00'),
(16659, 1478, 1513, 'like', '2026-08-24 11:36:00', '2026-08-24 11:36:00'),
(16660, 1478, 1520, 'like', '2026-08-23 11:36:00', '2026-08-23 11:36:00'),
(16661, 1478, 1527, 'superLike', '2026-08-22 11:36:00', '2026-08-22 11:36:00'),
(16662, 1478, 1534, 'pass', '2026-08-21 11:36:00', '2026-08-21 11:36:00'),
(16663, 1479, 1486, 'like', '2026-08-28 11:35:00', '2026-08-28 11:35:00'),
(16664, 1479, 1493, 'pass', '2026-08-27 11:35:00', '2026-08-27 11:35:00'),
(16665, 1479, 1500, 'like', '2026-08-26 11:35:00', '2026-08-26 11:35:00'),
(16666, 1479, 1507, 'like', '2026-08-25 11:35:00', '2026-08-25 11:35:00'),
(16667, 1479, 1514, 'pass', '2026-08-24 11:35:00', '2026-08-24 11:35:00'),
(16668, 1479, 1521, 'like', '2026-08-23 11:35:00', '2026-08-23 11:35:00'),
(16669, 1479, 1528, 'like', '2026-08-22 11:35:00', '2026-08-22 11:35:00'),
(16670, 1479, 1535, 'superLike', '2026-08-21 11:35:00', '2026-08-21 11:35:00'),
(16671, 1479, 1542, 'pass', '2026-08-20 11:35:00', '2026-08-20 11:35:00'),
(16672, 1480, 1487, 'like', '2026-08-28 11:34:00', '2026-08-28 11:34:00'),
(16673, 1480, 1494, 'like', '2026-08-27 11:34:00', '2026-08-27 11:34:00'),
(16674, 1480, 1501, 'pass', '2026-08-26 11:34:00', '2026-08-26 11:34:00'),
(16675, 1480, 1508, 'like', '2026-08-25 11:34:00', '2026-08-25 11:34:00'),
(16676, 1480, 1515, 'like', '2026-08-24 11:34:00', '2026-08-24 11:34:00'),
(16677, 1480, 1522, 'pass', '2026-08-23 11:34:00', '2026-08-23 11:34:00'),
(16678, 1480, 1529, 'like', '2026-08-22 11:34:00', '2026-08-22 11:34:00'),
(16679, 1480, 1536, 'like', '2026-08-21 11:34:00', '2026-08-21 11:34:00'),
(16680, 1480, 1543, 'superLike', '2026-08-20 11:34:00', '2026-08-20 11:34:00'),
(16681, 1480, 1550, 'pass', '2026-08-19 11:34:00', '2026-08-19 11:34:00'),
(16682, 1481, 1488, 'pass', '2026-08-28 11:33:00', '2026-08-28 11:33:00'),
(16683, 1481, 1495, 'like', '2026-08-27 11:33:00', '2026-08-27 11:33:00'),
(16684, 1481, 1502, 'like', '2026-08-26 11:33:00', '2026-08-26 11:33:00'),
(16685, 1481, 1509, 'pass', '2026-08-25 11:33:00', '2026-08-25 11:33:00'),
(16686, 1481, 1516, 'like', '2026-08-24 11:33:00', '2026-08-24 11:33:00'),
(16687, 1481, 1523, 'like', '2026-08-23 11:33:00', '2026-08-23 11:33:00'),
(16688, 1481, 1530, 'pass', '2026-08-22 11:33:00', '2026-08-22 11:33:00'),
(16689, 1481, 1537, 'like', '2026-08-21 11:33:00', '2026-08-21 11:33:00'),
(16690, 1481, 1544, 'like', '2026-08-20 11:33:00', '2026-08-20 11:33:00'),
(16691, 1481, 1551, 'superLike', '2026-08-19 11:33:00', '2026-08-19 11:33:00'),
(16692, 1481, 1558, 'pass', '2026-08-18 11:33:00', '2026-08-18 11:33:00'),
(16693, 1482, 1489, 'superLike', '2026-08-28 11:32:00', '2026-08-28 11:32:00'),
(16694, 1482, 1496, 'pass', '2026-08-27 11:32:00', '2026-08-27 11:32:00'),
(16695, 1482, 1503, 'like', '2026-08-26 11:32:00', '2026-08-26 11:32:00'),
(16696, 1482, 1510, 'like', '2026-08-25 11:32:00', '2026-08-25 11:32:00'),
(16697, 1482, 1517, 'pass', '2026-08-24 11:32:00', '2026-08-24 11:32:00'),
(16698, 1482, 1524, 'like', '2026-08-23 11:32:00', '2026-08-23 11:32:00'),
(16699, 1482, 1531, 'like', '2026-08-22 11:32:00', '2026-08-22 11:32:00'),
(16700, 1482, 1538, 'pass', '2026-08-21 11:32:00', '2026-08-21 11:32:00'),
(16701, 1482, 1545, 'like', '2026-08-20 11:32:00', '2026-08-20 11:32:00'),
(16702, 1482, 1552, 'like', '2026-08-19 11:32:00', '2026-08-19 11:32:00'),
(16703, 1482, 1559, 'superLike', '2026-08-18 11:32:00', '2026-08-18 11:32:00'),
(16704, 1482, 1566, 'pass', '2026-08-17 11:32:00', '2026-08-17 11:32:00'),
(16705, 1483, 1490, 'like', '2026-08-28 11:31:00', '2026-08-28 11:31:00'),
(16706, 1483, 1497, 'superLike', '2026-08-27 11:31:00', '2026-08-27 11:31:00'),
(16707, 1483, 1504, 'pass', '2026-08-26 11:31:00', '2026-08-26 11:31:00'),
(16708, 1483, 1511, 'like', '2026-08-25 11:31:00', '2026-08-25 11:31:00'),
(16709, 1483, 1518, 'like', '2026-08-24 11:31:00', '2026-08-24 11:31:00'),
(16710, 1483, 1525, 'pass', '2026-08-23 11:31:00', '2026-08-23 11:31:00'),
(16711, 1483, 1532, 'like', '2026-08-22 11:31:00', '2026-08-22 11:31:00'),
(16712, 1483, 1539, 'like', '2026-08-21 11:31:00', '2026-08-21 11:31:00'),
(16713, 1483, 1546, 'pass', '2026-08-20 11:31:00', '2026-08-20 11:31:00'),
(16714, 1483, 1553, 'like', '2026-08-19 11:31:00', '2026-08-19 11:31:00'),
(16715, 1483, 1560, 'like', '2026-08-18 11:31:00', '2026-08-18 11:31:00'),
(16716, 1483, 1567, 'superLike', '2026-08-17 11:31:00', '2026-08-17 11:31:00'),
(16717, 1483, 1574, 'pass', '2026-08-16 11:31:00', '2026-08-16 11:31:00'),
(16718, 1484, 1491, 'like', '2026-08-28 11:30:00', '2026-08-28 11:30:00'),
(16719, 1484, 1498, 'like', '2026-08-27 11:30:00', '2026-08-27 11:30:00'),
(16720, 1484, 1505, 'superLike', '2026-08-26 11:30:00', '2026-08-26 11:30:00'),
(16721, 1484, 1512, 'pass', '2026-08-25 11:30:00', '2026-08-25 11:30:00'),
(16722, 1484, 1519, 'like', '2026-08-24 11:30:00', '2026-08-24 11:30:00'),
(16723, 1484, 1526, 'like', '2026-08-23 11:30:00', '2026-08-23 11:30:00'),
(16724, 1484, 1533, 'pass', '2026-08-22 11:30:00', '2026-08-22 11:30:00'),
(16725, 1484, 1540, 'like', '2026-08-21 11:30:00', '2026-08-21 11:30:00'),
(16726, 1484, 1547, 'like', '2026-08-20 11:30:00', '2026-08-20 11:30:00'),
(16727, 1484, 1554, 'pass', '2026-08-19 11:30:00', '2026-08-19 11:30:00'),
(16728, 1484, 1561, 'like', '2026-08-18 11:30:00', '2026-08-18 11:30:00'),
(16729, 1484, 1568, 'like', '2026-08-17 11:30:00', '2026-08-17 11:30:00'),
(16730, 1484, 1575, 'superLike', '2026-08-16 11:30:00', '2026-08-16 11:30:00'),
(16731, 1484, 1582, 'pass', '2026-08-15 11:30:00', '2026-08-15 11:30:00'),
(16732, 1485, 1492, 'pass', '2026-08-28 11:29:00', '2026-08-28 11:29:00'),
(16733, 1485, 1499, 'like', '2026-08-27 11:29:00', '2026-08-27 11:29:00'),
(16734, 1485, 1506, 'like', '2026-08-26 11:29:00', '2026-08-26 11:29:00'),
(16735, 1485, 1513, 'superLike', '2026-08-25 11:29:00', '2026-08-25 11:29:00'),
(16736, 1485, 1520, 'pass', '2026-08-24 11:29:00', '2026-08-24 11:29:00'),
(16737, 1485, 1527, 'like', '2026-08-23 11:29:00', '2026-08-23 11:29:00'),
(16738, 1485, 1534, 'like', '2026-08-22 11:29:00', '2026-08-22 11:29:00'),
(16739, 1485, 1541, 'pass', '2026-08-21 11:29:00', '2026-08-21 11:29:00'),
(16740, 1485, 1548, 'like', '2026-08-20 11:29:00', '2026-08-20 11:29:00'),
(16741, 1485, 1555, 'like', '2026-08-19 11:29:00', '2026-08-19 11:29:00'),
(16742, 1485, 1562, 'pass', '2026-08-18 11:29:00', '2026-08-18 11:29:00'),
(16743, 1485, 1569, 'like', '2026-08-17 11:29:00', '2026-08-17 11:29:00'),
(16744, 1485, 1576, 'like', '2026-08-16 11:29:00', '2026-08-16 11:29:00'),
(16745, 1485, 1583, 'superLike', '2026-08-15 11:29:00', '2026-08-15 11:29:00'),
(16746, 1485, 1590, 'pass', '2026-08-14 11:29:00', '2026-08-14 11:29:00'),
(16747, 1486, 1493, 'like', '2026-08-28 11:28:00', '2026-08-28 11:28:00'),
(16748, 1486, 1500, 'pass', '2026-08-27 11:28:00', '2026-08-27 11:28:00'),
(16749, 1486, 1507, 'like', '2026-08-26 11:28:00', '2026-08-26 11:28:00'),
(16750, 1486, 1514, 'like', '2026-08-25 11:28:00', '2026-08-25 11:28:00'),
(16751, 1486, 1521, 'superLike', '2026-08-24 11:28:00', '2026-08-24 11:28:00'),
(16752, 1486, 1528, 'pass', '2026-08-23 11:28:00', '2026-08-23 11:28:00'),
(16753, 1486, 1535, 'like', '2026-08-22 11:28:00', '2026-08-22 11:28:00'),
(16754, 1486, 1542, 'like', '2026-08-21 11:28:00', '2026-08-21 11:28:00'),
(16755, 1487, 1494, 'like', '2026-08-28 11:27:00', '2026-08-28 11:27:00'),
(16756, 1487, 1501, 'like', '2026-08-27 11:27:00', '2026-08-27 11:27:00'),
(16757, 1487, 1508, 'pass', '2026-08-26 11:27:00', '2026-08-26 11:27:00'),
(16758, 1487, 1515, 'like', '2026-08-25 11:27:00', '2026-08-25 11:27:00'),
(16759, 1487, 1522, 'like', '2026-08-24 11:27:00', '2026-08-24 11:27:00'),
(16760, 1487, 1529, 'superLike', '2026-08-23 11:27:00', '2026-08-23 11:27:00'),
(16761, 1487, 1536, 'pass', '2026-08-22 11:27:00', '2026-08-22 11:27:00'),
(16762, 1487, 1543, 'like', '2026-08-21 11:27:00', '2026-08-21 11:27:00'),
(16763, 1487, 1550, 'like', '2026-08-20 11:27:00', '2026-08-20 11:27:00'),
(16764, 1488, 1495, 'pass', '2026-08-28 11:26:00', '2026-08-28 11:26:00'),
(16765, 1488, 1502, 'like', '2026-08-27 11:26:00', '2026-08-27 11:26:00'),
(16766, 1488, 1509, 'like', '2026-08-26 11:26:00', '2026-08-26 11:26:00'),
(16767, 1488, 1516, 'pass', '2026-08-25 11:26:00', '2026-08-25 11:26:00'),
(16768, 1488, 1523, 'like', '2026-08-24 11:26:00', '2026-08-24 11:26:00'),
(16769, 1488, 1530, 'like', '2026-08-23 11:26:00', '2026-08-23 11:26:00'),
(16770, 1488, 1537, 'superLike', '2026-08-22 11:26:00', '2026-08-22 11:26:00'),
(16771, 1488, 1544, 'pass', '2026-08-21 11:26:00', '2026-08-21 11:26:00'),
(16772, 1488, 1551, 'like', '2026-08-20 11:26:00', '2026-08-20 11:26:00'),
(16773, 1488, 1558, 'like', '2026-08-19 11:26:00', '2026-08-19 11:26:00'),
(16774, 1489, 1496, 'like', '2026-08-28 11:25:00', '2026-08-28 11:25:00'),
(16775, 1489, 1503, 'pass', '2026-08-27 11:25:00', '2026-08-27 11:25:00'),
(16776, 1489, 1510, 'like', '2026-08-26 11:25:00', '2026-08-26 11:25:00'),
(16777, 1489, 1517, 'like', '2026-08-25 11:25:00', '2026-08-25 11:25:00'),
(16778, 1489, 1524, 'pass', '2026-08-24 11:25:00', '2026-08-24 11:25:00'),
(16779, 1489, 1531, 'like', '2026-08-23 11:25:00', '2026-08-23 11:25:00'),
(16780, 1489, 1538, 'like', '2026-08-22 11:25:00', '2026-08-22 11:25:00'),
(16781, 1489, 1545, 'superLike', '2026-08-21 11:25:00', '2026-08-21 11:25:00'),
(16782, 1489, 1552, 'pass', '2026-08-20 11:25:00', '2026-08-20 11:25:00'),
(16783, 1489, 1559, 'like', '2026-08-19 11:25:00', '2026-08-19 11:25:00'),
(16784, 1489, 1566, 'like', '2026-08-18 11:25:00', '2026-08-18 11:25:00'),
(16785, 1490, 1497, 'like', '2026-08-28 11:24:00', '2026-08-28 11:24:00'),
(16786, 1490, 1504, 'like', '2026-08-27 11:24:00', '2026-08-27 11:24:00'),
(16787, 1490, 1511, 'pass', '2026-08-26 11:24:00', '2026-08-26 11:24:00'),
(16788, 1490, 1518, 'like', '2026-08-25 11:24:00', '2026-08-25 11:24:00'),
(16789, 1490, 1525, 'like', '2026-08-24 11:24:00', '2026-08-24 11:24:00'),
(16790, 1490, 1532, 'pass', '2026-08-23 11:24:00', '2026-08-23 11:24:00'),
(16791, 1490, 1539, 'like', '2026-08-22 11:24:00', '2026-08-22 11:24:00'),
(16792, 1490, 1546, 'like', '2026-08-21 11:24:00', '2026-08-21 11:24:00'),
(16793, 1490, 1553, 'superLike', '2026-08-20 11:24:00', '2026-08-20 11:24:00'),
(16794, 1490, 1560, 'pass', '2026-08-19 11:24:00', '2026-08-19 11:24:00'),
(16795, 1490, 1567, 'like', '2026-08-18 11:24:00', '2026-08-18 11:24:00'),
(16796, 1490, 1574, 'like', '2026-08-17 11:24:00', '2026-08-17 11:24:00'),
(16797, 1491, 1498, 'pass', '2026-08-28 11:23:00', '2026-08-28 11:23:00'),
(16798, 1491, 1505, 'like', '2026-08-27 11:23:00', '2026-08-27 11:23:00'),
(16799, 1491, 1512, 'like', '2026-08-26 11:23:00', '2026-08-26 11:23:00'),
(16800, 1491, 1519, 'pass', '2026-08-25 11:23:00', '2026-08-25 11:23:00'),
(16801, 1491, 1526, 'like', '2026-08-24 11:23:00', '2026-08-24 11:23:00'),
(16802, 1491, 1533, 'like', '2026-08-23 11:23:00', '2026-08-23 11:23:00'),
(16803, 1491, 1540, 'pass', '2026-08-22 11:23:00', '2026-08-22 11:23:00'),
(16804, 1491, 1547, 'like', '2026-08-21 11:23:00', '2026-08-21 11:23:00'),
(16805, 1491, 1554, 'like', '2026-08-20 11:23:00', '2026-08-20 11:23:00'),
(16806, 1491, 1561, 'superLike', '2026-08-19 11:23:00', '2026-08-19 11:23:00'),
(16807, 1491, 1568, 'pass', '2026-08-18 11:23:00', '2026-08-18 11:23:00'),
(16808, 1491, 1575, 'like', '2026-08-17 11:23:00', '2026-08-17 11:23:00'),
(16809, 1491, 1582, 'like', '2026-08-16 11:23:00', '2026-08-16 11:23:00'),
(16810, 1492, 1499, 'superLike', '2026-08-28 11:22:00', '2026-08-28 11:22:00'),
(16811, 1492, 1506, 'pass', '2026-08-27 11:22:00', '2026-08-27 11:22:00'),
(16812, 1492, 1513, 'like', '2026-08-26 11:22:00', '2026-08-26 11:22:00'),
(16813, 1492, 1520, 'like', '2026-08-25 11:22:00', '2026-08-25 11:22:00'),
(16814, 1492, 1527, 'pass', '2026-08-24 11:22:00', '2026-08-24 11:22:00'),
(16815, 1492, 1534, 'like', '2026-08-23 11:22:00', '2026-08-23 11:22:00'),
(16816, 1492, 1541, 'like', '2026-08-22 11:22:00', '2026-08-22 11:22:00'),
(16817, 1492, 1548, 'pass', '2026-08-21 11:22:00', '2026-08-21 11:22:00'),
(16818, 1492, 1555, 'like', '2026-08-20 11:22:00', '2026-08-20 11:22:00'),
(16819, 1492, 1562, 'like', '2026-08-19 11:22:00', '2026-08-19 11:22:00'),
(16820, 1492, 1569, 'superLike', '2026-08-18 11:22:00', '2026-08-18 11:22:00'),
(16821, 1492, 1576, 'pass', '2026-08-17 11:22:00', '2026-08-17 11:22:00'),
(16822, 1492, 1583, 'like', '2026-08-16 11:22:00', '2026-08-16 11:22:00'),
(16823, 1492, 1590, 'like', '2026-08-15 11:22:00', '2026-08-15 11:22:00'),
(16824, 1493, 1500, 'like', '2026-08-28 11:21:00', '2026-08-28 11:21:00'),
(16825, 1493, 1507, 'superLike', '2026-08-27 11:21:00', '2026-08-27 11:21:00'),
(16826, 1493, 1514, 'pass', '2026-08-26 11:21:00', '2026-08-26 11:21:00'),
(16827, 1493, 1521, 'like', '2026-08-25 11:21:00', '2026-08-25 11:21:00'),
(16828, 1493, 1528, 'like', '2026-08-24 11:21:00', '2026-08-24 11:21:00'),
(16829, 1493, 1535, 'pass', '2026-08-23 11:21:00', '2026-08-23 11:21:00'),
(16830, 1493, 1542, 'like', '2026-08-22 11:21:00', '2026-08-22 11:21:00'),
(16831, 1493, 1549, 'like', '2026-08-21 11:21:00', '2026-08-21 11:21:00'),
(16832, 1493, 1556, 'pass', '2026-08-20 11:21:00', '2026-08-20 11:21:00'),
(16833, 1493, 1563, 'like', '2026-08-19 11:21:00', '2026-08-19 11:21:00'),
(16834, 1493, 1570, 'like', '2026-08-18 11:21:00', '2026-08-18 11:21:00'),
(16835, 1493, 1577, 'superLike', '2026-08-17 11:21:00', '2026-08-17 11:21:00'),
(16836, 1493, 1584, 'pass', '2026-08-16 11:21:00', '2026-08-16 11:21:00'),
(16837, 1493, 1591, 'like', '2026-08-15 11:21:00', '2026-08-15 11:21:00'),
(16838, 1493, 1598, 'like', '2026-08-14 11:21:00', '2026-08-14 11:21:00'),
(16839, 1494, 1501, 'like', '2026-08-28 11:20:00', '2026-08-28 11:20:00'),
(16840, 1494, 1508, 'like', '2026-08-27 11:20:00', '2026-08-27 11:20:00'),
(16841, 1494, 1515, 'superLike', '2026-08-26 11:20:00', '2026-08-26 11:20:00'),
(16842, 1494, 1522, 'pass', '2026-08-25 11:20:00', '2026-08-25 11:20:00'),
(16843, 1494, 1529, 'like', '2026-08-24 11:20:00', '2026-08-24 11:20:00'),
(16844, 1494, 1536, 'like', '2026-08-23 11:20:00', '2026-08-23 11:20:00'),
(16845, 1494, 1543, 'pass', '2026-08-22 11:20:00', '2026-08-22 11:20:00'),
(16846, 1494, 1550, 'like', '2026-08-21 11:20:00', '2026-08-21 11:20:00'),
(16847, 1495, 1502, 'pass', '2026-08-28 11:19:00', '2026-08-28 11:19:00'),
(16848, 1495, 1509, 'like', '2026-08-27 11:19:00', '2026-08-27 11:19:00'),
(16849, 1495, 1516, 'like', '2026-08-26 11:19:00', '2026-08-26 11:19:00'),
(16850, 1495, 1523, 'superLike', '2026-08-25 11:19:00', '2026-08-25 11:19:00'),
(16851, 1495, 1530, 'pass', '2026-08-24 11:19:00', '2026-08-24 11:19:00'),
(16852, 1495, 1537, 'like', '2026-08-23 11:19:00', '2026-08-23 11:19:00'),
(16853, 1495, 1544, 'like', '2026-08-22 11:19:00', '2026-08-22 11:19:00'),
(16854, 1495, 1551, 'pass', '2026-08-21 11:19:00', '2026-08-21 11:19:00'),
(16855, 1495, 1558, 'like', '2026-08-20 11:19:00', '2026-08-20 11:19:00'),
(16856, 1496, 1503, 'like', '2026-08-28 11:18:00', '2026-08-28 11:18:00'),
(16857, 1496, 1510, 'pass', '2026-08-27 11:18:00', '2026-08-27 11:18:00'),
(16858, 1496, 1517, 'like', '2026-08-26 11:18:00', '2026-08-26 11:18:00'),
(16859, 1496, 1524, 'like', '2026-08-25 11:18:00', '2026-08-25 11:18:00'),
(16860, 1496, 1531, 'superLike', '2026-08-24 11:18:00', '2026-08-24 11:18:00'),
(16861, 1496, 1538, 'pass', '2026-08-23 11:18:00', '2026-08-23 11:18:00'),
(16862, 1496, 1545, 'like', '2026-08-22 11:18:00', '2026-08-22 11:18:00'),
(16863, 1496, 1552, 'like', '2026-08-21 11:18:00', '2026-08-21 11:18:00'),
(16864, 1496, 1559, 'pass', '2026-08-20 11:18:00', '2026-08-20 11:18:00'),
(16865, 1496, 1566, 'like', '2026-08-19 11:18:00', '2026-08-19 11:18:00'),
(16866, 1497, 1504, 'like', '2026-08-28 11:17:00', '2026-08-28 11:17:00'),
(16867, 1497, 1511, 'like', '2026-08-27 11:17:00', '2026-08-27 11:17:00'),
(16868, 1497, 1518, 'pass', '2026-08-26 11:17:00', '2026-08-26 11:17:00'),
(16869, 1497, 1525, 'like', '2026-08-25 11:17:00', '2026-08-25 11:17:00'),
(16870, 1497, 1532, 'like', '2026-08-24 11:17:00', '2026-08-24 11:17:00'),
(16871, 1497, 1539, 'superLike', '2026-08-23 11:17:00', '2026-08-23 11:17:00'),
(16872, 1497, 1546, 'pass', '2026-08-22 11:17:00', '2026-08-22 11:17:00'),
(16873, 1497, 1553, 'like', '2026-08-21 11:17:00', '2026-08-21 11:17:00'),
(16874, 1497, 1560, 'like', '2026-08-20 11:17:00', '2026-08-20 11:17:00'),
(16875, 1497, 1567, 'pass', '2026-08-19 11:17:00', '2026-08-19 11:17:00'),
(16876, 1497, 1574, 'like', '2026-08-18 11:17:00', '2026-08-18 11:17:00'),
(16877, 1498, 1505, 'pass', '2026-08-28 11:16:00', '2026-08-28 11:16:00'),
(16878, 1498, 1512, 'like', '2026-08-27 11:16:00', '2026-08-27 11:16:00'),
(16879, 1498, 1519, 'like', '2026-08-26 11:16:00', '2026-08-26 11:16:00'),
(16880, 1498, 1526, 'pass', '2026-08-25 11:16:00', '2026-08-25 11:16:00'),
(16881, 1498, 1533, 'like', '2026-08-24 11:16:00', '2026-08-24 11:16:00'),
(16882, 1498, 1540, 'like', '2026-08-23 11:16:00', '2026-08-23 11:16:00'),
(16883, 1498, 1547, 'superLike', '2026-08-22 11:16:00', '2026-08-22 11:16:00'),
(16884, 1498, 1554, 'pass', '2026-08-21 11:16:00', '2026-08-21 11:16:00'),
(16885, 1498, 1561, 'like', '2026-08-20 11:16:00', '2026-08-20 11:16:00'),
(16886, 1498, 1568, 'like', '2026-08-19 11:16:00', '2026-08-19 11:16:00'),
(16887, 1498, 1575, 'pass', '2026-08-18 11:16:00', '2026-08-18 11:16:00'),
(16888, 1498, 1582, 'like', '2026-08-17 11:16:00', '2026-08-17 11:16:00'),
(16889, 1499, 1506, 'like', '2026-08-28 11:15:00', '2026-08-28 11:15:00'),
(16890, 1499, 1513, 'pass', '2026-08-27 11:15:00', '2026-08-27 11:15:00'),
(16891, 1499, 1520, 'like', '2026-08-26 11:15:00', '2026-08-26 11:15:00'),
(16892, 1499, 1527, 'like', '2026-08-25 11:15:00', '2026-08-25 11:15:00'),
(16893, 1499, 1534, 'pass', '2026-08-24 11:15:00', '2026-08-24 11:15:00'),
(16894, 1499, 1541, 'like', '2026-08-23 11:15:00', '2026-08-23 11:15:00'),
(16895, 1499, 1548, 'like', '2026-08-22 11:15:00', '2026-08-22 11:15:00'),
(16896, 1499, 1555, 'superLike', '2026-08-21 11:15:00', '2026-08-21 11:15:00'),
(16897, 1499, 1562, 'pass', '2026-08-20 11:15:00', '2026-08-20 11:15:00'),
(16898, 1499, 1569, 'like', '2026-08-19 11:15:00', '2026-08-19 11:15:00'),
(16899, 1499, 1576, 'like', '2026-08-18 11:15:00', '2026-08-18 11:15:00'),
(16900, 1499, 1583, 'pass', '2026-08-17 11:15:00', '2026-08-17 11:15:00'),
(16901, 1499, 1590, 'like', '2026-08-16 11:15:00', '2026-08-16 11:15:00'),
(16902, 1500, 1507, 'like', '2026-08-28 11:14:00', '2026-08-28 11:14:00'),
(16903, 1500, 1514, 'like', '2026-08-27 11:14:00', '2026-08-27 11:14:00'),
(16904, 1500, 1521, 'pass', '2026-08-26 11:14:00', '2026-08-26 11:14:00'),
(16905, 1500, 1528, 'like', '2026-08-25 11:14:00', '2026-08-25 11:14:00'),
(16906, 1500, 1535, 'like', '2026-08-24 11:14:00', '2026-08-24 11:14:00'),
(16907, 1500, 1542, 'pass', '2026-08-23 11:14:00', '2026-08-23 11:14:00'),
(16908, 1500, 1549, 'like', '2026-08-22 11:14:00', '2026-08-22 11:14:00'),
(16909, 1500, 1556, 'like', '2026-08-21 11:14:00', '2026-08-21 11:14:00'),
(16910, 1500, 1563, 'superLike', '2026-08-20 11:14:00', '2026-08-20 11:14:00'),
(16911, 1500, 1570, 'pass', '2026-08-19 11:14:00', '2026-08-19 11:14:00'),
(16912, 1500, 1577, 'like', '2026-08-18 11:14:00', '2026-08-18 11:14:00'),
(16913, 1500, 1584, 'like', '2026-08-17 11:14:00', '2026-08-17 11:14:00'),
(16914, 1500, 1591, 'pass', '2026-08-16 11:14:00', '2026-08-16 11:14:00'),
(16915, 1500, 1598, 'like', '2026-08-15 11:14:00', '2026-08-15 11:14:00'),
(16916, 1501, 1508, 'pass', '2026-08-28 11:13:00', '2026-08-28 11:13:00'),
(16917, 1501, 1515, 'like', '2026-08-27 11:13:00', '2026-08-27 11:13:00'),
(16918, 1501, 1522, 'like', '2026-08-26 11:13:00', '2026-08-26 11:13:00'),
(16919, 1501, 1529, 'pass', '2026-08-25 11:13:00', '2026-08-25 11:13:00'),
(16920, 1501, 1536, 'like', '2026-08-24 11:13:00', '2026-08-24 11:13:00'),
(16921, 1501, 1543, 'like', '2026-08-23 11:13:00', '2026-08-23 11:13:00'),
(16922, 1501, 1550, 'pass', '2026-08-22 11:13:00', '2026-08-22 11:13:00'),
(16923, 1501, 1557, 'like', '2026-08-21 11:13:00', '2026-08-21 11:13:00'),
(16924, 1501, 1564, 'like', '2026-08-20 11:13:00', '2026-08-20 11:13:00'),
(16925, 1501, 1571, 'superLike', '2026-08-19 11:13:00', '2026-08-19 11:13:00'),
(16926, 1501, 1578, 'pass', '2026-08-18 11:13:00', '2026-08-18 11:13:00'),
(16927, 1501, 1585, 'like', '2026-08-17 11:13:00', '2026-08-17 11:13:00'),
(16928, 1501, 1592, 'like', '2026-08-16 11:13:00', '2026-08-16 11:13:00'),
(16929, 1501, 1599, 'pass', '2026-08-15 11:13:00', '2026-08-15 11:13:00'),
(16930, 1501, 1456, 'like', '2026-08-14 11:13:00', '2026-08-14 11:13:00'),
(16931, 1502, 1509, 'superLike', '2026-08-28 11:12:00', '2026-08-28 11:12:00'),
(16932, 1502, 1516, 'pass', '2026-08-27 11:12:00', '2026-08-27 11:12:00'),
(16933, 1502, 1523, 'like', '2026-08-26 11:12:00', '2026-08-26 11:12:00'),
(16934, 1502, 1530, 'like', '2026-08-25 11:12:00', '2026-08-25 11:12:00'),
(16935, 1502, 1537, 'pass', '2026-08-24 11:12:00', '2026-08-24 11:12:00'),
(16936, 1502, 1544, 'like', '2026-08-23 11:12:00', '2026-08-23 11:12:00'),
(16937, 1502, 1551, 'like', '2026-08-22 11:12:00', '2026-08-22 11:12:00'),
(16938, 1502, 1558, 'pass', '2026-08-21 11:12:00', '2026-08-21 11:12:00'),
(16939, 1503, 1510, 'like', '2026-08-28 11:11:00', '2026-08-28 11:11:00'),
(16940, 1503, 1517, 'superLike', '2026-08-27 11:11:00', '2026-08-27 11:11:00'),
(16941, 1503, 1524, 'pass', '2026-08-26 11:11:00', '2026-08-26 11:11:00'),
(16942, 1503, 1531, 'like', '2026-08-25 11:11:00', '2026-08-25 11:11:00'),
(16943, 1503, 1538, 'like', '2026-08-24 11:11:00', '2026-08-24 11:11:00'),
(16944, 1503, 1545, 'pass', '2026-08-23 11:11:00', '2026-08-23 11:11:00'),
(16945, 1503, 1552, 'like', '2026-08-22 11:11:00', '2026-08-22 11:11:00'),
(16946, 1503, 1559, 'like', '2026-08-21 11:11:00', '2026-08-21 11:11:00'),
(16947, 1503, 1566, 'pass', '2026-08-20 11:11:00', '2026-08-20 11:11:00'),
(16948, 1504, 1511, 'like', '2026-08-28 11:10:00', '2026-08-28 11:10:00'),
(16949, 1504, 1518, 'like', '2026-08-27 11:10:00', '2026-08-27 11:10:00'),
(16950, 1504, 1525, 'superLike', '2026-08-26 11:10:00', '2026-08-26 11:10:00'),
(16951, 1504, 1532, 'pass', '2026-08-25 11:10:00', '2026-08-25 11:10:00'),
(16952, 1504, 1539, 'like', '2026-08-24 11:10:00', '2026-08-24 11:10:00'),
(16953, 1504, 1546, 'like', '2026-08-23 11:10:00', '2026-08-23 11:10:00'),
(16954, 1504, 1553, 'pass', '2026-08-22 11:10:00', '2026-08-22 11:10:00'),
(16955, 1504, 1560, 'like', '2026-08-21 11:10:00', '2026-08-21 11:10:00'),
(16956, 1504, 1567, 'like', '2026-08-20 11:10:00', '2026-08-20 11:10:00'),
(16957, 1504, 1574, 'pass', '2026-08-19 11:10:00', '2026-08-19 11:10:00'),
(16958, 1505, 1512, 'pass', '2026-08-28 11:09:00', '2026-08-28 11:09:00'),
(16959, 1505, 1519, 'like', '2026-08-27 11:09:00', '2026-08-27 11:09:00'),
(16960, 1505, 1526, 'like', '2026-08-26 11:09:00', '2026-08-26 11:09:00'),
(16961, 1505, 1533, 'superLike', '2026-08-25 11:09:00', '2026-08-25 11:09:00'),
(16962, 1505, 1540, 'pass', '2026-08-24 11:09:00', '2026-08-24 11:09:00'),
(16963, 1505, 1547, 'like', '2026-08-23 11:09:00', '2026-08-23 11:09:00'),
(16964, 1505, 1554, 'like', '2026-08-22 11:09:00', '2026-08-22 11:09:00'),
(16965, 1505, 1561, 'pass', '2026-08-21 11:09:00', '2026-08-21 11:09:00'),
(16966, 1505, 1568, 'like', '2026-08-20 11:09:00', '2026-08-20 11:09:00'),
(16967, 1505, 1575, 'like', '2026-08-19 11:09:00', '2026-08-19 11:09:00'),
(16968, 1505, 1582, 'pass', '2026-08-18 11:09:00', '2026-08-18 11:09:00'),
(16969, 1506, 1513, 'like', '2026-08-28 11:08:00', '2026-08-28 11:08:00'),
(16970, 1506, 1520, 'pass', '2026-08-27 11:08:00', '2026-08-27 11:08:00'),
(16971, 1506, 1527, 'like', '2026-08-26 11:08:00', '2026-08-26 11:08:00'),
(16972, 1506, 1534, 'like', '2026-08-25 11:08:00', '2026-08-25 11:08:00'),
(16973, 1506, 1541, 'superLike', '2026-08-24 11:08:00', '2026-08-24 11:08:00'),
(16974, 1506, 1548, 'pass', '2026-08-23 11:08:00', '2026-08-23 11:08:00'),
(16975, 1506, 1555, 'like', '2026-08-22 11:08:00', '2026-08-22 11:08:00'),
(16976, 1506, 1562, 'like', '2026-08-21 11:08:00', '2026-08-21 11:08:00'),
(16977, 1506, 1569, 'pass', '2026-08-20 11:08:00', '2026-08-20 11:08:00'),
(16978, 1506, 1576, 'like', '2026-08-19 11:08:00', '2026-08-19 11:08:00'),
(16979, 1506, 1583, 'like', '2026-08-18 11:08:00', '2026-08-18 11:08:00'),
(16980, 1506, 1590, 'pass', '2026-08-17 11:08:00', '2026-08-17 11:08:00'),
(16981, 1507, 1514, 'like', '2026-08-28 11:07:00', '2026-08-28 11:07:00'),
(16982, 1507, 1521, 'like', '2026-08-27 11:07:00', '2026-08-27 11:07:00'),
(16983, 1507, 1528, 'pass', '2026-08-26 11:07:00', '2026-08-26 11:07:00'),
(16984, 1507, 1535, 'like', '2026-08-25 11:07:00', '2026-08-25 11:07:00'),
(16985, 1507, 1542, 'like', '2026-08-24 11:07:00', '2026-08-24 11:07:00'),
(16986, 1507, 1549, 'superLike', '2026-08-23 11:07:00', '2026-08-23 11:07:00'),
(16987, 1507, 1556, 'pass', '2026-08-22 11:07:00', '2026-08-22 11:07:00'),
(16988, 1507, 1563, 'like', '2026-08-21 11:07:00', '2026-08-21 11:07:00'),
(16989, 1507, 1570, 'like', '2026-08-20 11:07:00', '2026-08-20 11:07:00'),
(16990, 1507, 1577, 'pass', '2026-08-19 11:07:00', '2026-08-19 11:07:00'),
(16991, 1507, 1584, 'like', '2026-08-18 11:07:00', '2026-08-18 11:07:00'),
(16992, 1507, 1591, 'like', '2026-08-17 11:07:00', '2026-08-17 11:07:00'),
(16993, 1507, 1598, 'pass', '2026-08-16 11:07:00', '2026-08-16 11:07:00'),
(16994, 1508, 1515, 'pass', '2026-08-28 11:06:00', '2026-08-28 11:06:00'),
(16995, 1508, 1522, 'like', '2026-08-27 11:06:00', '2026-08-27 11:06:00'),
(16996, 1508, 1529, 'like', '2026-08-26 11:06:00', '2026-08-26 11:06:00'),
(16997, 1508, 1536, 'pass', '2026-08-25 11:06:00', '2026-08-25 11:06:00'),
(16998, 1508, 1543, 'like', '2026-08-24 11:06:00', '2026-08-24 11:06:00'),
(16999, 1508, 1550, 'like', '2026-08-23 11:06:00', '2026-08-23 11:06:00'),
(17000, 1508, 1557, 'superLike', '2026-08-22 11:06:00', '2026-08-22 11:06:00'),
(17001, 1508, 1564, 'pass', '2026-08-21 11:06:00', '2026-08-21 11:06:00'),
(17002, 1508, 1571, 'like', '2026-08-20 11:06:00', '2026-08-20 11:06:00'),
(17003, 1508, 1578, 'like', '2026-08-19 11:06:00', '2026-08-19 11:06:00'),
(17004, 1508, 1585, 'pass', '2026-08-18 11:06:00', '2026-08-18 11:06:00'),
(17005, 1508, 1592, 'like', '2026-08-17 11:06:00', '2026-08-17 11:06:00'),
(17006, 1508, 1599, 'like', '2026-08-16 11:06:00', '2026-08-16 11:06:00'),
(17007, 1508, 1456, 'pass', '2026-08-15 11:06:00', '2026-08-15 11:06:00'),
(17008, 1509, 1516, 'like', '2026-08-28 11:05:00', '2026-08-28 11:05:00'),
(17009, 1509, 1523, 'pass', '2026-08-27 11:05:00', '2026-08-27 11:05:00'),
(17010, 1509, 1530, 'like', '2026-08-26 11:05:00', '2026-08-26 11:05:00'),
(17011, 1509, 1537, 'like', '2026-08-25 11:05:00', '2026-08-25 11:05:00'),
(17012, 1509, 1544, 'pass', '2026-08-24 11:05:00', '2026-08-24 11:05:00'),
(17013, 1509, 1551, 'like', '2026-08-23 11:05:00', '2026-08-23 11:05:00'),
(17014, 1509, 1558, 'like', '2026-08-22 11:05:00', '2026-08-22 11:05:00'),
(17015, 1509, 1565, 'superLike', '2026-08-21 11:05:00', '2026-08-21 11:05:00'),
(17016, 1509, 1572, 'pass', '2026-08-20 11:05:00', '2026-08-20 11:05:00'),
(17017, 1509, 1579, 'like', '2026-08-19 11:05:00', '2026-08-19 11:05:00'),
(17018, 1509, 1586, 'like', '2026-08-18 11:05:00', '2026-08-18 11:05:00'),
(17019, 1509, 1593, 'pass', '2026-08-17 11:05:00', '2026-08-17 11:05:00'),
(17020, 1509, 1600, 'like', '2026-08-16 11:05:00', '2026-08-16 11:05:00'),
(17021, 1509, 1457, 'like', '2026-08-15 11:05:00', '2026-08-15 11:05:00'),
(17022, 1509, 1464, 'pass', '2026-08-14 11:05:00', '2026-08-14 11:05:00'),
(17023, 1510, 1517, 'like', '2026-08-28 11:04:00', '2026-08-28 11:04:00'),
(17024, 1510, 1524, 'like', '2026-08-27 11:04:00', '2026-08-27 11:04:00'),
(17025, 1510, 1531, 'pass', '2026-08-26 11:04:00', '2026-08-26 11:04:00'),
(17026, 1510, 1538, 'like', '2026-08-25 11:04:00', '2026-08-25 11:04:00'),
(17027, 1510, 1545, 'like', '2026-08-24 11:04:00', '2026-08-24 11:04:00'),
(17028, 1510, 1552, 'pass', '2026-08-23 11:04:00', '2026-08-23 11:04:00'),
(17029, 1510, 1559, 'like', '2026-08-22 11:04:00', '2026-08-22 11:04:00'),
(17030, 1510, 1566, 'like', '2026-08-21 11:04:00', '2026-08-21 11:04:00'),
(17031, 1511, 1518, 'pass', '2026-08-28 11:03:00', '2026-08-28 11:03:00'),
(17032, 1511, 1525, 'like', '2026-08-27 11:03:00', '2026-08-27 11:03:00'),
(17033, 1511, 1532, 'like', '2026-08-26 11:03:00', '2026-08-26 11:03:00');
INSERT INTO `discoveractions` (`id`, `actorUserId`, `targetUserId`, `action`, `createdAt`, `updatedAt`) VALUES
(17034, 1511, 1539, 'pass', '2026-08-25 11:03:00', '2026-08-25 11:03:00'),
(17035, 1511, 1546, 'like', '2026-08-24 11:03:00', '2026-08-24 11:03:00'),
(17036, 1511, 1553, 'like', '2026-08-23 11:03:00', '2026-08-23 11:03:00'),
(17037, 1511, 1560, 'pass', '2026-08-22 11:03:00', '2026-08-22 11:03:00'),
(17038, 1511, 1567, 'like', '2026-08-21 11:03:00', '2026-08-21 11:03:00'),
(17039, 1511, 1574, 'like', '2026-08-20 11:03:00', '2026-08-20 11:03:00'),
(17040, 1512, 1519, 'superLike', '2026-08-28 11:02:00', '2026-08-28 11:02:00'),
(17041, 1512, 1526, 'pass', '2026-08-27 11:02:00', '2026-08-27 11:02:00'),
(17042, 1512, 1533, 'like', '2026-08-26 11:02:00', '2026-08-26 11:02:00'),
(17043, 1512, 1540, 'like', '2026-08-25 11:02:00', '2026-08-25 11:02:00'),
(17044, 1512, 1547, 'pass', '2026-08-24 11:02:00', '2026-08-24 11:02:00'),
(17045, 1512, 1554, 'like', '2026-08-23 11:02:00', '2026-08-23 11:02:00'),
(17046, 1512, 1561, 'like', '2026-08-22 11:02:00', '2026-08-22 11:02:00'),
(17047, 1512, 1568, 'pass', '2026-08-21 11:02:00', '2026-08-21 11:02:00'),
(17048, 1512, 1575, 'like', '2026-08-20 11:02:00', '2026-08-20 11:02:00'),
(17049, 1512, 1582, 'like', '2026-08-19 11:02:00', '2026-08-19 11:02:00'),
(17050, 1513, 1520, 'like', '2026-08-28 11:01:00', '2026-08-28 11:01:00'),
(17051, 1513, 1527, 'superLike', '2026-08-27 11:01:00', '2026-08-27 11:01:00'),
(17052, 1513, 1534, 'pass', '2026-08-26 11:01:00', '2026-08-26 11:01:00'),
(17053, 1513, 1541, 'like', '2026-08-25 11:01:00', '2026-08-25 11:01:00'),
(17054, 1513, 1548, 'like', '2026-08-24 11:01:00', '2026-08-24 11:01:00'),
(17055, 1513, 1555, 'pass', '2026-08-23 11:01:00', '2026-08-23 11:01:00'),
(17056, 1513, 1562, 'like', '2026-08-22 11:01:00', '2026-08-22 11:01:00'),
(17057, 1513, 1569, 'like', '2026-08-21 11:01:00', '2026-08-21 11:01:00'),
(17058, 1513, 1576, 'pass', '2026-08-20 11:01:00', '2026-08-20 11:01:00'),
(17059, 1513, 1583, 'like', '2026-08-19 11:01:00', '2026-08-19 11:01:00'),
(17060, 1513, 1590, 'like', '2026-08-18 11:01:00', '2026-08-18 11:01:00'),
(17061, 1514, 1521, 'like', '2026-08-28 11:00:00', '2026-08-28 11:00:00'),
(17062, 1514, 1528, 'like', '2026-08-27 11:00:00', '2026-08-27 11:00:00'),
(17063, 1514, 1535, 'superLike', '2026-08-26 11:00:00', '2026-08-26 11:00:00'),
(17064, 1514, 1542, 'pass', '2026-08-25 11:00:00', '2026-08-25 11:00:00'),
(17065, 1514, 1549, 'like', '2026-08-24 11:00:00', '2026-08-24 11:00:00'),
(17066, 1514, 1556, 'like', '2026-08-23 11:00:00', '2026-08-23 11:00:00'),
(17067, 1514, 1563, 'pass', '2026-08-22 11:00:00', '2026-08-22 11:00:00'),
(17068, 1514, 1570, 'like', '2026-08-21 11:00:00', '2026-08-21 11:00:00'),
(17069, 1514, 1577, 'like', '2026-08-20 11:00:00', '2026-08-20 11:00:00'),
(17070, 1514, 1584, 'pass', '2026-08-19 11:00:00', '2026-08-19 11:00:00'),
(17071, 1514, 1591, 'like', '2026-08-18 11:00:00', '2026-08-18 11:00:00'),
(17072, 1514, 1598, 'like', '2026-08-17 11:00:00', '2026-08-17 11:00:00'),
(17073, 1515, 1522, 'pass', '2026-08-28 10:59:00', '2026-08-28 10:59:00'),
(17074, 1515, 1529, 'like', '2026-08-27 10:59:00', '2026-08-27 10:59:00'),
(17075, 1515, 1536, 'like', '2026-08-26 10:59:00', '2026-08-26 10:59:00'),
(17076, 1515, 1543, 'superLike', '2026-08-25 10:59:00', '2026-08-25 10:59:00'),
(17077, 1515, 1550, 'pass', '2026-08-24 10:59:00', '2026-08-24 10:59:00'),
(17078, 1515, 1557, 'like', '2026-08-23 10:59:00', '2026-08-23 10:59:00'),
(17079, 1515, 1564, 'like', '2026-08-22 10:59:00', '2026-08-22 10:59:00'),
(17080, 1515, 1571, 'pass', '2026-08-21 10:59:00', '2026-08-21 10:59:00'),
(17081, 1515, 1578, 'like', '2026-08-20 10:59:00', '2026-08-20 10:59:00'),
(17082, 1515, 1585, 'like', '2026-08-19 10:59:00', '2026-08-19 10:59:00'),
(17083, 1515, 1592, 'pass', '2026-08-18 10:59:00', '2026-08-18 10:59:00'),
(17084, 1515, 1599, 'like', '2026-08-17 10:59:00', '2026-08-17 10:59:00'),
(17085, 1515, 1456, 'like', '2026-08-16 10:59:00', '2026-08-16 10:59:00'),
(17086, 1516, 1523, 'like', '2026-08-28 10:58:00', '2026-08-28 10:58:00'),
(17087, 1516, 1530, 'pass', '2026-08-27 10:58:00', '2026-08-27 10:58:00'),
(17088, 1516, 1537, 'like', '2026-08-26 10:58:00', '2026-08-26 10:58:00'),
(17089, 1516, 1544, 'like', '2026-08-25 10:58:00', '2026-08-25 10:58:00'),
(17090, 1516, 1551, 'superLike', '2026-08-24 10:58:00', '2026-08-24 10:58:00'),
(17091, 1516, 1558, 'pass', '2026-08-23 10:58:00', '2026-08-23 10:58:00'),
(17092, 1516, 1565, 'like', '2026-08-22 10:58:00', '2026-08-22 10:58:00'),
(17093, 1516, 1572, 'like', '2026-08-21 10:58:00', '2026-08-21 10:58:00'),
(17094, 1516, 1579, 'pass', '2026-08-20 10:58:00', '2026-08-20 10:58:00'),
(17095, 1516, 1586, 'like', '2026-08-19 10:58:00', '2026-08-19 10:58:00'),
(17096, 1516, 1593, 'like', '2026-08-18 10:58:00', '2026-08-18 10:58:00'),
(17097, 1516, 1600, 'pass', '2026-08-17 10:58:00', '2026-08-17 10:58:00'),
(17098, 1516, 1457, 'like', '2026-08-16 10:58:00', '2026-08-16 10:58:00'),
(17099, 1516, 1464, 'like', '2026-08-15 10:58:00', '2026-08-15 10:58:00'),
(17100, 1517, 1524, 'like', '2026-08-28 10:57:00', '2026-08-28 10:57:00'),
(17101, 1517, 1531, 'like', '2026-08-27 10:57:00', '2026-08-27 10:57:00'),
(17102, 1517, 1538, 'pass', '2026-08-26 10:57:00', '2026-08-26 10:57:00'),
(17103, 1517, 1545, 'like', '2026-08-25 10:57:00', '2026-08-25 10:57:00'),
(17104, 1517, 1552, 'like', '2026-08-24 10:57:00', '2026-08-24 10:57:00'),
(17105, 1517, 1559, 'superLike', '2026-08-23 10:57:00', '2026-08-23 10:57:00'),
(17106, 1517, 1566, 'pass', '2026-08-22 10:57:00', '2026-08-22 10:57:00'),
(17107, 1517, 1573, 'like', '2026-08-21 10:57:00', '2026-08-21 10:57:00'),
(17108, 1517, 1580, 'like', '2026-08-20 10:57:00', '2026-08-20 10:57:00'),
(17109, 1517, 1587, 'pass', '2026-08-19 10:57:00', '2026-08-19 10:57:00'),
(17110, 1517, 1594, 'like', '2026-08-18 10:57:00', '2026-08-18 10:57:00'),
(17111, 1517, 1601, 'like', '2026-08-17 10:57:00', '2026-08-17 10:57:00'),
(17112, 1517, 1458, 'pass', '2026-08-16 10:57:00', '2026-08-16 10:57:00'),
(17113, 1517, 1465, 'like', '2026-08-15 10:57:00', '2026-08-15 10:57:00'),
(17114, 1517, 1472, 'like', '2026-08-14 10:57:00', '2026-08-14 10:57:00'),
(17115, 1518, 1525, 'pass', '2026-08-28 10:56:00', '2026-08-28 10:56:00'),
(17116, 1518, 1532, 'like', '2026-08-27 10:56:00', '2026-08-27 10:56:00'),
(17117, 1518, 1539, 'like', '2026-08-26 10:56:00', '2026-08-26 10:56:00'),
(17118, 1518, 1546, 'pass', '2026-08-25 10:56:00', '2026-08-25 10:56:00'),
(17119, 1518, 1553, 'like', '2026-08-24 10:56:00', '2026-08-24 10:56:00'),
(17120, 1518, 1560, 'like', '2026-08-23 10:56:00', '2026-08-23 10:56:00'),
(17121, 1518, 1567, 'superLike', '2026-08-22 10:56:00', '2026-08-22 10:56:00'),
(17122, 1518, 1574, 'pass', '2026-08-21 10:56:00', '2026-08-21 10:56:00'),
(17123, 1519, 1526, 'like', '2026-08-28 10:55:00', '2026-08-28 10:55:00'),
(17124, 1519, 1533, 'pass', '2026-08-27 10:55:00', '2026-08-27 10:55:00'),
(17125, 1519, 1540, 'like', '2026-08-26 10:55:00', '2026-08-26 10:55:00'),
(17126, 1519, 1547, 'like', '2026-08-25 10:55:00', '2026-08-25 10:55:00'),
(17127, 1519, 1554, 'pass', '2026-08-24 10:55:00', '2026-08-24 10:55:00'),
(17128, 1519, 1561, 'like', '2026-08-23 10:55:00', '2026-08-23 10:55:00'),
(17129, 1519, 1568, 'like', '2026-08-22 10:55:00', '2026-08-22 10:55:00'),
(17130, 1519, 1575, 'superLike', '2026-08-21 10:55:00', '2026-08-21 10:55:00'),
(17131, 1519, 1582, 'pass', '2026-08-20 10:55:00', '2026-08-20 10:55:00'),
(17132, 1520, 1527, 'like', '2026-08-28 10:54:00', '2026-08-28 10:54:00'),
(17133, 1520, 1534, 'like', '2026-08-27 10:54:00', '2026-08-27 10:54:00'),
(17134, 1520, 1541, 'pass', '2026-08-26 10:54:00', '2026-08-26 10:54:00'),
(17135, 1520, 1548, 'like', '2026-08-25 10:54:00', '2026-08-25 10:54:00'),
(17136, 1520, 1555, 'like', '2026-08-24 10:54:00', '2026-08-24 10:54:00'),
(17137, 1520, 1562, 'pass', '2026-08-23 10:54:00', '2026-08-23 10:54:00'),
(17138, 1520, 1569, 'like', '2026-08-22 10:54:00', '2026-08-22 10:54:00'),
(17139, 1520, 1576, 'like', '2026-08-21 10:54:00', '2026-08-21 10:54:00'),
(17140, 1520, 1583, 'superLike', '2026-08-20 10:54:00', '2026-08-20 10:54:00'),
(17141, 1520, 1590, 'pass', '2026-08-19 10:54:00', '2026-08-19 10:54:00'),
(17142, 1521, 1528, 'pass', '2026-08-28 10:53:00', '2026-08-28 10:53:00'),
(17143, 1521, 1535, 'like', '2026-08-27 10:53:00', '2026-08-27 10:53:00'),
(17144, 1521, 1542, 'like', '2026-08-26 10:53:00', '2026-08-26 10:53:00'),
(17145, 1521, 1549, 'pass', '2026-08-25 10:53:00', '2026-08-25 10:53:00'),
(17146, 1521, 1556, 'like', '2026-08-24 10:53:00', '2026-08-24 10:53:00'),
(17147, 1521, 1563, 'like', '2026-08-23 10:53:00', '2026-08-23 10:53:00'),
(17148, 1521, 1570, 'pass', '2026-08-22 10:53:00', '2026-08-22 10:53:00'),
(17149, 1521, 1577, 'like', '2026-08-21 10:53:00', '2026-08-21 10:53:00'),
(17150, 1521, 1584, 'like', '2026-08-20 10:53:00', '2026-08-20 10:53:00'),
(17151, 1521, 1591, 'superLike', '2026-08-19 10:53:00', '2026-08-19 10:53:00'),
(17152, 1521, 1598, 'pass', '2026-08-18 10:53:00', '2026-08-18 10:53:00'),
(17153, 1522, 1529, 'superLike', '2026-08-28 10:52:00', '2026-08-28 10:52:00'),
(17154, 1522, 1536, 'pass', '2026-08-27 10:52:00', '2026-08-27 10:52:00'),
(17155, 1522, 1543, 'like', '2026-08-26 10:52:00', '2026-08-26 10:52:00'),
(17156, 1522, 1550, 'like', '2026-08-25 10:52:00', '2026-08-25 10:52:00'),
(17157, 1522, 1557, 'pass', '2026-08-24 10:52:00', '2026-08-24 10:52:00'),
(17158, 1522, 1564, 'like', '2026-08-23 10:52:00', '2026-08-23 10:52:00'),
(17159, 1522, 1571, 'like', '2026-08-22 10:52:00', '2026-08-22 10:52:00'),
(17160, 1522, 1578, 'pass', '2026-08-21 10:52:00', '2026-08-21 10:52:00'),
(17161, 1522, 1585, 'like', '2026-08-20 10:52:00', '2026-08-20 10:52:00'),
(17162, 1522, 1592, 'like', '2026-08-19 10:52:00', '2026-08-19 10:52:00'),
(17163, 1522, 1599, 'superLike', '2026-08-18 10:52:00', '2026-08-18 10:52:00'),
(17164, 1522, 1456, 'pass', '2026-08-17 10:52:00', '2026-08-17 10:52:00'),
(17165, 1523, 1530, 'like', '2026-08-28 10:51:00', '2026-08-28 10:51:00'),
(17166, 1523, 1537, 'superLike', '2026-08-27 10:51:00', '2026-08-27 10:51:00'),
(17167, 1523, 1544, 'pass', '2026-08-26 10:51:00', '2026-08-26 10:51:00'),
(17168, 1523, 1551, 'like', '2026-08-25 10:51:00', '2026-08-25 10:51:00'),
(17169, 1523, 1558, 'like', '2026-08-24 10:51:00', '2026-08-24 10:51:00'),
(17170, 1523, 1565, 'pass', '2026-08-23 10:51:00', '2026-08-23 10:51:00'),
(17171, 1523, 1572, 'like', '2026-08-22 10:51:00', '2026-08-22 10:51:00'),
(17172, 1523, 1579, 'like', '2026-08-21 10:51:00', '2026-08-21 10:51:00'),
(17173, 1523, 1586, 'pass', '2026-08-20 10:51:00', '2026-08-20 10:51:00'),
(17174, 1523, 1593, 'like', '2026-08-19 10:51:00', '2026-08-19 10:51:00'),
(17175, 1523, 1600, 'like', '2026-08-18 10:51:00', '2026-08-18 10:51:00'),
(17176, 1523, 1457, 'superLike', '2026-08-17 10:51:00', '2026-08-17 10:51:00'),
(17177, 1523, 1464, 'pass', '2026-08-16 10:51:00', '2026-08-16 10:51:00'),
(17178, 1524, 1531, 'like', '2026-08-28 10:50:00', '2026-08-28 10:50:00'),
(17179, 1524, 1538, 'like', '2026-08-27 10:50:00', '2026-08-27 10:50:00'),
(17180, 1524, 1545, 'superLike', '2026-08-26 10:50:00', '2026-08-26 10:50:00'),
(17181, 1524, 1552, 'pass', '2026-08-25 10:50:00', '2026-08-25 10:50:00'),
(17182, 1524, 1559, 'like', '2026-08-24 10:50:00', '2026-08-24 10:50:00'),
(17183, 1524, 1566, 'like', '2026-08-23 10:50:00', '2026-08-23 10:50:00'),
(17184, 1524, 1573, 'pass', '2026-08-22 10:50:00', '2026-08-22 10:50:00'),
(17185, 1524, 1580, 'like', '2026-08-21 10:50:00', '2026-08-21 10:50:00'),
(17186, 1524, 1587, 'like', '2026-08-20 10:50:00', '2026-08-20 10:50:00'),
(17187, 1524, 1594, 'pass', '2026-08-19 10:50:00', '2026-08-19 10:50:00'),
(17188, 1524, 1601, 'like', '2026-08-18 10:50:00', '2026-08-18 10:50:00'),
(17189, 1524, 1458, 'like', '2026-08-17 10:50:00', '2026-08-17 10:50:00'),
(17190, 1524, 1465, 'superLike', '2026-08-16 10:50:00', '2026-08-16 10:50:00'),
(17191, 1524, 1472, 'pass', '2026-08-15 10:50:00', '2026-08-15 10:50:00'),
(17192, 1525, 1532, 'pass', '2026-08-28 10:49:00', '2026-08-28 10:49:00'),
(17193, 1525, 1539, 'like', '2026-08-27 10:49:00', '2026-08-27 10:49:00'),
(17194, 1525, 1546, 'like', '2026-08-26 10:49:00', '2026-08-26 10:49:00'),
(17195, 1525, 1553, 'superLike', '2026-08-25 10:49:00', '2026-08-25 10:49:00'),
(17196, 1525, 1560, 'pass', '2026-08-24 10:49:00', '2026-08-24 10:49:00'),
(17197, 1525, 1567, 'like', '2026-08-23 10:49:00', '2026-08-23 10:49:00'),
(17198, 1525, 1574, 'like', '2026-08-22 10:49:00', '2026-08-22 10:49:00'),
(17199, 1525, 1581, 'pass', '2026-08-21 10:49:00', '2026-08-21 10:49:00'),
(17200, 1525, 1588, 'like', '2026-08-20 10:49:00', '2026-08-20 10:49:00'),
(17201, 1525, 1595, 'like', '2026-08-19 10:49:00', '2026-08-19 10:49:00'),
(17202, 1525, 1602, 'pass', '2026-08-18 10:49:00', '2026-08-18 10:49:00'),
(17203, 1525, 1459, 'like', '2026-08-17 10:49:00', '2026-08-17 10:49:00'),
(17204, 1525, 1466, 'like', '2026-08-16 10:49:00', '2026-08-16 10:49:00'),
(17205, 1525, 1473, 'superLike', '2026-08-15 10:49:00', '2026-08-15 10:49:00'),
(17206, 1525, 1480, 'pass', '2026-08-14 10:49:00', '2026-08-14 10:49:00'),
(17207, 1526, 1533, 'like', '2026-08-28 10:48:00', '2026-08-28 10:48:00'),
(17208, 1526, 1540, 'pass', '2026-08-27 10:48:00', '2026-08-27 10:48:00'),
(17209, 1526, 1547, 'like', '2026-08-26 10:48:00', '2026-08-26 10:48:00'),
(17210, 1526, 1554, 'like', '2026-08-25 10:48:00', '2026-08-25 10:48:00'),
(17211, 1526, 1561, 'superLike', '2026-08-24 10:48:00', '2026-08-24 10:48:00'),
(17212, 1526, 1568, 'pass', '2026-08-23 10:48:00', '2026-08-23 10:48:00'),
(17213, 1526, 1575, 'like', '2026-08-22 10:48:00', '2026-08-22 10:48:00'),
(17214, 1526, 1582, 'like', '2026-08-21 10:48:00', '2026-08-21 10:48:00'),
(17215, 1527, 1534, 'like', '2026-08-28 10:47:00', '2026-08-28 10:47:00'),
(17216, 1527, 1541, 'like', '2026-08-27 10:47:00', '2026-08-27 10:47:00'),
(17217, 1527, 1548, 'pass', '2026-08-26 10:47:00', '2026-08-26 10:47:00'),
(17218, 1527, 1555, 'like', '2026-08-25 10:47:00', '2026-08-25 10:47:00'),
(17219, 1527, 1562, 'like', '2026-08-24 10:47:00', '2026-08-24 10:47:00'),
(17220, 1527, 1569, 'superLike', '2026-08-23 10:47:00', '2026-08-23 10:47:00'),
(17221, 1527, 1576, 'pass', '2026-08-22 10:47:00', '2026-08-22 10:47:00'),
(17222, 1527, 1583, 'like', '2026-08-21 10:47:00', '2026-08-21 10:47:00'),
(17223, 1527, 1590, 'like', '2026-08-20 10:47:00', '2026-08-20 10:47:00'),
(17224, 1528, 1535, 'pass', '2026-08-28 10:46:00', '2026-08-28 10:46:00'),
(17225, 1528, 1542, 'like', '2026-08-27 10:46:00', '2026-08-27 10:46:00'),
(17226, 1528, 1549, 'like', '2026-08-26 10:46:00', '2026-08-26 10:46:00'),
(17227, 1528, 1556, 'pass', '2026-08-25 10:46:00', '2026-08-25 10:46:00'),
(17228, 1528, 1563, 'like', '2026-08-24 10:46:00', '2026-08-24 10:46:00'),
(17229, 1528, 1570, 'like', '2026-08-23 10:46:00', '2026-08-23 10:46:00'),
(17230, 1528, 1577, 'superLike', '2026-08-22 10:46:00', '2026-08-22 10:46:00'),
(17231, 1528, 1584, 'pass', '2026-08-21 10:46:00', '2026-08-21 10:46:00'),
(17232, 1528, 1591, 'like', '2026-08-20 10:46:00', '2026-08-20 10:46:00'),
(17233, 1528, 1598, 'like', '2026-08-19 10:46:00', '2026-08-19 10:46:00'),
(17234, 1529, 1536, 'like', '2026-08-28 10:45:00', '2026-08-28 10:45:00'),
(17235, 1529, 1543, 'pass', '2026-08-27 10:45:00', '2026-08-27 10:45:00'),
(17236, 1529, 1550, 'like', '2026-08-26 10:45:00', '2026-08-26 10:45:00'),
(17237, 1529, 1557, 'like', '2026-08-25 10:45:00', '2026-08-25 10:45:00'),
(17238, 1529, 1564, 'pass', '2026-08-24 10:45:00', '2026-08-24 10:45:00'),
(17239, 1529, 1571, 'like', '2026-08-23 10:45:00', '2026-08-23 10:45:00'),
(17240, 1529, 1578, 'like', '2026-08-22 10:45:00', '2026-08-22 10:45:00'),
(17241, 1529, 1585, 'superLike', '2026-08-21 10:45:00', '2026-08-21 10:45:00'),
(17242, 1529, 1592, 'pass', '2026-08-20 10:45:00', '2026-08-20 10:45:00'),
(17243, 1529, 1599, 'like', '2026-08-19 10:45:00', '2026-08-19 10:45:00'),
(17244, 1529, 1456, 'like', '2026-08-18 10:45:00', '2026-08-18 10:45:00'),
(17245, 1530, 1537, 'like', '2026-08-28 10:44:00', '2026-08-28 10:44:00'),
(17246, 1530, 1544, 'like', '2026-08-27 10:44:00', '2026-08-27 10:44:00'),
(17247, 1530, 1551, 'pass', '2026-08-26 10:44:00', '2026-08-26 10:44:00'),
(17248, 1530, 1558, 'like', '2026-08-25 10:44:00', '2026-08-25 10:44:00'),
(17249, 1530, 1565, 'like', '2026-08-24 10:44:00', '2026-08-24 10:44:00'),
(17250, 1530, 1572, 'pass', '2026-08-23 10:44:00', '2026-08-23 10:44:00'),
(17251, 1530, 1579, 'like', '2026-08-22 10:44:00', '2026-08-22 10:44:00'),
(17252, 1530, 1586, 'like', '2026-08-21 10:44:00', '2026-08-21 10:44:00'),
(17253, 1530, 1593, 'superLike', '2026-08-20 10:44:00', '2026-08-20 10:44:00'),
(17254, 1530, 1600, 'pass', '2026-08-19 10:44:00', '2026-08-19 10:44:00'),
(17255, 1530, 1457, 'like', '2026-08-18 10:44:00', '2026-08-18 10:44:00'),
(17256, 1530, 1464, 'like', '2026-08-17 10:44:00', '2026-08-17 10:44:00'),
(17257, 1531, 1538, 'pass', '2026-08-28 10:43:00', '2026-08-28 10:43:00'),
(17258, 1531, 1545, 'like', '2026-08-27 10:43:00', '2026-08-27 10:43:00'),
(17259, 1531, 1552, 'like', '2026-08-26 10:43:00', '2026-08-26 10:43:00'),
(17260, 1531, 1559, 'pass', '2026-08-25 10:43:00', '2026-08-25 10:43:00'),
(17261, 1531, 1566, 'like', '2026-08-24 10:43:00', '2026-08-24 10:43:00'),
(17262, 1531, 1573, 'like', '2026-08-23 10:43:00', '2026-08-23 10:43:00'),
(17263, 1531, 1580, 'pass', '2026-08-22 10:43:00', '2026-08-22 10:43:00'),
(17264, 1531, 1587, 'like', '2026-08-21 10:43:00', '2026-08-21 10:43:00'),
(17265, 1531, 1594, 'like', '2026-08-20 10:43:00', '2026-08-20 10:43:00'),
(17266, 1531, 1601, 'superLike', '2026-08-19 10:43:00', '2026-08-19 10:43:00'),
(17267, 1531, 1458, 'pass', '2026-08-18 10:43:00', '2026-08-18 10:43:00'),
(17268, 1531, 1465, 'like', '2026-08-17 10:43:00', '2026-08-17 10:43:00'),
(17269, 1531, 1472, 'like', '2026-08-16 10:43:00', '2026-08-16 10:43:00'),
(17270, 1532, 1539, 'superLike', '2026-08-28 10:42:00', '2026-08-28 10:42:00'),
(17271, 1532, 1546, 'pass', '2026-08-27 10:42:00', '2026-08-27 10:42:00'),
(17272, 1532, 1553, 'like', '2026-08-26 10:42:00', '2026-08-26 10:42:00'),
(17273, 1532, 1560, 'like', '2026-08-25 10:42:00', '2026-08-25 10:42:00'),
(17274, 1532, 1567, 'pass', '2026-08-24 10:42:00', '2026-08-24 10:42:00'),
(17275, 1532, 1574, 'like', '2026-08-23 10:42:00', '2026-08-23 10:42:00'),
(17276, 1532, 1581, 'like', '2026-08-22 10:42:00', '2026-08-22 10:42:00'),
(17277, 1532, 1588, 'pass', '2026-08-21 10:42:00', '2026-08-21 10:42:00'),
(17278, 1532, 1595, 'like', '2026-08-20 10:42:00', '2026-08-20 10:42:00'),
(17279, 1532, 1602, 'like', '2026-08-19 10:42:00', '2026-08-19 10:42:00'),
(17280, 1532, 1459, 'superLike', '2026-08-18 10:42:00', '2026-08-18 10:42:00'),
(17281, 1532, 1466, 'pass', '2026-08-17 10:42:00', '2026-08-17 10:42:00'),
(17282, 1532, 1473, 'like', '2026-08-16 10:42:00', '2026-08-16 10:42:00'),
(17283, 1532, 1480, 'like', '2026-08-15 10:42:00', '2026-08-15 10:42:00'),
(17284, 1533, 1540, 'like', '2026-08-28 10:41:00', '2026-08-28 10:41:00'),
(17285, 1533, 1547, 'superLike', '2026-08-27 10:41:00', '2026-08-27 10:41:00'),
(17286, 1533, 1554, 'pass', '2026-08-26 10:41:00', '2026-08-26 10:41:00'),
(17287, 1533, 1561, 'like', '2026-08-25 10:41:00', '2026-08-25 10:41:00'),
(17288, 1533, 1568, 'like', '2026-08-24 10:41:00', '2026-08-24 10:41:00'),
(17289, 1533, 1575, 'pass', '2026-08-23 10:41:00', '2026-08-23 10:41:00'),
(17290, 1533, 1582, 'like', '2026-08-22 10:41:00', '2026-08-22 10:41:00'),
(17291, 1533, 1589, 'like', '2026-08-21 10:41:00', '2026-08-21 10:41:00'),
(17292, 1533, 1596, 'pass', '2026-08-20 10:41:00', '2026-08-20 10:41:00'),
(17293, 1533, 1603, 'like', '2026-08-19 10:41:00', '2026-08-19 10:41:00'),
(17294, 1533, 1460, 'like', '2026-08-18 10:41:00', '2026-08-18 10:41:00'),
(17295, 1533, 1467, 'superLike', '2026-08-17 10:41:00', '2026-08-17 10:41:00'),
(17296, 1533, 1474, 'pass', '2026-08-16 10:41:00', '2026-08-16 10:41:00'),
(17297, 1533, 1481, 'like', '2026-08-15 10:41:00', '2026-08-15 10:41:00'),
(17298, 1533, 1488, 'like', '2026-08-14 10:41:00', '2026-08-14 10:41:00'),
(17299, 1534, 1541, 'like', '2026-08-28 10:40:00', '2026-08-28 10:40:00'),
(17300, 1534, 1548, 'like', '2026-08-27 10:40:00', '2026-08-27 10:40:00'),
(17301, 1534, 1555, 'superLike', '2026-08-26 10:40:00', '2026-08-26 10:40:00'),
(17302, 1534, 1562, 'pass', '2026-08-25 10:40:00', '2026-08-25 10:40:00'),
(17303, 1534, 1569, 'like', '2026-08-24 10:40:00', '2026-08-24 10:40:00'),
(17304, 1534, 1576, 'like', '2026-08-23 10:40:00', '2026-08-23 10:40:00'),
(17305, 1534, 1583, 'pass', '2026-08-22 10:40:00', '2026-08-22 10:40:00'),
(17306, 1534, 1590, 'like', '2026-08-21 10:40:00', '2026-08-21 10:40:00'),
(17307, 1535, 1542, 'pass', '2026-08-28 10:39:00', '2026-08-28 10:39:00'),
(17308, 1535, 1549, 'like', '2026-08-27 10:39:00', '2026-08-27 10:39:00'),
(17309, 1535, 1556, 'like', '2026-08-26 10:39:00', '2026-08-26 10:39:00'),
(17310, 1535, 1563, 'superLike', '2026-08-25 10:39:00', '2026-08-25 10:39:00'),
(17311, 1535, 1570, 'pass', '2026-08-24 10:39:00', '2026-08-24 10:39:00'),
(17312, 1535, 1577, 'like', '2026-08-23 10:39:00', '2026-08-23 10:39:00'),
(17313, 1535, 1584, 'like', '2026-08-22 10:39:00', '2026-08-22 10:39:00'),
(17314, 1535, 1591, 'pass', '2026-08-21 10:39:00', '2026-08-21 10:39:00'),
(17315, 1535, 1598, 'like', '2026-08-20 10:39:00', '2026-08-20 10:39:00'),
(17316, 1536, 1543, 'like', '2026-08-28 10:38:00', '2026-08-28 10:38:00'),
(17317, 1536, 1550, 'pass', '2026-08-27 10:38:00', '2026-08-27 10:38:00'),
(17318, 1536, 1557, 'like', '2026-08-26 10:38:00', '2026-08-26 10:38:00'),
(17319, 1536, 1564, 'like', '2026-08-25 10:38:00', '2026-08-25 10:38:00'),
(17320, 1536, 1571, 'superLike', '2026-08-24 10:38:00', '2026-08-24 10:38:00'),
(17321, 1536, 1578, 'pass', '2026-08-23 10:38:00', '2026-08-23 10:38:00'),
(17322, 1536, 1585, 'like', '2026-08-22 10:38:00', '2026-08-22 10:38:00'),
(17323, 1536, 1592, 'like', '2026-08-21 10:38:00', '2026-08-21 10:38:00'),
(17324, 1536, 1599, 'pass', '2026-08-20 10:38:00', '2026-08-20 10:38:00'),
(17325, 1536, 1456, 'like', '2026-08-19 10:38:00', '2026-08-19 10:38:00'),
(17326, 1537, 1544, 'like', '2026-08-28 10:37:00', '2026-08-28 10:37:00'),
(17327, 1537, 1551, 'like', '2026-08-27 10:37:00', '2026-08-27 10:37:00'),
(17328, 1537, 1558, 'pass', '2026-08-26 10:37:00', '2026-08-26 10:37:00'),
(17329, 1537, 1565, 'like', '2026-08-25 10:37:00', '2026-08-25 10:37:00'),
(17330, 1537, 1572, 'like', '2026-08-24 10:37:00', '2026-08-24 10:37:00'),
(17331, 1537, 1579, 'superLike', '2026-08-23 10:37:00', '2026-08-23 10:37:00'),
(17332, 1537, 1586, 'pass', '2026-08-22 10:37:00', '2026-08-22 10:37:00'),
(17333, 1537, 1593, 'like', '2026-08-21 10:37:00', '2026-08-21 10:37:00'),
(17334, 1537, 1600, 'like', '2026-08-20 10:37:00', '2026-08-20 10:37:00'),
(17335, 1537, 1457, 'pass', '2026-08-19 10:37:00', '2026-08-19 10:37:00'),
(17336, 1537, 1464, 'like', '2026-08-18 10:37:00', '2026-08-18 10:37:00'),
(17337, 1538, 1545, 'pass', '2026-08-28 10:36:00', '2026-08-28 10:36:00'),
(17338, 1538, 1552, 'like', '2026-08-27 10:36:00', '2026-08-27 10:36:00'),
(17339, 1538, 1559, 'like', '2026-08-26 10:36:00', '2026-08-26 10:36:00'),
(17340, 1538, 1566, 'pass', '2026-08-25 10:36:00', '2026-08-25 10:36:00'),
(17341, 1538, 1573, 'like', '2026-08-24 10:36:00', '2026-08-24 10:36:00'),
(17342, 1538, 1580, 'like', '2026-08-23 10:36:00', '2026-08-23 10:36:00'),
(17343, 1538, 1587, 'superLike', '2026-08-22 10:36:00', '2026-08-22 10:36:00'),
(17344, 1538, 1594, 'pass', '2026-08-21 10:36:00', '2026-08-21 10:36:00'),
(17345, 1538, 1601, 'like', '2026-08-20 10:36:00', '2026-08-20 10:36:00'),
(17346, 1538, 1458, 'like', '2026-08-19 10:36:00', '2026-08-19 10:36:00'),
(17347, 1538, 1465, 'pass', '2026-08-18 10:36:00', '2026-08-18 10:36:00'),
(17348, 1538, 1472, 'like', '2026-08-17 10:36:00', '2026-08-17 10:36:00'),
(17349, 1539, 1546, 'like', '2026-08-28 10:35:00', '2026-08-28 10:35:00'),
(17350, 1539, 1553, 'pass', '2026-08-27 10:35:00', '2026-08-27 10:35:00'),
(17351, 1539, 1560, 'like', '2026-08-26 10:35:00', '2026-08-26 10:35:00'),
(17352, 1539, 1567, 'like', '2026-08-25 10:35:00', '2026-08-25 10:35:00'),
(17353, 1539, 1574, 'pass', '2026-08-24 10:35:00', '2026-08-24 10:35:00'),
(17354, 1539, 1581, 'like', '2026-08-23 10:35:00', '2026-08-23 10:35:00'),
(17355, 1539, 1588, 'like', '2026-08-22 10:35:00', '2026-08-22 10:35:00'),
(17356, 1539, 1595, 'superLike', '2026-08-21 10:35:00', '2026-08-21 10:35:00'),
(17357, 1539, 1602, 'pass', '2026-08-20 10:35:00', '2026-08-20 10:35:00'),
(17358, 1539, 1459, 'like', '2026-08-19 10:35:00', '2026-08-19 10:35:00'),
(17359, 1539, 1466, 'like', '2026-08-18 10:35:00', '2026-08-18 10:35:00'),
(17360, 1539, 1473, 'pass', '2026-08-17 10:35:00', '2026-08-17 10:35:00'),
(17361, 1539, 1480, 'like', '2026-08-16 10:35:00', '2026-08-16 10:35:00'),
(17362, 1540, 1547, 'like', '2026-08-28 10:34:00', '2026-08-28 10:34:00'),
(17363, 1540, 1554, 'like', '2026-08-27 10:34:00', '2026-08-27 10:34:00'),
(17364, 1540, 1561, 'pass', '2026-08-26 10:34:00', '2026-08-26 10:34:00'),
(17365, 1540, 1568, 'like', '2026-08-25 10:34:00', '2026-08-25 10:34:00'),
(17366, 1540, 1575, 'like', '2026-08-24 10:34:00', '2026-08-24 10:34:00'),
(17367, 1540, 1582, 'pass', '2026-08-23 10:34:00', '2026-08-23 10:34:00'),
(17368, 1540, 1589, 'like', '2026-08-22 10:34:00', '2026-08-22 10:34:00'),
(17369, 1540, 1596, 'like', '2026-08-21 10:34:00', '2026-08-21 10:34:00'),
(17370, 1540, 1603, 'superLike', '2026-08-20 10:34:00', '2026-08-20 10:34:00'),
(17371, 1540, 1460, 'pass', '2026-08-19 10:34:00', '2026-08-19 10:34:00'),
(17372, 1540, 1467, 'like', '2026-08-18 10:34:00', '2026-08-18 10:34:00'),
(17373, 1540, 1474, 'like', '2026-08-17 10:34:00', '2026-08-17 10:34:00'),
(17374, 1540, 1481, 'pass', '2026-08-16 10:34:00', '2026-08-16 10:34:00'),
(17375, 1540, 1488, 'like', '2026-08-15 10:34:00', '2026-08-15 10:34:00'),
(17376, 1541, 1548, 'pass', '2026-08-28 10:33:00', '2026-08-28 10:33:00'),
(17377, 1541, 1555, 'like', '2026-08-27 10:33:00', '2026-08-27 10:33:00'),
(17378, 1541, 1562, 'like', '2026-08-26 10:33:00', '2026-08-26 10:33:00'),
(17379, 1541, 1569, 'pass', '2026-08-25 10:33:00', '2026-08-25 10:33:00'),
(17380, 1541, 1576, 'like', '2026-08-24 10:33:00', '2026-08-24 10:33:00'),
(17381, 1541, 1583, 'like', '2026-08-23 10:33:00', '2026-08-23 10:33:00'),
(17382, 1541, 1590, 'pass', '2026-08-22 10:33:00', '2026-08-22 10:33:00'),
(17383, 1541, 1597, 'like', '2026-08-21 10:33:00', '2026-08-21 10:33:00'),
(17384, 1541, 1454, 'like', '2026-08-20 10:33:00', '2026-08-20 10:33:00'),
(17385, 1541, 1461, 'superLike', '2026-08-19 10:33:00', '2026-08-19 10:33:00'),
(17386, 1541, 1468, 'pass', '2026-08-18 10:33:00', '2026-08-18 10:33:00'),
(17387, 1541, 1475, 'like', '2026-08-17 10:33:00', '2026-08-17 10:33:00'),
(17388, 1541, 1482, 'like', '2026-08-16 10:33:00', '2026-08-16 10:33:00'),
(17389, 1541, 1489, 'pass', '2026-08-15 10:33:00', '2026-08-15 10:33:00'),
(17390, 1541, 1496, 'like', '2026-08-14 10:33:00', '2026-08-14 10:33:00'),
(17391, 1542, 1549, 'superLike', '2026-08-28 10:32:00', '2026-08-28 10:32:00'),
(17392, 1542, 1556, 'pass', '2026-08-27 10:32:00', '2026-08-27 10:32:00'),
(17393, 1542, 1563, 'like', '2026-08-26 10:32:00', '2026-08-26 10:32:00'),
(17394, 1542, 1570, 'like', '2026-08-25 10:32:00', '2026-08-25 10:32:00'),
(17395, 1542, 1577, 'pass', '2026-08-24 10:32:00', '2026-08-24 10:32:00'),
(17396, 1542, 1584, 'like', '2026-08-23 10:32:00', '2026-08-23 10:32:00'),
(17397, 1542, 1591, 'like', '2026-08-22 10:32:00', '2026-08-22 10:32:00'),
(17398, 1542, 1598, 'pass', '2026-08-21 10:32:00', '2026-08-21 10:32:00'),
(17399, 1543, 1550, 'like', '2026-08-28 10:31:00', '2026-08-28 10:31:00'),
(17400, 1543, 1557, 'superLike', '2026-08-27 10:31:00', '2026-08-27 10:31:00'),
(17401, 1543, 1564, 'pass', '2026-08-26 10:31:00', '2026-08-26 10:31:00'),
(17402, 1543, 1571, 'like', '2026-08-25 10:31:00', '2026-08-25 10:31:00'),
(17403, 1543, 1578, 'like', '2026-08-24 10:31:00', '2026-08-24 10:31:00'),
(17404, 1543, 1585, 'pass', '2026-08-23 10:31:00', '2026-08-23 10:31:00'),
(17405, 1543, 1592, 'like', '2026-08-22 10:31:00', '2026-08-22 10:31:00'),
(17406, 1543, 1599, 'like', '2026-08-21 10:31:00', '2026-08-21 10:31:00'),
(17407, 1543, 1456, 'pass', '2026-08-20 10:31:00', '2026-08-20 10:31:00'),
(17408, 1544, 1551, 'like', '2026-08-28 10:30:00', '2026-08-28 10:30:00'),
(17409, 1544, 1558, 'like', '2026-08-27 10:30:00', '2026-08-27 10:30:00'),
(17410, 1544, 1565, 'superLike', '2026-08-26 10:30:00', '2026-08-26 10:30:00'),
(17411, 1544, 1572, 'pass', '2026-08-25 10:30:00', '2026-08-25 10:30:00'),
(17412, 1544, 1579, 'like', '2026-08-24 10:30:00', '2026-08-24 10:30:00'),
(17413, 1544, 1586, 'like', '2026-08-23 10:30:00', '2026-08-23 10:30:00'),
(17414, 1544, 1593, 'pass', '2026-08-22 10:30:00', '2026-08-22 10:30:00'),
(17415, 1544, 1600, 'like', '2026-08-21 10:30:00', '2026-08-21 10:30:00'),
(17416, 1544, 1457, 'like', '2026-08-20 10:30:00', '2026-08-20 10:30:00'),
(17417, 1544, 1464, 'pass', '2026-08-19 10:30:00', '2026-08-19 10:30:00'),
(17418, 1545, 1552, 'pass', '2026-08-28 10:29:00', '2026-08-28 10:29:00'),
(17419, 1545, 1559, 'like', '2026-08-27 10:29:00', '2026-08-27 10:29:00'),
(17420, 1545, 1566, 'like', '2026-08-26 10:29:00', '2026-08-26 10:29:00'),
(17421, 1545, 1573, 'superLike', '2026-08-25 10:29:00', '2026-08-25 10:29:00'),
(17422, 1545, 1580, 'pass', '2026-08-24 10:29:00', '2026-08-24 10:29:00'),
(17423, 1545, 1587, 'like', '2026-08-23 10:29:00', '2026-08-23 10:29:00'),
(17424, 1545, 1594, 'like', '2026-08-22 10:29:00', '2026-08-22 10:29:00'),
(17425, 1545, 1601, 'pass', '2026-08-21 10:29:00', '2026-08-21 10:29:00'),
(17426, 1545, 1458, 'like', '2026-08-20 10:29:00', '2026-08-20 10:29:00'),
(17427, 1545, 1465, 'like', '2026-08-19 10:29:00', '2026-08-19 10:29:00'),
(17428, 1545, 1472, 'pass', '2026-08-18 10:29:00', '2026-08-18 10:29:00'),
(17429, 1546, 1553, 'like', '2026-08-28 10:28:00', '2026-08-28 10:28:00'),
(17430, 1546, 1560, 'pass', '2026-08-27 10:28:00', '2026-08-27 10:28:00'),
(17431, 1546, 1567, 'like', '2026-08-26 10:28:00', '2026-08-26 10:28:00'),
(17432, 1546, 1574, 'like', '2026-08-25 10:28:00', '2026-08-25 10:28:00'),
(17433, 1546, 1581, 'superLike', '2026-08-24 10:28:00', '2026-08-24 10:28:00'),
(17434, 1546, 1588, 'pass', '2026-08-23 10:28:00', '2026-08-23 10:28:00'),
(17435, 1546, 1595, 'like', '2026-08-22 10:28:00', '2026-08-22 10:28:00'),
(17436, 1546, 1602, 'like', '2026-08-21 10:28:00', '2026-08-21 10:28:00'),
(17437, 1546, 1459, 'pass', '2026-08-20 10:28:00', '2026-08-20 10:28:00'),
(17438, 1546, 1466, 'like', '2026-08-19 10:28:00', '2026-08-19 10:28:00'),
(17439, 1546, 1473, 'like', '2026-08-18 10:28:00', '2026-08-18 10:28:00'),
(17440, 1546, 1480, 'pass', '2026-08-17 10:28:00', '2026-08-17 10:28:00'),
(17441, 1547, 1554, 'like', '2026-08-28 10:27:00', '2026-08-28 10:27:00'),
(17442, 1547, 1561, 'like', '2026-08-27 10:27:00', '2026-08-27 10:27:00'),
(17443, 1547, 1568, 'pass', '2026-08-26 10:27:00', '2026-08-26 10:27:00'),
(17444, 1547, 1575, 'like', '2026-08-25 10:27:00', '2026-08-25 10:27:00'),
(17445, 1547, 1582, 'like', '2026-08-24 10:27:00', '2026-08-24 10:27:00'),
(17446, 1547, 1589, 'superLike', '2026-08-23 10:27:00', '2026-08-23 10:27:00'),
(17447, 1547, 1596, 'pass', '2026-08-22 10:27:00', '2026-08-22 10:27:00'),
(17448, 1547, 1603, 'like', '2026-08-21 10:27:00', '2026-08-21 10:27:00'),
(17449, 1547, 1460, 'like', '2026-08-20 10:27:00', '2026-08-20 10:27:00'),
(17450, 1547, 1467, 'pass', '2026-08-19 10:27:00', '2026-08-19 10:27:00'),
(17451, 1547, 1474, 'like', '2026-08-18 10:27:00', '2026-08-18 10:27:00'),
(17452, 1547, 1481, 'like', '2026-08-17 10:27:00', '2026-08-17 10:27:00'),
(17453, 1547, 1488, 'pass', '2026-08-16 10:27:00', '2026-08-16 10:27:00'),
(17454, 1548, 1555, 'pass', '2026-08-28 10:26:00', '2026-08-28 10:26:00'),
(17455, 1548, 1562, 'like', '2026-08-27 10:26:00', '2026-08-27 10:26:00'),
(17456, 1548, 1569, 'like', '2026-08-26 10:26:00', '2026-08-26 10:26:00'),
(17457, 1548, 1576, 'pass', '2026-08-25 10:26:00', '2026-08-25 10:26:00'),
(17458, 1548, 1583, 'like', '2026-08-24 10:26:00', '2026-08-24 10:26:00'),
(17459, 1548, 1590, 'like', '2026-08-23 10:26:00', '2026-08-23 10:26:00'),
(17460, 1548, 1597, 'superLike', '2026-08-22 10:26:00', '2026-08-22 10:26:00'),
(17461, 1548, 1454, 'pass', '2026-08-21 10:26:00', '2026-08-21 10:26:00'),
(17462, 1548, 1461, 'like', '2026-08-20 10:26:00', '2026-08-20 10:26:00'),
(17463, 1548, 1468, 'like', '2026-08-19 10:26:00', '2026-08-19 10:26:00'),
(17464, 1548, 1475, 'pass', '2026-08-18 10:26:00', '2026-08-18 10:26:00'),
(17465, 1548, 1482, 'like', '2026-08-17 10:26:00', '2026-08-17 10:26:00'),
(17466, 1548, 1489, 'like', '2026-08-16 10:26:00', '2026-08-16 10:26:00'),
(17467, 1548, 1496, 'pass', '2026-08-15 10:26:00', '2026-08-15 10:26:00'),
(17468, 1549, 1556, 'like', '2026-08-28 10:25:00', '2026-08-28 10:25:00'),
(17469, 1549, 1563, 'pass', '2026-08-27 10:25:00', '2026-08-27 10:25:00'),
(17470, 1549, 1570, 'like', '2026-08-26 10:25:00', '2026-08-26 10:25:00'),
(17471, 1549, 1577, 'like', '2026-08-25 10:25:00', '2026-08-25 10:25:00'),
(17472, 1549, 1584, 'pass', '2026-08-24 10:25:00', '2026-08-24 10:25:00'),
(17473, 1549, 1591, 'like', '2026-08-23 10:25:00', '2026-08-23 10:25:00'),
(17474, 1549, 1598, 'like', '2026-08-22 10:25:00', '2026-08-22 10:25:00'),
(17475, 1549, 1455, 'superLike', '2026-08-21 10:25:00', '2026-08-21 10:25:00'),
(17476, 1549, 1462, 'pass', '2026-08-20 10:25:00', '2026-08-20 10:25:00'),
(17477, 1549, 1469, 'like', '2026-08-19 10:25:00', '2026-08-19 10:25:00'),
(17478, 1549, 1476, 'like', '2026-08-18 10:25:00', '2026-08-18 10:25:00'),
(17479, 1549, 1483, 'pass', '2026-08-17 10:25:00', '2026-08-17 10:25:00'),
(17480, 1549, 1490, 'like', '2026-08-16 10:25:00', '2026-08-16 10:25:00'),
(17481, 1549, 1497, 'like', '2026-08-15 10:25:00', '2026-08-15 10:25:00'),
(17482, 1549, 1504, 'pass', '2026-08-14 10:25:00', '2026-08-14 10:25:00'),
(17483, 1550, 1557, 'like', '2026-08-28 10:24:00', '2026-08-28 10:24:00'),
(17484, 1550, 1564, 'like', '2026-08-27 10:24:00', '2026-08-27 10:24:00'),
(17485, 1550, 1571, 'pass', '2026-08-26 10:24:00', '2026-08-26 10:24:00'),
(17486, 1550, 1578, 'like', '2026-08-25 10:24:00', '2026-08-25 10:24:00'),
(17487, 1550, 1585, 'like', '2026-08-24 10:24:00', '2026-08-24 10:24:00'),
(17488, 1550, 1592, 'pass', '2026-08-23 10:24:00', '2026-08-23 10:24:00'),
(17489, 1550, 1599, 'like', '2026-08-22 10:24:00', '2026-08-22 10:24:00'),
(17490, 1550, 1456, 'like', '2026-08-21 10:24:00', '2026-08-21 10:24:00'),
(17491, 1551, 1558, 'pass', '2026-08-28 10:23:00', '2026-08-28 10:23:00'),
(17492, 1551, 1565, 'like', '2026-08-27 10:23:00', '2026-08-27 10:23:00'),
(17493, 1551, 1572, 'like', '2026-08-26 10:23:00', '2026-08-26 10:23:00'),
(17494, 1551, 1579, 'pass', '2026-08-25 10:23:00', '2026-08-25 10:23:00'),
(17495, 1551, 1586, 'like', '2026-08-24 10:23:00', '2026-08-24 10:23:00'),
(17496, 1551, 1593, 'like', '2026-08-23 10:23:00', '2026-08-23 10:23:00'),
(17497, 1551, 1600, 'pass', '2026-08-22 10:23:00', '2026-08-22 10:23:00'),
(17498, 1551, 1457, 'like', '2026-08-21 10:23:00', '2026-08-21 10:23:00'),
(17499, 1551, 1464, 'like', '2026-08-20 10:23:00', '2026-08-20 10:23:00'),
(17500, 1552, 1559, 'superLike', '2026-08-28 10:22:00', '2026-08-28 10:22:00'),
(17501, 1552, 1566, 'pass', '2026-08-27 10:22:00', '2026-08-27 10:22:00'),
(17502, 1552, 1573, 'like', '2026-08-26 10:22:00', '2026-08-26 10:22:00'),
(17503, 1552, 1580, 'like', '2026-08-25 10:22:00', '2026-08-25 10:22:00'),
(17504, 1552, 1587, 'pass', '2026-08-24 10:22:00', '2026-08-24 10:22:00'),
(17505, 1552, 1594, 'like', '2026-08-23 10:22:00', '2026-08-23 10:22:00'),
(17506, 1552, 1601, 'like', '2026-08-22 10:22:00', '2026-08-22 10:22:00'),
(17507, 1552, 1458, 'pass', '2026-08-21 10:22:00', '2026-08-21 10:22:00'),
(17508, 1552, 1465, 'like', '2026-08-20 10:22:00', '2026-08-20 10:22:00'),
(17509, 1552, 1472, 'like', '2026-08-19 10:22:00', '2026-08-19 10:22:00'),
(17510, 1553, 1560, 'like', '2026-08-28 10:21:00', '2026-08-28 10:21:00'),
(17511, 1553, 1567, 'superLike', '2026-08-27 10:21:00', '2026-08-27 10:21:00'),
(17512, 1553, 1574, 'pass', '2026-08-26 10:21:00', '2026-08-26 10:21:00'),
(17513, 1553, 1581, 'like', '2026-08-25 10:21:00', '2026-08-25 10:21:00'),
(17514, 1553, 1588, 'like', '2026-08-24 10:21:00', '2026-08-24 10:21:00'),
(17515, 1553, 1595, 'pass', '2026-08-23 10:21:00', '2026-08-23 10:21:00'),
(17516, 1553, 1602, 'like', '2026-08-22 10:21:00', '2026-08-22 10:21:00'),
(17517, 1553, 1459, 'like', '2026-08-21 10:21:00', '2026-08-21 10:21:00'),
(17518, 1553, 1466, 'pass', '2026-08-20 10:21:00', '2026-08-20 10:21:00'),
(17519, 1553, 1473, 'like', '2026-08-19 10:21:00', '2026-08-19 10:21:00'),
(17520, 1553, 1480, 'like', '2026-08-18 10:21:00', '2026-08-18 10:21:00'),
(17521, 1554, 1561, 'like', '2026-08-28 10:20:00', '2026-08-28 10:20:00'),
(17522, 1554, 1568, 'like', '2026-08-27 10:20:00', '2026-08-27 10:20:00'),
(17523, 1554, 1575, 'superLike', '2026-08-26 10:20:00', '2026-08-26 10:20:00'),
(17524, 1554, 1582, 'pass', '2026-08-25 10:20:00', '2026-08-25 10:20:00'),
(17525, 1554, 1589, 'like', '2026-08-24 10:20:00', '2026-08-24 10:20:00'),
(17526, 1554, 1596, 'like', '2026-08-23 10:20:00', '2026-08-23 10:20:00'),
(17527, 1554, 1603, 'pass', '2026-08-22 10:20:00', '2026-08-22 10:20:00'),
(17528, 1554, 1460, 'like', '2026-08-21 10:20:00', '2026-08-21 10:20:00'),
(17529, 1554, 1467, 'like', '2026-08-20 10:20:00', '2026-08-20 10:20:00'),
(17530, 1554, 1474, 'pass', '2026-08-19 10:20:00', '2026-08-19 10:20:00'),
(17531, 1554, 1481, 'like', '2026-08-18 10:20:00', '2026-08-18 10:20:00'),
(17532, 1554, 1488, 'like', '2026-08-17 10:20:00', '2026-08-17 10:20:00'),
(17533, 1555, 1562, 'pass', '2026-08-28 10:19:00', '2026-08-28 10:19:00'),
(17534, 1555, 1569, 'like', '2026-08-27 10:19:00', '2026-08-27 10:19:00'),
(17535, 1555, 1576, 'like', '2026-08-26 10:19:00', '2026-08-26 10:19:00'),
(17536, 1555, 1583, 'superLike', '2026-08-25 10:19:00', '2026-08-25 10:19:00'),
(17537, 1555, 1590, 'pass', '2026-08-24 10:19:00', '2026-08-24 10:19:00'),
(17538, 1555, 1597, 'like', '2026-08-23 10:19:00', '2026-08-23 10:19:00'),
(17539, 1555, 1454, 'like', '2026-08-22 10:19:00', '2026-08-22 10:19:00'),
(17540, 1555, 1461, 'pass', '2026-08-21 10:19:00', '2026-08-21 10:19:00'),
(17541, 1555, 1468, 'like', '2026-08-20 10:19:00', '2026-08-20 10:19:00'),
(17542, 1555, 1475, 'like', '2026-08-19 10:19:00', '2026-08-19 10:19:00'),
(17543, 1555, 1482, 'pass', '2026-08-18 10:19:00', '2026-08-18 10:19:00'),
(17544, 1555, 1489, 'like', '2026-08-17 10:19:00', '2026-08-17 10:19:00'),
(17545, 1555, 1496, 'like', '2026-08-16 10:19:00', '2026-08-16 10:19:00'),
(17546, 1556, 1563, 'like', '2026-08-28 10:18:00', '2026-08-28 10:18:00'),
(17547, 1556, 1570, 'pass', '2026-08-27 10:18:00', '2026-08-27 10:18:00'),
(17548, 1556, 1577, 'like', '2026-08-26 10:18:00', '2026-08-26 10:18:00'),
(17549, 1556, 1584, 'like', '2026-08-25 10:18:00', '2026-08-25 10:18:00'),
(17550, 1556, 1591, 'superLike', '2026-08-24 10:18:00', '2026-08-24 10:18:00'),
(17551, 1556, 1598, 'pass', '2026-08-23 10:18:00', '2026-08-23 10:18:00'),
(17552, 1556, 1455, 'like', '2026-08-22 10:18:00', '2026-08-22 10:18:00'),
(17553, 1556, 1462, 'like', '2026-08-21 10:18:00', '2026-08-21 10:18:00'),
(17554, 1556, 1469, 'pass', '2026-08-20 10:18:00', '2026-08-20 10:18:00'),
(17555, 1556, 1476, 'like', '2026-08-19 10:18:00', '2026-08-19 10:18:00'),
(17556, 1556, 1483, 'like', '2026-08-18 10:18:00', '2026-08-18 10:18:00'),
(17557, 1556, 1490, 'pass', '2026-08-17 10:18:00', '2026-08-17 10:18:00'),
(17558, 1556, 1497, 'like', '2026-08-16 10:18:00', '2026-08-16 10:18:00'),
(17559, 1556, 1504, 'like', '2026-08-15 10:18:00', '2026-08-15 10:18:00'),
(17560, 1557, 1564, 'like', '2026-08-28 10:17:00', '2026-08-28 10:17:00'),
(17561, 1557, 1571, 'like', '2026-08-27 10:17:00', '2026-08-27 10:17:00'),
(17562, 1557, 1578, 'pass', '2026-08-26 10:17:00', '2026-08-26 10:17:00'),
(17563, 1557, 1585, 'like', '2026-08-25 10:17:00', '2026-08-25 10:17:00'),
(17564, 1557, 1592, 'like', '2026-08-24 10:17:00', '2026-08-24 10:17:00'),
(17565, 1557, 1599, 'superLike', '2026-08-23 10:17:00', '2026-08-23 10:17:00'),
(17566, 1557, 1456, 'pass', '2026-08-22 10:17:00', '2026-08-22 10:17:00'),
(17567, 1557, 1463, 'like', '2026-08-21 10:17:00', '2026-08-21 10:17:00'),
(17568, 1557, 1470, 'like', '2026-08-20 10:17:00', '2026-08-20 10:17:00'),
(17569, 1557, 1477, 'pass', '2026-08-19 10:17:00', '2026-08-19 10:17:00'),
(17570, 1557, 1484, 'like', '2026-08-18 10:17:00', '2026-08-18 10:17:00'),
(17571, 1557, 1491, 'like', '2026-08-17 10:17:00', '2026-08-17 10:17:00'),
(17572, 1557, 1498, 'pass', '2026-08-16 10:17:00', '2026-08-16 10:17:00'),
(17573, 1557, 1505, 'like', '2026-08-15 10:17:00', '2026-08-15 10:17:00'),
(17574, 1557, 1512, 'like', '2026-08-14 10:17:00', '2026-08-14 10:17:00'),
(17575, 1558, 1565, 'pass', '2026-08-28 10:16:00', '2026-08-28 10:16:00'),
(17576, 1558, 1572, 'like', '2026-08-27 10:16:00', '2026-08-27 10:16:00'),
(17577, 1558, 1579, 'like', '2026-08-26 10:16:00', '2026-08-26 10:16:00'),
(17578, 1558, 1586, 'pass', '2026-08-25 10:16:00', '2026-08-25 10:16:00'),
(17579, 1558, 1593, 'like', '2026-08-24 10:16:00', '2026-08-24 10:16:00'),
(17580, 1558, 1600, 'like', '2026-08-23 10:16:00', '2026-08-23 10:16:00'),
(17581, 1558, 1457, 'superLike', '2026-08-22 10:16:00', '2026-08-22 10:16:00'),
(17582, 1558, 1464, 'pass', '2026-08-21 10:16:00', '2026-08-21 10:16:00'),
(17583, 1559, 1566, 'like', '2026-08-28 10:15:00', '2026-08-28 10:15:00'),
(17584, 1559, 1573, 'pass', '2026-08-27 10:15:00', '2026-08-27 10:15:00'),
(17585, 1559, 1580, 'like', '2026-08-26 10:15:00', '2026-08-26 10:15:00'),
(17586, 1559, 1587, 'like', '2026-08-25 10:15:00', '2026-08-25 10:15:00'),
(17587, 1559, 1594, 'pass', '2026-08-24 10:15:00', '2026-08-24 10:15:00'),
(17588, 1559, 1601, 'like', '2026-08-23 10:15:00', '2026-08-23 10:15:00'),
(17589, 1559, 1458, 'like', '2026-08-22 10:15:00', '2026-08-22 10:15:00'),
(17590, 1559, 1465, 'superLike', '2026-08-21 10:15:00', '2026-08-21 10:15:00'),
(17591, 1559, 1472, 'pass', '2026-08-20 10:15:00', '2026-08-20 10:15:00'),
(17592, 1560, 1567, 'like', '2026-08-28 10:14:00', '2026-08-28 10:14:00'),
(17593, 1560, 1574, 'like', '2026-08-27 10:14:00', '2026-08-27 10:14:00'),
(17594, 1560, 1581, 'pass', '2026-08-26 10:14:00', '2026-08-26 10:14:00'),
(17595, 1560, 1588, 'like', '2026-08-25 10:14:00', '2026-08-25 10:14:00'),
(17596, 1560, 1595, 'like', '2026-08-24 10:14:00', '2026-08-24 10:14:00'),
(17597, 1560, 1602, 'pass', '2026-08-23 10:14:00', '2026-08-23 10:14:00'),
(17598, 1560, 1459, 'like', '2026-08-22 10:14:00', '2026-08-22 10:14:00'),
(17599, 1560, 1466, 'like', '2026-08-21 10:14:00', '2026-08-21 10:14:00'),
(17600, 1560, 1473, 'superLike', '2026-08-20 10:14:00', '2026-08-20 10:14:00'),
(17601, 1560, 1480, 'pass', '2026-08-19 10:14:00', '2026-08-19 10:14:00'),
(17602, 1561, 1568, 'pass', '2026-08-28 10:13:00', '2026-08-28 10:13:00'),
(17603, 1561, 1575, 'like', '2026-08-27 10:13:00', '2026-08-27 10:13:00'),
(17604, 1561, 1582, 'like', '2026-08-26 10:13:00', '2026-08-26 10:13:00'),
(17605, 1561, 1589, 'pass', '2026-08-25 10:13:00', '2026-08-25 10:13:00'),
(17606, 1561, 1596, 'like', '2026-08-24 10:13:00', '2026-08-24 10:13:00'),
(17607, 1561, 1603, 'like', '2026-08-23 10:13:00', '2026-08-23 10:13:00'),
(17608, 1561, 1460, 'pass', '2026-08-22 10:13:00', '2026-08-22 10:13:00'),
(17609, 1561, 1467, 'like', '2026-08-21 10:13:00', '2026-08-21 10:13:00'),
(17610, 1561, 1474, 'like', '2026-08-20 10:13:00', '2026-08-20 10:13:00'),
(17611, 1561, 1481, 'superLike', '2026-08-19 10:13:00', '2026-08-19 10:13:00'),
(17612, 1561, 1488, 'pass', '2026-08-18 10:13:00', '2026-08-18 10:13:00'),
(17613, 1562, 1569, 'superLike', '2026-08-28 10:12:00', '2026-08-28 10:12:00'),
(17614, 1562, 1576, 'pass', '2026-08-27 10:12:00', '2026-08-27 10:12:00'),
(17615, 1562, 1583, 'like', '2026-08-26 10:12:00', '2026-08-26 10:12:00'),
(17616, 1562, 1590, 'like', '2026-08-25 10:12:00', '2026-08-25 10:12:00'),
(17617, 1562, 1597, 'pass', '2026-08-24 10:12:00', '2026-08-24 10:12:00'),
(17618, 1562, 1454, 'like', '2026-08-23 10:12:00', '2026-08-23 10:12:00'),
(17619, 1562, 1461, 'like', '2026-08-22 10:12:00', '2026-08-22 10:12:00'),
(17620, 1562, 1468, 'pass', '2026-08-21 10:12:00', '2026-08-21 10:12:00'),
(17621, 1562, 1475, 'like', '2026-08-20 10:12:00', '2026-08-20 10:12:00'),
(17622, 1562, 1482, 'like', '2026-08-19 10:12:00', '2026-08-19 10:12:00'),
(17623, 1562, 1489, 'superLike', '2026-08-18 10:12:00', '2026-08-18 10:12:00'),
(17624, 1562, 1496, 'pass', '2026-08-17 10:12:00', '2026-08-17 10:12:00'),
(17625, 1563, 1570, 'like', '2026-08-28 10:11:00', '2026-08-28 10:11:00'),
(17626, 1563, 1577, 'superLike', '2026-08-27 10:11:00', '2026-08-27 10:11:00'),
(17627, 1563, 1584, 'pass', '2026-08-26 10:11:00', '2026-08-26 10:11:00'),
(17628, 1563, 1591, 'like', '2026-08-25 10:11:00', '2026-08-25 10:11:00'),
(17629, 1563, 1598, 'like', '2026-08-24 10:11:00', '2026-08-24 10:11:00'),
(17630, 1563, 1455, 'pass', '2026-08-23 10:11:00', '2026-08-23 10:11:00'),
(17631, 1563, 1462, 'like', '2026-08-22 10:11:00', '2026-08-22 10:11:00'),
(17632, 1563, 1469, 'like', '2026-08-21 10:11:00', '2026-08-21 10:11:00'),
(17633, 1563, 1476, 'pass', '2026-08-20 10:11:00', '2026-08-20 10:11:00'),
(17634, 1563, 1483, 'like', '2026-08-19 10:11:00', '2026-08-19 10:11:00'),
(17635, 1563, 1490, 'like', '2026-08-18 10:11:00', '2026-08-18 10:11:00'),
(17636, 1563, 1497, 'superLike', '2026-08-17 10:11:00', '2026-08-17 10:11:00'),
(17637, 1563, 1504, 'pass', '2026-08-16 10:11:00', '2026-08-16 10:11:00'),
(17638, 1564, 1571, 'like', '2026-08-28 10:10:00', '2026-08-28 10:10:00'),
(17639, 1564, 1578, 'like', '2026-08-27 10:10:00', '2026-08-27 10:10:00'),
(17640, 1564, 1585, 'superLike', '2026-08-26 10:10:00', '2026-08-26 10:10:00'),
(17641, 1564, 1592, 'pass', '2026-08-25 10:10:00', '2026-08-25 10:10:00'),
(17642, 1564, 1599, 'like', '2026-08-24 10:10:00', '2026-08-24 10:10:00'),
(17643, 1564, 1456, 'like', '2026-08-23 10:10:00', '2026-08-23 10:10:00'),
(17644, 1564, 1463, 'pass', '2026-08-22 10:10:00', '2026-08-22 10:10:00'),
(17645, 1564, 1470, 'like', '2026-08-21 10:10:00', '2026-08-21 10:10:00'),
(17646, 1564, 1477, 'like', '2026-08-20 10:10:00', '2026-08-20 10:10:00'),
(17647, 1564, 1484, 'pass', '2026-08-19 10:10:00', '2026-08-19 10:10:00'),
(17648, 1564, 1491, 'like', '2026-08-18 10:10:00', '2026-08-18 10:10:00'),
(17649, 1564, 1498, 'like', '2026-08-17 10:10:00', '2026-08-17 10:10:00'),
(17650, 1564, 1505, 'superLike', '2026-08-16 10:10:00', '2026-08-16 10:10:00'),
(17651, 1564, 1512, 'pass', '2026-08-15 10:10:00', '2026-08-15 10:10:00'),
(17652, 1565, 1572, 'pass', '2026-08-28 10:09:00', '2026-08-28 10:09:00'),
(17653, 1565, 1579, 'like', '2026-08-27 10:09:00', '2026-08-27 10:09:00'),
(17654, 1565, 1586, 'like', '2026-08-26 10:09:00', '2026-08-26 10:09:00'),
(17655, 1565, 1593, 'superLike', '2026-08-25 10:09:00', '2026-08-25 10:09:00'),
(17656, 1565, 1600, 'pass', '2026-08-24 10:09:00', '2026-08-24 10:09:00'),
(17657, 1565, 1457, 'like', '2026-08-23 10:09:00', '2026-08-23 10:09:00'),
(17658, 1565, 1464, 'like', '2026-08-22 10:09:00', '2026-08-22 10:09:00'),
(17659, 1565, 1471, 'pass', '2026-08-21 10:09:00', '2026-08-21 10:09:00'),
(17660, 1565, 1478, 'like', '2026-08-20 10:09:00', '2026-08-20 10:09:00'),
(17661, 1565, 1485, 'like', '2026-08-19 10:09:00', '2026-08-19 10:09:00'),
(17662, 1565, 1492, 'pass', '2026-08-18 10:09:00', '2026-08-18 10:09:00'),
(17663, 1565, 1499, 'like', '2026-08-17 10:09:00', '2026-08-17 10:09:00'),
(17664, 1565, 1506, 'like', '2026-08-16 10:09:00', '2026-08-16 10:09:00'),
(17665, 1565, 1513, 'superLike', '2026-08-15 10:09:00', '2026-08-15 10:09:00'),
(17666, 1565, 1520, 'pass', '2026-08-14 10:09:00', '2026-08-14 10:09:00'),
(17667, 1566, 1573, 'like', '2026-08-28 10:08:00', '2026-08-28 10:08:00'),
(17668, 1566, 1580, 'pass', '2026-08-27 10:08:00', '2026-08-27 10:08:00'),
(17669, 1566, 1587, 'like', '2026-08-26 10:08:00', '2026-08-26 10:08:00'),
(17670, 1566, 1594, 'like', '2026-08-25 10:08:00', '2026-08-25 10:08:00'),
(17671, 1566, 1601, 'superLike', '2026-08-24 10:08:00', '2026-08-24 10:08:00'),
(17672, 1566, 1458, 'pass', '2026-08-23 10:08:00', '2026-08-23 10:08:00'),
(17673, 1566, 1465, 'like', '2026-08-22 10:08:00', '2026-08-22 10:08:00'),
(17674, 1566, 1472, 'like', '2026-08-21 10:08:00', '2026-08-21 10:08:00'),
(17675, 1567, 1574, 'like', '2026-08-28 10:07:00', '2026-08-28 10:07:00'),
(17676, 1567, 1581, 'like', '2026-08-27 10:07:00', '2026-08-27 10:07:00'),
(17677, 1567, 1588, 'pass', '2026-08-26 10:07:00', '2026-08-26 10:07:00'),
(17678, 1567, 1595, 'like', '2026-08-25 10:07:00', '2026-08-25 10:07:00'),
(17679, 1567, 1602, 'like', '2026-08-24 10:07:00', '2026-08-24 10:07:00'),
(17680, 1567, 1459, 'superLike', '2026-08-23 10:07:00', '2026-08-23 10:07:00'),
(17681, 1567, 1466, 'pass', '2026-08-22 10:07:00', '2026-08-22 10:07:00'),
(17682, 1567, 1473, 'like', '2026-08-21 10:07:00', '2026-08-21 10:07:00'),
(17683, 1567, 1480, 'like', '2026-08-20 10:07:00', '2026-08-20 10:07:00'),
(17684, 1568, 1575, 'pass', '2026-08-28 10:06:00', '2026-08-28 10:06:00'),
(17685, 1568, 1582, 'like', '2026-08-27 10:06:00', '2026-08-27 10:06:00'),
(17686, 1568, 1589, 'like', '2026-08-26 10:06:00', '2026-08-26 10:06:00'),
(17687, 1568, 1596, 'pass', '2026-08-25 10:06:00', '2026-08-25 10:06:00'),
(17688, 1568, 1603, 'like', '2026-08-24 10:06:00', '2026-08-24 10:06:00'),
(17689, 1568, 1460, 'like', '2026-08-23 10:06:00', '2026-08-23 10:06:00'),
(17690, 1568, 1467, 'superLike', '2026-08-22 10:06:00', '2026-08-22 10:06:00'),
(17691, 1568, 1474, 'pass', '2026-08-21 10:06:00', '2026-08-21 10:06:00'),
(17692, 1568, 1481, 'like', '2026-08-20 10:06:00', '2026-08-20 10:06:00'),
(17693, 1568, 1488, 'like', '2026-08-19 10:06:00', '2026-08-19 10:06:00'),
(17694, 1569, 1576, 'like', '2026-08-28 10:05:00', '2026-08-28 10:05:00'),
(17695, 1569, 1583, 'pass', '2026-08-27 10:05:00', '2026-08-27 10:05:00'),
(17696, 1569, 1590, 'like', '2026-08-26 10:05:00', '2026-08-26 10:05:00'),
(17697, 1569, 1597, 'like', '2026-08-25 10:05:00', '2026-08-25 10:05:00'),
(17698, 1569, 1454, 'pass', '2026-08-24 10:05:00', '2026-08-24 10:05:00'),
(17699, 1569, 1461, 'like', '2026-08-23 10:05:00', '2026-08-23 10:05:00'),
(17700, 1569, 1468, 'like', '2026-08-22 10:05:00', '2026-08-22 10:05:00'),
(17701, 1569, 1475, 'superLike', '2026-08-21 10:05:00', '2026-08-21 10:05:00'),
(17702, 1569, 1482, 'pass', '2026-08-20 10:05:00', '2026-08-20 10:05:00'),
(17703, 1569, 1489, 'like', '2026-08-19 10:05:00', '2026-08-19 10:05:00'),
(17704, 1569, 1496, 'like', '2026-08-18 10:05:00', '2026-08-18 10:05:00'),
(17705, 1570, 1577, 'like', '2026-08-28 10:04:00', '2026-08-28 10:04:00'),
(17706, 1570, 1584, 'like', '2026-08-27 10:04:00', '2026-08-27 10:04:00'),
(17707, 1570, 1591, 'pass', '2026-08-26 10:04:00', '2026-08-26 10:04:00'),
(17708, 1570, 1598, 'like', '2026-08-25 10:04:00', '2026-08-25 10:04:00'),
(17709, 1570, 1455, 'like', '2026-08-24 10:04:00', '2026-08-24 10:04:00'),
(17710, 1570, 1462, 'pass', '2026-08-23 10:04:00', '2026-08-23 10:04:00'),
(17711, 1570, 1469, 'like', '2026-08-22 10:04:00', '2026-08-22 10:04:00');
INSERT INTO `discoveractions` (`id`, `actorUserId`, `targetUserId`, `action`, `createdAt`, `updatedAt`) VALUES
(17712, 1570, 1476, 'like', '2026-08-21 10:04:00', '2026-08-21 10:04:00'),
(17713, 1570, 1483, 'superLike', '2026-08-20 10:04:00', '2026-08-20 10:04:00'),
(17714, 1570, 1490, 'pass', '2026-08-19 10:04:00', '2026-08-19 10:04:00'),
(17715, 1570, 1497, 'like', '2026-08-18 10:04:00', '2026-08-18 10:04:00'),
(17716, 1570, 1504, 'like', '2026-08-17 10:04:00', '2026-08-17 10:04:00'),
(17717, 1571, 1578, 'pass', '2026-08-28 10:03:00', '2026-08-28 10:03:00'),
(17718, 1571, 1585, 'like', '2026-08-27 10:03:00', '2026-08-27 10:03:00'),
(17719, 1571, 1592, 'like', '2026-08-26 10:03:00', '2026-08-26 10:03:00'),
(17720, 1571, 1599, 'pass', '2026-08-25 10:03:00', '2026-08-25 10:03:00'),
(17721, 1571, 1456, 'like', '2026-08-24 10:03:00', '2026-08-24 10:03:00'),
(17722, 1571, 1463, 'like', '2026-08-23 10:03:00', '2026-08-23 10:03:00'),
(17723, 1571, 1470, 'pass', '2026-08-22 10:03:00', '2026-08-22 10:03:00'),
(17724, 1571, 1477, 'like', '2026-08-21 10:03:00', '2026-08-21 10:03:00'),
(17725, 1571, 1484, 'like', '2026-08-20 10:03:00', '2026-08-20 10:03:00'),
(17726, 1571, 1491, 'superLike', '2026-08-19 10:03:00', '2026-08-19 10:03:00'),
(17727, 1571, 1498, 'pass', '2026-08-18 10:03:00', '2026-08-18 10:03:00'),
(17728, 1571, 1505, 'like', '2026-08-17 10:03:00', '2026-08-17 10:03:00'),
(17729, 1571, 1512, 'like', '2026-08-16 10:03:00', '2026-08-16 10:03:00'),
(17730, 1572, 1579, 'superLike', '2026-08-28 10:02:00', '2026-08-28 10:02:00'),
(17731, 1572, 1586, 'pass', '2026-08-27 10:02:00', '2026-08-27 10:02:00'),
(17732, 1572, 1593, 'like', '2026-08-26 10:02:00', '2026-08-26 10:02:00'),
(17733, 1572, 1600, 'like', '2026-08-25 10:02:00', '2026-08-25 10:02:00'),
(17734, 1572, 1457, 'pass', '2026-08-24 10:02:00', '2026-08-24 10:02:00'),
(17735, 1572, 1464, 'like', '2026-08-23 10:02:00', '2026-08-23 10:02:00'),
(17736, 1572, 1471, 'like', '2026-08-22 10:02:00', '2026-08-22 10:02:00'),
(17737, 1572, 1478, 'pass', '2026-08-21 10:02:00', '2026-08-21 10:02:00'),
(17738, 1572, 1485, 'like', '2026-08-20 10:02:00', '2026-08-20 10:02:00'),
(17739, 1572, 1492, 'like', '2026-08-19 10:02:00', '2026-08-19 10:02:00'),
(17740, 1572, 1499, 'superLike', '2026-08-18 10:02:00', '2026-08-18 10:02:00'),
(17741, 1572, 1506, 'pass', '2026-08-17 10:02:00', '2026-08-17 10:02:00'),
(17742, 1572, 1513, 'like', '2026-08-16 10:02:00', '2026-08-16 10:02:00'),
(17743, 1572, 1520, 'like', '2026-08-15 10:02:00', '2026-08-15 10:02:00'),
(17744, 1573, 1580, 'like', '2026-08-28 10:01:00', '2026-08-28 10:01:00'),
(17745, 1573, 1587, 'superLike', '2026-08-27 10:01:00', '2026-08-27 10:01:00'),
(17746, 1573, 1594, 'pass', '2026-08-26 10:01:00', '2026-08-26 10:01:00'),
(17747, 1573, 1601, 'like', '2026-08-25 10:01:00', '2026-08-25 10:01:00'),
(17748, 1573, 1458, 'like', '2026-08-24 10:01:00', '2026-08-24 10:01:00'),
(17749, 1573, 1465, 'pass', '2026-08-23 10:01:00', '2026-08-23 10:01:00'),
(17750, 1573, 1472, 'like', '2026-08-22 10:01:00', '2026-08-22 10:01:00'),
(17751, 1573, 1479, 'like', '2026-08-21 10:01:00', '2026-08-21 10:01:00'),
(17752, 1573, 1486, 'pass', '2026-08-20 10:01:00', '2026-08-20 10:01:00'),
(17753, 1573, 1493, 'like', '2026-08-19 10:01:00', '2026-08-19 10:01:00'),
(17754, 1573, 1500, 'like', '2026-08-18 10:01:00', '2026-08-18 10:01:00'),
(17755, 1573, 1507, 'superLike', '2026-08-17 10:01:00', '2026-08-17 10:01:00'),
(17756, 1573, 1514, 'pass', '2026-08-16 10:01:00', '2026-08-16 10:01:00'),
(17757, 1573, 1521, 'like', '2026-08-15 10:01:00', '2026-08-15 10:01:00'),
(17758, 1573, 1528, 'like', '2026-08-14 10:01:00', '2026-08-14 10:01:00'),
(17759, 1574, 1581, 'like', '2026-08-28 10:00:00', '2026-08-28 10:00:00'),
(17760, 1574, 1588, 'like', '2026-08-27 10:00:00', '2026-08-27 10:00:00'),
(17761, 1574, 1595, 'superLike', '2026-08-26 10:00:00', '2026-08-26 10:00:00'),
(17762, 1574, 1602, 'pass', '2026-08-25 10:00:00', '2026-08-25 10:00:00'),
(17763, 1574, 1459, 'like', '2026-08-24 10:00:00', '2026-08-24 10:00:00'),
(17764, 1574, 1466, 'like', '2026-08-23 10:00:00', '2026-08-23 10:00:00'),
(17765, 1574, 1473, 'pass', '2026-08-22 10:00:00', '2026-08-22 10:00:00'),
(17766, 1574, 1480, 'like', '2026-08-21 10:00:00', '2026-08-21 10:00:00'),
(17767, 1575, 1582, 'pass', '2026-08-28 09:59:00', '2026-08-28 09:59:00'),
(17768, 1575, 1589, 'like', '2026-08-27 09:59:00', '2026-08-27 09:59:00'),
(17769, 1575, 1596, 'like', '2026-08-26 09:59:00', '2026-08-26 09:59:00'),
(17770, 1575, 1603, 'superLike', '2026-08-25 09:59:00', '2026-08-25 09:59:00'),
(17771, 1575, 1460, 'pass', '2026-08-24 09:59:00', '2026-08-24 09:59:00'),
(17772, 1575, 1467, 'like', '2026-08-23 09:59:00', '2026-08-23 09:59:00'),
(17773, 1575, 1474, 'like', '2026-08-22 09:59:00', '2026-08-22 09:59:00'),
(17774, 1575, 1481, 'pass', '2026-08-21 09:59:00', '2026-08-21 09:59:00'),
(17775, 1575, 1488, 'like', '2026-08-20 09:59:00', '2026-08-20 09:59:00'),
(17776, 1576, 1583, 'like', '2026-08-28 09:58:00', '2026-08-28 09:58:00'),
(17777, 1576, 1590, 'pass', '2026-08-27 09:58:00', '2026-08-27 09:58:00'),
(17778, 1576, 1597, 'like', '2026-08-26 09:58:00', '2026-08-26 09:58:00'),
(17779, 1576, 1454, 'like', '2026-08-25 09:58:00', '2026-08-25 09:58:00'),
(17780, 1576, 1461, 'superLike', '2026-08-24 09:58:00', '2026-08-24 09:58:00'),
(17781, 1576, 1468, 'pass', '2026-08-23 09:58:00', '2026-08-23 09:58:00'),
(17782, 1576, 1475, 'like', '2026-08-22 09:58:00', '2026-08-22 09:58:00'),
(17783, 1576, 1482, 'like', '2026-08-21 09:58:00', '2026-08-21 09:58:00'),
(17784, 1576, 1489, 'pass', '2026-08-20 09:58:00', '2026-08-20 09:58:00'),
(17785, 1576, 1496, 'like', '2026-08-19 09:58:00', '2026-08-19 09:58:00'),
(17786, 1577, 1584, 'like', '2026-08-28 09:57:00', '2026-08-28 09:57:00'),
(17787, 1577, 1591, 'like', '2026-08-27 09:57:00', '2026-08-27 09:57:00'),
(17788, 1577, 1598, 'pass', '2026-08-26 09:57:00', '2026-08-26 09:57:00'),
(17789, 1577, 1455, 'like', '2026-08-25 09:57:00', '2026-08-25 09:57:00'),
(17790, 1577, 1462, 'like', '2026-08-24 09:57:00', '2026-08-24 09:57:00'),
(17791, 1577, 1469, 'superLike', '2026-08-23 09:57:00', '2026-08-23 09:57:00'),
(17792, 1577, 1476, 'pass', '2026-08-22 09:57:00', '2026-08-22 09:57:00'),
(17793, 1577, 1483, 'like', '2026-08-21 09:57:00', '2026-08-21 09:57:00'),
(17794, 1577, 1490, 'like', '2026-08-20 09:57:00', '2026-08-20 09:57:00'),
(17795, 1577, 1497, 'pass', '2026-08-19 09:57:00', '2026-08-19 09:57:00'),
(17796, 1577, 1504, 'like', '2026-08-18 09:57:00', '2026-08-18 09:57:00'),
(17797, 1578, 1585, 'pass', '2026-08-28 09:56:00', '2026-08-28 09:56:00'),
(17798, 1578, 1592, 'like', '2026-08-27 09:56:00', '2026-08-27 09:56:00'),
(17799, 1578, 1599, 'like', '2026-08-26 09:56:00', '2026-08-26 09:56:00'),
(17800, 1578, 1456, 'pass', '2026-08-25 09:56:00', '2026-08-25 09:56:00'),
(17801, 1578, 1463, 'like', '2026-08-24 09:56:00', '2026-08-24 09:56:00'),
(17802, 1578, 1470, 'like', '2026-08-23 09:56:00', '2026-08-23 09:56:00'),
(17803, 1578, 1477, 'superLike', '2026-08-22 09:56:00', '2026-08-22 09:56:00'),
(17804, 1578, 1484, 'pass', '2026-08-21 09:56:00', '2026-08-21 09:56:00'),
(17805, 1578, 1491, 'like', '2026-08-20 09:56:00', '2026-08-20 09:56:00'),
(17806, 1578, 1498, 'like', '2026-08-19 09:56:00', '2026-08-19 09:56:00'),
(17807, 1578, 1505, 'pass', '2026-08-18 09:56:00', '2026-08-18 09:56:00'),
(17808, 1578, 1512, 'like', '2026-08-17 09:56:00', '2026-08-17 09:56:00'),
(17809, 1579, 1586, 'like', '2026-08-28 09:55:00', '2026-08-28 09:55:00'),
(17810, 1579, 1593, 'pass', '2026-08-27 09:55:00', '2026-08-27 09:55:00'),
(17811, 1579, 1600, 'like', '2026-08-26 09:55:00', '2026-08-26 09:55:00'),
(17812, 1579, 1457, 'like', '2026-08-25 09:55:00', '2026-08-25 09:55:00'),
(17813, 1579, 1464, 'pass', '2026-08-24 09:55:00', '2026-08-24 09:55:00'),
(17814, 1579, 1471, 'like', '2026-08-23 09:55:00', '2026-08-23 09:55:00'),
(17815, 1579, 1478, 'like', '2026-08-22 09:55:00', '2026-08-22 09:55:00'),
(17816, 1579, 1485, 'superLike', '2026-08-21 09:55:00', '2026-08-21 09:55:00'),
(17817, 1579, 1492, 'pass', '2026-08-20 09:55:00', '2026-08-20 09:55:00'),
(17818, 1579, 1499, 'like', '2026-08-19 09:55:00', '2026-08-19 09:55:00'),
(17819, 1579, 1506, 'like', '2026-08-18 09:55:00', '2026-08-18 09:55:00'),
(17820, 1579, 1513, 'pass', '2026-08-17 09:55:00', '2026-08-17 09:55:00'),
(17821, 1579, 1520, 'like', '2026-08-16 09:55:00', '2026-08-16 09:55:00'),
(17822, 1580, 1587, 'like', '2026-08-28 09:54:00', '2026-08-28 09:54:00'),
(17823, 1580, 1594, 'like', '2026-08-27 09:54:00', '2026-08-27 09:54:00'),
(17824, 1580, 1601, 'pass', '2026-08-26 09:54:00', '2026-08-26 09:54:00'),
(17825, 1580, 1458, 'like', '2026-08-25 09:54:00', '2026-08-25 09:54:00'),
(17826, 1580, 1465, 'like', '2026-08-24 09:54:00', '2026-08-24 09:54:00'),
(17827, 1580, 1472, 'pass', '2026-08-23 09:54:00', '2026-08-23 09:54:00'),
(17828, 1580, 1479, 'like', '2026-08-22 09:54:00', '2026-08-22 09:54:00'),
(17829, 1580, 1486, 'like', '2026-08-21 09:54:00', '2026-08-21 09:54:00'),
(17830, 1580, 1493, 'superLike', '2026-08-20 09:54:00', '2026-08-20 09:54:00'),
(17831, 1580, 1500, 'pass', '2026-08-19 09:54:00', '2026-08-19 09:54:00'),
(17832, 1580, 1507, 'like', '2026-08-18 09:54:00', '2026-08-18 09:54:00'),
(17833, 1580, 1514, 'like', '2026-08-17 09:54:00', '2026-08-17 09:54:00'),
(17834, 1580, 1521, 'pass', '2026-08-16 09:54:00', '2026-08-16 09:54:00'),
(17835, 1580, 1528, 'like', '2026-08-15 09:54:00', '2026-08-15 09:54:00'),
(17836, 1581, 1588, 'pass', '2026-08-28 09:53:00', '2026-08-28 09:53:00'),
(17837, 1581, 1595, 'like', '2026-08-27 09:53:00', '2026-08-27 09:53:00'),
(17838, 1581, 1602, 'like', '2026-08-26 09:53:00', '2026-08-26 09:53:00'),
(17839, 1581, 1459, 'pass', '2026-08-25 09:53:00', '2026-08-25 09:53:00'),
(17840, 1581, 1466, 'like', '2026-08-24 09:53:00', '2026-08-24 09:53:00'),
(17841, 1581, 1473, 'like', '2026-08-23 09:53:00', '2026-08-23 09:53:00'),
(17842, 1581, 1480, 'pass', '2026-08-22 09:53:00', '2026-08-22 09:53:00'),
(17843, 1581, 1487, 'like', '2026-08-21 09:53:00', '2026-08-21 09:53:00'),
(17844, 1581, 1494, 'like', '2026-08-20 09:53:00', '2026-08-20 09:53:00'),
(17845, 1581, 1501, 'superLike', '2026-08-19 09:53:00', '2026-08-19 09:53:00'),
(17846, 1581, 1508, 'pass', '2026-08-18 09:53:00', '2026-08-18 09:53:00'),
(17847, 1581, 1515, 'like', '2026-08-17 09:53:00', '2026-08-17 09:53:00'),
(17848, 1581, 1522, 'like', '2026-08-16 09:53:00', '2026-08-16 09:53:00'),
(17849, 1581, 1529, 'pass', '2026-08-15 09:53:00', '2026-08-15 09:53:00'),
(17850, 1581, 1536, 'like', '2026-08-14 09:53:00', '2026-08-14 09:53:00'),
(17851, 1582, 1589, 'superLike', '2026-08-28 09:52:00', '2026-08-28 09:52:00'),
(17852, 1582, 1596, 'pass', '2026-08-27 09:52:00', '2026-08-27 09:52:00'),
(17853, 1582, 1603, 'like', '2026-08-26 09:52:00', '2026-08-26 09:52:00'),
(17854, 1582, 1460, 'like', '2026-08-25 09:52:00', '2026-08-25 09:52:00'),
(17855, 1582, 1467, 'pass', '2026-08-24 09:52:00', '2026-08-24 09:52:00'),
(17856, 1582, 1474, 'like', '2026-08-23 09:52:00', '2026-08-23 09:52:00'),
(17857, 1582, 1481, 'like', '2026-08-22 09:52:00', '2026-08-22 09:52:00'),
(17858, 1582, 1488, 'pass', '2026-08-21 09:52:00', '2026-08-21 09:52:00'),
(17859, 1583, 1590, 'like', '2026-08-28 09:51:00', '2026-08-28 09:51:00'),
(17860, 1583, 1597, 'superLike', '2026-08-27 09:51:00', '2026-08-27 09:51:00'),
(17861, 1583, 1454, 'pass', '2026-08-26 09:51:00', '2026-08-26 09:51:00'),
(17862, 1583, 1461, 'like', '2026-08-25 09:51:00', '2026-08-25 09:51:00'),
(17863, 1583, 1468, 'like', '2026-08-24 09:51:00', '2026-08-24 09:51:00'),
(17864, 1583, 1475, 'pass', '2026-08-23 09:51:00', '2026-08-23 09:51:00'),
(17865, 1583, 1482, 'like', '2026-08-22 09:51:00', '2026-08-22 09:51:00'),
(17866, 1583, 1489, 'like', '2026-08-21 09:51:00', '2026-08-21 09:51:00'),
(17867, 1583, 1496, 'pass', '2026-08-20 09:51:00', '2026-08-20 09:51:00'),
(17868, 1584, 1591, 'like', '2026-08-28 09:50:00', '2026-08-28 09:50:00'),
(17869, 1584, 1598, 'like', '2026-08-27 09:50:00', '2026-08-27 09:50:00'),
(17870, 1584, 1455, 'superLike', '2026-08-26 09:50:00', '2026-08-26 09:50:00'),
(17871, 1584, 1462, 'pass', '2026-08-25 09:50:00', '2026-08-25 09:50:00'),
(17872, 1584, 1469, 'like', '2026-08-24 09:50:00', '2026-08-24 09:50:00'),
(17873, 1584, 1476, 'like', '2026-08-23 09:50:00', '2026-08-23 09:50:00'),
(17874, 1584, 1483, 'pass', '2026-08-22 09:50:00', '2026-08-22 09:50:00'),
(17875, 1584, 1490, 'like', '2026-08-21 09:50:00', '2026-08-21 09:50:00'),
(17876, 1584, 1497, 'like', '2026-08-20 09:50:00', '2026-08-20 09:50:00'),
(17877, 1584, 1504, 'pass', '2026-08-19 09:50:00', '2026-08-19 09:50:00'),
(17878, 1585, 1592, 'pass', '2026-08-28 09:49:00', '2026-08-28 09:49:00'),
(17879, 1585, 1599, 'like', '2026-08-27 09:49:00', '2026-08-27 09:49:00'),
(17880, 1585, 1456, 'like', '2026-08-26 09:49:00', '2026-08-26 09:49:00'),
(17881, 1585, 1463, 'superLike', '2026-08-25 09:49:00', '2026-08-25 09:49:00'),
(17882, 1585, 1470, 'pass', '2026-08-24 09:49:00', '2026-08-24 09:49:00'),
(17883, 1585, 1477, 'like', '2026-08-23 09:49:00', '2026-08-23 09:49:00'),
(17884, 1585, 1484, 'like', '2026-08-22 09:49:00', '2026-08-22 09:49:00'),
(17885, 1585, 1491, 'pass', '2026-08-21 09:49:00', '2026-08-21 09:49:00'),
(17886, 1585, 1498, 'like', '2026-08-20 09:49:00', '2026-08-20 09:49:00'),
(17887, 1585, 1505, 'like', '2026-08-19 09:49:00', '2026-08-19 09:49:00'),
(17888, 1585, 1512, 'pass', '2026-08-18 09:49:00', '2026-08-18 09:49:00'),
(17889, 1586, 1593, 'like', '2026-08-28 09:48:00', '2026-08-28 09:48:00'),
(17890, 1586, 1600, 'pass', '2026-08-27 09:48:00', '2026-08-27 09:48:00'),
(17891, 1586, 1457, 'like', '2026-08-26 09:48:00', '2026-08-26 09:48:00'),
(17892, 1586, 1464, 'like', '2026-08-25 09:48:00', '2026-08-25 09:48:00'),
(17893, 1586, 1471, 'superLike', '2026-08-24 09:48:00', '2026-08-24 09:48:00'),
(17894, 1586, 1478, 'pass', '2026-08-23 09:48:00', '2026-08-23 09:48:00'),
(17895, 1586, 1485, 'like', '2026-08-22 09:48:00', '2026-08-22 09:48:00'),
(17896, 1586, 1492, 'like', '2026-08-21 09:48:00', '2026-08-21 09:48:00'),
(17897, 1586, 1499, 'pass', '2026-08-20 09:48:00', '2026-08-20 09:48:00'),
(17898, 1586, 1506, 'like', '2026-08-19 09:48:00', '2026-08-19 09:48:00'),
(17899, 1586, 1513, 'like', '2026-08-18 09:48:00', '2026-08-18 09:48:00'),
(17900, 1586, 1520, 'pass', '2026-08-17 09:48:00', '2026-08-17 09:48:00'),
(17901, 1587, 1594, 'like', '2026-08-28 09:47:00', '2026-08-28 09:47:00'),
(17902, 1587, 1601, 'like', '2026-08-27 09:47:00', '2026-08-27 09:47:00'),
(17903, 1587, 1458, 'pass', '2026-08-26 09:47:00', '2026-08-26 09:47:00'),
(17904, 1587, 1465, 'like', '2026-08-25 09:47:00', '2026-08-25 09:47:00'),
(17905, 1587, 1472, 'like', '2026-08-24 09:47:00', '2026-08-24 09:47:00'),
(17906, 1587, 1479, 'superLike', '2026-08-23 09:47:00', '2026-08-23 09:47:00'),
(17907, 1587, 1486, 'pass', '2026-08-22 09:47:00', '2026-08-22 09:47:00'),
(17908, 1587, 1493, 'like', '2026-08-21 09:47:00', '2026-08-21 09:47:00'),
(17909, 1587, 1500, 'like', '2026-08-20 09:47:00', '2026-08-20 09:47:00'),
(17910, 1587, 1507, 'pass', '2026-08-19 09:47:00', '2026-08-19 09:47:00'),
(17911, 1587, 1514, 'like', '2026-08-18 09:47:00', '2026-08-18 09:47:00'),
(17912, 1587, 1521, 'like', '2026-08-17 09:47:00', '2026-08-17 09:47:00'),
(17913, 1587, 1528, 'pass', '2026-08-16 09:47:00', '2026-08-16 09:47:00'),
(17914, 1588, 1595, 'pass', '2026-08-28 09:46:00', '2026-08-28 09:46:00'),
(17915, 1588, 1602, 'like', '2026-08-27 09:46:00', '2026-08-27 09:46:00'),
(17916, 1588, 1459, 'like', '2026-08-26 09:46:00', '2026-08-26 09:46:00'),
(17917, 1588, 1466, 'pass', '2026-08-25 09:46:00', '2026-08-25 09:46:00'),
(17918, 1588, 1473, 'like', '2026-08-24 09:46:00', '2026-08-24 09:46:00'),
(17919, 1588, 1480, 'like', '2026-08-23 09:46:00', '2026-08-23 09:46:00'),
(17920, 1588, 1487, 'superLike', '2026-08-22 09:46:00', '2026-08-22 09:46:00'),
(17921, 1588, 1494, 'pass', '2026-08-21 09:46:00', '2026-08-21 09:46:00'),
(17922, 1588, 1501, 'like', '2026-08-20 09:46:00', '2026-08-20 09:46:00'),
(17923, 1588, 1508, 'like', '2026-08-19 09:46:00', '2026-08-19 09:46:00'),
(17924, 1588, 1515, 'pass', '2026-08-18 09:46:00', '2026-08-18 09:46:00'),
(17925, 1588, 1522, 'like', '2026-08-17 09:46:00', '2026-08-17 09:46:00'),
(17926, 1588, 1529, 'like', '2026-08-16 09:46:00', '2026-08-16 09:46:00'),
(17927, 1588, 1536, 'pass', '2026-08-15 09:46:00', '2026-08-15 09:46:00'),
(17928, 1589, 1596, 'like', '2026-08-28 09:45:00', '2026-08-28 09:45:00'),
(17929, 1589, 1603, 'pass', '2026-08-27 09:45:00', '2026-08-27 09:45:00'),
(17930, 1589, 1460, 'like', '2026-08-26 09:45:00', '2026-08-26 09:45:00'),
(17931, 1589, 1467, 'like', '2026-08-25 09:45:00', '2026-08-25 09:45:00'),
(17932, 1589, 1474, 'pass', '2026-08-24 09:45:00', '2026-08-24 09:45:00'),
(17933, 1589, 1481, 'like', '2026-08-23 09:45:00', '2026-08-23 09:45:00'),
(17934, 1589, 1488, 'like', '2026-08-22 09:45:00', '2026-08-22 09:45:00'),
(17935, 1589, 1495, 'superLike', '2026-08-21 09:45:00', '2026-08-21 09:45:00'),
(17936, 1589, 1502, 'pass', '2026-08-20 09:45:00', '2026-08-20 09:45:00'),
(17937, 1589, 1509, 'like', '2026-08-19 09:45:00', '2026-08-19 09:45:00'),
(17938, 1589, 1516, 'like', '2026-08-18 09:45:00', '2026-08-18 09:45:00'),
(17939, 1589, 1523, 'pass', '2026-08-17 09:45:00', '2026-08-17 09:45:00'),
(17940, 1589, 1530, 'like', '2026-08-16 09:45:00', '2026-08-16 09:45:00'),
(17941, 1589, 1537, 'like', '2026-08-15 09:45:00', '2026-08-15 09:45:00'),
(17942, 1589, 1544, 'pass', '2026-08-14 09:45:00', '2026-08-14 09:45:00'),
(17943, 1590, 1597, 'like', '2026-08-28 09:44:00', '2026-08-28 09:44:00'),
(17944, 1590, 1454, 'like', '2026-08-27 09:44:00', '2026-08-27 09:44:00'),
(17945, 1590, 1461, 'pass', '2026-08-26 09:44:00', '2026-08-26 09:44:00'),
(17946, 1590, 1468, 'like', '2026-08-25 09:44:00', '2026-08-25 09:44:00'),
(17947, 1590, 1475, 'like', '2026-08-24 09:44:00', '2026-08-24 09:44:00'),
(17948, 1590, 1482, 'pass', '2026-08-23 09:44:00', '2026-08-23 09:44:00'),
(17949, 1590, 1489, 'like', '2026-08-22 09:44:00', '2026-08-22 09:44:00'),
(17950, 1590, 1496, 'like', '2026-08-21 09:44:00', '2026-08-21 09:44:00'),
(17951, 1591, 1598, 'pass', '2026-08-28 09:43:00', '2026-08-28 09:43:00'),
(17952, 1591, 1455, 'like', '2026-08-27 09:43:00', '2026-08-27 09:43:00'),
(17953, 1591, 1462, 'like', '2026-08-26 09:43:00', '2026-08-26 09:43:00'),
(17954, 1591, 1469, 'pass', '2026-08-25 09:43:00', '2026-08-25 09:43:00'),
(17955, 1591, 1476, 'like', '2026-08-24 09:43:00', '2026-08-24 09:43:00'),
(17956, 1591, 1483, 'like', '2026-08-23 09:43:00', '2026-08-23 09:43:00'),
(17957, 1591, 1490, 'pass', '2026-08-22 09:43:00', '2026-08-22 09:43:00'),
(17958, 1591, 1497, 'like', '2026-08-21 09:43:00', '2026-08-21 09:43:00'),
(17959, 1591, 1504, 'like', '2026-08-20 09:43:00', '2026-08-20 09:43:00'),
(17960, 1592, 1599, 'superLike', '2026-08-28 09:42:00', '2026-08-28 09:42:00'),
(17961, 1592, 1456, 'pass', '2026-08-27 09:42:00', '2026-08-27 09:42:00'),
(17962, 1592, 1463, 'like', '2026-08-26 09:42:00', '2026-08-26 09:42:00'),
(17963, 1592, 1470, 'like', '2026-08-25 09:42:00', '2026-08-25 09:42:00'),
(17964, 1592, 1477, 'pass', '2026-08-24 09:42:00', '2026-08-24 09:42:00'),
(17965, 1592, 1484, 'like', '2026-08-23 09:42:00', '2026-08-23 09:42:00'),
(17966, 1592, 1491, 'like', '2026-08-22 09:42:00', '2026-08-22 09:42:00'),
(17967, 1592, 1498, 'pass', '2026-08-21 09:42:00', '2026-08-21 09:42:00'),
(17968, 1592, 1505, 'like', '2026-08-20 09:42:00', '2026-08-20 09:42:00'),
(17969, 1592, 1512, 'like', '2026-08-19 09:42:00', '2026-08-19 09:42:00'),
(17970, 1593, 1600, 'like', '2026-08-28 09:41:00', '2026-08-28 09:41:00'),
(17971, 1593, 1457, 'superLike', '2026-08-27 09:41:00', '2026-08-27 09:41:00'),
(17972, 1593, 1464, 'pass', '2026-08-26 09:41:00', '2026-08-26 09:41:00'),
(17973, 1593, 1471, 'like', '2026-08-25 09:41:00', '2026-08-25 09:41:00'),
(17974, 1593, 1478, 'like', '2026-08-24 09:41:00', '2026-08-24 09:41:00'),
(17975, 1593, 1485, 'pass', '2026-08-23 09:41:00', '2026-08-23 09:41:00'),
(17976, 1593, 1492, 'like', '2026-08-22 09:41:00', '2026-08-22 09:41:00'),
(17977, 1593, 1499, 'like', '2026-08-21 09:41:00', '2026-08-21 09:41:00'),
(17978, 1593, 1506, 'pass', '2026-08-20 09:41:00', '2026-08-20 09:41:00'),
(17979, 1593, 1513, 'like', '2026-08-19 09:41:00', '2026-08-19 09:41:00'),
(17980, 1593, 1520, 'like', '2026-08-18 09:41:00', '2026-08-18 09:41:00'),
(17981, 1594, 1601, 'like', '2026-08-28 09:40:00', '2026-08-28 09:40:00'),
(17982, 1594, 1458, 'like', '2026-08-27 09:40:00', '2026-08-27 09:40:00'),
(17983, 1594, 1465, 'superLike', '2026-08-26 09:40:00', '2026-08-26 09:40:00'),
(17984, 1594, 1472, 'pass', '2026-08-25 09:40:00', '2026-08-25 09:40:00'),
(17985, 1594, 1479, 'like', '2026-08-24 09:40:00', '2026-08-24 09:40:00'),
(17986, 1594, 1486, 'like', '2026-08-23 09:40:00', '2026-08-23 09:40:00'),
(17987, 1594, 1493, 'pass', '2026-08-22 09:40:00', '2026-08-22 09:40:00'),
(17988, 1594, 1500, 'like', '2026-08-21 09:40:00', '2026-08-21 09:40:00'),
(17989, 1594, 1507, 'like', '2026-08-20 09:40:00', '2026-08-20 09:40:00'),
(17990, 1594, 1514, 'pass', '2026-08-19 09:40:00', '2026-08-19 09:40:00'),
(17991, 1594, 1521, 'like', '2026-08-18 09:40:00', '2026-08-18 09:40:00'),
(17992, 1594, 1528, 'like', '2026-08-17 09:40:00', '2026-08-17 09:40:00'),
(17993, 1595, 1602, 'pass', '2026-08-28 09:39:00', '2026-08-28 09:39:00'),
(17994, 1595, 1459, 'like', '2026-08-27 09:39:00', '2026-08-27 09:39:00'),
(17995, 1595, 1466, 'like', '2026-08-26 09:39:00', '2026-08-26 09:39:00'),
(17996, 1595, 1473, 'superLike', '2026-08-25 09:39:00', '2026-08-25 09:39:00'),
(17997, 1595, 1480, 'pass', '2026-08-24 09:39:00', '2026-08-24 09:39:00'),
(17998, 1595, 1487, 'like', '2026-08-23 09:39:00', '2026-08-23 09:39:00'),
(17999, 1595, 1494, 'like', '2026-08-22 09:39:00', '2026-08-22 09:39:00'),
(18000, 1595, 1501, 'pass', '2026-08-21 09:39:00', '2026-08-21 09:39:00'),
(18001, 1595, 1508, 'like', '2026-08-20 09:39:00', '2026-08-20 09:39:00'),
(18002, 1595, 1515, 'like', '2026-08-19 09:39:00', '2026-08-19 09:39:00'),
(18003, 1595, 1522, 'pass', '2026-08-18 09:39:00', '2026-08-18 09:39:00'),
(18004, 1595, 1529, 'like', '2026-08-17 09:39:00', '2026-08-17 09:39:00'),
(18005, 1595, 1536, 'like', '2026-08-16 09:39:00', '2026-08-16 09:39:00'),
(18006, 1596, 1603, 'like', '2026-08-28 09:38:00', '2026-08-28 09:38:00'),
(18007, 1596, 1460, 'pass', '2026-08-27 09:38:00', '2026-08-27 09:38:00'),
(18008, 1596, 1467, 'like', '2026-08-26 09:38:00', '2026-08-26 09:38:00'),
(18009, 1596, 1474, 'like', '2026-08-25 09:38:00', '2026-08-25 09:38:00'),
(18010, 1596, 1481, 'superLike', '2026-08-24 09:38:00', '2026-08-24 09:38:00'),
(18011, 1596, 1488, 'pass', '2026-08-23 09:38:00', '2026-08-23 09:38:00'),
(18012, 1596, 1495, 'like', '2026-08-22 09:38:00', '2026-08-22 09:38:00'),
(18013, 1596, 1502, 'like', '2026-08-21 09:38:00', '2026-08-21 09:38:00'),
(18014, 1596, 1509, 'pass', '2026-08-20 09:38:00', '2026-08-20 09:38:00'),
(18015, 1596, 1516, 'like', '2026-08-19 09:38:00', '2026-08-19 09:38:00'),
(18016, 1596, 1523, 'like', '2026-08-18 09:38:00', '2026-08-18 09:38:00'),
(18017, 1596, 1530, 'pass', '2026-08-17 09:38:00', '2026-08-17 09:38:00'),
(18018, 1596, 1537, 'like', '2026-08-16 09:38:00', '2026-08-16 09:38:00'),
(18019, 1596, 1544, 'like', '2026-08-15 09:38:00', '2026-08-15 09:38:00'),
(18020, 1597, 1454, 'like', '2026-08-28 09:37:00', '2026-08-28 09:37:00'),
(18021, 1597, 1461, 'like', '2026-08-27 09:37:00', '2026-08-27 09:37:00'),
(18022, 1597, 1468, 'pass', '2026-08-26 09:37:00', '2026-08-26 09:37:00'),
(18023, 1597, 1475, 'like', '2026-08-25 09:37:00', '2026-08-25 09:37:00'),
(18024, 1597, 1482, 'like', '2026-08-24 09:37:00', '2026-08-24 09:37:00'),
(18025, 1597, 1489, 'superLike', '2026-08-23 09:37:00', '2026-08-23 09:37:00'),
(18026, 1597, 1496, 'pass', '2026-08-22 09:37:00', '2026-08-22 09:37:00'),
(18027, 1597, 1503, 'like', '2026-08-21 09:37:00', '2026-08-21 09:37:00'),
(18028, 1597, 1510, 'like', '2026-08-20 09:37:00', '2026-08-20 09:37:00'),
(18029, 1597, 1517, 'pass', '2026-08-19 09:37:00', '2026-08-19 09:37:00'),
(18030, 1597, 1524, 'like', '2026-08-18 09:37:00', '2026-08-18 09:37:00'),
(18031, 1597, 1531, 'like', '2026-08-17 09:37:00', '2026-08-17 09:37:00'),
(18032, 1597, 1538, 'pass', '2026-08-16 09:37:00', '2026-08-16 09:37:00'),
(18033, 1597, 1545, 'like', '2026-08-15 09:37:00', '2026-08-15 09:37:00'),
(18034, 1597, 1552, 'like', '2026-08-14 09:37:00', '2026-08-14 09:37:00'),
(18035, 1598, 1455, 'pass', '2026-08-28 09:36:00', '2026-08-28 09:36:00'),
(18036, 1598, 1462, 'like', '2026-08-27 09:36:00', '2026-08-27 09:36:00'),
(18037, 1598, 1469, 'like', '2026-08-26 09:36:00', '2026-08-26 09:36:00'),
(18038, 1598, 1476, 'pass', '2026-08-25 09:36:00', '2026-08-25 09:36:00'),
(18039, 1598, 1483, 'like', '2026-08-24 09:36:00', '2026-08-24 09:36:00'),
(18040, 1598, 1490, 'like', '2026-08-23 09:36:00', '2026-08-23 09:36:00'),
(18041, 1598, 1497, 'superLike', '2026-08-22 09:36:00', '2026-08-22 09:36:00'),
(18042, 1598, 1504, 'pass', '2026-08-21 09:36:00', '2026-08-21 09:36:00'),
(18043, 1599, 1456, 'like', '2026-08-28 09:35:00', '2026-08-28 09:35:00'),
(18044, 1599, 1463, 'pass', '2026-08-27 09:35:00', '2026-08-27 09:35:00'),
(18045, 1599, 1470, 'like', '2026-08-26 09:35:00', '2026-08-26 09:35:00'),
(18046, 1599, 1477, 'like', '2026-08-25 09:35:00', '2026-08-25 09:35:00'),
(18047, 1599, 1484, 'pass', '2026-08-24 09:35:00', '2026-08-24 09:35:00'),
(18048, 1599, 1491, 'like', '2026-08-23 09:35:00', '2026-08-23 09:35:00'),
(18049, 1599, 1498, 'like', '2026-08-22 09:35:00', '2026-08-22 09:35:00'),
(18050, 1599, 1505, 'superLike', '2026-08-21 09:35:00', '2026-08-21 09:35:00'),
(18051, 1599, 1512, 'pass', '2026-08-20 09:35:00', '2026-08-20 09:35:00'),
(18052, 1600, 1457, 'like', '2026-08-28 09:34:00', '2026-08-28 09:34:00'),
(18053, 1600, 1464, 'like', '2026-08-27 09:34:00', '2026-08-27 09:34:00'),
(18054, 1600, 1471, 'pass', '2026-08-26 09:34:00', '2026-08-26 09:34:00'),
(18055, 1600, 1478, 'like', '2026-08-25 09:34:00', '2026-08-25 09:34:00'),
(18056, 1600, 1485, 'like', '2026-08-24 09:34:00', '2026-08-24 09:34:00'),
(18057, 1600, 1492, 'pass', '2026-08-23 09:34:00', '2026-08-23 09:34:00'),
(18058, 1600, 1499, 'like', '2026-08-22 09:34:00', '2026-08-22 09:34:00'),
(18059, 1600, 1506, 'like', '2026-08-21 09:34:00', '2026-08-21 09:34:00'),
(18060, 1600, 1513, 'superLike', '2026-08-20 09:34:00', '2026-08-20 09:34:00'),
(18061, 1600, 1520, 'pass', '2026-08-19 09:34:00', '2026-08-19 09:34:00'),
(18062, 1601, 1458, 'pass', '2026-08-28 09:33:00', '2026-08-28 09:33:00'),
(18063, 1601, 1465, 'like', '2026-08-27 09:33:00', '2026-08-27 09:33:00'),
(18064, 1601, 1472, 'like', '2026-08-26 09:33:00', '2026-08-26 09:33:00'),
(18065, 1601, 1479, 'pass', '2026-08-25 09:33:00', '2026-08-25 09:33:00'),
(18066, 1601, 1486, 'like', '2026-08-24 09:33:00', '2026-08-24 09:33:00'),
(18067, 1601, 1493, 'like', '2026-08-23 09:33:00', '2026-08-23 09:33:00'),
(18068, 1601, 1500, 'pass', '2026-08-22 09:33:00', '2026-08-22 09:33:00'),
(18069, 1601, 1507, 'like', '2026-08-21 09:33:00', '2026-08-21 09:33:00'),
(18070, 1601, 1514, 'like', '2026-08-20 09:33:00', '2026-08-20 09:33:00'),
(18071, 1601, 1521, 'superLike', '2026-08-19 09:33:00', '2026-08-19 09:33:00'),
(18072, 1601, 1528, 'pass', '2026-08-18 09:33:00', '2026-08-18 09:33:00'),
(18073, 1602, 1459, 'superLike', '2026-08-28 09:32:00', '2026-08-28 09:32:00'),
(18074, 1602, 1466, 'pass', '2026-08-27 09:32:00', '2026-08-27 09:32:00'),
(18075, 1602, 1473, 'like', '2026-08-26 09:32:00', '2026-08-26 09:32:00'),
(18076, 1602, 1480, 'like', '2026-08-25 09:32:00', '2026-08-25 09:32:00'),
(18077, 1602, 1487, 'pass', '2026-08-24 09:32:00', '2026-08-24 09:32:00'),
(18078, 1602, 1494, 'like', '2026-08-23 09:32:00', '2026-08-23 09:32:00'),
(18079, 1602, 1501, 'like', '2026-08-22 09:32:00', '2026-08-22 09:32:00'),
(18080, 1602, 1508, 'pass', '2026-08-21 09:32:00', '2026-08-21 09:32:00'),
(18081, 1602, 1515, 'like', '2026-08-20 09:32:00', '2026-08-20 09:32:00'),
(18082, 1602, 1522, 'like', '2026-08-19 09:32:00', '2026-08-19 09:32:00'),
(18083, 1602, 1529, 'superLike', '2026-08-18 09:32:00', '2026-08-18 09:32:00'),
(18084, 1602, 1536, 'pass', '2026-08-17 09:32:00', '2026-08-17 09:32:00'),
(18085, 1603, 1460, 'like', '2026-08-28 09:31:00', '2026-08-28 09:31:00'),
(18086, 1603, 1467, 'superLike', '2026-08-27 09:31:00', '2026-08-27 09:31:00'),
(18087, 1603, 1474, 'pass', '2026-08-26 09:31:00', '2026-08-26 09:31:00'),
(18088, 1603, 1481, 'like', '2026-08-25 09:31:00', '2026-08-25 09:31:00'),
(18089, 1603, 1488, 'like', '2026-08-24 09:31:00', '2026-08-24 09:31:00'),
(18090, 1603, 1495, 'pass', '2026-08-23 09:31:00', '2026-08-23 09:31:00'),
(18091, 1603, 1502, 'like', '2026-08-22 09:31:00', '2026-08-22 09:31:00'),
(18092, 1603, 1509, 'like', '2026-08-21 09:31:00', '2026-08-21 09:31:00'),
(18093, 1603, 1516, 'pass', '2026-08-20 09:31:00', '2026-08-20 09:31:00'),
(18094, 1603, 1523, 'like', '2026-08-19 09:31:00', '2026-08-19 09:31:00'),
(18095, 1603, 1530, 'like', '2026-08-18 09:31:00', '2026-08-18 09:31:00'),
(18096, 1603, 1537, 'superLike', '2026-08-17 09:31:00', '2026-08-17 09:31:00'),
(18097, 1603, 1544, 'pass', '2026-08-16 09:31:00', '2026-08-16 09:31:00'),
(18098, 1455, 1454, 'like', '2026-08-28 12:00:00', '2026-08-28 12:00:00'),
(18099, 1454, 1456, 'like', '2026-08-15 12:00:00', '2026-08-15 12:00:00'),
(18100, 1456, 1454, 'superLike', '2026-08-15 12:00:00', '2026-08-15 12:00:00'),
(18101, 1457, 1454, 'superLike', '2026-08-29 12:00:00', '2026-08-29 12:00:00'),
(18102, 1458, 1454, 'like', '2026-08-28 12:00:00', '2026-08-28 12:00:00'),
(18103, 1459, 1454, 'like', '2026-08-27 12:00:00', '2026-08-27 12:00:00'),
(18104, 1460, 1454, 'like', '2026-08-26 12:00:00', '2026-08-26 12:00:00'),
(18105, 1461, 1454, 'like', '2026-08-25 12:00:00', '2026-08-25 12:00:00'),
(18106, 1462, 1454, 'like', '2026-08-24 12:00:00', '2026-08-24 12:00:00'),
(18107, 1463, 1454, 'like', '2026-08-23 12:00:00', '2026-08-23 12:00:00'),
(18108, 1464, 1454, 'superLike', '2026-08-22 12:00:00', '2026-08-22 12:00:00'),
(18109, 1465, 1454, 'like', '2026-08-21 12:00:00', '2026-08-21 12:00:00'),
(18110, 1466, 1454, 'like', '2026-08-20 12:00:00', '2026-08-20 12:00:00'),
(18111, 1467, 1454, 'like', '2026-08-19 12:00:00', '2026-08-19 12:00:00'),
(18112, 1468, 1454, 'like', '2026-08-18 12:00:00', '2026-08-18 12:00:00'),
(18113, 1469, 1454, 'like', '2026-08-17 12:00:00', '2026-08-17 12:00:00'),
(18114, 1470, 1454, 'like', '2026-08-16 12:00:00', '2026-08-16 12:00:00'),
(18115, 1471, 1454, 'superLike', '2026-08-15 12:00:00', '2026-08-15 12:00:00'),
(18116, 1472, 1454, 'like', '2026-08-14 12:00:00', '2026-08-14 12:00:00'),
(18117, 1473, 1454, 'like', '2026-08-13 12:00:00', '2026-08-13 12:00:00'),
(18118, 1474, 1454, 'like', '2026-08-12 12:00:00', '2026-08-12 12:00:00'),
(18119, 1475, 1454, 'like', '2026-08-11 12:00:00', '2026-08-11 12:00:00'),
(18120, 1476, 1454, 'like', '2026-08-10 12:00:00', '2026-08-10 12:00:00'),
(18121, 1477, 1454, 'like', '2026-08-09 12:00:00', '2026-08-09 12:00:00'),
(18122, 1478, 1454, 'superLike', '2026-08-08 12:00:00', '2026-08-08 12:00:00'),
(18123, 1479, 1454, 'like', '2026-08-07 12:00:00', '2026-08-07 12:00:00'),
(18124, 1480, 1454, 'like', '2026-08-06 12:00:00', '2026-08-06 12:00:00'),
(18125, 1481, 1454, 'like', '2026-08-05 12:00:00', '2026-08-05 12:00:00'),
(18126, 1482, 1454, 'like', '2026-08-04 12:00:00', '2026-08-04 12:00:00'),
(18127, 1483, 1454, 'like', '2026-08-03 12:00:00', '2026-08-03 12:00:00'),
(18128, 1484, 1454, 'like', '2026-08-02 12:00:00', '2026-08-02 12:00:00'),
(18129, 1485, 1454, 'superLike', '2026-08-01 12:00:00', '2026-08-01 12:00:00'),
(18130, 1486, 1454, 'like', '2026-07-31 12:00:00', '2026-07-31 12:00:00'),
(18131, 1487, 1454, 'like', '2026-08-29 12:00:00', '2026-08-29 12:00:00'),
(18132, 1488, 1454, 'like', '2026-08-28 12:00:00', '2026-08-28 12:00:00'),
(18133, 1489, 1454, 'like', '2026-08-27 12:00:00', '2026-08-27 12:00:00'),
(18134, 1490, 1454, 'like', '2026-08-26 12:00:00', '2026-08-26 12:00:00'),
(18135, 1491, 1454, 'like', '2026-08-25 12:00:00', '2026-08-25 12:00:00'),
(18136, 1492, 1454, 'superLike', '2026-08-24 12:00:00', '2026-08-24 12:00:00'),
(18137, 1493, 1454, 'like', '2026-08-23 12:00:00', '2026-08-23 12:00:00'),
(18138, 1494, 1454, 'like', '2026-08-22 12:00:00', '2026-08-22 12:00:00'),
(18139, 1495, 1454, 'like', '2026-08-21 12:00:00', '2026-08-21 12:00:00'),
(18140, 1496, 1454, 'like', '2026-08-20 12:00:00', '2026-08-20 12:00:00'),
(18141, 1497, 1454, 'like', '2026-08-19 12:00:00', '2026-08-19 12:00:00'),
(18142, 1498, 1454, 'like', '2026-08-18 12:00:00', '2026-08-18 12:00:00'),
(18143, 1499, 1454, 'superLike', '2026-08-17 12:00:00', '2026-08-17 12:00:00'),
(18144, 1500, 1454, 'like', '2026-08-16 12:00:00', '2026-08-16 12:00:00'),
(18145, 1501, 1454, 'like', '2026-08-15 12:00:00', '2026-08-15 12:00:00'),
(18146, 1502, 1454, 'like', '2026-08-14 12:00:00', '2026-08-14 12:00:00'),
(18147, 1503, 1454, 'like', '2026-08-13 12:00:00', '2026-08-13 12:00:00'),
(18148, 1504, 1454, 'like', '2026-08-12 12:00:00', '2026-08-12 12:00:00'),
(18149, 1505, 1454, 'like', '2026-08-11 12:00:00', '2026-08-11 12:00:00'),
(18150, 1506, 1454, 'superLike', '2026-08-10 12:00:00', '2026-08-10 12:00:00'),
(18151, 1507, 1454, 'like', '2026-08-09 12:00:00', '2026-08-09 12:00:00'),
(18152, 1508, 1454, 'like', '2026-08-08 12:00:00', '2026-08-08 12:00:00'),
(18153, 1509, 1454, 'like', '2026-08-07 12:00:00', '2026-08-07 12:00:00'),
(18154, 1510, 1454, 'like', '2026-08-06 12:00:00', '2026-08-06 12:00:00'),
(18155, 1511, 1454, 'like', '2026-08-05 12:00:00', '2026-08-05 12:00:00'),
(18156, 1512, 1454, 'like', '2026-08-04 12:00:00', '2026-08-04 12:00:00'),
(18157, 1513, 1454, 'superLike', '2026-08-03 12:00:00', '2026-08-03 12:00:00'),
(18158, 1514, 1454, 'like', '2026-08-02 12:00:00', '2026-08-02 12:00:00'),
(18159, 1515, 1454, 'like', '2026-08-01 12:00:00', '2026-08-01 12:00:00'),
(18160, 1516, 1454, 'like', '2026-07-31 12:00:00', '2026-07-31 12:00:00'),
(18161, 1457, 1458, 'like', '2026-08-26 12:00:00', '2026-08-26 12:00:00'),
(18162, 1458, 1457, 'superLike', '2026-08-26 12:00:00', '2026-08-26 12:00:00'),
(18163, 1463, 1464, 'like', '2026-08-20 12:00:00', '2026-08-20 12:00:00'),
(18164, 1464, 1463, 'like', '2026-08-20 12:00:00', '2026-08-20 12:00:00'),
(18165, 1469, 1470, 'like', '2026-08-14 12:00:00', '2026-08-14 12:00:00'),
(18166, 1470, 1469, 'superLike', '2026-08-14 12:00:00', '2026-08-14 12:00:00'),
(18167, 1475, 1476, 'like', '2026-08-08 12:00:00', '2026-08-08 12:00:00'),
(18168, 1476, 1475, 'like', '2026-08-08 12:00:00', '2026-08-08 12:00:00'),
(18169, 1481, 1482, 'like', '2026-08-02 12:00:00', '2026-08-02 12:00:00'),
(18170, 1482, 1481, 'superLike', '2026-08-02 12:00:00', '2026-08-02 12:00:00'),
(18171, 1487, 1488, 'like', '2026-07-27 12:00:00', '2026-07-27 12:00:00'),
(18172, 1488, 1487, 'like', '2026-07-27 12:00:00', '2026-07-27 12:00:00'),
(18173, 1493, 1494, 'like', '2026-07-21 12:00:00', '2026-07-21 12:00:00'),
(18174, 1494, 1493, 'superLike', '2026-07-21 12:00:00', '2026-07-21 12:00:00'),
(18175, 1499, 1500, 'like', '2026-07-15 12:00:00', '2026-07-15 12:00:00'),
(18176, 1500, 1499, 'like', '2026-07-15 12:00:00', '2026-07-15 12:00:00'),
(18177, 1505, 1506, 'like', '2026-07-09 12:00:00', '2026-07-09 12:00:00'),
(18178, 1506, 1505, 'superLike', '2026-07-09 12:00:00', '2026-07-09 12:00:00'),
(18179, 1511, 1512, 'like', '2026-07-03 12:00:00', '2026-07-03 12:00:00'),
(18180, 1512, 1511, 'like', '2026-07-03 12:00:00', '2026-07-03 12:00:00'),
(18181, 1517, 1518, 'like', '2026-06-27 12:00:00', '2026-06-27 12:00:00'),
(18182, 1518, 1517, 'superLike', '2026-06-27 12:00:00', '2026-06-27 12:00:00'),
(18183, 1523, 1524, 'like', '2026-06-21 12:00:00', '2026-06-21 12:00:00'),
(18184, 1524, 1523, 'like', '2026-06-21 12:00:00', '2026-06-21 12:00:00'),
(18185, 1529, 1530, 'like', '2026-06-15 12:00:00', '2026-06-15 12:00:00'),
(18186, 1530, 1529, 'superLike', '2026-06-15 12:00:00', '2026-06-15 12:00:00'),
(18187, 1535, 1536, 'like', '2026-06-09 12:00:00', '2026-06-09 12:00:00'),
(18188, 1536, 1535, 'like', '2026-06-09 12:00:00', '2026-06-09 12:00:00'),
(18189, 1541, 1542, 'like', '2026-06-03 12:00:00', '2026-06-03 12:00:00'),
(18190, 1542, 1541, 'superLike', '2026-06-03 12:00:00', '2026-06-03 12:00:00'),
(18191, 1547, 1548, 'like', '2026-08-26 12:00:00', '2026-08-26 12:00:00'),
(18192, 1548, 1547, 'like', '2026-08-26 12:00:00', '2026-08-26 12:00:00'),
(18193, 1553, 1554, 'like', '2026-08-20 12:00:00', '2026-08-20 12:00:00'),
(18194, 1554, 1553, 'superLike', '2026-08-20 12:00:00', '2026-08-20 12:00:00'),
(18195, 1559, 1560, 'like', '2026-08-14 12:00:00', '2026-08-14 12:00:00'),
(18196, 1560, 1559, 'like', '2026-08-14 12:00:00', '2026-08-14 12:00:00'),
(18197, 1565, 1566, 'like', '2026-08-08 12:00:00', '2026-08-08 12:00:00'),
(18198, 1566, 1565, 'superLike', '2026-08-08 12:00:00', '2026-08-08 12:00:00'),
(18199, 1571, 1572, 'like', '2026-08-02 12:00:00', '2026-08-02 12:00:00'),
(18200, 1572, 1571, 'like', '2026-08-02 12:00:00', '2026-08-02 12:00:00'),
(18201, 1577, 1578, 'like', '2026-07-27 12:00:00', '2026-07-27 12:00:00'),
(18202, 1578, 1577, 'superLike', '2026-07-27 12:00:00', '2026-07-27 12:00:00'),
(18203, 1583, 1584, 'like', '2026-07-21 12:00:00', '2026-07-21 12:00:00'),
(18204, 1584, 1583, 'like', '2026-07-21 12:00:00', '2026-07-21 12:00:00'),
(18205, 1589, 1590, 'like', '2026-07-15 12:00:00', '2026-07-15 12:00:00'),
(18206, 1590, 1589, 'superLike', '2026-07-15 12:00:00', '2026-07-15 12:00:00'),
(18207, 1595, 1596, 'like', '2026-07-09 12:00:00', '2026-07-09 12:00:00'),
(18208, 1596, 1595, 'like', '2026-07-09 12:00:00', '2026-07-09 12:00:00'),
(18209, 1601, 1602, 'like', '2026-07-03 12:00:00', '2026-07-03 12:00:00'),
(18210, 1602, 1601, 'superLike', '2026-07-03 12:00:00', '2026-07-03 12:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `discoverfilterpreferences`
--

CREATE TABLE `discoverfilterpreferences` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `minAge` int(11) NOT NULL DEFAULT 18,
  `maxAge` int(11) NOT NULL DEFAULT 45,
  `maxDistanceKm` int(11) NOT NULL DEFAULT 80,
  `minScore` int(11) NOT NULL DEFAULT 0,
  `city` varchar(255) DEFAULT NULL,
  `minHeight` int(11) DEFAULT NULL,
  `hometown` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`hometown`)),
  `datingIntentions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`datingIntentions`)),
  `lifestyleTags` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`lifestyleTags`)),
  `education` varchar(255) DEFAULT NULL,
  `profession` varchar(255) DEFAULT NULL,
  `community` varchar(255) DEFAULT NULL,
  `religion` varchar(255) DEFAULT NULL,
  `languages` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`languages`)),
  `pronouns` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`pronouns`)),
  `sexuality` varchar(255) DEFAULT NULL,
  `qualities` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`qualities`)),
  `preferredTalkingHours` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`preferredTalkingHours`)),
  `loveLanguages` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`loveLanguages`)),
  `smoking` varchar(255) DEFAULT NULL,
  `drinking` varchar(255) DEFAULT NULL,
  `weed` varchar(255) DEFAULT NULL,
  `verifiedOnly` tinyint(1) NOT NULL DEFAULT 1,
  `onlineNow` tinyint(1) NOT NULL DEFAULT 0,
  `hasPrompts` tinyint(1) NOT NULL DEFAULT 0,
  `hasEventInterest` tinyint(1) NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `communicationStyles` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`communicationStyles`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `discoverfilterpreferences`
--

INSERT INTO `discoverfilterpreferences` (`id`, `userId`, `minAge`, `maxAge`, `maxDistanceKm`, `minScore`, `city`, `minHeight`, `hometown`, `datingIntentions`, `lifestyleTags`, `education`, `profession`, `community`, `religion`, `languages`, `pronouns`, `sexuality`, `qualities`, `preferredTalkingHours`, `loveLanguages`, `smoking`, `drinking`, `weed`, `verifiedOnly`, `onlineNow`, `hasPrompts`, `hasEventInterest`, `createdAt`, `updatedAt`, `communicationStyles`) VALUES
(1, 1, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:21', '[]'),
(2, 2, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:21', '[]'),
(3, 3, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:21', '[]'),
(4, 4, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:21', '[]'),
(5, 5, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:21', '[]'),
(6, 6, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:21', '[]'),
(7, 7, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:21', '[]'),
(8, 8, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:22', '[]'),
(9, 9, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:22', '[]'),
(10, 10, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:22', '[]'),
(11, 11, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:22', '[]'),
(12, 12, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:22', '[]'),
(13, 13, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:22', '[]'),
(14, 14, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:22', '[]'),
(15, 15, 22, 40, 100, 0, '', NULL, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:22', '[]'),
(16, 16, 18, 45, 80, 0, '', 0, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-11 18:56:35', '2026-08-11 18:56:35', '[]'),
(20, 49, 18, 45, 80, 0, '', 0, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-12 10:32:26', '2026-08-12 10:32:26', '[]'),
(45, 85, 18, 45, 80, 0, '', 0, '[]', '[]', '[]', '', '', '', '', '[]', '[]', '', '[]', '[]', '[]', '', '', '', 1, 0, 0, 0, '2026-08-13 06:38:27', '2026-08-13 06:38:27', '[]'),
(1405, 1454, 18, 99, 500, 0, NULL, NULL, '[]', '[]', '[]', NULL, NULL, NULL, NULL, '[]', '[]', NULL, '[]', '[]', '[]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-07-13 12:00:00', '2026-08-28 12:00:00', '[]'),
(1406, 1455, 18, 99, 500, 0, NULL, NULL, '[]', '[]', '[]', NULL, NULL, NULL, NULL, '[]', '[]', NULL, '[]', '[]', '[]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-12-21 11:59:00', '2026-08-13 11:59:00', '[]'),
(1407, 1456, 18, 99, 500, 0, NULL, NULL, '[]', '[]', '[]', NULL, NULL, NULL, NULL, '[]', '[]', NULL, '[]', '[]', '[]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-04-26 11:58:00', '2026-08-09 11:58:00', '[]'),
(1408, 1457, 18, 30, 150, 0, 'Vadodara', NULL, '[]', '[\"Exploring Possibilities\",\"Friendship First\"]', '[\"Occasionally\"]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Kindness\",\"Humour\"]', '[\"Afternoon\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-08-28 11:57:00', '2026-08-28 11:57:00', '[\"calls\"]'),
(1409, 1458, 71, 83, 20, 0, NULL, NULL, '[\"Surat\"]', '[\"Long-Term Relationship\"]', '[]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Humour\",\"Curiosity\"]', '[\"Afternoon\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-10-08 11:56:00', '2026-08-22 11:56:00', '[\"light_fun_conversations\"]'),
(1410, 1459, 19, 39, 40, 0, NULL, 160, '[]', '[\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Patience\",\"Humour\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-08-29 11:55:00', '2026-08-29 11:55:00', '[\"occasional_texting\"]'),
(1411, 1460, 21, 36, 80, 60, 'Surat', NULL, '[]', '[\"Casual Connection\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Kindness\",\"Empathy\"]', '[\"Evening\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2024-03-12 11:54:00', '2026-08-22 11:54:00', '[\"voice_notes\"]'),
(1412, 1461, 23, 43, 150, 0, NULL, NULL, '[]', '[\"Marriage Minded\"]', '[]', NULL, NULL, NULL, 'Muslim', '[\"English\"]', '[]', NULL, '[\"Empathy\",\"Curiosity\"]', '[\"Late night\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-09-28 11:53:00', '2026-08-26 11:53:00', '[\"calls\"]'),
(1413, 1462, 37, 49, 20, 0, NULL, NULL, '[\"Vadodara\"]', '[\"Friendship First\",\"Marriage Minded\"]', '[]', 'Postgraduate', NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Humour\",\"Honesty\"]', '[\"Morning\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-04-10 11:52:00', '2026-08-18 11:52:00', '[\"voice_notes\"]'),
(1414, 1463, 25, 40, 40, 0, 'Gandhinagar', NULL, '[]', '[\"Casual Connection\",\"Long-Term Relationship\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Kindness\",\"Patience\"]', '[\"Morning\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-03-23 11:51:00', '2026-08-29 11:51:00', '[\"frequent_texting\"]'),
(1415, 1464, 18, 36, 80, 0, NULL, 160, '[]', '[\"Marriage Minded\",\"Meaningful Dating\"]', '[]', NULL, 'Finance', NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Empathy\",\"Creativity\"]', '[\"Afternoon\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-11-11 11:50:00', '2026-08-18 11:50:00', '[\"deep_conversations\"]'),
(1416, 1465, 37, 57, 150, 0, NULL, NULL, '[]', '[\"Casual Connection\"]', '[]', NULL, NULL, 'Open', NULL, '[\"Hindi\"]', '[]', NULL, '[\"Curiosity\",\"Humour\"]', '[\"Afternoon\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-03-17 11:49:00', '2026-08-24 11:49:00', '[\"frequent_texting\"]'),
(1417, 1466, 43, 50, 20, 60, 'Ahmedabad', NULL, '[\"Gandhinagar\"]', '[\"Meaningful Dating\"]', '[\"A few times a week\"]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Empathy\",\"Kindness\"]', '[\"Evening\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-05-29 11:48:00', '2026-08-14 11:48:00', '[\"occasional_texting\"]'),
(1418, 1467, 21, 41, 40, 0, NULL, NULL, '[]', '[\"Friendship First\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Ambition\",\"Honesty\"]', '[\"Late night\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-08-18 11:47:00', '2026-08-18 11:47:00', '[\"occasional_texting\"]'),
(1419, 1468, 39, 59, 80, 0, NULL, NULL, '[]', '[\"Friendship First\",\"Casual Connection\"]', '[]', NULL, NULL, NULL, 'Christian', '[\"Tamil\"]', '[]', NULL, '[\"Patience\",\"Creativity\"]', '[\"Late night\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-04-30 11:46:00', '2026-08-22 11:46:00', '[\"deep_conversations\"]'),
(1420, 1469, 40, 55, 150, 0, 'Vadodara', 160, '[]', '[\"Casual Connection\"]', '[\"A few times a week\"]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Kindness\",\"Honesty\"]', '[\"Late night\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-12-17 11:45:00', '2026-08-22 11:45:00', '[\"calls\"]'),
(1421, 1470, 38, 50, 20, 0, NULL, NULL, '[\"Vadodara\"]', '[\"Long-Term Relationship\"]', '[]', 'Postgraduate', NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Creativity\",\"Kindness\"]', '[\"Morning\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-08-03 11:44:00', '2026-08-24 11:44:00', '[\"voice_notes\"]'),
(1422, 1471, 20, 40, 40, 0, NULL, NULL, '[]', '[\"Long-Term Relationship\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Creativity\",\"Curiosity\"]', '[\"Late night\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-08-11 11:43:00', '2026-08-25 11:43:00', '[\"calls\"]'),
(1423, 1472, 28, 43, 80, 60, 'Surat', NULL, '[]', '[\"Long-Term Relationship\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Honesty\",\"Empathy\"]', '[\"Afternoon\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-07-01 11:42:00', '2026-08-29 11:42:00', '[\"frequent_texting\"]'),
(1424, 1473, 38, 58, 150, 0, NULL, NULL, '[]', '[\"Casual Connection\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Patience\",\"Empathy\"]', '[\"Late night\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-01-05 11:41:00', '2026-08-21 11:41:00', '[\"light_fun_conversations\"]'),
(1425, 1474, 39, 51, 20, 0, NULL, 160, '[\"Surat\"]', '[\"Long-Term Relationship\",\"Exploring Possibilities\"]', '[]', NULL, 'Finance', NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Patience\",\"Creativity\"]', '[\"Evening\"]', '[\"Quality time\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-09-09 11:40:00', '2026-08-29 11:40:00', '[\"occasional_texting\"]'),
(1426, 1475, 41, 56, 40, 0, 'Gandhinagar', NULL, '[]', '[\"Casual Connection\",\"Long-Term Relationship\"]', '[\"A few times a week\"]', NULL, NULL, NULL, 'Sikh', '[\"Marathi\"]', '[]', NULL, '[\"Empathy\",\"Kindness\"]', '[\"Afternoon\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-04-21 11:39:00', '2026-08-10 11:39:00', '[\"calls\"]'),
(1427, 1476, 31, 51, 80, 0, NULL, NULL, '[]', '[\"Friendship First\",\"Exploring Possibilities\"]', '[]', NULL, NULL, 'Open', NULL, '[\"Hindi\"]', '[]', NULL, '[\"Curiosity\",\"Ambition\"]', '[\"Afternoon\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-09-25 11:38:00', '2026-08-29 11:38:00', '[\"calls\"]'),
(1428, 1477, 35, 55, 150, 0, NULL, NULL, '[]', '[\"Friendship First\",\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Curiosity\",\"Ambition\"]', '[\"Evening\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-05-02 11:37:00', '2026-08-12 11:37:00', '[\"occasional_texting\"]'),
(1429, 1478, 21, 28, 20, 60, 'Ahmedabad', NULL, '[\"Vadodara\"]', '[\"Meaningful Dating\",\"Casual Connection\"]', '[\"Daily\"]', 'Professional', NULL, NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Patience\",\"Creativity\"]', '[\"Evening\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-11-06 11:36:00', '2026-08-10 11:36:00', '[\"occasional_texting\"]'),
(1430, 1479, 19, 39, 40, 0, NULL, 160, '[]', '[\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Honesty\",\"Curiosity\"]', '[\"Evening\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-08-21 11:35:00', '2026-08-24 11:35:00', '[\"occasional_texting\"]'),
(1431, 1480, 34, 54, 80, 0, NULL, NULL, '[]', '[\"Long-Term Relationship\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Kindness\",\"Ambition\"]', '[\"Late night\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-08-09 11:34:00', '2026-08-10 11:34:00', '[\"occasional_texting\"]'),
(1432, 1481, 18, 33, 150, 0, 'Vadodara', NULL, '[]', '[\"Exploring Possibilities\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Honesty\",\"Curiosity\"]', '[\"Afternoon\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-07-19 11:33:00', '2026-08-27 11:33:00', '[\"deep_conversations\"]'),
(1433, 1482, 30, 42, 20, 0, NULL, NULL, '[\"Vadodara\"]', '[\"Long-Term Relationship\"]', '[]', NULL, NULL, NULL, 'Spiritual', '[\"Tamil\"]', '[]', NULL, '[\"Kindness\",\"Curiosity\"]', '[\"Morning\"]', '[\"Quality time\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-03-16 11:32:00', '2026-08-17 11:32:00', '[\"voice_notes\"]'),
(1434, 1483, 35, 55, 40, 0, NULL, NULL, '[]', '[\"Marriage Minded\"]', '[]', NULL, NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Patience\",\"Curiosity\"]', '[\"Late night\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-02-08 11:31:00', '2026-08-24 11:31:00', '[\"light_fun_conversations\"]'),
(1435, 1484, 25, 40, 80, 60, 'Surat', 160, '[]', '[\"Meaningful Dating\",\"Long-Term Relationship\"]', '[\"A few times a week\"]', NULL, 'Architect', NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Kindness\",\"Honesty\"]', '[\"Afternoon\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-09-02 11:30:00', '2026-08-18 11:30:00', '[\"voice_notes\"]'),
(1436, 1485, 26, 46, 150, 0, NULL, NULL, '[]', '[\"Marriage Minded\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Patience\",\"Humour\"]', '[\"Morning\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-04-23 11:29:00', '2026-08-12 11:29:00', '[\"light_fun_conversations\"]'),
(1437, 1486, 31, 43, 20, 0, NULL, NULL, '[\"Ahmedabad\"]', '[\"Meaningful Dating\"]', '[]', 'Undergraduate', NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Kindness\",\"Honesty\"]', '[\"Afternoon\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-09-07 11:28:00', '2026-08-20 11:28:00', '[\"deep_conversations\"]'),
(1438, 1487, 18, 33, 40, 0, 'Gandhinagar', NULL, '[]', '[\"Casual Connection\",\"Meaningful Dating\"]', '[\"Daily\"]', NULL, NULL, 'Open', NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Humour\",\"Creativity\"]', '[\"Morning\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-11-09 11:27:00', '2026-08-20 11:27:00', '[\"occasional_texting\"]'),
(1439, 1488, 40, 60, 80, 0, NULL, NULL, '[]', '[\"Long-Term Relationship\",\"Friendship First\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Empathy\",\"Ambition\"]', '[\"Morning\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-01-21 11:26:00', '2026-08-21 11:26:00', '[\"deep_conversations\"]'),
(1440, 1489, 29, 49, 150, 0, NULL, 160, '[]', '[\"Friendship First\"]', '[]', NULL, NULL, NULL, 'Muslim', '[\"Hindi\"]', '[]', NULL, '[\"Honesty\",\"Ambition\"]', '[\"Evening\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-10-19 11:25:00', '2026-08-16 11:25:00', '[\"deep_conversations\"]'),
(1441, 1490, 34, 41, 20, 60, 'Ahmedabad', NULL, '[\"Vadodara\"]', '[\"Friendship First\",\"Marriage Minded\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Honesty\",\"Kindness\"]', '[\"Evening\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-10-08 11:24:00', '2026-08-11 11:24:00', '[\"frequent_texting\"]'),
(1442, 1491, 20, 40, 40, 0, NULL, NULL, '[]', '[\"Exploring Possibilities\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Creativity\",\"Empathy\"]', '[\"Morning\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-02-13 11:23:00', '2026-08-22 11:23:00', '[\"occasional_texting\"]'),
(1443, 1492, 25, 45, 80, 0, NULL, NULL, '[]', '[\"Casual Connection\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Honesty\",\"Kindness\"]', '[\"Morning\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-04-29 11:22:00', '2026-08-19 11:22:00', '[\"occasional_texting\"]'),
(1444, 1493, 40, 55, 150, 0, 'Vadodara', NULL, '[]', '[\"Meaningful Dating\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Empathy\",\"Curiosity\"]', '[\"Evening\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-08-25 11:21:00', '2026-08-14 11:21:00', '[\"occasional_texting\"]'),
(1445, 1494, 37, 49, 20, 0, NULL, 160, '[\"Gandhinagar\"]', '[\"Casual Connection\",\"Meaningful Dating\"]', '[]', 'Postgraduate', 'Designer', NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Honesty\",\"Humour\"]', '[\"Late night\"]', '[\"Quality time\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-07-04 11:20:00', '2026-08-12 11:20:00', '[\"occasional_texting\"]'),
(1446, 1495, 22, 42, 40, 0, NULL, NULL, '[]', '[\"Long-Term Relationship\",\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Honesty\",\"Empathy\"]', '[\"Afternoon\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-07-15 11:19:00', '2026-08-15 11:19:00', '[\"deep_conversations\"]'),
(1447, 1496, 39, 54, 80, 60, 'Surat', NULL, '[]', '[\"Exploring Possibilities\",\"Meaningful Dating\"]', '[\"A few times a week\"]', NULL, NULL, NULL, 'Spiritual', '[\"Tamil\"]', '[]', NULL, '[\"Creativity\",\"Patience\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-11-04 11:18:00', '2026-08-24 11:18:00', '[\"occasional_texting\"]'),
(1448, 1497, 18, 36, 150, 0, NULL, NULL, '[]', '[\"Marriage Minded\",\"Friendship First\"]', '[]', NULL, NULL, NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Empathy\",\"Patience\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-08-30 11:17:00', '2026-08-25 11:17:00', '[\"calls\"]'),
(1449, 1498, 39, 51, 20, 0, NULL, NULL, '[\"Gandhinagar\"]', '[\"Exploring Possibilities\"]', '[]', NULL, NULL, 'Global', NULL, '[\"Tamil\"]', '[]', NULL, '[\"Kindness\",\"Humour\"]', '[\"Morning\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-12-18 11:16:00', '2026-08-24 11:16:00', '[\"deep_conversations\"]'),
(1450, 1499, 25, 40, 40, 0, 'Gandhinagar', 160, '[]', '[\"Marriage Minded\"]', '[\"A few times a week\"]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Kindness\",\"Patience\"]', '[\"Afternoon\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-01-19 11:15:00', '2026-08-09 11:15:00', '[\"frequent_texting\"]'),
(1451, 1500, 27, 47, 80, 0, NULL, NULL, '[]', '[\"Casual Connection\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Kindness\",\"Patience\"]', '[\"Late night\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-05-31 11:14:00', '2026-08-21 11:14:00', '[\"occasional_texting\"]'),
(1452, 1501, 22, 42, 150, 0, NULL, NULL, '[]', '[\"Marriage Minded\",\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Creativity\",\"Honesty\"]', '[\"Late night\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-07-18 11:13:00', '2026-08-13 11:13:00', '[\"deep_conversations\"]'),
(1453, 1502, 38, 45, 20, 60, 'Ahmedabad', NULL, '[\"Gandhinagar\"]', '[\"Marriage Minded\",\"Meaningful Dating\"]', '[\"A few times a week\"]', 'Undergraduate', NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Curiosity\",\"Patience\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-10-15 11:12:00', '2026-08-16 11:12:00', '[\"light_fun_conversations\"]'),
(1454, 1503, 37, 57, 40, 0, NULL, NULL, '[]', '[\"Marriage Minded\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, 'Hindu', '[\"Hindi\"]', '[]', NULL, '[\"Curiosity\",\"Creativity\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-02-03 11:11:00', '2026-08-12 11:11:00', '[\"light_fun_conversations\"]'),
(1455, 1504, 18, 38, 80, 0, NULL, 160, '[]', '[\"Exploring Possibilities\",\"Marriage Minded\"]', '[]', NULL, 'Business Owner', NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Creativity\",\"Honesty\"]', '[\"Morning\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-08-19 11:10:00', '2026-08-26 11:10:00', '[\"voice_notes\"]'),
(1456, 1505, 29, 44, 150, 0, 'Vadodara', NULL, '[]', '[\"Friendship First\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Kindness\",\"Patience\"]', '[\"Afternoon\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-11-19 11:09:00', '2026-08-11 11:09:00', '[\"frequent_texting\"]'),
(1457, 1506, 26, 38, 20, 0, NULL, NULL, '[\"Vadodara\"]', '[\"Friendship First\",\"Marriage Minded\"]', '[]', NULL, NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Humour\",\"Patience\"]', '[\"Afternoon\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-08-20 11:08:00', '2026-08-19 11:08:00', '[\"frequent_texting\"]'),
(1458, 1507, 35, 55, 40, 0, NULL, NULL, '[]', '[\"Casual Connection\"]', '[]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Humour\",\"Patience\"]', '[\"Evening\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-03-19 11:07:00', '2026-08-15 11:07:00', '[\"voice_notes\"]'),
(1459, 1508, 39, 54, 80, 60, 'Surat', NULL, '[]', '[\"Marriage Minded\",\"Friendship First\"]', '[\"A few times a week\"]', NULL, NULL, NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Humour\",\"Patience\"]', '[\"Afternoon\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-04-10 11:06:00', '2026-08-13 11:06:00', '[\"calls\"]'),
(1460, 1509, 40, 60, 150, 0, NULL, 160, '[]', '[\"Meaningful Dating\",\"Casual Connection\"]', '[]', NULL, NULL, 'Indian', NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Ambition\",\"Empathy\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-08-19 11:05:00', '2026-08-15 11:05:00', '[\"voice_notes\"]'),
(1461, 1510, 40, 52, 20, 0, NULL, NULL, '[\"Gandhinagar\"]', '[\"Exploring Possibilities\",\"Marriage Minded\"]', '[]', 'Doctorate & Research', NULL, NULL, 'Hindu', '[\"Gujarati\"]', '[]', NULL, '[\"Ambition\",\"Humour\"]', '[\"Morning\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-09-08 11:04:00', '2026-08-26 11:04:00', '[\"frequent_texting\"]'),
(1462, 1511, 36, 51, 40, 0, 'Gandhinagar', NULL, '[]', '[\"Marriage Minded\",\"Friendship First\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Honesty\",\"Kindness\"]', '[\"Late night\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-08-06 11:03:00', '2026-08-17 11:03:00', '[\"occasional_texting\"]'),
(1463, 1512, 30, 50, 80, 0, NULL, NULL, '[]', '[\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Patience\",\"Creativity\"]', '[\"Late night\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-08-12 11:02:00', '2026-08-17 11:02:00', '[\"voice_notes\"]'),
(1464, 1513, 21, 41, 150, 0, NULL, NULL, '[]', '[\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Honesty\",\"Kindness\"]', '[\"Morning\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-08-02 11:01:00', '2026-08-19 11:01:00', '[\"voice_notes\"]'),
(1465, 1514, 32, 39, 20, 60, 'Ahmedabad', 160, '[\"Surat\"]', '[\"Casual Connection\"]', '[\"Occasionally\"]', NULL, 'Designer', NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Kindness\",\"Creativity\"]', '[\"Afternoon\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-12-27 11:00:00', '2026-08-10 11:00:00', '[\"voice_notes\"]'),
(1466, 1515, 27, 47, 40, 0, NULL, NULL, '[]', '[\"Casual Connection\",\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Ambition\",\"Creativity\"]', '[\"Morning\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-05-26 10:59:00', '2026-08-16 10:59:00', '[\"voice_notes\"]'),
(1467, 1516, 36, 56, 80, 0, NULL, NULL, '[]', '[\"Casual Connection\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Kindness\",\"Ambition\"]', '[\"Late night\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-12-08 10:58:00', '2026-08-22 10:58:00', '[\"deep_conversations\"]'),
(1468, 1517, 19, 34, 150, 0, 'Vadodara', NULL, '[]', '[\"Meaningful Dating\"]', '[\"Daily\"]', NULL, NULL, NULL, 'Sikh', '[\"Tamil\"]', '[]', NULL, '[\"Curiosity\",\"Honesty\"]', '[\"Afternoon\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-08-20 10:57:00', '2026-08-24 10:57:00', '[\"calls\"]'),
(1469, 1518, 27, 39, 20, 0, NULL, NULL, '[\"Ahmedabad\"]', '[\"Long-Term Relationship\"]', '[]', 'Postgraduate', NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Patience\",\"Honesty\"]', '[\"Late night\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-08-21 10:56:00', '2026-08-24 10:56:00', '[\"voice_notes\"]'),
(1470, 1519, 18, 37, 40, 0, NULL, 160, '[]', '[\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Empathy\",\"Creativity\"]', '[\"Morning\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-12-23 10:55:00', '2026-08-27 10:55:00', '[\"voice_notes\"]'),
(1471, 1520, 24, 39, 80, 60, 'Surat', NULL, '[]', '[\"Exploring Possibilities\",\"Meaningful Dating\"]', '[\"A few times a week\"]', NULL, NULL, 'Global', NULL, '[\"Hindi\"]', '[]', NULL, '[\"Patience\",\"Kindness\"]', '[\"Evening\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-02-26 10:54:00', '2026-08-17 10:54:00', '[\"light_fun_conversations\"]'),
(1472, 1521, 29, 49, 150, 0, NULL, NULL, '[]', '[\"Friendship First\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Honesty\",\"Ambition\"]', '[\"Morning\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-07-18 10:53:00', '2026-08-12 10:53:00', '[\"voice_notes\"]'),
(1473, 1522, 36, 48, 20, 0, NULL, NULL, '[\"Vadodara\"]', '[\"Friendship First\",\"Long-Term Relationship\"]', '[]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Humour\",\"Patience\"]', '[\"Evening\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-11-30 10:52:00', '2026-08-21 10:52:00', '[\"deep_conversations\"]'),
(1474, 1523, 25, 40, 40, 0, 'Gandhinagar', NULL, '[]', '[\"Marriage Minded\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Curiosity\",\"Humour\"]', '[\"Afternoon\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-07-13 10:51:00', '2026-08-17 10:51:00', '[\"voice_notes\"]'),
(1475, 1524, 32, 52, 80, 0, NULL, 160, '[]', '[\"Friendship First\"]', '[]', NULL, 'Doctor', NULL, 'Jain', '[\"Gujarati\"]', '[]', NULL, '[\"Humour\",\"Kindness\"]', '[\"Morning\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-11-01 10:50:00', '2026-08-17 10:50:00', '[\"deep_conversations\"]'),
(1476, 1525, 18, 34, 150, 0, NULL, NULL, '[]', '[\"Casual Connection\"]', '[]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Patience\",\"Kindness\"]', '[\"Late night\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-06-25 10:49:00', '2026-08-16 10:49:00', '[\"occasional_texting\"]'),
(1477, 1526, 20, 27, 20, 60, 'Ahmedabad', NULL, '[\"Ahmedabad\"]', '[\"Long-Term Relationship\",\"Casual Connection\"]', '[\"Daily\"]', 'Doctorate & Research', NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Curiosity\",\"Kindness\"]', '[\"Evening\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-02-13 10:48:00', '2026-08-17 10:48:00', '[\"light_fun_conversations\"]'),
(1478, 1527, 18, 36, 40, 0, NULL, NULL, '[]', '[\"Friendship First\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Curiosity\",\"Kindness\"]', '[\"Late night\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-07-08 10:47:00', '2026-08-24 10:47:00', '[\"deep_conversations\"]'),
(1479, 1528, 32, 52, 80, 0, NULL, NULL, '[]', '[\"Friendship First\",\"Long-Term Relationship\"]', '[]', NULL, NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Ambition\",\"Empathy\"]', '[\"Afternoon\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-09-29 10:46:00', '2026-08-28 10:46:00', '[\"frequent_texting\"]'),
(1480, 1529, 26, 41, 150, 0, 'Vadodara', 160, '[]', '[\"Friendship First\",\"Long-Term Relationship\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Ambition\",\"Humour\"]', '[\"Afternoon\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-07-15 10:45:00', '2026-08-12 10:45:00', '[\"calls\"]'),
(1481, 1530, 29, 41, 20, 0, NULL, NULL, '[\"Vadodara\"]', '[\"Casual Connection\",\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Kindness\",\"Ambition\"]', '[\"Afternoon\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-10-08 10:44:00', '2026-08-29 10:44:00', '[\"light_fun_conversations\"]'),
(1482, 1531, 32, 52, 40, 0, NULL, NULL, '[]', '[\"Long-Term Relationship\",\"Marriage Minded\"]', '[]', NULL, NULL, 'Gujarati', 'Sikh', '[\"Marathi\"]', '[]', NULL, '[\"Humour\",\"Honesty\"]', '[\"Morning\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-09-09 10:43:00', '2026-08-22 10:43:00', '[\"deep_conversations\"]'),
(1483, 1532, 25, 40, 80, 60, 'Surat', NULL, '[]', '[\"Meaningful Dating\",\"Exploring Possibilities\"]', '[\"A few times a week\"]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Curiosity\",\"Empathy\"]', '[\"Morning\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-05-13 10:42:00', '2026-08-09 10:42:00', '[\"occasional_texting\"]'),
(1484, 1533, 36, 56, 150, 0, NULL, NULL, '[]', '[\"Casual Connection\"]', '[]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Creativity\",\"Ambition\"]', '[\"Afternoon\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-12-28 10:41:00', '2026-08-26 10:41:00', '[\"frequent_texting\"]'),
(1485, 1534, 18, 28, 20, 0, NULL, 160, '[\"Gandhinagar\"]', '[\"Casual Connection\"]', '[]', 'Postgraduate', 'Doctor', NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Creativity\",\"Ambition\"]', '[\"Evening\"]', '[\"Quality time\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-08-01 10:40:00', '2026-08-13 10:40:00', '[\"frequent_texting\"]'),
(1486, 1535, 40, 55, 40, 0, 'Gandhinagar', NULL, '[]', '[\"Marriage Minded\",\"Long-Term Relationship\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Humour\",\"Curiosity\"]', '[\"Morning\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-02-22 10:39:00', '2026-08-26 10:39:00', '[\"voice_notes\"]'),
(1487, 1536, 25, 45, 80, 0, NULL, NULL, '[]', '[\"Friendship First\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Curiosity\",\"Patience\"]', '[\"Late night\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-03-23 10:38:00', '2026-08-27 10:38:00', '[\"light_fun_conversations\"]'),
(1488, 1537, 37, 57, 150, 0, NULL, NULL, '[]', '[\"Marriage Minded\"]', '[]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Humour\",\"Kindness\"]', '[\"Evening\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-02-03 10:37:00', '2026-08-16 10:37:00', '[\"deep_conversations\"]'),
(1489, 1538, 23, 30, 20, 60, 'Ahmedabad', NULL, '[\"Surat\"]', '[\"Meaningful Dating\",\"Friendship First\"]', '[\"Occasionally\"]', NULL, NULL, NULL, 'Sikh', '[\"Tamil\"]', '[]', NULL, '[\"Humour\",\"Creativity\"]', '[\"Evening\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-08-11 10:36:00', '2026-08-22 10:36:00', '[\"occasional_texting\"]'),
(1490, 1539, 38, 58, 40, 0, NULL, 160, '[]', '[\"Exploring Possibilities\",\"Marriage Minded\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Empathy\",\"Curiosity\"]', '[\"Morning\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-08-05 10:35:00', '2026-08-21 10:35:00', '[\"deep_conversations\"]'),
(1491, 1540, 19, 39, 80, 0, NULL, NULL, '[]', '[\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Kindness\",\"Honesty\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-09-21 10:34:00', '2026-08-16 10:34:00', '[\"occasional_texting\"]'),
(1492, 1541, 25, 40, 150, 0, 'Vadodara', NULL, '[]', '[\"Friendship First\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Curiosity\",\"Humour\"]', '[\"Evening\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-06-12 10:33:00', '2026-08-25 10:33:00', '[\"occasional_texting\"]'),
(1493, 1542, 30, 42, 20, 0, NULL, NULL, '[\"Vadodara\"]', '[\"Long-Term Relationship\"]', '[]', 'Undergraduate', NULL, 'Open', NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Honesty\",\"Creativity\"]', '[\"Afternoon\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-08-06 10:32:00', '2026-08-24 10:32:00', '[\"voice_notes\"]'),
(1494, 1543, 28, 48, 40, 0, NULL, NULL, '[]', '[\"Marriage Minded\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Patience\",\"Humour\"]', '[\"Morning\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-12-31 10:31:00', '2026-08-17 10:31:00', '[\"calls\"]'),
(1495, 1544, 45, 60, 80, 60, 'Surat', 160, '[]', '[\"Friendship First\"]', '[\"Daily\"]', NULL, 'Student', NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Patience\",\"Honesty\"]', '[\"Afternoon\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-02-05 10:30:00', '2026-08-21 10:30:00', '[\"occasional_texting\"]'),
(1496, 1545, 18, 33, 150, 0, NULL, NULL, '[]', '[\"Casual Connection\"]', '[]', NULL, NULL, NULL, 'Sikh', '[\"Gujarati\"]', '[]', NULL, '[\"Creativity\",\"Ambition\"]', '[\"Late night\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-03-11 10:29:00', '2026-08-18 10:29:00', '[\"calls\"]'),
(1497, 1546, 18, 25, 20, 0, NULL, NULL, '[\"Ahmedabad\"]', '[\"Exploring Possibilities\",\"Long-Term Relationship\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Empathy\",\"Ambition\"]', '[\"Afternoon\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-04-25 10:28:00', '2026-08-29 10:28:00', '[\"voice_notes\"]'),
(1498, 1547, 23, 38, 40, 0, 'Gandhinagar', NULL, '[]', '[\"Long-Term Relationship\"]', '[\"A few times a week\"]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Ambition\",\"Creativity\"]', '[\"Morning\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-02-19 10:27:00', '2026-08-09 10:27:00', '[\"frequent_texting\"]'),
(1499, 1548, 38, 58, 80, 0, NULL, NULL, '[]', '[\"Meaningful Dating\",\"Friendship First\"]', '[]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Empathy\",\"Patience\"]', '[\"Late night\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-07-17 10:26:00', '2026-08-27 10:26:00', '[\"occasional_texting\"]'),
(1500, 1549, 34, 54, 150, 0, NULL, 160, '[]', '[\"Casual Connection\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Honesty\",\"Kindness\"]', '[\"Evening\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-07-29 10:25:00', '2026-08-20 10:25:00', '[\"occasional_texting\"]'),
(1501, 1550, 38, 45, 20, 60, 'Ahmedabad', NULL, '[\"Surat\"]', '[\"Meaningful Dating\"]', '[\"Daily\"]', 'Postgraduate', NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Creativity\",\"Ambition\"]', '[\"Afternoon\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-10-18 10:24:00', '2026-08-10 10:24:00', '[\"calls\"]'),
(1502, 1551, 23, 43, 40, 0, NULL, NULL, '[]', '[\"Friendship First\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Creativity\",\"Empathy\"]', '[\"Morning\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-08-16 10:23:00', '2026-08-16 10:23:00', '[\"voice_notes\"]'),
(1503, 1552, 32, 52, 80, 0, NULL, NULL, '[]', '[\"Friendship First\",\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, 'Hindu', '[\"Tamil\"]', '[]', NULL, '[\"Honesty\",\"Curiosity\"]', '[\"Afternoon\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-07-29 10:22:00', '2026-08-15 10:22:00', '[\"calls\"]'),
(1504, 1553, 26, 41, 150, 0, 'Vadodara', NULL, '[]', '[\"Marriage Minded\"]', '[\"A few times a week\"]', NULL, NULL, 'Gujarati', NULL, '[\"Tamil\"]', '[]', NULL, '[\"Creativity\",\"Curiosity\"]', '[\"Afternoon\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-04-30 10:21:00', '2026-08-27 10:21:00', '[\"calls\"]'),
(1505, 1554, 37, 49, 20, 0, NULL, 160, '[\"Vadodara\"]', '[\"Marriage Minded\",\"Exploring Possibilities\"]', '[]', NULL, 'Student', NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Kindness\",\"Patience\"]', '[\"Evening\"]', '[\"Quality time\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-12-01 10:20:00', '2026-08-17 10:20:00', '[\"calls\"]'),
(1506, 1555, 18, 38, 40, 0, NULL, NULL, '[]', '[\"Friendship First\",\"Casual Connection\"]', '[]', NULL, NULL, NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Ambition\",\"Kindness\"]', '[\"Late night\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-01-15 10:19:00', '2026-08-10 10:19:00', '[\"calls\"]'),
(1507, 1556, 18, 33, 80, 60, 'Surat', NULL, '[]', '[\"Friendship First\",\"Long-Term Relationship\"]', '[\"A few times a week\"]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Curiosity\",\"Humour\"]', '[\"Late night\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-04-09 10:18:00', '2026-08-27 10:18:00', '[\"light_fun_conversations\"]'),
(1508, 1557, 21, 41, 150, 0, NULL, NULL, '[]', '[\"Exploring Possibilities\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Ambition\",\"Empathy\"]', '[\"Morning\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-12-06 10:17:00', '2026-08-23 10:17:00', '[\"occasional_texting\"]'),
(1509, 1558, 20, 32, 20, 0, NULL, NULL, '[\"Ahmedabad\"]', '[\"Casual Connection\",\"Friendship First\"]', '[]', 'Professional', NULL, NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Kindness\",\"Honesty\"]', '[\"Afternoon\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-05-19 10:16:00', '2026-08-17 10:16:00', '[\"occasional_texting\"]'),
(1510, 1559, 41, 56, 40, 0, 'Gandhinagar', 160, '[]', '[\"Friendship First\"]', '[\"Daily\"]', NULL, NULL, NULL, 'Spiritual', '[\"Punjabi\"]', '[]', NULL, '[\"Humour\",\"Empathy\"]', '[\"Afternoon\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-05-19 10:15:00', '2026-08-18 10:15:00', '[\"light_fun_conversations\"]'),
(1511, 1560, 19, 39, 80, 0, NULL, NULL, '[]', '[\"Exploring Possibilities\",\"Casual Connection\"]', '[]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Patience\",\"Humour\"]', '[\"Evening\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-12-22 10:14:00', '2026-08-17 10:14:00', '[\"occasional_texting\"]'),
(1512, 1561, 24, 44, 150, 0, NULL, NULL, '[]', '[\"Marriage Minded\",\"Casual Connection\"]', '[]', NULL, NULL, NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Ambition\",\"Patience\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-05-02 10:13:00', '2026-08-26 10:13:00', '[\"deep_conversations\"]'),
(1513, 1562, 28, 35, 20, 60, 'Ahmedabad', NULL, '[\"Gandhinagar\"]', '[\"Marriage Minded\",\"Friendship First\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Patience\",\"Humour\"]', '[\"Late night\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-03-14 10:12:00', '2026-08-27 10:12:00', '[\"frequent_texting\"]'),
(1514, 1563, 30, 50, 40, 0, NULL, NULL, '[]', '[\"Friendship First\"]', '[]', NULL, NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Creativity\",\"Humour\"]', '[\"Late night\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-09-16 10:11:00', '2026-08-28 10:11:00', '[\"occasional_texting\"]'),
(1515, 1564, 22, 42, 80, 0, NULL, 160, '[]', '[\"Casual Connection\",\"Meaningful Dating\"]', '[]', NULL, 'Designer', 'Open', NULL, '[\"Tamil\"]', '[]', NULL, '[\"Ambition\",\"Kindness\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-03-21 10:10:00', '2026-08-19 10:10:00', '[\"occasional_texting\"]'),
(1516, 1565, 23, 38, 150, 0, 'Vadodara', NULL, '[]', '[\"Exploring Possibilities\"]', '[\"A few times a week\"]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Honesty\",\"Kindness\"]', '[\"Afternoon\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-04-25 10:09:00', '2026-08-18 10:09:00', '[\"voice_notes\"]'),
(1517, 1566, 23, 35, 20, 0, NULL, NULL, '[\"Gandhinagar\"]', '[\"Friendship First\",\"Casual Connection\"]', '[]', 'Postgraduate', NULL, NULL, 'Open', '[\"Marathi\"]', '[]', NULL, '[\"Kindness\",\"Humour\"]', '[\"Morning\"]', '[\"Quality time\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-10-24 10:08:00', '2026-08-28 10:08:00', '[\"deep_conversations\"]'),
(1518, 1567, 35, 55, 40, 0, NULL, NULL, '[]', '[\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Curiosity\",\"Honesty\"]', '[\"Afternoon\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-08-23 10:07:00', '2026-08-29 10:07:00', '[\"frequent_texting\"]'),
(1519, 1568, 33, 48, 80, 60, 'Surat', NULL, '[]', '[\"Friendship First\",\"Long-Term Relationship\"]', '[\"A few times a week\"]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Kindness\",\"Curiosity\"]', '[\"Evening\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-11-24 10:06:00', '2026-08-24 10:06:00', '[\"light_fun_conversations\"]'),
(1520, 1569, 18, 36, 150, 0, NULL, 160, '[]', '[\"Long-Term Relationship\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Curiosity\",\"Honesty\"]', '[\"Afternoon\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-02-26 10:05:00', '2026-08-14 10:05:00', '[\"light_fun_conversations\"]'),
(1521, 1570, 28, 40, 20, 0, NULL, NULL, '[\"Gandhinagar\"]', '[\"Long-Term Relationship\",\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Kindness\",\"Empathy\"]', '[\"Evening\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-03-31 10:04:00', '2026-08-16 10:04:00', '[\"voice_notes\"]'),
(1522, 1571, 30, 45, 40, 0, 'Gandhinagar', NULL, '[]', '[\"Casual Connection\",\"Long-Term Relationship\"]', '[\"Occasionally\"]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Empathy\",\"Creativity\"]', '[\"Morning\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-12-24 10:03:00', '2026-08-09 10:03:00', '[\"deep_conversations\"]'),
(1523, 1572, 18, 37, 80, 0, NULL, NULL, '[]', '[\"Marriage Minded\"]', '[]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Creativity\",\"Honesty\"]', '[\"Morning\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-04-10 10:02:00', '2026-08-18 10:02:00', '[\"voice_notes\"]'),
(1524, 1573, 18, 33, 150, 0, NULL, NULL, '[]', '[\"Friendship First\"]', '[]', NULL, NULL, NULL, 'Open', '[\"Marathi\"]', '[]', NULL, '[\"Creativity\",\"Ambition\"]', '[\"Evening\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-04-05 10:01:00', '2026-08-09 10:01:00', '[\"deep_conversations\"]'),
(1525, 1574, 27, 34, 20, 60, 'Ahmedabad', 160, '[\"Surat\"]', '[\"Exploring Possibilities\"]', '[\"Occasionally\"]', 'Professional', 'Entrepreneur', NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Patience\",\"Empathy\"]', '[\"Afternoon\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-07-08 10:00:00', '2026-08-26 10:00:00', '[\"voice_notes\"]'),
(1526, 1575, 18, 38, 40, 0, NULL, NULL, '[]', '[\"Friendship First\"]', '[]', NULL, NULL, 'Open', NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Ambition\",\"Humour\"]', '[\"Afternoon\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-08-28 09:59:00', '2026-08-28 09:59:00', '[\"calls\"]'),
(1527, 1576, 20, 40, 80, 0, NULL, NULL, '[]', '[\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Curiosity\",\"Patience\"]', '[\"Morning\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-05-16 09:58:00', '2026-08-20 09:58:00', '[\"voice_notes\"]'),
(1528, 1577, 26, 41, 150, 0, 'Vadodara', NULL, '[]', '[\"Long-Term Relationship\",\"Meaningful Dating\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Humour\",\"Patience\"]', '[\"Morning\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-09-28 09:57:00', '2026-08-13 09:57:00', '[\"deep_conversations\"]'),
(1529, 1578, 34, 46, 20, 0, NULL, NULL, '[\"Gandhinagar\"]', '[\"Friendship First\",\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Patience\",\"Creativity\"]', '[\"Evening\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-04-26 09:56:00', '2026-08-22 09:56:00', '[\"voice_notes\"]'),
(1530, 1579, 26, 46, 40, 0, NULL, 160, '[]', '[\"Meaningful Dating\",\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Honesty\",\"Kindness\"]', '[\"Evening\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-11-07 09:55:00', '2026-08-09 09:55:00', '[\"calls\"]'),
(1531, 1580, 25, 40, 80, 60, 'Surat', NULL, '[]', '[\"Casual Connection\"]', '[\"Occasionally\"]', NULL, NULL, NULL, 'Open', '[\"Tamil\"]', '[]', NULL, '[\"Curiosity\",\"Ambition\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-09-02 09:54:00', '2026-08-14 09:54:00', '[\"frequent_texting\"]'),
(1532, 1581, 19, 39, 150, 0, NULL, NULL, '[]', '[\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Honesty\",\"Patience\"]', '[\"Evening\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-08-31 09:53:00', '2026-08-22 09:53:00', '[\"light_fun_conversations\"]'),
(1533, 1582, 30, 42, 20, 0, NULL, NULL, '[\"Gandhinagar\"]', '[\"Marriage Minded\"]', '[]', 'Doctorate & Research', NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Ambition\",\"Patience\"]', '[\"Late night\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-06-14 09:52:00', '2026-08-15 09:52:00', '[\"frequent_texting\"]'),
(1534, 1583, 37, 52, 40, 0, 'Gandhinagar', NULL, '[]', '[\"Exploring Possibilities\",\"Meaningful Dating\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Patience\",\"Kindness\"]', '[\"Evening\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-08-07 09:51:00', '2026-08-22 09:51:00', '[\"occasional_texting\"]'),
(1535, 1584, 18, 36, 80, 0, NULL, 160, '[]', '[\"Marriage Minded\"]', '[]', NULL, 'Software Engineer', NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Honesty\",\"Humour\"]', '[\"Evening\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-03-23 09:50:00', '2026-08-22 09:50:00', '[\"light_fun_conversations\"]'),
(1536, 1585, 26, 46, 150, 0, NULL, NULL, '[]', '[\"Exploring Possibilities\"]', '[]', NULL, NULL, NULL, NULL, '[\"Malayalam\"]', '[]', NULL, '[\"Creativity\",\"Humour\"]', '[\"Afternoon\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-08-25 09:49:00', '2026-08-25 09:49:00', '[\"light_fun_conversations\"]'),
(1537, 1586, 35, 42, 20, 60, 'Ahmedabad', NULL, '[\"Surat\"]', '[\"Meaningful Dating\"]', '[\"Occasionally\"]', NULL, NULL, 'Open', NULL, '[\"Marathi\"]', '[]', NULL, '[\"Creativity\",\"Patience\"]', '[\"Afternoon\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-12-17 09:48:00', '2026-08-25 09:48:00', '[\"light_fun_conversations\"]'),
(1538, 1587, 34, 54, 40, 0, NULL, NULL, '[]', '[\"Casual Connection\"]', '[]', NULL, NULL, NULL, 'Open', '[\"Gujarati\"]', '[]', NULL, '[\"Curiosity\",\"Humour\"]', '[\"Evening\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-01-27 09:47:00', '2026-08-29 09:47:00', '[\"occasional_texting\"]'),
(1539, 1588, 32, 52, 80, 0, NULL, NULL, '[]', '[\"Meaningful Dating\",\"Casual Connection\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Humour\",\"Creativity\"]', '[\"Morning\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2025-07-17 09:46:00', '2026-08-24 09:46:00', '[\"voice_notes\"]'),
(1540, 1589, 26, 41, 150, 0, 'Vadodara', 160, '[]', '[\"Meaningful Dating\",\"Exploring Possibilities\"]', '[\"A few times a week\"]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Kindness\",\"Humour\"]', '[\"Morning\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-02-04 09:45:00', '2026-08-25 09:45:00', '[\"occasional_texting\"]'),
(1541, 1590, 18, 28, 20, 0, NULL, NULL, '[\"Gandhinagar\"]', '[\"Casual Connection\"]', '[]', 'Postgraduate', NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Honesty\",\"Curiosity\"]', '[\"Late night\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-06-25 09:44:00', '2026-08-22 09:44:00', '[\"occasional_texting\"]'),
(1542, 1591, 26, 46, 40, 0, NULL, NULL, '[]', '[\"Long-Term Relationship\"]', '[]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Curiosity\",\"Empathy\"]', '[\"Afternoon\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-08-19 09:43:00', '2026-08-19 09:43:00', '[\"light_fun_conversations\"]'),
(1543, 1592, 27, 42, 80, 60, 'Surat', NULL, '[]', '[\"Exploring Possibilities\",\"Friendship First\"]', '[\"Daily\"]', NULL, NULL, NULL, NULL, '[\"Hindi\"]', '[]', NULL, '[\"Kindness\",\"Honesty\"]', '[\"Evening\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-04-16 09:42:00', '2026-08-25 09:42:00', '[\"occasional_texting\"]'),
(1544, 1593, 36, 56, 150, 0, NULL, NULL, '[]', '[\"Meaningful Dating\",\"Casual Connection\"]', '[]', NULL, NULL, NULL, NULL, '[\"English\"]', '[]', NULL, '[\"Empathy\",\"Ambition\"]', '[\"Morning\"]', '[\"Words of affirmation\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-12-25 09:41:00', '2026-08-27 09:41:00', '[\"occasional_texting\"]');
INSERT INTO `discoverfilterpreferences` (`id`, `userId`, `minAge`, `maxAge`, `maxDistanceKm`, `minScore`, `city`, `minHeight`, `hometown`, `datingIntentions`, `lifestyleTags`, `education`, `profession`, `community`, `religion`, `languages`, `pronouns`, `sexuality`, `qualities`, `preferredTalkingHours`, `loveLanguages`, `smoking`, `drinking`, `weed`, `verifiedOnly`, `onlineNow`, `hasPrompts`, `hasEventInterest`, `createdAt`, `updatedAt`, `communicationStyles`) VALUES
(1545, 1594, 30, 42, 20, 0, NULL, 160, '[\"Vadodara\"]', '[\"Long-Term Relationship\"]', '[]', NULL, 'Designer', NULL, 'Sikh', '[\"Gujarati\"]', '[]', NULL, '[\"Creativity\",\"Empathy\"]', '[\"Afternoon\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2026-07-16 09:40:00', '2026-08-11 09:40:00', '[\"frequent_texting\"]'),
(1546, 1595, 36, 51, 40, 0, 'Gandhinagar', NULL, '[]', '[\"Marriage Minded\"]', '[\"Occasionally\"]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Empathy\",\"Curiosity\"]', '[\"Afternoon\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-09-24 09:39:00', '2026-08-17 09:39:00', '[\"frequent_texting\"]'),
(1547, 1596, 18, 36, 80, 0, NULL, NULL, '[]', '[\"Meaningful Dating\"]', '[]', NULL, NULL, NULL, NULL, '[\"Tamil\"]', '[]', NULL, '[\"Creativity\",\"Patience\"]', '[\"Evening\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-03-29 09:38:00', '2026-08-15 09:38:00', '[\"calls\"]'),
(1548, 1597, 21, 41, 150, 0, NULL, NULL, '[]', '[\"Meaningful Dating\"]', '[]', NULL, NULL, 'Indian', NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Humour\",\"Kindness\"]', '[\"Evening\"]', '[\"Acts of service\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-12-04 09:37:00', '2026-08-14 09:37:00', '[\"frequent_texting\"]'),
(1549, 1598, 27, 34, 20, 60, 'Ahmedabad', NULL, '[\"Gandhinagar\"]', '[\"Exploring Possibilities\",\"Friendship First\"]', '[\"A few times a week\"]', 'Postgraduate', NULL, NULL, NULL, '[\"Marathi\"]', '[]', NULL, '[\"Humour\",\"Patience\"]', '[\"Late night\"]', '[\"Physical touch\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-10-29 09:36:00', '2026-08-27 09:36:00', '[\"light_fun_conversations\"]'),
(1550, 1599, 23, 43, 40, 0, NULL, 160, '[]', '[\"Marriage Minded\"]', '[]', NULL, NULL, NULL, NULL, '[\"Gujarati\"]', '[]', NULL, '[\"Kindness\",\"Curiosity\"]', '[\"Evening\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2025-08-09 09:35:00', '2026-08-21 09:35:00', '[\"calls\"]'),
(1551, 1600, 37, 57, 80, 0, NULL, NULL, '[]', '[\"Long-Term Relationship\"]', '[]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Patience\",\"Humour\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 1, 0, '2026-04-16 09:34:00', '2026-08-10 09:34:00', '[\"occasional_texting\"]'),
(1552, 1601, 32, 47, 150, 0, 'Vadodara', NULL, '[]', '[\"Long-Term Relationship\"]', '[\"A few times a week\"]', NULL, NULL, NULL, 'Open', '[\"Gujarati\"]', '[]', NULL, '[\"Curiosity\",\"Empathy\"]', '[\"Evening\"]', '[\"Receiving gifts\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-07-02 09:33:00', '2026-08-09 09:33:00', '[\"occasional_texting\"]'),
(1553, 1602, 23, 35, 20, 0, NULL, NULL, '[\"Surat\"]', '[\"Meaningful Dating\",\"Marriage Minded\"]', '[]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Kindness\",\"Humour\"]', '[\"Afternoon\"]', '[\"Quality time\"]', NULL, NULL, NULL, 1, 0, 1, 0, '2025-07-31 09:32:00', '2026-08-16 09:32:00', '[\"light_fun_conversations\"]'),
(1554, 1603, 19, 39, 40, 0, NULL, NULL, '[]', '[\"Casual Connection\",\"Marriage Minded\"]', '[]', NULL, NULL, NULL, NULL, '[\"Punjabi\"]', '[]', NULL, '[\"Patience\",\"Ambition\"]', '[\"Evening\"]', '[\"Quality time\"]', NULL, NULL, NULL, 0, 0, 0, 0, '2026-02-19 09:31:00', '2026-08-22 09:31:00', '[\"occasional_texting\"]');

-- --------------------------------------------------------

--
-- Table structure for table `eventregistrations`
--

CREATE TABLE `eventregistrations` (
  `id` int(11) NOT NULL,
  `eventId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `status` enum('registered','promoted','cancelled') NOT NULL DEFAULT 'registered',
  `registeredAt` datetime NOT NULL,
  `cancelledAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `eventregistrations`
--

INSERT INTO `eventregistrations` (`id`, `eventId`, `userId`, `status`, `registeredAt`, `cancelledAt`, `createdAt`, `updatedAt`) VALUES
(1, 1, 1, 'registered', '2026-08-06 22:27:21', NULL, '2026-08-11 18:50:36', '2026-08-11 22:27:22'),
(2, 1, 3, 'registered', '2026-08-06 22:27:21', NULL, '2026-08-11 18:50:36', '2026-08-11 22:27:22'),
(3, 2, 3, 'registered', '2026-08-06 22:27:21', NULL, '2026-08-11 18:50:36', '2026-08-11 22:27:22'),
(4, 3, 1, 'registered', '2026-08-06 22:27:21', NULL, '2026-08-11 18:50:36', '2026-08-11 22:27:22'),
(5, 4, 1, 'registered', '2026-08-06 22:27:21', NULL, '2026-08-11 18:50:36', '2026-08-11 22:27:22'),
(6, 5, 1, 'cancelled', '2026-08-06 22:27:21', '2026-08-09 22:27:21', '2026-08-11 18:50:36', '2026-08-11 22:27:22'),
(14, 1, 49, 'cancelled', '2026-08-12 10:38:36', '2026-08-12 10:38:42', '2026-08-12 10:38:36', '2026-08-12 10:38:42'),
(23, 1, 85, 'cancelled', '2026-08-13 06:50:24', '2026-08-17 08:36:21', '2026-08-13 06:50:24', '2026-08-17 08:36:21');

-- --------------------------------------------------------

--
-- Table structure for table `events`
--

CREATE TABLE `events` (
  `id` int(11) NOT NULL,
  `title` varchar(160) NOT NULL,
  `description` text NOT NULL,
  `category` varchar(80) NOT NULL,
  `city` varchar(100) NOT NULL,
  `venueName` varchar(160) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `startDateTime` datetime NOT NULL,
  `endDateTime` datetime NOT NULL,
  `registrationDeadline` datetime DEFAULT NULL,
  `capacity` int(10) UNSIGNED NOT NULL,
  `status` enum('draft','published','cancelled','completed') NOT NULL DEFAULT 'draft',
  `visibility` enum('public','private') NOT NULL DEFAULT 'public',
  `registrationOpen` tinyint(1) NOT NULL DEFAULT 1,
  `heroImageUrl` varchar(500) DEFAULT NULL,
  `organizerId` int(11) NOT NULL,
  `price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `dressCode` varchar(120) DEFAULT NULL,
  `minAge` int(10) UNSIGNED DEFAULT NULL,
  `maxAge` int(10) UNSIGNED DEFAULT NULL,
  `language` varchar(160) DEFAULT NULL,
  `agenda` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`agenda`)),
  `facilities` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`facilities`)),
  `interests` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`interests`)),
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `waitlistCapacity` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `waitlistEnabled` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `events`
--

INSERT INTO `events` (`id`, `title`, `description`, `category`, `city`, `venueName`, `address`, `latitude`, `longitude`, `startDateTime`, `endDateTime`, `registrationDeadline`, `capacity`, `status`, `visibility`, `registrationOpen`, `heroImageUrl`, `organizerId`, `price`, `dressCode`, `minAge`, `maxAge`, `language`, `agenda`, `facilities`, `interests`, `createdAt`, `updatedAt`, `waitlistCapacity`, `waitlistEnabled`) VALUES
(1, 'AMORAA QA Coffee & Conversation', 'AMORAA QA Coffee & Conversation is realistic development-only data for exercising the existing event flows.', 'Coffee Meetup', 'Ahmedabad', 'The Courtyard, Ahmedabad', 'University Road, Ahmedabad', 23.0395000, 72.5660000, '2026-08-13 22:27:21', '2026-08-14 01:27:21', NULL, 24, 'published', 'public', 1, '/uploads/e2e-test/coffee_meetup.png', 11, 499.00, 'Smart casual', 21, 40, 'English, Hindi, Gujarati', '[{\"time\":\"18:00\",\"title\":\"Welcome and introductions\"},{\"time\":\"18:30\",\"title\":\"Hosted conversation circles\"}]', '[\"Parking\",\"Accessible entrance\",\"Filtered water\"]', '[\"Conversation\",\"Community\",\"Coffee Meetup\"]', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 0, 1),
(2, 'AMORAA QA Intimate Garba Evening', 'AMORAA QA Intimate Garba Evening is realistic development-only data for exercising the existing event flows.', 'Culture', 'Ahmedabad', 'The Courtyard, Ahmedabad', 'University Road, Ahmedabad', 23.0395000, 72.5660000, '2026-08-14 22:27:21', '2026-08-15 02:27:21', NULL, 1, 'published', 'public', 1, '/uploads/e2e-test/garba_night.png', 11, 0.00, 'Festive traditional', 21, 40, 'English, Hindi, Gujarati', '[{\"time\":\"18:00\",\"title\":\"Welcome and introductions\"},{\"time\":\"18:30\",\"title\":\"Hosted conversation circles\"}]', '[\"Parking\",\"Accessible entrance\",\"Filtered water\"]', '[\"Conversation\",\"Community\",\"Culture\"]', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 0, 1),
(3, 'AMORAA QA Live Music Social', 'AMORAA QA Live Music Social is realistic development-only data for exercising the existing event flows.', 'Live Music', 'Ahmedabad', 'The Courtyard, Ahmedabad', 'University Road, Ahmedabad', 23.0395000, 72.5660000, '2026-08-11 21:27:21', '2026-08-12 00:27:21', NULL, 30, 'published', 'public', 1, '/uploads/e2e-test/live_music.png', 11, 0.00, 'Smart casual', 21, 40, 'English, Hindi, Gujarati', '[{\"time\":\"18:00\",\"title\":\"Welcome and introductions\"},{\"time\":\"18:30\",\"title\":\"Hosted conversation circles\"}]', '[\"Parking\",\"Accessible entrance\",\"Filtered water\"]', '[\"Conversation\",\"Community\",\"Live Music\"]', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 0, 1),
(4, 'AMORAA QA Old City Food Walk', 'AMORAA QA Old City Food Walk is realistic development-only data for exercising the existing event flows.', 'Food Walk', 'Ahmedabad', 'The Courtyard, Ahmedabad', 'University Road, Ahmedabad', 23.0395000, 72.5660000, '2026-08-06 22:27:21', '2026-08-07 02:27:21', NULL, 20, 'completed', 'public', 0, '/uploads/e2e-test/old_city_food_walk.png', 11, 0.00, 'Smart casual', 21, 40, 'English, Hindi, Gujarati', '[{\"time\":\"18:00\",\"title\":\"Welcome and introductions\"},{\"time\":\"18:30\",\"title\":\"Hosted conversation circles\"}]', '[\"Parking\",\"Accessible entrance\",\"Filtered water\"]', '[\"Conversation\",\"Community\",\"Food Walk\"]', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 0, 1),
(5, 'AMORAA QA Rooftop Mixer', 'AMORAA QA Rooftop Mixer is realistic development-only data for exercising the existing event flows.', 'Social Mixer', 'Ahmedabad', 'The Courtyard, Ahmedabad', 'University Road, Ahmedabad', 23.0395000, 72.5660000, '2026-08-15 22:27:21', '2026-08-16 02:27:21', NULL, 40, 'cancelled', 'public', 0, '/uploads/e2e-test/startup_networking_mixer.png', 11, 0.00, 'Smart casual', 21, 40, 'English, Hindi, Gujarati', '[{\"time\":\"18:00\",\"title\":\"Welcome and introductions\"},{\"time\":\"18:30\",\"title\":\"Hosted conversation circles\"}]', '[\"Parking\",\"Accessible entrance\",\"Filtered water\"]', '[\"Conversation\",\"Community\",\"Social Mixer\"]', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `eventwaitlist`
--

CREATE TABLE `eventwaitlist` (
  `id` int(11) NOT NULL,
  `eventId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `status` enum('waiting','promoted','left') NOT NULL DEFAULT 'waiting',
  `joinedAt` datetime NOT NULL,
  `endedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `identityverificationdecisionevents`
--

CREATE TABLE `identityverificationdecisionevents` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `verificationId` bigint(20) UNSIGNED NOT NULL,
  `administratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `action` enum('approve','reject','request_resubmission') NOT NULL,
  `fromStatus` enum('pending','under_review','verified','rejected','resubmission_requested') NOT NULL,
  `toStatus` enum('pending','under_review','verified','rejected','resubmission_requested') NOT NULL,
  `reasonId` bigint(20) UNSIGNED DEFAULT NULL,
  `reasonCodeSnapshot` varchar(80) DEFAULT NULL,
  `reasonLabelSnapshot` varchar(160) DEFAULT NULL,
  `reasonDetail` varchar(500) DEFAULT NULL,
  `requiredItems` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`requiredItems`)),
  `internalNote` varchar(500) DEFAULT NULL,
  `submissionVersion` int(10) UNSIGNED NOT NULL,
  `idempotencyKey` varchar(160) NOT NULL,
  `requestHash` char(64) NOT NULL,
  `responseSnapshot` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`responseSnapshot`)),
  `createdAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `identityverificationreasons`
--

CREATE TABLE `identityverificationreasons` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(80) NOT NULL,
  `action` enum('reject','request_resubmission') NOT NULL,
  `label` varchar(160) NOT NULL,
  `allowsDetail` tinyint(1) NOT NULL DEFAULT 0,
  `requiresDetail` tinyint(1) NOT NULL DEFAULT 0,
  `allowedItems` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`allowedItems`)),
  `isActive` tinyint(1) NOT NULL DEFAULT 1,
  `sortOrder` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `identityverifications`
--

CREATE TABLE `identityverifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userId` int(11) NOT NULL,
  `status` enum('pending','under_review','verified','rejected','resubmission_requested') NOT NULL DEFAULT 'pending',
  `aadhaarStoragePath` varchar(500) NOT NULL,
  `aadhaarMimeType` varchar(50) NOT NULL,
  `aadhaarSizeBytes` int(10) UNSIGNED NOT NULL,
  `selfieStoragePath` varchar(500) NOT NULL,
  `selfieMimeType` varchar(50) NOT NULL,
  `selfieSizeBytes` int(10) UNSIGNED NOT NULL,
  `submittedAt` datetime NOT NULL,
  `reviewedAt` datetime DEFAULT NULL,
  `rejectionReason` varchar(500) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `reviewerAdministratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `reviewVersion` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `submissionVersion` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `reviewReasonCode` varchar(80) DEFAULT NULL,
  `resubmissionItems` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`resubmissionItems`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `identityverifications`
--

INSERT INTO `identityverifications` (`id`, `userId`, `status`, `aadhaarStoragePath`, `aadhaarMimeType`, `aadhaarSizeBytes`, `selfieStoragePath`, `selfieMimeType`, `selfieSizeBytes`, `submittedAt`, `reviewedAt`, `rejectionReason`, `createdAt`, `updatedAt`, `reviewerAdministratorId`, `reviewVersion`, `submissionVersion`, `reviewReasonCode`, `resubmissionItems`) VALUES
(1, 1, 'verified', 'identity-verification/e2e-aarav-document.png', 'image/png', 300307, 'identity-verification/e2e-aarav-selfie.png', 'image/png', 300307, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(2, 2, 'verified', 'identity-verification/e2e-diya-document.png', 'image/png', 291521, 'identity-verification/e2e-diya-selfie.png', 'image/png', 291521, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(3, 3, 'verified', 'identity-verification/e2e-kavya-document.png', 'image/png', 305837, 'identity-verification/e2e-kavya-selfie.png', 'image/png', 305837, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(4, 4, 'verified', 'identity-verification/e2e-riya-document.png', 'image/png', 226838, 'identity-verification/e2e-riya-selfie.png', 'image/png', 226838, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(5, 5, 'verified', 'identity-verification/e2e-meera-document.png', 'image/png', 290522, 'identity-verification/e2e-meera-selfie.png', 'image/png', 290522, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(6, 6, 'verified', 'identity-verification/e2e-ananya-document.png', 'image/png', 89226, 'identity-verification/e2e-ananya-selfie.png', 'image/png', 89226, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(7, 7, 'verified', 'identity-verification/e2e-nisha-document.png', 'image/png', 94283, 'identity-verification/e2e-nisha-selfie.png', 'image/png', 94283, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(8, 8, 'pending', 'identity-verification/e2e-isha-document.png', 'image/png', 91338, 'identity-verification/e2e-isha-selfie.png', 'image/png', 91338, '2026-01-30 10:00:00', NULL, NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(9, 9, 'verified', 'identity-verification/e2e-sara-document.png', 'image/png', 140107, 'identity-verification/e2e-sara-selfie.png', 'image/png', 140107, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(10, 10, 'verified', 'identity-verification/e2e-tara-document.png', 'image/png', 66050, 'identity-verification/e2e-tara-selfie.png', 'image/png', 66050, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(11, 11, 'verified', 'identity-verification/e2e-vihaan-document.png', 'image/png', 288618, 'identity-verification/e2e-vihaan-selfie.png', 'image/png', 288618, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(12, 12, 'verified', 'identity-verification/e2e-leela-document.png', 'image/png', 260916, 'identity-verification/e2e-leela-selfie.png', 'image/png', 260916, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:54', '2026-08-11 20:54:54', NULL, 1, 1, NULL, NULL),
(13, 13, 'verified', 'identity-verification/e2e-neha-document.png', 'image/png', 125242, 'identity-verification/e2e-neha-selfie.png', 'image/png', 125242, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:55', '2026-08-11 20:54:55', NULL, 1, 1, NULL, NULL),
(14, 14, 'verified', 'identity-verification/e2e-priya-document.png', 'image/png', 125673, 'identity-verification/e2e-priya-selfie.png', 'image/png', 125673, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:55', '2026-08-11 20:54:55', NULL, 1, 1, NULL, NULL),
(15, 15, 'verified', 'identity-verification/e2e-zoya-document.png', 'image/png', 150508, 'identity-verification/e2e-zoya-selfie.png', 'image/png', 150508, '2026-01-30 10:00:00', '2026-02-01 10:00:00', NULL, '2026-08-11 20:54:55', '2026-08-11 20:54:55', NULL, 1, 1, NULL, NULL),
(16, 49, 'pending', 'identity-verification/49-aadhaar-1786530964855-d2c118a70da8c0a7994ca707b7a5bc8fe78a.jpg', 'image/jpeg', 170129, 'identity-verification/49-selfie-1786530964857-5124feafd21cfe16a943a6e7921a47a3f1a5.jpg', 'image/jpeg', 348166, '2026-08-12 10:36:04', NULL, NULL, '2026-08-12 10:36:04', '2026-08-12 10:36:04', NULL, 1, 1, NULL, NULL),
(21, 85, 'pending', 'identity-verification/85-aadhaar-1786604188520-1f84c9165492ed770865017cea2e0e89dbb2.jpg', 'image/jpeg', 62327, 'identity-verification/85-selfie-1786604188589-f53334013cf93bc000d49f446707254c038c.jpg', 'image/jpeg', 319778, '2026-08-13 06:56:28', NULL, NULL, '2026-08-13 06:56:28', '2026-08-13 06:56:28', NULL, 1, 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `matches`
--

CREATE TABLE `matches` (
  `id` int(11) NOT NULL,
  `userOneId` int(11) NOT NULL,
  `userTwoId` int(11) NOT NULL,
  `matchedAt` datetime NOT NULL,
  `createdAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `matches`
--

INSERT INTO `matches` (`id`, `userOneId`, `userTwoId`, `matchedAt`, `createdAt`) VALUES
(1, 1, 3, '2026-08-01 22:27:21', '2026-08-01 18:50:36'),
(2, 1, 6, '2026-07-22 22:27:21', '2026-07-22 18:50:36'),
(18, 3, 85, '2026-08-13 07:06:31', '2026-08-13 07:06:31'),
(303, 1454, 1461, '2026-08-28 12:00:00', '2026-08-29 12:52:34'),
(304, 1454, 1468, '2026-08-27 12:00:00', '2026-08-29 12:52:34'),
(305, 1454, 1475, '2026-08-26 12:00:00', '2026-08-29 12:52:34'),
(306, 1454, 1489, '2026-08-24 12:00:00', '2026-08-29 12:52:34'),
(307, 1454, 1496, '2026-08-23 12:00:00', '2026-08-29 12:52:34'),
(308, 1454, 1510, '2026-08-21 12:00:00', '2026-08-29 12:52:34'),
(309, 1454, 1456, '2026-08-15 12:00:00', '2026-08-29 12:52:34'),
(310, 1457, 1458, '2026-08-26 12:00:00', '2026-08-29 12:52:34'),
(311, 1463, 1464, '2026-08-20 12:00:00', '2026-08-29 12:52:34'),
(312, 1469, 1470, '2026-08-14 12:00:00', '2026-08-29 12:52:34'),
(313, 1475, 1476, '2026-08-08 12:00:00', '2026-08-29 12:52:34'),
(314, 1481, 1482, '2026-08-02 12:00:00', '2026-08-29 12:52:34'),
(315, 1487, 1488, '2026-07-27 12:00:00', '2026-08-29 12:52:34'),
(316, 1493, 1494, '2026-07-21 12:00:00', '2026-08-29 12:52:34'),
(317, 1499, 1500, '2026-07-15 12:00:00', '2026-08-29 12:52:34'),
(318, 1505, 1506, '2026-07-09 12:00:00', '2026-08-29 12:52:34'),
(319, 1511, 1512, '2026-07-03 12:00:00', '2026-08-29 12:52:34'),
(320, 1517, 1518, '2026-06-27 12:00:00', '2026-08-29 12:52:34'),
(321, 1523, 1524, '2026-06-21 12:00:00', '2026-08-29 12:52:34'),
(322, 1529, 1530, '2026-06-15 12:00:00', '2026-08-29 12:52:34'),
(323, 1535, 1536, '2026-06-09 12:00:00', '2026-08-29 12:52:34'),
(324, 1541, 1542, '2026-06-03 12:00:00', '2026-08-29 12:52:34'),
(325, 1547, 1548, '2026-08-26 12:00:00', '2026-08-29 12:52:34'),
(326, 1553, 1554, '2026-08-20 12:00:00', '2026-08-29 12:52:34'),
(327, 1559, 1560, '2026-08-14 12:00:00', '2026-08-29 12:52:34'),
(328, 1565, 1566, '2026-08-08 12:00:00', '2026-08-29 12:52:34'),
(329, 1571, 1572, '2026-08-02 12:00:00', '2026-08-29 12:52:34'),
(330, 1577, 1578, '2026-07-27 12:00:00', '2026-08-29 12:52:34'),
(331, 1583, 1584, '2026-07-21 12:00:00', '2026-08-29 12:52:34'),
(332, 1589, 1590, '2026-07-15 12:00:00', '2026-08-29 12:52:34'),
(333, 1595, 1596, '2026-07-09 12:00:00', '2026-08-29 12:52:34'),
(334, 1601, 1602, '2026-07-03 12:00:00', '2026-08-29 12:52:34');

-- --------------------------------------------------------

--
-- Table structure for table `matchingactionfailures`
--

CREATE TABLE `matchingactionfailures` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `actionType` enum('like','super_like','rose') NOT NULL,
  `actorUserId` int(11) DEFAULT NULL,
  `targetUserId` int(11) DEFAULT NULL,
  `requestedTargetReference` varchar(80) DEFAULT NULL,
  `safeCode` varchar(80) NOT NULL,
  `safeCategory` enum('business_rejection','system_failure') NOT NULL DEFAULT 'business_rejection',
  `safeStage` varchar(80) NOT NULL,
  `retryable` tinyint(1) NOT NULL DEFAULT 0,
  `resolutionStatus` enum('not_applicable','unresolved','resolved') NOT NULL DEFAULT 'not_applicable',
  `createdAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `messagemedia`
--

CREATE TABLE `messagemedia` (
  `id` int(11) NOT NULL,
  `messageId` int(11) NOT NULL,
  `mediaType` enum('image') NOT NULL DEFAULT 'image',
  `originalName` varchar(255) NOT NULL,
  `storagePath` varchar(255) NOT NULL,
  `mimeType` varchar(100) NOT NULL,
  `sizeBytes` int(11) NOT NULL,
  `createdAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` int(11) NOT NULL,
  `conversationId` int(11) NOT NULL,
  `senderId` int(11) NOT NULL,
  `type` enum('text','image') NOT NULL DEFAULT 'text',
  `text` text DEFAULT NULL,
  `context` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`context`)),
  `status` enum('sent','delivered','read') NOT NULL DEFAULT 'sent',
  `deliveredAt` datetime DEFAULT NULL,
  `readAt` datetime DEFAULT NULL,
  `deletedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `conversationId`, `senderId`, `type`, `text`, `context`, `status`, `deliveredAt`, `readAt`, `deletedAt`, `createdAt`, `updatedAt`) VALUES
(1, 1, 3, 'text', 'Your neighbourhood café prompt made me smile.', NULL, 'read', '2026-08-11 20:30:33', '2026-08-11 20:30:33', NULL, '2026-08-11 17:30:36', '2026-08-11 18:50:36'),
(2, 1, 1, 'text', 'Then I need your most honest café recommendation.', NULL, 'read', '2026-08-11 20:40:33', '2026-08-11 20:40:33', NULL, '2026-08-11 17:50:36', '2026-08-11 18:50:36'),
(3, 1, 3, 'text', 'Deal. I know a quiet place near the old city.', NULL, 'sent', NULL, NULL, NULL, '2026-08-11 18:10:36', '2026-08-11 18:50:36'),
(4, 1, 1, 'text', 'That sounds like a very good first plan.', NULL, 'read', '2026-08-13 07:06:02', '2026-08-13 07:06:02', NULL, '2026-08-11 18:30:36', '2026-08-13 07:06:02'),
(5, 2, 1, 'text', 'What documentary stayed with you after the credits?', NULL, 'read', '2026-08-11 20:40:33', '2026-08-11 20:40:33', NULL, '2026-08-11 16:50:36', '2026-08-11 18:50:36'),
(6, 2, 6, 'text', 'The one I am editing now, because I still do not know its ending.', NULL, 'read', '2026-08-11 20:30:33', '2026-08-11 20:30:33', NULL, '2026-08-11 17:10:36', '2026-08-11 18:50:36'),
(7, 2, 1, 'text', 'That answer has definitely earned a longer conversation.', NULL, 'read', '2026-08-11 20:40:33', '2026-08-11 20:40:33', NULL, '2026-08-11 17:30:36', '2026-08-11 18:50:36'),
(8, 2, 6, 'text', 'Coffee this weekend? I can tell you the non-spoiler version.', NULL, 'read', '2026-08-11 20:30:33', '2026-08-11 20:30:33', NULL, '2026-08-11 17:50:36', '2026-08-11 18:50:36'),
(9, 2, 1, 'text', 'Saturday afternoon works for me.', NULL, 'read', '2026-08-11 20:40:33', '2026-08-11 20:40:33', NULL, '2026-08-11 18:10:36', '2026-08-11 18:50:36'),
(10, 2, 6, 'text', 'Perfect. I will send the café location tomorrow.', NULL, 'read', '2026-08-11 22:27:19', '2026-08-11 22:27:19', NULL, '2026-08-11 18:30:36', '2026-08-11 22:27:19'),
(32, 15, 3, 'text', 'Hello', NULL, 'read', '2026-08-13 07:08:33', '2026-08-13 07:08:33', NULL, '2026-08-13 07:07:56', '2026-08-13 07:08:33'),
(33, 15, 3, 'text', '😄', NULL, 'read', '2026-08-13 07:08:33', '2026-08-13 07:08:33', NULL, '2026-08-13 07:08:03', '2026-08-13 07:08:33'),
(34, 15, 85, 'text', 'Hyy', NULL, 'sent', NULL, NULL, NULL, '2026-08-13 07:08:37', '2026-08-13 07:08:37'),
(37, 15, 85, 'text', 'Hello', NULL, 'sent', NULL, NULL, NULL, '2026-08-17 08:03:07', '2026-08-17 08:03:07'),
(3748, 301, 1454, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'delivered', '2026-08-27 12:18:00', NULL, NULL, '2026-08-27 12:18:00', '2026-08-27 12:18:00'),
(3749, 302, 1454, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-26 12:18:00', '2026-08-26 12:23:00', NULL, '2026-08-26 12:18:00', '2026-08-26 12:18:00'),
(3750, 302, 1475, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-26 12:36:00', '2026-08-26 12:41:00', NULL, '2026-08-26 12:36:00', '2026-08-26 12:36:00'),
(3751, 302, 1454, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-26 12:54:00', '2026-08-26 12:59:00', NULL, '2026-08-26 12:54:00', '2026-08-26 12:54:00'),
(3752, 302, 1475, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-26 13:12:00', '2026-08-26 13:17:00', NULL, '2026-08-26 13:12:00', '2026-08-26 13:12:00'),
(3753, 302, 1454, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'delivered', '2026-08-26 13:30:00', NULL, NULL, '2026-08-26 13:30:00', '2026-08-26 13:30:00'),
(3754, 302, 1475, 'text', 'I would absolutely join that heritage walk.', NULL, 'delivered', '2026-08-26 13:48:00', NULL, NULL, '2026-08-26 13:48:00', '2026-08-26 13:48:00'),
(3755, 303, 1454, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-24 12:18:00', '2026-08-24 12:23:00', NULL, '2026-08-24 12:18:00', '2026-08-24 12:18:00'),
(3756, 303, 1489, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-24 12:36:00', '2026-08-24 12:41:00', NULL, '2026-08-24 12:36:00', '2026-08-24 12:36:00'),
(3757, 303, 1454, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-24 12:54:00', '2026-08-24 12:59:00', NULL, '2026-08-24 12:54:00', '2026-08-24 12:54:00'),
(3758, 303, 1489, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-24 13:12:00', '2026-08-24 13:17:00', NULL, '2026-08-24 13:12:00', '2026-08-24 13:12:00'),
(3759, 303, 1454, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-24 13:30:00', '2026-08-24 13:35:00', NULL, '2026-08-24 13:30:00', '2026-08-24 13:30:00'),
(3760, 303, 1489, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-24 13:48:00', '2026-08-24 13:53:00', NULL, '2026-08-24 13:48:00', '2026-08-24 13:48:00'),
(3761, 303, 1454, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-24 14:06:00', '2026-08-24 14:11:00', NULL, '2026-08-24 14:06:00', '2026-08-24 14:06:00'),
(3762, 303, 1489, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-24 14:24:00', '2026-08-24 14:29:00', NULL, '2026-08-24 14:24:00', '2026-08-24 14:24:00'),
(3763, 303, 1454, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-24 14:42:00', '2026-08-24 14:47:00', NULL, '2026-08-24 14:42:00', '2026-08-24 14:42:00'),
(3764, 303, 1489, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-24 15:00:00', '2026-08-24 15:05:00', NULL, '2026-08-24 15:00:00', '2026-08-24 15:00:00'),
(3765, 303, 1454, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-24 15:18:00', '2026-08-24 15:23:00', NULL, '2026-08-24 15:18:00', '2026-08-24 15:18:00'),
(3766, 303, 1489, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-24 15:36:00', '2026-08-24 15:41:00', NULL, '2026-08-24 15:36:00', '2026-08-24 15:36:00'),
(3767, 303, 1454, 'text', 'How\'s your weekend going?', NULL, 'delivered', '2026-08-24 15:54:00', NULL, NULL, '2026-08-24 15:54:00', '2026-08-24 15:54:00'),
(3768, 303, 1489, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'delivered', '2026-08-24 16:12:00', NULL, NULL, '2026-08-24 16:12:00', '2026-08-24 16:12:00'),
(3769, 303, 1454, 'text', 'What is the best book you have read this year?', NULL, 'delivered', '2026-08-24 16:30:00', NULL, NULL, '2026-08-24 16:30:00', '2026-08-24 16:30:00'),
(3770, 304, 1454, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-23 12:18:00', '2026-08-23 12:23:00', NULL, '2026-08-23 12:18:00', '2026-08-23 12:18:00'),
(3771, 304, 1496, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-23 12:36:00', '2026-08-23 12:41:00', NULL, '2026-08-23 12:36:00', '2026-08-23 12:36:00'),
(3772, 304, 1454, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-23 12:54:00', '2026-08-23 12:59:00', NULL, '2026-08-23 12:54:00', '2026-08-23 12:54:00'),
(3773, 304, 1496, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-23 13:12:00', '2026-08-23 13:17:00', NULL, '2026-08-23 13:12:00', '2026-08-23 13:12:00'),
(3774, 304, 1454, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-23 13:30:00', '2026-08-23 13:35:00', NULL, '2026-08-23 13:30:00', '2026-08-23 13:30:00'),
(3775, 304, 1496, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-23 13:48:00', '2026-08-23 13:53:00', NULL, '2026-08-23 13:48:00', '2026-08-23 13:48:00'),
(3776, 304, 1454, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-23 14:06:00', '2026-08-23 14:11:00', NULL, '2026-08-23 14:06:00', '2026-08-23 14:06:00'),
(3777, 304, 1496, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-23 14:24:00', '2026-08-23 14:29:00', NULL, '2026-08-23 14:24:00', '2026-08-23 14:24:00'),
(3778, 304, 1454, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-23 14:42:00', '2026-08-23 14:47:00', NULL, '2026-08-23 14:42:00', '2026-08-23 14:42:00'),
(3779, 304, 1496, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-23 15:00:00', '2026-08-23 15:05:00', NULL, '2026-08-23 15:00:00', '2026-08-23 15:00:00'),
(3780, 304, 1454, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-23 15:18:00', '2026-08-23 15:23:00', NULL, '2026-08-23 15:18:00', '2026-08-23 15:18:00'),
(3781, 304, 1496, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-23 15:36:00', '2026-08-23 15:41:00', NULL, '2026-08-23 15:36:00', '2026-08-23 15:36:00'),
(3782, 304, 1454, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-23 15:54:00', '2026-08-23 15:59:00', NULL, '2026-08-23 15:54:00', '2026-08-23 15:54:00'),
(3783, 304, 1496, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-23 16:12:00', '2026-08-23 16:17:00', NULL, '2026-08-23 16:12:00', '2026-08-23 16:12:00'),
(3784, 304, 1454, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-23 16:30:00', '2026-08-23 16:35:00', NULL, '2026-08-23 16:30:00', '2026-08-23 16:30:00'),
(3785, 304, 1496, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-23 16:48:00', '2026-08-23 16:53:00', NULL, '2026-08-23 16:48:00', '2026-08-23 16:48:00'),
(3786, 305, 1454, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-21 12:18:00', '2026-08-21 12:23:00', NULL, '2026-08-21 12:18:00', '2026-08-21 12:18:00'),
(3787, 305, 1510, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-21 12:36:00', '2026-08-21 12:41:00', NULL, '2026-08-21 12:36:00', '2026-08-21 12:36:00'),
(3788, 305, 1454, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-21 12:54:00', '2026-08-21 12:59:00', NULL, '2026-08-21 12:54:00', '2026-08-21 12:54:00'),
(3789, 305, 1510, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-21 13:12:00', '2026-08-21 13:17:00', NULL, '2026-08-21 13:12:00', '2026-08-21 13:12:00'),
(3790, 305, 1454, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-21 13:30:00', '2026-08-21 13:35:00', NULL, '2026-08-21 13:30:00', '2026-08-21 13:30:00'),
(3791, 305, 1510, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-21 13:48:00', '2026-08-21 13:53:00', NULL, '2026-08-21 13:48:00', '2026-08-21 13:48:00'),
(3792, 305, 1454, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-21 14:06:00', '2026-08-21 14:11:00', NULL, '2026-08-21 14:06:00', '2026-08-21 14:06:00'),
(3793, 305, 1510, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-21 14:24:00', '2026-08-21 14:29:00', NULL, '2026-08-21 14:24:00', '2026-08-21 14:24:00'),
(3794, 305, 1454, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-21 14:42:00', '2026-08-21 14:47:00', NULL, '2026-08-21 14:42:00', '2026-08-21 14:42:00'),
(3795, 305, 1510, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-21 15:00:00', '2026-08-21 15:05:00', NULL, '2026-08-21 15:00:00', '2026-08-21 15:00:00'),
(3796, 305, 1454, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-21 15:18:00', '2026-08-21 15:23:00', NULL, '2026-08-21 15:18:00', '2026-08-21 15:18:00'),
(3797, 305, 1510, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-21 15:36:00', '2026-08-21 15:41:00', NULL, '2026-08-21 15:36:00', '2026-08-21 15:36:00'),
(3798, 305, 1454, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-21 15:54:00', '2026-08-21 15:59:00', NULL, '2026-08-21 15:54:00', '2026-08-21 15:54:00'),
(3799, 305, 1510, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-21 16:12:00', '2026-08-21 16:17:00', NULL, '2026-08-21 16:12:00', '2026-08-21 16:12:00'),
(3800, 305, 1454, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-21 16:30:00', '2026-08-21 16:35:00', NULL, '2026-08-21 16:30:00', '2026-08-21 16:30:00'),
(3801, 305, 1510, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-21 16:48:00', '2026-08-21 16:53:00', NULL, '2026-08-21 16:48:00', '2026-08-21 16:48:00'),
(3802, 305, 1454, 'text', 'That made me laugh. I needed that today.', NULL, 'delivered', '2026-08-21 17:06:00', NULL, NULL, '2026-08-21 17:06:00', '2026-08-21 17:06:00'),
(3803, 306, 1454, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-15 12:18:00', '2026-08-15 12:23:00', NULL, '2026-08-15 12:18:00', '2026-08-15 12:18:00'),
(3804, 306, 1456, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-15 12:36:00', '2026-08-15 12:41:00', NULL, '2026-08-15 12:36:00', '2026-08-15 12:36:00'),
(3805, 306, 1454, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-15 12:54:00', '2026-08-15 12:59:00', NULL, '2026-08-15 12:54:00', '2026-08-15 12:54:00'),
(3806, 306, 1456, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-15 13:12:00', '2026-08-15 13:17:00', NULL, '2026-08-15 13:12:00', '2026-08-15 13:12:00'),
(3807, 306, 1454, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-15 13:30:00', '2026-08-15 13:35:00', NULL, '2026-08-15 13:30:00', '2026-08-15 13:30:00'),
(3808, 306, 1456, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-15 13:48:00', '2026-08-15 13:53:00', NULL, '2026-08-15 13:48:00', '2026-08-15 13:48:00'),
(3809, 306, 1454, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-15 14:06:00', '2026-08-15 14:11:00', NULL, '2026-08-15 14:06:00', '2026-08-15 14:06:00'),
(3810, 306, 1456, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-15 14:24:00', '2026-08-15 14:29:00', NULL, '2026-08-15 14:24:00', '2026-08-15 14:24:00'),
(3811, 306, 1454, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-15 14:42:00', '2026-08-15 14:47:00', NULL, '2026-08-15 14:42:00', '2026-08-15 14:42:00'),
(3812, 306, 1456, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-15 15:00:00', '2026-08-15 15:05:00', NULL, '2026-08-15 15:00:00', '2026-08-15 15:00:00'),
(3813, 306, 1454, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-15 15:18:00', '2026-08-15 15:23:00', NULL, '2026-08-15 15:18:00', '2026-08-15 15:18:00'),
(3814, 306, 1456, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-15 15:36:00', '2026-08-15 15:41:00', NULL, '2026-08-15 15:36:00', '2026-08-15 15:36:00'),
(3815, 306, 1454, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-15 15:54:00', '2026-08-15 15:59:00', NULL, '2026-08-15 15:54:00', '2026-08-15 15:54:00'),
(3816, 306, 1456, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-15 16:12:00', '2026-08-15 16:17:00', NULL, '2026-08-15 16:12:00', '2026-08-15 16:12:00'),
(3817, 306, 1454, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-15 16:30:00', '2026-08-15 16:35:00', NULL, '2026-08-15 16:30:00', '2026-08-15 16:30:00'),
(3818, 306, 1456, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-15 16:48:00', '2026-08-15 16:53:00', NULL, '2026-08-15 16:48:00', '2026-08-15 16:48:00'),
(3819, 306, 1454, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-15 17:06:00', '2026-08-15 17:11:00', NULL, '2026-08-15 17:06:00', '2026-08-15 17:06:00'),
(3820, 306, 1456, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-15 17:24:00', '2026-08-15 17:29:00', NULL, '2026-08-15 17:24:00', '2026-08-15 17:24:00'),
(3821, 306, 1454, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-15 17:42:00', '2026-08-15 17:47:00', NULL, '2026-08-15 17:42:00', '2026-08-15 17:42:00'),
(3822, 306, 1456, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-15 18:00:00', '2026-08-15 18:05:00', NULL, '2026-08-15 18:00:00', '2026-08-15 18:00:00'),
(3823, 306, 1454, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-15 18:18:00', '2026-08-15 18:23:00', NULL, '2026-08-15 18:18:00', '2026-08-15 18:18:00'),
(3824, 306, 1456, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-15 18:36:00', '2026-08-15 18:41:00', NULL, '2026-08-15 18:36:00', '2026-08-15 18:36:00'),
(3825, 306, 1454, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-15 18:54:00', '2026-08-15 18:59:00', NULL, '2026-08-15 18:54:00', '2026-08-15 18:54:00'),
(3826, 306, 1456, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-15 19:12:00', '2026-08-15 19:17:00', NULL, '2026-08-15 19:12:00', '2026-08-15 19:12:00'),
(3827, 306, 1454, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-15 19:30:00', '2026-08-15 19:35:00', NULL, '2026-08-15 19:30:00', '2026-08-15 19:30:00'),
(3828, 306, 1456, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-15 19:48:00', '2026-08-15 19:53:00', NULL, '2026-08-15 19:48:00', '2026-08-15 19:48:00'),
(3829, 306, 1454, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-15 20:06:00', '2026-08-15 20:11:00', NULL, '2026-08-15 20:06:00', '2026-08-15 20:06:00'),
(3830, 306, 1456, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-15 20:24:00', '2026-08-15 20:29:00', NULL, '2026-08-15 20:24:00', '2026-08-15 20:24:00'),
(3831, 306, 1454, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-15 20:42:00', '2026-08-15 20:47:00', NULL, '2026-08-15 20:42:00', '2026-08-15 20:42:00'),
(3832, 306, 1456, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-15 21:00:00', '2026-08-15 21:05:00', NULL, '2026-08-15 21:00:00', '2026-08-15 21:00:00'),
(3833, 306, 1454, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-15 21:18:00', '2026-08-15 21:23:00', NULL, '2026-08-15 21:18:00', '2026-08-15 21:18:00'),
(3834, 306, 1456, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-15 21:36:00', '2026-08-15 21:41:00', NULL, '2026-08-15 21:36:00', '2026-08-15 21:36:00'),
(3835, 306, 1454, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-15 21:54:00', '2026-08-15 21:59:00', NULL, '2026-08-15 21:54:00', '2026-08-15 21:54:00'),
(3836, 306, 1456, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-15 22:12:00', '2026-08-15 22:17:00', NULL, '2026-08-15 22:12:00', '2026-08-15 22:12:00'),
(3837, 306, 1454, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-15 22:30:00', '2026-08-15 22:35:00', NULL, '2026-08-15 22:30:00', '2026-08-15 22:30:00'),
(3838, 306, 1456, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-15 22:48:00', '2026-08-15 22:53:00', NULL, '2026-08-15 22:48:00', '2026-08-15 22:48:00'),
(3839, 306, 1454, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-15 23:06:00', '2026-08-15 23:11:00', NULL, '2026-08-15 23:06:00', '2026-08-15 23:06:00'),
(3840, 306, 1456, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-15 23:24:00', '2026-08-15 23:29:00', NULL, '2026-08-15 23:24:00', '2026-08-15 23:24:00'),
(3841, 306, 1454, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-15 23:42:00', '2026-08-15 23:47:00', NULL, '2026-08-15 23:42:00', '2026-08-15 23:42:00'),
(3842, 306, 1456, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-16 00:00:00', '2026-08-16 00:05:00', NULL, '2026-08-16 00:00:00', '2026-08-16 00:00:00'),
(3843, 306, 1454, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-16 00:18:00', '2026-08-16 00:23:00', NULL, '2026-08-16 00:18:00', '2026-08-16 00:18:00'),
(3844, 306, 1456, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-16 00:36:00', '2026-08-16 00:41:00', NULL, '2026-08-16 00:36:00', '2026-08-16 00:36:00'),
(3845, 306, 1454, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-16 00:54:00', '2026-08-16 00:59:00', NULL, '2026-08-16 00:54:00', '2026-08-16 00:54:00'),
(3846, 306, 1456, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-16 01:12:00', '2026-08-16 01:17:00', NULL, '2026-08-16 01:12:00', '2026-08-16 01:12:00'),
(3847, 306, 1454, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-16 01:30:00', '2026-08-16 01:35:00', NULL, '2026-08-16 01:30:00', '2026-08-16 01:30:00'),
(3848, 306, 1456, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-16 01:48:00', '2026-08-16 01:53:00', NULL, '2026-08-16 01:48:00', '2026-08-16 01:48:00'),
(3849, 306, 1454, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-16 02:06:00', '2026-08-16 02:11:00', NULL, '2026-08-16 02:06:00', '2026-08-16 02:06:00'),
(3850, 306, 1456, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-16 02:24:00', '2026-08-16 02:29:00', NULL, '2026-08-16 02:24:00', '2026-08-16 02:24:00'),
(3851, 306, 1454, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-16 02:42:00', '2026-08-16 02:47:00', NULL, '2026-08-16 02:42:00', '2026-08-16 02:42:00'),
(3852, 306, 1456, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-16 03:00:00', '2026-08-16 03:05:00', NULL, '2026-08-16 03:00:00', '2026-08-16 03:00:00'),
(3853, 306, 1454, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-16 03:18:00', '2026-08-16 03:23:00', NULL, '2026-08-16 03:18:00', '2026-08-16 03:18:00'),
(3854, 306, 1456, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-16 03:36:00', '2026-08-16 03:41:00', NULL, '2026-08-16 03:36:00', '2026-08-16 03:36:00'),
(3855, 306, 1454, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-16 03:54:00', '2026-08-16 03:59:00', NULL, '2026-08-16 03:54:00', '2026-08-16 03:54:00'),
(3856, 306, 1456, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'delivered', '2026-08-16 04:12:00', NULL, NULL, '2026-08-16 04:12:00', '2026-08-16 04:12:00'),
(3857, 306, 1454, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'delivered', '2026-08-16 04:30:00', NULL, NULL, '2026-08-16 04:30:00', '2026-08-16 04:30:00'),
(3858, 308, 1463, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-20 12:18:00', '2026-08-20 12:23:00', NULL, '2026-08-20 12:18:00', '2026-08-20 12:18:00'),
(3859, 309, 1469, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-14 12:18:00', '2026-08-14 12:23:00', NULL, '2026-08-14 12:18:00', '2026-08-14 12:18:00'),
(3860, 309, 1470, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-14 12:36:00', '2026-08-14 12:41:00', NULL, '2026-08-14 12:36:00', '2026-08-14 12:36:00'),
(3861, 309, 1469, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-14 12:54:00', '2026-08-14 12:59:00', NULL, '2026-08-14 12:54:00', '2026-08-14 12:54:00'),
(3862, 309, 1470, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-14 13:12:00', '2026-08-14 13:17:00', NULL, '2026-08-14 13:12:00', '2026-08-14 13:12:00'),
(3863, 309, 1469, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-14 13:30:00', '2026-08-14 13:35:00', NULL, '2026-08-14 13:30:00', '2026-08-14 13:30:00'),
(3864, 309, 1470, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'delivered', '2026-08-14 13:48:00', NULL, NULL, '2026-08-14 13:48:00', '2026-08-14 13:48:00'),
(3865, 310, 1475, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-08 12:18:00', '2026-08-08 12:23:00', NULL, '2026-08-08 12:18:00', '2026-08-08 12:18:00'),
(3866, 310, 1476, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-08 12:36:00', '2026-08-08 12:41:00', NULL, '2026-08-08 12:36:00', '2026-08-08 12:36:00'),
(3867, 310, 1475, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-08 12:54:00', '2026-08-08 12:59:00', NULL, '2026-08-08 12:54:00', '2026-08-08 12:54:00'),
(3868, 310, 1476, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-08 13:12:00', '2026-08-08 13:17:00', NULL, '2026-08-08 13:12:00', '2026-08-08 13:12:00'),
(3869, 310, 1475, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-08 13:30:00', '2026-08-08 13:35:00', NULL, '2026-08-08 13:30:00', '2026-08-08 13:30:00'),
(3870, 310, 1476, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-08 13:48:00', '2026-08-08 13:53:00', NULL, '2026-08-08 13:48:00', '2026-08-08 13:48:00'),
(3871, 310, 1475, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-08 14:06:00', '2026-08-08 14:11:00', NULL, '2026-08-08 14:06:00', '2026-08-08 14:06:00'),
(3872, 310, 1476, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-08 14:24:00', '2026-08-08 14:29:00', NULL, '2026-08-08 14:24:00', '2026-08-08 14:24:00'),
(3873, 310, 1475, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-08 14:42:00', '2026-08-08 14:47:00', NULL, '2026-08-08 14:42:00', '2026-08-08 14:42:00'),
(3874, 310, 1476, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-08 15:00:00', '2026-08-08 15:05:00', NULL, '2026-08-08 15:00:00', '2026-08-08 15:00:00'),
(3875, 310, 1475, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-08 15:18:00', '2026-08-08 15:23:00', NULL, '2026-08-08 15:18:00', '2026-08-08 15:18:00'),
(3876, 310, 1476, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-08 15:36:00', '2026-08-08 15:41:00', NULL, '2026-08-08 15:36:00', '2026-08-08 15:36:00'),
(3877, 310, 1475, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-08 15:54:00', '2026-08-08 15:59:00', NULL, '2026-08-08 15:54:00', '2026-08-08 15:54:00'),
(3878, 310, 1476, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-08 16:12:00', '2026-08-08 16:17:00', NULL, '2026-08-08 16:12:00', '2026-08-08 16:12:00'),
(3879, 310, 1475, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-08 16:30:00', '2026-08-08 16:35:00', NULL, '2026-08-08 16:30:00', '2026-08-08 16:30:00'),
(3880, 310, 1476, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-08 16:48:00', '2026-08-08 16:53:00', NULL, '2026-08-08 16:48:00', '2026-08-08 16:48:00'),
(3881, 310, 1475, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-08 17:06:00', '2026-08-08 17:11:00', NULL, '2026-08-08 17:06:00', '2026-08-08 17:06:00'),
(3882, 310, 1476, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-08 17:24:00', '2026-08-08 17:29:00', NULL, '2026-08-08 17:24:00', '2026-08-08 17:24:00'),
(3883, 310, 1475, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-08 17:42:00', '2026-08-08 17:47:00', NULL, '2026-08-08 17:42:00', '2026-08-08 17:42:00'),
(3884, 310, 1476, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-08 18:00:00', '2026-08-08 18:05:00', NULL, '2026-08-08 18:00:00', '2026-08-08 18:00:00'),
(3885, 310, 1475, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'delivered', '2026-08-08 18:18:00', NULL, NULL, '2026-08-08 18:18:00', '2026-08-08 18:18:00'),
(3886, 310, 1476, 'text', 'I would absolutely join that heritage walk.', NULL, 'delivered', '2026-08-08 18:36:00', NULL, NULL, '2026-08-08 18:36:00', '2026-08-08 18:36:00'),
(3887, 311, 1481, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-02 12:18:00', '2026-08-02 12:23:00', NULL, '2026-08-02 12:18:00', '2026-08-02 12:18:00'),
(3888, 311, 1482, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-02 12:36:00', '2026-08-02 12:41:00', NULL, '2026-08-02 12:36:00', '2026-08-02 12:36:00'),
(3889, 311, 1481, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-02 12:54:00', '2026-08-02 12:59:00', NULL, '2026-08-02 12:54:00', '2026-08-02 12:54:00'),
(3890, 311, 1482, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-02 13:12:00', '2026-08-02 13:17:00', NULL, '2026-08-02 13:12:00', '2026-08-02 13:12:00'),
(3891, 311, 1481, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-02 13:30:00', '2026-08-02 13:35:00', NULL, '2026-08-02 13:30:00', '2026-08-02 13:30:00'),
(3892, 311, 1482, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-02 13:48:00', '2026-08-02 13:53:00', NULL, '2026-08-02 13:48:00', '2026-08-02 13:48:00'),
(3893, 311, 1481, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-02 14:06:00', '2026-08-02 14:11:00', NULL, '2026-08-02 14:06:00', '2026-08-02 14:06:00'),
(3894, 311, 1482, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-02 14:24:00', '2026-08-02 14:29:00', NULL, '2026-08-02 14:24:00', '2026-08-02 14:24:00'),
(3895, 311, 1481, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-02 14:42:00', '2026-08-02 14:47:00', NULL, '2026-08-02 14:42:00', '2026-08-02 14:42:00'),
(3896, 311, 1482, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-02 15:00:00', '2026-08-02 15:05:00', NULL, '2026-08-02 15:00:00', '2026-08-02 15:00:00'),
(3897, 311, 1481, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-02 15:18:00', '2026-08-02 15:23:00', NULL, '2026-08-02 15:18:00', '2026-08-02 15:18:00'),
(3898, 311, 1482, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-02 15:36:00', '2026-08-02 15:41:00', NULL, '2026-08-02 15:36:00', '2026-08-02 15:36:00'),
(3899, 311, 1481, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-02 15:54:00', '2026-08-02 15:59:00', NULL, '2026-08-02 15:54:00', '2026-08-02 15:54:00'),
(3900, 311, 1482, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-02 16:12:00', '2026-08-02 16:17:00', NULL, '2026-08-02 16:12:00', '2026-08-02 16:12:00'),
(3901, 311, 1481, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-02 16:30:00', '2026-08-02 16:35:00', NULL, '2026-08-02 16:30:00', '2026-08-02 16:30:00'),
(3902, 311, 1482, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-02 16:48:00', '2026-08-02 16:53:00', NULL, '2026-08-02 16:48:00', '2026-08-02 16:48:00'),
(3903, 311, 1481, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-02 17:06:00', '2026-08-02 17:11:00', NULL, '2026-08-02 17:06:00', '2026-08-02 17:06:00'),
(3904, 311, 1482, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-02 17:24:00', '2026-08-02 17:29:00', NULL, '2026-08-02 17:24:00', '2026-08-02 17:24:00'),
(3905, 311, 1481, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-02 17:42:00', '2026-08-02 17:47:00', NULL, '2026-08-02 17:42:00', '2026-08-02 17:42:00'),
(3906, 311, 1482, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-02 18:00:00', '2026-08-02 18:05:00', NULL, '2026-08-02 18:00:00', '2026-08-02 18:00:00'),
(3907, 311, 1481, 'text', 'I would absolutely join that heritage walk.', NULL, 'delivered', '2026-08-02 18:18:00', NULL, NULL, '2026-08-02 18:18:00', '2026-08-02 18:18:00'),
(3908, 311, 1482, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'delivered', '2026-08-02 18:36:00', NULL, NULL, '2026-08-02 18:36:00', '2026-08-02 18:36:00'),
(3909, 311, 1481, 'text', 'That made me laugh. I needed that today.', NULL, 'delivered', '2026-08-02 18:54:00', NULL, NULL, '2026-08-02 18:54:00', '2026-08-02 18:54:00'),
(3910, 312, 1487, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-07-27 12:18:00', '2026-07-27 12:23:00', NULL, '2026-07-27 12:18:00', '2026-07-27 12:18:00'),
(3911, 312, 1488, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-07-27 12:36:00', '2026-07-27 12:41:00', NULL, '2026-07-27 12:36:00', '2026-07-27 12:36:00'),
(3912, 312, 1487, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-07-27 12:54:00', '2026-07-27 12:59:00', NULL, '2026-07-27 12:54:00', '2026-07-27 12:54:00'),
(3913, 312, 1488, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-07-27 13:12:00', '2026-07-27 13:17:00', NULL, '2026-07-27 13:12:00', '2026-07-27 13:12:00'),
(3914, 312, 1487, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-07-27 13:30:00', '2026-07-27 13:35:00', NULL, '2026-07-27 13:30:00', '2026-07-27 13:30:00'),
(3915, 312, 1488, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-07-27 13:48:00', '2026-07-27 13:53:00', NULL, '2026-07-27 13:48:00', '2026-07-27 13:48:00'),
(3916, 312, 1487, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-07-27 14:06:00', '2026-07-27 14:11:00', NULL, '2026-07-27 14:06:00', '2026-07-27 14:06:00'),
(3917, 312, 1488, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-07-27 14:24:00', '2026-07-27 14:29:00', NULL, '2026-07-27 14:24:00', '2026-07-27 14:24:00'),
(3918, 312, 1487, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-07-27 14:42:00', '2026-07-27 14:47:00', NULL, '2026-07-27 14:42:00', '2026-07-27 14:42:00'),
(3919, 312, 1488, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-07-27 15:00:00', '2026-07-27 15:05:00', NULL, '2026-07-27 15:00:00', '2026-07-27 15:00:00'),
(3920, 312, 1487, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-07-27 15:18:00', '2026-07-27 15:23:00', NULL, '2026-07-27 15:18:00', '2026-07-27 15:18:00'),
(3921, 312, 1488, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-07-27 15:36:00', '2026-07-27 15:41:00', NULL, '2026-07-27 15:36:00', '2026-07-27 15:36:00'),
(3922, 312, 1487, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-07-27 15:54:00', '2026-07-27 15:59:00', NULL, '2026-07-27 15:54:00', '2026-07-27 15:54:00'),
(3923, 312, 1488, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-07-27 16:12:00', '2026-07-27 16:17:00', NULL, '2026-07-27 16:12:00', '2026-07-27 16:12:00'),
(3924, 312, 1487, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-07-27 16:30:00', '2026-07-27 16:35:00', NULL, '2026-07-27 16:30:00', '2026-07-27 16:30:00'),
(3925, 312, 1488, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-07-27 16:48:00', '2026-07-27 16:53:00', NULL, '2026-07-27 16:48:00', '2026-07-27 16:48:00'),
(3926, 312, 1487, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-07-27 17:06:00', '2026-07-27 17:11:00', NULL, '2026-07-27 17:06:00', '2026-07-27 17:06:00'),
(3927, 312, 1488, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-07-27 17:24:00', '2026-07-27 17:29:00', NULL, '2026-07-27 17:24:00', '2026-07-27 17:24:00'),
(3928, 312, 1487, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-07-27 17:42:00', '2026-07-27 17:47:00', NULL, '2026-07-27 17:42:00', '2026-07-27 17:42:00'),
(3929, 312, 1488, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-07-27 18:00:00', '2026-07-27 18:05:00', NULL, '2026-07-27 18:00:00', '2026-07-27 18:00:00'),
(3930, 312, 1487, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-07-27 18:18:00', '2026-07-27 18:23:00', NULL, '2026-07-27 18:18:00', '2026-07-27 18:18:00'),
(3931, 312, 1488, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-07-27 18:36:00', '2026-07-27 18:41:00', NULL, '2026-07-27 18:36:00', '2026-07-27 18:36:00'),
(3932, 312, 1487, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-07-27 18:54:00', '2026-07-27 18:59:00', NULL, '2026-07-27 18:54:00', '2026-07-27 18:54:00'),
(3933, 312, 1488, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-07-27 19:12:00', '2026-07-27 19:17:00', NULL, '2026-07-27 19:12:00', '2026-07-27 19:12:00'),
(3934, 313, 1493, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-07-21 12:18:00', '2026-07-21 12:23:00', NULL, '2026-07-21 12:18:00', '2026-07-21 12:18:00'),
(3935, 313, 1494, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-07-21 12:36:00', '2026-07-21 12:41:00', NULL, '2026-07-21 12:36:00', '2026-07-21 12:36:00'),
(3936, 313, 1493, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-07-21 12:54:00', '2026-07-21 12:59:00', NULL, '2026-07-21 12:54:00', '2026-07-21 12:54:00'),
(3937, 313, 1494, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-07-21 13:12:00', '2026-07-21 13:17:00', NULL, '2026-07-21 13:12:00', '2026-07-21 13:12:00'),
(3938, 313, 1493, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-07-21 13:30:00', '2026-07-21 13:35:00', NULL, '2026-07-21 13:30:00', '2026-07-21 13:30:00'),
(3939, 313, 1494, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-07-21 13:48:00', '2026-07-21 13:53:00', NULL, '2026-07-21 13:48:00', '2026-07-21 13:48:00'),
(3940, 313, 1493, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-07-21 14:06:00', '2026-07-21 14:11:00', NULL, '2026-07-21 14:06:00', '2026-07-21 14:06:00'),
(3941, 313, 1494, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-07-21 14:24:00', '2026-07-21 14:29:00', NULL, '2026-07-21 14:24:00', '2026-07-21 14:24:00'),
(3942, 313, 1493, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-07-21 14:42:00', '2026-07-21 14:47:00', NULL, '2026-07-21 14:42:00', '2026-07-21 14:42:00'),
(3943, 313, 1494, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-07-21 15:00:00', '2026-07-21 15:05:00', NULL, '2026-07-21 15:00:00', '2026-07-21 15:00:00'),
(3944, 313, 1493, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-07-21 15:18:00', '2026-07-21 15:23:00', NULL, '2026-07-21 15:18:00', '2026-07-21 15:18:00'),
(3945, 313, 1494, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-07-21 15:36:00', '2026-07-21 15:41:00', NULL, '2026-07-21 15:36:00', '2026-07-21 15:36:00'),
(3946, 313, 1493, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-07-21 15:54:00', '2026-07-21 15:59:00', NULL, '2026-07-21 15:54:00', '2026-07-21 15:54:00'),
(3947, 313, 1494, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-07-21 16:12:00', '2026-07-21 16:17:00', NULL, '2026-07-21 16:12:00', '2026-07-21 16:12:00'),
(3948, 313, 1493, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-07-21 16:30:00', '2026-07-21 16:35:00', NULL, '2026-07-21 16:30:00', '2026-07-21 16:30:00'),
(3949, 313, 1494, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-07-21 16:48:00', '2026-07-21 16:53:00', NULL, '2026-07-21 16:48:00', '2026-07-21 16:48:00'),
(3950, 313, 1493, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-07-21 17:06:00', '2026-07-21 17:11:00', NULL, '2026-07-21 17:06:00', '2026-07-21 17:06:00'),
(3951, 313, 1494, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-07-21 17:24:00', '2026-07-21 17:29:00', NULL, '2026-07-21 17:24:00', '2026-07-21 17:24:00'),
(3952, 313, 1493, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-07-21 17:42:00', '2026-07-21 17:47:00', NULL, '2026-07-21 17:42:00', '2026-07-21 17:42:00'),
(3953, 313, 1494, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-07-21 18:00:00', '2026-07-21 18:05:00', NULL, '2026-07-21 18:00:00', '2026-07-21 18:00:00'),
(3954, 313, 1493, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-07-21 18:18:00', '2026-07-21 18:23:00', NULL, '2026-07-21 18:18:00', '2026-07-21 18:18:00'),
(3955, 313, 1494, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-07-21 18:36:00', '2026-07-21 18:41:00', NULL, '2026-07-21 18:36:00', '2026-07-21 18:36:00'),
(3956, 313, 1493, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-07-21 18:54:00', '2026-07-21 18:59:00', NULL, '2026-07-21 18:54:00', '2026-07-21 18:54:00'),
(3957, 313, 1494, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-07-21 19:12:00', '2026-07-21 19:17:00', NULL, '2026-07-21 19:12:00', '2026-07-21 19:12:00'),
(3958, 313, 1493, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'delivered', '2026-07-21 19:30:00', NULL, NULL, '2026-07-21 19:30:00', '2026-07-21 19:30:00'),
(3959, 315, 1505, 'text', 'How\'s your weekend going?', NULL, 'delivered', '2026-07-09 12:18:00', NULL, NULL, '2026-07-09 12:18:00', '2026-07-09 12:18:00'),
(3960, 316, 1511, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-07-03 12:18:00', '2026-07-03 12:23:00', NULL, '2026-07-03 12:18:00', '2026-07-03 12:18:00'),
(3961, 316, 1512, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-07-03 12:36:00', '2026-07-03 12:41:00', NULL, '2026-07-03 12:36:00', '2026-07-03 12:36:00'),
(3962, 316, 1511, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-07-03 12:54:00', '2026-07-03 12:59:00', NULL, '2026-07-03 12:54:00', '2026-07-03 12:54:00'),
(3963, 316, 1512, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-07-03 13:12:00', '2026-07-03 13:17:00', NULL, '2026-07-03 13:12:00', '2026-07-03 13:12:00'),
(3964, 316, 1511, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-07-03 13:30:00', '2026-07-03 13:35:00', NULL, '2026-07-03 13:30:00', '2026-07-03 13:30:00'),
(3965, 316, 1512, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-07-03 13:48:00', '2026-07-03 13:53:00', NULL, '2026-07-03 13:48:00', '2026-07-03 13:48:00'),
(3966, 317, 1517, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-06-27 12:18:00', '2026-06-27 12:23:00', NULL, '2026-06-27 12:18:00', '2026-06-27 12:18:00'),
(3967, 317, 1518, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-06-27 12:36:00', '2026-06-27 12:41:00', NULL, '2026-06-27 12:36:00', '2026-06-27 12:36:00'),
(3968, 317, 1517, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-06-27 12:54:00', '2026-06-27 12:59:00', NULL, '2026-06-27 12:54:00', '2026-06-27 12:54:00'),
(3969, 317, 1518, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-27 13:12:00', '2026-06-27 13:17:00', NULL, '2026-06-27 13:12:00', '2026-06-27 13:12:00'),
(3970, 317, 1517, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-06-27 13:30:00', '2026-06-27 13:35:00', NULL, '2026-06-27 13:30:00', '2026-06-27 13:30:00'),
(3971, 317, 1518, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-06-27 13:48:00', '2026-06-27 13:53:00', NULL, '2026-06-27 13:48:00', '2026-06-27 13:48:00'),
(3972, 317, 1517, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-06-27 14:06:00', '2026-06-27 14:11:00', NULL, '2026-06-27 14:06:00', '2026-06-27 14:06:00'),
(3973, 317, 1518, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-06-27 14:24:00', '2026-06-27 14:29:00', NULL, '2026-06-27 14:24:00', '2026-06-27 14:24:00'),
(3974, 317, 1517, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-06-27 14:42:00', '2026-06-27 14:47:00', NULL, '2026-06-27 14:42:00', '2026-06-27 14:42:00'),
(3975, 317, 1518, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-06-27 15:00:00', '2026-06-27 15:05:00', NULL, '2026-06-27 15:00:00', '2026-06-27 15:00:00'),
(3976, 317, 1517, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-06-27 15:18:00', '2026-06-27 15:23:00', NULL, '2026-06-27 15:18:00', '2026-06-27 15:18:00'),
(3977, 317, 1518, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-06-27 15:36:00', '2026-06-27 15:41:00', NULL, '2026-06-27 15:36:00', '2026-06-27 15:36:00'),
(3978, 317, 1517, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-06-27 15:54:00', '2026-06-27 15:59:00', NULL, '2026-06-27 15:54:00', '2026-06-27 15:54:00'),
(3979, 317, 1518, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-06-27 16:12:00', '2026-06-27 16:17:00', NULL, '2026-06-27 16:12:00', '2026-06-27 16:12:00'),
(3980, 317, 1517, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-06-27 16:30:00', '2026-06-27 16:35:00', NULL, '2026-06-27 16:30:00', '2026-06-27 16:30:00'),
(3981, 317, 1518, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-27 16:48:00', '2026-06-27 16:53:00', NULL, '2026-06-27 16:48:00', '2026-06-27 16:48:00'),
(3982, 317, 1517, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-06-27 17:06:00', '2026-06-27 17:11:00', NULL, '2026-06-27 17:06:00', '2026-06-27 17:06:00'),
(3983, 317, 1518, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-06-27 17:24:00', '2026-06-27 17:29:00', NULL, '2026-06-27 17:24:00', '2026-06-27 17:24:00'),
(3984, 317, 1517, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-06-27 17:42:00', '2026-06-27 17:47:00', NULL, '2026-06-27 17:42:00', '2026-06-27 17:42:00'),
(3985, 317, 1518, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-06-27 18:00:00', '2026-06-27 18:05:00', NULL, '2026-06-27 18:00:00', '2026-06-27 18:00:00'),
(3986, 317, 1517, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-06-27 18:18:00', '2026-06-27 18:23:00', NULL, '2026-06-27 18:18:00', '2026-06-27 18:18:00'),
(3987, 317, 1518, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-06-27 18:36:00', '2026-06-27 18:41:00', NULL, '2026-06-27 18:36:00', '2026-06-27 18:36:00'),
(3988, 317, 1517, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-06-27 18:54:00', '2026-06-27 18:59:00', NULL, '2026-06-27 18:54:00', '2026-06-27 18:54:00'),
(3989, 317, 1518, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-06-27 19:12:00', '2026-06-27 19:17:00', NULL, '2026-06-27 19:12:00', '2026-06-27 19:12:00'),
(3990, 317, 1517, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-06-27 19:30:00', '2026-06-27 19:35:00', NULL, '2026-06-27 19:30:00', '2026-06-27 19:30:00'),
(3991, 317, 1518, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-06-27 19:48:00', '2026-06-27 19:53:00', NULL, '2026-06-27 19:48:00', '2026-06-27 19:48:00'),
(3992, 317, 1517, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-06-27 20:06:00', '2026-06-27 20:11:00', NULL, '2026-06-27 20:06:00', '2026-06-27 20:06:00'),
(3993, 317, 1518, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-27 20:24:00', '2026-06-27 20:29:00', NULL, '2026-06-27 20:24:00', '2026-06-27 20:24:00'),
(3994, 317, 1517, 'text', 'That made me laugh. I needed that today.', NULL, 'delivered', '2026-06-27 20:42:00', NULL, NULL, '2026-06-27 20:42:00', '2026-06-27 20:42:00'),
(3995, 318, 1523, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-06-21 12:18:00', '2026-06-21 12:23:00', NULL, '2026-06-21 12:18:00', '2026-06-21 12:18:00'),
(3996, 318, 1524, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-06-21 12:36:00', '2026-06-21 12:41:00', NULL, '2026-06-21 12:36:00', '2026-06-21 12:36:00'),
(3997, 318, 1523, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-21 12:54:00', '2026-06-21 12:59:00', NULL, '2026-06-21 12:54:00', '2026-06-21 12:54:00'),
(3998, 318, 1524, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-06-21 13:12:00', '2026-06-21 13:17:00', NULL, '2026-06-21 13:12:00', '2026-06-21 13:12:00'),
(3999, 318, 1523, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-06-21 13:30:00', '2026-06-21 13:35:00', NULL, '2026-06-21 13:30:00', '2026-06-21 13:30:00'),
(4000, 318, 1524, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-06-21 13:48:00', '2026-06-21 13:53:00', NULL, '2026-06-21 13:48:00', '2026-06-21 13:48:00'),
(4001, 318, 1523, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-06-21 14:06:00', '2026-06-21 14:11:00', NULL, '2026-06-21 14:06:00', '2026-06-21 14:06:00');
INSERT INTO `messages` (`id`, `conversationId`, `senderId`, `type`, `text`, `context`, `status`, `deliveredAt`, `readAt`, `deletedAt`, `createdAt`, `updatedAt`) VALUES
(4002, 318, 1524, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-06-21 14:24:00', '2026-06-21 14:29:00', NULL, '2026-06-21 14:24:00', '2026-06-21 14:24:00'),
(4003, 318, 1523, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-06-21 14:42:00', '2026-06-21 14:47:00', NULL, '2026-06-21 14:42:00', '2026-06-21 14:42:00'),
(4004, 318, 1524, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-06-21 15:00:00', '2026-06-21 15:05:00', NULL, '2026-06-21 15:00:00', '2026-06-21 15:00:00'),
(4005, 318, 1523, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-06-21 15:18:00', '2026-06-21 15:23:00', NULL, '2026-06-21 15:18:00', '2026-06-21 15:18:00'),
(4006, 318, 1524, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-06-21 15:36:00', '2026-06-21 15:41:00', NULL, '2026-06-21 15:36:00', '2026-06-21 15:36:00'),
(4007, 318, 1523, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-06-21 15:54:00', '2026-06-21 15:59:00', NULL, '2026-06-21 15:54:00', '2026-06-21 15:54:00'),
(4008, 318, 1524, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-06-21 16:12:00', '2026-06-21 16:17:00', NULL, '2026-06-21 16:12:00', '2026-06-21 16:12:00'),
(4009, 318, 1523, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-21 16:30:00', '2026-06-21 16:35:00', NULL, '2026-06-21 16:30:00', '2026-06-21 16:30:00'),
(4010, 318, 1524, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-06-21 16:48:00', '2026-06-21 16:53:00', NULL, '2026-06-21 16:48:00', '2026-06-21 16:48:00'),
(4011, 318, 1523, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-06-21 17:06:00', '2026-06-21 17:11:00', NULL, '2026-06-21 17:06:00', '2026-06-21 17:06:00'),
(4012, 318, 1524, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-06-21 17:24:00', '2026-06-21 17:29:00', NULL, '2026-06-21 17:24:00', '2026-06-21 17:24:00'),
(4013, 318, 1523, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-06-21 17:42:00', '2026-06-21 17:47:00', NULL, '2026-06-21 17:42:00', '2026-06-21 17:42:00'),
(4014, 318, 1524, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-06-21 18:00:00', '2026-06-21 18:05:00', NULL, '2026-06-21 18:00:00', '2026-06-21 18:00:00'),
(4015, 318, 1523, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-06-21 18:18:00', '2026-06-21 18:23:00', NULL, '2026-06-21 18:18:00', '2026-06-21 18:18:00'),
(4016, 318, 1524, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-06-21 18:36:00', '2026-06-21 18:41:00', NULL, '2026-06-21 18:36:00', '2026-06-21 18:36:00'),
(4017, 318, 1523, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-06-21 18:54:00', '2026-06-21 18:59:00', NULL, '2026-06-21 18:54:00', '2026-06-21 18:54:00'),
(4018, 318, 1524, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-06-21 19:12:00', '2026-06-21 19:17:00', NULL, '2026-06-21 19:12:00', '2026-06-21 19:12:00'),
(4019, 318, 1523, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-06-21 19:30:00', '2026-06-21 19:35:00', NULL, '2026-06-21 19:30:00', '2026-06-21 19:30:00'),
(4020, 318, 1524, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-06-21 19:48:00', '2026-06-21 19:53:00', NULL, '2026-06-21 19:48:00', '2026-06-21 19:48:00'),
(4021, 318, 1523, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-21 20:06:00', '2026-06-21 20:11:00', NULL, '2026-06-21 20:06:00', '2026-06-21 20:06:00'),
(4022, 318, 1524, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-06-21 20:24:00', '2026-06-21 20:29:00', NULL, '2026-06-21 20:24:00', '2026-06-21 20:24:00'),
(4023, 318, 1523, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'delivered', '2026-06-21 20:42:00', NULL, NULL, '2026-06-21 20:42:00', '2026-06-21 20:42:00'),
(4024, 318, 1524, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'delivered', '2026-06-21 21:00:00', NULL, NULL, '2026-06-21 21:00:00', '2026-06-21 21:00:00'),
(4025, 319, 1529, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-06-15 12:18:00', '2026-06-15 12:23:00', NULL, '2026-06-15 12:18:00', '2026-06-15 12:18:00'),
(4026, 319, 1530, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-15 12:36:00', '2026-06-15 12:41:00', NULL, '2026-06-15 12:36:00', '2026-06-15 12:36:00'),
(4027, 319, 1529, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-06-15 12:54:00', '2026-06-15 12:59:00', NULL, '2026-06-15 12:54:00', '2026-06-15 12:54:00'),
(4028, 319, 1530, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-06-15 13:12:00', '2026-06-15 13:17:00', NULL, '2026-06-15 13:12:00', '2026-06-15 13:12:00'),
(4029, 319, 1529, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-06-15 13:30:00', '2026-06-15 13:35:00', NULL, '2026-06-15 13:30:00', '2026-06-15 13:30:00'),
(4030, 319, 1530, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-06-15 13:48:00', '2026-06-15 13:53:00', NULL, '2026-06-15 13:48:00', '2026-06-15 13:48:00'),
(4031, 319, 1529, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-06-15 14:06:00', '2026-06-15 14:11:00', NULL, '2026-06-15 14:06:00', '2026-06-15 14:06:00'),
(4032, 319, 1530, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-06-15 14:24:00', '2026-06-15 14:29:00', NULL, '2026-06-15 14:24:00', '2026-06-15 14:24:00'),
(4033, 319, 1529, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-06-15 14:42:00', '2026-06-15 14:47:00', NULL, '2026-06-15 14:42:00', '2026-06-15 14:42:00'),
(4034, 319, 1530, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-06-15 15:00:00', '2026-06-15 15:05:00', NULL, '2026-06-15 15:00:00', '2026-06-15 15:00:00'),
(4035, 319, 1529, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-06-15 15:18:00', '2026-06-15 15:23:00', NULL, '2026-06-15 15:18:00', '2026-06-15 15:18:00'),
(4036, 319, 1530, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-06-15 15:36:00', '2026-06-15 15:41:00', NULL, '2026-06-15 15:36:00', '2026-06-15 15:36:00'),
(4037, 319, 1529, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-06-15 15:54:00', '2026-06-15 15:59:00', NULL, '2026-06-15 15:54:00', '2026-06-15 15:54:00'),
(4038, 319, 1530, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-15 16:12:00', '2026-06-15 16:17:00', NULL, '2026-06-15 16:12:00', '2026-06-15 16:12:00'),
(4039, 319, 1529, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-06-15 16:30:00', '2026-06-15 16:35:00', NULL, '2026-06-15 16:30:00', '2026-06-15 16:30:00'),
(4040, 319, 1530, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-06-15 16:48:00', '2026-06-15 16:53:00', NULL, '2026-06-15 16:48:00', '2026-06-15 16:48:00'),
(4041, 319, 1529, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-06-15 17:06:00', '2026-06-15 17:11:00', NULL, '2026-06-15 17:06:00', '2026-06-15 17:06:00'),
(4042, 319, 1530, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-06-15 17:24:00', '2026-06-15 17:29:00', NULL, '2026-06-15 17:24:00', '2026-06-15 17:24:00'),
(4043, 319, 1529, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-06-15 17:42:00', '2026-06-15 17:47:00', NULL, '2026-06-15 17:42:00', '2026-06-15 17:42:00'),
(4044, 319, 1530, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-06-15 18:00:00', '2026-06-15 18:05:00', NULL, '2026-06-15 18:00:00', '2026-06-15 18:00:00'),
(4045, 319, 1529, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-06-15 18:18:00', '2026-06-15 18:23:00', NULL, '2026-06-15 18:18:00', '2026-06-15 18:18:00'),
(4046, 319, 1530, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-06-15 18:36:00', '2026-06-15 18:41:00', NULL, '2026-06-15 18:36:00', '2026-06-15 18:36:00'),
(4047, 319, 1529, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-06-15 18:54:00', '2026-06-15 18:59:00', NULL, '2026-06-15 18:54:00', '2026-06-15 18:54:00'),
(4048, 319, 1530, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-06-15 19:12:00', '2026-06-15 19:17:00', NULL, '2026-06-15 19:12:00', '2026-06-15 19:12:00'),
(4049, 319, 1529, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-06-15 19:30:00', '2026-06-15 19:35:00', NULL, '2026-06-15 19:30:00', '2026-06-15 19:30:00'),
(4050, 319, 1530, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-15 19:48:00', '2026-06-15 19:53:00', NULL, '2026-06-15 19:48:00', '2026-06-15 19:48:00'),
(4051, 319, 1529, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-06-15 20:06:00', '2026-06-15 20:11:00', NULL, '2026-06-15 20:06:00', '2026-06-15 20:06:00'),
(4052, 319, 1530, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-06-15 20:24:00', '2026-06-15 20:29:00', NULL, '2026-06-15 20:24:00', '2026-06-15 20:24:00'),
(4053, 319, 1529, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'delivered', '2026-06-15 20:42:00', NULL, NULL, '2026-06-15 20:42:00', '2026-06-15 20:42:00'),
(4054, 319, 1530, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'delivered', '2026-06-15 21:00:00', NULL, NULL, '2026-06-15 21:00:00', '2026-06-15 21:00:00'),
(4055, 319, 1529, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'delivered', '2026-06-15 21:18:00', NULL, NULL, '2026-06-15 21:18:00', '2026-06-15 21:18:00'),
(4056, 320, 1535, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-09 12:18:00', '2026-06-09 12:23:00', NULL, '2026-06-09 12:18:00', '2026-06-09 12:18:00'),
(4057, 320, 1536, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-06-09 12:36:00', '2026-06-09 12:41:00', NULL, '2026-06-09 12:36:00', '2026-06-09 12:36:00'),
(4058, 320, 1535, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-06-09 12:54:00', '2026-06-09 12:59:00', NULL, '2026-06-09 12:54:00', '2026-06-09 12:54:00'),
(4059, 320, 1536, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-06-09 13:12:00', '2026-06-09 13:17:00', NULL, '2026-06-09 13:12:00', '2026-06-09 13:12:00'),
(4060, 320, 1535, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-06-09 13:30:00', '2026-06-09 13:35:00', NULL, '2026-06-09 13:30:00', '2026-06-09 13:30:00'),
(4061, 320, 1536, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-06-09 13:48:00', '2026-06-09 13:53:00', NULL, '2026-06-09 13:48:00', '2026-06-09 13:48:00'),
(4062, 320, 1535, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-06-09 14:06:00', '2026-06-09 14:11:00', NULL, '2026-06-09 14:06:00', '2026-06-09 14:06:00'),
(4063, 320, 1536, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-06-09 14:24:00', '2026-06-09 14:29:00', NULL, '2026-06-09 14:24:00', '2026-06-09 14:24:00'),
(4064, 320, 1535, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-06-09 14:42:00', '2026-06-09 14:47:00', NULL, '2026-06-09 14:42:00', '2026-06-09 14:42:00'),
(4065, 320, 1536, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-06-09 15:00:00', '2026-06-09 15:05:00', NULL, '2026-06-09 15:00:00', '2026-06-09 15:00:00'),
(4066, 320, 1535, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-06-09 15:18:00', '2026-06-09 15:23:00', NULL, '2026-06-09 15:18:00', '2026-06-09 15:18:00'),
(4067, 320, 1536, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-06-09 15:36:00', '2026-06-09 15:41:00', NULL, '2026-06-09 15:36:00', '2026-06-09 15:36:00'),
(4068, 320, 1535, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-09 15:54:00', '2026-06-09 15:59:00', NULL, '2026-06-09 15:54:00', '2026-06-09 15:54:00'),
(4069, 320, 1536, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-06-09 16:12:00', '2026-06-09 16:17:00', NULL, '2026-06-09 16:12:00', '2026-06-09 16:12:00'),
(4070, 320, 1535, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-06-09 16:30:00', '2026-06-09 16:35:00', NULL, '2026-06-09 16:30:00', '2026-06-09 16:30:00'),
(4071, 320, 1536, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-06-09 16:48:00', '2026-06-09 16:53:00', NULL, '2026-06-09 16:48:00', '2026-06-09 16:48:00'),
(4072, 320, 1535, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-06-09 17:06:00', '2026-06-09 17:11:00', NULL, '2026-06-09 17:06:00', '2026-06-09 17:06:00'),
(4073, 320, 1536, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-06-09 17:24:00', '2026-06-09 17:29:00', NULL, '2026-06-09 17:24:00', '2026-06-09 17:24:00'),
(4074, 320, 1535, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-06-09 17:42:00', '2026-06-09 17:47:00', NULL, '2026-06-09 17:42:00', '2026-06-09 17:42:00'),
(4075, 320, 1536, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-06-09 18:00:00', '2026-06-09 18:05:00', NULL, '2026-06-09 18:00:00', '2026-06-09 18:00:00'),
(4076, 320, 1535, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-06-09 18:18:00', '2026-06-09 18:23:00', NULL, '2026-06-09 18:18:00', '2026-06-09 18:18:00'),
(4077, 320, 1536, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-06-09 18:36:00', '2026-06-09 18:41:00', NULL, '2026-06-09 18:36:00', '2026-06-09 18:36:00'),
(4078, 320, 1535, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-06-09 18:54:00', '2026-06-09 18:59:00', NULL, '2026-06-09 18:54:00', '2026-06-09 18:54:00'),
(4079, 320, 1536, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-06-09 19:12:00', '2026-06-09 19:17:00', NULL, '2026-06-09 19:12:00', '2026-06-09 19:12:00'),
(4080, 320, 1535, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-06-09 19:30:00', '2026-06-09 19:35:00', NULL, '2026-06-09 19:30:00', '2026-06-09 19:30:00'),
(4081, 320, 1536, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-06-09 19:48:00', '2026-06-09 19:53:00', NULL, '2026-06-09 19:48:00', '2026-06-09 19:48:00'),
(4082, 320, 1535, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-06-09 20:06:00', '2026-06-09 20:11:00', NULL, '2026-06-09 20:06:00', '2026-06-09 20:06:00'),
(4083, 320, 1536, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-06-09 20:24:00', '2026-06-09 20:29:00', NULL, '2026-06-09 20:24:00', '2026-06-09 20:24:00'),
(4084, 320, 1535, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-06-09 20:42:00', '2026-06-09 20:47:00', NULL, '2026-06-09 20:42:00', '2026-06-09 20:42:00'),
(4085, 320, 1536, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-06-09 21:00:00', '2026-06-09 21:05:00', NULL, '2026-06-09 21:00:00', '2026-06-09 21:00:00'),
(4086, 320, 1535, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-06-09 21:18:00', '2026-06-09 21:23:00', NULL, '2026-06-09 21:18:00', '2026-06-09 21:18:00'),
(4087, 320, 1536, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-06-09 21:36:00', '2026-06-09 21:41:00', NULL, '2026-06-09 21:36:00', '2026-06-09 21:36:00'),
(4088, 322, 1547, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'delivered', '2026-08-26 12:18:00', NULL, NULL, '2026-08-26 12:18:00', '2026-08-26 12:18:00'),
(4089, 323, 1553, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-20 12:18:00', '2026-08-20 12:23:00', NULL, '2026-08-20 12:18:00', '2026-08-20 12:18:00'),
(4090, 323, 1554, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-20 12:36:00', '2026-08-20 12:41:00', NULL, '2026-08-20 12:36:00', '2026-08-20 12:36:00'),
(4091, 323, 1553, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-20 12:54:00', '2026-08-20 12:59:00', NULL, '2026-08-20 12:54:00', '2026-08-20 12:54:00'),
(4092, 323, 1554, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'delivered', '2026-08-20 13:12:00', NULL, NULL, '2026-08-20 13:12:00', '2026-08-20 13:12:00'),
(4093, 323, 1553, 'text', 'How\'s your weekend going?', NULL, 'delivered', '2026-08-20 13:30:00', NULL, NULL, '2026-08-20 13:30:00', '2026-08-20 13:30:00'),
(4094, 323, 1554, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'delivered', '2026-08-20 13:48:00', NULL, NULL, '2026-08-20 13:48:00', '2026-08-20 13:48:00'),
(4095, 324, 1559, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-14 12:18:00', '2026-08-14 12:23:00', NULL, '2026-08-14 12:18:00', '2026-08-14 12:18:00'),
(4096, 324, 1560, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-14 12:36:00', '2026-08-14 12:41:00', NULL, '2026-08-14 12:36:00', '2026-08-14 12:36:00'),
(4097, 324, 1559, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-14 12:54:00', '2026-08-14 12:59:00', NULL, '2026-08-14 12:54:00', '2026-08-14 12:54:00'),
(4098, 324, 1560, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-14 13:12:00', '2026-08-14 13:17:00', NULL, '2026-08-14 13:12:00', '2026-08-14 13:12:00'),
(4099, 324, 1559, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-14 13:30:00', '2026-08-14 13:35:00', NULL, '2026-08-14 13:30:00', '2026-08-14 13:30:00'),
(4100, 324, 1560, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-14 13:48:00', '2026-08-14 13:53:00', NULL, '2026-08-14 13:48:00', '2026-08-14 13:48:00'),
(4101, 324, 1559, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-14 14:06:00', '2026-08-14 14:11:00', NULL, '2026-08-14 14:06:00', '2026-08-14 14:06:00'),
(4102, 324, 1560, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-14 14:24:00', '2026-08-14 14:29:00', NULL, '2026-08-14 14:24:00', '2026-08-14 14:24:00'),
(4103, 324, 1559, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-14 14:42:00', '2026-08-14 14:47:00', NULL, '2026-08-14 14:42:00', '2026-08-14 14:42:00'),
(4104, 324, 1560, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-14 15:00:00', '2026-08-14 15:05:00', NULL, '2026-08-14 15:00:00', '2026-08-14 15:00:00'),
(4105, 324, 1559, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-14 15:18:00', '2026-08-14 15:23:00', NULL, '2026-08-14 15:18:00', '2026-08-14 15:18:00'),
(4106, 324, 1560, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-14 15:36:00', '2026-08-14 15:41:00', NULL, '2026-08-14 15:36:00', '2026-08-14 15:36:00'),
(4107, 325, 1565, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-08 12:18:00', '2026-08-08 12:23:00', NULL, '2026-08-08 12:18:00', '2026-08-08 12:18:00'),
(4108, 325, 1566, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-08 12:36:00', '2026-08-08 12:41:00', NULL, '2026-08-08 12:36:00', '2026-08-08 12:36:00'),
(4109, 325, 1565, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-08 12:54:00', '2026-08-08 12:59:00', NULL, '2026-08-08 12:54:00', '2026-08-08 12:54:00'),
(4110, 325, 1566, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-08 13:12:00', '2026-08-08 13:17:00', NULL, '2026-08-08 13:12:00', '2026-08-08 13:12:00'),
(4111, 325, 1565, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-08 13:30:00', '2026-08-08 13:35:00', NULL, '2026-08-08 13:30:00', '2026-08-08 13:30:00'),
(4112, 325, 1566, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-08 13:48:00', '2026-08-08 13:53:00', NULL, '2026-08-08 13:48:00', '2026-08-08 13:48:00'),
(4113, 325, 1565, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-08 14:06:00', '2026-08-08 14:11:00', NULL, '2026-08-08 14:06:00', '2026-08-08 14:06:00'),
(4114, 325, 1566, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-08 14:24:00', '2026-08-08 14:29:00', NULL, '2026-08-08 14:24:00', '2026-08-08 14:24:00'),
(4115, 325, 1565, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-08 14:42:00', '2026-08-08 14:47:00', NULL, '2026-08-08 14:42:00', '2026-08-08 14:42:00'),
(4116, 325, 1566, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-08 15:00:00', '2026-08-08 15:05:00', NULL, '2026-08-08 15:00:00', '2026-08-08 15:00:00'),
(4117, 325, 1565, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-08 15:18:00', '2026-08-08 15:23:00', NULL, '2026-08-08 15:18:00', '2026-08-08 15:18:00'),
(4118, 325, 1566, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-08 15:36:00', '2026-08-08 15:41:00', NULL, '2026-08-08 15:36:00', '2026-08-08 15:36:00'),
(4119, 325, 1565, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'delivered', '2026-08-08 15:54:00', NULL, NULL, '2026-08-08 15:54:00', '2026-08-08 15:54:00'),
(4120, 326, 1571, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-08-02 12:18:00', '2026-08-02 12:23:00', NULL, '2026-08-02 12:18:00', '2026-08-02 12:18:00'),
(4121, 326, 1572, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-08-02 12:36:00', '2026-08-02 12:41:00', NULL, '2026-08-02 12:36:00', '2026-08-02 12:36:00'),
(4122, 326, 1571, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-08-02 12:54:00', '2026-08-02 12:59:00', NULL, '2026-08-02 12:54:00', '2026-08-02 12:54:00'),
(4123, 326, 1572, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-08-02 13:12:00', '2026-08-02 13:17:00', NULL, '2026-08-02 13:12:00', '2026-08-02 13:12:00'),
(4124, 326, 1571, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-08-02 13:30:00', '2026-08-02 13:35:00', NULL, '2026-08-02 13:30:00', '2026-08-02 13:30:00'),
(4125, 326, 1572, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-08-02 13:48:00', '2026-08-02 13:53:00', NULL, '2026-08-02 13:48:00', '2026-08-02 13:48:00'),
(4126, 326, 1571, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-08-02 14:06:00', '2026-08-02 14:11:00', NULL, '2026-08-02 14:06:00', '2026-08-02 14:06:00'),
(4127, 326, 1572, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-08-02 14:24:00', '2026-08-02 14:29:00', NULL, '2026-08-02 14:24:00', '2026-08-02 14:24:00'),
(4128, 326, 1571, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-08-02 14:42:00', '2026-08-02 14:47:00', NULL, '2026-08-02 14:42:00', '2026-08-02 14:42:00'),
(4129, 326, 1572, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-08-02 15:00:00', '2026-08-02 15:05:00', NULL, '2026-08-02 15:00:00', '2026-08-02 15:00:00'),
(4130, 326, 1571, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-08-02 15:18:00', '2026-08-02 15:23:00', NULL, '2026-08-02 15:18:00', '2026-08-02 15:18:00'),
(4131, 326, 1572, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-08-02 15:36:00', '2026-08-02 15:41:00', NULL, '2026-08-02 15:36:00', '2026-08-02 15:36:00'),
(4132, 326, 1571, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'delivered', '2026-08-02 15:54:00', NULL, NULL, '2026-08-02 15:54:00', '2026-08-02 15:54:00'),
(4133, 326, 1572, 'text', 'How\'s your weekend going?', NULL, 'delivered', '2026-08-02 16:12:00', NULL, NULL, '2026-08-02 16:12:00', '2026-08-02 16:12:00'),
(4134, 327, 1577, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-07-27 12:18:00', '2026-07-27 12:23:00', NULL, '2026-07-27 12:18:00', '2026-07-27 12:18:00'),
(4135, 327, 1578, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-07-27 12:36:00', '2026-07-27 12:41:00', NULL, '2026-07-27 12:36:00', '2026-07-27 12:36:00'),
(4136, 327, 1577, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-07-27 12:54:00', '2026-07-27 12:59:00', NULL, '2026-07-27 12:54:00', '2026-07-27 12:54:00'),
(4137, 327, 1578, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-07-27 13:12:00', '2026-07-27 13:17:00', NULL, '2026-07-27 13:12:00', '2026-07-27 13:12:00'),
(4138, 327, 1577, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-07-27 13:30:00', '2026-07-27 13:35:00', NULL, '2026-07-27 13:30:00', '2026-07-27 13:30:00'),
(4139, 327, 1578, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-07-27 13:48:00', '2026-07-27 13:53:00', NULL, '2026-07-27 13:48:00', '2026-07-27 13:48:00'),
(4140, 327, 1577, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-07-27 14:06:00', '2026-07-27 14:11:00', NULL, '2026-07-27 14:06:00', '2026-07-27 14:06:00'),
(4141, 327, 1578, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-07-27 14:24:00', '2026-07-27 14:29:00', NULL, '2026-07-27 14:24:00', '2026-07-27 14:24:00'),
(4142, 327, 1577, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-07-27 14:42:00', '2026-07-27 14:47:00', NULL, '2026-07-27 14:42:00', '2026-07-27 14:42:00'),
(4143, 327, 1578, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-07-27 15:00:00', '2026-07-27 15:05:00', NULL, '2026-07-27 15:00:00', '2026-07-27 15:00:00'),
(4144, 327, 1577, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-07-27 15:18:00', '2026-07-27 15:23:00', NULL, '2026-07-27 15:18:00', '2026-07-27 15:18:00'),
(4145, 327, 1578, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-07-27 15:36:00', '2026-07-27 15:41:00', NULL, '2026-07-27 15:36:00', '2026-07-27 15:36:00'),
(4146, 327, 1577, 'text', 'How\'s your weekend going?', NULL, 'delivered', '2026-07-27 15:54:00', NULL, NULL, '2026-07-27 15:54:00', '2026-07-27 15:54:00'),
(4147, 327, 1578, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'delivered', '2026-07-27 16:12:00', NULL, NULL, '2026-07-27 16:12:00', '2026-07-27 16:12:00'),
(4148, 327, 1577, 'text', 'What is the best book you have read this year?', NULL, 'delivered', '2026-07-27 16:30:00', NULL, NULL, '2026-07-27 16:30:00', '2026-07-27 16:30:00'),
(4149, 329, 1589, 'text', 'What is the best book you have read this year?', NULL, 'delivered', '2026-07-15 12:18:00', NULL, NULL, '2026-07-15 12:18:00', '2026-07-15 12:18:00'),
(4150, 330, 1595, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-07-09 12:18:00', '2026-07-09 12:23:00', NULL, '2026-07-09 12:18:00', '2026-07-09 12:18:00'),
(4151, 330, 1596, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-07-09 12:36:00', '2026-07-09 12:41:00', NULL, '2026-07-09 12:36:00', '2026-07-09 12:36:00'),
(4152, 330, 1595, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-07-09 12:54:00', '2026-07-09 12:59:00', NULL, '2026-07-09 12:54:00', '2026-07-09 12:54:00'),
(4153, 330, 1596, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-07-09 13:12:00', '2026-07-09 13:17:00', NULL, '2026-07-09 13:12:00', '2026-07-09 13:12:00'),
(4154, 330, 1595, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'delivered', '2026-07-09 13:30:00', NULL, NULL, '2026-07-09 13:30:00', '2026-07-09 13:30:00'),
(4155, 330, 1596, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'delivered', '2026-07-09 13:48:00', NULL, NULL, '2026-07-09 13:48:00', '2026-07-09 13:48:00'),
(4156, 331, 1601, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-07-03 12:18:00', '2026-07-03 12:23:00', NULL, '2026-07-03 12:18:00', '2026-07-03 12:18:00'),
(4157, 331, 1602, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-07-03 12:36:00', '2026-07-03 12:41:00', NULL, '2026-07-03 12:36:00', '2026-07-03 12:36:00'),
(4158, 331, 1601, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-07-03 12:54:00', '2026-07-03 12:59:00', NULL, '2026-07-03 12:54:00', '2026-07-03 12:54:00'),
(4159, 331, 1602, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-07-03 13:12:00', '2026-07-03 13:17:00', NULL, '2026-07-03 13:12:00', '2026-07-03 13:12:00'),
(4160, 331, 1601, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'read', '2026-07-03 13:30:00', '2026-07-03 13:35:00', NULL, '2026-07-03 13:30:00', '2026-07-03 13:30:00'),
(4161, 331, 1602, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'read', '2026-07-03 13:48:00', '2026-07-03 13:53:00', NULL, '2026-07-03 13:48:00', '2026-07-03 13:48:00'),
(4162, 331, 1601, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'read', '2026-07-03 14:06:00', '2026-07-03 14:11:00', NULL, '2026-07-03 14:06:00', '2026-07-03 14:06:00'),
(4163, 331, 1602, 'text', 'I\'ve been meaning to try that restaurant.', NULL, 'read', '2026-07-03 14:24:00', '2026-07-03 14:29:00', NULL, '2026-07-03 14:24:00', '2026-07-03 14:24:00'),
(4164, 331, 1601, 'text', 'How\'s your weekend going?', NULL, 'read', '2026-07-03 14:42:00', '2026-07-03 14:47:00', NULL, '2026-07-03 14:42:00', '2026-07-03 14:42:00'),
(4165, 331, 1602, 'text', 'A sunrise walk sounds like a very good plan.', NULL, 'read', '2026-07-03 15:00:00', '2026-07-03 15:05:00', NULL, '2026-07-03 15:00:00', '2026-07-03 15:00:00'),
(4166, 331, 1601, 'text', 'What is the best book you have read this year?', NULL, 'read', '2026-07-03 15:18:00', '2026-07-03 15:23:00', NULL, '2026-07-03 15:18:00', '2026-07-03 15:18:00'),
(4167, 331, 1602, 'text', 'Your coffee recommendation was excellent, by the way.', NULL, 'read', '2026-07-03 15:36:00', '2026-07-03 15:41:00', NULL, '2026-07-03 15:36:00', '2026-07-03 15:36:00'),
(4168, 331, 1601, 'text', 'I would absolutely join that heritage walk.', NULL, 'read', '2026-07-03 15:54:00', '2026-07-03 15:59:00', NULL, '2026-07-03 15:54:00', '2026-07-03 15:54:00'),
(4169, 331, 1602, 'text', 'Do you have a favourite live music spot in the city?', NULL, 'read', '2026-07-03 16:12:00', '2026-07-03 16:17:00', NULL, '2026-07-03 16:12:00', '2026-07-03 16:12:00'),
(4170, 331, 1601, 'text', 'That made me laugh. I needed that today.', NULL, 'read', '2026-07-03 16:30:00', '2026-07-03 16:35:00', NULL, '2026-07-03 16:30:00', '2026-07-03 16:30:00'),
(4171, 331, 1602, 'text', 'I am free Saturday afternoon if you want to continue this in person.', NULL, 'read', '2026-07-03 16:48:00', '2026-07-03 16:53:00', NULL, '2026-07-03 16:48:00', '2026-07-03 16:48:00'),
(4172, 331, 1601, 'text', 'Perfect. Shall we meet near the riverfront around four?', NULL, 'delivered', '2026-07-03 17:06:00', NULL, NULL, '2026-07-03 17:06:00', '2026-07-03 17:06:00'),
(4173, 331, 1602, 'text', 'Hey! I saw that you\'re into hiking too.', NULL, 'delivered', '2026-07-03 17:24:00', NULL, NULL, '2026-07-03 17:24:00', '2026-07-03 17:24:00'),
(4174, 331, 1601, 'text', 'That place looks amazing. Where was that photo taken?', NULL, 'delivered', '2026-07-03 17:42:00', NULL, NULL, '2026-07-03 17:42:00', '2026-07-03 17:42:00');

-- --------------------------------------------------------

--
-- Table structure for table `notificationdeliveries`
--

CREATE TABLE `notificationdeliveries` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `notificationId` bigint(20) UNSIGNED NOT NULL,
  `userDeviceId` bigint(20) UNSIGNED NOT NULL,
  `channel` enum('push') NOT NULL DEFAULT 'push',
  `status` enum('pending','sent','failed','credentials_required') NOT NULL DEFAULT 'pending',
  `providerMessageId` varchar(255) DEFAULT NULL,
  `attemptCount` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `lastAttemptAt` datetime DEFAULT NULL,
  `errorCode` varchar(100) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notificationpreferences`
--

CREATE TABLE `notificationpreferences` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `newMatches` tinyint(1) NOT NULL DEFAULT 1,
  `messages` tinyint(1) NOT NULL DEFAULT 1,
  `eventReminders` tinyint(1) NOT NULL DEFAULT 1,
  `paymentsAndMembership` tinyint(1) NOT NULL DEFAULT 1,
  `offers` tinyint(1) NOT NULL DEFAULT 0,
  `safetyUpdates` tinyint(1) NOT NULL DEFAULT 1,
  `pushEnabled` tinyint(1) NOT NULL DEFAULT 0,
  `emailEnabled` tinyint(1) NOT NULL DEFAULT 1,
  `smsEnabled` tinyint(1) NOT NULL DEFAULT 0,
  `quietHoursEnabled` tinyint(1) NOT NULL DEFAULT 1,
  `quietStart` varchar(5) NOT NULL DEFAULT '22:00',
  `quietEnd` varchar(5) NOT NULL DEFAULT '07:00',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notificationpreferences`
--

INSERT INTO `notificationpreferences` (`id`, `userId`, `newMatches`, `messages`, `eventReminders`, `paymentsAndMembership`, `offers`, `safetyUpdates`, `pushEnabled`, `emailEnabled`, `smsEnabled`, `quietHoursEnabled`, `quietStart`, `quietEnd`, `createdAt`, `updatedAt`) VALUES
(1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 22:27:21'),
(2, 2, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(3, 3, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(4, 4, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(5, 5, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(6, 6, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(7, 7, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(8, 8, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(9, 9, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(10, 10, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(11, 11, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(12, 12, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(13, 13, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(14, 14, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(15, 15, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(43, 85, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-13 07:06:31', '2026-08-13 07:06:31'),
(1403, 1454, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-07-13 12:00:00', '2026-08-28 12:00:00'),
(1404, 1455, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-12-21 11:59:00', '2026-08-13 11:59:00'),
(1405, 1456, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-04-26 11:58:00', '2026-08-09 11:58:00'),
(1406, 1457, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-08-28 11:57:00', '2026-08-28 11:57:00'),
(1407, 1458, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-10-08 11:56:00', '2026-08-22 11:56:00'),
(1408, 1459, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-29 11:55:00', '2026-08-29 11:55:00'),
(1409, 1460, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2024-03-12 11:54:00', '2026-08-22 11:54:00'),
(1410, 1461, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-09-28 11:53:00', '2026-08-26 11:53:00'),
(1411, 1462, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-04-10 11:52:00', '2026-08-18 11:52:00'),
(1412, 1463, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-03-23 11:51:00', '2026-08-29 11:51:00'),
(1413, 1464, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-11-11 11:50:00', '2026-08-18 11:50:00'),
(1414, 1465, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-03-17 11:49:00', '2026-08-24 11:49:00'),
(1415, 1466, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-05-29 11:48:00', '2026-08-14 11:48:00'),
(1416, 1467, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-18 11:47:00', '2026-08-18 11:47:00'),
(1417, 1468, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-04-30 11:46:00', '2026-08-22 11:46:00'),
(1418, 1469, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-12-17 11:45:00', '2026-08-22 11:45:00'),
(1419, 1470, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-08-03 11:44:00', '2026-08-24 11:44:00'),
(1420, 1471, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-11 11:43:00', '2026-08-25 11:43:00'),
(1421, 1472, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-07-01 11:42:00', '2026-08-29 11:42:00'),
(1422, 1473, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-01-05 11:41:00', '2026-08-21 11:41:00'),
(1423, 1474, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-09-09 11:40:00', '2026-08-29 11:40:00'),
(1424, 1475, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-04-21 11:39:00', '2026-08-10 11:39:00'),
(1425, 1476, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-09-25 11:38:00', '2026-08-29 11:38:00'),
(1426, 1477, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-05-02 11:37:00', '2026-08-12 11:37:00'),
(1427, 1478, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-11-06 11:36:00', '2026-08-10 11:36:00'),
(1428, 1479, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-21 11:35:00', '2026-08-24 11:35:00'),
(1429, 1480, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-08-09 11:34:00', '2026-08-10 11:34:00'),
(1430, 1481, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-07-19 11:33:00', '2026-08-27 11:33:00'),
(1431, 1482, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-03-16 11:32:00', '2026-08-17 11:32:00'),
(1432, 1483, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-02-08 11:31:00', '2026-08-24 11:31:00'),
(1433, 1484, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-09-02 11:30:00', '2026-08-18 11:30:00'),
(1434, 1485, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-04-23 11:29:00', '2026-08-12 11:29:00'),
(1435, 1486, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-09-07 11:28:00', '2026-08-20 11:28:00'),
(1436, 1487, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-11-09 11:27:00', '2026-08-20 11:27:00'),
(1437, 1488, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-01-21 11:26:00', '2026-08-21 11:26:00'),
(1438, 1489, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-10-19 11:25:00', '2026-08-16 11:25:00'),
(1439, 1490, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-10-08 11:24:00', '2026-08-11 11:24:00'),
(1440, 1491, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-02-13 11:23:00', '2026-08-22 11:23:00'),
(1441, 1492, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-04-29 11:22:00', '2026-08-19 11:22:00'),
(1442, 1493, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-08-25 11:21:00', '2026-08-14 11:21:00'),
(1443, 1494, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-07-04 11:20:00', '2026-08-12 11:20:00'),
(1444, 1495, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-07-15 11:19:00', '2026-08-15 11:19:00'),
(1445, 1496, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-11-04 11:18:00', '2026-08-24 11:18:00'),
(1446, 1497, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-08-30 11:17:00', '2026-08-25 11:17:00'),
(1447, 1498, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-12-18 11:16:00', '2026-08-24 11:16:00'),
(1448, 1499, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-01-19 11:15:00', '2026-08-09 11:15:00'),
(1449, 1500, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-05-31 11:14:00', '2026-08-21 11:14:00'),
(1450, 1501, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-07-18 11:13:00', '2026-08-13 11:13:00'),
(1451, 1502, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-10-15 11:12:00', '2026-08-16 11:12:00'),
(1452, 1503, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-02-03 11:11:00', '2026-08-12 11:11:00'),
(1453, 1504, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-08-19 11:10:00', '2026-08-26 11:10:00'),
(1454, 1505, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-11-19 11:09:00', '2026-08-11 11:09:00'),
(1455, 1506, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-08-20 11:08:00', '2026-08-19 11:08:00'),
(1456, 1507, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-03-19 11:07:00', '2026-08-15 11:07:00'),
(1457, 1508, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-04-10 11:06:00', '2026-08-13 11:06:00'),
(1458, 1509, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-08-19 11:05:00', '2026-08-15 11:05:00'),
(1459, 1510, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-09-08 11:04:00', '2026-08-26 11:04:00'),
(1460, 1511, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-08-06 11:03:00', '2026-08-17 11:03:00'),
(1461, 1512, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-12 11:02:00', '2026-08-17 11:02:00'),
(1462, 1513, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-02 11:01:00', '2026-08-19 11:01:00'),
(1463, 1514, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-12-27 11:00:00', '2026-08-10 11:00:00'),
(1464, 1515, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-05-26 10:59:00', '2026-08-16 10:59:00'),
(1465, 1516, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-12-08 10:58:00', '2026-08-22 10:58:00'),
(1466, 1517, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-08-20 10:57:00', '2026-08-24 10:57:00'),
(1467, 1518, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-21 10:56:00', '2026-08-24 10:56:00'),
(1468, 1519, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-12-23 10:55:00', '2026-08-27 10:55:00'),
(1469, 1520, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-02-26 10:54:00', '2026-08-17 10:54:00'),
(1470, 1521, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-07-18 10:53:00', '2026-08-12 10:53:00'),
(1471, 1522, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-11-30 10:52:00', '2026-08-21 10:52:00'),
(1472, 1523, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-07-13 10:51:00', '2026-08-17 10:51:00'),
(1473, 1524, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-11-01 10:50:00', '2026-08-17 10:50:00'),
(1474, 1525, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-06-25 10:49:00', '2026-08-16 10:49:00'),
(1475, 1526, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-02-13 10:48:00', '2026-08-17 10:48:00'),
(1476, 1527, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-07-08 10:47:00', '2026-08-24 10:47:00'),
(1477, 1528, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-09-29 10:46:00', '2026-08-28 10:46:00'),
(1478, 1529, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-07-15 10:45:00', '2026-08-12 10:45:00'),
(1479, 1530, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-10-08 10:44:00', '2026-08-29 10:44:00'),
(1480, 1531, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-09-09 10:43:00', '2026-08-22 10:43:00'),
(1481, 1532, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-05-13 10:42:00', '2026-08-09 10:42:00'),
(1482, 1533, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-12-28 10:41:00', '2026-08-26 10:41:00'),
(1483, 1534, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-01 10:40:00', '2026-08-13 10:40:00'),
(1484, 1535, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-02-22 10:39:00', '2026-08-26 10:39:00'),
(1485, 1536, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-03-23 10:38:00', '2026-08-27 10:38:00'),
(1486, 1537, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-02-03 10:37:00', '2026-08-16 10:37:00'),
(1487, 1538, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-08-11 10:36:00', '2026-08-22 10:36:00'),
(1488, 1539, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-08-05 10:35:00', '2026-08-21 10:35:00'),
(1489, 1540, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-09-21 10:34:00', '2026-08-16 10:34:00'),
(1490, 1541, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-06-12 10:33:00', '2026-08-25 10:33:00'),
(1491, 1542, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-08-06 10:32:00', '2026-08-24 10:32:00'),
(1492, 1543, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-12-31 10:31:00', '2026-08-17 10:31:00'),
(1493, 1544, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-02-05 10:30:00', '2026-08-21 10:30:00'),
(1494, 1545, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-03-11 10:29:00', '2026-08-18 10:29:00'),
(1495, 1546, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-04-25 10:28:00', '2026-08-29 10:28:00'),
(1496, 1547, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-02-19 10:27:00', '2026-08-09 10:27:00'),
(1497, 1548, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-07-17 10:26:00', '2026-08-27 10:26:00'),
(1498, 1549, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-07-29 10:25:00', '2026-08-20 10:25:00'),
(1499, 1550, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-10-18 10:24:00', '2026-08-10 10:24:00'),
(1500, 1551, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-16 10:23:00', '2026-08-16 10:23:00'),
(1501, 1552, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-07-29 10:22:00', '2026-08-15 10:22:00'),
(1502, 1553, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-04-30 10:21:00', '2026-08-27 10:21:00'),
(1503, 1554, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-12-01 10:20:00', '2026-08-17 10:20:00'),
(1504, 1555, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-01-15 10:19:00', '2026-08-10 10:19:00'),
(1505, 1556, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-04-09 10:18:00', '2026-08-27 10:18:00'),
(1506, 1557, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-12-06 10:17:00', '2026-08-23 10:17:00'),
(1507, 1558, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-05-19 10:16:00', '2026-08-17 10:16:00'),
(1508, 1559, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-05-19 10:15:00', '2026-08-18 10:15:00'),
(1509, 1560, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-12-22 10:14:00', '2026-08-17 10:14:00'),
(1510, 1561, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-05-02 10:13:00', '2026-08-26 10:13:00'),
(1511, 1562, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-03-14 10:12:00', '2026-08-27 10:12:00'),
(1512, 1563, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-09-16 10:11:00', '2026-08-28 10:11:00'),
(1513, 1564, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-03-21 10:10:00', '2026-08-19 10:10:00'),
(1514, 1565, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-04-25 10:09:00', '2026-08-18 10:09:00'),
(1515, 1566, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-10-24 10:08:00', '2026-08-28 10:08:00'),
(1516, 1567, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-08-23 10:07:00', '2026-08-29 10:07:00'),
(1517, 1568, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-11-24 10:06:00', '2026-08-24 10:06:00'),
(1518, 1569, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-02-26 10:05:00', '2026-08-14 10:05:00'),
(1519, 1570, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-03-31 10:04:00', '2026-08-16 10:04:00'),
(1520, 1571, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-12-24 10:03:00', '2026-08-09 10:03:00'),
(1521, 1572, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-04-10 10:02:00', '2026-08-18 10:02:00'),
(1522, 1573, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-04-05 10:01:00', '2026-08-09 10:01:00'),
(1523, 1574, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-07-08 10:00:00', '2026-08-26 10:00:00'),
(1524, 1575, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-28 09:59:00', '2026-08-28 09:59:00'),
(1525, 1576, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-05-16 09:58:00', '2026-08-20 09:58:00'),
(1526, 1577, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-09-28 09:57:00', '2026-08-13 09:57:00'),
(1527, 1578, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-04-26 09:56:00', '2026-08-22 09:56:00'),
(1528, 1579, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-11-07 09:55:00', '2026-08-09 09:55:00'),
(1529, 1580, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-09-02 09:54:00', '2026-08-14 09:54:00'),
(1530, 1581, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-08-31 09:53:00', '2026-08-22 09:53:00'),
(1531, 1582, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-06-14 09:52:00', '2026-08-15 09:52:00'),
(1532, 1583, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-08-07 09:51:00', '2026-08-22 09:51:00'),
(1533, 1584, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-03-23 09:50:00', '2026-08-22 09:50:00'),
(1534, 1585, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-25 09:49:00', '2026-08-25 09:49:00'),
(1535, 1586, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-12-17 09:48:00', '2026-08-25 09:48:00'),
(1536, 1587, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-01-27 09:47:00', '2026-08-29 09:47:00'),
(1537, 1588, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-07-17 09:46:00', '2026-08-24 09:46:00'),
(1538, 1589, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-02-04 09:45:00', '2026-08-25 09:45:00'),
(1539, 1590, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-06-25 09:44:00', '2026-08-22 09:44:00'),
(1540, 1591, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-08-19 09:43:00', '2026-08-19 09:43:00'),
(1541, 1592, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-04-16 09:42:00', '2026-08-25 09:42:00'),
(1542, 1593, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-12-25 09:41:00', '2026-08-27 09:41:00'),
(1543, 1594, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-07-16 09:40:00', '2026-08-11 09:40:00'),
(1544, 1595, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-09-24 09:39:00', '2026-08-17 09:39:00'),
(1545, 1596, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-03-29 09:38:00', '2026-08-15 09:38:00'),
(1546, 1597, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-12-04 09:37:00', '2026-08-14 09:37:00'),
(1547, 1598, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2025-10-29 09:36:00', '2026-08-27 09:36:00'),
(1548, 1599, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-08-09 09:35:00', '2026-08-21 09:35:00'),
(1549, 1600, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-04-16 09:34:00', '2026-08-10 09:34:00'),
(1550, 1601, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, '22:00', '07:00', '2026-07-02 09:33:00', '2026-08-09 09:33:00'),
(1551, 1602, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2025-07-31 09:32:00', '2026-08-16 09:32:00'),
(1552, 1603, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, '22:00', '07:00', '2026-02-19 09:31:00', '2026-08-22 09:31:00');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userId` int(11) NOT NULL,
  `actorUserId` int(11) DEFAULT NULL,
  `type` varchar(50) NOT NULL,
  `category` varchar(50) NOT NULL,
  `title` varchar(160) NOT NULL,
  `message` varchar(500) NOT NULL,
  `isRead` tinyint(1) NOT NULL DEFAULT 0,
  `readAt` datetime DEFAULT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`data`)),
  `deletedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `dedupeKey` varchar(180) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `userId`, `actorUserId`, `type`, `category`, `title`, `message`, `isRead`, `readAt`, `data`, `deletedAt`, `createdAt`, `updatedAt`, `dedupeKey`) VALUES
(1, 1, NULL, 'like', 'Likes', 'Meera liked your profile', 'Your thoughtful travel prompt caught her attention.', 0, NULL, '{\"targetUserId\":5}', NULL, '2026-08-11 18:50:36', '2026-08-11 22:27:22', NULL),
(2, 1, NULL, 'match', 'Matches', 'You matched with Kavya', 'Your shared interest in local cafés started something promising.', 0, NULL, '{\"targetUserId\":3}', NULL, '2026-08-11 18:05:36', '2026-08-11 22:27:22', NULL),
(3, 1, NULL, 'message', 'Messages', 'Ananya sent a message', 'Perfect. I will send the café location tomorrow.', 0, NULL, '{\"conversationId\":2,\"targetUserId\":6}', NULL, '2026-08-11 17:20:36', '2026-08-11 22:27:22', NULL),
(4, 1, NULL, 'super_like', 'Super Likes', 'Your Super Like was delivered', 'Leela can now see that you are especially interested.', 1, '2026-08-11 18:27:21', '{\"targetUserId\":12}', NULL, '2026-08-11 16:35:36', '2026-08-11 22:27:22', NULL),
(5, 1, NULL, 'event_reminder', 'Events', 'Coffee & Conversation is coming up', 'Your registration is confirmed for the upcoming meetup.', 0, NULL, '{\"eventId\":1,\"route\":\"/events\"}', NULL, '2026-08-11 15:50:36', '2026-08-11 22:27:22', NULL),
(6, 1, NULL, 'profile_view', 'Profile Views', 'Neha viewed your profile', 'Your profile made an impression this week.', 1, '2026-08-11 16:27:21', '{\"targetUserId\":13}', NULL, '2026-08-11 15:05:36', '2026-08-11 22:27:22', NULL),
(7, 1, NULL, 'verification', 'Verification', 'Identity verification complete', 'Your verified status is visible on your profile.', 1, '2026-08-11 15:27:21', '{\"route\":\"/kyc-verification\"}', NULL, '2026-08-11 14:20:36', '2026-08-11 22:27:22', NULL),
(8, 1, NULL, 'security', 'Security', 'New development login', 'Your QA account signed in from the local testing environment.', 1, '2026-08-11 14:27:21', '{}', NULL, '2026-08-11 13:35:36', '2026-08-11 22:27:22', NULL),
(9, 1, NULL, 'payment', 'Payments', 'AMORAA Gold is active', 'Your development membership is ready for testing.', 1, '2026-08-11 13:27:21', '{\"route\":\"/subscription\"}', NULL, '2026-08-11 12:50:36', '2026-08-11 22:27:22', NULL),
(10, 1, NULL, 'offer', 'Offers', 'A test-member offer is available', 'Explore the existing membership screen without a real payment.', 0, NULL, '{\"route\":\"/subscription\"}', NULL, '2026-08-11 12:05:36', '2026-08-11 22:27:22', NULL),
(11, 3, NULL, 'security', 'Security', 'Kavya private QA notification', 'This row verifies notification ownership isolation.', 1, '2026-08-13 07:05:46', '{}', NULL, '2026-08-11 18:50:36', '2026-08-13 07:05:46', NULL),
(12, 1, NULL, 'new_match', 'match', 'It\'s a match', 'You and Priya Menon matched.', 1, '2026-08-11 20:55:30', '{\"matchId\":\"3\",\"userId\":\"14\"}', NULL, '2026-08-11 20:54:58', '2026-08-11 20:55:30', 'match:3:1'),
(13, 14, NULL, 'new_match', 'match', 'It\'s a match', 'You have a new match.', 0, NULL, '{\"matchId\":\"3\",\"userId\":\"1\"}', NULL, '2026-08-11 20:54:58', '2026-08-11 20:54:58', 'match:3:14'),
(14, 6, NULL, 'new_message', 'message', 'Aarav Mehta', 'E2E verification message persisted through the API.', 0, NULL, '{\"conversationId\":\"2\",\"messageId\":\"11\"}', NULL, '2026-08-11 20:54:59', '2026-08-11 20:54:59', 'message:11'),
(15, 14, NULL, 'new_match', 'match', 'It\'s a match', 'You have a new match.', 0, NULL, '{\"matchId\":\"4\",\"userId\":\"1\"}', NULL, '2026-08-11 20:55:29', '2026-08-11 20:55:29', 'match:4:14'),
(16, 1, NULL, 'new_match', 'match', 'It\'s a match', 'You and Priya Menon matched.', 1, '2026-08-11 20:55:30', '{\"matchId\":\"4\",\"userId\":\"14\"}', NULL, '2026-08-11 20:55:29', '2026-08-11 20:55:30', 'match:4:1'),
(17, 6, NULL, 'new_message', 'message', 'Aarav Mehta', 'E2E verification message persisted through the API.', 0, NULL, '{\"conversationId\":\"2\",\"messageId\":\"12\"}', NULL, '2026-08-11 20:55:30', '2026-08-11 20:55:30', 'message:12'),
(19, 1, NULL, 'new_match', 'match', 'It\'s a match', 'You and Priya Menon matched.', 1, '2026-08-11 22:27:19', '{\"matchId\":\"5\",\"userId\":\"14\"}', NULL, '2026-08-11 22:27:18', '2026-08-11 22:27:19', 'match:5:1'),
(20, 14, NULL, 'new_match', 'match', 'It\'s a match', 'You have a new match.', 0, NULL, '{\"matchId\":\"5\",\"userId\":\"1\"}', NULL, '2026-08-11 22:27:18', '2026-08-11 22:27:18', 'match:5:14'),
(21, 6, NULL, 'new_message', 'message', 'Aarav Mehta', 'E2E verification message persisted through the API.', 0, NULL, '{\"conversationId\":\"2\",\"messageId\":\"13\"}', NULL, '2026-08-11 22:27:18', '2026-08-11 22:27:18', 'message:13'),
(33, 5, 49, 'rose_received', 'Messages', 'You received a Rose', 'shakti raju sent you a Rose.', 0, NULL, '{\"route\":\"/profile-detail\",\"targetUserId\":\"49\",\"roseTransactionId\":\"2\"}', NULL, '2026-08-12 10:33:18', '2026-08-12 10:33:18', 'rose:2'),
(34, 5, 49, 'new_like', 'Likes', 'You received a like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"49\"}', NULL, '2026-08-12 10:33:24', '2026-08-12 10:33:24', 'reaction:49:5'),
(35, 6, 49, 'new_like', 'Likes', 'You received a like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"49\"}', NULL, '2026-08-12 10:36:11', '2026-08-12 10:36:11', 'reaction:49:6'),
(36, 10, 49, 'new_super_like', 'Super Likes', 'You received a Super Like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"49\"}', NULL, '2026-08-12 10:39:10', '2026-08-12 10:39:10', 'reaction:49:10'),
(37, 10, 49, 'rose_received', 'Messages', 'You received a Rose', 'shakti raju sent you a Rose.', 0, NULL, '{\"route\":\"/profile-detail\",\"targetUserId\":\"49\",\"roseTransactionId\":\"3\"}', NULL, '2026-08-12 10:39:15', '2026-08-12 10:39:15', 'rose:3'),
(38, 11, 49, 'new_super_like', 'Super Likes', 'You received a Super Like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"49\"}', NULL, '2026-08-12 10:41:06', '2026-08-12 10:41:06', 'reaction:49:11'),
(39, 12, 49, 'new_like', 'Likes', 'You received a like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"49\"}', NULL, '2026-08-12 10:42:01', '2026-08-12 10:42:01', 'reaction:49:12'),
(40, 13, 49, 'new_super_like', 'Super Likes', 'You received a Super Like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"49\"}', NULL, '2026-08-12 10:43:59', '2026-08-12 10:43:59', 'reaction:49:13'),
(88, 3, 85, 'new_like', 'Likes', 'You received a like', 'Someone is interested in your profile.', 1, '2026-08-13 07:05:40', '{\"targetUserId\":\"85\"}', NULL, '2026-08-13 06:43:09', '2026-08-13 07:05:40', 'reaction:85:3'),
(89, 5, 85, 'new_super_like', 'Super Likes', 'You received a Super Like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"85\"}', NULL, '2026-08-13 06:44:45', '2026-08-13 06:44:45', 'reaction:85:5'),
(90, 6, 85, 'new_super_like', 'Super Likes', 'You received a Super Like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"85\"}', NULL, '2026-08-13 06:46:25', '2026-08-13 06:46:25', 'reaction:85:6'),
(91, 14, 85, 'new_like', 'Likes', 'You received a like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"85\"}', NULL, '2026-08-13 06:57:50', '2026-08-13 06:57:50', 'reaction:85:14'),
(92, 15, 85, 'new_like', 'Likes', 'You received a like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"85\"}', NULL, '2026-08-13 07:00:05', '2026-08-13 07:00:05', 'reaction:85:15'),
(93, 1, 85, 'new_like', 'Likes', 'You received a like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"85\"}', NULL, '2026-08-13 07:04:19', '2026-08-13 07:04:19', 'reaction:85:1'),
(94, 3, NULL, 'new_match', 'match', 'It\'s a match', 'You and yash andrapiya matched.', 0, NULL, '{\"matchId\":\"18\",\"userId\":\"85\"}', NULL, '2026-08-13 07:06:31', '2026-08-13 07:06:31', 'match:18:3'),
(95, 85, NULL, 'new_match', 'match', 'It\'s a match', 'You have a new match.', 0, NULL, '{\"matchId\":\"18\",\"userId\":\"3\"}', NULL, '2026-08-13 07:06:31', '2026-08-13 07:06:31', 'match:18:85'),
(96, 85, NULL, 'new_message', 'message', 'Kavya Patel', 'Hello', 0, NULL, '{\"conversationId\":\"15\",\"messageId\":\"32\"}', NULL, '2026-08-13 07:07:56', '2026-08-13 07:07:56', 'message:32'),
(97, 85, NULL, 'new_message', 'message', 'Kavya Patel', '😄', 0, NULL, '{\"conversationId\":\"15\",\"messageId\":\"33\"}', NULL, '2026-08-13 07:08:03', '2026-08-13 07:08:03', 'message:33'),
(98, 3, NULL, 'new_message', 'message', 'yash andrapiya', 'Hyy', 0, NULL, '{\"conversationId\":\"15\",\"messageId\":\"34\"}', NULL, '2026-08-13 07:08:37', '2026-08-13 07:08:37', 'message:34'),
(99, 4, 85, 'new_like', 'Likes', 'You received a like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"85\"}', NULL, '2026-08-13 07:08:47', '2026-08-13 07:08:47', 'reaction:85:4'),
(116, 13, 85, 'new_like', 'Likes', 'You received a like', 'Someone is interested in your profile.', 0, NULL, '{\"targetUserId\":\"85\"}', NULL, '2026-08-17 08:01:23', '2026-08-17 08:01:23', 'reaction:85:13'),
(117, 3, 85, 'new_message', 'message', 'yash andrapiya', 'Hello', 0, NULL, '{\"conversationId\":\"15\",\"messageId\":\"37\"}', NULL, '2026-08-17 08:03:07', '2026-08-17 08:03:07', 'message:37'),
(2403, 1461, 1454, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-28 12:00:00', '{\"actorUserId\":1454}', NULL, '2026-08-28 12:00:00', '2026-08-28 12:00:00', 'seed-action-1454-1461'),
(2404, 1496, 1454, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1454}', NULL, '2026-08-23 12:00:00', '2026-08-23 12:00:00', 'seed-action-1454-1496'),
(2405, 1476, 1455, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1455}', NULL, '2026-08-26 11:59:00', '2026-08-26 11:59:00', 'seed-action-1455-1476'),
(2406, 1484, 1456, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-25 11:58:00', '{\"actorUserId\":1456}', NULL, '2026-08-25 11:58:00', '2026-08-25 11:58:00', 'seed-action-1456-1484'),
(2407, 1485, 1457, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1457}', NULL, '2026-08-25 11:57:00', '2026-08-25 11:57:00', 'seed-action-1457-1485'),
(2408, 1520, 1457, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1457}', NULL, '2026-08-20 11:57:00', '2026-08-20 11:57:00', 'seed-action-1457-1520'),
(2409, 1479, 1458, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-26 11:56:00', '{\"actorUserId\":1458}', NULL, '2026-08-26 11:56:00', '2026-08-26 11:56:00', 'seed-action-1458-1479'),
(2410, 1466, 1459, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1459}', NULL, '2026-08-28 11:55:00', '2026-08-28 11:55:00', 'seed-action-1459-1466'),
(2411, 1501, 1459, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1459}', NULL, '2026-08-23 11:55:00', '2026-08-23 11:55:00', 'seed-action-1459-1501'),
(2412, 1536, 1459, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-18 11:55:00', '{\"actorUserId\":1459}', NULL, '2026-08-18 11:55:00', '2026-08-18 11:55:00', 'seed-action-1459-1536'),
(2413, 1516, 1460, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1460}', NULL, '2026-08-21 11:54:00', '2026-08-21 11:54:00', 'seed-action-1460-1516'),
(2414, 1524, 1461, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1461}', NULL, '2026-08-20 11:53:00', '2026-08-20 11:53:00', 'seed-action-1461-1524'),
(2415, 1490, 1462, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1462}', NULL, '2026-08-25 11:52:00', '2026-08-25 11:52:00', 'seed-action-1462-1490'),
(2416, 1470, 1463, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-28 11:51:00', '{\"actorUserId\":1463}', NULL, '2026-08-28 11:51:00', '2026-08-28 11:51:00', 'seed-action-1463-1470'),
(2417, 1478, 1464, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1464}', NULL, '2026-08-27 11:50:00', '2026-08-27 11:50:00', 'seed-action-1464-1478'),
(2418, 1479, 1465, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-27 11:49:00', '{\"actorUserId\":1465}', NULL, '2026-08-27 11:49:00', '2026-08-27 11:49:00', 'seed-action-1465-1479'),
(2419, 1514, 1465, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1465}', NULL, '2026-08-22 11:49:00', '2026-08-22 11:49:00', 'seed-action-1465-1514'),
(2420, 1473, 1466, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1466}', NULL, '2026-08-28 11:48:00', '2026-08-28 11:48:00', 'seed-action-1466-1473'),
(2421, 1543, 1466, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-18 11:48:00', '{\"actorUserId\":1466}', NULL, '2026-08-18 11:48:00', '2026-08-18 11:48:00', 'seed-action-1466-1543'),
(2422, 1495, 1467, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1467}', NULL, '2026-08-25 11:47:00', '2026-08-25 11:47:00', 'seed-action-1467-1495'),
(2423, 1530, 1467, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1467}', NULL, '2026-08-20 11:47:00', '2026-08-20 11:47:00', 'seed-action-1467-1530'),
(2424, 1510, 1468, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-23 11:46:00', '{\"actorUserId\":1468}', NULL, '2026-08-23 11:46:00', '2026-08-23 11:46:00', 'seed-action-1468-1510'),
(2425, 1518, 1469, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1469}', NULL, '2026-08-22 11:45:00', '2026-08-22 11:45:00', 'seed-action-1469-1518'),
(2426, 1484, 1470, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1470}', NULL, '2026-08-27 11:44:00', '2026-08-27 11:44:00', 'seed-action-1470-1484'),
(2427, 1519, 1470, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1470}', NULL, '2026-08-22 11:44:00', '2026-08-22 11:44:00', 'seed-action-1470-1519'),
(2428, 1534, 1471, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-20 11:43:00', '{\"actorUserId\":1471}', NULL, '2026-08-20 11:43:00', '2026-08-20 11:43:00', 'seed-action-1471-1534'),
(2429, 1542, 1472, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1472}', NULL, '2026-08-19 11:42:00', '2026-08-19 11:42:00', 'seed-action-1472-1542'),
(2430, 1508, 1473, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1473}', NULL, '2026-08-24 11:41:00', '2026-08-24 11:41:00', 'seed-action-1473-1508'),
(2431, 1543, 1473, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-19 11:41:00', '{\"actorUserId\":1473}', NULL, '2026-08-19 11:41:00', '2026-08-19 11:41:00', 'seed-action-1473-1543'),
(2432, 1537, 1474, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1474}', NULL, '2026-08-20 11:40:00', '2026-08-20 11:40:00', 'seed-action-1474-1537'),
(2433, 1489, 1475, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1475}', NULL, '2026-08-27 11:39:00', '2026-08-27 11:39:00', 'seed-action-1475-1489'),
(2434, 1524, 1475, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-22 11:39:00', '{\"actorUserId\":1475}', NULL, '2026-08-22 11:39:00', '2026-08-22 11:39:00', 'seed-action-1475-1524'),
(2435, 1559, 1475, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1475}', NULL, '2026-08-17 11:39:00', '2026-08-17 11:39:00', 'seed-action-1475-1559'),
(2436, 1504, 1476, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1476}', NULL, '2026-08-25 11:38:00', '2026-08-25 11:38:00', 'seed-action-1476-1504'),
(2437, 1574, 1476, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-15 11:38:00', '{\"actorUserId\":1476}', NULL, '2026-08-15 11:38:00', '2026-08-15 11:38:00', 'seed-action-1476-1574'),
(2438, 1512, 1477, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1477}', NULL, '2026-08-24 11:37:00', '2026-08-24 11:37:00', 'seed-action-1477-1512'),
(2439, 1582, 1477, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1477}', NULL, '2026-08-14 11:37:00', '2026-08-14 11:37:00', 'seed-action-1477-1582'),
(2440, 1513, 1478, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-24 11:36:00', '{\"actorUserId\":1478}', NULL, '2026-08-24 11:36:00', '2026-08-24 11:36:00', 'seed-action-1478-1513'),
(2441, 1528, 1479, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1479}', NULL, '2026-08-22 11:35:00', '2026-08-22 11:35:00', 'seed-action-1479-1528'),
(2442, 1536, 1480, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-21 11:34:00', '{\"actorUserId\":1480}', NULL, '2026-08-21 11:34:00', '2026-08-21 11:34:00', 'seed-action-1480-1536'),
(2443, 1502, 1481, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1481}', NULL, '2026-08-26 11:33:00', '2026-08-26 11:33:00', 'seed-action-1481-1502'),
(2444, 1537, 1481, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1481}', NULL, '2026-08-21 11:33:00', '2026-08-21 11:33:00', 'seed-action-1481-1537'),
(2445, 1531, 1482, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-22 11:32:00', '{\"actorUserId\":1482}', NULL, '2026-08-22 11:32:00', '2026-08-22 11:32:00', 'seed-action-1482-1531'),
(2446, 1518, 1483, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1483}', NULL, '2026-08-24 11:31:00', '2026-08-24 11:31:00', 'seed-action-1483-1518'),
(2447, 1553, 1483, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1483}', NULL, '2026-08-19 11:31:00', '2026-08-19 11:31:00', 'seed-action-1483-1553'),
(2448, 1498, 1484, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-27 11:30:00', '{\"actorUserId\":1484}', NULL, '2026-08-27 11:30:00', '2026-08-27 11:30:00', 'seed-action-1484-1498'),
(2449, 1568, 1484, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1484}', NULL, '2026-08-17 11:30:00', '2026-08-17 11:30:00', 'seed-action-1484-1568'),
(2450, 1506, 1485, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1485}', NULL, '2026-08-26 11:29:00', '2026-08-26 11:29:00', 'seed-action-1485-1506'),
(2451, 1576, 1485, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1485}', NULL, '2026-08-16 11:29:00', '2026-08-16 11:29:00', 'seed-action-1485-1576'),
(2452, 1507, 1486, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1486}', NULL, '2026-08-26 11:28:00', '2026-08-26 11:28:00', 'seed-action-1486-1507'),
(2453, 1542, 1486, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1486}', NULL, '2026-08-21 11:28:00', '2026-08-21 11:28:00', 'seed-action-1486-1542'),
(2454, 1522, 1487, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-24 11:27:00', '{\"actorUserId\":1487}', NULL, '2026-08-24 11:27:00', '2026-08-24 11:27:00', 'seed-action-1487-1522'),
(2455, 1530, 1488, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1488}', NULL, '2026-08-23 11:26:00', '2026-08-23 11:26:00', 'seed-action-1488-1530'),
(2456, 1496, 1489, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1489}', NULL, '2026-08-28 11:25:00', '2026-08-28 11:25:00', 'seed-action-1489-1496'),
(2457, 1531, 1489, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-23 11:25:00', '{\"actorUserId\":1489}', NULL, '2026-08-23 11:25:00', '2026-08-23 11:25:00', 'seed-action-1489-1531'),
(2458, 1566, 1489, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1489}', NULL, '2026-08-18 11:25:00', '2026-08-18 11:25:00', 'seed-action-1489-1566'),
(2459, 1525, 1490, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1490}', NULL, '2026-08-24 11:24:00', '2026-08-24 11:24:00', 'seed-action-1490-1525'),
(2460, 1512, 1491, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-26 11:23:00', '{\"actorUserId\":1491}', NULL, '2026-08-26 11:23:00', '2026-08-26 11:23:00', 'seed-action-1491-1512'),
(2461, 1547, 1491, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1491}', NULL, '2026-08-21 11:23:00', '2026-08-21 11:23:00', 'seed-action-1491-1547'),
(2462, 1582, 1491, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1491}', NULL, '2026-08-16 11:23:00', '2026-08-16 11:23:00', 'seed-action-1491-1582'),
(2463, 1562, 1492, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-19 11:22:00', '{\"actorUserId\":1492}', NULL, '2026-08-19 11:22:00', '2026-08-19 11:22:00', 'seed-action-1492-1562'),
(2464, 1500, 1493, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1493}', NULL, '2026-08-28 11:21:00', '2026-08-28 11:21:00', 'seed-action-1493-1500'),
(2465, 1570, 1493, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1493}', NULL, '2026-08-18 11:21:00', '2026-08-18 11:21:00', 'seed-action-1493-1570'),
(2466, 1501, 1494, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-28 11:20:00', '{\"actorUserId\":1494}', NULL, '2026-08-28 11:20:00', '2026-08-28 11:20:00', 'seed-action-1494-1501'),
(2467, 1536, 1494, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1494}', NULL, '2026-08-23 11:20:00', '2026-08-23 11:20:00', 'seed-action-1494-1536'),
(2468, 1516, 1495, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1495}', NULL, '2026-08-26 11:19:00', '2026-08-26 11:19:00', 'seed-action-1495-1516'),
(2469, 1524, 1496, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-25 11:18:00', '{\"actorUserId\":1496}', NULL, '2026-08-25 11:18:00', '2026-08-25 11:18:00', 'seed-action-1496-1524'),
(2470, 1525, 1497, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1497}', NULL, '2026-08-25 11:17:00', '2026-08-25 11:17:00', 'seed-action-1497-1525'),
(2471, 1560, 1497, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1497}', NULL, '2026-08-20 11:17:00', '2026-08-20 11:17:00', 'seed-action-1497-1560'),
(2472, 1519, 1498, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-26 11:16:00', '{\"actorUserId\":1498}', NULL, '2026-08-26 11:16:00', '2026-08-26 11:16:00', 'seed-action-1498-1519'),
(2473, 1506, 1499, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1499}', NULL, '2026-08-28 11:15:00', '2026-08-28 11:15:00', 'seed-action-1499-1506'),
(2474, 1541, 1499, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1499}', NULL, '2026-08-23 11:15:00', '2026-08-23 11:15:00', 'seed-action-1499-1541'),
(2475, 1576, 1499, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-18 11:15:00', '{\"actorUserId\":1499}', NULL, '2026-08-18 11:15:00', '2026-08-18 11:15:00', 'seed-action-1499-1576'),
(2476, 1556, 1500, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1500}', NULL, '2026-08-21 11:14:00', '2026-08-21 11:14:00', 'seed-action-1500-1556'),
(2477, 1564, 1501, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1501}', NULL, '2026-08-20 11:13:00', '2026-08-20 11:13:00', 'seed-action-1501-1564'),
(2478, 1530, 1502, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1502}', NULL, '2026-08-25 11:12:00', '2026-08-25 11:12:00', 'seed-action-1502-1530'),
(2479, 1510, 1503, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-28 11:11:00', '{\"actorUserId\":1503}', NULL, '2026-08-28 11:11:00', '2026-08-28 11:11:00', 'seed-action-1503-1510'),
(2480, 1518, 1504, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1504}', NULL, '2026-08-27 11:10:00', '2026-08-27 11:10:00', 'seed-action-1504-1518'),
(2481, 1519, 1505, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-27 11:09:00', '{\"actorUserId\":1505}', NULL, '2026-08-27 11:09:00', '2026-08-27 11:09:00', 'seed-action-1505-1519'),
(2482, 1554, 1505, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1505}', NULL, '2026-08-22 11:09:00', '2026-08-22 11:09:00', 'seed-action-1505-1554'),
(2483, 1513, 1506, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1506}', NULL, '2026-08-28 11:08:00', '2026-08-28 11:08:00', 'seed-action-1506-1513'),
(2484, 1583, 1506, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-18 11:08:00', '{\"actorUserId\":1506}', NULL, '2026-08-18 11:08:00', '2026-08-18 11:08:00', 'seed-action-1506-1583'),
(2485, 1535, 1507, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1507}', NULL, '2026-08-25 11:07:00', '2026-08-25 11:07:00', 'seed-action-1507-1535'),
(2486, 1570, 1507, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1507}', NULL, '2026-08-20 11:07:00', '2026-08-20 11:07:00', 'seed-action-1507-1570'),
(2487, 1550, 1508, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-23 11:06:00', '{\"actorUserId\":1508}', NULL, '2026-08-23 11:06:00', '2026-08-23 11:06:00', 'seed-action-1508-1550'),
(2488, 1558, 1509, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1509}', NULL, '2026-08-22 11:05:00', '2026-08-22 11:05:00', 'seed-action-1509-1558'),
(2489, 1524, 1510, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1510}', NULL, '2026-08-27 11:04:00', '2026-08-27 11:04:00', 'seed-action-1510-1524'),
(2490, 1559, 1510, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1510}', NULL, '2026-08-22 11:04:00', '2026-08-22 11:04:00', 'seed-action-1510-1559'),
(2491, 1574, 1511, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-20 11:03:00', '{\"actorUserId\":1511}', NULL, '2026-08-20 11:03:00', '2026-08-20 11:03:00', 'seed-action-1511-1574'),
(2492, 1582, 1512, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1512}', NULL, '2026-08-19 11:02:00', '2026-08-19 11:02:00', 'seed-action-1512-1582'),
(2493, 1548, 1513, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1513}', NULL, '2026-08-24 11:01:00', '2026-08-24 11:01:00', 'seed-action-1513-1548'),
(2494, 1583, 1513, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-19 11:01:00', '{\"actorUserId\":1513}', NULL, '2026-08-19 11:01:00', '2026-08-19 11:01:00', 'seed-action-1513-1583'),
(2495, 1577, 1514, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1514}', NULL, '2026-08-20 11:00:00', '2026-08-20 11:00:00', 'seed-action-1514-1577'),
(2496, 1529, 1515, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1515}', NULL, '2026-08-27 10:59:00', '2026-08-27 10:59:00', 'seed-action-1515-1529'),
(2497, 1564, 1515, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-22 10:59:00', '{\"actorUserId\":1515}', NULL, '2026-08-22 10:59:00', '2026-08-22 10:59:00', 'seed-action-1515-1564'),
(2498, 1599, 1515, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1515}', NULL, '2026-08-17 10:59:00', '2026-08-17 10:59:00', 'seed-action-1515-1599'),
(2499, 1544, 1516, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1516}', NULL, '2026-08-25 10:58:00', '2026-08-25 10:58:00', 'seed-action-1516-1544'),
(2500, 1464, 1516, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-15 10:58:00', '{\"actorUserId\":1516}', NULL, '2026-08-15 10:58:00', '2026-08-15 10:58:00', 'seed-action-1516-1464'),
(2501, 1552, 1517, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1517}', NULL, '2026-08-24 10:57:00', '2026-08-24 10:57:00', 'seed-action-1517-1552'),
(2502, 1472, 1517, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1517}', NULL, '2026-08-14 10:57:00', '2026-08-14 10:57:00', 'seed-action-1517-1472'),
(2503, 1553, 1518, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-24 10:56:00', '{\"actorUserId\":1518}', NULL, '2026-08-24 10:56:00', '2026-08-24 10:56:00', 'seed-action-1518-1553'),
(2504, 1568, 1519, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1519}', NULL, '2026-08-22 10:55:00', '2026-08-22 10:55:00', 'seed-action-1519-1568'),
(2505, 1576, 1520, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-21 10:54:00', '{\"actorUserId\":1520}', NULL, '2026-08-21 10:54:00', '2026-08-21 10:54:00', 'seed-action-1520-1576'),
(2506, 1542, 1521, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1521}', NULL, '2026-08-26 10:53:00', '2026-08-26 10:53:00', 'seed-action-1521-1542'),
(2507, 1577, 1521, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1521}', NULL, '2026-08-21 10:53:00', '2026-08-21 10:53:00', 'seed-action-1521-1577'),
(2508, 1571, 1522, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-22 10:52:00', '{\"actorUserId\":1522}', NULL, '2026-08-22 10:52:00', '2026-08-22 10:52:00', 'seed-action-1522-1571'),
(2509, 1558, 1523, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1523}', NULL, '2026-08-24 10:51:00', '2026-08-24 10:51:00', 'seed-action-1523-1558'),
(2510, 1593, 1523, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1523}', NULL, '2026-08-19 10:51:00', '2026-08-19 10:51:00', 'seed-action-1523-1593'),
(2511, 1538, 1524, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-27 10:50:00', '{\"actorUserId\":1524}', NULL, '2026-08-27 10:50:00', '2026-08-27 10:50:00', 'seed-action-1524-1538'),
(2512, 1458, 1524, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1524}', NULL, '2026-08-17 10:50:00', '2026-08-17 10:50:00', 'seed-action-1524-1458'),
(2513, 1546, 1525, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1525}', NULL, '2026-08-26 10:49:00', '2026-08-26 10:49:00', 'seed-action-1525-1546'),
(2514, 1466, 1525, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1525}', NULL, '2026-08-16 10:49:00', '2026-08-16 10:49:00', 'seed-action-1525-1466'),
(2515, 1547, 1526, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1526}', NULL, '2026-08-26 10:48:00', '2026-08-26 10:48:00', 'seed-action-1526-1547'),
(2516, 1582, 1526, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1526}', NULL, '2026-08-21 10:48:00', '2026-08-21 10:48:00', 'seed-action-1526-1582'),
(2517, 1562, 1527, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-24 10:47:00', '{\"actorUserId\":1527}', NULL, '2026-08-24 10:47:00', '2026-08-24 10:47:00', 'seed-action-1527-1562'),
(2518, 1570, 1528, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1528}', NULL, '2026-08-23 10:46:00', '2026-08-23 10:46:00', 'seed-action-1528-1570'),
(2519, 1536, 1529, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1529}', NULL, '2026-08-28 10:45:00', '2026-08-28 10:45:00', 'seed-action-1529-1536'),
(2520, 1571, 1529, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-23 10:45:00', '{\"actorUserId\":1529}', NULL, '2026-08-23 10:45:00', '2026-08-23 10:45:00', 'seed-action-1529-1571'),
(2521, 1456, 1529, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1529}', NULL, '2026-08-18 10:45:00', '2026-08-18 10:45:00', 'seed-action-1529-1456'),
(2522, 1565, 1530, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1530}', NULL, '2026-08-24 10:44:00', '2026-08-24 10:44:00', 'seed-action-1530-1565'),
(2523, 1552, 1531, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-26 10:43:00', '{\"actorUserId\":1531}', NULL, '2026-08-26 10:43:00', '2026-08-26 10:43:00', 'seed-action-1531-1552'),
(2524, 1587, 1531, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1531}', NULL, '2026-08-21 10:43:00', '2026-08-21 10:43:00', 'seed-action-1531-1587'),
(2525, 1472, 1531, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1531}', NULL, '2026-08-16 10:43:00', '2026-08-16 10:43:00', 'seed-action-1531-1472'),
(2526, 1602, 1532, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-19 10:42:00', '{\"actorUserId\":1532}', NULL, '2026-08-19 10:42:00', '2026-08-19 10:42:00', 'seed-action-1532-1602'),
(2527, 1540, 1533, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1533}', NULL, '2026-08-28 10:41:00', '2026-08-28 10:41:00', 'seed-action-1533-1540'),
(2528, 1460, 1533, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1533}', NULL, '2026-08-18 10:41:00', '2026-08-18 10:41:00', 'seed-action-1533-1460'),
(2529, 1541, 1534, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-28 10:40:00', '{\"actorUserId\":1534}', NULL, '2026-08-28 10:40:00', '2026-08-28 10:40:00', 'seed-action-1534-1541'),
(2530, 1576, 1534, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1534}', NULL, '2026-08-23 10:40:00', '2026-08-23 10:40:00', 'seed-action-1534-1576'),
(2531, 1556, 1535, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1535}', NULL, '2026-08-26 10:39:00', '2026-08-26 10:39:00', 'seed-action-1535-1556'),
(2532, 1564, 1536, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-25 10:38:00', '{\"actorUserId\":1536}', NULL, '2026-08-25 10:38:00', '2026-08-25 10:38:00', 'seed-action-1536-1564'),
(2533, 1565, 1537, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1537}', NULL, '2026-08-25 10:37:00', '2026-08-25 10:37:00', 'seed-action-1537-1565'),
(2534, 1600, 1537, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1537}', NULL, '2026-08-20 10:37:00', '2026-08-20 10:37:00', 'seed-action-1537-1600'),
(2535, 1559, 1538, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-26 10:36:00', '{\"actorUserId\":1538}', NULL, '2026-08-26 10:36:00', '2026-08-26 10:36:00', 'seed-action-1538-1559'),
(2536, 1546, 1539, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1539}', NULL, '2026-08-28 10:35:00', '2026-08-28 10:35:00', 'seed-action-1539-1546'),
(2537, 1581, 1539, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1539}', NULL, '2026-08-23 10:35:00', '2026-08-23 10:35:00', 'seed-action-1539-1581'),
(2538, 1466, 1539, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-18 10:35:00', '{\"actorUserId\":1539}', NULL, '2026-08-18 10:35:00', '2026-08-18 10:35:00', 'seed-action-1539-1466'),
(2539, 1596, 1540, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1540}', NULL, '2026-08-21 10:34:00', '2026-08-21 10:34:00', 'seed-action-1540-1596'),
(2540, 1454, 1541, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1541}', NULL, '2026-08-20 10:33:00', '2026-08-20 10:33:00', 'seed-action-1541-1454'),
(2541, 1570, 1542, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1542}', NULL, '2026-08-25 10:32:00', '2026-08-25 10:32:00', 'seed-action-1542-1570'),
(2542, 1550, 1543, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-28 10:31:00', '{\"actorUserId\":1543}', NULL, '2026-08-28 10:31:00', '2026-08-28 10:31:00', 'seed-action-1543-1550'),
(2543, 1558, 1544, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1544}', NULL, '2026-08-27 10:30:00', '2026-08-27 10:30:00', 'seed-action-1544-1558'),
(2544, 1559, 1545, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-27 10:29:00', '{\"actorUserId\":1545}', NULL, '2026-08-27 10:29:00', '2026-08-27 10:29:00', 'seed-action-1545-1559'),
(2545, 1594, 1545, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1545}', NULL, '2026-08-22 10:29:00', '2026-08-22 10:29:00', 'seed-action-1545-1594'),
(2546, 1553, 1546, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1546}', NULL, '2026-08-28 10:28:00', '2026-08-28 10:28:00', 'seed-action-1546-1553'),
(2547, 1473, 1546, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-18 10:28:00', '{\"actorUserId\":1546}', NULL, '2026-08-18 10:28:00', '2026-08-18 10:28:00', 'seed-action-1546-1473'),
(2548, 1575, 1547, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1547}', NULL, '2026-08-25 10:27:00', '2026-08-25 10:27:00', 'seed-action-1547-1575'),
(2549, 1460, 1547, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1547}', NULL, '2026-08-20 10:27:00', '2026-08-20 10:27:00', 'seed-action-1547-1460'),
(2550, 1590, 1548, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-23 10:26:00', '{\"actorUserId\":1548}', NULL, '2026-08-23 10:26:00', '2026-08-23 10:26:00', 'seed-action-1548-1590'),
(2551, 1598, 1549, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1549}', NULL, '2026-08-22 10:25:00', '2026-08-22 10:25:00', 'seed-action-1549-1598'),
(2552, 1564, 1550, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1550}', NULL, '2026-08-27 10:24:00', '2026-08-27 10:24:00', 'seed-action-1550-1564'),
(2553, 1599, 1550, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1550}', NULL, '2026-08-22 10:24:00', '2026-08-22 10:24:00', 'seed-action-1550-1599'),
(2554, 1464, 1551, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-20 10:23:00', '{\"actorUserId\":1551}', NULL, '2026-08-20 10:23:00', '2026-08-20 10:23:00', 'seed-action-1551-1464'),
(2555, 1472, 1552, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1552}', NULL, '2026-08-19 10:22:00', '2026-08-19 10:22:00', 'seed-action-1552-1472'),
(2556, 1588, 1553, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1553}', NULL, '2026-08-24 10:21:00', '2026-08-24 10:21:00', 'seed-action-1553-1588'),
(2557, 1473, 1553, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-19 10:21:00', '{\"actorUserId\":1553}', NULL, '2026-08-19 10:21:00', '2026-08-19 10:21:00', 'seed-action-1553-1473'),
(2558, 1467, 1554, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1554}', NULL, '2026-08-20 10:20:00', '2026-08-20 10:20:00', 'seed-action-1554-1467'),
(2559, 1569, 1555, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1555}', NULL, '2026-08-27 10:19:00', '2026-08-27 10:19:00', 'seed-action-1555-1569'),
(2560, 1454, 1555, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-22 10:19:00', '{\"actorUserId\":1555}', NULL, '2026-08-22 10:19:00', '2026-08-22 10:19:00', 'seed-action-1555-1454'),
(2561, 1489, 1555, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1555}', NULL, '2026-08-17 10:19:00', '2026-08-17 10:19:00', 'seed-action-1555-1489'),
(2562, 1584, 1556, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1556}', NULL, '2026-08-25 10:18:00', '2026-08-25 10:18:00', 'seed-action-1556-1584'),
(2563, 1504, 1556, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-15 10:18:00', '{\"actorUserId\":1556}', NULL, '2026-08-15 10:18:00', '2026-08-15 10:18:00', 'seed-action-1556-1504'),
(2564, 1592, 1557, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1557}', NULL, '2026-08-24 10:17:00', '2026-08-24 10:17:00', 'seed-action-1557-1592'),
(2565, 1512, 1557, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1557}', NULL, '2026-08-14 10:17:00', '2026-08-14 10:17:00', 'seed-action-1557-1512'),
(2566, 1593, 1558, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-24 10:16:00', '{\"actorUserId\":1558}', NULL, '2026-08-24 10:16:00', '2026-08-24 10:16:00', 'seed-action-1558-1593'),
(2567, 1458, 1559, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1559}', NULL, '2026-08-22 10:15:00', '2026-08-22 10:15:00', 'seed-action-1559-1458'),
(2568, 1466, 1560, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-21 10:14:00', '{\"actorUserId\":1560}', NULL, '2026-08-21 10:14:00', '2026-08-21 10:14:00', 'seed-action-1560-1466'),
(2569, 1582, 1561, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1561}', NULL, '2026-08-26 10:13:00', '2026-08-26 10:13:00', 'seed-action-1561-1582'),
(2570, 1467, 1561, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1561}', NULL, '2026-08-21 10:13:00', '2026-08-21 10:13:00', 'seed-action-1561-1467'),
(2571, 1461, 1562, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-22 10:12:00', '{\"actorUserId\":1562}', NULL, '2026-08-22 10:12:00', '2026-08-22 10:12:00', 'seed-action-1562-1461'),
(2572, 1598, 1563, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1563}', NULL, '2026-08-24 10:11:00', '2026-08-24 10:11:00', 'seed-action-1563-1598'),
(2573, 1483, 1563, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1563}', NULL, '2026-08-19 10:11:00', '2026-08-19 10:11:00', 'seed-action-1563-1483'),
(2574, 1578, 1564, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-27 10:10:00', '{\"actorUserId\":1564}', NULL, '2026-08-27 10:10:00', '2026-08-27 10:10:00', 'seed-action-1564-1578'),
(2575, 1498, 1564, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1564}', NULL, '2026-08-17 10:10:00', '2026-08-17 10:10:00', 'seed-action-1564-1498'),
(2576, 1586, 1565, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1565}', NULL, '2026-08-26 10:09:00', '2026-08-26 10:09:00', 'seed-action-1565-1586'),
(2577, 1506, 1565, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1565}', NULL, '2026-08-16 10:09:00', '2026-08-16 10:09:00', 'seed-action-1565-1506'),
(2578, 1587, 1566, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1566}', NULL, '2026-08-26 10:08:00', '2026-08-26 10:08:00', 'seed-action-1566-1587'),
(2579, 1472, 1566, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1566}', NULL, '2026-08-21 10:08:00', '2026-08-21 10:08:00', 'seed-action-1566-1472'),
(2580, 1602, 1567, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-24 10:07:00', '{\"actorUserId\":1567}', NULL, '2026-08-24 10:07:00', '2026-08-24 10:07:00', 'seed-action-1567-1602'),
(2581, 1460, 1568, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1568}', NULL, '2026-08-23 10:06:00', '2026-08-23 10:06:00', 'seed-action-1568-1460'),
(2582, 1576, 1569, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1569}', NULL, '2026-08-28 10:05:00', '2026-08-28 10:05:00', 'seed-action-1569-1576'),
(2583, 1461, 1569, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-23 10:05:00', '{\"actorUserId\":1569}', NULL, '2026-08-23 10:05:00', '2026-08-23 10:05:00', 'seed-action-1569-1461'),
(2584, 1496, 1569, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1569}', NULL, '2026-08-18 10:05:00', '2026-08-18 10:05:00', 'seed-action-1569-1496'),
(2585, 1455, 1570, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1570}', NULL, '2026-08-24 10:04:00', '2026-08-24 10:04:00', 'seed-action-1570-1455'),
(2586, 1592, 1571, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-26 10:03:00', '{\"actorUserId\":1571}', NULL, '2026-08-26 10:03:00', '2026-08-26 10:03:00', 'seed-action-1571-1592'),
(2587, 1477, 1571, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1571}', NULL, '2026-08-21 10:03:00', '2026-08-21 10:03:00', 'seed-action-1571-1477'),
(2588, 1512, 1571, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1571}', NULL, '2026-08-16 10:03:00', '2026-08-16 10:03:00', 'seed-action-1571-1512'),
(2589, 1492, 1572, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-19 10:02:00', '{\"actorUserId\":1572}', NULL, '2026-08-19 10:02:00', '2026-08-19 10:02:00', 'seed-action-1572-1492'),
(2590, 1580, 1573, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1573}', NULL, '2026-08-28 10:01:00', '2026-08-28 10:01:00', 'seed-action-1573-1580'),
(2591, 1500, 1573, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1573}', NULL, '2026-08-18 10:01:00', '2026-08-18 10:01:00', 'seed-action-1573-1500'),
(2592, 1581, 1574, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-28 10:00:00', '{\"actorUserId\":1574}', NULL, '2026-08-28 10:00:00', '2026-08-28 10:00:00', 'seed-action-1574-1581'),
(2593, 1466, 1574, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1574}', NULL, '2026-08-23 10:00:00', '2026-08-23 10:00:00', 'seed-action-1574-1466'),
(2594, 1596, 1575, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1575}', NULL, '2026-08-26 09:59:00', '2026-08-26 09:59:00', 'seed-action-1575-1596'),
(2595, 1454, 1576, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-25 09:58:00', '{\"actorUserId\":1576}', NULL, '2026-08-25 09:58:00', '2026-08-25 09:58:00', 'seed-action-1576-1454');
INSERT INTO `notifications` (`id`, `userId`, `actorUserId`, `type`, `category`, `title`, `message`, `isRead`, `readAt`, `data`, `deletedAt`, `createdAt`, `updatedAt`, `dedupeKey`) VALUES
(2596, 1455, 1577, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1577}', NULL, '2026-08-25 09:57:00', '2026-08-25 09:57:00', 'seed-action-1577-1455'),
(2597, 1490, 1577, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1577}', NULL, '2026-08-20 09:57:00', '2026-08-20 09:57:00', 'seed-action-1577-1490'),
(2598, 1599, 1578, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-26 09:56:00', '{\"actorUserId\":1578}', NULL, '2026-08-26 09:56:00', '2026-08-26 09:56:00', 'seed-action-1578-1599'),
(2599, 1586, 1579, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1579}', NULL, '2026-08-28 09:55:00', '2026-08-28 09:55:00', 'seed-action-1579-1586'),
(2600, 1471, 1579, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1579}', NULL, '2026-08-23 09:55:00', '2026-08-23 09:55:00', 'seed-action-1579-1471'),
(2601, 1506, 1579, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-18 09:55:00', '{\"actorUserId\":1579}', NULL, '2026-08-18 09:55:00', '2026-08-18 09:55:00', 'seed-action-1579-1506'),
(2602, 1486, 1580, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1580}', NULL, '2026-08-21 09:54:00', '2026-08-21 09:54:00', 'seed-action-1580-1486'),
(2603, 1494, 1581, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1581}', NULL, '2026-08-20 09:53:00', '2026-08-20 09:53:00', 'seed-action-1581-1494'),
(2604, 1460, 1582, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1582}', NULL, '2026-08-25 09:52:00', '2026-08-25 09:52:00', 'seed-action-1582-1460'),
(2605, 1590, 1583, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-28 09:51:00', '{\"actorUserId\":1583}', NULL, '2026-08-28 09:51:00', '2026-08-28 09:51:00', 'seed-action-1583-1590'),
(2606, 1598, 1584, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1584}', NULL, '2026-08-27 09:50:00', '2026-08-27 09:50:00', 'seed-action-1584-1598'),
(2607, 1599, 1585, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-27 09:49:00', '{\"actorUserId\":1585}', NULL, '2026-08-27 09:49:00', '2026-08-27 09:49:00', 'seed-action-1585-1599'),
(2608, 1484, 1585, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1585}', NULL, '2026-08-22 09:49:00', '2026-08-22 09:49:00', 'seed-action-1585-1484'),
(2609, 1593, 1586, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1586}', NULL, '2026-08-28 09:48:00', '2026-08-28 09:48:00', 'seed-action-1586-1593'),
(2610, 1513, 1586, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-18 09:48:00', '{\"actorUserId\":1586}', NULL, '2026-08-18 09:48:00', '2026-08-18 09:48:00', 'seed-action-1586-1513'),
(2611, 1465, 1587, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1587}', NULL, '2026-08-25 09:47:00', '2026-08-25 09:47:00', 'seed-action-1587-1465'),
(2612, 1500, 1587, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1587}', NULL, '2026-08-20 09:47:00', '2026-08-20 09:47:00', 'seed-action-1587-1500'),
(2613, 1480, 1588, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-23 09:46:00', '{\"actorUserId\":1588}', NULL, '2026-08-23 09:46:00', '2026-08-23 09:46:00', 'seed-action-1588-1480'),
(2614, 1488, 1589, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1589}', NULL, '2026-08-22 09:45:00', '2026-08-22 09:45:00', 'seed-action-1589-1488'),
(2615, 1454, 1590, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1590}', NULL, '2026-08-27 09:44:00', '2026-08-27 09:44:00', 'seed-action-1590-1454'),
(2616, 1489, 1590, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1590}', NULL, '2026-08-22 09:44:00', '2026-08-22 09:44:00', 'seed-action-1590-1489'),
(2617, 1504, 1591, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-20 09:43:00', '{\"actorUserId\":1591}', NULL, '2026-08-20 09:43:00', '2026-08-20 09:43:00', 'seed-action-1591-1504'),
(2618, 1512, 1592, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1592}', NULL, '2026-08-19 09:42:00', '2026-08-19 09:42:00', 'seed-action-1592-1512'),
(2619, 1478, 1593, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1593}', NULL, '2026-08-24 09:41:00', '2026-08-24 09:41:00', 'seed-action-1593-1478'),
(2620, 1513, 1593, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-19 09:41:00', '{\"actorUserId\":1593}', NULL, '2026-08-19 09:41:00', '2026-08-19 09:41:00', 'seed-action-1593-1513'),
(2621, 1507, 1594, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1594}', NULL, '2026-08-20 09:40:00', '2026-08-20 09:40:00', 'seed-action-1594-1507'),
(2622, 1459, 1595, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1595}', NULL, '2026-08-27 09:39:00', '2026-08-27 09:39:00', 'seed-action-1595-1459'),
(2623, 1494, 1595, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-22 09:39:00', '{\"actorUserId\":1595}', NULL, '2026-08-22 09:39:00', '2026-08-22 09:39:00', 'seed-action-1595-1494'),
(2624, 1529, 1595, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1595}', NULL, '2026-08-17 09:39:00', '2026-08-17 09:39:00', 'seed-action-1595-1529'),
(2625, 1474, 1596, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1596}', NULL, '2026-08-25 09:38:00', '2026-08-25 09:38:00', 'seed-action-1596-1474'),
(2626, 1544, 1596, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-15 09:38:00', '{\"actorUserId\":1596}', NULL, '2026-08-15 09:38:00', '2026-08-15 09:38:00', 'seed-action-1596-1544'),
(2627, 1482, 1597, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1597}', NULL, '2026-08-24 09:37:00', '2026-08-24 09:37:00', 'seed-action-1597-1482'),
(2628, 1552, 1597, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1597}', NULL, '2026-08-14 09:37:00', '2026-08-14 09:37:00', 'seed-action-1597-1552'),
(2629, 1483, 1598, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-24 09:36:00', '{\"actorUserId\":1598}', NULL, '2026-08-24 09:36:00', '2026-08-24 09:36:00', 'seed-action-1598-1483'),
(2630, 1498, 1599, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1599}', NULL, '2026-08-22 09:35:00', '2026-08-22 09:35:00', 'seed-action-1599-1498'),
(2631, 1506, 1600, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-21 09:34:00', '{\"actorUserId\":1600}', NULL, '2026-08-21 09:34:00', '2026-08-21 09:34:00', 'seed-action-1600-1506'),
(2632, 1472, 1601, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1601}', NULL, '2026-08-26 09:33:00', '2026-08-26 09:33:00', 'seed-action-1601-1472'),
(2633, 1507, 1601, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1601}', NULL, '2026-08-21 09:33:00', '2026-08-21 09:33:00', 'seed-action-1601-1507'),
(2634, 1501, 1602, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-22 09:32:00', '{\"actorUserId\":1602}', NULL, '2026-08-22 09:32:00', '2026-08-22 09:32:00', 'seed-action-1602-1501'),
(2635, 1488, 1603, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1603}', NULL, '2026-08-24 09:31:00', '2026-08-24 09:31:00', 'seed-action-1603-1488'),
(2636, 1523, 1603, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1603}', NULL, '2026-08-19 09:31:00', '2026-08-19 09:31:00', 'seed-action-1603-1523'),
(2637, 1456, 1454, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-15 12:00:00', '{\"actorUserId\":1454}', NULL, '2026-08-15 12:00:00', '2026-08-15 12:00:00', 'seed-action-1454-1456'),
(2638, 1454, 1460, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1460}', NULL, '2026-08-26 12:00:00', '2026-08-26 12:00:00', 'seed-action-1460-1454'),
(2639, 1454, 1465, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1465}', NULL, '2026-08-21 12:00:00', '2026-08-21 12:00:00', 'seed-action-1465-1454'),
(2640, 1454, 1470, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1470}', NULL, '2026-08-16 12:00:00', '2026-08-16 12:00:00', 'seed-action-1470-1454'),
(2641, 1454, 1475, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-11 12:00:00', '{\"actorUserId\":1475}', NULL, '2026-08-11 12:00:00', '2026-08-11 12:00:00', 'seed-action-1475-1454'),
(2642, 1454, 1480, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1480}', NULL, '2026-08-06 12:00:00', '2026-08-06 12:00:00', 'seed-action-1480-1454'),
(2643, 1454, 1485, 'super_like', 'matches', 'A new Super Like', 'Someone sent you a Super Like.', 0, NULL, '{\"actorUserId\":1485}', NULL, '2026-08-01 12:00:00', '2026-08-01 12:00:00', 'seed-action-1485-1454'),
(2644, 1454, 1490, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1490}', NULL, '2026-08-26 12:00:00', '2026-08-26 12:00:00', 'seed-action-1490-1454'),
(2645, 1454, 1495, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-21 12:00:00', '{\"actorUserId\":1495}', NULL, '2026-08-21 12:00:00', '2026-08-21 12:00:00', 'seed-action-1495-1454'),
(2646, 1454, 1500, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1500}', NULL, '2026-08-16 12:00:00', '2026-08-16 12:00:00', 'seed-action-1500-1454'),
(2647, 1454, 1505, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1505}', NULL, '2026-08-11 12:00:00', '2026-08-11 12:00:00', 'seed-action-1505-1454'),
(2648, 1454, 1510, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1510}', NULL, '2026-08-06 12:00:00', '2026-08-06 12:00:00', 'seed-action-1510-1454'),
(2649, 1454, 1515, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-01 12:00:00', '{\"actorUserId\":1515}', NULL, '2026-08-01 12:00:00', '2026-08-01 12:00:00', 'seed-action-1515-1454'),
(2650, 1463, 1464, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1464}', NULL, '2026-08-20 12:00:00', '2026-08-20 12:00:00', 'seed-action-1464-1463'),
(2651, 1482, 1481, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1481}', NULL, '2026-08-02 12:00:00', '2026-08-02 12:00:00', 'seed-action-1481-1482'),
(2652, 1493, 1494, 'super_like', 'matches', 'A new Super Like', 'Someone sent you a Super Like.', 0, NULL, '{\"actorUserId\":1494}', NULL, '2026-07-21 12:00:00', '2026-07-21 12:00:00', 'seed-action-1494-1493'),
(2653, 1512, 1511, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-07-03 12:00:00', '{\"actorUserId\":1511}', NULL, '2026-07-03 12:00:00', '2026-07-03 12:00:00', 'seed-action-1511-1512'),
(2654, 1523, 1524, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1524}', NULL, '2026-06-21 12:00:00', '2026-06-21 12:00:00', 'seed-action-1524-1523'),
(2655, 1542, 1541, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1541}', NULL, '2026-06-03 12:00:00', '2026-06-03 12:00:00', 'seed-action-1541-1542'),
(2656, 1553, 1554, 'super_like', 'matches', 'A new Super Like', 'Someone sent you a Super Like.', 0, NULL, '{\"actorUserId\":1554}', NULL, '2026-08-20 12:00:00', '2026-08-20 12:00:00', 'seed-action-1554-1553'),
(2657, 1572, 1571, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 1, '2026-08-02 12:00:00', '{\"actorUserId\":1571}', NULL, '2026-08-02 12:00:00', '2026-08-02 12:00:00', 'seed-action-1571-1572'),
(2658, 1583, 1584, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1584}', NULL, '2026-07-21 12:00:00', '2026-07-21 12:00:00', 'seed-action-1584-1583'),
(2659, 1602, 1601, 'like', 'matches', 'Someone likes you', 'Someone new liked your profile.', 0, NULL, '{\"actorUserId\":1601}', NULL, '2026-07-03 12:00:00', '2026-07-03 12:00:00', 'seed-action-1601-1602');

-- --------------------------------------------------------

--
-- Table structure for table `onboardingprofiles`
--

CREATE TABLE `onboardingprofiles` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `birthDate` date DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `customGender` varchar(255) NOT NULL DEFAULT '',
  `interestedIn` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`interestedIn`)),
  `relationshipGoals` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`relationshipGoals`)),
  `city` varchar(255) DEFAULT NULL,
  `preferredDistance` int(11) NOT NULL DEFAULT 50,
  `profession` varchar(255) DEFAULT NULL,
  `company` varchar(255) DEFAULT NULL,
  `education` varchar(255) DEFAULT NULL,
  `bio` text DEFAULT NULL,
  `hometown` varchar(255) NOT NULL DEFAULT '',
  `interests` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`interests`)),
  `lifestyle` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`lifestyle`)),
  `prompts` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`prompts`)),
  `pronouns` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`pronouns`)),
  `sexuality` varchar(255) NOT NULL DEFAULT '',
  `valuedQualities` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`valuedQualities`)),
  `loveLanguages` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`loveLanguages`)),
  `preferredTalkingHours` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`preferredTalkingHours`)),
  `photos` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`photos`)),
  `primaryPhotoIndex` int(11) NOT NULL DEFAULT 0,
  `height` varchar(255) DEFAULT NULL,
  `smoking` varchar(255) DEFAULT NULL,
  `drinking` varchar(255) DEFAULT NULL,
  `weed` varchar(255) DEFAULT NULL,
  `community` varchar(255) DEFAULT NULL,
  `religion` varchar(255) DEFAULT NULL,
  `languages` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`languages`)),
  `stage` enum('age','gender','interestedIn','relationshipGoal','location','starterProfile','profileCompletion','photos','complete') NOT NULL DEFAULT 'age',
  `onboardingCompleted` tinyint(1) NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `communicationStyle` enum('frequent_texting','occasional_texting','calls','voice_notes','deep_conversations','light_fun_conversations') DEFAULT NULL,
  `iceBreaker` varchar(280) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `onboardingprofiles`
--

INSERT INTO `onboardingprofiles` (`id`, `userId`, `birthDate`, `gender`, `customGender`, `interestedIn`, `relationshipGoals`, `city`, `preferredDistance`, `profession`, `company`, `education`, `bio`, `hometown`, `interests`, `lifestyle`, `prompts`, `pronouns`, `sexuality`, `valuedQualities`, `loveLanguages`, `preferredTalkingHours`, `photos`, `primaryPhotoIndex`, `height`, `smoking`, `drinking`, `weed`, `community`, `religion`, `languages`, `stage`, `onboardingCompleted`, `createdAt`, `updatedAt`, `communicationStyle`, `iceBreaker`) VALUES
(1, 1, '1994-08-18', 'Male', '', '[\"Female\"]', '[\"Long-term relationship\"]', 'Ahmedabad', 80, 'Product Designer', 'Studio Meridian', 'NID Ahmedabad', 'Aarav values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Ahmedabad', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Cooking\"]', '{\"Height\":\"178\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Hindu\",\"Exercise\":\"Three times a week\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Open to pets\",\"Food preference\":\"Everything in moderation\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"He/Him\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/aarav-primary.png\",\"/uploads/e2e-test/aarav-gallery.jpg\"]', 0, '178', 'Never', 'Socially', 'Never', 'Gujarati', 'Hindu', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'deep_conversations', 'What is one small ritual that makes your week better?'),
(2, 2, '1997-02-11', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 80, 'Architect', 'Civic Labs', 'CEPT University', 'Diya values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Vadodara', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Photography\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Spiritual\",\"Exercise\":\"Yoga and walking\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Dog person\",\"Food preference\":\"Vegetarian\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/diya-primary.png\",\"/uploads/e2e-test/diya-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Spiritual', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'calls', 'What is one small ritual that makes your week better?'),
(3, 3, '1996-06-24', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 80, 'Brand Strategist', 'Sahaj Collective', 'MICA', 'Kavya values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Surat', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Cooking\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Hindu\",\"Exercise\":\"Three times a week\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Open to pets\",\"Food preference\":\"Everything in moderation\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/kavya-primary.png\",\"/uploads/e2e-test/kavya-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Hindu', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'voice_notes', 'What is one small ritual that makes your week better?'),
(4, 4, '1998-01-09', 'Female', '', '[\"Male\"]', '[\"Long-term relationship\"]', 'Vadodara', 80, 'Urban Planner', 'Studio Meridian', 'CEPT University', 'Riya values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Kochi', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Photography\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Spiritual\",\"Exercise\":\"Yoga and walking\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Dog person\",\"Food preference\":\"Vegetarian\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/riya-primary.png\",\"/uploads/e2e-test/riya-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Spiritual', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'deep_conversations', 'What is one small ritual that makes your week better?'),
(5, 5, '1995-11-03', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 80, 'Clinical Psychologist', 'Civic Labs', 'Gujarat University', 'Meera values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Ahmedabad', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Cooking\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Hindu\",\"Exercise\":\"Three times a week\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Open to pets\",\"Food preference\":\"Everything in moderation\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/meera-primary.png\",\"/uploads/e2e-test/meera-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Hindu', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'calls', 'What is one small ritual that makes your week better?'),
(6, 6, '1994-04-27', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 80, 'Documentary Filmmaker', 'Sahaj Collective', 'FTII', 'Ananya values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Vadodara', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Photography\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Spiritual\",\"Exercise\":\"Yoga and walking\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Dog person\",\"Food preference\":\"Vegetarian\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/ananya-primary.png\",\"/uploads/e2e-test/ananya-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Spiritual', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'voice_notes', 'What is one small ritual that makes your week better?'),
(7, 7, '2000-09-15', 'Female', '', '[\"Male\"]', '[]', NULL, 80, NULL, NULL, NULL, NULL, '', '[]', '{}', '{}', '[\"She/Her\"]', 'Straight', '[]', '[]', '[]', '[\"/uploads/e2e-test/nisha-primary.png\",\"/uploads/e2e-test/nisha-gallery.png\"]', 0, NULL, NULL, NULL, NULL, NULL, NULL, '[]', 'starterProfile', 0, '2026-08-11 18:50:36', '2026-08-11 22:27:21', NULL, ''),
(8, 8, '1999-12-02', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 80, 'Research Associate', 'Civic Labs', 'Ahmedabad University', 'Isha values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Kochi', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Photography\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Spiritual\",\"Exercise\":\"Yoga and walking\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Dog person\",\"Food preference\":\"Vegetarian\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/isha-primary.png\",\"/uploads/e2e-test/isha-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Spiritual', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'calls', 'What is one small ritual that makes your week better?'),
(9, 9, '1993-03-19', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 80, 'Hospitality Consultant', 'Sahaj Collective', 'IHM Ahmedabad', 'Sara values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Ahmedabad', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Cooking\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Hindu\",\"Exercise\":\"Three times a week\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Open to pets\",\"Food preference\":\"Everything in moderation\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/sara-primary.png\",\"/uploads/e2e-test/sara-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Hindu', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'voice_notes', 'What is one small ritual that makes your week better?'),
(10, 10, '1996-07-30', 'Female', '', '[\"Male\"]', '[\"Long-term relationship\"]', 'Ahmedabad', 80, 'Content Producer', 'Studio Meridian', 'St. Xavier’s College', 'Tara values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Vadodara', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Photography\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Spiritual\",\"Exercise\":\"Yoga and walking\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Dog person\",\"Food preference\":\"Vegetarian\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/tara-primary.png\",\"/uploads/e2e-test/tara-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Spiritual', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'deep_conversations', 'What is one small ritual that makes your week better?'),
(11, 11, '1990-10-12', 'Male', '', '[\"Female\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 80, 'Community Curator', 'Civic Labs', 'IIM Ahmedabad', 'Vihaan values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Surat', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Cooking\"]', '{\"Height\":\"178\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Hindu\",\"Exercise\":\"Three times a week\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Open to pets\",\"Food preference\":\"Everything in moderation\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"He/Him\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/vihaan-primary.png\",\"/uploads/e2e-test/vihaan-gallery.jpg\"]', 0, '178', 'Never', 'Socially', 'Never', 'Gujarati', 'Hindu', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'calls', 'What is one small ritual that makes your week better?'),
(12, 12, '1997-05-20', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Gandhinagar', 80, 'Sustainability Analyst', 'Sahaj Collective', 'TERI School', 'Leela values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Kochi', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Photography\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Spiritual\",\"Exercise\":\"Yoga and walking\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Dog person\",\"Food preference\":\"Vegetarian\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/leela-primary.png\",\"/uploads/e2e-test/leela-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Spiritual', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'voice_notes', 'What is one small ritual that makes your week better?'),
(13, 13, '1995-01-16', 'Female', '', '[\"Male\"]', '[\"Long-term relationship\"]', 'Ahmedabad', 80, 'Ceramic Artist', 'Studio Meridian', 'MSU Baroda', 'Neha values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Ahmedabad', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Cooking\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Hindu\",\"Exercise\":\"Three times a week\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Open to pets\",\"Food preference\":\"Everything in moderation\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/neha-primary.png\",\"/uploads/e2e-test/neha-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Hindu', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'deep_conversations', 'What is one small ritual that makes your week better?'),
(14, 14, '1996-12-08', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 80, 'Data Journalist', 'Civic Labs', 'Asian College of Journalism', 'Priya values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Vadodara', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Photography\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Spiritual\",\"Exercise\":\"Yoga and walking\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Dog person\",\"Food preference\":\"Vegetarian\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/priya-primary.png\",\"/uploads/e2e-test/priya-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Spiritual', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'calls', 'What is one small ritual that makes your week better?'),
(15, 15, '1998-08-05', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 80, 'Landscape Designer', 'Sahaj Collective', 'CEPT University', 'Zoya values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.', 'Surat', '[\"Coffee\",\"Travel\",\"Live music\",\"Books\",\"Cooking\"]', '{\"Height\":\"165\",\"Languages\":\"English, Hindi, Gujarati\",\"Religion\":\"Hindu\",\"Exercise\":\"Three times a week\",\"Smoking\":\"Never\",\"Drinking\":\"Socially\",\"Pets\":\"Open to pets\",\"Food preference\":\"Everything in moderation\"}', '{\"My ideal Sunday is\":\"Coffee, a long walk, and cooking dinner with friends.\",\"A green flag I value is\":\"Kindness that stays consistent when nobody is watching.\",\"Together we could\":\"Explore a new neighbourhood without planning every minute.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Emotional maturity\"]', '[\"Quality Time\",\"Words of Affirmation\"]', '[\"Evenings\",\"Weekend mornings\"]', '[\"/uploads/e2e-test/zoya-primary.png\",\"/uploads/e2e-test/zoya-gallery.png\"]', 0, '165', 'Never', 'Socially', 'Never', 'Gujarati', 'Hindu', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'voice_notes', 'What is one small ritual that makes your week better?'),
(16, 16, '2000-08-12', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\"]', 'Ahmedabad', 50, NULL, NULL, NULL, NULL, '', '[]', '{}', '{}', '[]', '', '[]', '[]', '[]', '[\"/uploads/onboarding-photos/16-1786474526581-ckp4m105.png\",\"/uploads/onboarding-photos/16-1786474539011-fjhh8ooa.png\",\"/uploads/onboarding-photos/16-1786474557614-mlu7xhq6.png\"]', 0, NULL, NULL, NULL, NULL, NULL, NULL, '[]', 'photos', 0, '2026-08-11 18:54:33', '2026-08-11 18:55:57', NULL, ''),
(17, 17, '2000-08-12', 'Male', '', '[\"Male\"]', '[\"Long-Term Relationship\"]', 'Ahmedabad', 50, '', '', '', '', '', '[]', '{}', '{}', '[]', '', '[]', '[]', '[]', '[\"/uploads/onboarding-photos/17-1786479464197-b14571da72373af5.png\",\"/uploads/onboarding-photos/17-1786479474142-a2080c3ecb299ba8.png\",\"/uploads/onboarding-photos/17-1786479485895-c9141675b8a496ae.png\",\"/uploads/onboarding-photos/17-1786479492919-6b966750829c3d1e.png\",\"/uploads/onboarding-photos/17-1786479548740-88c554a6f1e1c47b.png\"]', 0, NULL, NULL, NULL, NULL, NULL, NULL, '[]', 'complete', 1, '2026-08-11 20:15:32', '2026-08-11 20:19:08', NULL, ''),
(18, 18, '2001-08-12', 'Male', '', '[\"Female\"]', '[\"Long-Term Relationship\"]', 'Ahmedabad', 50, NULL, NULL, NULL, NULL, '', '[]', '{}', '{}', '[]', '', '[]', '[]', '[]', '[\"/uploads/onboarding-photos/18-1786516712996-83e7005d7f085bd8.png\",\"/uploads/onboarding-photos/18-1786516726531-a02063984e30e46e.png\",\"/uploads/onboarding-photos/18-1786516736085-e679e4784c6c4c93.png\",\"/uploads/onboarding-photos/18-1786516736086-bbccaec412ec2ba7.png\"]', 0, NULL, NULL, NULL, NULL, NULL, NULL, '[]', 'complete', 1, '2026-08-12 06:37:42', '2026-08-12 06:38:56', NULL, ''),
(37, 49, '2003-08-12', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\"]', 'Gandhinagar', 50, 'Software Engineer', 'TDS', 'Undergraduate', 'Love you zindgi of my heart and version hdkdkbdjdb', 'Ahwa', '[\"Coffee\",\"Cooking\",\"Road trips\",\"Live music\",\"Yoga\",\"Photography\",\"Dogs\"]', '{\"Smoking\":\"Never\",\"Drinking\":\"Never\",\"Weed\":\"Never\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\",\"Height\":\"5\'6\\\" · 168 cm\",\"Religion\":\"Muslim\",\"Languages\":\"Gujarati & Hindi\"}', '{\"A green flag I value is...\":\"hello\",\"My ideal Sunday is...\":\"website\",\"Together we could...\":\"perfect\"}', '[\"he\",\"him\"]', 'Gay', '[\"Ambition\",\"Sassiness\",\"Humility\"]', '[\"Words of Affirmation\",\"Quality Time\",\"Acts of Service\"]', '[\"Early Morning\",\"Afternoon\",\"Late Night\"]', '[\"/uploads/onboarding-photos/49-1786530711868-c12f0acbd62378e9.png\",\"/uploads/onboarding-photos/49-1786530717266-2e0f9726809e93a2.png\",\"/uploads/onboarding-photos/49-1786530739439-5bcbba18415eef6d.png\"]', 0, NULL, NULL, NULL, NULL, NULL, NULL, '[]', 'complete', 1, '2026-08-12 10:31:37', '2026-08-12 10:38:19', 'calls', 'Hello Sir'),
(68, 85, '2000-08-13', 'Male', '', '[\"Female\"]', '[\"Meaningful Dating\"]', 'Gandhinagar', 105, 'Software Engineer', 'TDS', 'TDS', 'hello Sir I am yash andrapiya yash Jitendrabhai namaste I have to create a successful affiliate marketing campaign planning to go to the', 'Ahwa', '[\"Coffee\",\"Cooking\",\"Road trips\",\"Live music\",\"Yoga\",\"Photography\",\"Dogs\"]', '{\"Height\":\"5\'7\\\" · 170 cm\",\"Religion\":\"Jain\",\"Smoking\":\"Yes\",\"Drinking\":\"Yes\",\"Weed\":\"Yes\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\",\"Languages\":\"Gujarati, Hindi & English\"}', '{\"My ideal Sunday is...\":\"hello dear\",\"A green flag I value is...\":\"hello dear\",\"Together we could...\":\"hello Sir\"}', '[\"her\",\"hers\"]', 'Gay', '[\"Ambition\",\"Sassiness\"]', '[\"Words of Affirmation\",\"Acts of Service\",\"Physical Touch\"]', '[\"Early Morning\",\"Morning\",\"Afternoon\",\"Evening\",\"Late Night\",\"Flexible\"]', '[\"/uploads/onboarding-photos/85-1786605007977-2242d602211376de.png\",\"/uploads/onboarding-photos/85-1786605024290-85402bc16e4397a6.png\"]', 0, NULL, NULL, NULL, NULL, NULL, NULL, '[]', 'complete', 1, '2026-08-13 06:37:30', '2026-08-13 07:10:26', 'calls', 'Hello Sir I am yash'),
(1434, 1454, '1999-08-29', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\",\"Marriage Minded\"]', 'Ahmedabad', 20, 'Architect', 'Daylight Design', 'Postgraduate', 'Architect with a soft spot for old buildings, quiet cafés, and spontaneous road trips. I am looking for a thoughtful connection with someone who enjoys curious conversations and a well-planned Sunday.', 'Gandhinagar', '[\"Coffee\",\"Heritage walks\",\"Photography\",\"Reading\",\"Road trips\",\"Yoga\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Malayalam & Punjabi\",\"Religion\":\"Spiritual\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Curiosity\",\"Empathy\",\"Creativity\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-001-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-001-02.png\"]', 0, '192 cm', 'Sometimes', 'Never', 'Prefer not to say', 'Open', 'Spiritual', '[\"Malayalam\",\"Punjabi\"]', 'complete', 1, '2025-07-13 12:00:00', '2026-08-28 12:00:00', 'occasional_texting', 'What is your signature dish?'),
(1435, 1455, '1997-08-28', 'Male', '', '[\"Female\"]', '[\"Long-Term Relationship\",\"Meaningful Dating\"]', 'Ahmedabad', 40, 'Software Engineer', 'Bluebird Labs', 'Postgraduate', 'Engineer, weekend trail hunter, and enthusiastic maker of breakfast. I value direct communication, a playful sense of humour, and finding someone to build both small rituals and big adventures with.', 'Gandhinagar', '[\"Coffee\",\"Cooking\",\"Hiking\",\"Live music\",\"Photography\",\"Road trips\",\"Running\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi & Malayalam & Tamil\",\"Religion\":\"Jain\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Straight', '[\"Ambition\",\"Honesty\",\"Curiosity\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Late night\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-002-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-002-02.png\"]', 0, '173 cm', 'Sometimes', 'Yes', 'Never', 'Gujarati', 'Jain', '[\"Hindi\",\"Malayalam\",\"Tamil\"]', 'complete', 1, '2025-12-21 11:59:00', '2026-08-13 11:59:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1436, 1456, '1992-08-27', 'Female', '', '[\"Male\"]', '[\"Marriage Minded\"]', 'Vadodara', 80, 'Doctor', 'Aster Health', 'Professional', 'Doctor, patient gardener, and lifelong reader. I make time for classical music, family dinners, and community work, and hope to meet someone steady, warm, and intentional.', 'Surat', '[\"Classical\",\"Cooking\",\"Gardening\",\"Mindfulness\",\"Reading\",\"Volunteering\",\"Yoga\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Marathi & Malayalam & Gujarati\",\"Religion\":\"Christian\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Open', '[\"Humour\",\"Honesty\",\"Creativity\"]', '[\"Quality time\",\"Physical touch\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-003-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-003-02.png\"]', 0, '177 cm', 'Sometimes', 'Sometimes', 'Never', 'Indian', 'Christian', '[\"Marathi\",\"Malayalam\",\"Gujarati\"]', 'complete', 1, '2026-04-26 11:58:00', '2026-08-09 11:58:00', 'frequent_texting', 'Which city would you revisit tomorrow?'),
(1437, 1457, '2008-08-26', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\",\"Friendship First\"]', 'Vadodara', 150, 'Marketing', 'Mosaic Ventures', 'Undergraduate', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. I always make room for dessert.', 'Vadodara', '[\"Writing\",\"Dogs\",\"Road trips\",\"Reading\",\"Volunteering\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Tamil\",\"Religion\":\"Sikh\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Straight', '[\"Kindness\",\"Humour\",\"Patience\"]', '[\"Receiving gifts\",\"Acts of service\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-004-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-004-02.png\"]', 0, '183 cm', 'Prefer not to say', 'Never', 'Never', 'Global', 'Sikh', '[\"Tamil\"]', 'complete', 1, '2026-08-28 11:57:00', '2026-08-28 11:57:00', 'calls', 'Which city would you revisit tomorrow?'),
(1438, 1458, '1947-08-25', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\"]', 'Ahmedabad', 20, 'Marketing', 'Mosaic Ventures', 'Doctorate & Research', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Tell me about a place you would revisit.', 'Surat', '[\"Design\",\"Heritage walks\",\"Road trips\",\"Cafes\",\"Yoga\",\"Cooking\",\"Live music\",\"City breaks\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Punjabi\",\"Religion\":\"Sikh\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Humour\",\"Curiosity\",\"Creativity\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-005-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-005-02.jpg\"]', 0, '154 cm', 'Prefer not to say', 'Never', 'Never', 'Open', 'Sikh', '[\"Punjabi\"]', 'complete', 1, '2025-10-08 11:56:00', '2026-08-22 11:56:00', 'light_fun_conversations', 'What is your signature dish?'),
(1439, 1459, '1999-08-24', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\"]', 'Gandhinagar', 40, 'Architect', 'Northstar Collective', 'Doctorate & Research', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Tell me about a place you would revisit.', 'Gandhinagar', '[\"Yoga\",\"Cafes\",\"Mindfulness\",\"Dogs\",\"Reading\",\"Cooking\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi & Marathi & Malayalam\",\"Religion\":\"Sikh\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Open', '[\"Patience\",\"Humour\",\"Kindness\"]', '[\"Receiving gifts\",\"Words of affirmation\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-006-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-006-02.jpg\"]', 0, '177 cm', 'Prefer not to say', 'Sometimes', 'Sometimes', 'Open', 'Sikh', '[\"Hindi\",\"Marathi\",\"Malayalam\"]', 'complete', 1, '2026-08-29 11:55:00', '2026-08-29 11:55:00', 'occasional_texting', 'Which city would you revisit tomorrow?'),
(1440, 1460, '2002-08-23', 'Female', '', '[\"Male\"]', '[\"Casual Connection\"]', 'Surat', 80, 'Business Owner', 'Cedar Works', 'Postgraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. I always make room for dessert.', 'Gandhinagar', '[\"Road trips\",\"Cooking\",\"Running\",\"Baking\",\"Coffee\",\"Beaches\",\"Volunteering\",\"Heritage walks\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"English & Gujarati\",\"Religion\":\"Christian\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Kindness\",\"Empathy\",\"Honesty\"]', '[\"Physical touch\",\"Receiving gifts\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-007-01.webp\",\"/uploads/onboarding-photos/amoraa-demo-profile-007-02.jpg\"]', 0, '187 cm', 'Sometimes', 'Yes', 'Sometimes', 'Open', 'Christian', '[\"English\",\"Gujarati\"]', 'complete', 1, '2024-03-12 11:54:00', '2026-08-22 11:54:00', 'voice_notes', 'Which city would you revisit tomorrow?'),
(1441, 1461, '1995-08-22', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\"]', 'Vadodara', 150, 'Business Owner', 'Riverstone', 'Professional', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Teach me something you love.', 'Gandhinagar', '[\"Mindfulness\",\"Cooking\",\"Dogs\",\"Pottery\",\"Cycling\",\"Volunteering\",\"Classical\",\"Road trips\",\"Reading\",\"Wildlife\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"English\",\"Religion\":\"Muslim\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Straight', '[\"Empathy\",\"Curiosity\",\"Kindness\"]', '[\"Physical touch\",\"Quality time\"]', '[\"Late night\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-008-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-008-02.jpg\"]', 0, '176 cm', 'Prefer not to say', 'Sometimes', 'Prefer not to say', 'Indian', 'Muslim', '[\"English\"]', 'complete', 1, '2025-09-28 11:53:00', '2026-08-26 11:53:00', 'calls', 'What is a small thing that made your week better?'),
(1442, 1462, '1981-08-21', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Marriage Minded\"]', 'Ahmedabad', 20, 'Entrepreneur', 'Independent', 'Postgraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Bonus points for a great playlist.', 'Vadodara', '[\"Reading\",\"Beaches\",\"Photography\",\"Volunteering\",\"Cats\",\"Hiking\",\"Live music\",\"Classical\",\"Coffee\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"English & Punjabi\",\"Religion\":\"Spiritual\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Open', '[\"Humour\",\"Honesty\",\"Curiosity\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-009-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-009-02.webp\"]', 0, '179 cm', 'Never', 'Yes', 'Sometimes', 'Global', 'Spiritual', '[\"English\",\"Punjabi\"]', 'complete', 1, '2026-04-10 11:52:00', '2026-08-18 11:52:00', 'voice_notes', 'What is a small thing that made your week better?'),
(1443, 1463, '1998-08-20', 'Male', '', '[\"Female\"]', '[\"Casual Connection\",\"Long-Term Relationship\"]', 'Gandhinagar', 40, 'Software Engineer', 'Aster Health', 'Undergraduate', 'Here for something real.', 'Surat', '[\"Photography\",\"Design\",\"Reading\",\"Volunteering\",\"Yoga\",\"City breaks\",\"Classical\",\"Running\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi\",\"Religion\":\"Spiritual\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Kindness\",\"Patience\",\"Ambition\"]', '[\"Acts of service\",\"Receiving gifts\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-010-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-010-02.jpg\"]', 0, '172 cm', 'Never', 'Never', 'Sometimes', 'Open', 'Spiritual', '[\"Hindi\"]', 'complete', 1, '2026-03-23 11:51:00', '2026-08-29 11:51:00', 'frequent_texting', 'Which city would you revisit tomorrow?'),
(1444, 1464, '2002-08-19', 'Female', '', '[\"Male\"]', '[\"Marriage Minded\",\"Meaningful Dating\"]', 'Surat', 80, 'Finance', 'Acorn Studio', 'Professional', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Tell me about a place you would revisit.', 'Vadodara', '[\"Pottery\",\"Yoga\",\"Live music\",\"Cooking\",\"City breaks\",\"Photography\",\"Design\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"English & Hindi\",\"Religion\":\"Christian\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Straight', '[\"Empathy\",\"Creativity\",\"Kindness\"]', '[\"Physical touch\",\"Receiving gifts\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-011-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-011-02.jpg\"]', 0, '137 cm', 'Prefer not to say', 'Sometimes', 'Never', 'Open', 'Christian', '[\"English\",\"Hindi\"]', 'complete', 1, '2025-11-11 11:50:00', '2026-08-18 11:50:00', 'deep_conversations', 'What is your signature dish?'),
(1445, 1465, '1981-08-18', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Casual Connection\"]', 'Vadodara', 150, 'Marketing', 'Aster Health', 'Undergraduate', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Tell me about a place you would revisit.', 'Gandhinagar', '[\"Cooking\",\"Cats\",\"Hiking\",\"Live music\",\"Design\",\"City breaks\",\"Indie\",\"Baking\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Hindi & Marathi\",\"Religion\":\"Sikh\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"They/Them\"]', 'Open', '[\"Curiosity\",\"Humour\",\"Kindness\"]', '[\"Acts of service\",\"Physical touch\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-012-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-012-02.webp\"]', 0, '213 cm', 'Prefer not to say', 'Never', 'Never', 'Open', 'Sikh', '[\"Hindi\",\"Marathi\"]', 'complete', 1, '2026-03-17 11:49:00', '2026-08-24 11:49:00', 'frequent_texting', 'What is your signature dish?'),
(1446, 1466, '1980-08-17', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 20, 'Student', 'Daylight Design', 'Postgraduate', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Bonus points for a great playlist.', 'Gandhinagar', '[\"Classical\",\"Cafes\",\"Yoga\",\"Street food\",\"Beaches\",\"City breaks\",\"Bollywood\",\"Cooking\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Marathi & Tamil\",\"Religion\":\"Open\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Open', '[\"Empathy\",\"Kindness\",\"Curiosity\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-013-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-013-02.jpg\"]', 0, '151 cm', 'Prefer not to say', 'Never', 'Never', 'Global', 'Open', '[\"Marathi\",\"Tamil\"]', 'complete', 1, '2026-05-29 11:48:00', '2026-08-14 11:48:00', 'occasional_texting', 'What is your signature dish?'),
(1447, 1467, '1997-08-16', 'Male', '', '[\"Female\"]', '[\"Friendship First\"]', 'Gandhinagar', 40, 'Business Owner', 'Independent', 'Undergraduate', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. I always make room for dessert.', 'Vadodara', '[\"Gardening\",\"Cats\",\"Coffee\",\"Yoga\",\"Photography\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi & English & Marathi\",\"Religion\":\"Jain\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Straight', '[\"Ambition\",\"Honesty\",\"Creativity\"]', '[\"Quality time\",\"Physical touch\"]', '[\"Late night\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-014-01.webp\",\"/uploads/onboarding-photos/amoraa-demo-profile-014-02.jpg\"]', 0, '156 cm', 'Never', 'Yes', 'Never', 'Gujarati', 'Jain', '[\"Hindi\",\"English\",\"Marathi\"]', 'complete', 1, '2026-08-18 11:47:00', '2026-08-18 11:47:00', 'occasional_texting', 'Which city would you revisit tomorrow?'),
(1448, 1468, '1979-08-15', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Casual Connection\"]', 'Surat', 80, 'Designer', 'Independent', 'Postgraduate', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Bonus points for a great playlist.', 'Gandhinagar', '[\"Writing\",\"Cafes\",\"Cats\",\"City breaks\",\"Cooking\",\"Heritage walks\",\"Bollywood\",\"Running\",\"Design\",\"Road trips\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Tamil & Hindi & Gujarati\",\"Religion\":\"Christian\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Open', '[\"Patience\",\"Creativity\",\"Empathy\"]', '[\"Receiving gifts\",\"Quality time\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-015-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-015-02.webp\"]', 0, '177 cm', 'Sometimes', 'Never', 'Prefer not to say', 'Global', 'Christian', '[\"Tamil\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-04-30 11:46:00', '2026-08-22 11:46:00', 'deep_conversations', 'Which city would you revisit tomorrow?'),
(1449, 1469, '1983-08-14', 'Male', '', '[\"Female\"]', '[\"Casual Connection\"]', 'Vadodara', 150, 'Finance', 'Saffron & Co.', 'Doctorate & Research', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Tell me about a place you would revisit.', 'Vadodara', '[\"Photography\",\"Road trips\",\"Beaches\",\"Coffee\",\"Street food\",\"Mindfulness\",\"Volunteering\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Marathi & Tamil & Hindi\",\"Religion\":\"Hindu\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Kindness\",\"Honesty\",\"Patience\"]', '[\"Words of affirmation\",\"Physical touch\"]', '[\"Late night\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-016-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-016-02.jpg\"]', 0, '150 cm', 'Never', 'Never', 'Prefer not to say', 'Global', 'Hindu', '[\"Marathi\",\"Tamil\",\"Hindi\"]', 'complete', 1, '2025-12-17 11:45:00', '2026-08-22 11:45:00', 'calls', 'What is a small thing that made your week better?'),
(1450, 1470, '1980-08-13', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\"]', 'Ahmedabad', 20, 'Designer', 'Cedar Works', 'Postgraduate', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. I always make room for dessert.', 'Vadodara', '[\"Road trips\",\"Street food\",\"Cycling\",\"Dogs\",\"Heritage walks\",\"Cooking\",\"Cats\",\"Bollywood\",\"Wildlife\",\"Mindfulness\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Tamil & Punjabi\",\"Religion\":\"Hindu\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Straight', '[\"Creativity\",\"Kindness\",\"Ambition\"]', '[\"Acts of service\",\"Physical touch\"]', '[\"Morning\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-017-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-017-02.jpg\"]', 0, '161 cm', 'Sometimes', 'Sometimes', 'Prefer not to say', 'Open', 'Hindu', '[\"Tamil\",\"Punjabi\"]', 'complete', 1, '2025-08-03 11:44:00', '2026-08-24 11:44:00', 'voice_notes', 'What is a small thing that made your week better?'),
(1451, 1471, '1998-08-12', 'Male', '', '[\"Female\"]', '[\"Long-Term Relationship\",\"Meaningful Dating\"]', 'Gandhinagar', 40, 'Finance', 'Saffron & Co.', 'Postgraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Tell me about a place you would revisit.', 'Ahmedabad', '[\"Baking\",\"Bollywood\",\"Design\",\"Yoga\",\"Street food\",\"Dogs\",\"Beaches\",\"Gardening\",\"Pottery\",\"Running\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Malayalam\",\"Religion\":\"Open\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Straight', '[\"Creativity\",\"Curiosity\",\"Patience\"]', '[\"Acts of service\",\"Receiving gifts\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-018-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-018-02.jpg\"]', 0, '193 cm', 'Never', 'Yes', 'Never', 'Global', 'Open', '[\"Malayalam\"]', 'complete', 1, '2026-08-11 11:43:00', '2026-08-25 11:43:00', 'calls', 'Which city would you revisit tomorrow?'),
(1452, 1472, '1995-08-11', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\"]', 'Surat', 80, 'Architect', 'Cedar Works', 'Postgraduate', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Tell me about a place you would revisit.', 'Vadodara', '[\"Beaches\",\"Dogs\",\"Yoga\",\"Heritage walks\",\"Pottery\",\"Volunteering\",\"Wildlife\",\"Design\",\"City breaks\",\"Live music\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Gujarati\",\"Religion\":\"Open\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Straight', '[\"Honesty\",\"Empathy\",\"Patience\"]', '[\"Receiving gifts\",\"Physical touch\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-019-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-019-02.jpg\"]', 0, '187 cm', 'Never', 'Sometimes', 'Never', 'Indian', 'Open', '[\"Gujarati\"]', 'complete', 1, '2026-07-01 11:42:00', '2026-08-29 11:42:00', 'frequent_texting', 'What is your signature dish?');
INSERT INTO `onboardingprofiles` (`id`, `userId`, `birthDate`, `gender`, `customGender`, `interestedIn`, `relationshipGoals`, `city`, `preferredDistance`, `profession`, `company`, `education`, `bio`, `hometown`, `interests`, `lifestyle`, `prompts`, `pronouns`, `sexuality`, `valuedQualities`, `loveLanguages`, `preferredTalkingHours`, `photos`, `primaryPhotoIndex`, `height`, `smoking`, `drinking`, `weed`, `community`, `religion`, `languages`, `stage`, `onboardingCompleted`, `createdAt`, `updatedAt`, `communicationStyle`, `iceBreaker`) VALUES
(1453, 1473, '1980-08-10', 'Male', '', '[\"Female\"]', '[\"Casual Connection\",\"Meaningful Dating\"]', 'Vadodara', 150, 'Finance', 'Saffron & Co.', 'Undergraduate', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Tell me about a place you would revisit.', 'Vadodara', '[\"Bollywood\",\"Gardening\",\"Live music\",\"Cycling\",\"Dogs\",\"Mindfulness\",\"Hiking\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Malayalam\",\"Religion\":\"Spiritual\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Open', '[\"Patience\",\"Empathy\",\"Honesty\"]', '[\"Words of affirmation\",\"Physical touch\"]', '[\"Late night\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-020-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-020-02.jpg\"]', 0, '180 cm', 'Never', 'Yes', 'Sometimes', 'Indian', 'Spiritual', '[\"Malayalam\"]', 'complete', 1, '2026-01-05 11:41:00', '2026-08-21 11:41:00', 'light_fun_conversations', 'What is your signature dish?'),
(1454, 1474, '1979-08-09', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\",\"Exploring Possibilities\"]', 'Ahmedabad', 20, 'Finance', 'Daylight Design', 'Professional', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Tell me about a place you would revisit.', 'Surat', '[\"Pottery\",\"Wildlife\",\"Dogs\",\"Cooking\",\"Volunteering\",\"Coffee\",\"Beaches\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Marathi & Gujarati & Tamil\",\"Religion\":\"Sikh\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Straight', '[\"Patience\",\"Creativity\",\"Honesty\"]', '[\"Quality time\",\"Receiving gifts\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-021-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-021-02.png\"]', 0, '172 cm', 'Prefer not to say', 'Yes', 'Sometimes', 'Open', 'Sikh', '[\"Marathi\",\"Gujarati\",\"Tamil\"]', 'complete', 1, '2025-09-09 11:40:00', '2026-08-29 11:40:00', 'occasional_texting', 'What is your signature dish?'),
(1455, 1475, '1982-08-08', 'Male', '', '[\"Female\"]', '[\"Casual Connection\",\"Long-Term Relationship\"]', 'Gandhinagar', 40, 'Software Engineer', 'Aster Health', 'Undergraduate', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Tell me about a place you would revisit.', 'Vadodara', '[\"Mindfulness\",\"Cats\",\"Design\",\"Gardening\",\"Heritage walks\",\"Pottery\",\"Classical\",\"Reading\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Marathi & Gujarati & Punjabi\",\"Religion\":\"Sikh\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Empathy\",\"Kindness\",\"Humour\"]', '[\"Quality time\",\"Physical touch\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-022-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-022-02.png\"]', 0, '155 cm', 'Sometimes', 'Sometimes', 'Sometimes', 'Global', 'Sikh', '[\"Marathi\",\"Gujarati\",\"Punjabi\"]', 'complete', 1, '2026-04-21 11:39:00', '2026-08-10 11:39:00', 'calls', 'What is your signature dish?'),
(1456, 1476, '1987-08-07', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Friendship First\",\"Exploring Possibilities\"]', 'Surat', 80, 'Student', 'Daylight Design', 'Undergraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Bonus points for a great playlist.', 'Vadodara', '[\"Baking\",\"Street food\",\"Beaches\",\"Design\",\"Mindfulness\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Hindi & Gujarati & English\",\"Religion\":\"Jain\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"They/Them\"]', 'Open', '[\"Curiosity\",\"Ambition\",\"Patience\"]', '[\"Words of affirmation\",\"Receiving gifts\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-023-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-023-02.png\"]', 0, '169 cm', 'Prefer not to say', 'Never', 'Sometimes', 'Open', 'Jain', '[\"Hindi\",\"Gujarati\",\"English\"]', 'complete', 1, '2025-09-25 11:38:00', '2026-08-29 11:38:00', 'calls', 'What is your signature dish?'),
(1457, 1477, '1983-08-06', 'Male', '', '[\"Female\"]', '[\"Friendship First\",\"Exploring Possibilities\"]', 'Vadodara', 150, 'Finance', 'Northstar Collective', 'Undergraduate', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Tell me about a place you would revisit.', 'Vadodara', '[\"Gardening\",\"Mindfulness\",\"Yoga\",\"Live music\",\"Writing\",\"Volunteering\",\"Design\",\"Street food\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Marathi & English & Punjabi\",\"Religion\":\"Spiritual\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Open', '[\"Curiosity\",\"Ambition\",\"Empathy\"]', '[\"Physical touch\",\"Acts of service\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-024-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-024-02.png\"]', 0, '182 cm', 'Never', 'Never', 'Prefer not to say', 'Global', 'Spiritual', '[\"Marathi\",\"English\",\"Punjabi\"]', 'complete', 1, '2026-05-02 11:37:00', '2026-08-12 11:37:00', 'occasional_texting', 'Which city would you revisit tomorrow?'),
(1458, 1478, '2002-08-05', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\",\"Casual Connection\"]', 'Ahmedabad', 20, 'Marketing', 'Acorn Studio', 'Professional', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Tell me about a place you would revisit.', 'Vadodara', '[\"Cycling\",\"Yoga\",\"Photography\",\"Cooking\",\"Live music\",\"Heritage walks\",\"Design\",\"Baking\",\"City breaks\",\"Street food\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Malayalam & Marathi\",\"Religion\":\"Hindu\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Open', '[\"Patience\",\"Creativity\",\"Humour\"]', '[\"Acts of service\",\"Physical touch\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-025-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-025-02.png\"]', 0, '189 cm', 'Prefer not to say', 'Sometimes', 'Prefer not to say', 'Gujarati', 'Hindu', '[\"Malayalam\",\"Marathi\"]', 'complete', 1, '2025-11-06 11:36:00', '2026-08-10 11:36:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1459, 1479, '1999-08-04', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\"]', 'Gandhinagar', 40, 'Architect', 'Northstar Collective', 'Postgraduate', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Teach me something you love.', 'Vadodara', '[\"Coffee\",\"Dogs\",\"Yoga\",\"Gardening\",\"Photography\",\"Cafes\",\"Bollywood\",\"Beaches\",\"Live music\",\"Indie\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Punjabi & Hindi\",\"Religion\":\"Jain\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Open', '[\"Honesty\",\"Curiosity\",\"Empathy\"]', '[\"Physical touch\",\"Acts of service\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-026-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-026-02.png\"]', 0, '173 cm', 'Prefer not to say', 'Never', 'Sometimes', 'Global', 'Jain', '[\"Punjabi\",\"Hindi\"]', 'complete', 1, '2026-08-21 11:35:00', '2026-08-24 11:35:00', 'occasional_texting', 'What is your signature dish?'),
(1460, 1480, '1984-08-03', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\",\"Meaningful Dating\"]', 'Surat', 80, 'Designer', 'Daylight Design', 'Postgraduate', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Teach me something you love.', 'Ahmedabad', '[\"Cats\",\"Pottery\",\"Classical\",\"Cycling\",\"Coffee\",\"Reading\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Marathi & Hindi & Tamil\",\"Religion\":\"Spiritual\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Ambition\",\"Empathy\"]', '[\"Physical touch\",\"Receiving gifts\"]', '[\"Late night\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-027-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-027-02.png\"]', 0, '176 cm', 'Never', 'Sometimes', 'Sometimes', 'Open', 'Spiritual', '[\"Marathi\",\"Hindi\",\"Tamil\"]', 'complete', 1, '2025-08-09 11:34:00', '2026-08-10 11:34:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1461, 1481, '2005-08-02', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\"]', 'Vadodara', 150, 'Finance', 'Independent', 'Doctorate & Research', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Bonus points for a great playlist.', 'Surat', '[\"Cafes\",\"Cats\",\"Reading\",\"Design\",\"Baking\",\"Gardening\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Marathi\",\"Religion\":\"Sikh\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Honesty\",\"Curiosity\",\"Ambition\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-028-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-028-02.png\"]', 0, '193 cm', 'Sometimes', 'Never', 'Prefer not to say', 'Gujarati', 'Sikh', '[\"Marathi\"]', 'complete', 1, '2026-07-19 11:33:00', '2026-08-27 11:33:00', 'deep_conversations', 'What is a small thing that made your week better?'),
(1462, 1482, '1988-08-01', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\"]', 'Ahmedabad', 20, 'Designer', 'Saffron & Co.', 'Professional', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. Tell me about a place you would revisit.', 'Vadodara', '[\"Cats\",\"Street food\",\"Pottery\",\"Coffee\",\"Road trips\",\"Cycling\",\"Photography\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Tamil & Marathi & Hindi\",\"Religion\":\"Spiritual\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Open', '[\"Kindness\",\"Curiosity\",\"Ambition\"]', '[\"Quality time\",\"Receiving gifts\"]', '[\"Morning\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-029-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-029-02.png\"]', 0, '188 cm', 'Prefer not to say', 'Yes', 'Prefer not to say', 'Gujarati', 'Spiritual', '[\"Tamil\",\"Marathi\",\"Hindi\"]', 'complete', 1, '2026-03-16 11:32:00', '2026-08-17 11:32:00', 'voice_notes', 'Which city would you revisit tomorrow?'),
(1463, 1483, '1983-07-31', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\"]', 'Gandhinagar', 40, 'Marketing', 'Riverstone', 'Undergraduate', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. I always make room for dessert.', 'Surat', '[\"Reading\",\"Yoga\",\"Street food\",\"Design\",\"Gardening\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"English\",\"Religion\":\"Christian\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Straight', '[\"Patience\",\"Curiosity\",\"Creativity\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-030-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-030-02.png\"]', 0, '179 cm', 'Sometimes', 'Yes', 'Sometimes', 'Gujarati', 'Christian', '[\"English\"]', 'complete', 1, '2026-02-08 11:31:00', '2026-08-24 11:31:00', 'light_fun_conversations', 'Which city would you revisit tomorrow?'),
(1464, 1484, '1998-07-30', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\",\"Long-Term Relationship\"]', 'Surat', 80, 'Architect', 'Bluebird Labs', 'Professional', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Teach me something you love.', 'Gandhinagar', '[\"Cycling\",\"Street food\",\"Coffee\",\"Heritage walks\",\"Live music\",\"Cooking\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"English & Punjabi & Tamil\",\"Religion\":\"Spiritual\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Kindness\",\"Honesty\",\"Ambition\"]', '[\"Acts of service\",\"Words of affirmation\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-031-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-031-02.png\"]', 0, '177 cm', 'Sometimes', 'Never', 'Prefer not to say', 'Gujarati', 'Spiritual', '[\"English\",\"Punjabi\",\"Tamil\"]', 'complete', 1, '2025-09-02 11:30:00', '2026-08-18 11:30:00', 'voice_notes', 'Which city would you revisit tomorrow?'),
(1465, 1485, '1992-07-29', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\",\"Meaningful Dating\"]', 'Vadodara', 150, 'Marketing', 'Riverstone', 'Postgraduate', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. I always make room for dessert.', 'Vadodara', '[\"Reading\",\"Classical\",\"Wildlife\",\"Design\",\"Baking\",\"Heritage walks\",\"Cooking\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Hindi & Gujarati\",\"Religion\":\"Muslim\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Open', '[\"Patience\",\"Humour\",\"Honesty\"]', '[\"Acts of service\",\"Physical touch\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-032-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-032-02.jpg\"]', 0, '190 cm', 'Never', 'Never', 'Prefer not to say', 'Global', 'Muslim', '[\"Hindi\",\"Gujarati\"]', 'complete', 1, '2026-04-23 11:29:00', '2026-08-12 11:29:00', 'light_fun_conversations', 'What is your signature dish?'),
(1466, 1486, '1987-07-28', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 20, 'Marketing', 'Mosaic Ventures', 'Undergraduate', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Teach me something you love.', 'Ahmedabad', '[\"Cooking\",\"Running\",\"Baking\",\"Bollywood\",\"Design\",\"Gardening\",\"Indie\",\"Mindfulness\",\"Cafes\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Hindi & Malayalam\",\"Religion\":\"Sikh\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Honesty\",\"Humour\"]', '[\"Words of affirmation\",\"Receiving gifts\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-033-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-033-02.jpg\"]', 0, '193 cm', 'Never', 'Never', 'Never', 'Open', 'Sikh', '[\"Hindi\",\"Malayalam\"]', 'complete', 1, '2025-09-07 11:28:00', '2026-08-20 11:28:00', 'deep_conversations', 'What is a small thing that made your week better?'),
(1467, 1487, '2005-07-27', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Casual Connection\",\"Meaningful Dating\"]', 'Gandhinagar', 40, 'Business Owner', 'Riverstone', 'Postgraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Bonus points for a great playlist.', 'Gandhinagar', '[\"Indie\",\"Cooking\",\"Yoga\",\"Mindfulness\",\"Wildlife\",\"Volunteering\",\"Coffee\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Malayalam\",\"Religion\":\"Jain\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"They/Them\"]', 'Open', '[\"Humour\",\"Creativity\",\"Honesty\"]', '[\"Quality time\",\"Words of affirmation\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-034-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-034-02.jpg\"]', 0, '194 cm', 'Prefer not to say', 'Sometimes', 'Prefer not to say', 'Open', 'Jain', '[\"Malayalam\"]', 'complete', 1, '2025-11-09 11:27:00', '2026-08-20 11:27:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1468, 1488, '1978-07-26', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\",\"Friendship First\"]', 'Surat', 80, 'Software Engineer', 'Independent', 'Doctorate & Research', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Bonus points for a great playlist.', 'Vadodara', '[\"Mindfulness\",\"Cooking\",\"Hiking\",\"Reading\",\"Heritage walks\",\"Bollywood\",\"Running\",\"Wildlife\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Hindi\",\"Religion\":\"Muslim\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Empathy\",\"Ambition\",\"Patience\"]', '[\"Receiving gifts\",\"Words of affirmation\"]', '[\"Morning\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-035-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-035-02.jpg\"]', 0, '158 cm', 'Prefer not to say', 'Sometimes', 'Sometimes', 'Global', 'Muslim', '[\"Hindi\"]', 'complete', 1, '2026-01-21 11:26:00', '2026-08-21 11:26:00', 'deep_conversations', 'Which city would you revisit tomorrow?'),
(1469, 1489, '1989-07-25', 'Male', '', '[\"Female\"]', '[\"Friendship First\"]', 'Vadodara', 150, 'Business Owner', 'Saffron & Co.', 'Undergraduate', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. I always make room for dessert.', 'Gandhinagar', '[\"City breaks\",\"Pottery\",\"Beaches\",\"Cats\",\"Street food\",\"Classical\",\"Cooking\",\"Baking\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Hindi & Tamil & Malayalam\",\"Religion\":\"Muslim\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Open', '[\"Honesty\",\"Ambition\",\"Patience\"]', '[\"Acts of service\",\"Physical touch\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-036-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-036-02.jpg\"]', 0, '190 cm', 'Sometimes', 'Yes', 'Never', 'Open', 'Muslim', '[\"Hindi\",\"Tamil\",\"Malayalam\"]', 'complete', 1, '2025-10-19 11:25:00', '2026-08-16 11:25:00', 'deep_conversations', 'What is a small thing that made your week better?'),
(1470, 1490, '1989-07-24', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Marriage Minded\"]', 'Ahmedabad', 20, 'Architect', 'Daylight Design', 'Doctorate & Research', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. I always make room for dessert.', 'Vadodara', '[\"Gardening\",\"Pottery\",\"Mindfulness\",\"City breaks\",\"Bollywood\",\"Beaches\",\"Cafes\",\"Running\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Gujarati & Hindi\",\"Religion\":\"Open\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Open', '[\"Honesty\",\"Kindness\",\"Empathy\"]', '[\"Acts of service\",\"Quality time\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-037-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-037-02.jpg\"]', 0, '166 cm', 'Never', 'Sometimes', 'Never', 'Open', 'Open', '[\"Gujarati\",\"Hindi\"]', 'complete', 1, '2025-10-08 11:24:00', '2026-08-11 11:24:00', 'frequent_texting', 'Which city would you revisit tomorrow?'),
(1471, 1491, '1998-07-23', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\",\"Meaningful Dating\"]', 'Gandhinagar', 40, 'Finance', 'Mosaic Ventures', 'Doctorate & Research', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Bonus points for a great playlist.', 'Vadodara', '[\"Cats\",\"Writing\",\"Street food\",\"Dogs\",\"Volunteering\",\"Cycling\",\"Coffee\",\"Wildlife\",\"Mindfulness\",\"Beaches\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Gujarati & Marathi & Hindi\",\"Religion\":\"Open\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Creativity\",\"Empathy\",\"Kindness\"]', '[\"Quality time\",\"Physical touch\"]', '[\"Morning\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-038-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-038-02.jpg\"]', 0, '164 cm', 'Sometimes', 'Never', 'Sometimes', 'Open', 'Open', '[\"Gujarati\",\"Marathi\",\"Hindi\"]', 'complete', 1, '2026-02-13 11:23:00', '2026-08-22 11:23:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1472, 1492, '1993-07-22', 'Female', '', '[\"Male\"]', '[\"Casual Connection\",\"Meaningful Dating\"]', 'Surat', 80, 'Business Owner', 'Acorn Studio', 'Doctorate & Research', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. I always make room for dessert.', 'Ahmedabad', '[\"Mindfulness\",\"Cycling\",\"Writing\",\"Indie\",\"Street food\",\"Cats\",\"Volunteering\",\"Photography\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Marathi & Hindi\",\"Religion\":\"Sikh\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Straight', '[\"Honesty\",\"Kindness\",\"Ambition\"]', '[\"Quality time\",\"Words of affirmation\"]', '[\"Morning\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-039-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-039-02.webp\"]', 0, '157 cm', 'Prefer not to say', 'Never', 'Never', 'Open', 'Sikh', '[\"Marathi\",\"Hindi\"]', 'complete', 1, '2026-04-29 11:22:00', '2026-08-19 11:22:00', 'occasional_texting', 'What is your signature dish?'),
(1473, 1493, '1983-07-21', 'Male', '', '[\"Female\"]', '[\"Meaningful Dating\"]', 'Vadodara', 150, 'Marketing', 'Cedar Works', 'Postgraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. I always make room for dessert.', 'Gandhinagar', '[\"Cycling\",\"Cooking\",\"Reading\",\"Cats\",\"Hiking\",\"City breaks\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"English & Hindi\",\"Religion\":\"Open\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Open', '[\"Empathy\",\"Curiosity\",\"Ambition\"]', '[\"Words of affirmation\",\"Receiving gifts\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-040-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-040-02.jpg\"]', 0, '185 cm', 'Prefer not to say', 'Never', 'Never', 'Open', 'Open', '[\"English\",\"Hindi\"]', 'complete', 1, '2025-08-25 11:21:00', '2026-08-14 11:21:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1474, 1494, '1981-07-20', 'Female', '', '[\"Male\"]', '[\"Casual Connection\",\"Meaningful Dating\"]', 'Ahmedabad', 20, 'Designer', 'Acorn Studio', 'Postgraduate', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. I always make room for dessert.', 'Gandhinagar', '[\"Dogs\",\"Design\",\"Yoga\",\"Bollywood\",\"Hiking\",\"City breaks\",\"Writing\",\"Indie\",\"Cafes\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Punjabi & Tamil & Malayalam\",\"Religion\":\"Spiritual\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Straight', '[\"Honesty\",\"Humour\",\"Curiosity\"]', '[\"Quality time\",\"Words of affirmation\"]', '[\"Late night\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-041-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-041-02.jpg\"]', 0, '175 cm', 'Sometimes', 'Yes', 'Never', 'Gujarati', 'Spiritual', '[\"Punjabi\",\"Tamil\",\"Malayalam\"]', 'complete', 1, '2026-07-04 11:20:00', '2026-08-12 11:20:00', 'occasional_texting', 'Which city would you revisit tomorrow?'),
(1475, 1495, '1996-07-19', 'Male', '', '[\"Female\"]', '[\"Long-Term Relationship\",\"Exploring Possibilities\"]', 'Gandhinagar', 40, 'Doctor', 'Bluebird Labs', 'Doctorate & Research', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Bonus points for a great playlist.', 'Gandhinagar', '[\"Running\",\"Volunteering\",\"Dogs\",\"Design\",\"Cats\",\"City breaks\",\"Classical\",\"Heritage walks\",\"Coffee\",\"Live music\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"English\",\"Religion\":\"Hindu\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Open', '[\"Honesty\",\"Empathy\",\"Humour\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-042-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-042-02.jpg\"]', 0, '186 cm', 'Sometimes', 'Yes', 'Prefer not to say', 'Open', 'Hindu', '[\"English\"]', 'complete', 1, '2025-07-15 11:19:00', '2026-08-15 11:19:00', 'deep_conversations', 'Which city would you revisit tomorrow?'),
(1476, 1496, '1984-07-18', 'Female', '', '[\"Male\"]', '[\"Exploring Possibilities\",\"Meaningful Dating\"]', 'Surat', 80, 'Marketing', 'Daylight Design', 'Professional', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Bonus points for a great playlist.', 'Surat', '[\"Wildlife\",\"Hiking\",\"Cats\",\"Reading\",\"Classical\",\"Indie\",\"City breaks\",\"Cycling\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Tamil & Malayalam & Marathi\",\"Religion\":\"Spiritual\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Open', '[\"Creativity\",\"Patience\",\"Curiosity\"]', '[\"Receiving gifts\",\"Words of affirmation\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-043-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-043-02.webp\"]', 0, '179 cm', 'Prefer not to say', 'Sometimes', 'Never', 'Global', 'Spiritual', '[\"Tamil\",\"Malayalam\",\"Marathi\"]', 'complete', 1, '2025-11-04 11:18:00', '2026-08-24 11:18:00', 'occasional_texting', 'Which city would you revisit tomorrow?'),
(1477, 1497, '2002-07-17', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\",\"Friendship First\"]', 'Vadodara', 150, 'Architect', 'Cedar Works', 'Doctorate & Research', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. I always make room for dessert.', 'Vadodara', '[\"Running\",\"Reading\",\"Hiking\",\"Mindfulness\",\"Baking\",\"Photography\",\"Live music\",\"Bollywood\",\"City breaks\",\"Writing\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Malayalam\",\"Religion\":\"Muslim\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Open', '[\"Empathy\",\"Patience\",\"Curiosity\"]', '[\"Receiving gifts\",\"Acts of service\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-044-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-044-02.jpg\"]', 0, '185 cm', 'Sometimes', 'Never', 'Never', 'Gujarati', 'Muslim', '[\"Malayalam\"]', 'complete', 1, '2025-08-30 11:17:00', '2026-08-25 11:17:00', 'calls', 'What is a small thing that made your week better?'),
(1478, 1498, '1979-07-16', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Exploring Possibilities\"]', 'Ahmedabad', 20, 'Architect', 'Daylight Design', 'Professional', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Bonus points for a great playlist.', 'Gandhinagar', '[\"Wildlife\",\"Cycling\",\"Volunteering\",\"Beaches\",\"Running\",\"Writing\",\"Cooking\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Tamil\",\"Religion\":\"Hindu\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"They/Them\"]', 'Straight', '[\"Kindness\",\"Humour\",\"Honesty\"]', '[\"Physical touch\",\"Receiving gifts\"]', '[\"Morning\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-045-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-045-02.jpg\"]', 0, '154 cm', 'Prefer not to say', 'Sometimes', 'Sometimes', 'Global', 'Hindu', '[\"Tamil\"]', 'complete', 1, '2025-12-18 11:16:00', '2026-08-24 11:16:00', 'deep_conversations', 'Which city would you revisit tomorrow?'),
(1479, 1499, '1998-07-15', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\"]', 'Gandhinagar', 40, 'Software Engineer', 'Aster Health', 'Undergraduate', 'My ideal Sunday includes good coffee, a heritage walk, and cooking something ambitious. Hoping to meet someone warm who enjoys both plans and spontaneity. Tell me about a place you would revisit.', 'Vadodara', '[\"Photography\",\"Cycling\",\"Indie\",\"Live music\",\"Yoga\",\"Dogs\",\"Beaches\",\"Cafes\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Marathi & Punjabi & English\",\"Religion\":\"Hindu\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Open', '[\"Kindness\",\"Patience\",\"Empathy\"]', '[\"Quality time\",\"Acts of service\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-046-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-046-02.jpg\"]', 0, '161 cm', 'Never', 'Never', 'Prefer not to say', 'Open', 'Hindu', '[\"Marathi\",\"Punjabi\",\"English\"]', 'complete', 1, '2026-01-19 11:15:00', '2026-08-09 11:15:00', 'frequent_texting', 'Which city would you revisit tomorrow?'),
(1480, 1500, '1991-07-14', 'Female', '', '[\"Male\"]', '[\"Casual Connection\"]', 'Surat', 80, 'Designer', 'Northstar Collective', 'Professional', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. Bonus points for a great playlist.', 'Surat', '[\"Design\",\"Beaches\",\"Road trips\",\"Indie\",\"Cats\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Hindi\",\"Religion\":\"Muslim\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Kindness\",\"Patience\",\"Honesty\"]', '[\"Acts of service\",\"Words of affirmation\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-047-01.webp\",\"/uploads/onboarding-photos/amoraa-demo-profile-047-02.webp\"]', 0, '171 cm', 'Never', 'Sometimes', 'Sometimes', 'Indian', 'Muslim', '[\"Hindi\"]', 'complete', 1, '2026-05-31 11:14:00', '2026-08-21 11:14:00', 'occasional_texting', 'What is your signature dish?'),
(1481, 1501, '1996-07-13', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\",\"Exploring Possibilities\"]', 'Vadodara', 150, 'Finance', 'Independent', 'Undergraduate', 'My ideal Sunday includes good coffee, a heritage walk, and cooking something ambitious. Hoping to meet someone warm who enjoys both plans and spontaneity. I always make room for dessert.', 'Surat', '[\"Yoga\",\"Wildlife\",\"Road trips\",\"Baking\",\"Heritage walks\",\"Street food\",\"Cats\",\"City breaks\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Marathi & Malayalam\",\"Religion\":\"Open\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Creativity\",\"Honesty\",\"Kindness\"]', '[\"Receiving gifts\",\"Words of affirmation\"]', '[\"Late night\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-048-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-048-02.jpg\"]', 0, '167 cm', 'Sometimes', 'Never', 'Never', 'Global', 'Open', '[\"Marathi\",\"Malayalam\"]', 'complete', 1, '2026-07-18 11:13:00', '2026-08-13 11:13:00', 'deep_conversations', 'What is a small thing that made your week better?'),
(1482, 1502, '1985-07-12', 'Female', '', '[\"Male\"]', '[\"Marriage Minded\",\"Meaningful Dating\"]', 'Ahmedabad', 20, 'Architect', 'Daylight Design', 'Undergraduate', 'My ideal Sunday includes good coffee, a heritage walk, and cooking something ambitious. Hoping to meet someone warm who enjoys both plans and spontaneity. Tell me about a place you would revisit.', 'Gandhinagar', '[\"Road trips\",\"Pottery\",\"Beaches\",\"Indie\",\"Running\",\"Mindfulness\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"English\",\"Religion\":\"Spiritual\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Curiosity\",\"Patience\",\"Honesty\"]', '[\"Receiving gifts\",\"Quality time\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-049-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-049-02.jpg\"]', 0, '172 cm', 'Never', 'Yes', 'Never', 'Open', 'Spiritual', '[\"English\"]', 'complete', 1, '2025-10-15 11:12:00', '2026-08-16 11:12:00', 'light_fun_conversations', 'What is a small thing that made your week better?'),
(1483, 1503, '1981-07-11', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\",\"Meaningful Dating\"]', 'Gandhinagar', 40, 'Designer', 'Aster Health', 'Doctorate & Research', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Teach me something you love.', 'Ahmedabad', '[\"Running\",\"Classical\",\"Cats\",\"Hiking\",\"Cafes\",\"Writing\",\"Indie\",\"Cooking\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi\",\"Religion\":\"Hindu\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Straight', '[\"Curiosity\",\"Creativity\",\"Patience\"]', '[\"Receiving gifts\",\"Physical touch\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-050-01.webp\",\"/uploads/onboarding-photos/amoraa-demo-profile-050-02.jpg\"]', 0, '159 cm', 'Sometimes', 'Never', 'Sometimes', 'Gujarati', 'Hindu', '[\"Hindi\"]', 'complete', 1, '2026-02-03 11:11:00', '2026-08-12 11:11:00', 'light_fun_conversations', 'What is a small thing that made your week better?'),
(1484, 1504, '2000-07-10', 'Female', '', '[\"Male\"]', '[\"Exploring Possibilities\",\"Marriage Minded\"]', 'Surat', 80, 'Business Owner', 'Independent', 'Doctorate & Research', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Teach me something you love.', 'Gandhinagar', '[\"Gardening\",\"Beaches\",\"Yoga\",\"Street food\",\"Pottery\",\"Photography\",\"Cats\",\"Reading\",\"Cafes\",\"Road trips\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"English & Punjabi & Gujarati\",\"Religion\":\"Sikh\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Straight', '[\"Creativity\",\"Honesty\",\"Humour\"]', '[\"Physical touch\",\"Acts of service\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-051-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-051-02.jpg\"]', 0, '175 cm', 'Sometimes', 'Yes', 'Prefer not to say', 'Gujarati', 'Sikh', '[\"English\",\"Punjabi\",\"Gujarati\"]', 'complete', 1, '2025-08-19 11:10:00', '2026-08-26 11:10:00', 'voice_notes', 'What is your signature dish?'),
(1485, 1505, '1994-07-09', 'Male', '', '[\"Female\"]', '[\"Friendship First\"]', 'Vadodara', 150, 'Designer', 'Bluebird Labs', 'Professional', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Bonus points for a great playlist.', 'Vadodara', '[\"Coffee\",\"Road trips\",\"Street food\",\"Bollywood\",\"Running\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Punjabi & Gujarati & Tamil\",\"Religion\":\"Jain\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Kindness\",\"Patience\",\"Ambition\"]', '[\"Quality time\",\"Receiving gifts\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-052-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-052-02.jpg\"]', 0, '156 cm', 'Sometimes', 'Never', 'Sometimes', 'Gujarati', 'Jain', '[\"Punjabi\",\"Gujarati\",\"Tamil\"]', 'complete', 1, '2025-11-19 11:09:00', '2026-08-11 11:09:00', 'frequent_texting', 'Which city would you revisit tomorrow?'),
(1486, 1506, '1992-07-08', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Marriage Minded\"]', 'Ahmedabad', 20, 'Marketing', 'Acorn Studio', 'Undergraduate', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Tell me about a place you would revisit.', 'Vadodara', '[\"Dogs\",\"Beaches\",\"Yoga\",\"Hiking\",\"Writing\",\"Photography\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"English\",\"Religion\":\"Jain\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Humour\",\"Patience\",\"Empathy\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-053-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-053-02.jpg\"]', 0, '173 cm', 'Prefer not to say', 'Yes', 'Never', 'Gujarati', 'Jain', '[\"English\"]', 'complete', 1, '2025-08-20 11:08:00', '2026-08-19 11:08:00', 'frequent_texting', 'Which city would you revisit tomorrow?'),
(1487, 1507, '1983-07-07', 'Male', '', '[\"Female\"]', '[\"Casual Connection\"]', 'Gandhinagar', 40, 'Software Engineer', 'Daylight Design', 'Professional', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. I always make room for dessert.', 'Ahmedabad', '[\"Yoga\",\"Indie\",\"Volunteering\",\"Cycling\",\"Wildlife\",\"Mindfulness\",\"Writing\",\"Hiking\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Tamil & English & Malayalam\",\"Religion\":\"Jain\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Humour\",\"Patience\",\"Curiosity\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-054-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-054-02.jpg\"]', 0, '161 cm', 'Sometimes', 'Yes', 'Never', 'Gujarati', 'Jain', '[\"Tamil\",\"English\",\"Malayalam\"]', 'complete', 1, '2026-03-19 11:07:00', '2026-08-15 11:07:00', 'voice_notes', 'What is your signature dish?'),
(1488, 1508, '1984-07-06', 'Female', '', '[\"Male\"]', '[\"Marriage Minded\",\"Friendship First\"]', 'Surat', 80, 'Student', 'Saffron & Co.', 'Undergraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Teach me something you love.', 'Vadodara', '[\"Classical\",\"Design\",\"Live music\",\"Mindfulness\",\"Writing\",\"Pottery\",\"Cats\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Malayalam & Punjabi\",\"Religion\":\"Jain\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Open', '[\"Humour\",\"Patience\",\"Creativity\"]', '[\"Acts of service\",\"Quality time\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-055-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-055-02.jpg\"]', 0, '179 cm', 'Prefer not to say', 'Never', 'Sometimes', 'Indian', 'Jain', '[\"Malayalam\",\"Punjabi\"]', 'complete', 1, '2026-04-10 11:06:00', '2026-08-13 11:06:00', 'calls', 'What is a small thing that made your week better?');
INSERT INTO `onboardingprofiles` (`id`, `userId`, `birthDate`, `gender`, `customGender`, `interestedIn`, `relationshipGoals`, `city`, `preferredDistance`, `profession`, `company`, `education`, `bio`, `hometown`, `interests`, `lifestyle`, `prompts`, `pronouns`, `sexuality`, `valuedQualities`, `loveLanguages`, `preferredTalkingHours`, `photos`, `primaryPhotoIndex`, `height`, `smoking`, `drinking`, `weed`, `community`, `religion`, `languages`, `stage`, `onboardingCompleted`, `createdAt`, `updatedAt`, `communicationStyle`, `iceBreaker`) VALUES
(1489, 1509, '1978-07-05', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Meaningful Dating\",\"Casual Connection\"]', 'Vadodara', 150, 'Architect', 'Cedar Works', 'Postgraduate', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. I always make room for dessert.', 'Surat', '[\"Street food\",\"City breaks\",\"Dogs\",\"Road trips\",\"Cafes\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Gujarati\",\"Religion\":\"Hindu\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"They/Them\"]', 'Open', '[\"Ambition\",\"Empathy\",\"Curiosity\"]', '[\"Receiving gifts\",\"Acts of service\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-056-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-056-02.jpg\"]', 0, '152 cm', 'Sometimes', 'Yes', 'Never', 'Indian', 'Hindu', '[\"Gujarati\"]', 'complete', 1, '2025-08-19 11:05:00', '2026-08-15 11:05:00', 'voice_notes', 'What is a small thing that made your week better?'),
(1490, 1510, '1978-07-04', 'Female', '', '[\"Male\"]', '[\"Exploring Possibilities\",\"Marriage Minded\"]', 'Ahmedabad', 20, 'Architect', 'Cedar Works', 'Doctorate & Research', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. I always make room for dessert.', 'Gandhinagar', '[\"Design\",\"Street food\",\"Cycling\",\"Photography\",\"Wildlife\",\"Mindfulness\",\"Writing\",\"Live music\",\"Running\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Gujarati & English & Tamil\",\"Religion\":\"Hindu\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Open', '[\"Ambition\",\"Humour\",\"Patience\"]', '[\"Words of affirmation\",\"Receiving gifts\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-057-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-057-02.jpg\"]', 0, '194 cm', 'Prefer not to say', 'Yes', 'Sometimes', 'Gujarati', 'Hindu', '[\"Gujarati\",\"English\",\"Tamil\"]', 'complete', 1, '2025-09-08 11:04:00', '2026-08-26 11:04:00', 'frequent_texting', 'Which city would you revisit tomorrow?'),
(1491, 1511, '1987-07-03', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\",\"Friendship First\"]', 'Gandhinagar', 40, 'Finance', 'Acorn Studio', 'Undergraduate', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Teach me something you love.', 'Vadodara', '[\"Mindfulness\",\"Wildlife\",\"Heritage walks\",\"City breaks\",\"Volunteering\",\"Yoga\",\"Running\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Gujarati & Marathi & English\",\"Religion\":\"Jain\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Open', '[\"Honesty\",\"Kindness\",\"Ambition\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-058-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-058-02.jpg\"]', 0, '172 cm', 'Sometimes', 'Sometimes', 'Sometimes', 'Indian', 'Jain', '[\"Gujarati\",\"Marathi\",\"English\"]', 'complete', 1, '2025-08-06 11:03:00', '2026-08-17 11:03:00', 'occasional_texting', 'What is your signature dish?'),
(1492, 1512, '1988-07-02', 'Female', '', '[\"Male\"]', '[\"Exploring Possibilities\"]', 'Surat', 80, 'Entrepreneur', 'Acorn Studio', 'Postgraduate', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Teach me something you love.', 'Vadodara', '[\"Photography\",\"Yoga\",\"Indie\",\"Coffee\",\"Street food\",\"Writing\",\"Live music\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Marathi\",\"Religion\":\"Jain\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Patience\",\"Creativity\",\"Honesty\"]', '[\"Quality time\",\"Words of affirmation\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-059-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-059-02.jpg\"]', 0, '181 cm', 'Sometimes', 'Yes', 'Sometimes', 'Indian', 'Jain', '[\"Marathi\"]', 'complete', 1, '2026-08-12 11:02:00', '2026-08-17 11:02:00', 'voice_notes', 'What is a small thing that made your week better?'),
(1493, 1513, '1997-07-01', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\"]', 'Vadodara', 150, 'Software Engineer', 'Mosaic Ventures', 'Professional', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Bonus points for a great playlist.', 'Surat', '[\"Photography\",\"Design\",\"Hiking\",\"Bollywood\",\"Beaches\",\"Mindfulness\",\"City breaks\",\"Cycling\",\"Wildlife\",\"Reading\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Hindi\",\"Religion\":\"Sikh\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Straight', '[\"Honesty\",\"Kindness\",\"Humour\"]', '[\"Receiving gifts\",\"Physical touch\"]', '[\"Morning\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-060-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-060-02.jpg\"]', 0, '153 cm', 'Prefer not to say', 'Sometimes', 'Never', 'Gujarati', 'Sikh', '[\"Hindi\"]', 'complete', 1, '2026-08-02 11:01:00', '2026-08-19 11:01:00', 'voice_notes', 'What is a small thing that made your week better?'),
(1494, 1514, '1991-06-30', 'Female', '', '[\"Male\"]', '[\"Casual Connection\"]', 'Ahmedabad', 20, 'Designer', 'Northstar Collective', 'Postgraduate', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. I always make room for dessert.', 'Surat', '[\"Coffee\",\"Running\",\"Volunteering\",\"Bollywood\",\"Photography\",\"Pottery\",\"Street food\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Tamil & Punjabi & Malayalam\",\"Religion\":\"Jain\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Creativity\",\"Empathy\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-061-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-061-02.jpg\"]', 0, '190 cm', 'Prefer not to say', 'Never', 'Prefer not to say', 'Gujarati', 'Jain', '[\"Tamil\",\"Punjabi\",\"Malayalam\"]', 'complete', 1, '2025-12-27 11:00:00', '2026-08-10 11:00:00', 'voice_notes', 'Which city would you revisit tomorrow?'),
(1495, 1515, '1991-06-29', 'Male', '', '[\"Female\"]', '[\"Casual Connection\",\"Exploring Possibilities\"]', 'Gandhinagar', 40, 'Doctor', 'Riverstone', 'Doctorate & Research', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Teach me something you love.', 'Vadodara', '[\"Cats\",\"Running\",\"Classical\",\"Live music\",\"Yoga\",\"Indie\",\"Hiking\",\"Cycling\",\"Bollywood\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Tamil & Malayalam\",\"Religion\":\"Muslim\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Open', '[\"Ambition\",\"Creativity\",\"Empathy\"]', '[\"Physical touch\",\"Quality time\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-062-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-062-02.jpg\"]', 0, '170 cm', 'Prefer not to say', 'Yes', 'Prefer not to say', 'Open', 'Muslim', '[\"Tamil\",\"Malayalam\"]', 'complete', 1, '2026-05-26 10:59:00', '2026-08-16 10:59:00', 'voice_notes', 'What is your signature dish?'),
(1496, 1516, '1982-06-28', 'Female', '', '[\"Male\"]', '[\"Casual Connection\",\"Meaningful Dating\"]', 'Surat', 80, 'Marketing', 'Cedar Works', 'Postgraduate', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Teach me something you love.', 'Vadodara', '[\"Mindfulness\",\"Volunteering\",\"Yoga\",\"Cooking\",\"Gardening\",\"Live music\",\"Heritage walks\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Punjabi & Gujarati & English\",\"Religion\":\"Hindu\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Kindness\",\"Ambition\",\"Curiosity\"]', '[\"Words of affirmation\",\"Physical touch\"]', '[\"Late night\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-063-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-063-02.jpg\"]', 0, '158 cm', 'Never', 'Sometimes', 'Prefer not to say', 'Indian', 'Hindu', '[\"Punjabi\",\"Gujarati\",\"English\"]', 'complete', 1, '2025-12-08 10:58:00', '2026-08-22 10:58:00', 'deep_conversations', 'What is your signature dish?'),
(1497, 1517, '2004-06-27', 'Male', '', '[\"Female\"]', '[\"Meaningful Dating\"]', 'Vadodara', 150, 'Architect', 'Acorn Studio', 'Undergraduate', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Tell me about a place you would revisit.', 'Ahmedabad', '[\"Running\",\"Volunteering\",\"Road trips\",\"Baking\",\"Cats\",\"Classical\",\"Writing\",\"Bollywood\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Tamil & Malayalam & Marathi\",\"Religion\":\"Sikh\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Curiosity\",\"Honesty\",\"Creativity\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-064-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-064-02.jpg\"]', 0, '163 cm', 'Prefer not to say', 'Never', 'Prefer not to say', 'Gujarati', 'Sikh', '[\"Tamil\",\"Malayalam\",\"Marathi\"]', 'complete', 1, '2025-08-20 10:57:00', '2026-08-24 10:57:00', 'calls', 'Which city would you revisit tomorrow?'),
(1498, 1518, '1991-06-26', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\"]', 'Ahmedabad', 20, 'Business Owner', 'Mosaic Ventures', 'Postgraduate', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Teach me something you love.', 'Ahmedabad', '[\"Photography\",\"Cafes\",\"Pottery\",\"Heritage walks\",\"Hiking\",\"Cycling\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"English & Gujarati\",\"Religion\":\"Sikh\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Open', '[\"Patience\",\"Honesty\",\"Kindness\"]', '[\"Acts of service\",\"Receiving gifts\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-065-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-065-02.jpg\"]', 0, '173 cm', 'Sometimes', 'Yes', 'Sometimes', 'Indian', 'Sikh', '[\"English\",\"Gujarati\"]', 'complete', 1, '2026-08-21 10:56:00', '2026-08-24 10:56:00', 'voice_notes', 'What is your signature dish?'),
(1499, 1519, '2001-06-25', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\"]', 'Gandhinagar', 40, 'Doctor', 'Acorn Studio', 'Professional', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. I always make room for dessert.', 'Gandhinagar', '[\"Reading\",\"Classical\",\"City breaks\",\"Bollywood\",\"Pottery\",\"Coffee\",\"Cooking\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Gujarati & Punjabi & Marathi\",\"Religion\":\"Spiritual\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Straight', '[\"Empathy\",\"Creativity\",\"Kindness\"]', '[\"Words of affirmation\",\"Receiving gifts\"]', '[\"Morning\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-066-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-066-02.jpg\"]', 0, '185 cm', 'Prefer not to say', 'Sometimes', 'Never', 'Global', 'Spiritual', '[\"Gujarati\",\"Punjabi\",\"Marathi\"]', 'complete', 1, '2025-12-23 10:55:00', '2026-08-27 10:55:00', 'voice_notes', 'What is a small thing that made your week better?'),
(1500, 1520, '1999-06-24', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Exploring Possibilities\",\"Meaningful Dating\"]', 'Surat', 80, 'Doctor', 'Northstar Collective', 'Professional', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Bonus points for a great playlist.', 'Surat', '[\"Cooking\",\"Writing\",\"Cycling\",\"Cats\",\"Design\",\"Coffee\",\"Bollywood\",\"Volunteering\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Hindi\",\"Religion\":\"Hindu\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"They/Them\"]', 'Open', '[\"Patience\",\"Kindness\",\"Ambition\"]', '[\"Acts of service\",\"Quality time\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-067-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-067-02.jpg\"]', 0, '154 cm', 'Sometimes', 'Sometimes', 'Sometimes', 'Global', 'Hindu', '[\"Hindi\"]', 'complete', 1, '2026-02-26 10:54:00', '2026-08-17 10:54:00', 'light_fun_conversations', 'What is a small thing that made your week better?'),
(1501, 1521, '1989-06-23', 'Male', '', '[\"Female\"]', '[\"Friendship First\"]', 'Vadodara', 150, 'Entrepreneur', 'Independent', 'Professional', 'My ideal Sunday includes good coffee, a heritage walk, and cooking something ambitious. Hoping to meet someone warm who enjoys both plans and spontaneity. Bonus points for a great playlist.', 'Ahmedabad', '[\"City breaks\",\"Live music\",\"Photography\",\"Hiking\",\"Volunteering\",\"Gardening\",\"Wildlife\",\"Baking\",\"Coffee\",\"Dogs\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Hindi & English\",\"Religion\":\"Spiritual\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Honesty\",\"Ambition\",\"Curiosity\"]', '[\"Acts of service\",\"Receiving gifts\"]', '[\"Morning\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-068-01.webp\",\"/uploads/onboarding-photos/amoraa-demo-profile-068-02.jpg\"]', 0, '169 cm', 'Sometimes', 'Sometimes', 'Sometimes', 'Global', 'Spiritual', '[\"Hindi\",\"English\"]', 'complete', 1, '2025-07-18 10:53:00', '2026-08-12 10:53:00', 'voice_notes', 'What is a small thing that made your week better?'),
(1502, 1522, '1982-06-22', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Long-Term Relationship\"]', 'Ahmedabad', 20, 'Architect', 'Daylight Design', 'Postgraduate', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. I always make room for dessert.', 'Vadodara', '[\"Heritage walks\",\"Gardening\",\"Photography\",\"Cafes\",\"Pottery\",\"Classical\",\"Writing\",\"Coffee\",\"Dogs\",\"Baking\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Gujarati & English & Tamil\",\"Religion\":\"Open\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Open', '[\"Humour\",\"Patience\",\"Honesty\"]', '[\"Words of affirmation\",\"Receiving gifts\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-069-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-069-02.jpg\"]', 0, '167 cm', 'Prefer not to say', 'Never', 'Never', 'Indian', 'Open', '[\"Gujarati\",\"English\",\"Tamil\"]', 'complete', 1, '2025-11-30 10:52:00', '2026-08-21 10:52:00', 'deep_conversations', 'What is your signature dish?'),
(1503, 1523, '1998-06-21', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\"]', 'Gandhinagar', 40, 'Doctor', 'Bluebird Labs', 'Professional', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. I always make room for dessert.', 'Ahmedabad', '[\"Coffee\",\"Bollywood\",\"Cafes\",\"Street food\",\"Baking\",\"Live music\",\"Beaches\",\"Gardening\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi & Punjabi & Marathi\",\"Religion\":\"Hindu\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Open', '[\"Curiosity\",\"Humour\",\"Ambition\"]', '[\"Quality time\",\"Words of affirmation\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-070-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-070-02.jpg\"]', 0, '179 cm', 'Prefer not to say', 'Never', 'Prefer not to say', 'Indian', 'Hindu', '[\"Hindi\",\"Punjabi\",\"Marathi\"]', 'complete', 1, '2026-07-13 10:51:00', '2026-08-17 10:51:00', 'voice_notes', 'Which city would you revisit tomorrow?'),
(1504, 1524, '1986-06-20', 'Female', '', '[\"Male\"]', '[\"Friendship First\"]', 'Surat', 80, 'Doctor', 'Mosaic Ventures', 'Postgraduate', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Teach me something you love.', 'Gandhinagar', '[\"Live music\",\"Cats\",\"Bollywood\",\"Street food\",\"Classical\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Gujarati\",\"Religion\":\"Jain\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Humour\",\"Kindness\",\"Patience\"]', '[\"Physical touch\",\"Acts of service\"]', '[\"Morning\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-071-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-071-02.jpg\"]', 0, '158 cm', 'Sometimes', 'Yes', 'Prefer not to say', 'Global', 'Jain', '[\"Gujarati\"]', 'complete', 1, '2025-11-01 10:50:00', '2026-08-17 10:50:00', 'deep_conversations', 'Which city would you revisit tomorrow?'),
(1505, 1525, '2004-06-19', 'Male', '', '[\"Female\"]', '[\"Casual Connection\"]', 'Vadodara', 150, 'Student', 'Cedar Works', 'Undergraduate', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. Tell me about a place you would revisit.', 'Surat', '[\"Wildlife\",\"Road trips\",\"Street food\",\"Reading\",\"Gardening\",\"Beaches\",\"Cycling\",\"Indie\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Gujarati & Hindi & Tamil\",\"Religion\":\"Open\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Open', '[\"Patience\",\"Kindness\",\"Creativity\"]', '[\"Quality time\",\"Physical touch\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-072-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-072-02.jpg\"]', 0, '159 cm', 'Sometimes', 'Yes', 'Sometimes', 'Indian', 'Open', '[\"Gujarati\",\"Hindi\",\"Tamil\"]', 'complete', 1, '2026-06-25 10:49:00', '2026-08-16 10:49:00', 'occasional_texting', 'Which city would you revisit tomorrow?'),
(1506, 1526, '2003-06-18', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\",\"Casual Connection\"]', 'Ahmedabad', 20, 'Software Engineer', 'Daylight Design', 'Doctorate & Research', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Teach me something you love.', 'Ahmedabad', '[\"Volunteering\",\"Dogs\",\"Classical\",\"City breaks\",\"Reading\",\"Running\",\"Yoga\",\"Bollywood\",\"Live music\",\"Baking\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Gujarati & Hindi\",\"Religion\":\"Sikh\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Open', '[\"Curiosity\",\"Kindness\",\"Ambition\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-073-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-073-02.jpg\"]', 0, '179 cm', 'Never', 'Yes', 'Prefer not to say', 'Open', 'Sikh', '[\"Gujarati\",\"Hindi\"]', 'complete', 1, '2026-02-13 10:48:00', '2026-08-17 10:48:00', 'light_fun_conversations', 'What is your signature dish?'),
(1507, 1527, '2002-06-17', 'Male', '', '[\"Female\"]', '[\"Friendship First\"]', 'Gandhinagar', 40, 'Finance', 'Aster Health', 'Doctorate & Research', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Tell me about a place you would revisit.', 'Gandhinagar', '[\"Street food\",\"Mindfulness\",\"Cats\",\"Cycling\",\"Beaches\",\"Yoga\",\"Dogs\",\"Reading\",\"Live music\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi & Gujarati\",\"Religion\":\"Hindu\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Open', '[\"Curiosity\",\"Kindness\",\"Ambition\"]', '[\"Physical touch\",\"Quality time\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-074-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-074-02.jpg\"]', 0, '182 cm', 'Prefer not to say', 'Sometimes', 'Sometimes', 'Gujarati', 'Hindu', '[\"Hindi\",\"Gujarati\"]', 'complete', 1, '2025-07-08 10:47:00', '2026-08-24 10:47:00', 'deep_conversations', 'What is a small thing that made your week better?'),
(1508, 1528, '1986-06-16', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Long-Term Relationship\"]', 'Surat', 80, 'Designer', 'Mosaic Ventures', 'Doctorate & Research', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Tell me about a place you would revisit.', 'Surat', '[\"Reading\",\"Dogs\",\"Cafes\",\"Writing\",\"Wildlife\",\"Bollywood\",\"Mindfulness\",\"Hiking\",\"Classical\",\"Gardening\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"English & Hindi & Gujarati\",\"Religion\":\"Jain\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Open', '[\"Ambition\",\"Empathy\",\"Humour\"]', '[\"Receiving gifts\",\"Words of affirmation\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-075-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-075-02.jpg\"]', 0, '161 cm', 'Never', 'Yes', 'Prefer not to say', 'Open', 'Jain', '[\"English\",\"Hindi\",\"Gujarati\"]', 'complete', 1, '2025-09-29 10:46:00', '2026-08-28 10:46:00', 'frequent_texting', 'What is a small thing that made your week better?'),
(1509, 1529, '1997-06-15', 'Male', '', '[\"Female\"]', '[\"Friendship First\",\"Long-Term Relationship\"]', 'Vadodara', 150, 'Doctor', 'Saffron & Co.', 'Undergraduate', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Bonus points for a great playlist.', 'Gandhinagar', '[\"Classical\",\"Baking\",\"Beaches\",\"Design\",\"Cafes\",\"Cycling\",\"Pottery\",\"Volunteering\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Hindi & Malayalam & Punjabi\",\"Religion\":\"Spiritual\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Straight', '[\"Ambition\",\"Humour\",\"Patience\"]', '[\"Quality time\",\"Words of affirmation\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-076-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-076-02.jpg\"]', 0, '190 cm', 'Prefer not to say', 'Yes', 'Prefer not to say', 'Gujarati', 'Spiritual', '[\"Hindi\",\"Malayalam\",\"Punjabi\"]', 'complete', 1, '2025-07-15 10:45:00', '2026-08-12 10:45:00', 'calls', 'What is a small thing that made your week better?'),
(1510, 1530, '1989-06-14', 'Female', '', '[\"Male\"]', '[\"Casual Connection\",\"Exploring Possibilities\"]', 'Ahmedabad', 20, 'Student', 'Bluebird Labs', 'Postgraduate', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Bonus points for a great playlist.', 'Vadodara', '[\"Mindfulness\",\"Cooking\",\"Wildlife\",\"Beaches\",\"Heritage walks\",\"Cats\",\"Gardening\",\"Cycling\",\"Pottery\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Malayalam & English & Marathi\",\"Religion\":\"Sikh\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Ambition\",\"Empathy\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-077-01.png\",\"/uploads/onboarding-photos/amoraa-demo-profile-077-02.jpg\"]', 0, '165 cm', 'Never', 'Sometimes', 'Sometimes', 'Gujarati', 'Sikh', '[\"Malayalam\",\"English\",\"Marathi\"]', 'complete', 1, '2025-10-08 10:44:00', '2026-08-29 10:44:00', 'light_fun_conversations', 'Which city would you revisit tomorrow?'),
(1511, 1531, '1986-06-13', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Long-Term Relationship\",\"Marriage Minded\"]', 'Gandhinagar', 40, 'Doctor', 'Daylight Design', 'Professional', 'My ideal Sunday includes good coffee, a heritage walk, and cooking something ambitious. Hoping to meet someone warm who enjoys both plans and spontaneity. I always make room for dessert.', 'Surat', '[\"Design\",\"Writing\",\"Running\",\"Bollywood\",\"Hiking\",\"Pottery\",\"Reading\",\"Cats\",\"Road trips\",\"Live music\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Marathi & Tamil\",\"Religion\":\"Sikh\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"They/Them\"]', 'Bisexual', '[\"Humour\",\"Honesty\",\"Ambition\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Morning\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-078-01.webp\",\"/uploads/onboarding-photos/amoraa-demo-profile-078-02.jpg\"]', 0, '160 cm', 'Never', 'Yes', 'Never', 'Gujarati', 'Sikh', '[\"Marathi\",\"Tamil\"]', 'complete', 1, '2025-09-09 10:43:00', '2026-08-22 10:43:00', 'deep_conversations', 'Which city would you revisit tomorrow?'),
(1512, 1532, '1998-06-12', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\",\"Exploring Possibilities\"]', 'Surat', 80, 'Marketing', 'Bluebird Labs', 'Undergraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Teach me something you love.', 'Ahmedabad', '[\"Reading\",\"Street food\",\"Wildlife\",\"Hiking\",\"Baking\",\"Cats\",\"Pottery\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Punjabi\",\"Religion\":\"Christian\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Curiosity\",\"Empathy\",\"Creativity\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-079-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-079-02.jpg\"]', 0, '159 cm', 'Prefer not to say', 'Sometimes', 'Prefer not to say', 'Indian', 'Christian', '[\"Punjabi\"]', 'complete', 1, '2026-05-13 10:42:00', '2026-08-09 10:42:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1513, 1533, '1982-06-11', 'Male', '', '[\"Female\"]', '[\"Casual Connection\"]', 'Vadodara', 150, 'Business Owner', 'Cedar Works', 'Postgraduate', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. I always make room for dessert.', 'Vadodara', '[\"Cats\",\"Road trips\",\"Yoga\",\"Cooking\",\"Bollywood\",\"Hiking\",\"Cafes\",\"Writing\",\"Cycling\",\"Gardening\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Punjabi & Malayalam\",\"Religion\":\"Jain\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Straight', '[\"Creativity\",\"Ambition\",\"Patience\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-080-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-080-02.jpg\"]', 0, '194 cm', 'Sometimes', 'Never', 'Sometimes', 'Gujarati', 'Jain', '[\"Punjabi\",\"Malayalam\"]', 'complete', 1, '2025-12-28 10:41:00', '2026-08-26 10:41:00', 'frequent_texting', 'What is your signature dish?'),
(1514, 1534, '2002-06-10', 'Female', '', '[\"Male\"]', '[\"Casual Connection\"]', 'Ahmedabad', 20, 'Doctor', 'Bluebird Labs', 'Postgraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Bonus points for a great playlist.', 'Gandhinagar', '[\"Writing\",\"Design\",\"Mindfulness\",\"Yoga\",\"Gardening\",\"Cafes\",\"Beaches\",\"Live music\",\"Running\",\"Bollywood\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Tamil\",\"Religion\":\"Hindu\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Creativity\",\"Ambition\",\"Patience\"]', '[\"Quality time\",\"Words of affirmation\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-081-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-081-02.jpg\"]', 0, '188 cm', 'Sometimes', 'Never', 'Never', 'Indian', 'Hindu', '[\"Tamil\"]', 'complete', 1, '2026-08-01 10:40:00', '2026-08-13 10:40:00', 'frequent_texting', 'What is a small thing that made your week better?'),
(1515, 1535, '1983-06-09', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\",\"Long-Term Relationship\"]', 'Gandhinagar', 40, 'Student', 'Mosaic Ventures', 'Undergraduate', 'My ideal Sunday includes good coffee, a heritage walk, and cooking something ambitious. Hoping to meet someone warm who enjoys both plans and spontaneity. Teach me something you love.', 'Ahmedabad', '[\"Cats\",\"Photography\",\"Live music\",\"Cycling\",\"Baking\",\"Gardening\",\"Mindfulness\",\"Volunteering\",\"Classical\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Marathi & Gujarati\",\"Religion\":\"Sikh\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Open', '[\"Humour\",\"Curiosity\",\"Kindness\"]', '[\"Physical touch\",\"Receiving gifts\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-082-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-082-02.jpg\"]', 0, '188 cm', 'Prefer not to say', 'Sometimes', 'Prefer not to say', 'Indian', 'Sikh', '[\"Marathi\",\"Gujarati\"]', 'complete', 1, '2026-02-22 10:39:00', '2026-08-26 10:39:00', 'voice_notes', 'Which city would you revisit tomorrow?'),
(1516, 1536, '1993-06-08', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Meaningful Dating\"]', 'Surat', 80, 'Finance', 'Bluebird Labs', 'Undergraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Teach me something you love.', 'Ahmedabad', '[\"Live music\",\"City breaks\",\"Road trips\",\"Coffee\",\"Hiking\",\"Yoga\",\"Dogs\",\"Bollywood\",\"Gardening\",\"Volunteering\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Punjabi & Malayalam\",\"Religion\":\"Sikh\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Curiosity\",\"Patience\",\"Ambition\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Late night\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-083-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-083-02.jpg\"]', 0, '155 cm', 'Prefer not to say', 'Sometimes', 'Never', 'Open', 'Sikh', '[\"Punjabi\",\"Malayalam\"]', 'complete', 1, '2026-03-23 10:38:00', '2026-08-27 10:38:00', 'light_fun_conversations', 'What is a small thing that made your week better?'),
(1517, 1537, '1981-06-07', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\"]', 'Vadodara', 150, 'Student', 'Northstar Collective', 'Professional', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Bonus points for a great playlist.', 'Vadodara', '[\"Volunteering\",\"Pottery\",\"Baking\",\"Beaches\",\"Gardening\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Punjabi & Tamil & Hindi\",\"Religion\":\"Jain\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Humour\",\"Kindness\",\"Ambition\"]', '[\"Words of affirmation\",\"Quality time\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-084-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-084-02.jpg\"]', 0, '155 cm', 'Prefer not to say', 'Yes', 'Sometimes', 'Indian', 'Jain', '[\"Punjabi\",\"Tamil\",\"Hindi\"]', 'complete', 1, '2026-02-03 10:37:00', '2026-08-16 10:37:00', 'deep_conversations', 'What is your signature dish?'),
(1518, 1538, '2000-06-06', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\",\"Friendship First\"]', 'Ahmedabad', 20, 'Architect', 'Cedar Works', 'Professional', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Bonus points for a great playlist.', 'Surat', '[\"Dogs\",\"Reading\",\"Indie\",\"Mindfulness\",\"Design\",\"Classical\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Tamil\",\"Religion\":\"Sikh\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Open', '[\"Humour\",\"Creativity\",\"Empathy\"]', '[\"Physical touch\",\"Acts of service\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-085-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-085-02.jpg\"]', 0, '169 cm', 'Never', 'Sometimes', 'Never', 'Indian', 'Sikh', '[\"Tamil\"]', 'complete', 1, '2025-08-11 10:36:00', '2026-08-22 10:36:00', 'occasional_texting', 'What is your signature dish?'),
(1519, 1539, '1980-06-05', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\",\"Marriage Minded\"]', 'Gandhinagar', 40, 'Student', 'Saffron & Co.', 'Professional', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Teach me something you love.', 'Ahmedabad', '[\"Writing\",\"Gardening\",\"Road trips\",\"Street food\",\"Reading\",\"City breaks\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi & Punjabi\",\"Religion\":\"Open\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Straight', '[\"Empathy\",\"Curiosity\",\"Patience\"]', '[\"Acts of service\",\"Words of affirmation\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-086-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-086-02.jpg\"]', 0, '153 cm', 'Never', 'Never', 'Prefer not to say', 'Indian', 'Open', '[\"Hindi\",\"Punjabi\"]', 'complete', 1, '2025-08-05 10:35:00', '2026-08-21 10:35:00', 'deep_conversations', 'Which city would you revisit tomorrow?'),
(1520, 1540, '1999-06-04', 'Female', '', '[\"Male\"]', '[\"Exploring Possibilities\"]', 'Surat', 80, 'Finance', 'Bluebird Labs', 'Doctorate & Research', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Tell me about a place you would revisit.', 'Surat', '[\"Mindfulness\",\"Reading\",\"Running\",\"City breaks\",\"Indie\",\"Writing\",\"Gardening\",\"Live music\",\"Design\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Tamil & Malayalam\",\"Religion\":\"Muslim\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Honesty\",\"Patience\"]', '[\"Receiving gifts\",\"Quality time\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-087-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-087-02.jpg\"]', 0, '183 cm', 'Never', 'Sometimes', 'Prefer not to say', 'Gujarati', 'Muslim', '[\"Tamil\",\"Malayalam\"]', 'complete', 1, '2025-09-21 10:34:00', '2026-08-16 10:34:00', 'occasional_texting', 'What is your signature dish?'),
(1521, 1541, '1998-06-03', 'Male', '', '[\"Female\"]', '[\"Friendship First\"]', 'Vadodara', 150, 'Finance', 'Independent', 'Postgraduate', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. I always make room for dessert.', 'Gandhinagar', '[\"Cafes\",\"Volunteering\",\"Dogs\",\"Indie\",\"Classical\",\"Running\",\"Heritage walks\",\"Beaches\",\"Live music\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Punjabi\",\"Religion\":\"Open\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Straight', '[\"Curiosity\",\"Humour\",\"Honesty\"]', '[\"Acts of service\",\"Words of affirmation\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-088-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-088-02.jpg\"]', 0, '192 cm', 'Prefer not to say', 'Yes', 'Prefer not to say', 'Indian', 'Open', '[\"Punjabi\"]', 'complete', 1, '2026-06-12 10:33:00', '2026-08-25 10:33:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1522, 1542, '1988-06-02', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Long-Term Relationship\"]', 'Ahmedabad', 20, 'Business Owner', 'Bluebird Labs', 'Undergraduate', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. I always make room for dessert.', 'Vadodara', '[\"Writing\",\"Wildlife\",\"Road trips\",\"Cafes\",\"Cooking\",\"Gardening\",\"Cats\",\"Bollywood\",\"Beaches\",\"Yoga\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Malayalam & Punjabi & Tamil\",\"Religion\":\"Sikh\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"They/Them\"]', 'Open', '[\"Honesty\",\"Creativity\",\"Humour\"]', '[\"Words of affirmation\",\"Quality time\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-089-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-089-02.jpg\"]', 0, '161 cm', 'Never', 'Sometimes', 'Never', 'Open', 'Sikh', '[\"Malayalam\",\"Punjabi\",\"Tamil\"]', 'complete', 1, '2025-08-06 10:32:00', '2026-08-24 10:32:00', 'voice_notes', 'Which city would you revisit tomorrow?'),
(1523, 1543, '1990-06-01', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\"]', 'Gandhinagar', 40, 'Doctor', 'Bluebird Labs', 'Postgraduate', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. Tell me about a place you would revisit.', 'Ahmedabad', '[\"Bollywood\",\"Live music\",\"City breaks\",\"Coffee\",\"Pottery\",\"Classical\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi & Punjabi & Marathi\",\"Religion\":\"Open\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Open', '[\"Patience\",\"Humour\",\"Kindness\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-090-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-090-02.jpg\"]', 0, '151 cm', 'Prefer not to say', 'Yes', 'Never', 'Gujarati', 'Open', '[\"Hindi\",\"Punjabi\",\"Marathi\"]', 'complete', 1, '2025-12-31 10:31:00', '2026-08-17 10:31:00', 'calls', 'Which city would you revisit tomorrow?'),
(1524, 1544, '1978-05-31', 'Female', '', '[\"Male\"]', '[\"Friendship First\"]', 'Surat', 80, 'Student', 'Independent', 'Professional', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Teach me something you love.', 'Vadodara', '[\"Classical\",\"Street food\",\"Baking\",\"Cats\",\"Cooking\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Punjabi\",\"Religion\":\"Sikh\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Patience\",\"Honesty\",\"Humour\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-091-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-091-02.jpg\"]', 0, '163 cm', 'Prefer not to say', 'Sometimes', 'Prefer not to say', 'Gujarati', 'Sikh', '[\"Punjabi\"]', 'complete', 1, '2026-02-05 10:30:00', '2026-08-21 10:30:00', 'occasional_texting', 'Which city would you revisit tomorrow?');
INSERT INTO `onboardingprofiles` (`id`, `userId`, `birthDate`, `gender`, `customGender`, `interestedIn`, `relationshipGoals`, `city`, `preferredDistance`, `profession`, `company`, `education`, `bio`, `hometown`, `interests`, `lifestyle`, `prompts`, `pronouns`, `sexuality`, `valuedQualities`, `loveLanguages`, `preferredTalkingHours`, `photos`, `primaryPhotoIndex`, `height`, `smoking`, `drinking`, `weed`, `community`, `religion`, `languages`, `stage`, `onboardingCompleted`, `createdAt`, `updatedAt`, `communicationStyle`, `iceBreaker`) VALUES
(1525, 1545, '2005-05-30', 'Male', '', '[\"Female\"]', '[\"Casual Connection\"]', 'Vadodara', 150, 'Software Engineer', 'Northstar Collective', 'Professional', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Tell me about a place you would revisit.', 'Ahmedabad', '[\"Heritage walks\",\"Indie\",\"Photography\",\"Beaches\",\"Dogs\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Gujarati & Punjabi\",\"Religion\":\"Sikh\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Open', '[\"Creativity\",\"Ambition\",\"Curiosity\"]', '[\"Words of affirmation\",\"Physical touch\"]', '[\"Late night\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-092-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-092-02.jpg\"]', 0, '191 cm', 'Never', 'Sometimes', 'Never', 'Open', 'Sikh', '[\"Gujarati\",\"Punjabi\"]', 'complete', 1, '2026-03-11 10:29:00', '2026-08-18 10:29:00', 'calls', 'What is your signature dish?'),
(1526, 1546, '2005-05-29', 'Female', '', '[\"Male\"]', '[\"Exploring Possibilities\",\"Long-Term Relationship\"]', 'Ahmedabad', 20, 'Designer', 'Northstar Collective', 'Postgraduate', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Teach me something you love.', 'Ahmedabad', '[\"Coffee\",\"Photography\",\"Volunteering\",\"Live music\",\"Street food\",\"Wildlife\",\"Pottery\",\"Gardening\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Hindi\",\"Religion\":\"Hindu\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Empathy\",\"Ambition\",\"Creativity\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-093-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-093-02.jpg\"]', 0, '194 cm', 'Sometimes', 'Yes', 'Prefer not to say', 'Open', 'Hindu', '[\"Hindi\"]', 'complete', 1, '2026-04-25 10:28:00', '2026-08-29 10:28:00', 'voice_notes', 'Which city would you revisit tomorrow?'),
(1527, 1547, '2000-05-28', 'Male', '', '[\"Female\"]', '[\"Long-Term Relationship\"]', 'Gandhinagar', 40, 'Doctor', 'Northstar Collective', 'Doctorate & Research', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Tell me about a place you would revisit.', 'Vadodara', '[\"Live music\",\"Yoga\",\"Indie\",\"Cafes\",\"Gardening\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Tamil & Malayalam\",\"Religion\":\"Christian\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Ambition\",\"Creativity\",\"Kindness\"]', '[\"Receiving gifts\",\"Physical touch\"]', '[\"Morning\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-094-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-094-02.jpg\"]', 0, '160 cm', 'Sometimes', 'Never', 'Never', 'Gujarati', 'Christian', '[\"Tamil\",\"Malayalam\"]', 'complete', 1, '2026-02-19 10:27:00', '2026-08-09 10:27:00', 'frequent_texting', 'What is a small thing that made your week better?'),
(1528, 1548, '1980-05-27', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\",\"Friendship First\"]', 'Surat', 80, 'Designer', 'Aster Health', 'Undergraduate', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Teach me something you love.', 'Surat', '[\"Volunteering\",\"Cooking\",\"Yoga\",\"Running\",\"Reading\",\"Cafes\",\"Coffee\",\"Bollywood\",\"Baking\",\"Beaches\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Marathi & English & Malayalam\",\"Religion\":\"Sikh\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Open', '[\"Empathy\",\"Patience\",\"Creativity\"]', '[\"Quality time\",\"Receiving gifts\"]', '[\"Late night\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-095-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-095-02.jpg\"]', 0, '188 cm', 'Never', 'Never', 'Never', 'Global', 'Sikh', '[\"Marathi\",\"English\",\"Malayalam\"]', 'complete', 1, '2026-07-17 10:26:00', '2026-08-27 10:26:00', 'occasional_texting', 'Which city would you revisit tomorrow?'),
(1529, 1549, '1984-05-26', 'Male', '', '[\"Female\"]', '[\"Casual Connection\",\"Meaningful Dating\"]', 'Vadodara', 150, 'Designer', 'Saffron & Co.', 'Professional', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. I always make room for dessert.', 'Surat', '[\"Cafes\",\"Gardening\",\"Heritage walks\",\"Baking\",\"Pottery\",\"Cooking\",\"Cats\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Gujarati & English & Punjabi\",\"Religion\":\"Muslim\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Honesty\",\"Kindness\",\"Patience\"]', '[\"Acts of service\",\"Words of affirmation\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-096-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-096-02.jpg\"]', 0, '168 cm', 'Never', 'Yes', 'Never', 'Gujarati', 'Muslim', '[\"Gujarati\",\"English\",\"Punjabi\"]', 'complete', 1, '2026-07-29 10:25:00', '2026-08-20 10:25:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1530, 1550, '1985-05-25', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 20, 'Student', 'Northstar Collective', 'Postgraduate', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Tell me about a place you would revisit.', 'Surat', '[\"Wildlife\",\"Cafes\",\"Gardening\",\"Dogs\",\"Photography\",\"Beaches\",\"Writing\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Hindi\",\"Religion\":\"Christian\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Creativity\",\"Ambition\",\"Honesty\"]', '[\"Words of affirmation\",\"Quality time\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-097-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-097-02.jpg\"]', 0, '185 cm', 'Sometimes', 'Sometimes', 'Sometimes', 'Indian', 'Christian', '[\"Hindi\"]', 'complete', 1, '2025-10-18 10:24:00', '2026-08-10 10:24:00', 'calls', 'Which city would you revisit tomorrow?'),
(1531, 1551, '1995-05-24', 'Male', '', '[\"Female\"]', '[\"Friendship First\"]', 'Gandhinagar', 40, 'Marketing', 'Aster Health', 'Postgraduate', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. I always make room for dessert.', 'Ahmedabad', '[\"Reading\",\"Mindfulness\",\"Heritage walks\",\"Coffee\",\"Gardening\",\"Wildlife\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi\",\"Religion\":\"Sikh\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Open', '[\"Creativity\",\"Empathy\",\"Honesty\"]', '[\"Words of affirmation\",\"Quality time\"]', '[\"Morning\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-098-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-098-02.jpg\"]', 0, '153 cm', 'Never', 'Never', 'Never', 'Gujarati', 'Sikh', '[\"Hindi\"]', 'complete', 1, '2026-08-16 10:23:00', '2026-08-16 10:23:00', 'voice_notes', 'What is a small thing that made your week better?'),
(1532, 1552, '1986-05-23', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Exploring Possibilities\"]', 'Surat', 80, 'Finance', 'Independent', 'Professional', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Teach me something you love.', 'Gandhinagar', '[\"Yoga\",\"Baking\",\"Beaches\",\"Photography\",\"Cooking\",\"Dogs\",\"Street food\",\"Writing\",\"Cats\",\"Mindfulness\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Tamil & Malayalam\",\"Religion\":\"Hindu\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Straight', '[\"Honesty\",\"Curiosity\",\"Kindness\"]', '[\"Physical touch\",\"Receiving gifts\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-099-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-099-02.jpg\"]', 0, '194 cm', 'Never', 'Never', 'Prefer not to say', 'Gujarati', 'Hindu', '[\"Tamil\",\"Malayalam\"]', 'complete', 1, '2025-07-29 10:22:00', '2026-08-15 10:22:00', 'calls', 'Which city would you revisit tomorrow?'),
(1533, 1553, '1997-05-22', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Marriage Minded\"]', 'Vadodara', 150, 'Student', 'Cedar Works', 'Postgraduate', 'My ideal Sunday includes good coffee, a heritage walk, and cooking something ambitious. Hoping to meet someone warm who enjoys both plans and spontaneity. Tell me about a place you would revisit.', 'Surat', '[\"Gardening\",\"Cooking\",\"Mindfulness\",\"Volunteering\",\"Pottery\",\"Bollywood\",\"Photography\",\"Street food\",\"Beaches\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Tamil\",\"Religion\":\"Open\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"They/Them\"]', 'Open', '[\"Creativity\",\"Curiosity\",\"Patience\"]', '[\"Words of affirmation\",\"Physical touch\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-100-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-100-02.jpg\"]', 0, '154 cm', 'Prefer not to say', 'Yes', 'Sometimes', 'Gujarati', 'Open', '[\"Tamil\"]', 'complete', 1, '2026-04-30 10:21:00', '2026-08-27 10:21:00', 'calls', 'Which city would you revisit tomorrow?'),
(1534, 1554, '1981-05-21', 'Female', '', '[\"Male\"]', '[\"Marriage Minded\",\"Exploring Possibilities\"]', 'Ahmedabad', 20, 'Student', 'Independent', 'Doctorate & Research', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Bonus points for a great playlist.', 'Vadodara', '[\"Baking\",\"Indie\",\"Hiking\",\"Photography\",\"Cafes\",\"Bollywood\",\"Cycling\",\"Writing\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Tamil & English & Hindi\",\"Religion\":\"Muslim\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Patience\",\"Humour\"]', '[\"Quality time\",\"Acts of service\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-101-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-101-02.jpg\"]', 0, '182 cm', 'Prefer not to say', 'Sometimes', 'Prefer not to say', 'Open', 'Muslim', '[\"Tamil\",\"English\",\"Hindi\"]', 'complete', 1, '2025-12-01 10:20:00', '2026-08-17 10:20:00', 'calls', 'Which city would you revisit tomorrow?'),
(1535, 1555, '2000-05-20', 'Male', '', '[\"Female\"]', '[\"Friendship First\",\"Casual Connection\"]', 'Gandhinagar', 40, 'Designer', 'Saffron & Co.', 'Doctorate & Research', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Bonus points for a great playlist.', 'Gandhinagar', '[\"Reading\",\"Road trips\",\"Beaches\",\"Yoga\",\"Pottery\",\"Wildlife\",\"Classical\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Malayalam & Tamil & Punjabi\",\"Religion\":\"Christian\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Ambition\",\"Kindness\",\"Patience\"]', '[\"Acts of service\",\"Receiving gifts\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-102-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-102-02.jpg\"]', 0, '183 cm', 'Never', 'Yes', 'Prefer not to say', 'Open', 'Christian', '[\"Malayalam\",\"Tamil\",\"Punjabi\"]', 'complete', 1, '2026-01-15 10:19:00', '2026-08-10 10:19:00', 'calls', 'What is a small thing that made your week better?'),
(1536, 1556, '2005-05-19', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Long-Term Relationship\"]', 'Surat', 80, 'Finance', 'Daylight Design', 'Professional', 'My ideal Sunday includes good coffee, a heritage walk, and cooking something ambitious. Hoping to meet someone warm who enjoys both plans and spontaneity. Bonus points for a great playlist.', 'Vadodara', '[\"Bollywood\",\"Photography\",\"Classical\",\"Reading\",\"Running\",\"Hiking\",\"Heritage walks\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Tamil & Punjabi & Malayalam\",\"Religion\":\"Sikh\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Open', '[\"Curiosity\",\"Humour\",\"Kindness\"]', '[\"Acts of service\",\"Receiving gifts\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-103-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-103-02.jpg\"]', 0, '181 cm', 'Never', 'Never', 'Never', 'Open', 'Sikh', '[\"Tamil\",\"Punjabi\",\"Malayalam\"]', 'complete', 1, '2026-04-09 10:18:00', '2026-08-27 10:18:00', 'light_fun_conversations', 'What is your signature dish?'),
(1537, 1557, '1997-05-18', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\",\"Meaningful Dating\"]', 'Vadodara', 150, 'Business Owner', 'Northstar Collective', 'Doctorate & Research', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Teach me something you love.', 'Surat', '[\"Live music\",\"Coffee\",\"Classical\",\"Street food\",\"Dogs\",\"Volunteering\",\"Reading\",\"Cafes\",\"Baking\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"English\",\"Religion\":\"Sikh\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Straight', '[\"Ambition\",\"Empathy\",\"Creativity\"]', '[\"Acts of service\",\"Physical touch\"]', '[\"Morning\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-104-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-104-02.jpg\"]', 0, '160 cm', 'Prefer not to say', 'Yes', 'Never', 'Gujarati', 'Sikh', '[\"English\"]', 'complete', 1, '2025-12-06 10:17:00', '2026-08-23 10:17:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1538, 1558, '1998-05-17', 'Female', '', '[\"Male\"]', '[\"Casual Connection\",\"Friendship First\"]', 'Ahmedabad', 20, 'Marketing', 'Daylight Design', 'Professional', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Teach me something you love.', 'Ahmedabad', '[\"Indie\",\"City breaks\",\"Classical\",\"Running\",\"Road trips\",\"Wildlife\",\"Mindfulness\",\"Hiking\",\"Baking\",\"Design\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Malayalam & Tamil & English\",\"Religion\":\"Sikh\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Kindness\",\"Honesty\",\"Creativity\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-105-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-105-02.jpg\"]', 0, '169 cm', 'Never', 'Yes', 'Never', 'Indian', 'Sikh', '[\"Malayalam\",\"Tamil\",\"English\"]', 'complete', 1, '2026-05-19 10:16:00', '2026-08-17 10:16:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1539, 1559, '1982-05-16', 'Male', '', '[\"Female\"]', '[\"Friendship First\"]', 'Gandhinagar', 40, 'Finance', 'Northstar Collective', 'Professional', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Teach me something you love.', 'Surat', '[\"Beaches\",\"Design\",\"Coffee\",\"Cooking\",\"Dogs\",\"Gardening\",\"Pottery\",\"Volunteering\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Punjabi\",\"Religion\":\"Spiritual\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Straight', '[\"Humour\",\"Empathy\",\"Ambition\"]', '[\"Acts of service\",\"Words of affirmation\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-106-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-106-02.jpg\"]', 0, '170 cm', 'Never', 'Yes', 'Sometimes', 'Global', 'Spiritual', '[\"Punjabi\"]', 'complete', 1, '2026-05-19 10:15:00', '2026-08-18 10:15:00', 'light_fun_conversations', 'What is your signature dish?'),
(1540, 1560, '1999-05-15', 'Female', '', '[\"Male\"]', '[\"Exploring Possibilities\",\"Casual Connection\"]', 'Surat', 80, 'Software Engineer', 'Aster Health', 'Postgraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Teach me something you love.', 'Vadodara', '[\"Live music\",\"Road trips\",\"Writing\",\"City breaks\",\"Hiking\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Tamil & Malayalam\",\"Religion\":\"Jain\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Patience\",\"Humour\",\"Empathy\"]', '[\"Quality time\",\"Acts of service\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-107-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-107-02.jpg\"]', 0, '160 cm', 'Sometimes', 'Sometimes', 'Never', 'Indian', 'Jain', '[\"Tamil\",\"Malayalam\"]', 'complete', 1, '2025-12-22 10:14:00', '2026-08-17 10:14:00', 'occasional_texting', 'What is your signature dish?'),
(1541, 1561, '1994-05-14', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\",\"Casual Connection\"]', 'Vadodara', 150, 'Business Owner', 'Riverstone', 'Postgraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Teach me something you love.', 'Gandhinagar', '[\"Mindfulness\",\"Design\",\"Dogs\",\"Pottery\",\"Yoga\",\"Writing\",\"Photography\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Malayalam & Marathi\",\"Religion\":\"Christian\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Straight', '[\"Ambition\",\"Patience\",\"Honesty\"]', '[\"Receiving gifts\",\"Words of affirmation\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-108-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-108-02.jpg\"]', 0, '169 cm', 'Prefer not to say', 'Sometimes', 'Prefer not to say', 'Gujarati', 'Christian', '[\"Malayalam\",\"Marathi\"]', 'complete', 1, '2026-05-02 10:13:00', '2026-08-26 10:13:00', 'deep_conversations', 'Which city would you revisit tomorrow?'),
(1542, 1562, '1995-05-13', 'Female', '', '[\"Male\"]', '[\"Marriage Minded\",\"Friendship First\"]', 'Ahmedabad', 20, 'Marketing', 'Riverstone', 'Doctorate & Research', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Bonus points for a great playlist.', 'Gandhinagar', '[\"Gardening\",\"Mindfulness\",\"Heritage walks\",\"Volunteering\",\"Bollywood\",\"Beaches\",\"Cycling\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Marathi\",\"Religion\":\"Spiritual\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Straight', '[\"Patience\",\"Humour\",\"Creativity\"]', '[\"Receiving gifts\",\"Words of affirmation\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-109-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-109-02.jpg\"]', 0, '159 cm', 'Never', 'Never', 'Sometimes', 'Global', 'Spiritual', '[\"Marathi\"]', 'complete', 1, '2026-03-14 10:12:00', '2026-08-27 10:12:00', 'frequent_texting', 'Which city would you revisit tomorrow?'),
(1543, 1563, '1988-05-12', 'Male', '', '[\"Female\"]', '[\"Friendship First\"]', 'Gandhinagar', 40, 'Business Owner', 'Bluebird Labs', 'Doctorate & Research', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Bonus points for a great playlist.', 'Surat', '[\"Gardening\",\"Cycling\",\"Street food\",\"Reading\",\"City breaks\",\"Photography\",\"Classical\",\"Writing\",\"Mindfulness\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"English\",\"Religion\":\"Muslim\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Creativity\",\"Humour\",\"Curiosity\"]', '[\"Acts of service\",\"Words of affirmation\"]', '[\"Late night\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-110-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-110-02.jpg\"]', 0, '167 cm', 'Prefer not to say', 'Sometimes', 'Prefer not to say', 'Open', 'Muslim', '[\"English\"]', 'complete', 1, '2025-09-16 10:11:00', '2026-08-28 10:11:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1544, 1564, '1996-05-11', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Casual Connection\",\"Meaningful Dating\"]', 'Surat', 80, 'Designer', 'Aster Health', 'Professional', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. I always make room for dessert.', 'Vadodara', '[\"Running\",\"Cooking\",\"Heritage walks\",\"Photography\",\"Bollywood\",\"Live music\",\"Street food\",\"Cycling\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Tamil\",\"Religion\":\"Jain\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"They/Them\"]', 'Open', '[\"Ambition\",\"Kindness\",\"Humour\"]', '[\"Receiving gifts\",\"Quality time\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-111-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-111-02.jpg\"]', 0, '185 cm', 'Never', 'Never', 'Never', 'Open', 'Jain', '[\"Tamil\"]', 'complete', 1, '2026-03-21 10:10:00', '2026-08-19 10:10:00', 'occasional_texting', 'Which city would you revisit tomorrow?'),
(1545, 1565, '2000-05-10', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\"]', 'Vadodara', 150, 'Entrepreneur', 'Cedar Works', 'Professional', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. Teach me something you love.', 'Gandhinagar', '[\"Cycling\",\"Bollywood\",\"Coffee\",\"Indie\",\"Cats\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Gujarati & Tamil\",\"Religion\":\"Christian\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Honesty\",\"Kindness\",\"Empathy\"]', '[\"Acts of service\",\"Receiving gifts\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-112-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-112-02.jpg\"]', 0, '151 cm', 'Never', 'Yes', 'Prefer not to say', 'Gujarati', 'Christian', '[\"Gujarati\",\"Tamil\"]', 'complete', 1, '2026-04-25 10:09:00', '2026-08-18 10:09:00', 'voice_notes', 'What is your signature dish?'),
(1546, 1566, '1995-05-09', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Casual Connection\"]', 'Ahmedabad', 20, 'Business Owner', 'Mosaic Ventures', 'Postgraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Bonus points for a great playlist.', 'Gandhinagar', '[\"Baking\",\"Hiking\",\"Pottery\",\"Wildlife\",\"Cycling\",\"Road trips\",\"Beaches\",\"Heritage walks\",\"Bollywood\",\"Gardening\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Marathi & Gujarati\",\"Religion\":\"Open\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Open', '[\"Kindness\",\"Humour\",\"Creativity\"]', '[\"Quality time\",\"Acts of service\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-113-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-113-02.jpg\"]', 0, '156 cm', 'Prefer not to say', 'Sometimes', 'Sometimes', 'Indian', 'Open', '[\"Marathi\",\"Gujarati\"]', 'complete', 1, '2025-10-24 10:08:00', '2026-08-28 10:08:00', 'deep_conversations', 'What is a small thing that made your week better?'),
(1547, 1567, '1983-05-08', 'Male', '', '[\"Female\"]', '[\"Meaningful Dating\"]', 'Gandhinagar', 40, 'Student', 'Northstar Collective', 'Postgraduate', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Bonus points for a great playlist.', 'Surat', '[\"Street food\",\"Road trips\",\"Design\",\"Wildlife\",\"Reading\",\"Photography\",\"Yoga\",\"City breaks\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Tamil & Punjabi & Marathi\",\"Religion\":\"Christian\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Open', '[\"Curiosity\",\"Honesty\",\"Patience\"]', '[\"Receiving gifts\",\"Quality time\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-114-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-114-02.jpg\"]', 0, '155 cm', 'Sometimes', 'Never', 'Prefer not to say', 'Indian', 'Christian', '[\"Tamil\",\"Punjabi\",\"Marathi\"]', 'complete', 1, '2025-08-23 10:07:00', '2026-08-29 10:07:00', 'frequent_texting', 'Which city would you revisit tomorrow?'),
(1548, 1568, '1990-05-07', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Long-Term Relationship\"]', 'Surat', 80, 'Marketing', 'Acorn Studio', 'Professional', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. Teach me something you love.', 'Ahmedabad', '[\"City breaks\",\"Running\",\"Cooking\",\"Hiking\",\"Pottery\",\"Mindfulness\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Tamil & Punjabi & Marathi\",\"Religion\":\"Spiritual\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Curiosity\",\"Patience\"]', '[\"Physical touch\",\"Quality time\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-115-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-115-02.jpg\"]', 0, '161 cm', 'Never', 'Yes', 'Prefer not to say', 'Open', 'Spiritual', '[\"Tamil\",\"Punjabi\",\"Marathi\"]', 'complete', 1, '2025-11-24 10:06:00', '2026-08-24 10:06:00', 'light_fun_conversations', 'What is your signature dish?'),
(1549, 1569, '2002-05-06', 'Male', '', '[\"Female\"]', '[\"Long-Term Relationship\"]', 'Vadodara', 150, 'Student', 'Mosaic Ventures', 'Doctorate & Research', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. I always make room for dessert.', 'Gandhinagar', '[\"Baking\",\"Street food\",\"Volunteering\",\"Beaches\",\"Live music\",\"Yoga\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Hindi & Malayalam & English\",\"Religion\":\"Spiritual\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Curiosity\",\"Honesty\",\"Humour\"]', '[\"Quality time\",\"Acts of service\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-116-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-116-02.jpg\"]', 0, '187 cm', 'Prefer not to say', 'Sometimes', 'Prefer not to say', 'Indian', 'Spiritual', '[\"Hindi\",\"Malayalam\",\"English\"]', 'complete', 1, '2026-02-26 10:05:00', '2026-08-14 10:05:00', 'light_fun_conversations', 'What is your signature dish?'),
(1550, 1570, '1990-05-05', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\",\"Meaningful Dating\"]', 'Ahmedabad', 20, 'Student', 'Independent', 'Postgraduate', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. Teach me something you love.', 'Gandhinagar', '[\"Cycling\",\"Photography\",\"Baking\",\"Reading\",\"Yoga\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Hindi & Tamil\",\"Religion\":\"Christian\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Straight', '[\"Kindness\",\"Empathy\",\"Creativity\"]', '[\"Physical touch\",\"Receiving gifts\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-117-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-117-02.jpg\"]', 0, '186 cm', 'Sometimes', 'Sometimes', 'Never', 'Global', 'Christian', '[\"Hindi\",\"Tamil\"]', 'complete', 1, '2026-03-31 10:04:00', '2026-08-16 10:04:00', 'voice_notes', 'What is a small thing that made your week better?'),
(1551, 1571, '1993-05-04', 'Male', '', '[\"Female\"]', '[\"Casual Connection\",\"Long-Term Relationship\"]', 'Gandhinagar', 40, 'Marketing', 'Riverstone', 'Postgraduate', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. Teach me something you love.', 'Ahmedabad', '[\"City breaks\",\"Pottery\",\"Road trips\",\"Dogs\",\"Bollywood\",\"Classical\",\"Coffee\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Tamil & Punjabi & Hindi\",\"Religion\":\"Open\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Open', '[\"Empathy\",\"Creativity\",\"Kindness\"]', '[\"Words of affirmation\",\"Physical touch\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-118-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-118-02.jpg\"]', 0, '181 cm', 'Prefer not to say', 'Yes', 'Sometimes', 'Global', 'Open', '[\"Tamil\",\"Punjabi\",\"Hindi\"]', 'complete', 1, '2025-12-24 10:03:00', '2026-08-09 10:03:00', 'deep_conversations', 'What is your signature dish?'),
(1552, 1572, '2001-05-03', 'Female', '', '[\"Male\"]', '[\"Marriage Minded\"]', 'Surat', 80, 'Student', 'Independent', 'Postgraduate', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Teach me something you love.', 'Ahmedabad', '[\"Coffee\",\"Gardening\",\"Indie\",\"Wildlife\",\"Cafes\",\"Street food\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Tamil & English & Marathi\",\"Religion\":\"Christian\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Straight', '[\"Creativity\",\"Honesty\",\"Humour\"]', '[\"Acts of service\",\"Words of affirmation\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-119-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-119-02.jpg\"]', 0, '175 cm', 'Never', 'Never', 'Never', 'Indian', 'Christian', '[\"Tamil\",\"English\",\"Marathi\"]', 'complete', 1, '2026-04-10 10:02:00', '2026-08-18 10:02:00', 'voice_notes', 'What is a small thing that made your week better?'),
(1553, 1573, '2005-05-02', 'Male', '', '[\"Female\"]', '[\"Friendship First\"]', 'Vadodara', 150, 'Finance', 'Daylight Design', 'Undergraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Tell me about a place you would revisit.', 'Vadodara', '[\"Yoga\",\"Writing\",\"Dogs\",\"Cafes\",\"Hiking\",\"Heritage walks\",\"Cycling\",\"Wildlife\",\"Volunteering\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Marathi & Malayalam & Gujarati\",\"Religion\":\"Open\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Creativity\",\"Ambition\",\"Humour\"]', '[\"Quality time\",\"Acts of service\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-120-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-120-02.jpg\"]', 0, '179 cm', 'Prefer not to say', 'Sometimes', 'Sometimes', 'Open', 'Open', '[\"Marathi\",\"Malayalam\",\"Gujarati\"]', 'complete', 1, '2026-04-05 10:01:00', '2026-08-09 10:01:00', 'deep_conversations', 'Which city would you revisit tomorrow?'),
(1554, 1574, '1996-05-01', 'Female', '', '[\"Male\"]', '[\"Exploring Possibilities\"]', 'Ahmedabad', 20, 'Entrepreneur', 'Acorn Studio', 'Professional', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. I always make room for dessert.', 'Surat', '[\"Photography\",\"Dogs\",\"Volunteering\",\"Road trips\",\"Street food\",\"Beaches\",\"Cats\",\"Indie\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Gujarati & Punjabi\",\"Religion\":\"Spiritual\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Patience\",\"Empathy\",\"Kindness\"]', '[\"Acts of service\",\"Receiving gifts\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-121-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-121-02.jpg\"]', 0, '154 cm', 'Sometimes', 'Yes', 'Prefer not to say', 'Global', 'Spiritual', '[\"Gujarati\",\"Punjabi\"]', 'complete', 1, '2025-07-08 10:00:00', '2026-08-26 10:00:00', 'voice_notes', 'What is your signature dish?'),
(1555, 1575, '2000-04-30', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Friendship First\"]', 'Gandhinagar', 40, 'Designer', 'Riverstone', 'Professional', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Bonus points for a great playlist.', 'Gandhinagar', '[\"Running\",\"Cooking\",\"City breaks\",\"Live music\",\"Gardening\",\"Road trips\",\"Reading\",\"Beaches\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Malayalam & Punjabi\",\"Religion\":\"Open\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"They/Them\"]', 'Open', '[\"Ambition\",\"Humour\",\"Honesty\"]', '[\"Acts of service\",\"Words of affirmation\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-122-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-122-02.jpg\"]', 0, '164 cm', 'Sometimes', 'Yes', 'Prefer not to say', 'Open', 'Open', '[\"Malayalam\",\"Punjabi\"]', 'complete', 1, '2026-08-28 09:59:00', '2026-08-28 09:59:00', 'calls', 'What is a small thing that made your week better?'),
(1556, 1576, '1998-04-29', 'Female', '', '[\"Male\"]', '[\"Exploring Possibilities\"]', 'Surat', 80, 'Finance', 'Northstar Collective', 'Doctorate & Research', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Teach me something you love.', 'Gandhinagar', '[\"Indie\",\"Yoga\",\"Mindfulness\",\"Design\",\"Classical\",\"Beaches\",\"Cycling\",\"City breaks\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Malayalam & Tamil\",\"Religion\":\"Open\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Curiosity\",\"Patience\",\"Honesty\"]', '[\"Acts of service\",\"Words of affirmation\"]', '[\"Morning\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-123-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-123-02.jpg\"]', 0, '183 cm', 'Prefer not to say', 'Never', 'Prefer not to say', 'Open', 'Open', '[\"Malayalam\",\"Tamil\"]', 'complete', 1, '2026-05-16 09:58:00', '2026-08-20 09:58:00', 'voice_notes', 'What is a small thing that made your week better?'),
(1557, 1577, '1997-04-28', 'Male', '', '[\"Female\"]', '[\"Long-Term Relationship\",\"Meaningful Dating\"]', 'Vadodara', 150, 'Architect', 'Northstar Collective', 'Postgraduate', 'My ideal Sunday includes good coffee, a heritage walk, and cooking something ambitious. Hoping to meet someone warm who enjoys both plans and spontaneity. I always make room for dessert.', 'Ahmedabad', '[\"Beaches\",\"Mindfulness\",\"Cycling\",\"Heritage walks\",\"Cooking\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Tamil & English\",\"Religion\":\"Sikh\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Open', '[\"Humour\",\"Patience\",\"Empathy\"]', '[\"Acts of service\",\"Quality time\"]', '[\"Morning\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-124-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-124-02.jpg\"]', 0, '181 cm', 'Never', 'Yes', 'Sometimes', 'Open', 'Sikh', '[\"Tamil\",\"English\"]', 'complete', 1, '2025-09-28 09:57:00', '2026-08-13 09:57:00', 'deep_conversations', 'What is a small thing that made your week better?'),
(1558, 1578, '1984-04-27', 'Female', '', '[\"Male\"]', '[\"Friendship First\",\"Exploring Possibilities\"]', 'Ahmedabad', 20, 'Business Owner', 'Mosaic Ventures', 'Professional', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Bonus points for a great playlist.', 'Gandhinagar', '[\"Volunteering\",\"Heritage walks\",\"Street food\",\"Photography\",\"Yoga\",\"Gardening\",\"Road trips\",\"Cafes\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Marathi\",\"Religion\":\"Spiritual\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Patience\",\"Creativity\",\"Curiosity\"]', '[\"Acts of service\",\"Receiving gifts\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-125-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-125-02.jpg\"]', 0, '187 cm', 'Prefer not to say', 'Yes', 'Prefer not to say', 'Global', 'Spiritual', '[\"Marathi\"]', 'complete', 1, '2026-04-26 09:56:00', '2026-08-22 09:56:00', 'voice_notes', 'What is your signature dish?'),
(1559, 1579, '1992-04-26', 'Male', '', '[\"Female\"]', '[\"Meaningful Dating\",\"Exploring Possibilities\"]', 'Gandhinagar', 40, 'Finance', 'Cedar Works', 'Postgraduate', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Teach me something you love.', 'Vadodara', '[\"Wildlife\",\"Heritage walks\",\"Gardening\",\"Running\",\"Live music\",\"Bollywood\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi & Punjabi\",\"Religion\":\"Spiritual\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Open', '[\"Honesty\",\"Kindness\",\"Ambition\"]', '[\"Quality time\",\"Receiving gifts\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-126-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-126-02.jpg\"]', 0, '193 cm', 'Prefer not to say', 'Never', 'Never', 'Open', 'Spiritual', '[\"Hindi\",\"Punjabi\"]', 'complete', 1, '2025-11-07 09:55:00', '2026-08-09 09:55:00', 'calls', 'What is your signature dish?'),
(1560, 1580, '1998-04-25', 'Female', '', '[\"Male\"]', '[\"Casual Connection\"]', 'Surat', 80, 'Architect', 'Independent', 'Professional', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Tell me about a place you would revisit.', 'Gandhinagar', '[\"Live music\",\"Classical\",\"Pottery\",\"Heritage walks\",\"Street food\",\"Photography\",\"Bollywood\",\"City breaks\",\"Mindfulness\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Tamil & English\",\"Religion\":\"Open\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Straight', '[\"Curiosity\",\"Ambition\",\"Honesty\"]', '[\"Receiving gifts\",\"Words of affirmation\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-127-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-127-02.jpg\"]', 0, '187 cm', 'Prefer not to say', 'Yes', 'Prefer not to say', 'Global', 'Open', '[\"Tamil\",\"English\"]', 'complete', 1, '2025-09-02 09:54:00', '2026-08-14 09:54:00', 'frequent_texting', 'What is a small thing that made your week better?');
INSERT INTO `onboardingprofiles` (`id`, `userId`, `birthDate`, `gender`, `customGender`, `interestedIn`, `relationshipGoals`, `city`, `preferredDistance`, `profession`, `company`, `education`, `bio`, `hometown`, `interests`, `lifestyle`, `prompts`, `pronouns`, `sexuality`, `valuedQualities`, `loveLanguages`, `preferredTalkingHours`, `photos`, `primaryPhotoIndex`, `height`, `smoking`, `drinking`, `weed`, `community`, `religion`, `languages`, `stage`, `onboardingCompleted`, `createdAt`, `updatedAt`, `communicationStyle`, `iceBreaker`) VALUES
(1561, 1581, '1999-04-24', 'Male', '', '[\"Female\"]', '[\"Meaningful Dating\"]', 'Vadodara', 150, 'Student', 'Mosaic Ventures', 'Undergraduate', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Bonus points for a great playlist.', 'Gandhinagar', '[\"Dogs\",\"Running\",\"Yoga\",\"Cooking\",\"Reading\",\"Hiking\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Punjabi\",\"Religion\":\"Muslim\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Open', '[\"Honesty\",\"Patience\",\"Empathy\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-128-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-128-02.jpg\"]', 0, '168 cm', 'Never', 'Sometimes', 'Never', 'Open', 'Muslim', '[\"Punjabi\"]', 'complete', 1, '2025-08-31 09:53:00', '2026-08-22 09:53:00', 'light_fun_conversations', 'Which city would you revisit tomorrow?'),
(1562, 1582, '1988-04-23', 'Female', '', '[\"Male\"]', '[\"Marriage Minded\"]', 'Ahmedabad', 20, 'Entrepreneur', 'Independent', 'Doctorate & Research', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Tell me about a place you would revisit.', 'Gandhinagar', '[\"Cycling\",\"City breaks\",\"Beaches\",\"Wildlife\",\"Coffee\",\"Heritage walks\",\"Design\",\"Mindfulness\",\"Road trips\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Hindi & Punjabi\",\"Religion\":\"Sikh\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Ambition\",\"Patience\",\"Creativity\"]', '[\"Acts of service\",\"Physical touch\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-129-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-129-02.jpg\"]', 0, '153 cm', 'Prefer not to say', 'Never', 'Prefer not to say', 'Indian', 'Sikh', '[\"Hindi\",\"Punjabi\"]', 'complete', 1, '2026-06-14 09:52:00', '2026-08-15 09:52:00', 'frequent_texting', 'What is your signature dish?'),
(1563, 1583, '1986-04-22', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\",\"Meaningful Dating\"]', 'Gandhinagar', 40, 'Designer', 'Independent', 'Undergraduate', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. I always make room for dessert.', 'Ahmedabad', '[\"Indie\",\"Baking\",\"Writing\",\"Mindfulness\",\"Cooking\",\"Running\",\"Gardening\",\"Photography\",\"Bollywood\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Punjabi\",\"Religion\":\"Jain\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Bisexual', '[\"Patience\",\"Kindness\",\"Honesty\"]', '[\"Quality time\",\"Acts of service\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-130-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-130-02.jpg\"]', 0, '176 cm', 'Prefer not to say', 'Never', 'Sometimes', 'Gujarati', 'Jain', '[\"Punjabi\"]', 'complete', 1, '2026-08-07 09:51:00', '2026-08-22 09:51:00', 'occasional_texting', 'Which city would you revisit tomorrow?'),
(1564, 1584, '2002-04-21', 'Female', '', '[\"Male\"]', '[\"Marriage Minded\"]', 'Surat', 80, 'Software Engineer', 'Riverstone', 'Postgraduate', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. I always make room for dessert.', 'Gandhinagar', '[\"Dogs\",\"Reading\",\"Classical\",\"Cycling\",\"Street food\",\"Bollywood\",\"Running\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Malayalam\",\"Religion\":\"Muslim\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Honesty\",\"Humour\",\"Creativity\"]', '[\"Physical touch\",\"Acts of service\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-131-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-131-02.jpg\"]', 0, '192 cm', 'Prefer not to say', 'Never', 'Sometimes', 'Open', 'Muslim', '[\"Malayalam\"]', 'complete', 1, '2026-03-23 09:50:00', '2026-08-22 09:50:00', 'light_fun_conversations', 'Which city would you revisit tomorrow?'),
(1565, 1585, '1992-04-20', 'Male', '', '[\"Female\"]', '[\"Exploring Possibilities\"]', 'Vadodara', 150, 'Entrepreneur', 'Daylight Design', 'Undergraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Teach me something you love.', 'Gandhinagar', '[\"Volunteering\",\"Live music\",\"Gardening\",\"Reading\",\"Hiking\",\"Running\",\"Indie\",\"Classical\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Malayalam & Marathi & Hindi\",\"Religion\":\"Jain\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Open', '[\"Creativity\",\"Humour\",\"Patience\"]', '[\"Receiving gifts\",\"Quality time\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-132-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-132-02.jpg\"]', 0, '158 cm', 'Prefer not to say', 'Sometimes', 'Never', 'Global', 'Jain', '[\"Malayalam\",\"Marathi\",\"Hindi\"]', 'complete', 1, '2026-08-25 09:49:00', '2026-08-25 09:49:00', 'light_fun_conversations', 'What is a small thing that made your week better?'),
(1566, 1586, '1988-04-19', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Meaningful Dating\"]', 'Ahmedabad', 20, 'Doctor', 'Saffron & Co.', 'Professional', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Tell me about a place you would revisit.', 'Surat', '[\"Running\",\"Street food\",\"Classical\",\"City breaks\",\"Wildlife\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Marathi\",\"Religion\":\"Hindu\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegan\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"They/Them\"]', 'Open', '[\"Creativity\",\"Patience\",\"Honesty\"]', '[\"Acts of service\",\"Quality time\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-133-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-133-02.jpg\"]', 0, '183 cm', 'Never', 'Yes', 'Sometimes', 'Open', 'Hindu', '[\"Marathi\"]', 'complete', 1, '2025-12-17 09:48:00', '2026-08-25 09:48:00', 'light_fun_conversations', 'Which city would you revisit tomorrow?'),
(1567, 1587, '1984-04-18', 'Male', '', '[\"Female\"]', '[\"Casual Connection\"]', 'Gandhinagar', 40, 'Finance', 'Northstar Collective', 'Postgraduate', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Tell me about a place you would revisit.', 'Vadodara', '[\"Pottery\",\"Indie\",\"Heritage walks\",\"Cycling\",\"Beaches\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Gujarati\",\"Religion\":\"Open\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Straight', '[\"Curiosity\",\"Humour\",\"Creativity\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-134-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-134-02.jpg\"]', 0, '173 cm', 'Prefer not to say', 'Sometimes', 'Never', 'Open', 'Open', '[\"Gujarati\"]', 'complete', 1, '2026-01-27 09:47:00', '2026-08-29 09:47:00', 'occasional_texting', 'What is your signature dish?'),
(1568, 1588, '1986-04-17', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\",\"Casual Connection\"]', 'Surat', 80, 'Finance', 'Saffron & Co.', 'Doctorate & Research', 'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter. I always make room for dessert.', 'Surat', '[\"Baking\",\"Cats\",\"Mindfulness\",\"Design\",\"Indie\",\"Running\",\"Live music\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Hindi & Marathi\",\"Religion\":\"Jain\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Straight', '[\"Humour\",\"Creativity\",\"Empathy\"]', '[\"Acts of service\",\"Physical touch\"]', '[\"Morning\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-135-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-135-02.jpg\"]', 0, '167 cm', 'Never', 'Yes', 'Prefer not to say', 'Indian', 'Jain', '[\"Hindi\",\"Marathi\"]', 'complete', 1, '2025-07-17 09:46:00', '2026-08-24 09:46:00', 'voice_notes', 'Which city would you revisit tomorrow?'),
(1569, 1589, '1997-04-16', 'Male', '', '[\"Female\"]', '[\"Meaningful Dating\",\"Exploring Possibilities\"]', 'Vadodara', 150, 'Designer', 'Aster Health', 'Doctorate & Research', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Tell me about a place you would revisit.', 'Vadodara', '[\"Classical\",\"Cats\",\"Coffee\",\"Cooking\",\"Beaches\",\"Photography\",\"Indie\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Gujarati & English\",\"Religion\":\"Christian\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Open', '[\"Kindness\",\"Humour\",\"Honesty\"]', '[\"Physical touch\",\"Quality time\"]', '[\"Morning\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-136-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-136-02.jpg\"]', 0, '173 cm', 'Prefer not to say', 'Sometimes', 'Never', 'Gujarati', 'Christian', '[\"Gujarati\",\"English\"]', 'complete', 1, '2026-02-04 09:45:00', '2026-08-25 09:45:00', 'occasional_texting', 'Which city would you revisit tomorrow?'),
(1570, 1590, '2002-04-15', 'Female', '', '[\"Male\"]', '[\"Casual Connection\"]', 'Ahmedabad', 20, 'Designer', 'Independent', 'Postgraduate', 'My ideal Sunday includes good coffee, a heritage walk, and cooking something ambitious. Hoping to meet someone warm who enjoys both plans and spontaneity. Tell me about a place you would revisit.', 'Gandhinagar', '[\"Design\",\"Reading\",\"Cycling\",\"Road trips\",\"Live music\",\"Yoga\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Hindi\",\"Religion\":\"Sikh\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Open', '[\"Honesty\",\"Curiosity\",\"Ambition\"]', '[\"Physical touch\",\"Receiving gifts\"]', '[\"Late night\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-137-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-137-02.jpg\"]', 0, '188 cm', 'Never', 'Yes', 'Never', 'Indian', 'Sikh', '[\"Hindi\"]', 'complete', 1, '2026-06-25 09:44:00', '2026-08-22 09:44:00', 'occasional_texting', 'What is your signature dish?'),
(1571, 1591, '1992-04-14', 'Male', '', '[\"Female\"]', '[\"Long-Term Relationship\"]', 'Gandhinagar', 40, 'Designer', 'Bluebird Labs', 'Postgraduate', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Tell me about a place you would revisit.', 'Gandhinagar', '[\"Baking\",\"Beaches\",\"Wildlife\",\"Road trips\",\"Cats\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Hindi & Tamil\",\"Religion\":\"Christian\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Open', '[\"Curiosity\",\"Empathy\",\"Patience\"]', '[\"Receiving gifts\",\"Words of affirmation\"]', '[\"Afternoon\",\"Evening\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-138-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-138-02.jpg\"]', 0, '167 cm', 'Never', 'Yes', 'Sometimes', 'Global', 'Christian', '[\"Hindi\",\"Tamil\"]', 'complete', 1, '2026-08-19 09:43:00', '2026-08-19 09:43:00', 'light_fun_conversations', 'What is your signature dish?'),
(1572, 1592, '1996-04-13', 'Female', '', '[\"Male\"]', '[\"Exploring Possibilities\",\"Friendship First\"]', 'Surat', 80, 'Software Engineer', 'Daylight Design', 'Professional', 'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures. Teach me something you love.', 'Ahmedabad', '[\"Road trips\",\"Beaches\",\"Heritage walks\",\"Coffee\",\"Indie\",\"Pottery\",\"Bollywood\",\"Dogs\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Hindi & Malayalam\",\"Religion\":\"Muslim\",\"Exercise\":\"Daily\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Kindness\",\"Honesty\",\"Patience\"]', '[\"Physical touch\",\"Words of affirmation\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-139-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-139-02.jpg\"]', 0, '193 cm', 'Prefer not to say', 'Yes', 'Never', 'Gujarati', 'Muslim', '[\"Hindi\",\"Malayalam\"]', 'complete', 1, '2026-04-16 09:42:00', '2026-08-25 09:42:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1573, 1593, '1982-04-12', 'Male', '', '[\"Female\"]', '[\"Meaningful Dating\",\"Casual Connection\"]', 'Vadodara', 150, 'Student', 'Mosaic Ventures', 'Professional', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. Bonus points for a great playlist.', 'Ahmedabad', '[\"City breaks\",\"Wildlife\",\"Indie\",\"Yoga\",\"Cafes\",\"Design\",\"Photography\",\"Hiking\",\"Cooking\",\"Gardening\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"English & Punjabi\",\"Religion\":\"Spiritual\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegan\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"He/Him\"]', 'Open', '[\"Empathy\",\"Ambition\",\"Curiosity\"]', '[\"Words of affirmation\",\"Acts of service\"]', '[\"Morning\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-140-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-140-02.jpg\"]', 0, '150 cm', 'Never', 'Never', 'Sometimes', 'Global', 'Spiritual', '[\"English\",\"Punjabi\"]', 'complete', 1, '2025-12-25 09:41:00', '2026-08-27 09:41:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1574, 1594, '1988-04-11', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\"]', 'Ahmedabad', 20, 'Designer', 'Mosaic Ventures', 'Professional', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Bonus points for a great playlist.', 'Vadodara', '[\"Live music\",\"Running\",\"Classical\",\"Road trips\",\"Cats\",\"Gardening\",\"Cooking\",\"Volunteering\",\"Indie\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Gujarati & Punjabi\",\"Religion\":\"Sikh\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Creativity\",\"Empathy\",\"Honesty\"]', '[\"Acts of service\",\"Receiving gifts\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-141-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-141-02.jpg\"]', 0, '167 cm', 'Prefer not to say', 'Never', 'Sometimes', 'Global', 'Sikh', '[\"Gujarati\",\"Punjabi\"]', 'complete', 1, '2026-07-16 09:40:00', '2026-08-11 09:40:00', 'frequent_texting', 'What is a small thing that made your week better?'),
(1575, 1595, '1987-04-10', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\"]', 'Gandhinagar', 40, 'Doctor', 'Riverstone', 'Professional', 'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long. Bonus points for a great playlist.', 'Gandhinagar', '[\"Cats\",\"Dogs\",\"Wildlife\",\"Heritage walks\",\"Gardening\",\"Cooking\",\"Street food\",\"Classical\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Gujarati & Tamil & Hindi\",\"Religion\":\"Jain\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Straight', '[\"Empathy\",\"Curiosity\",\"Humour\"]', '[\"Acts of service\",\"Receiving gifts\"]', '[\"Afternoon\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-142-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-142-02.jpg\"]', 0, '173 cm', 'Never', 'Never', 'Sometimes', 'Global', 'Jain', '[\"Gujarati\",\"Tamil\",\"Hindi\"]', 'complete', 1, '2025-09-24 09:39:00', '2026-08-17 09:39:00', 'frequent_texting', 'What is a small thing that made your week better?'),
(1576, 1596, '2002-04-09', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\"]', 'Surat', 80, 'Architect', 'Mosaic Ventures', 'Professional', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Tell me about a place you would revisit.', 'Surat', '[\"Dogs\",\"Hiking\",\"Mindfulness\",\"Cats\",\"Photography\",\"Pottery\",\"Yoga\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Tamil & Gujarati & English\",\"Religion\":\"Spiritual\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Straight', '[\"Creativity\",\"Patience\",\"Honesty\"]', '[\"Quality time\",\"Acts of service\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-143-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-143-02.jpg\"]', 0, '166 cm', 'Prefer not to say', 'Yes', 'Never', 'Global', 'Spiritual', '[\"Tamil\",\"Gujarati\",\"English\"]', 'complete', 1, '2026-03-29 09:38:00', '2026-08-15 09:38:00', 'calls', 'Which city would you revisit tomorrow?'),
(1577, 1597, '1997-04-08', 'Other', 'Non-binary', '[\"Male\",\"Female\",\"Other\"]', '[\"Meaningful Dating\"]', 'Vadodara', 150, 'Marketing', 'Independent', 'Postgraduate', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Teach me something you love.', 'Surat', '[\"Bollywood\",\"Beaches\",\"Hiking\",\"Dogs\",\"Indie\",\"Yoga\",\"Wildlife\",\"Volunteering\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Gujarati & Malayalam\",\"Religion\":\"Open\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Flexible\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"They/Them\"]', 'Open', '[\"Humour\",\"Kindness\",\"Empathy\"]', '[\"Acts of service\",\"Quality time\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-144-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-144-02.jpg\"]', 0, '158 cm', 'Never', 'Yes', 'Never', 'Indian', 'Open', '[\"Gujarati\",\"Malayalam\"]', 'complete', 1, '2025-12-04 09:37:00', '2026-08-14 09:37:00', 'frequent_texting', 'What is your signature dish?'),
(1578, 1598, '1996-04-07', 'Female', '', '[\"Male\"]', '[\"Exploring Possibilities\",\"Friendship First\"]', 'Ahmedabad', 20, 'Marketing', 'Acorn Studio', 'Postgraduate', 'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow. Tell me about a place you would revisit.', 'Gandhinagar', '[\"Bollywood\",\"Beaches\",\"Coffee\",\"Photography\",\"City breaks\",\"Dogs\",\"Cafes\",\"Volunteering\",\"Writing\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Marathi\",\"Religion\":\"Jain\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"She/Her\"]', 'Straight', '[\"Humour\",\"Patience\",\"Creativity\"]', '[\"Physical touch\",\"Quality time\"]', '[\"Late night\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-145-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-145-02.jpg\"]', 0, '190 cm', 'Sometimes', 'Sometimes', 'Sometimes', 'Open', 'Jain', '[\"Marathi\"]', 'complete', 1, '2025-10-29 09:36:00', '2026-08-27 09:36:00', 'light_fun_conversations', 'What is your signature dish?'),
(1579, 1599, '1995-04-06', 'Male', '', '[\"Female\"]', '[\"Marriage Minded\"]', 'Gandhinagar', 40, 'Business Owner', 'Aster Health', 'Postgraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. Teach me something you love.', 'Gandhinagar', '[\"Running\",\"Cats\",\"Beaches\",\"Baking\",\"Wildlife\",\"Road trips\",\"Classical\",\"Pottery\",\"Bollywood\",\"Cooking\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Gujarati\",\"Religion\":\"Spiritual\",\"Exercise\":\"Daily\",\"Food preference\":\"Everything\",\"Pets\":\"Dog person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Open', '[\"Kindness\",\"Curiosity\",\"Creativity\"]', '[\"Quality time\",\"Receiving gifts\"]', '[\"Evening\",\"Afternoon\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-146-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-146-02.jpg\"]', 0, '176 cm', 'Prefer not to say', 'Sometimes', 'Never', 'Open', 'Spiritual', '[\"Gujarati\"]', 'complete', 1, '2025-08-09 09:35:00', '2026-08-21 09:35:00', 'calls', 'Which city would you revisit tomorrow?'),
(1580, 1600, '1981-04-05', 'Female', '', '[\"Male\"]', '[\"Long-Term Relationship\"]', 'Surat', 80, 'Business Owner', 'Acorn Studio', 'Professional', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Bonus points for a great playlist.', 'Gandhinagar', '[\"Cats\",\"Wildlife\",\"Heritage walks\",\"Volunteering\",\"Gardening\",\"Running\",\"Road trips\"]', '{\"Height\":\"5′8″–5′11″\",\"Languages\":\"Punjabi & Malayalam\",\"Religion\":\"Christian\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Coffee, a long walk, and cooking dinner together.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Patience\",\"Humour\",\"Creativity\"]', '[\"Receiving gifts\",\"Physical touch\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-147-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-147-02.jpg\"]', 0, '181 cm', 'Sometimes', 'Never', 'Sometimes', 'Open', 'Christian', '[\"Punjabi\",\"Malayalam\"]', 'complete', 1, '2026-04-16 09:34:00', '2026-08-10 09:34:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1581, 1601, '1991-04-04', 'Male', '', '[\"Female\"]', '[\"Long-Term Relationship\"]', 'Vadodara', 150, 'Software Engineer', 'Northstar Collective', 'Professional', 'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner. Bonus points for a great playlist.', 'Gandhinagar', '[\"Wildlife\",\"Mindfulness\",\"Design\",\"Dogs\",\"Gardening\",\"Writing\",\"Indie\",\"Live music\",\"Street food\",\"Cycling\"]', '{\"Height\":\"6′0″ and above\",\"Languages\":\"Gujarati & Punjabi & Marathi\",\"Religion\":\"Open\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"Good music, close friends, and nowhere to rush.\",\"The way to win me over is\":\"Bring a thoughtful plan and an open mind.\"}', '[\"He/Him\"]', 'Straight', '[\"Curiosity\",\"Empathy\",\"Creativity\"]', '[\"Receiving gifts\",\"Physical touch\"]', '[\"Evening\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-148-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-148-02.jpg\"]', 0, '169 cm', 'Sometimes', 'Yes', 'Sometimes', 'Open', 'Open', '[\"Gujarati\",\"Punjabi\",\"Marathi\"]', 'complete', 1, '2026-07-02 09:33:00', '2026-08-09 09:33:00', 'occasional_texting', 'What is a small thing that made your week better?'),
(1582, 1602, '1995-04-03', 'Female', '', '[\"Male\"]', '[\"Meaningful Dating\",\"Marriage Minded\"]', 'Ahmedabad', 20, 'Architect', 'Cedar Works', 'Undergraduate', 'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often. I always make room for dessert.', 'Surat', '[\"Photography\",\"Wildlife\",\"Indie\",\"Live music\",\"Bollywood\",\"Road trips\",\"Classical\",\"Running\",\"Cooking\"]', '{\"Height\":\"Under 5′4″\",\"Languages\":\"Punjabi & Gujarati & Marathi\",\"Religion\":\"Christian\",\"Exercise\":\"Occasionally\",\"Food preference\":\"Everything\",\"Pets\":\"Love all pets\",\"Sleep habits\":\"Night owl\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Be curious and communicate clearly.\"}', '[\"She/Her\"]', 'Bisexual', '[\"Kindness\",\"Humour\",\"Curiosity\"]', '[\"Quality time\",\"Acts of service\"]', '[\"Afternoon\",\"Late night\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-149-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-149-02.jpg\"]', 0, '166 cm', 'Prefer not to say', 'Sometimes', 'Sometimes', 'Indian', 'Christian', '[\"Punjabi\",\"Gujarati\",\"Marathi\"]', 'complete', 1, '2025-07-31 09:32:00', '2026-08-16 09:32:00', 'light_fun_conversations', 'What is your signature dish?'),
(1583, 1603, '1999-04-02', 'Male', '', '[\"Female\"]', '[\"Casual Connection\",\"Marriage Minded\"]', 'Gandhinagar', 40, 'Student', 'Northstar Collective', 'Postgraduate', 'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things. I always make room for dessert.', 'Vadodara', '[\"Photography\",\"Heritage walks\",\"Coffee\",\"Beaches\",\"Indie\"]', '{\"Height\":\"5′4″–5′7″\",\"Languages\":\"Punjabi\",\"Religion\":\"Sikh\",\"Exercise\":\"A few times a week\",\"Food preference\":\"Vegetarian\",\"Pets\":\"Cat person\",\"Sleep habits\":\"Early bird\"}', '{\"A perfect Sunday looks like\":\"A slow morning followed by a spontaneous day trip.\",\"The way to win me over is\":\"Make me laugh and remember the little things.\"}', '[\"He/Him\"]', 'Open', '[\"Patience\",\"Ambition\",\"Empathy\"]', '[\"Quality time\",\"Acts of service\"]', '[\"Evening\",\"Morning\"]', '[\"/uploads/onboarding-photos/amoraa-demo-profile-150-01.jpg\",\"/uploads/onboarding-photos/amoraa-demo-profile-150-02.jpg\"]', 0, '177 cm', 'Never', 'Never', 'Sometimes', 'Global', 'Sikh', '[\"Punjabi\"]', 'complete', 1, '2026-02-19 09:31:00', '2026-08-22 09:31:00', 'occasional_texting', 'Which city would you revisit tomorrow?');

-- --------------------------------------------------------

--
-- Table structure for table `otptokens`
--

CREATE TABLE `otptokens` (
  `id` int(11) NOT NULL,
  `phoneNumber` varchar(255) DEFAULT NULL,
  `codeHash` varchar(255) NOT NULL,
  `purpose` enum('account_verification','password_reset') NOT NULL,
  `expiresAt` datetime NOT NULL,
  `attempts` int(11) NOT NULL DEFAULT 0,
  `consumed` tinyint(1) NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `recoveryUsedAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `otptokens`
--

INSERT INTO `otptokens` (`id`, `phoneNumber`, `codeHash`, `purpose`, `expiresAt`, `attempts`, `consumed`, `createdAt`, `updatedAt`, `email`, `recoveryUsedAt`) VALUES
(1, '+919100000107', '$2b$12$m5IzAkbr3sUiMemYsgfG4ePZ8pAO/fGBaUhW4HXSRWY79LgaeRdlG', 'account_verification', '2026-08-18 22:27:21', 0, 0, '2026-08-11 18:50:36', '2026-08-11 22:27:22', NULL, NULL),
(2, '+919723653140', '$2b$12$qrLh0mymRECvvka94zuR8e02yYRphvJ6E4owp50AC8U3tVmel2Vfq', 'account_verification', '2026-08-11 19:04:00', 0, 1, '2026-08-11 18:54:01', '2026-08-11 18:54:30', NULL, NULL),
(3, '+919978504352', '$2b$12$vQOkllfPJ0CjOQBrGWpDlOky5vC.2eIdxwoAJ4OVOY7oBDvAWtYdK', 'account_verification', '2026-08-11 20:25:13', 0, 1, '2026-08-11 20:15:13', '2026-08-11 20:15:29', NULL, NULL),
(4, '+919723653160', '$2b$12$N0XuCjzYx9UHkF64FdKmPeZGkJ/OTOgj6r0YvyIrqfHBNa6KtCF42', 'account_verification', '2026-08-12 06:46:21', 0, 1, '2026-08-12 06:36:21', '2026-08-12 06:37:13', NULL, NULL),
(5, '+919723653160', '$2b$12$znsmYBZGsZeHj0piXX6fPeUj5/UWPzAg5Z/L8lvAS.2KixfXDk4k.', 'account_verification', '2026-08-12 06:47:13', 0, 1, '2026-08-12 06:37:13', '2026-08-12 06:37:39', NULL, NULL),
(6, '+919723653110', '$2b$12$PjueJ/GwGrji5wW3SqSfqegsPK79tq5LpSzcx1FRlG5Ac3RhN9pXC', 'account_verification', '2026-08-12 10:41:12', 0, 1, '2026-08-12 10:31:13', '2026-08-12 10:31:34', NULL, NULL),
(31, '+919723653101', '$2b$12$IGyCqY4aKN3OSo7n2heW7.cy.8FnOK9D/NwwlreKbOk9eWl.hlXYC', 'account_verification', '2026-08-13 06:47:10', 0, 1, '2026-08-13 06:37:10', '2026-08-13 06:37:24', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `paymentevents`
--

CREATE TABLE `paymentevents` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `paymentId` bigint(20) UNSIGNED DEFAULT NULL,
  `provider` varchar(32) NOT NULL,
  `providerEventId` varchar(160) NOT NULL,
  `eventType` varchar(120) NOT NULL,
  `payloadHash` varchar(64) NOT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`payload`)),
  `status` enum('received','processed','ignored','failed') NOT NULL DEFAULT 'received',
  `processedAt` datetime DEFAULT NULL,
  `errorMessage` varchar(500) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `paymentevents`
--

INSERT INTO `paymentevents` (`id`, `paymentId`, `provider`, `providerEventId`, `eventType`, `payloadHash`, `payload`, `status`, `processedAt`, `errorMessage`, `createdAt`, `updatedAt`) VALUES
(1, 1, 'qa_seed', 'qa_event_subscription_aarav', 'payment.captured', 'e2e0000000000000000000000000000000000000000000000000000000000000', '{\"source\":\"e2e_test_seed\",\"paymentId\":\"1\"}', 'processed', '2026-07-12 22:27:21', NULL, '2026-08-11 18:50:36', '2026-08-11 22:27:22');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userId` int(11) NOT NULL,
  `planId` varchar(64) DEFAULT NULL,
  `productType` enum('subscription') NOT NULL,
  `productReferenceId` varchar(64) NOT NULL,
  `provider` varchar(32) NOT NULL DEFAULT 'razorpay',
  `providerOrderId` varchar(120) DEFAULT NULL,
  `providerPaymentId` varchar(120) DEFAULT NULL,
  `amountMinor` int(10) UNSIGNED NOT NULL,
  `currency` varchar(3) NOT NULL,
  `status` enum('created','authorized','paid','failed','cancelled','refunded','chargeback') NOT NULL DEFAULT 'created',
  `idempotencyKey` varchar(100) NOT NULL,
  `failureCode` varchar(100) DEFAULT NULL,
  `failureMessage` varchar(500) DEFAULT NULL,
  `verifiedAt` datetime DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `userId`, `planId`, `productType`, `productReferenceId`, `provider`, `providerOrderId`, `providerPaymentId`, `amountMinor`, `currency`, `status`, `idempotencyKey`, `failureCode`, `failureMessage`, `verifiedAt`, `metadata`, `createdAt`, `updatedAt`) VALUES
(1, 1, 'amoraa_gold_monthly', 'subscription', 'amoraa_gold_monthly', 'qa_seed', 'qa_order_subscription_aarav', 'qa_payment_subscription_aarav', 199900, 'INR', 'paid', 'e2e:subscription:aarav', NULL, NULL, '2026-07-12 22:27:21', '{\"source\":\"e2e_test_seed\"}', '2026-08-11 18:50:36', '2026-08-11 22:27:22');

-- --------------------------------------------------------

--
-- Table structure for table `platformsettings`
--

CREATE TABLE `platformsettings` (
  `key` varchar(80) NOT NULL,
  `value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`value`)),
  `version` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `updatedByAdministratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT current_timestamp(),
  `updatedAt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `platformsettings`
--

INSERT INTO `platformsettings` (`key`, `value`, `version`, `updatedByAdministratorId`, `createdAt`, `updatedAt`) VALUES
('maintenance_mode_enabled', 'false', 1, NULL, '2026-09-02 06:49:33', '2026-09-02 06:49:33'),
('registration_enabled', 'true', 1, NULL, '2026-09-02 06:49:33', '2026-09-02 06:49:33'),
('support_email', '\"\"', 1, NULL, '2026-09-02 06:49:33', '2026-09-02 06:49:33');

-- --------------------------------------------------------

--
-- Table structure for table `profiletaxonomycategories`
--

CREATE TABLE `profiletaxonomycategories` (
  `key` varchar(40) NOT NULL,
  `label` varchar(120) NOT NULL,
  `maximumSelections` int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `profiletaxonomycategories`
--

INSERT INTO `profiletaxonomycategories` (`key`, `label`, `maximumSelections`) VALUES
('education', 'Education', NULL),
('interests', 'Interests', 20),
('languages', 'Languages', 10),
('occupations', 'Occupation', NULL),
('religions', 'Religion', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `profiletaxonomyoptions`
--

CREATE TABLE `profiletaxonomyoptions` (
  `id` varchar(80) NOT NULL,
  `categoryKey` varchar(40) NOT NULL,
  `label` varchar(255) NOT NULL,
  `normalizedLabel` varchar(255) NOT NULL,
  `allowsCustomValue` tinyint(1) NOT NULL DEFAULT 0,
  `isActive` tinyint(1) NOT NULL DEFAULT 1,
  `sortOrder` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `profiletaxonomyoptions`
--

INSERT INTO `profiletaxonomyoptions` (`id`, `categoryKey`, `label`, `normalizedLabel`, `allowsCustomValue`, `isActive`, `sortOrder`) VALUES
('taxonomy_education_099630d77376c2908345fff9cae89ba6', 'education', 'IIM Ahmedabad', 'iim ahmedabad', 0, 1, 8),
('taxonomy_education_24b1f1a8533a6a4530efe972d327303a', 'education', 'NID Ahmedabad', 'nid ahmedabad', 0, 1, 11),
('taxonomy_education_26b2ed9b74709e112dd43b08bd91e7bd', 'education', 'MICA', 'mica', 0, 1, 9),
('taxonomy_education_2ec5cfb2b4ee4942a60ebf1cea812201', 'education', 'MSU Baroda', 'msu baroda', 0, 1, 10),
('taxonomy_education_3428c34b8fd31aab4f351524726918d3', 'education', 'St. Xavier’s College', 'st. xavier’s college', 0, 1, 14),
('taxonomy_education_3d25f3852902662f0ab76bf366c78268', 'education', 'Undergraduate', 'undergraduate', 0, 1, 17),
('taxonomy_education_43a529a199582da9417184b7bd77f470', 'education', 'Postgraduate', 'postgraduate', 0, 1, 12),
('taxonomy_education_630319ec80ff51999ac0ca6212ba07e1', 'education', 'Professional', 'professional', 0, 1, 13),
('taxonomy_education_679ceec980e487df10c27d93111c16a6', 'education', 'Asian College of Journalism', 'asian college of journalism', 0, 1, 2),
('taxonomy_education_68c90181d238ca4ce1f400f0448c4a60', 'education', 'Doctorate & Research', 'doctorate & research', 0, 1, 4),
('taxonomy_education_8c4244198785f30553118746a41409ad', 'education', 'FTII', 'ftii', 0, 1, 5),
('taxonomy_education_8e190c77074b9a2b3112f65e1c6cb967', 'education', 'Other', 'other', 1, 1, 18),
('taxonomy_education_a7fef4cc2de1cbe883f7385d64942f0b', 'education', 'Ahmedabad University', 'ahmedabad university', 0, 1, 1),
('taxonomy_education_c86e9deba1f3eaaad12e65775bdebe75', 'education', 'IHM Ahmedabad', 'ihm ahmedabad', 0, 1, 7),
('taxonomy_education_e81022ffcc0dbadb22126b4897ccce6b', 'education', 'TERI School', 'teri school', 0, 1, 16),
('taxonomy_education_f0491053f69dadeee099e45135498d06', 'education', 'TDS', 'tds', 0, 1, 15),
('taxonomy_education_f249c0f9e74376c139fc543d723ba51e', 'education', 'Gujarat University', 'gujarat university', 0, 1, 6),
('taxonomy_education_f9b773522316e151ab043b6feebd0d48', 'education', 'CEPT University', 'cept university', 0, 1, 3),
('taxonomy_interests_17d3f146a7ff46696e90d344d71f149d', 'interests', 'Live music', 'live music', 0, 1, 18),
('taxonomy_interests_1a18b8687a5f349ade07b9c0b9aa19d9', 'interests', 'Cafes', 'cafes', 0, 1, 5),
('taxonomy_interests_1eccafcceaccc852d6de0b8c684311ff', 'interests', 'Cycling', 'cycling', 0, 1, 11),
('taxonomy_interests_2b75cbc87ab1864f9348c42514550ba4', 'interests', 'Dogs', 'dogs', 0, 1, 13),
('taxonomy_interests_2b8a65ebd09b231f52bf38c916b42142', 'interests', 'Yoga', 'yoga', 0, 1, 30),
('taxonomy_interests_350ffe79f5a62e3e9ee5320f06cd61fd', 'interests', 'City breaks', 'city breaks', 0, 1, 7),
('taxonomy_interests_3945bc01c3b6b9309bd609701fc6f75c', 'interests', 'Coffee', 'coffee', 0, 1, 9),
('taxonomy_interests_3c06a0fe4c4333a5cefd01c3856e9cbc', 'interests', 'Reading', 'reading', 0, 1, 22),
('taxonomy_interests_51c9c70da5e77bf7f250ba33f2010735', 'interests', 'Cooking', 'cooking', 0, 1, 10),
('taxonomy_interests_5249904c08646e4051eb68a905313a9e', 'interests', 'Road trips', 'road trips', 0, 1, 23),
('taxonomy_interests_58c70ff740079395571e91e8375f23fe', 'interests', 'Design', 'design', 0, 1, 12),
('taxonomy_interests_5cd434d6d9694243177b13e6860884e2', 'interests', 'Baking', 'baking', 0, 1, 1),
('taxonomy_interests_5e428aa4ef1d47b7f68de7ec6072927e', 'interests', 'Heritage walks', 'heritage walks', 0, 1, 15),
('taxonomy_interests_6400e3fb6f0248a22f1701488b661b51', 'interests', 'Beaches', 'beaches', 0, 1, 2),
('taxonomy_interests_660385511aa1cefb21e188f444a2583f', 'interests', 'Volunteering', 'volunteering', 0, 1, 27),
('taxonomy_interests_7cceb23319fd0f59b37b3e0fe4e4e29f', 'interests', 'Travel', 'travel', 0, 1, 26),
('taxonomy_interests_83def92afa04acf3932b67ccf6895bc3', 'interests', 'Bollywood', 'bollywood', 0, 1, 3),
('taxonomy_interests_855c3ec5872be6b0b532ebdd1860710e', 'interests', 'Indie', 'indie', 0, 1, 17),
('taxonomy_interests_87fe4fc8e4e641bfc5427c998a0ebb20', 'interests', 'Writing', 'writing', 0, 1, 29),
('taxonomy_interests_94ab15610ed9e4757c4c175263dd3e8a', 'interests', 'Classical', 'classical', 0, 1, 8),
('taxonomy_interests_a622dab6821e90b3cfcdd40177b5fa85', 'interests', 'Gardening', 'gardening', 0, 1, 14),
('taxonomy_interests_b3d70a04e13466a171121f53d5283a72', 'interests', 'Pottery', 'pottery', 0, 1, 21),
('taxonomy_interests_bdb00af4b6c9315ec5154a4827a808ad', 'interests', 'Running', 'running', 0, 1, 24),
('taxonomy_interests_be0a1b0880cd552556b05c0de8c901b2', 'interests', 'Photography', 'photography', 0, 1, 20),
('taxonomy_interests_cd96766c057c13b958e177898cf48cc1', 'interests', 'Books', 'books', 0, 1, 4),
('taxonomy_interests_ced354776b34c87d746717d206523b97', 'interests', 'Hiking', 'hiking', 0, 1, 16),
('taxonomy_interests_cf958febd880156918e87d8446ae5d26', 'interests', 'Cats', 'cats', 0, 1, 6),
('taxonomy_interests_d20caaba42492031a565c758340c66c5', 'interests', 'Wildlife', 'wildlife', 0, 1, 28),
('taxonomy_interests_e8b0f19b00990722bb4abbb1e4ebb6fb', 'interests', 'Mindfulness', 'mindfulness', 0, 1, 19),
('taxonomy_interests_fa79c9ec1d3c8834e0172b127600b185', 'interests', 'Street food', 'street food', 0, 1, 25),
('taxonomy_languages_073381d776bf4cc1e75790c434ba375c', 'languages', 'Malayalam', 'malayalam', 0, 1, 4),
('taxonomy_languages_137748bd4c9e8790357cfc3498a31e5b', 'languages', 'Punjabi', 'punjabi', 0, 1, 6),
('taxonomy_languages_31ced47d5a8a59679dc1f7fc742357b0', 'languages', 'English', 'english', 0, 1, 1),
('taxonomy_languages_52a9d88ec7ded2d388e158bc335a0d05', 'languages', 'Tamil', 'tamil', 0, 1, 7),
('taxonomy_languages_5f85839abb5895fa98e6474343452506', 'languages', 'Hindi', 'hindi', 0, 1, 3),
('taxonomy_languages_b12e07d1785f8a13dd733d21cf37c349', 'languages', 'Gujarati', 'gujarati', 0, 1, 2),
('taxonomy_languages_d87394032d10deb4253f4d1fbd01f94c', 'languages', 'Marathi', 'marathi', 0, 1, 5),
('taxonomy_occupations_01a22de0fb3236d3087472794eaa7ac9', 'occupations', 'Doctor', 'doctor', 0, 1, 10),
('taxonomy_occupations_02fe2f0ee9c29639c4a073c399ed24d8', 'occupations', 'Business Owner', 'business owner', 0, 1, 3),
('taxonomy_occupations_0fe996aa63fa137128e967a86949058a', 'occupations', 'Architect', 'architect', 0, 1, 1),
('taxonomy_occupations_1fd6c61be7afba68fe94364f09ffb64d', 'occupations', 'Finance', 'finance', 0, 1, 13),
('taxonomy_occupations_3ea0ec330742a270c73469b3a2a0f7d8', 'occupations', 'Urban Planner', 'urban planner', 0, 1, 22),
('taxonomy_occupations_556a9c02a0d9588a4b119a6dab80e9ed', 'occupations', 'Entrepreneur', 'entrepreneur', 0, 1, 12),
('taxonomy_occupations_56790828d0d5b956aefa9702ae9fbef3', 'occupations', 'Software Engineer', 'software engineer', 0, 1, 19),
('taxonomy_occupations_59dc2ec26fd5683777f19b087d3b4c3a', 'occupations', 'Ceramic Artist', 'ceramic artist', 0, 1, 4),
('taxonomy_occupations_65c2fd841f32baf9fed72a19ef5a4623', 'occupations', 'Data Journalist', 'data journalist', 0, 1, 8),
('taxonomy_occupations_6d7b0c1d426e17e51c0f91500613d795', 'occupations', 'Hospitality Consultant', 'hospitality consultant', 0, 1, 14),
('taxonomy_occupations_6f80b6624316896d8a77b8d437bc7cce', 'occupations', 'Research Associate', 'research associate', 0, 1, 18),
('taxonomy_occupations_76343c8899b82b1afbafa960c595e26c', 'occupations', 'Landscape Designer', 'landscape designer', 0, 1, 15),
('taxonomy_occupations_7f1ac5bad0fd1a81cd5ba07c158d772b', 'occupations', 'Community Curator', 'community curator', 0, 1, 6),
('taxonomy_occupations_84b5ade4d181196dd65a697cd4259047', 'occupations', 'Product Designer', 'product designer', 0, 1, 17),
('taxonomy_occupations_892588712203c90578f8edada0a6242f', 'occupations', 'Clinical Psychologist', 'clinical psychologist', 0, 1, 5),
('taxonomy_occupations_b25fb4829b4e29dba6189785c6ba2b91', 'occupations', 'Sustainability Analyst', 'sustainability analyst', 0, 1, 21),
('taxonomy_occupations_ba5595def046ec2bf3bc647d9c0c0790', 'occupations', 'Documentary Filmmaker', 'documentary filmmaker', 0, 1, 11),
('taxonomy_occupations_bbc0710ac4c14a3a3fad7e8e2ce1151d', 'occupations', 'Marketing', 'marketing', 0, 1, 16),
('taxonomy_occupations_dc27ff7534bd4ab1afd2fbe31759edde', 'occupations', 'Student', 'student', 0, 1, 20),
('taxonomy_occupations_e0e6e551de98bb1646acee51f8052a45', 'occupations', 'Brand Strategist', 'brand strategist', 0, 1, 2),
('taxonomy_occupations_f4f0eb019c1d78786aa534b6f30a9bf9', 'occupations', 'Other', 'other', 1, 1, 23),
('taxonomy_occupations_fda451e571a8ca4313b66350a582a173', 'occupations', 'Designer', 'designer', 0, 1, 9),
('taxonomy_occupations_fdb23af96223bceaa84075b8ab10b257', 'occupations', 'Content Producer', 'content producer', 0, 1, 7),
('taxonomy_religions_51cb29071e52751d263ef290e8338a91', 'religions', 'Christian', 'christian', 0, 1, 1),
('taxonomy_religions_5ab805cce1d90bedb4dc92431f6b3700', 'religions', 'Other', 'other', 1, 1, 8),
('taxonomy_religions_67267b940ddf695a9ab9658fa14180c3', 'religions', 'Hindu', 'hindu', 0, 1, 2),
('taxonomy_religions_88ce1035d0058ac8f70b89e61e6576c0', 'religions', 'Open', 'open', 0, 1, 5),
('taxonomy_religions_99376e5bf5db23352eb759b04c7c84a2', 'religions', 'Muslim', 'muslim', 0, 1, 4),
('taxonomy_religions_b10312bb1ef8ab28f3f7e2b808b794db', 'religions', 'Spiritual', 'spiritual', 0, 1, 7),
('taxonomy_religions_bfc45e9fd0cddbf14447e40e7b1cfdac', 'religions', 'Sikh', 'sikh', 0, 1, 6),
('taxonomy_religions_f4d5d8107719220cbbc9cde41c9bf4a7', 'religions', 'Jain', 'jain', 0, 1, 3);

-- --------------------------------------------------------

--
-- Table structure for table `refreshtokens`
--

CREATE TABLE `refreshtokens` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `tokenSelector` varchar(32) DEFAULT NULL,
  `tokenHash` varchar(255) NOT NULL,
  `expiresAt` datetime NOT NULL,
  `createdByIp` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `refreshtokens`
--

INSERT INTO `refreshtokens` (`id`, `userId`, `tokenSelector`, `tokenHash`, `expiresAt`, `createdByIp`, `createdAt`, `updatedAt`) VALUES
(1, 16, NULL, '$2b$12$7Q3Pv.eBiuy5wYdiF.EOTOftHgchSBa4.Y6dOcdnfJPdR7yX5xfkW', '2026-09-10 18:54:31', '::1', '2026-08-11 18:54:31', '2026-08-11 18:54:31'),
(2, 17, NULL, '$2b$12$1Y5bJfzS9BPsVFjn6sIGke80Bn16hGHOI/IBxPTyEQmrbr/YcMjYq', '2026-09-10 20:15:30', '::1', '2026-08-11 20:15:30', '2026-08-11 20:15:30'),
(5, 1, NULL, '$2b$12$Hh1uy.4VDcmBnyexnDDVR.W62JpBrfg0O6yT7QPT516ZduehfsMKK', '2026-09-10 20:54:58', '::ffff:127.0.0.1', '2026-08-11 20:54:58', '2026-08-11 20:54:58'),
(16, 18, NULL, '$2b$12$wH4miKu2GRbCKTX7hAU3ouO8kpUHDJtAIs5702TqDjA8G5tJ/gOGG', '2026-09-11 06:37:39', '::1', '2026-08-12 06:37:39', '2026-08-12 06:37:39'),
(40, 49, NULL, '$2b$12$jTogLgARkFlsStBZEIctXeMDV709r4/fE8lHtcwgBzYDbK8Pex.4y', '2026-09-11 10:31:34', '::ffff:10.231.234.74', '2026-08-12 10:31:34', '2026-08-12 10:31:34'),
(88, 85, 'a9f9fff659258d4dd0aa11dd476cee23', '$2b$12$clGKh7FvJ2kKyp10oMr7.eHoSDRlbqGaDeA10eJXBUwoK/RtSQ.GS', '2026-09-12 07:08:25', '::ffff:10.231.234.74', '2026-08-13 07:08:25', '2026-08-13 07:08:25'),
(113, 85, 'dfbb08c4b99bcb8f4699cc6a62c8f3cb', '$2b$12$IBqzUwLausOgF5mZzIhAZeKgYKpC19/a7jxaf3TLAEDAR5QUAjJZy', '2026-09-16 08:29:11', '::ffff:127.0.0.1', '2026-08-17 08:29:11', '2026-08-17 08:29:11'),
(114, 85, 'a61208c1b41e89bed875c631bb553b8b', '$2b$12$sHDQrMAFmt/PVvFnsWHZM.Rx99Hqv1YDvTSozog7vYH6k3Ah2yu6K', '2026-09-16 09:06:37', '::ffff:127.0.0.1', '2026-08-17 09:06:37', '2026-08-17 09:06:37'),
(115, 85, '03b78b7ccc33f8315a8b8fe7caea7275', '$2b$12$hhBpoS2FoAqMs4bo1T9kpu0dItKlfGVULwkATm39re6Kypj10iqzC', '2026-09-16 12:00:59', '::ffff:127.0.0.1', '2026-08-17 12:00:59', '2026-08-17 12:00:59'),
(117, 85, '7fd4ecc1536fb2a1617efeaae7bf9fe9', '$2b$12$aop4RztIyG09Wc2rp..owOevALi7uOqtR/LgUURLJONPpQcYzI4eO', '2026-09-18 07:47:25', '::1', '2026-08-19 07:47:25', '2026-08-19 07:47:25'),
(131, 1454, 'f973e427ce7ef236634608d125c8971a', '$2b$12$NdNPoRwGpQyJdyZrcKAQleLNCkFZP6xBrMsSj6ax9QbikSgV8dYL2', '2026-09-28 12:52:40', '127.0.0.1', '2026-08-29 12:52:40', '2026-08-29 12:52:40'),
(132, 1455, 'ba4a51146842e1fe19b3fd9150a080e7', '$2b$12$xV5P1T3yDcIDwCZunagefuGdBggDKa4553bYDsoyAnU90KPS6qptG', '2026-09-28 12:52:40', '127.0.0.1', '2026-08-29 12:52:40', '2026-08-29 12:52:40'),
(133, 1456, '435ea23b4d4ac1c1c5381a572713ef41', '$2b$12$OpTgIzYp0Z8IeYl1nar16uD/u9ja5vbqn37MPvYAs1W0jMvzj1gaW', '2026-09-28 12:52:41', '127.0.0.1', '2026-08-29 12:52:41', '2026-08-29 12:52:41'),
(134, 1454, 'd1d8c8ea8b695e673083443aad375256', '$2b$12$8XlywvqAZ38qyV0VKUcO1ezFjIfCZWeXZZa6yxex7o/NmT3TQGPsG', '2026-09-28 12:53:47', '127.0.0.1', '2026-08-29 12:53:47', '2026-08-29 12:53:47'),
(135, 1455, '323e4b723cf1a77959e02a4c449569a8', '$2b$12$bQOrsktJ.6kQ/gzJqDCxu.OdRnAAvakdGZm8Lwnv5Lx7fXDq6RsSK', '2026-09-28 12:53:47', '127.0.0.1', '2026-08-29 12:53:47', '2026-08-29 12:53:47'),
(136, 1456, 'd4706e3b56111a5bc7ac4ad9e09b4295', '$2b$12$amGLAgdkytpH/QUK7bjXcOaWHZ0ouSTJSFx4sdAqdUCQfT7xsfbTC', '2026-09-28 12:53:48', '127.0.0.1', '2026-08-29 12:53:48', '2026-08-29 12:53:48'),
(137, 1454, '03aa31b856c696f64d68cdb3fb6cb4ed', '$2b$12$3pfYHmxu1XSfBtt5PBvl7.QFFxIsjvMGrXCNaFTXB6t1qrbiwFNKm', '2026-09-28 12:54:09', '127.0.0.1', '2026-08-29 12:54:09', '2026-08-29 12:54:09'),
(138, 1455, '2523302f60a580100103f8a83e8db3a1', '$2b$12$.lzx662awOwLOVqiW2PVZOVOtTzGfGz9KUT6JxWgz3gz5MJsYnjmK', '2026-09-28 12:54:09', '127.0.0.1', '2026-08-29 12:54:09', '2026-08-29 12:54:09'),
(139, 1456, '94998d650f747fa85b1eea2c22fe662f', '$2b$12$MXZDEwV55VWyYYoUPDNBaufIyOHp666t9bPDowOff53amBz8TRcyu', '2026-09-28 12:54:09', '127.0.0.1', '2026-08-29 12:54:09', '2026-08-29 12:54:09');

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `id` int(11) NOT NULL,
  `reporterUserId` int(11) NOT NULL,
  `reportedUserId` int(11) DEFAULT NULL,
  `targetType` enum('profile','event','message') NOT NULL DEFAULT 'profile',
  `targetId` varchar(255) NOT NULL,
  `reason` enum('fake_profile','harassment','inappropriate_photo','scam','spam','other') NOT NULL,
  `notes` text DEFAULT NULL,
  `status` enum('open','reviewing','resolved','dismissed') NOT NULL DEFAULT 'open',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reports`
--

INSERT INTO `reports` (`id`, `reporterUserId`, `reportedUserId`, `targetType`, `targetId`, `reason`, `notes`, `status`, `createdAt`, `updatedAt`) VALUES
(1, 1, 10, 'profile', '10', 'spam', 'QA seed scenario: repeated promotional messages.', 'open', '2026-08-11 18:50:36', '2026-08-11 18:50:36');

-- --------------------------------------------------------

--
-- Table structure for table `rosetransactions`
--

CREATE TABLE `rosetransactions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `senderId` int(11) NOT NULL,
  `recipientId` int(11) NOT NULL,
  `conversationId` int(11) DEFAULT NULL,
  `idempotencyKey` varchar(100) NOT NULL,
  `status` enum('sent','reversed') NOT NULL DEFAULT 'sent',
  `note` varchar(280) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rosetransactions`
--

INSERT INTO `rosetransactions` (`id`, `senderId`, `recipientId`, `conversationId`, `idempotencyKey`, `status`, `note`, `createdAt`, `updatedAt`) VALUES
(1, 1, 6, 2, 'e2e:gift:ananya', 'sent', 'For the documentary recommendation.', '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(2, 49, 5, NULL, 'flutter:rose:1786530796500904:1464289790', 'sent', NULL, '2026-08-12 10:33:18', '2026-08-12 10:33:18'),
(3, 49, 10, NULL, 'flutter:rose:1786531151731144:4125272342', 'sent', 'Hello', '2026-08-12 10:39:15', '2026-08-12 10:39:15'),
(295, 1454, 1455, NULL, 'dummy-seed-12345-1454-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-08-29 12:00:00', '2026-08-29 12:00:00'),
(296, 1459, 1468, NULL, 'dummy-seed-12345-1459-1468', 'sent', NULL, '2026-08-24 12:00:00', '2026-08-24 12:00:00'),
(297, 1464, 1455, NULL, 'dummy-seed-12345-1464-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-08-19 12:00:00', '2026-08-19 12:00:00'),
(298, 1469, 1478, NULL, 'dummy-seed-12345-1469-1478', 'sent', NULL, '2026-08-14 12:00:00', '2026-08-14 12:00:00'),
(299, 1474, 1455, NULL, 'dummy-seed-12345-1474-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-08-09 12:00:00', '2026-08-09 12:00:00'),
(300, 1479, 1488, NULL, 'dummy-seed-12345-1479-1488', 'sent', NULL, '2026-08-04 12:00:00', '2026-08-04 12:00:00'),
(301, 1484, 1455, NULL, 'dummy-seed-12345-1484-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-07-30 12:00:00', '2026-07-30 12:00:00'),
(302, 1489, 1498, NULL, 'dummy-seed-12345-1489-1498', 'sent', NULL, '2026-07-25 12:00:00', '2026-07-25 12:00:00'),
(303, 1494, 1455, NULL, 'dummy-seed-12345-1494-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-07-20 12:00:00', '2026-07-20 12:00:00'),
(304, 1499, 1508, NULL, 'dummy-seed-12345-1499-1508', 'sent', NULL, '2026-08-29 12:00:00', '2026-08-29 12:00:00'),
(305, 1504, 1455, NULL, 'dummy-seed-12345-1504-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-08-24 12:00:00', '2026-08-24 12:00:00'),
(306, 1509, 1518, NULL, 'dummy-seed-12345-1509-1518', 'sent', NULL, '2026-08-19 12:00:00', '2026-08-19 12:00:00'),
(307, 1514, 1455, NULL, 'dummy-seed-12345-1514-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-08-14 12:00:00', '2026-08-14 12:00:00'),
(308, 1519, 1528, NULL, 'dummy-seed-12345-1519-1528', 'sent', NULL, '2026-08-09 12:00:00', '2026-08-09 12:00:00'),
(309, 1524, 1455, NULL, 'dummy-seed-12345-1524-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-08-04 12:00:00', '2026-08-04 12:00:00'),
(310, 1529, 1538, NULL, 'dummy-seed-12345-1529-1538', 'sent', NULL, '2026-07-30 12:00:00', '2026-07-30 12:00:00'),
(311, 1534, 1455, NULL, 'dummy-seed-12345-1534-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-07-25 12:00:00', '2026-07-25 12:00:00'),
(312, 1539, 1548, NULL, 'dummy-seed-12345-1539-1548', 'sent', NULL, '2026-07-20 12:00:00', '2026-07-20 12:00:00'),
(313, 1544, 1455, NULL, 'dummy-seed-12345-1544-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-08-29 12:00:00', '2026-08-29 12:00:00'),
(314, 1549, 1558, NULL, 'dummy-seed-12345-1549-1558', 'sent', NULL, '2026-08-24 12:00:00', '2026-08-24 12:00:00'),
(315, 1554, 1455, NULL, 'dummy-seed-12345-1554-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-08-19 12:00:00', '2026-08-19 12:00:00'),
(316, 1559, 1568, NULL, 'dummy-seed-12345-1559-1568', 'sent', NULL, '2026-08-14 12:00:00', '2026-08-14 12:00:00'),
(317, 1564, 1455, NULL, 'dummy-seed-12345-1564-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-08-09 12:00:00', '2026-08-09 12:00:00'),
(318, 1569, 1578, NULL, 'dummy-seed-12345-1569-1578', 'sent', NULL, '2026-08-04 12:00:00', '2026-08-04 12:00:00'),
(319, 1574, 1455, NULL, 'dummy-seed-12345-1574-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-07-30 12:00:00', '2026-07-30 12:00:00'),
(320, 1579, 1588, NULL, 'dummy-seed-12345-1579-1588', 'sent', NULL, '2026-07-25 12:00:00', '2026-07-25 12:00:00'),
(321, 1584, 1455, NULL, 'dummy-seed-12345-1584-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-07-20 12:00:00', '2026-07-20 12:00:00'),
(322, 1589, 1598, NULL, 'dummy-seed-12345-1589-1598', 'sent', NULL, '2026-08-29 12:00:00', '2026-08-29 12:00:00'),
(323, 1594, 1455, NULL, 'dummy-seed-12345-1594-1455', 'sent', 'Your profile felt thoughtful. I would love to say hello.', '2026-08-24 12:00:00', '2026-08-24 12:00:00'),
(324, 1599, 1458, NULL, 'dummy-seed-12345-1599-1458', 'sent', NULL, '2026-08-19 12:00:00', '2026-08-19 12:00:00'),
(325, 1456, 1454, 306, 'dummy-seed-12345-demo-c-to-demo-a-match-rose', 'sent', 'I enjoyed our conversation and wanted to send a little extra hello.', '2026-08-16 12:00:00', '2026-08-16 12:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `savedprofiles`
--

CREATE TABLE `savedprofiles` (
  `id` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `savedUserId` int(11) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `savedprofiles`
--

INSERT INTO `savedprofiles` (`id`, `userId`, `savedUserId`, `createdAt`, `updatedAt`) VALUES
(1, 1, 13, '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(2, 3, 1, '2026-08-11 18:50:36', '2026-08-11 18:50:36'),
(14, 85, 11, '2026-08-13 06:48:17', '2026-08-13 06:48:17'),
(4026, 1454, 1476, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4027, 1454, 1487, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4028, 1454, 1498, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4029, 1455, 1477, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4030, 1455, 1488, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4031, 1455, 1499, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4032, 1456, 1478, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4033, 1456, 1489, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4034, 1456, 1500, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4035, 1457, 1479, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4036, 1457, 1490, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4037, 1457, 1501, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4038, 1458, 1480, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4039, 1458, 1491, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4040, 1458, 1502, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4041, 1459, 1481, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4042, 1459, 1492, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4043, 1459, 1503, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4044, 1460, 1482, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4045, 1460, 1493, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4046, 1460, 1504, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4047, 1461, 1483, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4048, 1461, 1494, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4049, 1461, 1505, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4050, 1462, 1484, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4051, 1462, 1495, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4052, 1462, 1506, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4053, 1463, 1485, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4054, 1463, 1496, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4055, 1463, 1507, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4056, 1464, 1486, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4057, 1464, 1497, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4058, 1464, 1508, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4059, 1465, 1487, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4060, 1465, 1498, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4061, 1465, 1509, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4062, 1466, 1488, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4063, 1466, 1499, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4064, 1466, 1510, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4065, 1467, 1489, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4066, 1467, 1500, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4067, 1467, 1511, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4068, 1468, 1490, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4069, 1468, 1501, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4070, 1468, 1512, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4071, 1469, 1491, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4072, 1469, 1502, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4073, 1469, 1513, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4074, 1470, 1492, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4075, 1470, 1503, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4076, 1470, 1514, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4077, 1471, 1493, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4078, 1471, 1504, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4079, 1471, 1515, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4080, 1472, 1494, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4081, 1472, 1505, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4082, 1472, 1516, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4083, 1473, 1495, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4084, 1473, 1506, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4085, 1473, 1517, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4086, 1474, 1496, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4087, 1474, 1507, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4088, 1474, 1518, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4089, 1475, 1497, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4090, 1475, 1508, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4091, 1475, 1519, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4092, 1476, 1498, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4093, 1476, 1509, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4094, 1476, 1520, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4095, 1477, 1499, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4096, 1477, 1510, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4097, 1477, 1521, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4098, 1478, 1500, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4099, 1478, 1511, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4100, 1478, 1522, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4101, 1479, 1501, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4102, 1479, 1512, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4103, 1479, 1523, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4104, 1480, 1502, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4105, 1480, 1513, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4106, 1480, 1524, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4107, 1481, 1503, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4108, 1481, 1514, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4109, 1481, 1525, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4110, 1482, 1504, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4111, 1482, 1515, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4112, 1482, 1526, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4113, 1483, 1505, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4114, 1483, 1516, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4115, 1483, 1527, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4116, 1484, 1506, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4117, 1484, 1517, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4118, 1484, 1528, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4119, 1485, 1507, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4120, 1485, 1518, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4121, 1485, 1529, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4122, 1486, 1508, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4123, 1486, 1519, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4124, 1486, 1530, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4125, 1487, 1509, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4126, 1487, 1520, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4127, 1487, 1531, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4128, 1488, 1510, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4129, 1488, 1521, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4130, 1488, 1532, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4131, 1489, 1511, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4132, 1489, 1522, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4133, 1489, 1533, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4134, 1490, 1512, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4135, 1490, 1523, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4136, 1490, 1534, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4137, 1491, 1513, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4138, 1491, 1524, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4139, 1491, 1535, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4140, 1492, 1514, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4141, 1492, 1525, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4142, 1492, 1536, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4143, 1493, 1515, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4144, 1493, 1526, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4145, 1493, 1537, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4146, 1494, 1516, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4147, 1494, 1527, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4148, 1494, 1538, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4149, 1495, 1517, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4150, 1495, 1528, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4151, 1495, 1539, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4152, 1496, 1518, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4153, 1496, 1529, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4154, 1496, 1540, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4155, 1497, 1519, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4156, 1497, 1530, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4157, 1497, 1541, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4158, 1498, 1520, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4159, 1498, 1531, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4160, 1498, 1542, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4161, 1499, 1521, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4162, 1499, 1532, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4163, 1499, 1543, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4164, 1500, 1522, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4165, 1500, 1533, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4166, 1500, 1544, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4167, 1501, 1523, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4168, 1501, 1534, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4169, 1501, 1545, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4170, 1502, 1524, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4171, 1502, 1535, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4172, 1502, 1546, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4173, 1503, 1525, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4174, 1503, 1536, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4175, 1503, 1547, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4176, 1504, 1526, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4177, 1504, 1537, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4178, 1504, 1548, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4179, 1505, 1527, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4180, 1505, 1538, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4181, 1505, 1549, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4182, 1506, 1528, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4183, 1506, 1539, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4184, 1506, 1550, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4185, 1507, 1529, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4186, 1507, 1540, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4187, 1507, 1551, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4188, 1508, 1530, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4189, 1508, 1541, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4190, 1508, 1552, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4191, 1509, 1531, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4192, 1509, 1542, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4193, 1509, 1553, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4194, 1510, 1532, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4195, 1510, 1543, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4196, 1510, 1554, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4197, 1511, 1533, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4198, 1511, 1544, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4199, 1511, 1555, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4200, 1512, 1534, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4201, 1512, 1545, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4202, 1512, 1556, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4203, 1513, 1535, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4204, 1513, 1546, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4205, 1513, 1557, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4206, 1514, 1536, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4207, 1514, 1547, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4208, 1514, 1558, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4209, 1515, 1537, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4210, 1515, 1548, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4211, 1515, 1559, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4212, 1516, 1538, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4213, 1516, 1549, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4214, 1516, 1560, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4215, 1517, 1539, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4216, 1517, 1550, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4217, 1517, 1561, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4218, 1518, 1540, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4219, 1518, 1551, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4220, 1518, 1562, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4221, 1519, 1541, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4222, 1519, 1552, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4223, 1519, 1563, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4224, 1520, 1542, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4225, 1520, 1553, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4226, 1520, 1564, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4227, 1521, 1543, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4228, 1521, 1554, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4229, 1521, 1565, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4230, 1522, 1544, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4231, 1522, 1555, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4232, 1522, 1566, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4233, 1523, 1545, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4234, 1523, 1556, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4235, 1523, 1567, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4236, 1524, 1546, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4237, 1524, 1557, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4238, 1524, 1568, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4239, 1525, 1547, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4240, 1525, 1558, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4241, 1525, 1569, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4242, 1526, 1548, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4243, 1526, 1559, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4244, 1526, 1570, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4245, 1527, 1549, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4246, 1527, 1560, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4247, 1527, 1571, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4248, 1528, 1550, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4249, 1528, 1561, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4250, 1528, 1572, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4251, 1529, 1551, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4252, 1529, 1562, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4253, 1529, 1573, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4254, 1530, 1552, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4255, 1530, 1563, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4256, 1530, 1574, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4257, 1531, 1553, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4258, 1531, 1564, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4259, 1531, 1575, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4260, 1532, 1554, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4261, 1532, 1565, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4262, 1532, 1576, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4263, 1533, 1555, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4264, 1533, 1566, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4265, 1533, 1577, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4266, 1534, 1556, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4267, 1534, 1567, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4268, 1534, 1578, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4269, 1535, 1557, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4270, 1535, 1568, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4271, 1535, 1579, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4272, 1536, 1558, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4273, 1536, 1569, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4274, 1536, 1580, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4275, 1537, 1559, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4276, 1537, 1570, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4277, 1537, 1581, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4278, 1538, 1560, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4279, 1538, 1571, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4280, 1538, 1582, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4281, 1539, 1561, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4282, 1539, 1572, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4283, 1539, 1583, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4284, 1540, 1562, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4285, 1540, 1573, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4286, 1540, 1584, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4287, 1541, 1563, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4288, 1541, 1574, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4289, 1541, 1585, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4290, 1542, 1564, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4291, 1542, 1575, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4292, 1542, 1586, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4293, 1543, 1565, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4294, 1543, 1576, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4295, 1543, 1587, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4296, 1544, 1566, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4297, 1544, 1577, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4298, 1544, 1588, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4299, 1545, 1567, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4300, 1545, 1578, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4301, 1545, 1589, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4302, 1546, 1568, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4303, 1546, 1579, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4304, 1546, 1590, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4305, 1547, 1569, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4306, 1547, 1580, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4307, 1547, 1591, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4308, 1548, 1570, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4309, 1548, 1581, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4310, 1548, 1592, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4311, 1549, 1571, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4312, 1549, 1582, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4313, 1549, 1593, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4314, 1550, 1572, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4315, 1550, 1583, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4316, 1550, 1594, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4317, 1551, 1573, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4318, 1551, 1584, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4319, 1551, 1595, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4320, 1552, 1574, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4321, 1552, 1585, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4322, 1552, 1596, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4323, 1553, 1575, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4324, 1553, 1586, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4325, 1553, 1597, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4326, 1554, 1576, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4327, 1554, 1587, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4328, 1554, 1598, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4329, 1555, 1577, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4330, 1555, 1588, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4331, 1555, 1599, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4332, 1556, 1578, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4333, 1556, 1589, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4334, 1556, 1600, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4335, 1557, 1579, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4336, 1557, 1590, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4337, 1557, 1601, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4338, 1558, 1580, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4339, 1558, 1591, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4340, 1558, 1602, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4341, 1559, 1581, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4342, 1559, 1592, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4343, 1559, 1603, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4344, 1560, 1582, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4345, 1560, 1593, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4346, 1560, 1454, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4347, 1561, 1583, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4348, 1561, 1594, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4349, 1561, 1455, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4350, 1562, 1584, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4351, 1562, 1595, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4352, 1562, 1456, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4353, 1563, 1585, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4354, 1563, 1596, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4355, 1563, 1457, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4356, 1564, 1586, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4357, 1564, 1597, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4358, 1564, 1458, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4359, 1565, 1587, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4360, 1565, 1598, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4361, 1565, 1459, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4362, 1566, 1588, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4363, 1566, 1599, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4364, 1566, 1460, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4365, 1567, 1589, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4366, 1567, 1600, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4367, 1567, 1461, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4368, 1568, 1590, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4369, 1568, 1601, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4370, 1568, 1462, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4371, 1569, 1591, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4372, 1569, 1602, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4373, 1569, 1463, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4374, 1570, 1592, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4375, 1570, 1603, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4376, 1570, 1464, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4377, 1571, 1593, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4378, 1571, 1454, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4379, 1571, 1465, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4380, 1572, 1594, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4381, 1572, 1455, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4382, 1572, 1466, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4383, 1573, 1595, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4384, 1573, 1456, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4385, 1573, 1467, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4386, 1574, 1596, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4387, 1574, 1457, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4388, 1574, 1468, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4389, 1575, 1597, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4390, 1575, 1458, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4391, 1575, 1469, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4392, 1576, 1598, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4393, 1576, 1459, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4394, 1576, 1470, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4395, 1577, 1599, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4396, 1577, 1460, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4397, 1577, 1471, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4398, 1578, 1600, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4399, 1578, 1461, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4400, 1578, 1472, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4401, 1579, 1601, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4402, 1579, 1462, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4403, 1579, 1473, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4404, 1580, 1602, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4405, 1580, 1463, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4406, 1580, 1474, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4407, 1581, 1603, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4408, 1581, 1464, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4409, 1581, 1475, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4410, 1582, 1454, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4411, 1582, 1465, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4412, 1582, 1476, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4413, 1583, 1455, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4414, 1583, 1466, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4415, 1583, 1477, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4416, 1584, 1456, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4417, 1584, 1467, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4418, 1584, 1478, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4419, 1585, 1457, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4420, 1585, 1468, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4421, 1585, 1479, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4422, 1586, 1458, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4423, 1586, 1469, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4424, 1586, 1480, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4425, 1587, 1459, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4426, 1587, 1470, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4427, 1587, 1481, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4428, 1588, 1460, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4429, 1588, 1471, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4430, 1588, 1482, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4431, 1589, 1461, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4432, 1589, 1472, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4433, 1589, 1483, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4434, 1590, 1462, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4435, 1590, 1473, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4436, 1590, 1484, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4437, 1591, 1463, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4438, 1591, 1474, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4439, 1591, 1485, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4440, 1592, 1464, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4441, 1592, 1475, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4442, 1592, 1486, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4443, 1593, 1465, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4444, 1593, 1476, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4445, 1593, 1487, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4446, 1594, 1466, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4447, 1594, 1477, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4448, 1594, 1488, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4449, 1595, 1467, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4450, 1595, 1478, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4451, 1595, 1489, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4452, 1596, 1468, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4453, 1596, 1479, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4454, 1596, 1490, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4455, 1597, 1469, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4456, 1597, 1480, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4457, 1597, 1491, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4458, 1598, 1470, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4459, 1598, 1481, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4460, 1598, 1492, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4461, 1599, 1471, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4462, 1599, 1482, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4463, 1599, 1493, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4464, 1600, 1472, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4465, 1600, 1483, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4466, 1600, 1494, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4467, 1601, 1473, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4468, 1601, 1484, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4469, 1601, 1495, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4470, 1602, 1474, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4471, 1602, 1485, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4472, 1602, 1496, '2026-08-25 12:00:00', '2026-08-29 12:00:00'),
(4473, 1603, 1475, '2026-08-27 12:00:00', '2026-08-29 12:00:00'),
(4474, 1603, 1486, '2026-08-26 12:00:00', '2026-08-29 12:00:00'),
(4475, 1603, 1497, '2026-08-25 12:00:00', '2026-08-29 12:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `sequelizemeta`
--

CREATE TABLE `sequelizemeta` (
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sequelizemeta`
--

INSERT INTO `sequelizemeta` (`name`) VALUES
('202608090001-create-baseline-schema.js'),
('202608100000-rename-legacy-otp-email.js'),
('202608100001-add-communication-style.js'),
('202608110001-add-phase1-query-indexes.js'),
('202608120001-add-account-lifecycle.js'),
('202608120002-create-blocks.js'),
('202608120003-create-reports-and-evidence.js'),
('202608130001-create-chat-foundation.js'),
('202608140001-create-events-foundation.js'),
('202608140002-add-event-feedback-media.js'),
('202608150001-create-monetization-foundation.js'),
('202608150002-allow-wallet-reversal-balances.js'),
('202608160001-complete-partial-integrations.js'),
('202608170001-create-notifications.js'),
('202608180001-create-identity-verification.js'),
('202608180002-add-conversation-mute.js'),
('202608180003-create-push-delivery.js'),
('202608180004-add-email-password-recovery.js'),
('202608190001-add-message-delivery-status.js'),
('202608200001-add-notification-actor.js'),
('202608210001-remove-retired-features.js'),
('202608210002-rename-event-organizer-column.js'),
('202608220001-add-refresh-token-selector.js'),
('202608230001-restore-event-waitlist.js'),
('202608240001-create-admin-foundation.js'),
('202608250001-sync-admin-permission-catalog.js'),
('202608250002-harden-admin-sessions.js'),
('202608260001-complete-administrator-management.js'),
('202608270001-complete-kyc-decisions.js'),
('202608280001-add-admin-financial-read-indexes.js'),
('202608310001-add-administrator-mfa.js'),
('202608310002-add-admin-user-activity.js'),
('202608310003-create-profile-taxonomy.js'),
('202609010001-create-admin-discover-configuration.js'),
('202609010002-create-matching-action-failures.js'),
('202609020001-create-platform-settings.js'),
('202609020002-create-admin-report-cases.js'),
('202609020003-add-safety-personal-data-permission.js'),
('202609030001-add-conversation-participant-hide.js'),
('202609030002-add-event-registration-deadline.js'),
('202609070001-create-account-deletion-confirmations.js'),
('202609070002-create-account-deletion-requests.js');

-- --------------------------------------------------------

--
-- Table structure for table `subscriptionplans`
--

CREATE TABLE `subscriptionplans` (
  `id` varchar(64) NOT NULL,
  `name` varchar(120) NOT NULL,
  `displayName` varchar(160) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `priceMinor` int(10) UNSIGNED NOT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'INR',
  `billingPeriod` enum('day','week','month','year') NOT NULL DEFAULT 'month',
  `billingInterval` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `features` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`features`)),
  `entitlements` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`entitlements`)),
  `trialDays` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `offerText` varchar(255) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `sortOrder` int(11) NOT NULL DEFAULT 0,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subscriptionplans`
--

INSERT INTO `subscriptionplans` (`id`, `name`, `displayName`, `description`, `priceMinor`, `currency`, `billingPeriod`, `billingInterval`, `features`, `entitlements`, `trialDays`, `offerText`, `active`, `sortOrder`, `createdAt`, `updatedAt`) VALUES
('amoraa_gold_monthly', 'AMORAA Gold', 'AMORAA Gold Monthly', 'Premium tools for more intentional conversations.', 199900, 'INR', 'month', 1, '[\"Priority recommendations\",\"Read receipts\",\"Incognito browsing\",\"Premium event access\"]', '{\"premium\":true,\"advancedDiscoverFilters\":true,\"readReceipts\":true,\"premiumEvents\":true}', 0, 'Most popular', 1, 20, '2026-08-11 18:50:36', '2026-08-29 12:52:34'),
('amoraa_platinum_monthly', 'AMORAA Platinum', 'AMORAA Platinum Monthly', 'The most complete AMORAA experience for intentional dating.', 349900, 'INR', 'month', 1, '[\"Unlimited Super Likes\",\"Read receipts\",\"Incognito browsing\",\"Premium events\",\"Concierge match signals\"]', '{\"premium\":true,\"advancedDiscoverFilters\":true,\"readReceipts\":true,\"premiumEvents\":true}', 0, NULL, 1, 30, '2026-08-11 18:50:36', '2026-08-29 12:52:34'),
('amoraa_plus_monthly', 'AMORAA Plus', 'AMORAA Plus Monthly', 'A calmer way to meet more compatible people.', 119900, 'INR', 'month', 1, '[\"Unlimited likes\",\"See who liked you\",\"Advanced intent filters\",\"3 Super Likes each week\"]', '{\"premium\":true,\"advancedDiscoverFilters\":true}', 0, NULL, 1, 10, '2026-08-11 18:50:36', '2026-08-29 12:52:34');

-- --------------------------------------------------------

--
-- Table structure for table `subscriptions`
--

CREATE TABLE `subscriptions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userId` int(11) NOT NULL,
  `planId` varchar(64) NOT NULL,
  `status` enum('active','expired','cancelled','past_due','trialing') NOT NULL,
  `provider` varchar(32) NOT NULL DEFAULT 'razorpay',
  `providerCustomerId` varchar(120) DEFAULT NULL,
  `providerSubscriptionId` varchar(120) DEFAULT NULL,
  `startedAt` datetime NOT NULL,
  `currentPeriodStart` datetime NOT NULL,
  `currentPeriodEnd` datetime NOT NULL,
  `autoRenew` tinyint(1) NOT NULL DEFAULT 0,
  `cancelAtPeriodEnd` tinyint(1) NOT NULL DEFAULT 0,
  `cancelledAt` datetime DEFAULT NULL,
  `endedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subscriptions`
--

INSERT INTO `subscriptions` (`id`, `userId`, `planId`, `status`, `provider`, `providerCustomerId`, `providerSubscriptionId`, `startedAt`, `currentPeriodStart`, `currentPeriodEnd`, `autoRenew`, `cancelAtPeriodEnd`, `cancelledAt`, `endedAt`, `createdAt`, `updatedAt`) VALUES
(1, 1, 'amoraa_gold_monthly', 'active', 'qa_seed', 'qa_customer_aarav', 'qa_subscription_aarav', '2026-07-12 22:27:21', '2026-07-12 22:27:21', '2027-07-12 22:27:21', 0, 0, NULL, NULL, '2026-08-11 18:50:36', '2026-08-11 22:27:22'),
(181, 1454, 'amoraa_plus_monthly', 'active', 'seed', 'seed-customer-1454', 'seed-subscription-1454', '2026-08-09 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 1, 0, NULL, NULL, '2025-07-13 12:00:00', '2026-08-28 12:00:00'),
(182, 1455, 'amoraa_gold_monthly', 'active', 'seed', 'seed-customer-1455', 'seed-subscription-1455', '2026-08-08 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 0, 0, NULL, NULL, '2025-12-21 11:59:00', '2026-08-13 11:59:00'),
(183, 1456, 'amoraa_platinum_monthly', 'active', 'seed', 'seed-customer-1456', 'seed-subscription-1456', '2026-08-07 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 1, 0, NULL, NULL, '2026-04-26 11:58:00', '2026-08-09 11:58:00'),
(184, 1463, 'amoraa_plus_monthly', 'active', 'seed', 'seed-customer-1463', 'seed-subscription-1463', '2026-08-06 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 0, 0, NULL, NULL, '2026-03-23 11:51:00', '2026-08-29 11:51:00'),
(185, 1472, 'amoraa_gold_monthly', 'active', 'seed', 'seed-customer-1472', 'seed-subscription-1472', '2026-08-05 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 1, 0, NULL, NULL, '2026-07-01 11:42:00', '2026-08-29 11:42:00'),
(186, 1481, 'amoraa_platinum_monthly', 'active', 'seed', 'seed-customer-1481', 'seed-subscription-1481', '2026-08-04 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 0, 0, NULL, NULL, '2026-07-19 11:33:00', '2026-08-27 11:33:00'),
(187, 1490, 'amoraa_plus_monthly', 'active', 'seed', 'seed-customer-1490', 'seed-subscription-1490', '2026-08-03 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 1, 0, NULL, NULL, '2025-10-08 11:24:00', '2026-08-11 11:24:00'),
(188, 1499, 'amoraa_gold_monthly', 'active', 'seed', 'seed-customer-1499', 'seed-subscription-1499', '2026-08-02 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 0, 0, NULL, NULL, '2026-01-19 11:15:00', '2026-08-09 11:15:00'),
(189, 1508, 'amoraa_platinum_monthly', 'active', 'seed', 'seed-customer-1508', 'seed-subscription-1508', '2026-08-01 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 1, 0, NULL, NULL, '2026-04-10 11:06:00', '2026-08-13 11:06:00'),
(190, 1517, 'amoraa_plus_monthly', 'active', 'seed', 'seed-customer-1517', 'seed-subscription-1517', '2026-07-31 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 0, 0, NULL, NULL, '2025-08-20 10:57:00', '2026-08-24 10:57:00'),
(191, 1526, 'amoraa_gold_monthly', 'active', 'seed', 'seed-customer-1526', 'seed-subscription-1526', '2026-07-30 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 1, 0, NULL, NULL, '2026-02-13 10:48:00', '2026-08-17 10:48:00'),
(192, 1535, 'amoraa_platinum_monthly', 'active', 'seed', 'seed-customer-1535', 'seed-subscription-1535', '2026-07-29 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 0, 0, NULL, NULL, '2026-02-22 10:39:00', '2026-08-26 10:39:00'),
(193, 1544, 'amoraa_plus_monthly', 'active', 'seed', 'seed-customer-1544', 'seed-subscription-1544', '2026-07-28 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 1, 0, NULL, NULL, '2026-02-05 10:30:00', '2026-08-21 10:30:00'),
(194, 1553, 'amoraa_gold_monthly', 'active', 'seed', 'seed-customer-1553', 'seed-subscription-1553', '2026-07-27 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 0, 0, NULL, NULL, '2026-04-30 10:21:00', '2026-08-27 10:21:00'),
(195, 1562, 'amoraa_platinum_monthly', 'active', 'seed', 'seed-customer-1562', 'seed-subscription-1562', '2026-07-26 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 1, 0, NULL, NULL, '2026-03-14 10:12:00', '2026-08-27 10:12:00'),
(196, 1571, 'amoraa_plus_monthly', 'active', 'seed', 'seed-customer-1571', 'seed-subscription-1571', '2026-07-25 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 0, 0, NULL, NULL, '2025-12-24 10:03:00', '2026-08-09 10:03:00'),
(197, 1580, 'amoraa_gold_monthly', 'active', 'seed', 'seed-customer-1580', 'seed-subscription-1580', '2026-07-24 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 1, 0, NULL, NULL, '2025-09-02 09:54:00', '2026-08-14 09:54:00'),
(198, 1589, 'amoraa_platinum_monthly', 'active', 'seed', 'seed-customer-1589', 'seed-subscription-1589', '2026-07-23 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 0, 0, NULL, NULL, '2026-02-04 09:45:00', '2026-08-25 09:45:00'),
(199, 1598, 'amoraa_plus_monthly', 'active', 'seed', 'seed-customer-1598', 'seed-subscription-1598', '2026-07-22 12:00:00', '2026-08-19 12:00:00', '2026-09-18 12:00:00', 1, 0, NULL, NULL, '2025-10-29 09:36:00', '2026-08-27 09:36:00');

-- --------------------------------------------------------

--
-- Table structure for table `userdevices`
--

CREATE TABLE `userdevices` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userId` int(11) NOT NULL,
  `pushToken` varchar(512) NOT NULL,
  `platform` enum('android','ios','web') NOT NULL,
  `installationId` varchar(160) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `lastSeenAt` datetime NOT NULL,
  `invalidatedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `userloginevents`
--

CREATE TABLE `userloginevents` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userId` int(11) NOT NULL,
  `result` enum('successful','failed') NOT NULL,
  `authenticationMethod` enum('password','google') NOT NULL,
  `failureCategory` varchar(80) DEFAULT NULL,
  `ipAddress` varchar(64) DEFAULT NULL,
  `userAgent` varchar(500) DEFAULT NULL,
  `occurredAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phoneNumber` varchar(255) NOT NULL DEFAULT '',
  `passwordHash` varchar(255) DEFAULT NULL,
  `authProvider` enum('local','google') NOT NULL DEFAULT 'local',
  `googleId` varchar(255) DEFAULT NULL,
  `isVerified` tinyint(1) DEFAULT 0,
  `termsAcceptedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `accountStatus` enum('active','deactivated','deleted') NOT NULL DEFAULT 'active',
  `deactivatedAt` datetime DEFAULT NULL,
  `deletedAt` datetime DEFAULT NULL,
  `tokenVersion` int(11) NOT NULL DEFAULT 0,
  `deletionReason` varchar(255) DEFAULT NULL,
  `deletionDetails` text DEFAULT NULL,
  `lastActiveAt` datetime DEFAULT NULL,
  `identityVerifiedAt` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `phoneNumber`, `passwordHash`, `authProvider`, `googleId`, `isVerified`, `termsAcceptedAt`, `createdAt`, `updatedAt`, `accountStatus`, `deactivatedAt`, `deletedAt`, `tokenVersion`, `deletionReason`, `deletionDetails`, `lastActiveAt`, `identityVerifiedAt`) VALUES
(1, 'Aarav Mehta', 'qa.aarav@example.test', '+919100000100', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-17 08:47:50', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-17 08:47:50', '2026-02-01 10:00:00'),
(2, 'Diya Shah', 'qa.diya@example.test', '+919100000101', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 22:26:21', '2026-02-01 10:00:00'),
(3, 'Kavya Patel', 'qa.kavya@example.test', '+919100000102', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-13 07:08:06', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-13 07:08:06', '2026-02-01 10:00:00'),
(4, 'Riya Desai', 'qa.riya@example.test', '+919100000103', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 22:24:21', '2026-02-01 10:00:00'),
(5, 'Meera Joshi', 'qa.meera@example.test', '+919100000104', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 22:23:21', '2026-02-01 10:00:00'),
(6, 'Ananya Rao', 'qa.ananya@example.test', '+919100000105', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 22:27:21', '2026-02-01 10:00:00'),
(7, 'Nisha Trivedi', 'qa.nisha@example.test', '+919100000106', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'active', NULL, NULL, 0, NULL, NULL, '2026-07-12 22:27:21', '2026-02-01 10:00:00'),
(8, 'Isha Kapoor', 'qa.isha@example.test', '+919100000107', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 0, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:21', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 22:25:21', NULL),
(9, 'Sara Khan', 'qa.sara@example.test', '+919100000108', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'deactivated', '2026-07-28 22:27:21', NULL, 0, NULL, NULL, '2026-07-12 22:27:21', '2026-02-01 10:00:00'),
(10, 'Tara Bhatt', 'qa.tara@example.test', '+919100000109', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 22:23:21', '2026-02-01 10:00:00'),
(11, 'Vihaan Shah', 'qa.vihaan@example.test', '+919100000110', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 22:27:21', '2026-02-01 10:00:00'),
(12, 'Leela Nair', 'qa.leela@example.test', '+919100000111', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 22:26:21', '2026-02-01 10:00:00'),
(13, 'Neha Soni', 'qa.neha@example.test', '+919100000112', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 22:25:21', '2026-02-01 10:00:00'),
(14, 'Priya Menon', 'qa.priya@example.test', '+919100000113', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 22:24:21', '2026-02-01 10:00:00'),
(15, 'Zoya Mirza', 'qa.zoya@example.test', '+919100000114', '$2b$12$6.hgan4rz3UUpza0Yzwm/eeacQfA3kczAKjQ00JaLpkjdjo.9htvC', 'local', NULL, 1, '2026-01-15 10:00:00', '2026-08-11 18:50:36', '2026-08-11 22:27:22', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 22:23:21', '2026-02-01 10:00:00'),
(16, 'yash', 'yash1@gmail.com', '+919723653140', '$2b$12$Wzd9wBkhxgqDFmZWSCjH6eSTWlmLBkyrg1YrabGztiW4UpTkZY7AW', 'local', NULL, 1, '2026-08-11 18:54:00', '2026-08-11 18:54:00', '2026-08-11 18:56:50', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 18:56:50', NULL),
(17, 'ronak khan', 'ronakkhan1@gmail.com', '+919978504352', '$2b$12$YFCr1TjeWAVkbEjzfvdLR.n2HE5kVt44OmzuuiZABQNvDnkDQ8Y6W', 'local', NULL, 1, '2026-08-11 20:15:13', '2026-08-11 20:15:13', '2026-08-11 20:18:44', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 20:18:44', NULL),
(18, 'yash and', 'yashand1@gmail.com', '+919723653160', '$2b$12$ITpNKaJUx5y.F4KkW8feteioiWM3kTwnAX8xHc/gxsvbsouMIKD2e', 'local', NULL, 1, '2026-08-12 06:36:21', '2026-08-12 06:36:21', '2026-08-12 06:38:30', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-12 06:38:30', NULL),
(49, 'shakti raju', 'shakti1@gmail.com', '+919723653110', '$2b$12$Inpj.PK70/3EzlEVpG.uVuQsDwv7aSqL.Td34e115.7s6FvDDG3B.', 'local', NULL, 1, '2026-08-12 10:31:12', '2026-08-12 10:31:12', '2026-08-12 10:45:35', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-12 10:45:35', NULL),
(85, 'yash andrapiya', 'yashandrapiya1@gmail.com', '+919723653101', '$2b$12$IUhlgukOSHQ8WPwXWW1sjOn6B71/juu/XBRuSy8pyExwJa167qpZ.', 'local', NULL, 1, '2026-08-13 06:37:10', '2026-08-13 06:37:10', '2026-08-19 07:47:25', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-19 07:47:25', NULL),
(1454, 'Aisha Mehta', 'demo.aisha@seed.amoraa.example.test', '+919990000001', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-07-13 12:00:00', '2025-07-13 12:00:00', '2026-08-29 12:53:48', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 12:53:48', '2026-08-28 12:00:00'),
(1455, 'Rohan Shah', 'demo.rohan@seed.amoraa.example.test', '+919990000002', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-21 11:59:00', '2025-12-21 11:59:00', '2026-08-29 12:53:48', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 12:53:48', '2026-08-13 11:59:00'),
(1456, 'Kavya Iyer', 'demo.kavya@seed.amoraa.example.test', '+919990000003', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-26 11:58:00', '2026-04-26 11:58:00', '2026-08-09 11:58:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-14 05:28:00', '2026-08-09 11:58:00'),
(1457, 'Saanvi Mehta', 'profile.0004.saanvi.mehta@seed.amoraa.example.test', '+919990000004', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-28 11:57:00', '2026-08-28 11:57:00', '2026-08-28 11:57:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-25 21:02:00', NULL),
(1458, 'Neel Sharma', 'profile.0005.neel.sharma@seed.amoraa.example.test', '+919990000005', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-10-08 11:56:00', '2025-10-08 11:56:00', '2026-08-22 11:56:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-15 23:29:00', '2026-08-22 11:56:00'),
(1459, 'Mira Rao', 'profile.0006.mira.rao@seed.amoraa.example.test', '+919990000006', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-29 11:55:00', '2026-08-29 11:55:00', '2026-08-29 11:55:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:58:00', NULL),
(1460, 'Kabir Singh', 'profile.0007.kabir.singh@seed.amoraa.example.test', '+919990000007', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2024-03-12 11:54:00', '2024-03-12 11:54:00', '2026-08-22 11:54:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-21 04:15:00', NULL),
(1461, 'Neel Shah', 'profile.0008.neel.shah@seed.amoraa.example.test', '+919990000008', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-28 11:53:00', '2025-09-28 11:53:00', '2026-08-26 11:53:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-19 09:59:00', NULL),
(1462, 'Mihir Desai', 'profile.0009.mihir.desai@seed.amoraa.example.test', '+919990000009', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-10 11:52:00', '2026-04-10 11:52:00', '2026-08-18 11:52:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-12 22:12:00', '2026-08-18 11:52:00'),
(1463, 'Samir Nair', 'profile.0010.samir.nair@seed.amoraa.example.test', '+919990000010', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-03-23 11:51:00', '2026-03-23 11:51:00', '2026-08-29 11:51:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-14 13:56:00', NULL),
(1464, 'Mira Kapoor', 'profile.0011.mira.kapoor@seed.amoraa.example.test', '+919990000011', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-11-11 11:50:00', '2025-11-11 11:50:00', '2026-08-18 11:50:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:59:00', NULL),
(1465, 'Pranav Desai', 'profile.0012.pranav.desai@seed.amoraa.example.test', '+919990000012', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-03-17 11:49:00', '2026-03-17 11:49:00', '2026-08-24 11:49:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-22 18:45:00', NULL),
(1466, 'Arjun Desai', 'profile.0013.arjun.desai@seed.amoraa.example.test', '+919990000013', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-05-29 11:48:00', '2026-05-29 11:48:00', '2026-08-14 11:48:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-23 00:24:00', '2026-08-14 11:48:00'),
(1467, 'Ira Sharma', 'profile.0014.ira.sharma@seed.amoraa.example.test', '+919990000014', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-18 11:47:00', '2026-08-18 11:47:00', '2026-08-18 11:47:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-16 11:31:00', NULL),
(1468, 'Aarav Vyas', 'profile.0015.aarav.vyas@seed.amoraa.example.test', '+919990000015', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-30 11:46:00', '2026-04-30 11:46:00', '2026-08-22 11:46:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-19 00:55:00', NULL),
(1469, 'Kabir Bhat', 'profile.0016.kabir.bhat@seed.amoraa.example.test', '+919990000016', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-17 11:45:00', '2025-12-17 11:45:00', '2026-08-22 11:45:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:59:00', NULL),
(1470, 'Nisha Nair', 'profile.0017.nisha.nair@seed.amoraa.example.test', '+919990000017', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-03 11:44:00', '2025-08-03 11:44:00', '2026-08-24 11:44:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-26 07:35:00', '2026-08-24 11:44:00'),
(1471, 'Mira Rao', 'profile.0018.mira.rao@seed.amoraa.example.test', '+919990000018', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-11 11:43:00', '2026-08-11 11:43:00', '2026-08-25 11:43:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-13 08:57:00', NULL),
(1472, 'Rohan Soni', 'profile.0019.rohan.soni@seed.amoraa.example.test', '+919990000019', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-07-01 11:42:00', '2026-07-01 11:42:00', '2026-08-29 11:42:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-15 08:40:00', NULL),
(1473, 'Yash Soni', 'profile.0020.yash.soni@seed.amoraa.example.test', '+919990000020', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-01-05 11:41:00', '2026-01-05 11:41:00', '2026-08-21 11:41:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-17 02:43:00', NULL),
(1474, 'Vihaan Soni', 'profile.0021.vihaan.soni@seed.amoraa.example.test', '+919990000021', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-09 11:40:00', '2025-09-09 11:40:00', '2026-08-29 11:40:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:53:00', '2026-08-29 11:40:00'),
(1475, 'Aisha Desai', 'profile.0022.aisha.desai@seed.amoraa.example.test', '+919990000022', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-21 11:39:00', '2026-04-21 11:39:00', '2026-08-10 11:39:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-18 16:29:00', NULL),
(1476, 'Kavya Desai', 'profile.0023.kavya.desai@seed.amoraa.example.test', '+919990000023', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-25 11:38:00', '2025-09-25 11:38:00', '2026-08-29 11:38:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-25 07:12:00', NULL),
(1477, 'Aditi Singh', 'profile.0024.aditi.singh@seed.amoraa.example.test', '+919990000024', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-05-02 11:37:00', '2026-05-02 11:37:00', '2026-08-12 11:37:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-09 13:30:00', NULL),
(1478, 'Rhea Vyas', 'profile.0025.rhea.vyas@seed.amoraa.example.test', '+919990000025', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-11-06 11:36:00', '2025-11-06 11:36:00', '2026-08-10 11:36:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-13 05:38:00', '2026-08-10 11:36:00'),
(1479, 'Tara Shah', 'profile.0026.tara.shah@seed.amoraa.example.test', '+919990000026', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-21 11:35:00', '2026-08-21 11:35:00', '2026-08-24 11:35:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:53:00', NULL),
(1480, 'Kabir Singh', 'profile.0027.kabir.singh@seed.amoraa.example.test', '+919990000027', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-09 11:34:00', '2025-08-09 11:34:00', '2026-08-10 11:34:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-12 10:30:00', NULL),
(1481, 'Rhea Shah', 'profile.0028.rhea.shah@seed.amoraa.example.test', '+919990000028', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-07-19 11:33:00', '2026-07-19 11:33:00', '2026-08-27 11:33:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-27 11:49:00', NULL),
(1482, 'Mihir Kapoor', 'profile.0029.mihir.kapoor@seed.amoraa.example.test', '+919990000029', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-03-16 11:32:00', '2026-03-16 11:32:00', '2026-08-17 11:32:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-17 07:40:00', '2026-08-17 11:32:00'),
(1483, 'Zara Singh', 'profile.0030.zara.singh@seed.amoraa.example.test', '+919990000030', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-08 11:31:00', '2026-02-08 11:31:00', '2026-08-24 11:31:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-15 19:50:00', NULL),
(1484, 'Rhea Rao', 'profile.0031.rhea.rao@seed.amoraa.example.test', '+919990000031', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-02 11:30:00', '2025-09-02 11:30:00', '2026-08-18 11:30:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:52:00', NULL),
(1485, 'Ira Joshi', 'profile.0032.ira.joshi@seed.amoraa.example.test', '+919990000032', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-23 11:29:00', '2026-04-23 11:29:00', '2026-08-12 11:29:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-14 13:45:00', NULL),
(1486, 'Krish Soni', 'profile.0033.krish.soni@seed.amoraa.example.test', '+919990000033', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-07 11:28:00', '2025-09-07 11:28:00', '2026-08-20 11:28:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-15 15:07:00', '2026-08-20 11:28:00'),
(1487, 'Kabir Joshi', 'profile.0034.kabir.joshi@seed.amoraa.example.test', '+919990000034', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-11-09 11:27:00', '2025-11-09 11:27:00', '2026-08-20 11:27:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-23 00:09:00', NULL),
(1488, 'Kabir Bhat', 'profile.0035.kabir.bhat@seed.amoraa.example.test', '+919990000035', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-01-21 11:26:00', '2026-01-21 11:26:00', '2026-08-21 11:26:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-14 17:14:00', NULL),
(1489, 'Mihir Trivedi', 'profile.0036.mihir.trivedi@seed.amoraa.example.test', '+919990000036', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-10-19 11:25:00', '2025-10-19 11:25:00', '2026-08-16 11:25:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:49:00', NULL),
(1490, 'Aisha Sharma', 'profile.0037.aisha.sharma@seed.amoraa.example.test', '+919990000037', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-10-08 11:24:00', '2025-10-08 11:24:00', '2026-08-11 11:24:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-25 16:51:00', '2026-08-11 11:24:00'),
(1491, 'Kavya Nair', 'profile.0038.kavya.nair@seed.amoraa.example.test', '+919990000038', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-13 11:23:00', '2026-02-13 11:23:00', '2026-08-22 11:23:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-17 23:51:00', NULL),
(1492, 'Rohan Trivedi', 'profile.0039.rohan.trivedi@seed.amoraa.example.test', '+919990000039', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-29 11:22:00', '2026-04-29 11:22:00', '2026-08-19 11:22:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-13 15:06:00', NULL),
(1493, 'Mira Sharma', 'profile.0040.mira.sharma@seed.amoraa.example.test', '+919990000040', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-25 11:21:00', '2025-08-25 11:21:00', '2026-08-14 11:21:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-10 11:21:00', NULL),
(1494, 'Saanvi Shah', 'profile.0041.saanvi.shah@seed.amoraa.example.test', '+919990000041', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-07-04 11:20:00', '2026-07-04 11:20:00', '2026-08-12 11:20:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:53:00', '2026-08-12 11:20:00'),
(1495, 'Tara Iyer', 'profile.0042.tara.iyer@seed.amoraa.example.test', '+919990000042', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-07-15 11:19:00', '2025-07-15 11:19:00', '2026-08-15 11:19:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-26 19:24:00', NULL),
(1496, 'Esha Menon', 'profile.0043.esha.menon@seed.amoraa.example.test', '+919990000043', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-11-04 11:18:00', '2025-11-04 11:18:00', '2026-08-24 11:18:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-12 02:44:00', NULL),
(1497, 'Aisha Vyas', 'profile.0044.aisha.vyas@seed.amoraa.example.test', '+919990000044', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-30 11:17:00', '2025-08-30 11:17:00', '2026-08-25 11:17:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-20 20:51:00', NULL),
(1498, 'Sara Trivedi', 'profile.0045.sara.trivedi@seed.amoraa.example.test', '+919990000045', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-18 11:16:00', '2025-12-18 11:16:00', '2026-08-24 11:16:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-18 22:23:00', '2026-08-24 11:16:00'),
(1499, 'Vihaan Sharma', 'profile.0046.vihaan.sharma@seed.amoraa.example.test', '+919990000046', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-01-19 11:15:00', '2026-01-19 11:15:00', '2026-08-09 11:15:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:57:00', NULL),
(1500, 'Mihir Joshi', 'profile.0047.mihir.joshi@seed.amoraa.example.test', '+919990000047', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-05-31 11:14:00', '2026-05-31 11:14:00', '2026-08-21 11:14:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-17 03:15:00', NULL),
(1501, 'Mira Joshi', 'profile.0048.mira.joshi@seed.amoraa.example.test', '+919990000048', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-07-18 11:13:00', '2026-07-18 11:13:00', '2026-08-13 11:13:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-27 15:23:00', NULL),
(1502, 'Rohan Bhat', 'profile.0049.rohan.bhat@seed.amoraa.example.test', '+919990000049', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-10-15 11:12:00', '2025-10-15 11:12:00', '2026-08-16 11:12:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-13 10:47:00', '2026-08-16 11:12:00'),
(1503, 'Aarav Singh', 'profile.0050.aarav.singh@seed.amoraa.example.test', '+919990000050', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-03 11:11:00', '2026-02-03 11:11:00', '2026-08-12 11:11:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-18 03:31:00', NULL),
(1504, 'Tara Menon', 'profile.0051.tara.menon@seed.amoraa.example.test', '+919990000051', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-19 11:10:00', '2025-08-19 11:10:00', '2026-08-26 11:10:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:55:00', NULL),
(1505, 'Naina Iyer', 'profile.0052.naina.iyer@seed.amoraa.example.test', '+919990000052', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-11-19 11:09:00', '2025-11-19 11:09:00', '2026-08-11 11:09:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-10 08:45:00', NULL),
(1506, 'Neel Verma', 'profile.0053.neel.verma@seed.amoraa.example.test', '+919990000053', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-20 11:08:00', '2025-08-20 11:08:00', '2026-08-19 11:08:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-12 09:17:00', '2026-08-19 11:08:00'),
(1507, 'Zara Trivedi', 'profile.0054.zara.trivedi@seed.amoraa.example.test', '+919990000054', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-03-19 11:07:00', '2026-03-19 11:07:00', '2026-08-15 11:07:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-21 00:34:00', NULL),
(1508, 'Pranav Shah', 'profile.0055.pranav.shah@seed.amoraa.example.test', '+919990000055', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-10 11:06:00', '2026-04-10 11:06:00', '2026-08-13 11:06:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-09 17:06:00', NULL),
(1509, 'Yash Desai', 'profile.0056.yash.desai@seed.amoraa.example.test', '+919990000056', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-19 11:05:00', '2025-08-19 11:05:00', '2026-08-15 11:05:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:55:00', NULL),
(1510, 'Sara Khan', 'profile.0057.sara.khan@seed.amoraa.example.test', '+919990000057', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-08 11:04:00', '2025-09-08 11:04:00', '2026-08-26 11:04:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 16:08:00', '2026-08-26 11:04:00'),
(1511, 'Esha Patel', 'profile.0058.esha.patel@seed.amoraa.example.test', '+919990000058', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-06 11:03:00', '2025-08-06 11:03:00', '2026-08-17 11:03:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-16 04:53:00', NULL),
(1512, 'Rohan Sharma', 'profile.0059.rohan.sharma@seed.amoraa.example.test', '+919990000059', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-12 11:02:00', '2026-08-12 11:02:00', '2026-08-17 11:02:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-17 17:38:00', NULL),
(1513, 'Aditi Iyer', 'profile.0060.aditi.iyer@seed.amoraa.example.test', '+919990000060', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-02 11:01:00', '2026-08-02 11:01:00', '2026-08-19 11:01:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-28 06:48:00', NULL),
(1514, 'Ira Trivedi', 'profile.0061.ira.trivedi@seed.amoraa.example.test', '+919990000061', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-27 11:00:00', '2025-12-27 11:00:00', '2026-08-10 11:00:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:49:00', '2026-08-10 11:00:00'),
(1515, 'Rhea Joshi', 'profile.0062.rhea.joshi@seed.amoraa.example.test', '+919990000062', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-05-26 10:59:00', '2026-05-26 10:59:00', '2026-08-16 10:59:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-21 23:06:00', NULL),
(1516, 'Kavya Desai', 'profile.0063.kavya.desai@seed.amoraa.example.test', '+919990000063', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-08 10:58:00', '2025-12-08 10:58:00', '2026-08-22 10:58:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-26 12:13:00', NULL),
(1517, 'Krish Trivedi', 'profile.0064.krish.trivedi@seed.amoraa.example.test', '+919990000064', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-20 10:57:00', '2025-08-20 10:57:00', '2026-08-24 10:57:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-17 08:34:00', NULL),
(1518, 'Aditi Patel', 'profile.0065.aditi.patel@seed.amoraa.example.test', '+919990000065', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-21 10:56:00', '2026-08-21 10:56:00', '2026-08-24 10:56:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-26 10:43:00', '2026-08-24 10:56:00'),
(1519, 'Samir Shah', 'profile.0066.samir.shah@seed.amoraa.example.test', '+919990000066', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-23 10:55:00', '2025-12-23 10:55:00', '2026-08-27 10:55:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:48:00', NULL),
(1520, 'Tara Sharma', 'profile.0067.tara.sharma@seed.amoraa.example.test', '+919990000067', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-26 10:54:00', '2026-02-26 10:54:00', '2026-08-17 10:54:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-22 23:07:00', NULL),
(1521, 'Dev Bhat', 'profile.0068.dev.bhat@seed.amoraa.example.test', '+919990000068', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-07-18 10:53:00', '2025-07-18 10:53:00', '2026-08-12 10:53:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-23 07:40:00', NULL),
(1522, 'Mira Kapoor', 'profile.0069.mira.kapoor@seed.amoraa.example.test', '+919990000069', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-11-30 10:52:00', '2025-11-30 10:52:00', '2026-08-21 10:52:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-16 18:24:00', '2026-08-21 10:52:00'),
(1523, 'Aarav Shah', 'profile.0070.aarav.shah@seed.amoraa.example.test', '+919990000070', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-07-13 10:51:00', '2026-07-13 10:51:00', '2026-08-17 10:51:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-20 23:30:00', NULL),
(1524, 'Arjun Nair', 'profile.0071.arjun.nair@seed.amoraa.example.test', '+919990000071', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-11-01 10:50:00', '2025-11-01 10:50:00', '2026-08-17 10:50:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:49:00', NULL),
(1525, 'Sara Bhat', 'profile.0072.sara.bhat@seed.amoraa.example.test', '+919990000072', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-06-25 10:49:00', '2026-06-25 10:49:00', '2026-08-16 10:49:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-18 23:06:00', NULL),
(1526, 'Kavya Desai', 'profile.0073.kavya.desai@seed.amoraa.example.test', '+919990000073', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-13 10:48:00', '2026-02-13 10:48:00', '2026-08-17 10:48:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-28 15:06:00', '2026-08-17 10:48:00'),
(1527, 'Aisha Kapoor', 'profile.0074.aisha.kapoor@seed.amoraa.example.test', '+919990000074', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-07-08 10:47:00', '2025-07-08 10:47:00', '2026-08-24 10:47:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 07:28:00', NULL),
(1528, 'Tara Sharma', 'profile.0075.tara.sharma@seed.amoraa.example.test', '+919990000075', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-29 10:46:00', '2025-09-29 10:46:00', '2026-08-28 10:46:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-28 10:48:00', NULL),
(1529, 'Ira Nair', 'profile.0076.ira.nair@seed.amoraa.example.test', '+919990000076', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-07-15 10:45:00', '2025-07-15 10:45:00', '2026-08-12 10:45:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:55:00', NULL),
(1530, 'Diya Desai', 'profile.0077.diya.desai@seed.amoraa.example.test', '+919990000077', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-10-08 10:44:00', '2025-10-08 10:44:00', '2026-08-29 10:44:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-13 00:53:00', '2026-08-29 10:44:00'),
(1531, 'Ananya Rao', 'profile.0078.ananya.rao@seed.amoraa.example.test', '+919990000078', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-09 10:43:00', '2025-09-09 10:43:00', '2026-08-22 10:43:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-26 10:06:00', NULL),
(1532, 'Shaurya Shah', 'profile.0079.shaurya.shah@seed.amoraa.example.test', '+919990000079', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-05-13 10:42:00', '2026-05-13 10:42:00', '2026-08-09 10:42:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-14 10:10:00', NULL),
(1533, 'Rhea Iyer', 'profile.0080.rhea.iyer@seed.amoraa.example.test', '+919990000080', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-28 10:41:00', '2025-12-28 10:41:00', '2026-08-26 10:41:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-27 18:01:00', NULL),
(1534, 'Mira Sharma', 'profile.0081.mira.sharma@seed.amoraa.example.test', '+919990000081', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-01 10:40:00', '2026-08-01 10:40:00', '2026-08-13 10:40:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:49:00', '2026-08-13 10:40:00'),
(1535, 'Tara Vyas', 'profile.0082.tara.vyas@seed.amoraa.example.test', '+919990000082', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-22 10:39:00', '2026-02-22 10:39:00', '2026-08-26 10:39:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-18 02:52:00', NULL),
(1536, 'Saanvi Khan', 'profile.0083.saanvi.khan@seed.amoraa.example.test', '+919990000083', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-03-23 10:38:00', '2026-03-23 10:38:00', '2026-08-27 10:38:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-20 13:26:00', NULL),
(1537, 'Kavya Khan', 'profile.0084.kavya.khan@seed.amoraa.example.test', '+919990000084', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-03 10:37:00', '2026-02-03 10:37:00', '2026-08-16 10:37:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-25 09:27:00', NULL),
(1538, 'Meera Nair', 'profile.0085.meera.nair@seed.amoraa.example.test', '+919990000085', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-11 10:36:00', '2025-08-11 10:36:00', '2026-08-22 10:36:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-19 09:26:00', '2026-08-22 10:36:00'),
(1539, 'Neel Nair', 'profile.0086.neel.nair@seed.amoraa.example.test', '+919990000086', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-05 10:35:00', '2025-08-05 10:35:00', '2026-08-21 10:35:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:56:00', NULL),
(1540, 'Kabir Bhat', 'profile.0087.kabir.bhat@seed.amoraa.example.test', '+919990000087', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-21 10:34:00', '2025-09-21 10:34:00', '2026-08-16 10:34:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-11 02:29:00', NULL),
(1541, 'Mihir Shah', 'profile.0088.mihir.shah@seed.amoraa.example.test', '+919990000088', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-06-12 10:33:00', '2026-06-12 10:33:00', '2026-08-25 10:33:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-17 15:57:00', NULL),
(1542, 'Naina Iyer', 'profile.0089.naina.iyer@seed.amoraa.example.test', '+919990000089', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-06 10:32:00', '2025-08-06 10:32:00', '2026-08-24 10:32:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-15 05:20:00', '2026-08-24 10:32:00'),
(1543, 'Tara Trivedi', 'profile.0090.tara.trivedi@seed.amoraa.example.test', '+919990000090', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-31 10:31:00', '2025-12-31 10:31:00', '2026-08-17 10:31:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-21 14:02:00', NULL),
(1544, 'Ananya Sharma', 'profile.0091.ananya.sharma@seed.amoraa.example.test', '+919990000091', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-05 10:30:00', '2026-02-05 10:30:00', '2026-08-21 10:30:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:55:00', NULL),
(1545, 'Kabir Iyer', 'profile.0092.kabir.iyer@seed.amoraa.example.test', '+919990000092', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-03-11 10:29:00', '2026-03-11 10:29:00', '2026-08-18 10:29:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-24 19:57:00', NULL),
(1546, 'Tara Verma', 'profile.0093.tara.verma@seed.amoraa.example.test', '+919990000093', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-25 10:28:00', '2026-04-25 10:28:00', '2026-08-29 10:28:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-24 21:16:00', '2026-08-29 10:28:00'),
(1547, 'Rhea Trivedi', 'profile.0094.rhea.trivedi@seed.amoraa.example.test', '+919990000094', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-19 10:27:00', '2026-02-19 10:27:00', '2026-08-09 10:27:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-10 15:03:00', NULL),
(1548, 'Yash Singh', 'profile.0095.yash.singh@seed.amoraa.example.test', '+919990000095', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-07-17 10:26:00', '2026-07-17 10:26:00', '2026-08-27 10:26:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-26 18:56:00', NULL),
(1549, 'Aarav Verma', 'profile.0096.aarav.verma@seed.amoraa.example.test', '+919990000096', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-07-29 10:25:00', '2026-07-29 10:25:00', '2026-08-20 10:25:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:53:00', NULL),
(1550, 'Neel Nair', 'profile.0097.neel.nair@seed.amoraa.example.test', '+919990000097', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-10-18 10:24:00', '2025-10-18 10:24:00', '2026-08-10 10:24:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-23 16:37:00', '2026-08-10 10:24:00'),
(1551, 'Aditi Joshi', 'profile.0098.aditi.joshi@seed.amoraa.example.test', '+919990000098', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-16 10:23:00', '2026-08-16 10:23:00', '2026-08-16 10:23:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-20 05:30:00', NULL),
(1552, 'Harsh Soni', 'profile.0099.harsh.soni@seed.amoraa.example.test', '+919990000099', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-07-29 10:22:00', '2025-07-29 10:22:00', '2026-08-15 10:22:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-10 03:02:00', NULL),
(1553, 'Shaurya Mehta', 'profile.0100.shaurya.mehta@seed.amoraa.example.test', '+919990000100', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-30 10:21:00', '2026-04-30 10:21:00', '2026-08-27 10:21:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-18 14:36:00', NULL),
(1554, 'Nisha Kapoor', 'profile.0101.nisha.kapoor@seed.amoraa.example.test', '+919990000101', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-01 10:20:00', '2025-12-01 10:20:00', '2026-08-17 10:20:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:54:00', '2026-08-17 10:20:00'),
(1555, 'Ira Joshi', 'profile.0102.ira.joshi@seed.amoraa.example.test', '+919990000102', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-01-15 10:19:00', '2026-01-15 10:19:00', '2026-08-10 10:19:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-15 18:23:00', NULL),
(1556, 'Tara Rao', 'profile.0103.tara.rao@seed.amoraa.example.test', '+919990000103', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-09 10:18:00', '2026-04-09 10:18:00', '2026-08-27 10:18:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-19 19:40:00', NULL),
(1557, 'Esha Rao', 'profile.0104.esha.rao@seed.amoraa.example.test', '+919990000104', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-06 10:17:00', '2025-12-06 10:17:00', '2026-08-23 10:17:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-28 02:07:00', NULL),
(1558, 'Yash Singh', 'profile.0105.yash.singh@seed.amoraa.example.test', '+919990000105', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-05-19 10:16:00', '2026-05-19 10:16:00', '2026-08-17 10:16:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-24 12:25:00', '2026-08-17 10:16:00'),
(1559, 'Nisha Menon', 'profile.0106.nisha.menon@seed.amoraa.example.test', '+919990000106', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-05-19 10:15:00', '2026-05-19 10:15:00', '2026-08-18 10:15:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:59:00', NULL),
(1560, 'Aarav Vyas', 'profile.0107.aarav.vyas@seed.amoraa.example.test', '+919990000107', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-22 10:14:00', '2025-12-22 10:14:00', '2026-08-17 10:14:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-23 00:48:00', NULL),
(1561, 'Diya Iyer', 'profile.0108.diya.iyer@seed.amoraa.example.test', '+919990000108', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-05-02 10:13:00', '2026-05-02 10:13:00', '2026-08-26 10:13:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-26 12:58:00', NULL),
(1562, 'Rhea Desai', 'profile.0109.rhea.desai@seed.amoraa.example.test', '+919990000109', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-03-14 10:12:00', '2026-03-14 10:12:00', '2026-08-27 10:12:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-26 03:51:00', '2026-08-27 10:12:00'),
(1563, 'Krish Singh', 'profile.0110.krish.singh@seed.amoraa.example.test', '+919990000110', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-16 10:11:00', '2025-09-16 10:11:00', '2026-08-28 10:11:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-23 08:22:00', NULL),
(1564, 'Aditi Menon', 'profile.0111.aditi.menon@seed.amoraa.example.test', '+919990000111', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-03-21 10:10:00', '2026-03-21 10:10:00', '2026-08-19 10:10:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:50:00', NULL),
(1565, 'Mihir Sharma', 'profile.0112.mihir.sharma@seed.amoraa.example.test', '+919990000112', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-25 10:09:00', '2026-04-25 10:09:00', '2026-08-18 10:09:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-16 17:21:00', NULL),
(1566, 'Nisha Soni', 'profile.0113.nisha.soni@seed.amoraa.example.test', '+919990000113', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-10-24 10:08:00', '2025-10-24 10:08:00', '2026-08-28 10:08:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-26 06:34:00', '2026-08-28 10:08:00'),
(1567, 'Arjun Khan', 'profile.0114.arjun.khan@seed.amoraa.example.test', '+919990000114', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-23 10:07:00', '2025-08-23 10:07:00', '2026-08-29 10:07:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-21 16:35:00', NULL),
(1568, 'Aarav Iyer', 'profile.0115.aarav.iyer@seed.amoraa.example.test', '+919990000115', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-11-24 10:06:00', '2025-11-24 10:06:00', '2026-08-24 10:06:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-27 20:47:00', NULL),
(1569, 'Ishaan Menon', 'profile.0116.ishaan.menon@seed.amoraa.example.test', '+919990000116', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-26 10:05:00', '2026-02-26 10:05:00', '2026-08-14 10:05:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:51:00', NULL),
(1570, 'Kabir Trivedi', 'profile.0117.kabir.trivedi@seed.amoraa.example.test', '+919990000117', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-03-31 10:04:00', '2026-03-31 10:04:00', '2026-08-16 10:04:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-23 18:03:00', '2026-08-16 10:04:00'),
(1571, 'Rohan Bhat', 'profile.0118.rohan.bhat@seed.amoraa.example.test', '+919990000118', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-24 10:03:00', '2025-12-24 10:03:00', '2026-08-09 10:03:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-12 02:59:00', NULL),
(1572, 'Ananya Vyas', 'profile.0119.ananya.vyas@seed.amoraa.example.test', '+919990000119', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-10 10:02:00', '2026-04-10 10:02:00', '2026-08-18 10:02:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-09 23:19:00', NULL),
(1573, 'Sara Iyer', 'profile.0120.sara.iyer@seed.amoraa.example.test', '+919990000120', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-05 10:01:00', '2026-04-05 10:01:00', '2026-08-09 10:01:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-26 07:38:00', NULL),
(1574, 'Mira Singh', 'profile.0121.mira.singh@seed.amoraa.example.test', '+919990000121', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-07-08 10:00:00', '2025-07-08 10:00:00', '2026-08-26 10:00:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:54:00', '2026-08-26 10:00:00'),
(1575, 'Shaurya Patel', 'profile.0122.shaurya.patel@seed.amoraa.example.test', '+919990000122', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-28 09:59:00', '2026-08-28 09:59:00', '2026-08-28 09:59:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-27 11:28:00', NULL),
(1576, 'Aditi Patel', 'profile.0123.aditi.patel@seed.amoraa.example.test', '+919990000123', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-05-16 09:58:00', '2026-05-16 09:58:00', '2026-08-20 09:58:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-17 23:23:00', NULL),
(1577, 'Mihir Rao', 'profile.0124.mihir.rao@seed.amoraa.example.test', '+919990000124', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-28 09:57:00', '2025-09-28 09:57:00', '2026-08-13 09:57:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-16 02:46:00', NULL),
(1578, 'Meera Vyas', 'profile.0125.meera.vyas@seed.amoraa.example.test', '+919990000125', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-26 09:56:00', '2026-04-26 09:56:00', '2026-08-22 09:56:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-15 10:59:00', '2026-08-22 09:56:00'),
(1579, 'Samir Mehta', 'profile.0126.samir.mehta@seed.amoraa.example.test', '+919990000126', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-11-07 09:55:00', '2025-11-07 09:55:00', '2026-08-09 09:55:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:59:00', NULL),
(1580, 'Krish Rao', 'profile.0127.krish.rao@seed.amoraa.example.test', '+919990000127', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-02 09:54:00', '2025-09-02 09:54:00', '2026-08-14 09:54:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-19 10:09:00', NULL),
(1581, 'Avni Mehta', 'profile.0128.avni.mehta@seed.amoraa.example.test', '+919990000128', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-31 09:53:00', '2025-08-31 09:53:00', '2026-08-22 09:53:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-16 16:33:00', NULL),
(1582, 'Kabir Desai', 'profile.0129.kabir.desai@seed.amoraa.example.test', '+919990000129', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-06-14 09:52:00', '2026-06-14 09:52:00', '2026-08-15 09:52:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-22 12:56:00', '2026-08-15 09:52:00'),
(1583, 'Samir Kapoor', 'profile.0130.samir.kapoor@seed.amoraa.example.test', '+919990000130', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-07 09:51:00', '2026-08-07 09:51:00', '2026-08-22 09:51:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-18 09:19:00', NULL),
(1584, 'Avni Iyer', 'profile.0131.avni.iyer@seed.amoraa.example.test', '+919990000131', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-03-23 09:50:00', '2026-03-23 09:50:00', '2026-08-22 09:50:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:52:00', NULL),
(1585, 'Esha Nair', 'profile.0132.esha.nair@seed.amoraa.example.test', '+919990000132', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-25 09:49:00', '2026-08-25 09:49:00', '2026-08-25 09:49:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-14 06:56:00', NULL),
(1586, 'Ira Patel', 'profile.0133.ira.patel@seed.amoraa.example.test', '+919990000133', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-17 09:48:00', '2025-12-17 09:48:00', '2026-08-25 09:48:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-10 20:00:00', '2026-08-25 09:48:00'),
(1587, 'Diya Vyas', 'profile.0134.diya.vyas@seed.amoraa.example.test', '+919990000134', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-01-27 09:47:00', '2026-01-27 09:47:00', '2026-08-29 09:47:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-28 11:09:00', NULL),
(1588, 'Veer Khan', 'profile.0135.veer.khan@seed.amoraa.example.test', '+919990000135', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-07-17 09:46:00', '2025-07-17 09:46:00', '2026-08-24 09:46:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-16 18:45:00', NULL),
(1589, 'Dev Desai', 'profile.0136.dev.desai@seed.amoraa.example.test', '+919990000136', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-04 09:45:00', '2026-02-04 09:45:00', '2026-08-25 09:45:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:52:00', NULL),
(1590, 'Krish Shah', 'profile.0137.krish.shah@seed.amoraa.example.test', '+919990000137', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-06-25 09:44:00', '2026-06-25 09:44:00', '2026-08-22 09:44:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-16 18:05:00', '2026-08-22 09:44:00'),
(1591, 'Harsh Kapoor', 'profile.0138.harsh.kapoor@seed.amoraa.example.test', '+919990000138', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-08-19 09:43:00', '2026-08-19 09:43:00', '2026-08-19 09:43:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-26 01:28:00', NULL),
(1592, 'Pranav Bhat', 'profile.0139.pranav.bhat@seed.amoraa.example.test', '+919990000139', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-16 09:42:00', '2026-04-16 09:42:00', '2026-08-25 09:42:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-13 11:43:00', NULL),
(1593, 'Veer Singh', 'profile.0140.veer.singh@seed.amoraa.example.test', '+919990000140', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-25 09:41:00', '2025-12-25 09:41:00', '2026-08-27 09:41:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-19 18:43:00', NULL),
(1594, 'Meera Iyer', 'profile.0141.meera.iyer@seed.amoraa.example.test', '+919990000141', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-07-16 09:40:00', '2026-07-16 09:40:00', '2026-08-11 09:40:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:52:00', '2026-08-11 09:40:00');
INSERT INTO `users` (`id`, `name`, `email`, `phoneNumber`, `passwordHash`, `authProvider`, `googleId`, `isVerified`, `termsAcceptedAt`, `createdAt`, `updatedAt`, `accountStatus`, `deactivatedAt`, `deletedAt`, `tokenVersion`, `deletionReason`, `deletionDetails`, `lastActiveAt`, `identityVerifiedAt`) VALUES
(1595, 'Tara Verma', 'profile.0142.tara.verma@seed.amoraa.example.test', '+919990000142', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-09-24 09:39:00', '2025-09-24 09:39:00', '2026-08-17 09:39:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-28 02:06:00', NULL),
(1596, 'Mihir Mehta', 'profile.0143.mihir.mehta@seed.amoraa.example.test', '+919990000143', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-03-29 09:38:00', '2026-03-29 09:38:00', '2026-08-15 09:38:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-22 21:28:00', NULL),
(1597, 'Aisha Kapoor', 'profile.0144.aisha.kapoor@seed.amoraa.example.test', '+919990000144', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-12-04 09:37:00', '2025-12-04 09:37:00', '2026-08-14 09:37:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-24 16:58:00', NULL),
(1598, 'Priya Mehta', 'profile.0145.priya.mehta@seed.amoraa.example.test', '+919990000145', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-10-29 09:36:00', '2025-10-29 09:36:00', '2026-08-27 09:36:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-24 13:37:00', '2026-08-27 09:36:00'),
(1599, 'Arjun Patel', 'profile.0146.arjun.patel@seed.amoraa.example.test', '+919990000146', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-08-09 09:35:00', '2025-08-09 09:35:00', '2026-08-21 09:35:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-29 11:52:00', NULL),
(1600, 'Aditi Vyas', 'profile.0147.aditi.vyas@seed.amoraa.example.test', '+919990000147', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-04-16 09:34:00', '2026-04-16 09:34:00', '2026-08-10 09:34:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-20 08:19:00', NULL),
(1601, 'Sara Trivedi', 'profile.0148.sara.trivedi@seed.amoraa.example.test', '+919990000148', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-07-02 09:33:00', '2026-07-02 09:33:00', '2026-08-09 09:33:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-14 17:05:00', NULL),
(1602, 'Diya Trivedi', 'profile.0149.diya.trivedi@seed.amoraa.example.test', '+919990000149', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2025-07-31 09:32:00', '2025-07-31 09:32:00', '2026-08-16 09:32:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-28 05:56:00', '2026-08-16 09:32:00'),
(1603, 'Rhea Khan', 'profile.0150.rhea.khan@seed.amoraa.example.test', '+919990000150', '$2b$10$ERSmO/v2ge8iwcJsIJ54buYob1CqY27c0T7n480ABRmr/li6eUQXq', 'local', NULL, 1, '2026-02-19 09:31:00', '2026-02-19 09:31:00', '2026-08-22 09:31:00', 'active', NULL, NULL, 0, NULL, NULL, '2026-08-17 07:26:00', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `usertimelineevents`
--

CREATE TABLE `usertimelineevents` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `userId` int(11) NOT NULL,
  `eventType` varchar(80) NOT NULL,
  `title` varchar(160) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `status` varchar(80) DEFAULT NULL,
  `relatedReference` varchar(191) DEFAULT NULL,
  `administratorId` bigint(20) UNSIGNED DEFAULT NULL,
  `occurredAt` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `usertimelineevents`
--

INSERT INTO `usertimelineevents` (`id`, `userId`, `eventType`, `title`, `description`, `status`, `relatedReference`, `administratorId`, `occurredAt`) VALUES
(1, 1, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(2, 2, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(3, 3, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(4, 4, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(5, 5, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(6, 6, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(7, 7, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(8, 8, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(9, 9, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(10, 10, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(11, 11, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(12, 12, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(13, 13, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(14, 14, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(15, 15, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:50:36'),
(16, 16, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 18:54:00'),
(17, 17, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 20:15:13'),
(18, 18, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-12 06:36:21'),
(19, 49, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-12 10:31:12'),
(20, 85, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-13 06:37:10'),
(21, 1454, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-07-13 12:00:00'),
(22, 1455, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-21 11:59:00'),
(23, 1456, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-26 11:58:00'),
(24, 1457, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-28 11:57:00'),
(25, 1458, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-10-08 11:56:00'),
(26, 1459, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-29 11:55:00'),
(27, 1460, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2024-03-12 11:54:00'),
(28, 1461, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-28 11:53:00'),
(29, 1462, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-10 11:52:00'),
(30, 1463, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-03-23 11:51:00'),
(31, 1464, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-11-11 11:50:00'),
(32, 1465, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-03-17 11:49:00'),
(33, 1466, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-05-29 11:48:00'),
(34, 1467, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-18 11:47:00'),
(35, 1468, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-30 11:46:00'),
(36, 1469, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-17 11:45:00'),
(37, 1470, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-03 11:44:00'),
(38, 1471, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-11 11:43:00'),
(39, 1472, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-07-01 11:42:00'),
(40, 1473, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-01-05 11:41:00'),
(41, 1474, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-09 11:40:00'),
(42, 1475, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-21 11:39:00'),
(43, 1476, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-25 11:38:00'),
(44, 1477, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-05-02 11:37:00'),
(45, 1478, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-11-06 11:36:00'),
(46, 1479, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-21 11:35:00'),
(47, 1480, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-09 11:34:00'),
(48, 1481, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-07-19 11:33:00'),
(49, 1482, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-03-16 11:32:00'),
(50, 1483, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-08 11:31:00'),
(51, 1484, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-02 11:30:00'),
(52, 1485, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-23 11:29:00'),
(53, 1486, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-07 11:28:00'),
(54, 1487, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-11-09 11:27:00'),
(55, 1488, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-01-21 11:26:00'),
(56, 1489, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-10-19 11:25:00'),
(57, 1490, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-10-08 11:24:00'),
(58, 1491, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-13 11:23:00'),
(59, 1492, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-29 11:22:00'),
(60, 1493, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-25 11:21:00'),
(61, 1494, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-07-04 11:20:00'),
(62, 1495, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-07-15 11:19:00'),
(63, 1496, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-11-04 11:18:00'),
(64, 1497, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-30 11:17:00'),
(65, 1498, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-18 11:16:00'),
(66, 1499, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-01-19 11:15:00'),
(67, 1500, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-05-31 11:14:00'),
(68, 1501, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-07-18 11:13:00'),
(69, 1502, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-10-15 11:12:00'),
(70, 1503, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-03 11:11:00'),
(71, 1504, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-19 11:10:00'),
(72, 1505, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-11-19 11:09:00'),
(73, 1506, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-20 11:08:00'),
(74, 1507, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-03-19 11:07:00'),
(75, 1508, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-10 11:06:00'),
(76, 1509, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-19 11:05:00'),
(77, 1510, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-08 11:04:00'),
(78, 1511, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-06 11:03:00'),
(79, 1512, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-12 11:02:00'),
(80, 1513, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-02 11:01:00'),
(81, 1514, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-27 11:00:00'),
(82, 1515, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-05-26 10:59:00'),
(83, 1516, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-08 10:58:00'),
(84, 1517, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-20 10:57:00'),
(85, 1518, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-21 10:56:00'),
(86, 1519, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-23 10:55:00'),
(87, 1520, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-26 10:54:00'),
(88, 1521, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-07-18 10:53:00'),
(89, 1522, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-11-30 10:52:00'),
(90, 1523, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-07-13 10:51:00'),
(91, 1524, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-11-01 10:50:00'),
(92, 1525, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-06-25 10:49:00'),
(93, 1526, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-13 10:48:00'),
(94, 1527, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-07-08 10:47:00'),
(95, 1528, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-29 10:46:00'),
(96, 1529, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-07-15 10:45:00'),
(97, 1530, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-10-08 10:44:00'),
(98, 1531, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-09 10:43:00'),
(99, 1532, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-05-13 10:42:00'),
(100, 1533, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-28 10:41:00'),
(101, 1534, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-01 10:40:00'),
(102, 1535, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-22 10:39:00'),
(103, 1536, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-03-23 10:38:00'),
(104, 1537, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-03 10:37:00'),
(105, 1538, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-11 10:36:00'),
(106, 1539, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-05 10:35:00'),
(107, 1540, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-21 10:34:00'),
(108, 1541, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-06-12 10:33:00'),
(109, 1542, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-06 10:32:00'),
(110, 1543, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-31 10:31:00'),
(111, 1544, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-05 10:30:00'),
(112, 1545, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-03-11 10:29:00'),
(113, 1546, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-25 10:28:00'),
(114, 1547, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-19 10:27:00'),
(115, 1548, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-07-17 10:26:00'),
(116, 1549, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-07-29 10:25:00'),
(117, 1550, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-10-18 10:24:00'),
(118, 1551, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-16 10:23:00'),
(119, 1552, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-07-29 10:22:00'),
(120, 1553, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-30 10:21:00'),
(121, 1554, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-01 10:20:00'),
(122, 1555, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-01-15 10:19:00'),
(123, 1556, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-09 10:18:00'),
(124, 1557, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-06 10:17:00'),
(125, 1558, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-05-19 10:16:00'),
(126, 1559, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-05-19 10:15:00'),
(127, 1560, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-22 10:14:00'),
(128, 1561, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-05-02 10:13:00'),
(129, 1562, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-03-14 10:12:00'),
(130, 1563, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-16 10:11:00'),
(131, 1564, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-03-21 10:10:00'),
(132, 1565, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-25 10:09:00'),
(133, 1566, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-10-24 10:08:00'),
(134, 1567, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-23 10:07:00'),
(135, 1568, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-11-24 10:06:00'),
(136, 1569, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-26 10:05:00'),
(137, 1570, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-03-31 10:04:00'),
(138, 1571, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-24 10:03:00'),
(139, 1572, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-10 10:02:00'),
(140, 1573, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-05 10:01:00'),
(141, 1574, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-07-08 10:00:00'),
(142, 1575, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-28 09:59:00'),
(143, 1576, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-05-16 09:58:00'),
(144, 1577, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-28 09:57:00'),
(145, 1578, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-26 09:56:00'),
(146, 1579, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-11-07 09:55:00'),
(147, 1580, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-02 09:54:00'),
(148, 1581, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-31 09:53:00'),
(149, 1582, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-06-14 09:52:00'),
(150, 1583, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-07 09:51:00'),
(151, 1584, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-03-23 09:50:00'),
(152, 1585, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-25 09:49:00'),
(153, 1586, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-17 09:48:00'),
(154, 1587, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-01-27 09:47:00'),
(155, 1588, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-07-17 09:46:00'),
(156, 1589, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-04 09:45:00'),
(157, 1590, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-06-25 09:44:00'),
(158, 1591, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-08-19 09:43:00'),
(159, 1592, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-16 09:42:00'),
(160, 1593, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-25 09:41:00'),
(161, 1594, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-07-16 09:40:00'),
(162, 1595, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-09-24 09:39:00'),
(163, 1596, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-03-29 09:38:00'),
(164, 1597, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-12-04 09:37:00'),
(165, 1598, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-10-29 09:36:00'),
(166, 1599, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-08-09 09:35:00'),
(167, 1600, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-04-16 09:34:00'),
(168, 1601, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-07-02 09:33:00'),
(169, 1602, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2025-07-31 09:32:00'),
(170, 1603, 'account_created', 'Account created', NULL, NULL, NULL, NULL, '2026-02-19 09:31:00');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accountdeletionconfirmations`
--
ALTER TABLE `accountdeletionconfirmations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `tokenSelector` (`tokenSelector`),
  ADD KEY `account_deletion_confirmations_user_expiry` (`userId`,`expiresAt`);

--
-- Indexes for table `accountdeletionrequests`
--
ALTER TABLE `accountdeletionrequests`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `correlationId` (`correlationId`),
  ADD KEY `account_deletion_requests_user_requested` (`userId`,`requestedAt`),
  ADD KEY `account_deletion_requests_status_requested` (`status`,`requestedAt`);

--
-- Indexes for table `adminauditlogs`
--
ALTER TABLE `adminauditlogs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `admin_audit_actor_time` (`administratorId`,`createdAt`),
  ADD KEY `admin_audit_target_time` (`targetType`,`targetId`,`createdAt`),
  ADD KEY `admin_audit_action_time` (`action`,`createdAt`);

--
-- Indexes for table `admindiscoverfilterfields`
--
ALTER TABLE `admindiscoverfilterfields`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `key` (`key`),
  ADD KEY `updatedByAdministratorId` (`updatedByAdministratorId`),
  ADD KEY `admin_discover_filters_state_order` (`enabled`,`visible`,`displayOrder`);

--
-- Indexes for table `admindiscoversettings`
--
ALTER TABLE `admindiscoversettings`
  ADD PRIMARY KEY (`key`),
  ADD KEY `updatedByAdministratorId` (`updatedByAdministratorId`);

--
-- Indexes for table `adminidempotencykeys`
--
ALTER TABLE `adminidempotencykeys`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `admin_idempotency_actor_scope_key` (`administratorId`,`scope`,`idempotencyKey`),
  ADD KEY `admin_idempotency_expiry` (`expiresAt`);

--
-- Indexes for table `admininvitations`
--
ALTER TABLE `admininvitations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `selector` (`selector`),
  ADD KEY `invitedByAdministratorId` (`invitedByAdministratorId`),
  ADD KEY `admin_invitations_owner_expiry` (`administratorId`,`expiresAt`),
  ADD KEY `admin_invitations_delivery_state` (`deliveryStatus`,`createdAt`);

--
-- Indexes for table `administratorroles`
--
ALTER TABLE `administratorroles`
  ADD PRIMARY KEY (`administratorId`,`roleId`),
  ADD KEY `roleId` (`roleId`);

--
-- Indexes for table `administrators`
--
ALTER TABLE `administrators`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `administrators_status` (`status`,`id`),
  ADD KEY `Administrators_suspendedByAdministratorId_foreign_idx` (`suspendedByAdministratorId`),
  ADD KEY `administrators_created_by_fk` (`createdByAdministratorId`),
  ADD KEY `administrators_status_created_at` (`status`,`createdAt`),
  ADD KEY `administrators_invitation_created_at` (`invitationStatus`,`createdAt`);

--
-- Indexes for table `adminmfachallenges`
--
ALTER TABLE `adminmfachallenges`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `selector` (`selector`),
  ADD KEY `admin_mfa_challenges_owner_expiry_state` (`administratorId`,`expiresAt`,`consumedAt`);

--
-- Indexes for table `adminmfacredentials`
--
ALTER TABLE `adminmfacredentials`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `administratorId` (`administratorId`),
  ADD KEY `admin_mfa_credentials_state_admin` (`enabledAt`,`administratorId`);

--
-- Indexes for table `adminmfarecoverycodes`
--
ALTER TABLE `adminmfarecoverycodes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codeHash` (`codeHash`),
  ADD KEY `admin_mfa_recovery_owner_generation_state` (`administratorId`,`generation`,`consumedAt`);

--
-- Indexes for table `adminpasswordresettokens`
--
ALTER TABLE `adminpasswordresettokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `selector` (`selector`),
  ADD KEY `admin_password_reset_owner_expiry` (`administratorId`,`expiresAt`);

--
-- Indexes for table `adminpermissions`
--
ALTER TABLE `adminpermissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `key` (`key`);

--
-- Indexes for table `adminrefreshtokens`
--
ALTER TABLE `adminrefreshtokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `selector` (`selector`),
  ADD KEY `admin_refresh_tokens_owner_expiry` (`administratorId`,`expiresAt`),
  ADD KEY `AdminRefreshTokens_replacedByTokenId_foreign_idx` (`replacedByTokenId`),
  ADD KEY `admin_refresh_tokens_family_state` (`sessionFamilyId`,`revokedAt`);

--
-- Indexes for table `adminreportcases`
--
ALTER TABLE `adminreportcases`
  ADD PRIMARY KEY (`reportId`),
  ADD KEY `assignedAdministratorId` (`assignedAdministratorId`),
  ADD KEY `resolvedByAdministratorId` (`resolvedByAdministratorId`),
  ADD KEY `admin_report_cases_status_assigned_administrator_id_updated_at` (`status`,`assignedAdministratorId`,`updatedAt`);

--
-- Indexes for table `adminreportnotes`
--
ALTER TABLE `adminreportnotes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `authorAdministratorId` (`authorAdministratorId`),
  ADD KEY `admin_report_notes_report_id_created_at` (`reportId`,`createdAt`);

--
-- Indexes for table `adminrolepermissions`
--
ALTER TABLE `adminrolepermissions`
  ADD PRIMARY KEY (`roleId`,`permissionId`),
  ADD KEY `permissionId` (`permissionId`);

--
-- Indexes for table `adminroles`
--
ALTER TABLE `adminroles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `key` (`key`),
  ADD KEY `admin_roles_state_name` (`isActive`,`name`);

--
-- Indexes for table `adminusernotes`
--
ALTER TABLE `adminusernotes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `deletedByAdministratorId` (`deletedByAdministratorId`),
  ADD KEY `admin_user_notes_user_state_time` (`userId`,`deletedAt`,`createdAt`),
  ADD KEY `admin_user_notes_author_state` (`authorAdministratorId`,`deletedAt`);

--
-- Indexes for table `adminusernoteversions`
--
ALTER TABLE `adminusernoteversions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `admin_user_note_versions_note_version` (`noteId`,`version`),
  ADD KEY `administratorId` (`administratorId`);

--
-- Indexes for table `blocks`
--
ALTER TABLE `blocks`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `blocks_blocker_blocked_unique` (`blockerUserId`,`blockedUserId`),
  ADD KEY `blocks_blocked_blocker_lookup` (`blockedUserId`,`blockerUserId`);

--
-- Indexes for table `conversationparticipants`
--
ALTER TABLE `conversationparticipants`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `conversation_participants_conversation_user_unique` (`conversationId`,`userId`),
  ADD KEY `conversation_participants_user_conversation` (`userId`,`conversationId`),
  ADD KEY `conversation_participants_last_read_message_fk` (`lastReadMessageId`),
  ADD KEY `conversation_participants_mute_lookup` (`userId`,`mutedAt`,`mutedUntil`),
  ADD KEY `conversation_participants_hidden_lookup` (`userId`,`hiddenAt`);

--
-- Indexes for table `conversations`
--
ALTER TABLE `conversations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `conversations_pair_key_unique` (`pairKey`),
  ADD KEY `conversations_activity` (`lastMessageAt`,`id`),
  ADD KEY `conversations_last_message_fk` (`lastMessageId`);

--
-- Indexes for table `discoveractions`
--
ALTER TABLE `discoveractions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `discover_actions_actor_user_id_target_user_id` (`actorUserId`,`targetUserId`),
  ADD KEY `targetUserId` (`targetUserId`);

--
-- Indexes for table `discoverfilterpreferences`
--
ALTER TABLE `discoverfilterpreferences`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `userId` (`userId`);

--
-- Indexes for table `eventregistrations`
--
ALTER TABLE `eventregistrations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `event_registrations_event_user_unique` (`eventId`,`userId`),
  ADD KEY `event_registrations_capacity_lookup` (`eventId`,`status`),
  ADD KEY `event_registrations_user_lookup` (`userId`,`status`,`eventId`);

--
-- Indexes for table `events`
--
ALTER TABLE `events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `events_browse_order` (`status`,`visibility`,`startDateTime`,`id`),
  ADD KEY `events_filter_lookup` (`category`,`city`,`startDateTime`),
  ADD KEY `events_host_order` (`organizerId`,`startDateTime`),
  ADD KEY `events_registration_deadline` (`registrationDeadline`);

--
-- Indexes for table `eventwaitlist`
--
ALTER TABLE `eventwaitlist`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `event_waitlist_event_user_unique` (`eventId`,`userId`),
  ADD KEY `event_waitlist_promotion_order` (`eventId`,`status`,`joinedAt`,`id`),
  ADD KEY `event_waitlist_user_lookup` (`userId`,`status`,`eventId`);

--
-- Indexes for table `identityverificationdecisionevents`
--
ALTER TABLE `identityverificationdecisionevents`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idempotencyKey` (`idempotencyKey`),
  ADD KEY `reasonId` (`reasonId`),
  ADD KEY `identity_verification_decisions_history` (`verificationId`,`createdAt`,`id`),
  ADD KEY `identity_verification_decisions_reviewer` (`administratorId`,`createdAt`,`id`),
  ADD KEY `identity_verification_decisions_action` (`action`,`createdAt`,`id`);

--
-- Indexes for table `identityverificationreasons`
--
ALTER TABLE `identityverificationreasons`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `identity_verification_reasons_active_action` (`action`,`isActive`,`sortOrder`,`id`);

--
-- Indexes for table `identityverifications`
--
ALTER TABLE `identityverifications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `userId` (`userId`),
  ADD KEY `identity_verifications_review_queue` (`status`,`submittedAt`,`id`),
  ADD KEY `identity_verifications_reviewer_history` (`reviewerAdministratorId`,`reviewedAt`,`id`),
  ADD KEY `identity_verifications_status_updated` (`status`,`updatedAt`,`id`);

--
-- Indexes for table `matches`
--
ALTER TABLE `matches`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `matches_user_one_id_user_two_id` (`userOneId`,`userTwoId`),
  ADD KEY `userTwoId` (`userTwoId`);

--
-- Indexes for table `matchingactionfailures`
--
ALTER TABLE `matchingactionfailures`
  ADD PRIMARY KEY (`id`),
  ADD KEY `targetUserId` (`targetUserId`),
  ADD KEY `matching_action_failures_type_time` (`actionType`,`createdAt`),
  ADD KEY `matching_action_failures_code_time` (`safeCode`,`createdAt`),
  ADD KEY `matching_action_failures_actor_time` (`actorUserId`,`createdAt`);

--
-- Indexes for table `messagemedia`
--
ALTER TABLE `messagemedia`
  ADD PRIMARY KEY (`id`),
  ADD KEY `message_media_message_id` (`messageId`,`id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `messages_conversation_id` (`conversationId`,`id`),
  ADD KEY `messages_conversation_sender_id` (`conversationId`,`senderId`,`id`),
  ADD KEY `messages_sender_fk` (`senderId`);

--
-- Indexes for table `notificationdeliveries`
--
ALTER TABLE `notificationdeliveries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `notification_deliveries_target_unique` (`notificationId`,`userDeviceId`,`channel`),
  ADD KEY `userDeviceId` (`userDeviceId`),
  ADD KEY `notification_deliveries_retry_queue` (`status`,`lastAttemptAt`,`id`);

--
-- Indexes for table `notificationpreferences`
--
ALTER TABLE `notificationpreferences`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `userId` (`userId`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `notifications_user_dedupe_unique` (`userId`,`dedupeKey`),
  ADD KEY `notifications_inbox_order` (`userId`,`createdAt`,`id`),
  ADD KEY `notifications_unread_lookup` (`userId`,`isRead`,`deletedAt`),
  ADD KEY `notifications_actor_user_id` (`actorUserId`);

--
-- Indexes for table `onboardingprofiles`
--
ALTER TABLE `onboardingprofiles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `userId` (`userId`),
  ADD KEY `onboarding_profiles_discover_eligibility` (`onboardingCompleted`,`birthDate`,`communicationStyle`,`userId`);

--
-- Indexes for table `otptokens`
--
ALTER TABLE `otptokens`
  ADD PRIMARY KEY (`id`),
  ADD KEY `otp_tokens_resend_policy` (`phoneNumber`,`purpose`,`consumed`,`createdAt`),
  ADD KEY `otp_tokens_email_policy` (`email`,`purpose`,`consumed`,`createdAt`);

--
-- Indexes for table `paymentevents`
--
ALTER TABLE `paymentevents`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `payment_events_provider_event_unique` (`provider`,`providerEventId`),
  ADD KEY `payment_events_payment_history` (`paymentId`,`createdAt`),
  ADD KEY `payment_events_admin_status_history` (`status`,`createdAt`,`id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `payments_user_idempotency_unique` (`userId`,`idempotencyKey`),
  ADD UNIQUE KEY `payments_provider_order_unique` (`provider`,`providerOrderId`),
  ADD UNIQUE KEY `payments_provider_payment_unique` (`provider`,`providerPaymentId`),
  ADD KEY `planId` (`planId`),
  ADD KEY `payments_user_history` (`userId`,`createdAt`,`id`),
  ADD KEY `payments_admin_status_history` (`status`,`createdAt`,`id`),
  ADD KEY `payments_admin_currency_history` (`currency`,`createdAt`,`id`);

--
-- Indexes for table `platformsettings`
--
ALTER TABLE `platformsettings`
  ADD PRIMARY KEY (`key`),
  ADD KEY `updatedByAdministratorId` (`updatedByAdministratorId`);

--
-- Indexes for table `profiletaxonomycategories`
--
ALTER TABLE `profiletaxonomycategories`
  ADD PRIMARY KEY (`key`);

--
-- Indexes for table `profiletaxonomyoptions`
--
ALTER TABLE `profiletaxonomyoptions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `profile_taxonomy_option_category_label` (`categoryKey`,`normalizedLabel`),
  ADD KEY `profile_taxonomy_options_category_state_sort` (`categoryKey`,`isActive`,`sortOrder`);

--
-- Indexes for table `refreshtokens`
--
ALTER TABLE `refreshtokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `refresh_tokens_token_selector_unique` (`tokenSelector`),
  ADD KEY `userId` (`userId`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reports_duplicate_guard_lookup` (`reporterUserId`,`targetType`,`targetId`,`reason`,`createdAt`),
  ADD KEY `reports_reported_user_status` (`reportedUserId`,`status`);

--
-- Indexes for table `rosetransactions`
--
ALTER TABLE `rosetransactions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `rose_transactions_sender_idempotency_unique` (`senderId`,`idempotencyKey`),
  ADD KEY `conversationId` (`conversationId`),
  ADD KEY `rose_transactions_recipient_history` (`recipientId`,`createdAt`,`id`);

--
-- Indexes for table `savedprofiles`
--
ALTER TABLE `savedprofiles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `saved_profiles_user_target_unique` (`userId`,`savedUserId`),
  ADD KEY `savedUserId` (`savedUserId`),
  ADD KEY `saved_profiles_user_created` (`userId`,`createdAt`,`id`);

--
-- Indexes for table `sequelizemeta`
--
ALTER TABLE `sequelizemeta`
  ADD PRIMARY KEY (`name`);

--
-- Indexes for table `subscriptionplans`
--
ALTER TABLE `subscriptionplans`
  ADD PRIMARY KEY (`id`),
  ADD KEY `subscription_plans_catalog` (`active`,`sortOrder`,`id`);

--
-- Indexes for table `subscriptions`
--
ALTER TABLE `subscriptions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `subscriptions_user_unique` (`userId`),
  ADD UNIQUE KEY `subscriptions_provider_reference_unique` (`provider`,`providerSubscriptionId`),
  ADD KEY `planId` (`planId`),
  ADD KEY `subscriptions_entitlement_lookup` (`status`,`currentPeriodEnd`,`userId`);

--
-- Indexes for table `userdevices`
--
ALTER TABLE `userdevices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `pushToken` (`pushToken`),
  ADD KEY `user_devices_active_lookup` (`userId`,`active`,`lastSeenAt`),
  ADD KEY `user_devices_installation_lookup` (`userId`,`installationId`);

--
-- Indexes for table `userloginevents`
--
ALTER TABLE `userloginevents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_login_events_user_time` (`userId`,`occurredAt`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `googleId` (`googleId`),
  ADD KEY `users_account_status` (`accountStatus`,`id`),
  ADD KEY `users_last_active` (`lastActiveAt`,`id`),
  ADD KEY `users_identity_verified` (`identityVerifiedAt`,`id`);

--
-- Indexes for table `usertimelineevents`
--
ALTER TABLE `usertimelineevents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `administratorId` (`administratorId`),
  ADD KEY `user_timeline_events_user_time` (`userId`,`occurredAt`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accountdeletionconfirmations`
--
ALTER TABLE `accountdeletionconfirmations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `accountdeletionrequests`
--
ALTER TABLE `accountdeletionrequests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `adminauditlogs`
--
ALTER TABLE `adminauditlogs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `adminidempotencykeys`
--
ALTER TABLE `adminidempotencykeys`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `admininvitations`
--
ALTER TABLE `admininvitations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `administrators`
--
ALTER TABLE `administrators`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `adminmfachallenges`
--
ALTER TABLE `adminmfachallenges`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `adminmfacredentials`
--
ALTER TABLE `adminmfacredentials`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `adminmfarecoverycodes`
--
ALTER TABLE `adminmfarecoverycodes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `adminpasswordresettokens`
--
ALTER TABLE `adminpasswordresettokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `adminpermissions`
--
ALTER TABLE `adminpermissions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=412;

--
-- AUTO_INCREMENT for table `adminrefreshtokens`
--
ALTER TABLE `adminrefreshtokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `adminreportnotes`
--
ALTER TABLE `adminreportnotes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `adminroles`
--
ALTER TABLE `adminroles`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `adminusernotes`
--
ALTER TABLE `adminusernotes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `adminusernoteversions`
--
ALTER TABLE `adminusernoteversions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `blocks`
--
ALTER TABLE `blocks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=59;

--
-- AUTO_INCREMENT for table `conversationparticipants`
--
ALTER TABLE `conversationparticipants`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=672;

--
-- AUTO_INCREMENT for table `conversations`
--
ALTER TABLE `conversations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=332;

--
-- AUTO_INCREMENT for table `discoveractions`
--
ALTER TABLE `discoveractions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18211;

--
-- AUTO_INCREMENT for table `discoverfilterpreferences`
--
ALTER TABLE `discoverfilterpreferences`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1555;

--
-- AUTO_INCREMENT for table `eventregistrations`
--
ALTER TABLE `eventregistrations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `events`
--
ALTER TABLE `events`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `eventwaitlist`
--
ALTER TABLE `eventwaitlist`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `identityverificationdecisionevents`
--
ALTER TABLE `identityverificationdecisionevents`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `identityverificationreasons`
--
ALTER TABLE `identityverificationreasons`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `identityverifications`
--
ALTER TABLE `identityverifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `matches`
--
ALTER TABLE `matches`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=335;

--
-- AUTO_INCREMENT for table `matchingactionfailures`
--
ALTER TABLE `matchingactionfailures`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `messagemedia`
--
ALTER TABLE `messagemedia`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4175;

--
-- AUTO_INCREMENT for table `notificationdeliveries`
--
ALTER TABLE `notificationdeliveries`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notificationpreferences`
--
ALTER TABLE `notificationpreferences`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1553;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2660;

--
-- AUTO_INCREMENT for table `onboardingprofiles`
--
ALTER TABLE `onboardingprofiles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1584;

--
-- AUTO_INCREMENT for table `otptokens`
--
ALTER TABLE `otptokens`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT for table `paymentevents`
--
ALTER TABLE `paymentevents`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `refreshtokens`
--
ALTER TABLE `refreshtokens`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=140;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `rosetransactions`
--
ALTER TABLE `rosetransactions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=326;

--
-- AUTO_INCREMENT for table `savedprofiles`
--
ALTER TABLE `savedprofiles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4476;

--
-- AUTO_INCREMENT for table `subscriptions`
--
ALTER TABLE `subscriptions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=200;

--
-- AUTO_INCREMENT for table `userdevices`
--
ALTER TABLE `userdevices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `userloginevents`
--
ALTER TABLE `userloginevents`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1604;

--
-- AUTO_INCREMENT for table `usertimelineevents`
--
ALTER TABLE `usertimelineevents`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=171;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `accountdeletionconfirmations`
--
ALTER TABLE `accountdeletionconfirmations`
  ADD CONSTRAINT `accountdeletionconfirmations_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `accountdeletionrequests`
--
ALTER TABLE `accountdeletionrequests`
  ADD CONSTRAINT `accountdeletionrequests_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `adminauditlogs`
--
ALTER TABLE `adminauditlogs`
  ADD CONSTRAINT `adminauditlogs_ibfk_1` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `admindiscoverfilterfields`
--
ALTER TABLE `admindiscoverfilterfields`
  ADD CONSTRAINT `admindiscoverfilterfields_ibfk_1` FOREIGN KEY (`updatedByAdministratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `admindiscoversettings`
--
ALTER TABLE `admindiscoversettings`
  ADD CONSTRAINT `admindiscoversettings_ibfk_1` FOREIGN KEY (`updatedByAdministratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `adminidempotencykeys`
--
ALTER TABLE `adminidempotencykeys`
  ADD CONSTRAINT `adminidempotencykeys_ibfk_1` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `admininvitations`
--
ALTER TABLE `admininvitations`
  ADD CONSTRAINT `admininvitations_ibfk_1` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `admininvitations_ibfk_2` FOREIGN KEY (`invitedByAdministratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `administratorroles`
--
ALTER TABLE `administratorroles`
  ADD CONSTRAINT `administratorroles_ibfk_1` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `administratorroles_ibfk_2` FOREIGN KEY (`roleId`) REFERENCES `adminroles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `administrators`
--
ALTER TABLE `administrators`
  ADD CONSTRAINT `Administrators_suspendedByAdministratorId_foreign_idx` FOREIGN KEY (`suspendedByAdministratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `administrators_created_by_fk` FOREIGN KEY (`createdByAdministratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `adminmfachallenges`
--
ALTER TABLE `adminmfachallenges`
  ADD CONSTRAINT `adminmfachallenges_ibfk_1` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `adminmfacredentials`
--
ALTER TABLE `adminmfacredentials`
  ADD CONSTRAINT `adminmfacredentials_ibfk_1` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `adminmfarecoverycodes`
--
ALTER TABLE `adminmfarecoverycodes`
  ADD CONSTRAINT `adminmfarecoverycodes_ibfk_1` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `adminpasswordresettokens`
--
ALTER TABLE `adminpasswordresettokens`
  ADD CONSTRAINT `adminpasswordresettokens_ibfk_1` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `adminrefreshtokens`
--
ALTER TABLE `adminrefreshtokens`
  ADD CONSTRAINT `AdminRefreshTokens_replacedByTokenId_foreign_idx` FOREIGN KEY (`replacedByTokenId`) REFERENCES `adminrefreshtokens` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `adminrefreshtokens_ibfk_1` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `adminreportcases`
--
ALTER TABLE `adminreportcases`
  ADD CONSTRAINT `adminreportcases_ibfk_1` FOREIGN KEY (`reportId`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `adminreportcases_ibfk_2` FOREIGN KEY (`assignedAdministratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `adminreportcases_ibfk_3` FOREIGN KEY (`resolvedByAdministratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `adminreportnotes`
--
ALTER TABLE `adminreportnotes`
  ADD CONSTRAINT `adminreportnotes_ibfk_1` FOREIGN KEY (`reportId`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `adminreportnotes_ibfk_2` FOREIGN KEY (`authorAdministratorId`) REFERENCES `administrators` (`id`);

--
-- Constraints for table `adminrolepermissions`
--
ALTER TABLE `adminrolepermissions`
  ADD CONSTRAINT `adminrolepermissions_ibfk_1` FOREIGN KEY (`roleId`) REFERENCES `adminroles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `adminrolepermissions_ibfk_2` FOREIGN KEY (`permissionId`) REFERENCES `adminpermissions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `adminusernotes`
--
ALTER TABLE `adminusernotes`
  ADD CONSTRAINT `adminusernotes_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `adminusernotes_ibfk_2` FOREIGN KEY (`authorAdministratorId`) REFERENCES `administrators` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `adminusernotes_ibfk_3` FOREIGN KEY (`deletedByAdministratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `adminusernoteversions`
--
ALTER TABLE `adminusernoteversions`
  ADD CONSTRAINT `adminusernoteversions_ibfk_1` FOREIGN KEY (`noteId`) REFERENCES `adminusernotes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `adminusernoteversions_ibfk_2` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `blocks`
--
ALTER TABLE `blocks`
  ADD CONSTRAINT `blocks_ibfk_1` FOREIGN KEY (`blockerUserId`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `blocks_ibfk_2` FOREIGN KEY (`blockedUserId`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `conversationparticipants`
--
ALTER TABLE `conversationparticipants`
  ADD CONSTRAINT `conversation_participants_conversation_fk` FOREIGN KEY (`conversationId`) REFERENCES `conversations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `conversation_participants_last_read_message_fk` FOREIGN KEY (`lastReadMessageId`) REFERENCES `messages` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `conversation_participants_user_fk` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `conversations`
--
ALTER TABLE `conversations`
  ADD CONSTRAINT `conversations_last_message_fk` FOREIGN KEY (`lastMessageId`) REFERENCES `messages` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `discoveractions`
--
ALTER TABLE `discoveractions`
  ADD CONSTRAINT `discoveractions_ibfk_1` FOREIGN KEY (`actorUserId`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `discoveractions_ibfk_2` FOREIGN KEY (`targetUserId`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `discoverfilterpreferences`
--
ALTER TABLE `discoverfilterpreferences`
  ADD CONSTRAINT `discoverfilterpreferences_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `eventregistrations`
--
ALTER TABLE `eventregistrations`
  ADD CONSTRAINT `eventregistrations_ibfk_1` FOREIGN KEY (`eventId`) REFERENCES `events` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `eventregistrations_ibfk_2` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `events`
--
ALTER TABLE `events`
  ADD CONSTRAINT `events_ibfk_1` FOREIGN KEY (`organizerId`) REFERENCES `users` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `events_ibfk_2` FOREIGN KEY (`organizerId`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `eventwaitlist`
--
ALTER TABLE `eventwaitlist`
  ADD CONSTRAINT `eventwaitlist_ibfk_1` FOREIGN KEY (`eventId`) REFERENCES `events` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `eventwaitlist_ibfk_2` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `identityverificationdecisionevents`
--
ALTER TABLE `identityverificationdecisionevents`
  ADD CONSTRAINT `identityverificationdecisionevents_ibfk_1` FOREIGN KEY (`verificationId`) REFERENCES `identityverifications` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `identityverificationdecisionevents_ibfk_2` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `identityverificationdecisionevents_ibfk_3` FOREIGN KEY (`reasonId`) REFERENCES `identityverificationreasons` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `identityverifications`
--
ALTER TABLE `identityverifications`
  ADD CONSTRAINT `IdentityVerifications_reviewerAdministratorId_foreign_idx` FOREIGN KEY (`reviewerAdministratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `identityverifications_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `matches`
--
ALTER TABLE `matches`
  ADD CONSTRAINT `matches_ibfk_1` FOREIGN KEY (`userOneId`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `matches_ibfk_2` FOREIGN KEY (`userTwoId`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `matchingactionfailures`
--
ALTER TABLE `matchingactionfailures`
  ADD CONSTRAINT `matchingactionfailures_ibfk_1` FOREIGN KEY (`actorUserId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `matchingactionfailures_ibfk_2` FOREIGN KEY (`targetUserId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `messagemedia`
--
ALTER TABLE `messagemedia`
  ADD CONSTRAINT `message_media_message_fk` FOREIGN KEY (`messageId`) REFERENCES `messages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_conversation_fk` FOREIGN KEY (`conversationId`) REFERENCES `conversations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `messages_sender_fk` FOREIGN KEY (`senderId`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `notificationdeliveries`
--
ALTER TABLE `notificationdeliveries`
  ADD CONSTRAINT `notificationdeliveries_ibfk_1` FOREIGN KEY (`notificationId`) REFERENCES `notifications` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `notificationdeliveries_ibfk_2` FOREIGN KEY (`userDeviceId`) REFERENCES `userdevices` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `notificationpreferences`
--
ALTER TABLE `notificationpreferences`
  ADD CONSTRAINT `notificationpreferences_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `Notifications_actorUserId_foreign_idx` FOREIGN KEY (`actorUserId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `onboardingprofiles`
--
ALTER TABLE `onboardingprofiles`
  ADD CONSTRAINT `onboardingprofiles_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `paymentevents`
--
ALTER TABLE `paymentevents`
  ADD CONSTRAINT `paymentevents_ibfk_1` FOREIGN KEY (`paymentId`) REFERENCES `payments` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`planId`) REFERENCES `subscriptionplans` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `platformsettings`
--
ALTER TABLE `platformsettings`
  ADD CONSTRAINT `platformsettings_ibfk_1` FOREIGN KEY (`updatedByAdministratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `profiletaxonomyoptions`
--
ALTER TABLE `profiletaxonomyoptions`
  ADD CONSTRAINT `profiletaxonomyoptions_ibfk_1` FOREIGN KEY (`categoryKey`) REFERENCES `profiletaxonomycategories` (`key`) ON UPDATE CASCADE;

--
-- Constraints for table `refreshtokens`
--
ALTER TABLE `refreshtokens`
  ADD CONSTRAINT `refreshtokens_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`reporterUserId`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `reports_ibfk_2` FOREIGN KEY (`reportedUserId`) REFERENCES `users` (`id`);

--
-- Constraints for table `rosetransactions`
--
ALTER TABLE `rosetransactions`
  ADD CONSTRAINT `rosetransactions_ibfk_1` FOREIGN KEY (`senderId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rosetransactions_ibfk_2` FOREIGN KEY (`recipientId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rosetransactions_ibfk_3` FOREIGN KEY (`conversationId`) REFERENCES `conversations` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `savedprofiles`
--
ALTER TABLE `savedprofiles`
  ADD CONSTRAINT `savedprofiles_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `savedprofiles_ibfk_2` FOREIGN KEY (`savedUserId`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `subscriptions`
--
ALTER TABLE `subscriptions`
  ADD CONSTRAINT `subscriptions_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `subscriptions_ibfk_2` FOREIGN KEY (`planId`) REFERENCES `subscriptionplans` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `userdevices`
--
ALTER TABLE `userdevices`
  ADD CONSTRAINT `userdevices_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `userloginevents`
--
ALTER TABLE `userloginevents`
  ADD CONSTRAINT `userloginevents_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `usertimelineevents`
--
ALTER TABLE `usertimelineevents`
  ADD CONSTRAINT `usertimelineevents_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `usertimelineevents_ibfk_2` FOREIGN KEY (`administratorId`) REFERENCES `administrators` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
