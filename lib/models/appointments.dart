class Appointment {
  final int? id;
  final String name;
  final int age;
  final String sex;
  final String animalType;
  final String date;
  final String time;
  final String? status;
  final int? userId;
  final String? phoneNumber; // Changed to match Laravel 'phone_number'
  final String purpose; // Added because Laravel requires 'purpose'

  Appointment({
    this.id,
    required this.name,
    required this.age,
    required this.sex,
    required this.animalType,
    required this.date,
    required this.time,
    this.status,
    this.userId,
    this.phoneNumber,
    required this.purpose, // Added to constructor
  });

  // Factory constructor to read from Laravel JSON
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      name: json['name'] ?? 'N/A',
      age: json['age'] ?? 0,
      sex: json['sex'] ?? 'N/A',
      animalType: json['animal_type'] ?? 'N/A',
      date: json['date'] ?? 'N/A',
      time: json['time'] ?? 'N/A',
      status: json['status'] ?? 'Pending',
      userId: json['user_id'],
      // MATCHES LARAVEL CONTROLLER OUTPUT
      phoneNumber: json['phone_number'],
      purpose: json['purpose'] ?? 'Check-up',
    );
  }

  // Method to send data to Laravel
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'sex': sex,
      // MATCHES LARAVEL VALIDATION RULES
      'animal_type': animalType,
      'date': date,
      'time': time,
      'status': status,
      'user_id': userId,
      'phone_number': phoneNumber, // Sends 'phone_number'
      'purpose': purpose, // Sends 'purpose'
    };
  }
}
