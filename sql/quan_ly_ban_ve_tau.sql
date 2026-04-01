-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Máy chủ: 127.0.0.1
-- Thời gian đã tạo: Th4 01, 2026 lúc 10:36 AM
-- Phiên bản máy phục vụ: 10.4.32-MariaDB
-- Phiên bản PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `quan_ly_ban_ve_tau`
--
CREATE DATABASE IF NOT EXISTS `quan_ly_ban_ve_tau` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `quan_ly_ban_ve_tau`;

DELIMITER $$
--
-- Thủ tục
--
DROP PROCEDURE IF EXISTS `sp_DoanhThuBayNgay`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_DoanhThuBayNgay` ()   BEGIN
    SELECT
        DATE(ngay_dat) AS ngay,
        COALESCE(SUM(gia_ve), 0) AS doanh_thu
    FROM ve_tau
    WHERE (CURDATE() - DATE(ngay_dat) BETWEEN 0 AND 7) AND trang_thai = 'Đã thanh toán'
    GROUP BY DATE(ngay_dat)
    ORDER BY ngay ASC;
END$$

DROP PROCEDURE IF EXISTS `sp_ThongKeDoanhSo`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ThongKeDoanhSo` (IN `p_thang` INT, IN `p_nam` INT)   BEGIN
    SELECT 
        nv.ma_nhan_vien,
        nv.ho_ten,
        COUNT(vt.id) as so_ve_ban,
        COALESCE(SUM(vt.gia_ve), 0) as doanh_so
    FROM nhan_vien nv
    LEFT JOIN ve_tau vt ON nv.id = vt.id_nhan_vien 
        AND MONTH(vt.ngay_dat) = p_thang 
        AND YEAR(vt.ngay_dat) = p_nam
        AND vt.trang_thai = 'Đã thanh toán'
    WHERE nv.vai_tro = 'Nhân viên'
    GROUP BY nv.id
    ORDER BY doanh_so DESC;
END$$

DROP PROCEDURE IF EXISTS `sp_ThongKeDoanhThuTheoNgay`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ThongKeDoanhThuTheoNgay` (IN `p_ngay_bat_dau` DATE, IN `p_ngay_ket_thuc` DATE)   BEGIN
SELECT
    DATE(ngay_dat) as ngay, COALESCE(SUM(gia_ve), 0) as doanh_thu, COUNT(id) as so_ve_ban
FROM ve_tau
WHERE DATE(ngay_dat) BETWEEN '2025-01-01'
  AND '2025-12-31'
  AND trang_thai = 'Đã thanh toán'
GROUP BY DATE(ngay_dat)
ORDER BY ngay ASC;
END$$

DROP PROCEDURE IF EXISTS `sp_ThongKeDoanhThuTheoTuyen`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ThongKeDoanhThuTheoTuyen` (IN `p_ngay_bat_dau` DATE, IN `p_ngay_ket_thuc` DATE)   BEGIN
SELECT td.ten_tuyen,
       COALESCE(SUM(vt.gia_ve), 0) as doanh_thu
FROM ve_tau vt
         JOIN lich_trinh lt ON vt.id_lich_trinh = lt.id
         JOIN tuyen_duong td ON lt.id_tuyen_duong = td.id
WHERE DATE (vt.ngay_dat) BETWEEN p_ngay_bat_dau
  AND p_ngay_ket_thuc
  AND vt.trang_thai = 'Đã thanh toán'
GROUP BY td.ten_tuyen
ORDER BY doanh_thu DESC;
END$$

DROP PROCEDURE IF EXISTS `sp_ThongKeKhachHangVIP`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ThongKeKhachHangVIP` (IN `p_limit` INT)   BEGIN
SELECT kh.ho_ten,
       kh.sdt,
       COUNT(vt.id)                as so_ve_da_mua,
       COALESCE(SUM(vt.gia_ve), 0) as tong_tien_chi_tieu
FROM khach_hang kh
         JOIN ve_tau vt ON kh.id = vt.id_khach_hang
WHERE vt.trang_thai = 'Đã thanh toán'
GROUP BY kh.id
ORDER BY tong_tien_chi_tieu DESC LIMIT p_limit;
END$$

DROP PROCEDURE IF EXISTS `sp_ThongKeTyLeLapDay`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ThongKeTyLeLapDay` (IN `p_ngay_bat_dau` DATE, IN `p_ngay_ket_thuc` DATE)   BEGIN
SELECT lt.ma_lich_trinh,
       t.ten_tau,
       lt.ngay_di,
       -- Đếm tổng số ghế của tàu (Dựa vào bảng ghe -> toa -> tau)
       (SELECT COUNT(g.id)
        FROM ghe g
                 JOIN toa_tau tt ON g.id_toa_tau = tt.id
        WHERE tt.id_tau = t.id)                                               AS tong_so_ghe,
       -- Đếm số vé đã bán (trừ vé hủy)
       COUNT(vt.id)                                                           as ve_da_ban,
       -- Tính phần trăm
       ROUND((COUNT(vt.id) * 100.0 / NULLIF((SELECT COUNT(g.id)
                                             FROM ghe g
                                                      JOIN toa_tau tt ON g.id_toa_tau = tt.id
                                             WHERE tt.id_tau = t.id), 0)), 2) as ty_le_lap_day
FROM lich_trinh lt
         JOIN tau t ON lt.id_tau = t.id
         LEFT JOIN ve_tau vt ON lt.id = vt.id_lich_trinh AND vt.trang_thai = 'Đã thanh toán'
WHERE DATE (lt.ngay_di) BETWEEN p_ngay_bat_dau AND p_ngay_ket_thuc
GROUP BY lt.id, t.id
ORDER BY ty_le_lap_day DESC;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `ga_tau`
--

DROP TABLE IF EXISTS `ga_tau`;
CREATE TABLE IF NOT EXISTS `ga_tau` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ma_ga` varchar(20) NOT NULL COMMENT 'VD: HN, DN, SG',
  `ten_ga` varchar(100) NOT NULL COMMENT 'VD: Ga Hà Nội',
  `dia_chi` varchar(255) DEFAULT NULL,
  `thanh_pho` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ma_ga` (`ma_ga`),
  UNIQUE KEY `ten_ga` (`ten_ga`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `ga_tau`
--

INSERT INTO `ga_tau` (`id`, `ma_ga`, `ten_ga`, `dia_chi`, `thanh_pho`) VALUES
(1, 'HN', 'Ga Hà Nội', '120 Lê Duẩn', 'Hà Nội'),
(2, 'DN', 'Ga Đà Nẵng', '202 Hải Phòng', 'Đà Nẵng'),
(3, 'SG', 'Ga Sài Gòn', '1 Nguyễn Thông', 'TP.HCM'),
(4, 'HUE', 'Ga Huế', '2 Bùi Thị Xuân', 'Huế'),
(5, 'NT', 'Ga Nha Trang', '17 Thái Nguyên', 'Khánh Hòa'),
(6, 'VINH', 'Ga Vinh', '1 Lệ Ninh', 'Nghệ An'),
(7, 'HP', 'Ga Hải Phòng', '75 Lương Khánh Thiện', 'Hải Phòng'),
(8, 'ND', 'Ga Nam Định', 'Trần Đăng Ninh', 'Nam Định'),
(9, 'TH', 'Ga Thanh Hóa', 'Dương Đình Nghệ', 'Thanh Hóa'),
(10, 'QN', 'Ga Quy Nhơn', 'Lê Hồng Phong', 'Bình Định');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `ghe`
--

DROP TABLE IF EXISTS `ghe`;
CREATE TABLE IF NOT EXISTS `ghe` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `so_ghe` varchar(10) NOT NULL COMMENT 'VD: A1, B2',
  `id_toa_tau` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_ghe_trong_toa` (`so_ghe`,`id_toa_tau`),
  KEY `id_toa_tau` (`id_toa_tau`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `ghe`
--

INSERT INTO `ghe` (`id`, `so_ghe`, `id_toa_tau`) VALUES
(1, 'A1', 1),
(13, 'A1', 4),
(2, 'A2', 1),
(14, 'A2', 4),
(3, 'B1', 1),
(15, 'B1', 4),
(4, 'B2', 1),
(16, 'B2', 4),
(5, 'C1', 2),
(17, 'C1', 5),
(6, 'C2', 2),
(18, 'C2', 5),
(7, 'C3', 2),
(19, 'C3', 5),
(8, 'C4', 2),
(20, 'C4', 5),
(9, 'D1', 3),
(21, 'D1', 6),
(10, 'D2', 3),
(22, 'D2', 6),
(11, 'D3', 3),
(23, 'D3', 6),
(12, 'D4', 3),
(24, 'D4', 6),
(25, 'G1', 7),
(26, 'G2', 7),
(27, 'G3', 7),
(28, 'G4', 7),
(29, 'H1', 8),
(30, 'H2', 8),
(31, 'H3', 8),
(32, 'H4', 8),
(33, 'K1', 9),
(34, 'K2', 9),
(35, 'K3', 9),
(36, 'K4', 9),
(37, 'L1', 10),
(38, 'L2', 10),
(39, 'L3', 10),
(40, 'L4', 10),
(41, 'M1', 11),
(42, 'M2', 11),
(43, 'M3', 11),
(44, 'M4', 11),
(45, 'N1', 12),
(46, 'N2', 12),
(47, 'N3', 12),
(48, 'N4', 12);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `khach_hang`
--

DROP TABLE IF EXISTS `khach_hang`;
CREATE TABLE IF NOT EXISTS `khach_hang` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cccd` varchar(20) DEFAULT NULL,
  `ho_ten` varchar(100) NOT NULL,
  `ngay_sinh` date DEFAULT curdate(),
  `gioi_tinh` varchar(20) NOT NULL,
  `sdt` varchar(20) NOT NULL,
  `dia_chi` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sdt` (`sdt`),
  UNIQUE KEY `cccd` (`cccd`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `khach_hang`
--

INSERT INTO `khach_hang` (`id`, `cccd`, `ho_ten`, `ngay_sinh`, `gioi_tinh`, `sdt`, `dia_chi`) VALUES
(1, '001090000001', 'Phạm Văn Minh', '1990-05-12', 'Nam', '0912111222', 'Số 5, Ngõ 1, Quan Hoa, Hà Nội'),
(2, '001090000002', 'Nguyễn Thị Hương', '1992-08-22', 'Nữ', '0912333444', 'P12, Quận 4, TP.HCM'),
(3, '001090000003', 'Lê Thanh Sơn', '1985-03-15', 'Nam', '0912555666', 'Hải Châu, Đà Nẵng'),
(4, '001090000004', 'Trần Bảo Ngọc', '1998-11-04', 'Nữ', '0912777888', 'TP. Huế, Thừa Thiên Huế'),
(5, '001090000005', 'Hoàng Văn Đức', '2000-02-28', 'Nam', '0912999000', 'Lê Chân, Hải Phòng'),
(6, '001090000006', 'Vũ Thị Lan', '1975-06-18', 'Nữ', '0913111222', 'Nha Trang, Khánh Hòa'),
(7, '001090000007', 'Đặng Quốc Khánh', '1968-09-09', 'Nam', '0913333444', 'TP. Vinh, Nghệ An'),
(8, '001090000008', 'Bùi Văn Hùng', '1991-12-25', 'Nam', '0913555666', 'TP. Nam Định'),
(9, '001090000009', 'Đỗ Thị Mai', '1993-07-14', 'Nữ', '0913777888', 'TP. Thanh Hóa'),
(10, '001090000010', 'Hồ Văn Cường', '1999-10-10', 'Nam', '0913999000', 'Quy Nhơn, Bình Định'),
(11, '001090000011', 'Ngô Thu Trang', '2002-04-30', 'Nữ', '0914111222', 'Hoàng Mai, Hà Nội'),
(12, '001090000012', 'Dương Văn Long', '1980-01-01', 'Nam', '0914333444', 'Bình Thạnh, TP.HCM'),
(13, '001090000013', 'Lý Thị Hồng', '1965-08-15', 'Nữ', '0914555666', 'Sơn Trà, Đà Nẵng'),
(14, '001090000014', 'Vương Quốc Tuấn', '1996-05-20', 'Nam', '0914777888', 'Hương Thủy, Huế'),
(15, '001090000015', 'Trịnh Thị Kim Anh', '1994-11-20', 'Nữ', '0914999000', 'Cam Ranh, Khánh Hòa'),
(16, '001090000016', 'Phan Hải Đăng', '1988-02-10', 'Nam', '0915111222', 'Ba Đình, Hà Nội'),
(17, '001090000017', 'Lưu Thị Mơ', '1995-11-11', 'Nữ', '0915333444', 'Quận 1, TP.HCM'),
(18, '001090000018', 'Trương Tấn Tài', '1990-09-09', 'Nam', '0915555666', 'Biên Hòa, Đồng Nai'),
(19, '001090000019', 'Đinh Ngọc Diệp', '2001-07-20', 'Nữ', '0915777888', 'Thanh Xuân, Hà Nội'),
(20, '001090000020', 'Tạ Văn Quang', '1983-05-05', 'Nam', '0915999000', 'Sơn Trà, Đà Nẵng');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `lich_trinh`
--

DROP TABLE IF EXISTS `lich_trinh`;
CREATE TABLE IF NOT EXISTS `lich_trinh` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ma_lich_trinh` varchar(20) DEFAULT NULL,
  `id_tau` int(11) NOT NULL,
  `id_tuyen_duong` int(11) NOT NULL,
  `ngay_di` datetime NOT NULL,
  `ngay_den` datetime NOT NULL,
  `trang_thai` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_tau_schedule` (`id_tau`,`ngay_di`),
  UNIQUE KEY `ma_lich_trinh` (`ma_lich_trinh`),
  KEY `id_tuyen_duong` (`id_tuyen_duong`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `lich_trinh`
--

INSERT INTO `lich_trinh` (`id`, `ma_lich_trinh`, `id_tau`, `id_tuyen_duong`, `ngay_di`, `ngay_den`, `trang_thai`) VALUES
(1, 'LT-TET-01', 1, 1, '2025-01-20 06:00:00', '2025-01-21 12:00:00', 'Hoàn thành'),
(2, 'LT-TET-02', 2, 2, '2025-01-21 08:00:00', '2025-01-22 14:00:00', 'Hoàn thành'),
(3, 'LT-TET-03', 1, 3, '2025-01-25 10:00:00', '2025-01-25 22:00:00', 'Hoàn thành'),
(4, 'LT-MAR-01', 3, 6, '2025-03-10 07:00:00', '2025-03-10 14:00:00', 'Hoàn thành'),
(5, 'LT-APR-01', 5, 5, '2025-04-29 20:00:00', '2025-04-30 05:00:00', 'Hoàn thành'),
(6, 'LT-APR-02', 6, 6, '2025-04-30 06:00:00', '2025-04-30 12:00:00', 'Hoàn thành'),
(7, 'LT-MAY-01', 1, 1, '2025-05-01 06:00:00', '2025-05-02 12:00:00', 'Hoàn thành'),
(8, 'LT-JUN-01', 2, 8, '2025-06-15 08:00:00', '2025-06-15 20:00:00', 'Hoàn thành'),
(9, 'LT-JUN-02', 2, 8, '2025-06-20 08:00:00', '2025-06-20 20:00:00', 'Chờ'),
(10, 'LT-DEC-01', 1, 1, '2025-12-25 06:00:00', '2025-12-26 12:00:00', 'Chờ'),
(11, 'LT-JUN-05', 5, 3, '2025-06-25 06:00:00', '2025-06-25 18:00:00', 'Hoàn thành'),
(12, 'LT-JUL-01', 6, 5, '2025-07-01 20:00:00', '2025-07-02 05:00:00', 'Hoàn thành'),
(13, 'LT-JUL-05', 2, 8, '2025-07-05 08:00:00', '2025-07-05 20:00:00', 'Hoàn thành');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `loai_toa`
--

DROP TABLE IF EXISTS `loai_toa`;
CREATE TABLE IF NOT EXISTS `loai_toa` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ten_loai` varchar(50) NOT NULL COMMENT 'VD: Ngồi mềm điều hòa, Giường nằm',
  `he_so_gia` decimal(3,2) DEFAULT 1.00,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ten_loai` (`ten_loai`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `loai_toa`
--

INSERT INTO `loai_toa` (`id`, `ten_loai`, `he_so_gia`) VALUES
(1, 'Ngồi cứng', 1.00),
(2, 'Ngồi mềm điều hòa', 1.20),
(3, 'Giường nằm khoang 6', 1.50),
(4, 'Giường nằm khoang 4', 1.80);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `nhan_vien`
--

DROP TABLE IF EXISTS `nhan_vien`;
CREATE TABLE IF NOT EXISTS `nhan_vien` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ma_nhan_vien` varchar(20) NOT NULL,
  `mat_khau` varchar(255) NOT NULL,
  `ho_ten` varchar(100) NOT NULL,
  `ngay_sinh` date NOT NULL DEFAULT curdate(),
  `gioi_tinh` varchar(20) NOT NULL,
  `sdt` varchar(20) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `dia_chi` varchar(255) NOT NULL,
  `vai_tro` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ma_nhan_vien` (`ma_nhan_vien`),
  UNIQUE KEY `sdt` (`sdt`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `nhan_vien`
--

INSERT INTO `nhan_vien` (`id`, `ma_nhan_vien`, `mat_khau`, `ho_ten`, `ngay_sinh`, `gioi_tinh`, `sdt`, `email`, `dia_chi`, `vai_tro`) VALUES
(1, 'ADMIN01', '$2a$12$gmkjs/CePmv8B6L684vWD.ytns6H4aoo4EXuFcVMAfWD1iV586QzW', 'Nguyễn Quốc Hưng', '1980-05-15', 'Nam', '0909123456', 'hung.nguyen@tauhoa.vn', 'Số 10, Đội Cấn, Ba Đình, Hà Nội', 'Quản trị viên'),
(2, 'ADMIN02', '$2a$12$JriS6Fh3iYVWC2APBzOmju8X9/6V/z6TTjWSi9w2QS3h0f037.wL6', 'Trần Thị Thanh Tâm', '1985-08-20', 'Nữ', '0909234567', 'tam.tran@tauhoa.vn', '15 Lê Lợi, Hải Châu, Đà Nẵng', 'Quản trị viên'),
(3, 'ADMIN03', '$2a$12$2nMQzv/tJzBU804t5tJ3MOj.EWhAGynFs7vuDT5KNgNENxz1yWMXu', 'Lê Văn Tuân', '1990-12-10', 'Nam', '0909345678', 'tuan.le@tauhoa.vn', '120 Nguyễn Thị Minh Khai, Q3, TP.HCM', 'Quản trị viên'),
(4, 'ADMIN04', '$2a$12$bEKMSlItzcpnDzDyqxx5G.uvj4vxAQnpwE2i.mQAAccOPA2iZ6k7a', 'Phạm Minh Hoàng', '1982-03-25', 'Nam', '0909456789', 'hoang.pham@tauhoa.vn', 'TP. Thủ Đức, TP.HCM', 'Quản trị viên'),
(5, 'ADMIN05', '$2a$12$n3oI8f3gurpnlkS1KhAZcu98h7If0B0m7NRAPVDHo10BvIGrj5qHa', 'Hoàng Thu Thảo', '1995-06-30', 'Nữ', '0909567890', 'thao.hoang@tauhoa.vn', 'Cầu Giấy, Hà Nội', 'Quản trị viên'),
(6, 'NV01', '$2a$12$WS1mox8/ujPzoAsNGQ8S5OfsBt1FqG6TrqMQABvnx2vIiYEbcoto6', 'Vũ Thị Thu Ngân', '1998-04-26', 'Nữ', '0909678901', 'ngan.vu@tauhoa.vn', 'Thanh Khê, Đà Nẵng', 'Nhân viên'),
(7, 'NV02', '$2a$12$RQ1t6qizqBDzPokkJxpfLucu2i6M0SEjcP5UNiNlonXRWG1geAaNy', 'Ngô Xuân Bách', '1993-09-15', 'Nam', '0909789012', 'bach.ngo@tauhoa.vn', 'Gò Vấp, TP.HCM', 'Nhân viên'),
(8, 'NV03', '$2a$12$u1h7j1s6ATb8Du0STcvZk.8VuA7KSMqeQzUWbnR2NdR34Jz.kKqhO', 'Đặng Tuyết Mai', '2000-01-20', 'Nữ', '0909890123', 'mai.dang@tauhoa.vn', 'Long Biên, Hà Nội', 'Nhân viên'),
(9, 'NV04', '$2a$12$P5B4Z/I5UzrsG85YT9y8vutqhU3AI.leimQYQFa99tCAMrYMWezZ6', 'Bùi Minh Tú', '2001-11-27', 'Nam', '0909901234', 'tu.bui@tauhoa.vn', 'TP. Vinh, Nghệ An', 'Nhân viên');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `tau`
--

DROP TABLE IF EXISTS `tau`;
CREATE TABLE IF NOT EXISTS `tau` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ma_tau` varchar(20) NOT NULL COMMENT 'VD: SE1, TN1',
  `ten_tau` varchar(100) NOT NULL COMMENT 'VD: Tàu Thống Nhất SE1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ma_tau` (`ma_tau`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `tau`
--

INSERT INTO `tau` (`id`, `ma_tau`, `ten_tau`) VALUES
(1, 'SE1', 'Thống Nhất SE1 (Nhanh)'),
(2, 'SE2', 'Thống Nhất SE2 (Nhanh)'),
(3, 'TN1', 'Thống Nhất TN1 (Thường)'),
(4, 'TN2', 'Thống Nhất TN2 (Thường)'),
(5, 'QB1', 'Quảng Bình Express'),
(6, 'NA1', 'Nghệ An Train'),
(7, 'SPT1', 'Phan Thiết Express'),
(8, 'SE3', 'Thống Nhất SE3'),
(9, 'SE4', 'Thống Nhất SE4');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `toa_tau`
--

DROP TABLE IF EXISTS `toa_tau`;
CREATE TABLE IF NOT EXISTS `toa_tau` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ma_toa` varchar(20) NOT NULL COMMENT 'VD: Toa 1, Toa 2',
  `id_tau` int(11) NOT NULL,
  `id_loai_toa` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_toa_trong_tau` (`ma_toa`,`id_tau`),
  KEY `id_tau` (`id_tau`),
  KEY `id_loai_toa` (`id_loai_toa`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `toa_tau`
--

INSERT INTO `toa_tau` (`id`, `ma_toa`, `id_tau`, `id_loai_toa`) VALUES
(1, 'Toa 1', 1, 2),
(2, 'Toa 2', 1, 3),
(3, 'Toa 3', 1, 4),
(4, 'Toa 1', 2, 2),
(5, 'Toa 2', 2, 3),
(6, 'Toa 3', 2, 4),
(7, 'Toa 1', 3, 1),
(8, 'Toa 2', 3, 2),
(9, 'Toa 1', 5, 2),
(10, 'Toa 2', 5, 3),
(11, 'Toa 1', 6, 1),
(12, 'Toa 2', 6, 2);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `tuyen_duong`
--

DROP TABLE IF EXISTS `tuyen_duong`;
CREATE TABLE IF NOT EXISTS `tuyen_duong` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ma_tuyen` varchar(20) NOT NULL COMMENT 'VD: HN-SG',
  `ten_tuyen` varchar(100) NOT NULL,
  `id_ga_di` int(11) NOT NULL,
  `id_ga_den` int(11) NOT NULL,
  `khoang_cach_km` int(11) DEFAULT NULL,
  `gia_co_ban` decimal(10,2) NOT NULL COMMENT 'Giá gốc chưa nhân hệ số',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ma_tuyen` (`ma_tuyen`),
  UNIQUE KEY `unique_route` (`id_ga_di`,`id_ga_den`),
  KEY `id_ga_den` (`id_ga_den`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `tuyen_duong`
--

INSERT INTO `tuyen_duong` (`id`, `ma_tuyen`, `ten_tuyen`, `id_ga_di`, `id_ga_den`, `khoang_cach_km`, `gia_co_ban`) VALUES
(1, 'HN-SG', 'Hà Nội - Sài Gòn', 1, 3, 1726, 1000000.00),
(2, 'SG-HN', 'Sài Gòn - Hà Nội', 3, 1, 1726, 1000000.00),
(3, 'HN-DN', 'Hà Nội - Đà Nẵng', 1, 2, 791, 500000.00),
(4, 'DN-HN', 'Đà Nẵng - Hà Nội', 2, 1, 791, 500000.00),
(5, 'SG-NT', 'Sài Gòn - Nha Trang', 3, 5, 411, 300000.00),
(6, 'HN-VINH', 'Hà Nội - Vinh', 1, 6, 319, 200000.00),
(7, 'HN-HP', 'Hà Nội - Hải Phòng', 1, 7, 102, 100000.00),
(8, 'SG-QN', 'Sài Gòn - Quy Nhơn', 3, 10, 600, 450000.00);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `ve_tau`
--

DROP TABLE IF EXISTS `ve_tau`;
CREATE TABLE IF NOT EXISTS `ve_tau` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ma_ve` varchar(20) NOT NULL,
  `id_khach_hang` int(11) NOT NULL,
  `id_lich_trinh` int(11) NOT NULL,
  `id_ghe` int(11) NOT NULL,
  `id_nhan_vien` int(11) DEFAULT NULL,
  `ngay_dat` datetime DEFAULT current_timestamp(),
  `gia_ve` decimal(10,2) NOT NULL,
  `trang_thai` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ma_ve` (`ma_ve`),
  UNIQUE KEY `unique_booking` (`id_lich_trinh`,`id_ghe`),
  KEY `id_khach_hang` (`id_khach_hang`),
  KEY `id_ghe` (`id_ghe`),
  KEY `id_nhan_vien` (`id_nhan_vien`)
) ENGINE=InnoDB AUTO_INCREMENT=52 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `ve_tau`
--

INSERT INTO `ve_tau` (`id`, `ma_ve`, `id_khach_hang`, `id_lich_trinh`, `id_ghe`, `id_nhan_vien`, `ngay_dat`, `gia_ve`, `trang_thai`) VALUES
(1, 'VE-01-01', 1, 1, 1, 6, '2025-01-10 08:00:00', 1200000.00, 'Đã thanh toán'),
(2, 'VE-01-02', 2, 1, 2, 6, '2025-01-10 08:05:00', 1200000.00, 'Đã thanh toán'),
(3, 'VE-01-03', 3, 1, 5, 7, '2025-01-11 09:00:00', 1500000.00, 'Đã thanh toán'),
(4, 'VE-01-04', 4, 1, 6, 7, '2025-01-11 09:10:00', 1500000.00, 'Đã thanh toán'),
(5, 'VE-01-05', 5, 1, 9, 6, '2025-01-12 10:00:00', 1800000.00, 'Đã thanh toán'),
(6, 'VE-01-06', 6, 1, 10, 6, '2025-01-12 10:15:00', 1800000.00, 'Đã thanh toán'),
(7, 'VE-01-07', 7, 2, 13, 8, '2025-01-15 08:00:00', 1200000.00, 'Đã thanh toán'),
(8, 'VE-01-08', 8, 2, 14, 8, '2025-01-15 08:30:00', 1200000.00, 'Đã thanh toán'),
(9, 'VE-01-09', 9, 2, 17, 9, '2025-01-16 09:00:00', 1500000.00, 'Đã thanh toán'),
(10, 'VE-01-10', 10, 2, 21, 9, '2025-01-16 09:30:00', 1800000.00, 'Đã thanh toán'),
(11, 'VE-01-11', 11, 3, 1, 6, '2025-01-20 10:00:00', 600000.00, 'Đã thanh toán'),
(12, 'VE-01-12', 12, 3, 2, 6, '2025-01-20 10:05:00', 600000.00, 'Đã thanh toán'),
(13, 'VE-03-01', 13, 4, 25, 7, '2025-03-01 08:00:00', 200000.00, 'Đã thanh toán'),
(14, 'VE-03-02', 14, 4, 26, 7, '2025-03-01 08:00:00', 200000.00, 'Đã thanh toán'),
(15, 'VE-03-03', 15, 4, 27, 7, '2025-03-02 09:00:00', 200000.00, 'Đã hủy'),
(16, 'VE-04-01', 1, 5, 33, 6, '2025-04-10 10:00:00', 360000.00, 'Đã thanh toán'),
(17, 'VE-04-02', 2, 5, 34, 6, '2025-04-10 10:00:00', 360000.00, 'Đã thanh toán'),
(18, 'VE-04-03', 3, 5, 37, 8, '2025-04-12 14:00:00', 450000.00, 'Đã thanh toán'),
(19, 'VE-04-04', 4, 5, 38, 8, '2025-04-12 14:00:00', 450000.00, 'Đã thanh toán'),
(20, 'VE-04-05', 5, 6, 41, 9, '2025-04-20 08:00:00', 200000.00, 'Đã thanh toán'),
(21, 'VE-04-06', 6, 6, 42, 9, '2025-04-20 08:00:00', 200000.00, 'Đã thanh toán'),
(22, 'VE-04-07', 7, 6, 45, 9, '2025-04-21 09:00:00', 240000.00, 'Đã thanh toán'),
(23, 'VE-05-01', 8, 7, 1, 6, '2025-04-25 10:00:00', 1200000.00, 'Đã thanh toán'),
(24, 'VE-05-02', 9, 7, 5, 6, '2025-04-25 10:00:00', 1500000.00, 'Đã thanh toán'),
(25, 'VE-06-01', 10, 8, 13, 7, '2025-06-01 08:00:00', 540000.00, 'Đã thanh toán'),
(26, 'VE-06-02', 11, 8, 14, 7, '2025-06-01 08:00:00', 540000.00, 'Đã thanh toán'),
(27, 'VE-06-03', 12, 8, 17, 7, '2025-06-02 09:00:00', 675000.00, 'Đã thanh toán'),
(28, 'VE-06-04', 13, 8, 21, 7, '2025-06-02 09:00:00', 810000.00, 'Đã thanh toán'),
(29, 'VE-06-05', 14, 9, 13, 8, '2025-06-10 10:00:00', 540000.00, 'Đã thanh toán'),
(30, 'VE-06-06', 15, 9, 14, 8, '2025-06-10 10:00:00', 540000.00, 'Đã thanh toán'),
(31, 'VE-12-01', 1, 10, 1, 6, '2025-12-01 08:00:00', 1200000.00, 'Đã thanh toán'),
(32, 'VE-06-10', 16, 9, 15, 8, '2025-06-12 08:00:00', 540000.00, 'Đã thanh toán'),
(33, 'VE-06-11', 16, 9, 16, 8, '2025-06-12 08:00:00', 540000.00, 'Đã thanh toán'),
(34, 'VE-06-12', 17, 9, 18, 8, '2025-06-13 09:30:00', 675000.00, 'Đã thanh toán'),
(35, 'VE-06-13', 18, 9, 19, 8, '2025-06-13 10:00:00', 675000.00, 'Đã thanh toán'),
(36, 'VE-06-14', 19, 9, 20, 8, '2025-06-14 14:00:00', 675000.00, 'Đã thanh toán'),
(37, 'VE-06-20', 1, 11, 33, 9, '2025-06-20 08:00:00', 1500000.00, 'Đã thanh toán'),
(38, 'VE-06-21', 1, 11, 34, 9, '2025-06-20 08:00:00', 1500000.00, 'Đã thanh toán'),
(39, 'VE-06-22', 1, 11, 35, 9, '2025-06-20 08:00:00', 1500000.00, 'Đã thanh toán'),
(40, 'VE-06-23', 1, 11, 36, 9, '2025-06-20 08:00:00', 1500000.00, 'Đã thanh toán'),
(41, 'VE-07-01', 2, 12, 41, 6, '2025-06-28 10:00:00', 400000.00, 'Đã thanh toán'),
(42, 'VE-07-02', 3, 12, 42, 6, '2025-06-28 11:00:00', 400000.00, 'Đã thanh toán'),
(43, 'VE-07-03', 4, 12, 43, 7, '2025-06-29 09:00:00', 400000.00, 'Đã thanh toán'),
(44, 'VE-07-04', 5, 12, 44, 7, '2025-06-29 09:30:00', 400000.00, 'Đã thanh toán'),
(45, 'VE-07-05', 6, 12, 45, 8, '2025-06-30 08:00:00', 480000.00, 'Đã thanh toán'),
(46, 'VE-07-06', 7, 12, 46, 8, '2025-06-30 08:30:00', 480000.00, 'Đã thanh toán'),
(47, 'VE-07-07', 20, 12, 47, 9, '2025-06-30 15:00:00', 480000.00, 'Đã thanh toán'),
(48, 'VE-07-08', 19, 12, 48, 9, '2025-06-30 16:00:00', 480000.00, 'Đã thanh toán'),
(49, 'VE-07-20', 10, 13, 13, 7, '2025-07-01 08:00:00', 500000.00, 'Đã hủy'),
(50, 'VE-07-21', 11, 13, 14, 7, '2025-07-01 08:30:00', 500000.00, 'Đã hủy'),
(51, 'VE-07-22', 12, 13, 15, 7, '2025-07-02 09:00:00', 500000.00, 'Đã thanh toán');

--
-- Các ràng buộc cho các bảng đã đổ
--

--
-- Các ràng buộc cho bảng `ghe`
--
ALTER TABLE `ghe`
  ADD CONSTRAINT `ghe_ibfk_1` FOREIGN KEY (`id_toa_tau`) REFERENCES `toa_tau` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `lich_trinh`
--
ALTER TABLE `lich_trinh`
  ADD CONSTRAINT `lich_trinh_ibfk_1` FOREIGN KEY (`id_tau`) REFERENCES `tau` (`id`),
  ADD CONSTRAINT `lich_trinh_ibfk_2` FOREIGN KEY (`id_tuyen_duong`) REFERENCES `tuyen_duong` (`id`);

--
-- Các ràng buộc cho bảng `toa_tau`
--
ALTER TABLE `toa_tau`
  ADD CONSTRAINT `toa_tau_ibfk_1` FOREIGN KEY (`id_tau`) REFERENCES `tau` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `toa_tau_ibfk_2` FOREIGN KEY (`id_loai_toa`) REFERENCES `loai_toa` (`id`);

--
-- Các ràng buộc cho bảng `tuyen_duong`
--
ALTER TABLE `tuyen_duong`
  ADD CONSTRAINT `tuyen_duong_ibfk_1` FOREIGN KEY (`id_ga_di`) REFERENCES `ga_tau` (`id`),
  ADD CONSTRAINT `tuyen_duong_ibfk_2` FOREIGN KEY (`id_ga_den`) REFERENCES `ga_tau` (`id`);

--
-- Các ràng buộc cho bảng `ve_tau`
--
ALTER TABLE `ve_tau`
  ADD CONSTRAINT `ve_tau_ibfk_1` FOREIGN KEY (`id_khach_hang`) REFERENCES `khach_hang` (`id`),
  ADD CONSTRAINT `ve_tau_ibfk_2` FOREIGN KEY (`id_lich_trinh`) REFERENCES `lich_trinh` (`id`),
  ADD CONSTRAINT `ve_tau_ibfk_3` FOREIGN KEY (`id_ghe`) REFERENCES `ghe` (`id`),
  ADD CONSTRAINT `ve_tau_ibfk_4` FOREIGN KEY (`id_nhan_vien`) REFERENCES `nhan_vien` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
