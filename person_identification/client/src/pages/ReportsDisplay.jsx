// client/src/pages/ReportsDisplay.jsx

import { useState, useEffect } from "react";

const CONF_COLORS = {
  high: { bg: "#f0fff4", border: "#68d391", badge: "#276749", label: "HIGH" },
  medium: { bg: "#fffff0", border: "#f6e05e", badge: "#b7791f", label: "MEDIUM" },
  low: { bg: "#fff5f5", border: "#fc8181", badge: "#9b2c2c", label: "LOW" },
};

const EMERGENCY_COLORS = {
  critical: { bg: "#e53e3e", label: "🔴 CRITICAL" },
  stable: { bg: "#38a169", label: "🟢 Stable" },
  unknown: { bg: "#718096", label: "⚪ Unknown" },
};

export default function ReportsDisplay() {
  const [tab, setTab] = useState("matches");
  const [groups, setGroups] = useState([]);
  const [allReports, setAllReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [copiedId, setCopiedId] = useState(null);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [groupsRes, reportsRes] = await Promise.all([
        fetch("/api/person-reports/groups"),
        fetch("/api/person-reports"),
      ]);
      const groupsData = await groupsRes.json();
      const reportsData = await reportsRes.json();
      setGroups(groupsData.groups || []);
      setAllReports(reportsData.reports || []);
    } catch (e) {
      console.error("Failed to fetch data", e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    // Auto-refresh every 30 seconds
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

  const handleResolve = async (groupId) => {
    try {
      await fetch(`/api/person-reports/groups/${groupId}/resolve`, {
        method: "PATCH",
      });
      fetchData();
    } catch (e) {
      alert("Failed to resolve. Try again.");
    }
  };

  const copyPhone = (phone, id) => {
    navigator.clipboard.writeText(phone);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const unresolved = allReports.filter((r) => !r.resolved);
  const activeGroups = groups.filter((g) => !g.resolved);
  const resolvedGroups = groups.filter((g) => g.resolved);

  if (loading) {
    return (
      <div style={s.loadingWrap}>
        <div style={s.spinner} />
        <p style={{ color: "#718096", marginTop: 16 }}>Loading reports...</p>
      </div>
    );
  }

  return (
    <div style={s.wrap}>
      {/* Header */}
      <div style={s.header}>
        <div>
          <h1 style={s.title}>📋 Reports Dashboard</h1>
          <p style={s.sub}>Live view of all person reports and AI-detected matches</p>
        </div>
        <div style={s.headerRight}>
          <button style={s.refreshBtn} onClick={fetchData}>🔄 Refresh</button>
          <button
            style={s.newBtn}
            onClick={() => (window.location.href = "/")}
          >
            + New Report
          </button>
        </div>
      </div>

      {/* Stats Row */}
      <div style={s.statsRow}>
        <div style={{ ...s.statCard, borderTop: "4px solid #e53e3e" }}>
          <div style={s.statNum}>{activeGroups.length}</div>
          <div style={s.statLabel}>Active Matches</div>
        </div>
        <div style={{ ...s.statCard, borderTop: "4px solid #ed8936" }}>
          <div style={s.statNum}>{unresolved.length}</div>
          <div style={s.statLabel}>Unmatched Reports</div>
        </div>
        <div style={{ ...s.statCard, borderTop: "4px solid #38a169" }}>
          <div style={s.statNum}>{resolvedGroups.length}</div>
          <div style={s.statLabel}>Resolved Cases</div>
        </div>
        <div style={{ ...s.statCard, borderTop: "4px solid #3182ce" }}>
          <div style={s.statNum}>{allReports.length}</div>
          <div style={s.statLabel}>Total Reports</div>
        </div>
      </div>

      {/* Tabs */}
      <div style={s.tabRow}>
        {[
          { id: "matches", label: `🔗 Matches (${activeGroups.length})` },
          { id: "unresolved", label: `⚠️ Unmatched (${unresolved.length})` },
          { id: "all", label: `📄 All Reports (${allReports.length})` },
          { id: "resolved", label: `✅ Resolved (${resolvedGroups.length})` },
        ].map((t) => (
          <button
            key={t.id}
            style={{
              ...s.tab,
              background: tab === t.id ? "#3182ce" : "#fff",
              color: tab === t.id ? "white" : "#4a5568",
              borderBottom: tab === t.id ? "3px solid #2b6cb0" : "3px solid transparent",
            }}
            onClick={() => setTab(t.id)}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* TAB: MATCHES */}
      {tab === "matches" && (
        <div>
          {activeGroups.length === 0 ? (
            <EmptyState icon="🔗" text="No matches found yet. Submit more reports to trigger AI matching." />
          ) : (
            activeGroups.map((group) => (
              <GroupCard
                key={group._id}
                group={group}
                onResolve={handleResolve}
                onCopyPhone={copyPhone}
                copiedId={copiedId}
              />
            ))
          )}
        </div>
      )}

      {/* TAB: UNMATCHED */}
      {tab === "unresolved" && (
        <div>
          {unresolved.length === 0 ? (
            <EmptyState icon="✅" text="All reports have been matched!" />
          ) : (
            <div style={s.reportGrid}>
              {unresolved.map((r) => (
                <ReportCard key={r._id} report={r} onCopyPhone={copyPhone} copiedId={copiedId} />
              ))}
            </div>
          )}
        </div>
      )}

      {/* TAB: ALL */}
      {tab === "all" && (
        <div style={s.reportGrid}>
          {allReports.length === 0 ? (
            <EmptyState icon="📄" text="No reports submitted yet." />
          ) : (
            allReports.map((r) => (
              <ReportCard key={r._id} report={r} onCopyPhone={copyPhone} copiedId={copiedId} />
            ))
          )}
        </div>
      )}

      {/* TAB: RESOLVED */}
      {tab === "resolved" && (
        <div>
          {resolvedGroups.length === 0 ? (
            <EmptyState icon="📭" text="No resolved cases yet." />
          ) : (
            resolvedGroups.map((group) => (
              <GroupCard
                key={group._id}
                group={group}
                onResolve={handleResolve}
                onCopyPhone={copyPhone}
                copiedId={copiedId}
              />
            ))
          )}
        </div>
      )}
    </div>
  );
}

function GroupCard({ group, onResolve, onCopyPhone, copiedId }) {
  const [expanded, setExpanded] = useState(true);
  const conf = CONF_COLORS[group.confidence] || CONF_COLORS.medium;
  const emer = EMERGENCY_COLORS[group.highestEmergency] || EMERGENCY_COLORS.unknown;

  return (
    <div style={{ ...s.groupCard, background: conf.bg, border: `2px solid ${conf.border}` }}>
      {/* Group Header */}
      <div style={s.groupHeader}>
        <div style={s.groupLeft}>
          <span style={s.groupBadge}>
            👤 {group.reportIds?.length || 2} Reports — Likely Same Person
          </span>
          <div style={s.groupTags}>
            <span style={{ ...s.confBadge, background: conf.badge }}>
              {conf.label} CONFIDENCE
            </span>
            <span style={{ ...s.emerBadge, background: emer.bg }}>
              {emer.label}
            </span>
            {group.resolved && (
              <span style={{ ...s.emerBadge, background: "#718096" }}>✅ Resolved</span>
            )}
          </div>
        </div>
        <button
          style={s.expandBtn}
          onClick={() => setExpanded((e) => !e)}
        >
          {expanded ? "▲ Collapse" : "▼ Expand"}
        </button>
      </div>

      <h3 style={s.groupName}>{group.representativeName}</h3>
      <p style={s.groupReason}>💬 <em>{group.aiReason}</em></p>

      {expanded && (
        <div>
          <div style={s.reportsRow}>
            {(group.reportIds || []).map((r, i) => (
              <div key={r._id || i} style={s.inlineReport}>
                <div style={s.inlineReportHeader}>
                  <strong>
                    {r.reportType === "looking" ? "🔍 Looking For" : "👁️ Found/Saw"}
                  </strong>
                  <span style={s.reporterTag}>
                    {r.reporterName}
                  </span>
                </div>
                <p style={s.inlineDesc}>{r.descriptionText}</p>
                <div style={s.inlineMeta}>
                  {r.approximateAge && <span style={s.metaChip}>🎂 {r.approximateAge}</span>}
                  {r.locationText && <span style={s.metaChip}>📍 {r.locationText}</span>}
                  {r.lastSeenAt && <span style={s.metaChip}>🕐 {new Date(r.lastSeenAt).toLocaleString()}</span>}
                  {r.isInjured && <span style={{ ...s.metaChip, background: "#fed7d7", color: "#9b2c2c" }}>🩹 Injured</span>}
                  {r.isUnconscious && <span style={{ ...s.metaChip, background: "#fed7d7", color: "#9b2c2c" }}>😶 Unconscious</span>}
                </div>
                <button
                  style={s.phoneBtn}
                  onClick={() => onCopyPhone(r.reporterPhone, r._id)}
                >
                  {copiedId === r._id ? "✅ Copied!" : `📞 ${r.reporterPhone}`}
                </button>
                {r.photoUrl && (
                  <img src={r.photoUrl} alt="person" style={s.inlinePhoto} />
                )}
              </div>
            ))}
          </div>

          {!group.resolved && (
            <button style={s.resolveBtn} onClick={() => onResolve(group._id)}>
              ✅ Mark as Resolved — Case Closed
            </button>
          )}
        </div>
      )}
    </div>
  );
}

function ReportCard({ report, onCopyPhone, copiedId }) {
  const emer = EMERGENCY_COLORS[report.emergencyLevel] || EMERGENCY_COLORS.unknown;
  return (
    <div style={s.reportCard}>
      <div style={s.reportCardHeader}>
        <span style={s.reportTypeBadge}>
          {report.reportType === "looking" ? "🔍 Looking" : "👁️ Found"}
        </span>
        <span style={{ ...s.emerBadge, background: emer.bg, fontSize: 11 }}>
          {emer.label}
        </span>
      </div>
      <p style={s.reportDesc}>{report.descriptionText}</p>
      <div style={s.reportMeta}>
        {report.approximateAge && <span style={s.metaChip}>🎂 {report.approximateAge}</span>}
        {report.gender !== "unknown" && <span style={s.metaChip}>👤 {report.gender}</span>}
        {report.locationText && <span style={s.metaChip}>📍 {report.locationText}</span>}
        {report.isInjured && <span style={{ ...s.metaChip, background: "#fed7d7", color: "#9b2c2c" }}>🩹 Injured</span>}
        {report.isUnconscious && <span style={{ ...s.metaChip, background: "#fed7d7", color: "#9b2c2c" }}>😶 Unconscious</span>}
      </div>
      <div style={s.reportFooter}>
        <span style={s.reporterName}>👤 {report.reporterName}</span>
        <button
          style={s.phoneBtn}
          onClick={() => onCopyPhone(report.reporterPhone, report._id)}
        >
          {copiedId === report._id ? "✅ Copied!" : `📞 ${report.reporterPhone}`}
        </button>
      </div>
      {report.photoUrl && (
        <img src={report.photoUrl} alt="person" style={s.cardPhoto} />
      )}
    </div>
  );
}

function EmptyState({ icon, text }) {
  return (
    <div style={s.empty}>
      <div style={{ fontSize: 48, marginBottom: 12 }}>{icon}</div>
      <p style={{ color: "#718096", fontSize: 15 }}>{text}</p>
    </div>
  );
}

const s = {
  wrap: { maxWidth: 960, margin: "0 auto", padding: "24px 16px", fontFamily: "'Segoe UI', sans-serif" },
  header: { display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 24 },
  title: { fontSize: 26, fontWeight: "800", color: "#1a202c", margin: 0 },
  sub: { color: "#718096", fontSize: 14, marginTop: 4 },
  headerRight: { display: "flex", gap: 10 },
  refreshBtn: { padding: "8px 16px", background: "#edf2f7", border: "none", borderRadius: 8, cursor: "pointer", fontSize: 14, color: "#4a5568", fontWeight: "600" },
  newBtn: { padding: "8px 18px", background: "#3182ce", color: "white", border: "none", borderRadius: 8, cursor: "pointer", fontSize: 14, fontWeight: "700" },
  statsRow: { display: "flex", gap: 14, marginBottom: 24 },
  statCard: { flex: 1, background: "#fff", borderRadius: 12, padding: "16px 20px", boxShadow: "0 2px 8px rgba(0,0,0,0.06)" },
  statNum: { fontSize: 32, fontWeight: "800", color: "#1a202c" },
  statLabel: { fontSize: 13, color: "#718096", marginTop: 2 },
  tabRow: { display: "flex", gap: 4, marginBottom: 20, borderBottom: "1px solid #e2e8f0", overflowX: "auto" },
  tab: { padding: "10px 18px", border: "none", borderRadius: "8px 8px 0 0", cursor: "pointer", fontSize: 14, fontWeight: "600", whiteSpace: "nowrap" },
  groupCard: { borderRadius: 14, padding: 20, marginBottom: 16 },
  groupHeader: { display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 },
  groupLeft: { flex: 1 },
  groupBadge: { fontWeight: "700", fontSize: 15, color: "#2d3748" },
  groupTags: { display: "flex", gap: 8, marginTop: 6, flexWrap: "wrap" },
  confBadge: { color: "white", fontSize: 11, fontWeight: "700", padding: "3px 10px", borderRadius: 20 },
  emerBadge: { color: "white", fontSize: 11, fontWeight: "700", padding: "3px 10px", borderRadius: 20 },
  expandBtn: { padding: "6px 14px", background: "rgba(0,0,0,0.06)", border: "none", borderRadius: 6, cursor: "pointer", fontSize: 12, color: "#4a5568", marginLeft: 12 },
  groupName: { fontSize: 20, fontWeight: "700", color: "#1a202c", margin: "8px 0 4px" },
  groupReason: { color: "#4a5568", fontSize: 14, margin: "0 0 16px" },
  reportsRow: { display: "flex", gap: 12, marginBottom: 14 },
  inlineReport: { flex: 1, background: "rgba(255,255,255,0.8)", borderRadius: 10, padding: 14, border: "1px solid rgba(0,0,0,0.08)" },
  inlineReportHeader: { display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 },
  reporterTag: { fontSize: 12, color: "#718096" },
  inlineDesc: { fontSize: 14, color: "#2d3748", margin: "0 0 8px", lineHeight: 1.5 },
  inlineMeta: { display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 10 },
  metaChip: { background: "#edf2f7", color: "#4a5568", fontSize: 12, padding: "3px 8px", borderRadius: 12 },
  phoneBtn: { padding: "6px 12px", background: "#ebf8ff", color: "#2b6cb0", border: "1px solid #bee3f8", borderRadius: 6, cursor: "pointer", fontSize: 13, fontWeight: "600" },
  inlinePhoto: { width: 80, height: 80, objectFit: "cover", borderRadius: 8, marginTop: 10, border: "2px solid #e2e8f0" },
  resolveBtn: { width: "100%", padding: "12px", background: "#276749", color: "white", border: "none", borderRadius: 8, cursor: "pointer", fontSize: 15, fontWeight: "700", marginTop: 4 },
  reportGrid: { display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 14 },
  reportCard: { background: "#fff", borderRadius: 12, padding: 16, boxShadow: "0 2px 8px rgba(0,0,0,0.06)", border: "1px solid #e2e8f0" },
  reportCardHeader: { display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 },
  reportTypeBadge: { fontWeight: "700", fontSize: 14, color: "#2d3748" },
  reportDesc: { fontSize: 14, color: "#4a5568", margin: "0 0 10px", lineHeight: 1.5 },
  reportMeta: { display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 10 },
  reportFooter: { display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 8 },
  reporterName: { fontSize: 13, color: "#718096" },
  cardPhoto: { width: "100%", height: 120, objectFit: "cover", borderRadius: 8, marginTop: 10, border: "1px solid #e2e8f0" },
  empty: { textAlign: "center", padding: "60px 20px" },
  loadingWrap: { display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", minHeight: "60vh" },
  spinner: { width: 40, height: 40, border: "4px solid #e2e8f0", borderTop: "4px solid #3182ce", borderRadius: "50%", animation: "spin 1s linear infinite" },
};
