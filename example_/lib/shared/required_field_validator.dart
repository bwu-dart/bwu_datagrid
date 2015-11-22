library bwu_datagrid_examples.shared.required_field_validator;

import 'package:bwu_datagrid/editors/editors.dart';

class RequiredFieldValidator {
  ValidationResult call(dynamic value) {
    if (value == null || (value is String && value.isEmpty)) {
      return new ValidationResult(false, 'This is a required field');
    } else {
      return new ValidationResult(true);
    }
  }
}
