class Student {
  String firstName;
  bool isPresent;
  String lastName;
  String studentId;

  Student({
    required this.firstName,
    required this.isPresent,
    required this.lastName,
    required this.studentId,
  });

  // A method to convert the Student object to a Map
  Map<String, dynamic> toMap() {
    return {
      'first_name': firstName,
      'is_present': isPresent,
      'last_name': lastName,
      'student_id': studentId,
    };
  }

  // A method to create a Student object from a Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      firstName: map['first_name'],
      isPresent: map['is_present'],
      lastName: map['last_name'],
      studentId: map['student_id'],
    );
  }
}
