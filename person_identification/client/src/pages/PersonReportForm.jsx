// client/src/pages/PersonReportForm.jsx

import { useState, useEffect } from "react";
import { useVoiceTranscript } from "../hooks/useVoiceTranscript";

const AGE_RANGES = [
  "Unknown",
  "0-10 (Child)",
  "11-17 (Teenager)",
  "18-25 (Young Adult)",
  "26-35 (Adult)",
  "36-45 (Adult)",
  "46-55 (Middle-aged)",
  "56-65 (Middle-aged)",
  "66-75 (Senior)",
  "76-85 (Elderly)",
  "85+ (Elderly)",
];

const STEPS = [
  { id: 1, label: "Report Type" },
  { id: 2, label: "Person Details" },
  { id: 3, label: "Description" },
  { id: 4, label: "Location & Time" },
  { id: 5, label: "Your Info" },
];

export default function PersonReportForm() {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    reportType: "",
    emergencyLevel: "unknown",
    isInjured: false,
    isUnconscious: false,
    name: "",
    approximateAge: "Unknown",
    gender: "unknown",
    descriptionText: "",
    locationText: "",
    lat: "",
    lng: "",
    lastSeenAt: "",
    reporterName: "",
    reporterPhone: "",
  });
  const [photo, setPhoto] = useState(null);
  const [photoPreview, setPhotoPreview] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const {
    isListening,
    transcript,
    error: voiceError,
    startListening,
    stopListening,
    resetTranscript,
  } = useVoiceTranscript();

  useEffect(() => {
    if (transcript)
      setFormData((prev) => ({ ...prev, descriptionText: transcript }));
  }, [transcript]);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handlePhotoChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setPhoto(file);
      setPhotoPreview(URL.createObjectURL(file));
    }
  };

  const detectLocation = () => {
    if (!navigator.geolocation) {
      alert("GPS not supported in your browser.");
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) =>
        setFormData((prev) => ({
          ...prev,
          lat: pos.coords.latitude,
          lng: pos.coords.longitude,
        })),
      () => alert("Could not detect GPS. Please type location manually.")
    );
  };

  const nextStep = () => {
    if (step === 1 && !formData.reportType) {
      setError("Please select a report type.");
      return;
    }
    if (step === 3 && !formData.descriptionText.trim()) {
      setError("Please add a description.");
      return;
    }
    setError("");
    setStep((s) => s + 1);
  };

  const prevStep = () => {
    setError("");
    setStep((s) => s - 1);
  };

  const handleSubmit = async () => {
    if (!formData.reporterName || !formData.reporterPhone) {
      setError("Please enter your name and phone number.");
      return;
    }
    setLoading(true);
    setError("");
    const data = new FormData();
    Object.keys(formData).forEach((key) => data.append(key, formData[key]));
    if (photo) data.append("photo", photo);
    try {
      const res = await fetch("/api/person-reports", {
        method: "POST",
        body: data,
      });
      const result = await res.json();
      if (result.success) setSubmitted(true);
      else setError("Something went wrong. Please try again.");
    } catch {
      setError("Network error. Check your connection.");
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setSubmitted(false);
    setStep(1);
    setFormData({
      reportType: "", emergencyLevel: "unknown", isInjured: false,
      isUnconscious: false, name: "", approximateAge: "Unknown",
      gender: "unknown", descriptionText: "", locationText: "",
      lat: "", lng: "", lastSeenAt: "", reporterName: "", reporterPhone: "",
    });
    setPhoto(null);
    setPhotoPreview("");
    resetTranscript();
    setError("");
  };

  if (submitted) {
    return (
      <div style={s.successWrap}>
        <div style={s.successBox}>
          <div style={s.successIcon}>✅</div>
          <h2 style={s.successTitle}>Report Submitted</h2>
          <p style={s.successText}>
            Your report has been saved. Our AI is scanning for matches now.
          </p>
          <p style={s.successText}>
            If a match is found, we will contact you at{" "}
            <strong>{formData.reporterPhone}</strong>.
          </p>
          <div style={{ display: "flex", gap: 12, justifyContent: "center", marginTop: 24 }}>
            <button style={s.successBtn} onClick={resetForm}>
              Submit Another Report
            </button>
            <button
              style={{ ...s.successBtn, background: "#2b6cb0" }}
              onClick={() => (window.location.href = "/reports")}
            >
              View All Reports
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div style={s.wrap}>
      {/* Header */}
      <div style={s.header}>
        <h1 style={s.title}>🆘 Person Report</h1>
        <p style={s.sub}>Report a missing person or someone you found during the disaster.</p>
      </div>

      {/* Progress Bar */}
      <div style={s.progressWrap}>
        {STEPS.map((st) => (
          <div key={st.id} style={s.progressItem}>
            <div
              style={{
                ...s.progressDot,
                background:
                  step > st.id ? "#38a169" : step === st.id ? "#3182ce" : "#cbd5e0",
                color: step >= st.id ? "white" : "#718096",
              }}
            >
              {step > st.id ? "✓" : st.id}
            </div>
            <span
              style={{
                ...s.progressLabel,
                color: step === st.id ? "#3182ce" : "#718096",
                fontWeight: step === st.id ? "700" : "400",
              }}
            >
              {st.label}
            </span>
          </div>
        ))}
      </div>
      <div style={s.progressBar}>
        <div
          style={{
            ...s.progressFill,
            width: `${((step - 1) / (STEPS.length - 1)) * 100}%`,
          }}
        />
      </div>

      {/* Form Card */}
      <div style={s.card}>

        {/* STEP 1 — Report Type */}
        {step === 1 && (
          <div>
            <h2 style={s.stepTitle}>What are you reporting?</h2>
            <p style={s.stepSub}>Choose the type that best describes your situation.</p>
            <div style={s.typeGrid}>
              <div
                style={{
                  ...s.typeCard,
                  border: formData.reportType === "looking"
                    ? "3px solid #3182ce" : "2px solid #e2e8f0",
                  background: formData.reportType === "looking" ? "#ebf8ff" : "#fff",
                }}
                onClick={() => setFormData((p) => ({ ...p, reportType: "looking" }))}
              >
                <div style={s.typeIcon}>🔍</div>
                <div style={s.typeLabel}>I am LOOKING for someone</div>
                <div style={s.typeSub}>Report a missing person</div>
              </div>
              <div
                style={{
                  ...s.typeCard,
                  border: formData.reportType === "found"
                    ? "3px solid #38a169" : "2px solid #e2e8f0",
                  background: formData.reportType === "found" ? "#f0fff4" : "#fff",
                }}
                onClick={() => setFormData((p) => ({ ...p, reportType: "found" }))}
              >
                <div style={s.typeIcon}>👁️</div>
                <div style={s.typeLabel}>I FOUND or SAW someone</div>
                <div style={s.typeSub}>Report a person you encountered</div>
              </div>
            </div>

            <div style={{ marginTop: 28 }}>
              <label style={s.label}>Emergency Level</label>
              <div style={s.emergencyGrid}>
                {[
                  { value: "critical", label: "🔴 Critical", sub: "Needs immediate help", bg: "#fff5f5", border: "#fc8181" },
                  { value: "stable", label: "🟢 Stable", sub: "Not in immediate danger", bg: "#f0fff4", border: "#68d391" },
                  { value: "unknown", label: "⚪ Unknown", sub: "Situation unclear", bg: "#f7fafc", border: "#cbd5e0" },
                ].map((opt) => (
                  <div
                    key={opt.value}
                    style={{
                      ...s.emergencyCard,
                      border: formData.emergencyLevel === opt.value
                        ? `3px solid ${opt.border}` : "2px solid #e2e8f0",
                      background: formData.emergencyLevel === opt.value ? opt.bg : "#fff",
                    }}
                    onClick={() => setFormData((p) => ({ ...p, emergencyLevel: opt.value }))}
                  >
                    <div style={{ fontWeight: "700", fontSize: 15 }}>{opt.label}</div>
                    <div style={{ fontSize: 12, color: "#718096", marginTop: 2 }}>{opt.sub}</div>
                  </div>
                ))}
              </div>
            </div>

            <div style={{ marginTop: 20 }}>
              <label style={s.label}>Medical Status</label>
              <div style={s.checkRow}>
                <label style={s.checkCard}>
                  <input
                    type="checkbox"
                    name="isInjured"
                    checked={formData.isInjured}
                    onChange={handleChange}
                    style={{ marginRight: 8 }}
                  />
                  🩹 Person is <strong>injured</strong>
                </label>
                <label style={s.checkCard}>
                  <input
                    type="checkbox"
                    name="isUnconscious"
                    checked={formData.isUnconscious}
                    onChange={handleChange}
                    style={{ marginRight: 8 }}
                  />
                  😶 Person is <strong>unconscious</strong>
                </label>
              </div>
            </div>
          </div>
        )}

        {/* STEP 2 — Person Details */}
        {step === 2 && (
          <div>
            <h2 style={s.stepTitle}>Person's Identity</h2>
            <p style={s.stepSub}>Fill in what you know. All fields are optional except description.</p>

            <div style={s.field}>
              <label style={s.label}>Name (if known)</label>
              <input
                style={s.input}
                type="text"
                name="name"
                placeholder="Leave blank if unknown"
                value={formData.name}
                onChange={handleChange}
              />
            </div>

            <div style={s.row}>
              <div style={{ flex: 1 }}>
                <label style={s.label}>Age Range</label>
                <select
                  name="approximateAge"
                  value={formData.approximateAge}
                  onChange={handleChange}
                  style={s.select}
                >
                  {AGE_RANGES.map((r) => (
                    <option key={r} value={r}>{r}</option>
                  ))}
                </select>
              </div>
              <div style={{ flex: 1 }}>
                <label style={s.label}>Gender</label>
                <select
                  name="gender"
                  value={formData.gender}
                  onChange={handleChange}
                  style={s.select}
                >
                  <option value="unknown">Unknown</option>
                  <option value="male">Male</option>
                  <option value="female">Female</option>
                </select>
              </div>
            </div>

            <div style={s.field}>
              <label style={s.label}>Photo (optional but very helpful)</label>
              <div style={s.photoUpload}>
                <input
                  type="file"
                  accept="image/*"
                  onChange={handlePhotoChange}
                  id="photoInput"
                  style={{ display: "none" }}
                />
                <label htmlFor="photoInput" style={s.photoLabel}>
                  📸 {photo ? "Change Photo" : "Upload Photo"}
                </label>
                {photoPreview && (
                  <img src={photoPreview} alt="Preview" style={s.photoPreview} />
                )}
              </div>
            </div>
          </div>
        )}

        {/* STEP 3 — Description */}
        {step === 3 && (
          <div>
            <h2 style={s.stepTitle}>Describe the Person</h2>
            <p style={s.stepSub}>
              Describe clothing, hair, height, build, injuries — anything you remember.
              You can type or use voice input.
            </p>

            <div style={s.voiceRow}>
              {!isListening ? (
                <button type="button" style={s.voiceBtn} onClick={startListening}>
                  🎙️ Start Voice Input
                </button>
              ) : (
                <button
                  type="button"
                  style={{ ...s.voiceBtn, background: "#e53e3e" }}
                  onClick={stopListening}
                >
                  ⏹️ Stop Recording
                </button>
              )}
              {isListening && (
                <span style={s.recording}>● Recording... speak now</span>
              )}
            </div>

            {voiceError && <p style={s.err}>{voiceError}</p>}

            <textarea
              style={s.textarea}
              name="descriptionText"
              placeholder={
                `Examples:\n` +
                `"Elderly woman, short, grey hair, red jacket, dark pants, limping on right leg"\n` +
                `"Young man, tall, black t-shirt, jeans, has a cut on his forehead"\n` +
                `"Middle-aged woman, brown hijab, green dress, carrying a baby"`
              }
              value={formData.descriptionText}
              onChange={handleChange}
              rows={7}
            />

            <div style={s.tipBox}>
              <strong>💡 Helpful details to include:</strong>
              <ul style={{ margin: "6px 0 0 0", paddingLeft: 18, fontSize: 13, color: "#4a5568" }}>
                <li>Clothing colors and type</li>
                <li>Hair color and length</li>
                <li>Height (short / average / tall)</li>
                <li>Any injuries or distinctive marks</li>
                <li>What they were carrying or wearing</li>
              </ul>
            </div>
          </div>
        )}

        {/* STEP 4 — Location & Time */}
        {step === 4 && (
          <div>
            <h2 style={s.stepTitle}>Location & Time</h2>
            <p style={s.stepSub}>Where and when was this person seen?</p>

            <div style={s.field}>
              <label style={s.label}>Location Description</label>
              <input
                style={s.input}
                type="text"
                name="locationText"
                placeholder='e.g. "Near west bridge, Barangay 5" or "Outside City Hall"'
                value={formData.locationText}
                onChange={handleChange}
              />
            </div>

            <button type="button" style={s.gpsBtn} onClick={detectLocation}>
              📍 Auto-detect My GPS Location
            </button>

            {formData.lat && (
              <div style={s.gpsBadge}>
                ✅ GPS coordinates saved:{" "}
                {parseFloat(formData.lat).toFixed(5)},{" "}
                {parseFloat(formData.lng).toFixed(5)}
              </div>
            )}

            <div style={{ ...s.field, marginTop: 20 }}>
              <label style={s.label}>Date & Time Last Seen / Found</label>
              <input
                style={s.input}
                type="datetime-local"
                name="lastSeenAt"
                value={formData.lastSeenAt}
                onChange={handleChange}
              />
            </div>
          </div>
        )}

        {/* STEP 5 — Reporter Info */}
        {step === 5 && (
          <div>
            <h2 style={s.stepTitle}>Your Contact Info</h2>
            <p style={s.stepSub}>
              We need this to contact you if a match is found.
            </p>

            <div style={s.field}>
              <label style={s.label}>Your Full Name</label>
              <input
                style={s.input}
                type="text"
                name="reporterName"
                placeholder="Your name"
                value={formData.reporterName}
                onChange={handleChange}
              />
            </div>

            <div style={s.field}>
              <label style={s.label}>Your Phone Number</label>
              <input
                style={s.input}
                type="tel"
                name="reporterPhone"
                placeholder="Phone number we can reach you at"
                value={formData.reporterPhone}
                onChange={handleChange}
              />
            </div>

            {/* Summary */}
            <div style={s.summaryBox}>
              <strong>📋 Report Summary</strong>
              <div style={s.summaryGrid}>
                <div style={s.summaryItem}>
                  <span style={s.summaryKey}>Type</span>
                  <span style={s.summaryVal}>
                    {formData.reportType === "looking" ? "🔍 Looking For" : "👁️ Found/Saw"}
                  </span>
                </div>
                <div style={s.summaryItem}>
                  <span style={s.summaryKey}>Emergency</span>
                  <span style={s.summaryVal}>
                    {formData.emergencyLevel === "critical" ? "🔴 Critical"
                      : formData.emergencyLevel === "stable" ? "🟢 Stable" : "⚪ Unknown"}
                  </span>
                </div>
                <div style={s.summaryItem}>
                  <span style={s.summaryKey}>Age Range</span>
                  <span style={s.summaryVal}>{formData.approximateAge}</span>
                </div>
                <div style={s.summaryItem}>
                  <span style={s.summaryKey}>Gender</span>
                  <span style={s.summaryVal}>{formData.gender}</span>
                </div>
                {formData.isInjured && (
                  <div style={s.summaryItem}>
                    <span style={s.summaryVal}>🩹 Injured</span>
                  </div>
                )}
                {formData.isUnconscious && (
                  <div style={s.summaryItem}>
                    <span style={s.summaryVal}>😶 Unconscious</span>
                  </div>
                )}
              </div>
              <div style={{ marginTop: 8, fontSize: 13, color: "#4a5568" }}>
                <strong>Description:</strong> {formData.descriptionText.slice(0, 100)}
                {formData.descriptionText.length > 100 ? "..." : ""}
              </div>
            </div>
          </div>
        )}

        {/* Error */}
        {error && <div style={s.errorBox}>{error}</div>}

        {/* Navigation Buttons */}
        <div style={s.navRow}>
          {step > 1 && (
            <button type="button" style={s.backBtn} onClick={prevStep}>
              ← Back
            </button>
          )}
          {step < 5 ? (
            <button type="button" style={s.nextBtn} onClick={nextStep}>
              Next →
            </button>
          ) : (
            <button
              type="button"
              style={s.submitBtn}
              onClick={handleSubmit}
              disabled={loading}
            >
              {loading ? "Submitting..." : "✅ Submit Report"}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

const s = {
  wrap: { maxWidth: 680, margin: "0 auto", padding: "24px 16px", fontFamily: "'Segoe UI', sans-serif" },
  header: { textAlign: "center", marginBottom: 24 },
  title: { fontSize: 28, fontWeight: "800", color: "#1a202c", margin: 0 },
  sub: { color: "#718096", fontSize: 15, marginTop: 6 },
  progressWrap: { display: "flex", justifyContent: "space-between", marginBottom: 8 },
  progressItem: { display: "flex", flexDirection: "column", alignItems: "center", flex: 1 },
  progressDot: { width: 28, height: 28, borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: "700", marginBottom: 4 },
  progressLabel: { fontSize: 11, textAlign: "center" },
  progressBar: { height: 4, background: "#e2e8f0", borderRadius: 2, marginBottom: 24, position: "relative" },
  progressFill: { height: "100%", background: "#3182ce", borderRadius: 2, transition: "width 0.3s" },
  card: { background: "#fff", borderRadius: 16, padding: 28, boxShadow: "0 4px 24px rgba(0,0,0,0.08)", border: "1px solid #e2e8f0" },
  stepTitle: { fontSize: 22, fontWeight: "700", color: "#1a202c", marginBottom: 6, marginTop: 0 },
  stepSub: { color: "#718096", fontSize: 14, marginBottom: 24, marginTop: 0 },
  typeGrid: { display: "flex", gap: 16 },
  typeCard: { flex: 1, padding: 20, borderRadius: 12, cursor: "pointer", textAlign: "center", transition: "all 0.2s" },
  typeIcon: { fontSize: 32, marginBottom: 8 },
  typeLabel: { fontWeight: "700", fontSize: 15, color: "#2d3748" },
  typeSub: { fontSize: 12, color: "#718096", marginTop: 4 },
  emergencyGrid: { display: "flex", gap: 10, marginTop: 8 },
  emergencyCard: { flex: 1, padding: "12px 10px", borderRadius: 10, cursor: "pointer", textAlign: "center" },
  checkRow: { display: "flex", gap: 12, marginTop: 8 },
  checkCard: { flex: 1, padding: 14, border: "2px solid #e2e8f0", borderRadius: 10, cursor: "pointer", fontSize: 14, display: "flex", alignItems: "center" },
  field: { marginBottom: 18 },
  row: { display: "flex", gap: 16, marginBottom: 18 },
  label: { display: "block", fontWeight: "600", fontSize: 14, color: "#4a5568", marginBottom: 6 },
  input: { width: "100%", padding: "11px 14px", border: "2px solid #e2e8f0", borderRadius: 8, fontSize: 15, boxSizing: "border-box", outline: "none", color: "#2d3748" },
  select: { width: "100%", padding: "11px 14px", border: "2px solid #e2e8f0", borderRadius: 8, fontSize: 15, background: "#fff", color: "#2d3748" },
  photoUpload: { display: "flex", alignItems: "center", gap: 16, marginTop: 6 },
  photoLabel: { padding: "10px 18px", background: "#ebf8ff", color: "#2b6cb0", borderRadius: 8, cursor: "pointer", fontWeight: "600", fontSize: 14, border: "2px solid #bee3f8" },
  photoPreview: { width: 80, height: 80, objectFit: "cover", borderRadius: 8, border: "2px solid #e2e8f0" },
  voiceRow: { display: "flex", alignItems: "center", gap: 12, marginBottom: 12 },
  voiceBtn: { padding: "10px 20px", background: "#2b6cb0", color: "white", border: "none", borderRadius: 8, cursor: "pointer", fontSize: 14, fontWeight: "600" },
  recording: { color: "#e53e3e", fontWeight: "700", fontSize: 14 },
  textarea: { width: "100%", padding: "12px 14px", border: "2px solid #e2e8f0", borderRadius: 8, fontSize: 14, boxSizing: "border-box", resize: "vertical", color: "#2d3748", lineHeight: 1.6 },
  tipBox: { marginTop: 12, padding: 14, background: "#fffff0", border: "1px solid #f6e05e", borderRadius: 8, fontSize: 13 },
  gpsBtn: { padding: "10px 18px", background: "#276749", color: "white", border: "none", borderRadius: 8, cursor: "pointer", fontSize: 14, fontWeight: "600" },
  gpsBadge: { marginTop: 10, padding: "8px 14px", background: "#f0fff4", border: "1px solid #9ae6b4", borderRadius: 6, fontSize: 13, color: "#276749" },
  summaryBox: { marginTop: 20, padding: 16, background: "#f7fafc", border: "1px solid #e2e8f0", borderRadius: 10, fontSize: 14 },
  summaryGrid: { display: "flex", flexWrap: "wrap", gap: 10, marginTop: 10 },
  summaryItem: { display: "flex", gap: 6, alignItems: "center" },
  summaryKey: { color: "#718096", fontSize: 12 },
  summaryVal: { fontWeight: "600", color: "#2d3748", fontSize: 13 },
  navRow: { display: "flex", justifyContent: "space-between", marginTop: 28, gap: 12 },
  backBtn: { padding: "12px 24px", background: "#edf2f7", color: "#4a5568", border: "none", borderRadius: 8, cursor: "pointer", fontSize: 15, fontWeight: "600" },
  nextBtn: { marginLeft: "auto", padding: "12px 28px", background: "#3182ce", color: "white", border: "none", borderRadius: 8, cursor: "pointer", fontSize: 15, fontWeight: "700" },
  submitBtn: { marginLeft: "auto", padding: "12px 28px", background: "#276749", color: "white", border: "none", borderRadius: 8, cursor: "pointer", fontSize: 15, fontWeight: "700" },
  errorBox: { marginTop: 12, padding: "10px 14px", background: "#fff5f5", border: "1px solid #fc8181", borderRadius: 8, color: "#c53030", fontSize: 14 },
  successWrap: { minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", padding: 24, background: "#f7fafc" },
  successBox: { maxWidth: 480, width: "100%", padding: 40, background: "#fff", borderRadius: 20, textAlign: "center", boxShadow: "0 8px 32px rgba(0,0,0,0.1)", border: "2px solid #9ae6b4" },
  successIcon: { fontSize: 56, marginBottom: 16 },
  successTitle: { fontSize: 26, fontWeight: "800", color: "#1a202c", margin: "0 0 12px" },
  successText: { color: "#718096", fontSize: 15, margin: "0 0 8px" },
  successBtn: { padding: "12px 24px", background: "#276749", color: "white", border: "none", borderRadius: 8, cursor: "pointer", fontSize: 15, fontWeight: "600" },
  err: { color: "#e53e3e", fontSize: 13, marginBottom: 8 },
};
