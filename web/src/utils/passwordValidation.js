/**
 * Shared password validation rules and helpers.
 * Used by both the PasswordStrength component and Register form.
 */

export const PASSWORD_RULES = [
  {
    id: 'length',
    label: 'At least 8 characters',
    test: (p) => p.length >= 8,
  },
  {
    id: 'uppercase',
    label: 'One uppercase letter',
    test: (p) => /[A-Z]/.test(p),
  },
  {
    id: 'lowercase',
    label: 'One lowercase letter',
    test: (p) => /[a-z]/.test(p),
  },
  {
    id: 'number',
    label: 'One number',
    test: (p) => /[0-9]/.test(p),
  },
  {
    id: 'special',
    label: 'One special character (e.g. @, #, $, !)',
    test: (p) => /[@#$!%&*^()_+=\-{}[\]|\\:;"'<>,.?/~`]/.test(p),
  },
];

/**
 * Returns 'weak' | 'medium' | 'strong' based on how many rules pass.
 */
export function getPasswordStrength(password) {
  const passed = PASSWORD_RULES.filter((r) => r.test(password)).length;
  if (passed <= 2) return 'weak';
  if (passed <= 4) return 'medium';
  return 'strong';
}

/**
 * Returns true only when all 5 rules are satisfied.
 */
export function isPasswordValid(password) {
  return PASSWORD_RULES.every((r) => r.test(password));
}

/**
 * Returns an error string for inline field validation, or '' when valid.
 */
export function getPasswordError(password) {
  if (!password) return 'Password is required';
  if (!isPasswordValid(password)) return 'Password does not meet all requirements';
  return '';
}

