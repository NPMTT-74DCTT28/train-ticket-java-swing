# **Desktop app Hệ thống quản lý bán vé tàu (Java Swing)**

- [Giới thiệu](#giới-thiệu)
- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Hướng dẫn cài đặt](#hướng-dẫn-cài-đặt)
- [Tổng kết](#tổng-kết)

## **Giới thiệu**

**HỌC PHẦN LẬP TRÌNH JAVA NÂNG CAO**

**Nhóm 3 - Lớp 74DCTT28 - Trường Đại học Công nghệ Giao thông Vận tải**

  ```
  Hoàng Quốc Phương
  Nguyễn Văn Tuấn
  Nguyễn Phúc Thanh
  Hoàng Trọng Nguyên
  Phạm Quang Minh
  ```

## **Yêu cầu hệ thống**

- [Java 8](https://www.java.com/en/download/)
- [JDK 25](https://www.oracle.com/java/technologies/downloads/#jdk25-windows)
- [IntelliJ IDEA](https://www.jetbrains.com/idea/download/?section=windows)
- [XAMPP 8.2.12](https://www.apachefriends.org/download.html)

## **Hướng dẫn cài đặt**

Hệ thống được xây dựng và thử nghiệm dựa trên toàn bộ các phần phụ thuộc trong [yêu cầu hệ thống](#yêu-cầu-hệ-thống).

Hướng dẫn chi tiết:

- Clone project này về máy tính cá nhân.

- Khởi chạy Apache và MySQL trong XAMPP, truy cập `phpmyadmin` bằng trình duyệt bất kỳ, sau đó import file [
  `quan_ly_ban_ve_tau.sql`](./sql/quan_ly_ban_ve_tau.sql) để nhập cơ sở dữ liệu `quan_ly_ban_ve_tau`. Bạn có thể đổi tên
  database sau khi import thành công (Lưu ý: Bạn có thể tắt kiểm tra khoá ngoại khi import để không bị báo lỗi xung đột
  khoá ngoại - do sai thứ tự tạo bảng vì file sql này xuất ra từ MySQL, thứ tự tạo bảng sắp xếp theo alphabet).

- Mở project bằng `IntelliJ IDEA`, cấu hình `JDK 25` làm JDK của project (JDK cũ hơn có thể không tương thích).

- Trong thư mục [`resources/`](./src/main/resources):
    + Tạo một bản sao của `db.properties.example`, sau đó đổi tên file thành `db.properties`.
    + Thay đổi thông tin kết nối cơ sở dữ liệu của bạn trong file `db.properties` (URL, tài khoản, mật khẩu MySQL) nếu
      cần. Lưu ý, không dùng dấu nháy, chỉ cần điền thông tin là được.

- Khởi chạy:
    + Khi mở project lần đầu, tại phần run project trong IntelliJ IDEA (phía trên cùng), chọn file cấu hình run project
      là `QuanLyBanVeTau`.
    + File cấu hình này nằm trong thư mục [`.run/`](.run/QuanLyBanVeTau.run.xml).
    + Run project, đăng nhập bằng mã nhân viên bất kỳ nằm trong bảng `nhan_vien` với mật khẩu mặc định `123456`.
    + Tài khoản quản trị viên sẽ được sử dụng toàn bộ chức năng, nhân viên chỉ được dùng một số chức năng quản lý, tra
      cứu nhất định.

Chú ý: Không thêm thủ công plain text vào cột `mat_khau` trong bảng (vì check mật khẩu sẽ luôn sai). Nếu muốn cấp tài
khoản mới/cập nhật mật khẩu, sử dụng chức năng thêm nhân viên/đổi mật khẩu hoặc truy cập
[BCrypt Generator](https://bcrypt-generator.com/) để tạo mã băm (12 rounds) và thêm thủ công vào cột `mat_khau`.

## **Tổng kết**

Ứng dụng về cơ bản đã hoàn thiện đầy đủ các chức năng cơ bản, tuy nhiên, do giới hạn về thời gian cũng như phạm vi kiến
thức, nhóm nhận thấy vẫn còn một số hạn chế cần khắc phục:

```
  • Giao diện người dùng (UI – User Interface) của Java Swing tuy đầy đủ chức năng nhưng chưa thực sự hiện đại và bắt mắt như các ứng dụng Web/Mobile.
  • Chưa tích hợp được hệ thống thanh toán trực tuyến (Momo, VNPAY, ATM, v.v) mà chủ yếu vẫn chỉ là mô phỏng thanh toán tiền mặt.
  • Chưa có chức năng đặt vé online cho khách hàng (Client-side) mà hiện tại chỉ phục vụ cho nhân viên bán vé tại quầy (Admin-side).
  • Chưa tích hợp được tính năng xuất vé ra file PDF, xuất Excel cho các hạng mục thống kê, v.v.
  • Chưa có tính năng lấy lại mật khẩu thông qua email/số điện nếu quên mật khẩu; các email, số điện thoại vẫn chỉ là email và số điện thoại ảo, chưa có phương thức xác thực.
  • Chưa hoàn toàn tối ưu về cách tổ chức code, chưa vận dụng triệt để các Design Pattern (mẫu thiết kế) - Singleton (độc bản), Observer cho các class, v.v.
```

Với nền tảng kiến trúc CSDL và Backend đã xây dựng, nhóm đề xuất các hướng nâng cấp như sau:

```
  • Bổ sung các tính năng cần thiết như xuất vé, xuất Excel, v.v.
  • Chuyển đổi lên nền tảng Web: Sử dụng Spring Boot để viết API và xây dựng giao diện Web (ReactJS/VueJS) để khách hàng có thể đặt vé từ xa.
  • Sử dụng JavaMail API để tích hợp tính năng lấy lại mật khẩu đã quên thông qua mã OTP được gửi về mail.
  • Tích hợp AI: Ứng dụng các thuật toán học máy để dự báo nhu cầu đi lại, từ đó gợi ý điều chỉnh giá vé linh hoạt (Dynamic Pricing) theo giờ cao điểm.
  • Mở rộng thanh toán: Tích hợp cổng thanh toán điện tử và quét mã QR trên vé.
```
