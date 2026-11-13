import { PASSWORD_RULES, getPasswordStrength } from '../utils/passwordValidation';

const CheckIcon = () => (
  <svg
    width="13"
    height="13"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2.5"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
  >
    <polyline points="20 6 9 17 4 12" />
  </svg>
);

const CircleIcon = () => (
  <svg
    width="13"
    height="13"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
  >
    <circle cx="12" cy="12" r="9" />
  </svg>
);

const STRENGTH_META = {
  weak:   { label: 'Weak',   filledSegments: 1 },
  medium: { label: 'Medium', filledSegments: 2 },
  strong: { label: 'Strong', filledSegments: 3 },
};

/**
 * Live password strength panel.
 * Renders only when password has at least one character.
 *
 * Props:
 *   password {string} — the current raw password value
 */
export const PasswordStrength = ({ password }) => {
  if (!password) return null;

  const strength = getPasswordStrength(password);
  const { label, filledSegments } = STRENGTH_META[strength];

  return (
    <div className="pw-strength-panel" aria-live="polite">
      {/* Criteria list */}
      <ul className="pw-rule-list" aria-label="Password requirements">
        {PASSWORD_RULES.map((rule) => {
          const met = rule.test(password);
          return (
            <li key={rule.id} className={`pw-rule-item ${met ? 'met' : 'unmet'}`}>
              {met ? <CheckIcon /> : <CircleIcon />}
              <span>{rule.label}</span>
            </li>
          );
        })}
      </ul>

      {/* Strength bar */}
      <div className="pw-strength-bar-row">
        <div className="pw-strength-bar" aria-hidden="true">
          {[1, 2, 3].map((seg) => (
            <div
              key={seg}
              className={`pw-strength-segment ${seg <= filledSegments ? `strength-${strength}` : 'strength-empty'}`}
            />
          ))}
        </div>
        <span className={`pw-strength-label strength-label-${strength}`}>{label}</span>
      </div>
    </div>
  );
};

export default PasswordStrength;

