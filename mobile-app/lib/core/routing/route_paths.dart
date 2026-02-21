class RoutePaths {
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const settings = '/settings';

  // Admin
  static const adminUsers = '/admin/users';
  static const adminOrders = '/admin/orders';
  static const adminReports = '/admin/reports';
  static const adminDealers = '/admin/dealers';
  static const adminEmployees = '/admin/employees';

  // Manager
  static const managerAssignOrders = '/manager/assign-orders';
  static const managerReports = '/manager/reports';
  static const managerTeam = '/manager/team';

  // Operator
  static const operatorAssignedOrders = '/operator/assigned-orders';
  static const operatorUpdateStatus = '/operator/update-status';
  static const operatorUploadPhotos = '/operator/upload-photos';

  // Sales
  static const salesCreateOrder = '/sales/create-order';
  static const salesCustomerOrders = '/sales/customer-orders';
  static const salesReport = '/sales/report';

  // HR
  static const hrEmployees = '/hr/employees';
  static const hrAttendance = '/hr/attendance';
  static const hrSalary = '/hr/salary';

  // Dealer
  static const dealerNewOrder = '/dealer/new-order';
  static const dealerTrackOrders = '/dealer/track-orders';
  static const dealerPayments = '/dealer/payments';
}
