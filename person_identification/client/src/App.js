import PersonReportForm from "./pages/PersonReportForm";
import ReportsDisplay from "./pages/ReportsDisplay";

function App() {
  const path = window.location.pathname;

  return (
    <div style={{ minHeight: "100vh", background: "#f7fafc" }}>
      {/* Nav */}
      <div style={{
        background: "#1a202c", padding: "14px 24px",
        display: "flex", alignItems: "center", gap: 24,
      }}>
        <span style={{ color: "white", fontWeight: "800", fontSize: 18 }}>
          🆘 ReliefNet
        </span>
        <a href="/" style={navLink(path === "/")}>Submit Report</a>
        <a href="/reports" style={navLink(path === "/reports")}>View Reports</a>
      </div>

      {path === "/reports" ? <ReportsDisplay /> : <PersonReportForm />}
    </div>
  );
}

const navLink = (active) => ({
  color: active ? "#63b3ed" : "#a0aec0",
  textDecoration: "none",
  fontWeight: active ? "700" : "400",
  fontSize: 14,
});

export default App;
