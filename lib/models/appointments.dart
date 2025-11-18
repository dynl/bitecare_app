// This model represents a single appointment.
// You might need to adjust field names based on your actual API response.
class Appointment {
  final int? id;
  final String name;
  final int age;
  final String sex;
  final String animalType;
  final String date;
  final String time;
  final String? status; // e.g., 'Pending', 'Confirmed', 'Cancelled'
  final int? userId; // If you want to link to a user

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
  });

  // Factory constructor to create an Appointment from a JSON map
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
    );
  }

  // Method to convert an Appointment object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'sex': sex,
      'animal_type': animalType,
      'date': date,
      'time': time,
      'status': status,
      'user_id': userId,
    };
  }
}
