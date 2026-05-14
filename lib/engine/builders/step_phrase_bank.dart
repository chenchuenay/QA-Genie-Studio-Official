import 'package:qa_genie/core/utils/stable_hash.dart';

class StepPhraseBank {
  final String _seedPrefix;

  StepPhraseBank(this._seedPrefix);

  static const _openActions = ['Open', 'Navigate to', 'Launch', 'Access', 'Browse to'];
  static const _submitActions = ['Click Login', 'Tap Sign In', 'Submit the form', 'Press Continue'];
  static const _validationActions = ['Verify validation message', 'Observe error feedback', 'Check inline validation'];

  String randomOpen(String key) => _openActions[StableHash.forText('$_seedPrefix-open-$key', _openActions.length)];
  String randomSubmit(String key) => _submitActions[StableHash.forText('$_seedPrefix-submit-$key', _submitActions.length)];
  String randomValidation(String key) => _validationActions[StableHash.forText('$_seedPrefix-validate-$key', _validationActions.length)];
}
