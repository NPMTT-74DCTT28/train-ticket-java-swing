package com.group3tt28.quanlybanvetau.controller.nghiepvu;

import com.group3tt28.quanlybanvetau.dao.GheDAO;
import com.group3tt28.quanlybanvetau.dao.KhachHangDAO;
import com.group3tt28.quanlybanvetau.dao.LichTrinhDAO;
import com.group3tt28.quanlybanvetau.dao.VeTauDAO;
import com.group3tt28.quanlybanvetau.model.*;
import com.group3tt28.quanlybanvetau.util.SessionManager;
import com.group3tt28.quanlybanvetau.view.nghiepvu.QLVeTauPanel;

import javax.swing.table.DefaultTableModel;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.util.HashMap;
import java.util.List;

public class QLVeTauController {
    private final QLVeTauPanel panel;
    private final VeTauDAO dao;
    private final DefaultTableModel model;
    private final NhanVien currentuser;
    private int selectedRow = -1;
    private HashMap<Integer, String> mapKhachHang = new HashMap<>();

    public QLVeTauController(QLVeTauPanel panel) {
        this.dao = new VeTauDAO();
        this.panel = panel;
        KhachHangDAO khachHangDAO = new KhachHangDAO();
        LichTrinhDAO lichTrinhDAO = new LichTrinhDAO();
        GheDAO gheDAO = new GheDAO();
        currentuser = SessionManager.getCurrentUser();
        this.panel.setFieldNhanVien(currentuser.getId());
        System.out.println(currentuser.getId());

        panel.addThemVeTauListener(new ThemVeTauListener());
        panel.addSuaVeTauListener(new SuaVeTauListener());
        panel.addXoaVeTauListener(new XoaVeTauListener());
        panel.addResetFormListener(new ResetFormListener());
        panel.addTableMouseClickListener(new TableMouseClickListener());

        model = (DefaultTableModel) panel.getTable().getModel();

        List<KhachHang> dskh = khachHangDAO.getAll();
        this.panel.setComboKhachHangData(dskh);

        List<LichTrinh> dslt = lichTrinhDAO.getAll();
        this.panel.setComboLichTrinhData(dslt);

        List<Ghe> dsg = gheDAO.getAll();
        this.panel.setComboGheData(dsg);

        refresh();
    }

    private void refresh() {
        panel.resetForm();
        selectedRow = -1;
        try {
            KhachHangDAO khachHangDAO = new KhachHangDAO();
            List<KhachHang> listkh = khachHangDAO.getAll();

            mapKhachHang.clear();
            for (KhachHang khachHang : listkh) {
                mapKhachHang.put(khachHang.getId(), khachHang.getCccd() + " - " + khachHang.getHoTen());
            }

            panel.setComboKhachHangData(listkh);

            List<VeTau> listVeTau = dao.getAll();
            model.setRowCount(0);
            for (VeTau veTau : listVeTau) {
                String tenKhachHang = mapKhachHang.getOrDefault(veTau.getIdKhachHang(), String.valueOf(veTau.getIdKhachHang()));
                model.addRow(new Object[]{
                        veTau.getId(),
                        veTau.getMaVe(),
                        tenKhachHang,
                        veTau.getIdLichTrinh(),
                        veTau.getIdGhe(),
                        veTau.getIdNhanVien(),
                        veTau.getNgayDat() != null ? veTau.getNgayDat().toString() : "",
                        veTau.getGiaVe(),
                        veTau.getTrangThaiVe()
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        model.fireTableDataChanged();
    }

    private String validateInput(VeTau veTau, boolean isEditMode) {
        if (veTau.getMaVe().isEmpty()) {
            return "Vui lòng nhập mã vé!";
        }

        if (veTau.getIdKhachHang() < 1) {
            return "ID Khách hàng không hợp lệ!";
        }

        if (veTau.getIdLichTrinh() < 1) {
            return "ID Lịch trình không hợp lệ!";
        }

        if (veTau.getIdGhe() < 1) {
            return "ID Ghế không hợp lệ!";
        }

        if (veTau.getIdNhanVien() < 1) {
            return "ID Nhân viên không hợp lệ!";
        }

        if (veTau.getGiaVe() <= 0) {
            return "Giá vé phải lớn hơn 0!";
        }

        if (veTau.getTrangThaiVe() == null || veTau.getTrangThaiVe().isEmpty()) {
            return "Vui lòng nhập Trạng thái!";
        }

        return null;
    }

    private class ThemVeTauListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent e) {
            try {

                VeTau veTau = panel.getVeTauFromForm();
                veTau.setId(0);

                if (dao.checkTrung(veTau.getMaVe(), veTau.getIdLichTrinh(), veTau.getIdGhe(), veTau.getId())) {
                    panel.showWarning("Mã vé này đã tồn tại trên hệ thống!");
                    return;
                }

                if (dao.isGheDaDat(veTau.getIdLichTrinh(), veTau.getIdGhe(), null)) {
                    panel.showWarning("Ghế này đã có người đặt trên lịch trình đã chọn!");
                    return;
                }

                if (dao.insert(veTau)) {
                    panel.showMessage("Thêm vé thành công!");
                    refresh();
                } else {
                    panel.showError("Thêm thất bại! Vui lòng kiểm tra lại");
                }

            } catch (Exception ex) {
                ex.printStackTrace();
                panel.showError("Lỗi hệ thống: " + ex.getMessage());
            }
        }
    }

    private class SuaVeTauListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent e) {
            try {
                if (selectedRow == -1) {
                    panel.showWarning("Vui lòng chọn vé tàu để sửa!");
                    return;
                }

                VeTau veTau = panel.getVeTauFromForm();
                String error = validateInput(veTau, true);
                if (error != null) {
                    panel.showWarning(error);
                    return;
                }
                veTau.setId(Integer.parseInt(model.getValueAt(selectedRow, 0).toString()));

                if (dao.isGheDaDat(veTau.getIdLichTrinh(), veTau.getIdGhe(), veTau.getMaVe())) {
                    panel.showWarning("Không thể sửa! Ghế này đã được đặt bởi một vé khác.");
                    return;
                }

                if (panel.showConfirm("Bạn có muốn cập nhật thông tin vé " + veTau.getMaVe() + "?")) {
                    if (dao.update(veTau)) {
                        panel.showMessage("Cập nhật thành công!");
                        refresh();
                    } else {
                        panel.showError("Cập nhật thất bại! Vui lòng kiểm tra lại!");
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
                panel.showError("Lỗi hệ thống: " + ex.getMessage());
            }
        }
    }

    private class XoaVeTauListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent e) {
            try {
                if (selectedRow == -1) {
                    panel.showWarning("Vui lòng chọn vé tàu để xóa!");
                    return;
                }


                int ID = Integer.parseInt(model.getValueAt(selectedRow, 0).toString());
                String maVe = model.getValueAt(selectedRow, 1).toString();
                if (panel.showConfirm("Bạn có chắc chắn muốn xóa vé " + maVe + "?")) {
                    if (dao.delete(ID)) {
                        panel.showMessage("Xóa thành công!");
                        refresh();
                    } else {
                        panel.showError("Xóa thất bại! Vui lòng kiểm tra lại");
                    }
                }
            } catch (Exception ex) {
                ex.printStackTrace();
                panel.showError("Lỗi hệ thống: " + ex.getMessage());
            }
        }
    }

    private class ResetFormListener implements ActionListener {
        @Override
        public void actionPerformed(ActionEvent e) {
            panel.resetForm();
            selectedRow = -1;
            panel.setFieldNhanVien(currentuser.getId());
        }
    }

    private class TableMouseClickListener implements MouseListener {
        @Override
        public void mouseClicked(MouseEvent e) {
            panel.startEditMode();

            selectedRow = panel.getTable().getSelectedRow();
            if (selectedRow == -1) {
                return;
            }

            List<VeTau> listVeTau = dao.getAll();
            VeTau selectedVe = listVeTau.get(selectedRow);

            panel.setMaVe((model.getValueAt(selectedRow, 1).toString()));
            panel.setSelectedKhachHangId((selectedVe.getIdKhachHang()));
            panel.setSelectedLichTrinhId((Integer.parseInt(model.getValueAt(selectedRow, 3).toString())));
            panel.setSelectedGheId((Integer.parseInt(model.getValueAt(selectedRow, 4).toString())));
            panel.setFieldNhanVien((Integer.parseInt(model.getValueAt(selectedRow, 5).toString())));

            panel.setGiaVe(Double.parseDouble(model.getValueAt(selectedRow, 7).toString()));
            panel.setTrangThai(model.getValueAt(selectedRow, 8).toString());
        }

        @Override
        public void mousePressed(MouseEvent e) {
        }

        @Override
        public void mouseReleased(MouseEvent e) {
        }

        @Override
        public void mouseEntered(MouseEvent e) {
        }

        @Override
        public void mouseExited(MouseEvent e) {
        }
    }


}
