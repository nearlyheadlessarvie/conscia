class PasswordPolicyRequirement {
  const PasswordPolicyRequirement({
    required this.message,
    required this.isSatisfied,
  });

  final String message;
  final bool Function(String value) isSatisfied;
}

final _numberPattern = RegExp(r'[0-9]');
final _lowercasePattern = RegExp(r'[a-z]');
final _uppercasePattern = RegExp(r'[A-Z]');

final cognitoPasswordRequirements = <PasswordPolicyRequirement>[
  PasswordPolicyRequirement(
    message: 'At least 8 characters',
    isSatisfied: (value) => value.length >= 8,
  ),
  PasswordPolicyRequirement(
    message: 'Include 1 number',
    isSatisfied: _numberPattern.hasMatch,
  ),
  PasswordPolicyRequirement(
    message: 'Include 1 lowercase letter',
    isSatisfied: _lowercasePattern.hasMatch,
  ),
  PasswordPolicyRequirement(
    message: 'Include 1 uppercase letter',
    isSatisfied: _uppercasePattern.hasMatch,
  ),
];

String? validatePasswordForCognito(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }

  for (final requirement in cognitoPasswordRequirements) {
    if (!requirement.isSatisfied(value)) {
      return requirement.message;
    }
  }

  return null;
}
