class Programs {

  static String allProgram = "All Programs";

  static List<String> programs = [
    allProgram,
    'Computer Science',
    'Information Technology',
    'Accountancy',
    'Hospitality Management',
    'Computer Engineering',
    'Psychology',
    'Electrical Engineering',
    'Electronics Engineering',
    'Business Administration',
    'Criminology'
  ];

  static final Map<String, String> _programAlias = {
  allProgram: 'All',
  'Computer Science': 'BSCS',
  'Information Technology': 'BSIT',
  'Accountancy': 'BSA',
  'Hospitality Management': 'BSHM',
  'Computer Engineering': 'BSCpE',
  'Psychology': 'BSPsych',
  'Electrical Engineering': 'BSEE',
  'Electronics Engineering': 'BSECE',
  'Business Administration': 'BSBA',
  'Criminology': 'BSCrim'
  };

  static getProgramAlias(String program) {
    return _programAlias[program] ?? "Not Found" ;
  }

}