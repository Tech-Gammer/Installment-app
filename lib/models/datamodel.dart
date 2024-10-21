class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String cnic;
  final String role;
  final String userNumber;  // Changed from int to String

  UserModel(this.uid, this.name, this.email, this.phone, this.password, this.cnic, this.role, this.userNumber);

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'cnic': cnic,
      'role': role,
      'userNumber': userNumber,  // Storing as String
    };
  }
}

class AdminModel {
  final String adminId;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String cnic;
  final String role;
  final String adminNumber;  // Changed from int to String

  AdminModel(this.adminId, this.name, this.email, this.phone, this.password, this.cnic, this.role, this.adminNumber);

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'cnic': cnic,
      'role': role,
      'adminNumber': adminNumber,  // Storing as String
    };
  }
}
