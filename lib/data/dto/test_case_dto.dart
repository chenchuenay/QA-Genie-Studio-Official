class TestCaseDto {
  final String id, title, module, feature, priority, expectedResult;
  final List<Map<String,dynamic>> steps;
  final List<String> preconditions;
  TestCaseDto.fromJson(Map<String,dynamic> json):
    id=json['id']??'', title=json['title']??'', module=json['module']??'', feature=json['feature']??'', priority=json['priority']??'Medium',
    steps=List<Map<String,dynamic>>.from(json['steps']??[]), expectedResult=json['expectedResult']??'', preconditions=List<String>.from(json['preconditions']??[]);
}
