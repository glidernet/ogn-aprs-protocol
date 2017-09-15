-- phpMyAdmin SQL Dump
-- version 4.5.4.1deb2ubuntu2
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Sep 04, 2017 at 12:40 AM
-- Server version: 5.7.19-0ubuntu0.16.04.1
-- PHP Version: 7.0.22-0ubuntu0.16.04.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `OGNDDB`
--

-- --------------------------------------------------------

--
-- Table structure for table `aircrafts`
--

CREATE TABLE `aircrafts` (
  `ac_id` smallint(5) UNSIGNED NOT NULL,
  `ac_type` varchar(32) CHARACTER SET utf32 COLLATE utf32_unicode_ci NOT NULL,
  `ac_cat` tinyint(3) UNSIGNED NOT NULL DEFAULT '1'
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='List of Aircraft types';

--
-- Dumping data for table `aircrafts`
--

INSERT INTO `aircrafts` (`ac_id`, `ac_type`, `ac_cat`) VALUES
(1, 'UFO', 1);

-- --------------------------------------------------------

--
-- Table structure for table `devices`
--

CREATE TABLE `devices` (
  `dev_id` varchar(36) COLLATE utf8_unicode_ci NOT NULL COMMENT 'The userid sent by the device',
  `dev_type` tinyint(2) NOT NULL DEFAULT '2' COMMENT 'link with the devicetype table',
  `dev_passwd` varchar(16) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Password in case that the device require password to retrive info',
  `dev_plane` int(7) NOT NULL COMMENT 'Link to the planes table, identifying the plane carrying this device',
  `dev_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '0-1 if the device is active or not'
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='Table with all the devices';

-- --------------------------------------------------------

--
-- Table structure for table `devtypes`
--

CREATE TABLE `devtypes` (
  `devt_id` tinyint(2) NOT NULL,
  `devt_name` varchar(9) NOT NULL DEFAULT 'FLARM'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='All posible device types';

--
-- Dumping data for table `devtypes`
--

INSERT INTO `devtypes` (`devt_id`, `devt_name`) VALUES
(11, 'ADSB'),
(8, 'CAPTURS'),
(9, 'FANET'),
(2, 'FLARM'),
(1, 'FLARMICAO'),
(6, 'LT24'),
(12, 'MAVLINK'),
(3, 'OGNT'),
(10, 'PILOTAWAR'),
(7, 'SKYLINES'),
(5, 'SPIDER'),
(4, 'SPOT');

-- --------------------------------------------------------

--
-- Table structure for table `planes`
--

CREATE TABLE `planes` (
  `pln_id` int(7) UNSIGNED NOT NULL COMMENT 'The unique identifier of the plane',
  `pln_reg` varchar(7) NOT NULL COMMENT 'The official registration in the country',
  `pln_accn` varchar(3) NOT NULL COMMENT 'The competition ID',
  `pln_actype` smallint(5) NOT NULL COMMENT 'Link to the aircraft type table',
  `pln_userid` mediumint(8) NOT NULL COMMENT 'Link with the userid table',
  `pln_notrack` tinyint(1) NOT NULL COMMENT '0-1 if the user do not want to be tracked',
  `pln_noident` tinyint(1) NOT NULL COMMENT '0-1 if the user do not want to show the identification',
  `pln_owner` varchar(64) DEFAULT NULL COMMENT 'Non mandatory field with the name of the owner',
  `pln_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT '0-1 if the plane is active or not',
  `pln_multidvces` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Flag to indicate that this plane has registered several devices'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='List of all the planes using the OGN';

-- --------------------------------------------------------

--
-- Table structure for table `tmpusers`
--

CREATE TABLE `tmpusers` (
  `tusr_adress` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `tusr_pw` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  `tusr_validation` varchar(128) CHARACTER SET utf16 COLLATE utf16_unicode_ci NOT NULL,
  `tusr_time` bigint(20) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `usr_id` mediumint(8) UNSIGNED NOT NULL,
  `usr_adress` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `usr_pw` varchar(128) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='All treh registered users';

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`usr_id`, `usr_adress`, `usr_pw`) VALUES
(1, 'acasadoalonso@gmail.com', 'Gl6ttU9WXRqaw'),
(2, 'acasado@acm.org', 'Gl6ttU9WXRqaw');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `aircrafts`
--
ALTER TABLE `aircrafts`
  ADD PRIMARY KEY (`ac_id`),
  ADD UNIQUE KEY `ac_id` (`ac_id`);

--
-- Indexes for table `devices`
--
ALTER TABLE `devices`
  ADD PRIMARY KEY (`dev_id`),
  ADD UNIQUE KEY `dev_id` (`dev_id`);

--
-- Indexes for table `devtypes`
--
ALTER TABLE `devtypes`
  ADD PRIMARY KEY (`devt_id`),
  ADD UNIQUE KEY `devt_id` (`devt_id`),
  ADD UNIQUE KEY `devt_name` (`devt_name`);

--
-- Indexes for table `planes`
--
ALTER TABLE `planes`
  ADD PRIMARY KEY (`pln_id`),
  ADD UNIQUE KEY `pln_id` (`pln_id`),
  ADD KEY `pln_userid` (`pln_userid`),
  ADD KEY `pln_reg` (`pln_reg`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`usr_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `aircrafts`
--
ALTER TABLE `aircrafts`
  MODIFY `ac_id` smallint(5) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `planes`
--
ALTER TABLE `planes`
  MODIFY `pln_id` int(7) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'The unique identifier of the plane';
--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `usr_id` mediumint(8) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
