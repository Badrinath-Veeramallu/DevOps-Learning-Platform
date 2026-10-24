import { useRef, useEffect } from "react";

/**
 * 21st.dev inspired 6-Digit OTP / PIN Input
 * Features:
 * - Auto-advances focus on digit entry
 * - Backspace moves focus backward
 * - Left/Right arrow key navigation
 * - Full 6-digit clipboard paste handling
 * - Accessible inputMode="numeric", pattern="[0-9]*"
 * - Keyboard accessible with clear focus ring
 */
export const OtpInput = ({
  value = "",
  onChange,
  disabled = false,
  hasError = false,
  autoFocus = true,
}) => {
  const inputRefs = useRef([]);

  // Ensure digits array is always 6 elements
  const digits = Array.from({ length: 6 }, (_, i) => value[i] || "");

  useEffect(() => {
    if (autoFocus && inputRefs.current[0] && !disabled) {
      inputRefs.current[0].focus();
    }
  }, [autoFocus, disabled]);

  const handleChange = (e, index) => {
    const rawVal = e.target.value;
    // Extract only digits
    const cleanDigit = rawVal.replace(/\D/g, "");

    if (!cleanDigit) {
      // Deletion
      const newDigits = [...digits];
      newDigits[index] = "";
      onChange(newDigits.join(""));
      return;
    }

    if (cleanDigit.length > 1) {
      // In case multiple digits typed quickly
      handlePastedCode(cleanDigit, index);
      return;
    }

    const newDigits = [...digits];
    newDigits[index] = cleanDigit.charAt(cleanDigit.length - 1);
    onChange(newDigits.join(""));

    // Advance focus to next input
    if (index < 5 && inputRefs.current[index + 1]) {
      inputRefs.current[index + 1].focus();
    }
  };

  const handleKeyDown = (e, index) => {
    if (e.key === "Backspace") {
      if (!digits[index] && index > 0 && inputRefs.current[index - 1]) {
        // Current slot is empty, backspace moves focus to previous slot
        inputRefs.current[index - 1].focus();
      }
    } else if (e.key === "ArrowLeft" && index > 0) {
      e.preventDefault();
      inputRefs.current[index - 1]?.focus();
    } else if (e.key === "ArrowRight" && index < 5) {
      e.preventDefault();
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handlePaste = (e) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData("text").trim();
    handlePastedCode(pastedData, 0);
  };

  const handlePastedCode = (code, startIndex = 0) => {
    const onlyDigits = code.replace(/\D/g, "");
    if (!onlyDigits) return;

    const newDigits = [...digits];
    for (let i = 0; i < onlyDigits.length && startIndex + i < 6; i++) {
      newDigits[startIndex + i] = onlyDigits[i];
    }
    onChange(newDigits.join(""));

    // Focus slot after last pasted digit
    const nextFocusIndex = Math.min(5, startIndex + onlyDigits.length);
    inputRefs.current[nextFocusIndex]?.focus();
  };

  return (
    <div
      className={`otp-container ${hasError ? "otp-container-error" : ""}`}
      onPaste={handlePaste}
      role="group"
      aria-label="6-digit verification code"
    >
      {digits.map((digit, idx) => (
        <input
          key={idx}
          ref={(el) => (inputRefs.current[idx] = el)}
          type="text"
          inputMode="numeric"
          autoComplete={idx === 0 ? "one-time-code" : "off"}
          pattern="[0-9]*"
          maxLength={1}
          value={digit}
          disabled={disabled}
          onChange={(e) => handleChange(e, idx)}
          onKeyDown={(e) => handleKeyDown(e, idx)}
          onFocus={(e) => e.target.select()}
          className={`otp-slot ${digit ? "otp-slot-filled" : ""}`}
          aria-label={`Digit ${idx + 1} of 6`}
        />
      ))}
    </div>
  );
};

export default OtpInput;
