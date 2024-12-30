class Student {
  String firstName;
  String lastName;
  String studentId;
  String yearLevel;

  Student(
      {required this.firstName,
      required this.lastName,
      required this.studentId,
      required this.yearLevel});

  // A method to convert the Student object to a Map
  Map<String, dynamic> toMap() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'student_id': studentId,
      'year_level': yearLevel
    };
  }

  // A method to create a Student object from a Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
        firstName: map['first_name'],
        lastName: map['last_name'],
        studentId: map['student_id'],
        yearLevel: map['year_level']);
  }
}
