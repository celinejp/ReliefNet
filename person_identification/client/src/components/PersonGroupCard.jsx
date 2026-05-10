export default function PersonGroupCard({ group, onResolve }) {
  const confColor = { high:"#276749", medium:"#b7791f", low:"#9b2c2c" };
  const emerColor = { critical:"#e53e3e", stable:"#38a169", unknown:"#718096" };
  return (
    <div style={s.card}>
      <div style={s.header}>
        <span style={s.badge}>👤 {group.reportIds.length} Reports — Likely Same Person</span>
        <span style={{...s.emerBadge, background: group.resolved ? "#718096" : emerColor[group.highestEmergency]}}>
          {group.resolved ? "✅ Resolved" : group.highestEmergency === "critical" ? "🔴 CRITICAL" : group.highestEmergency === "stable" ? "🟢 Stable" : "⚪ Unknown"}
        </span>
      </div>
      <h3 style={s.name}>{group.representativeName}</h3>
      <span style={{...s.conf, background: confColor[group.confidence]}}>{group.confidence.toUpperCase()} CONFIDENCE</span>
      <p style={s.reason}>💬 {group.aiReason}</p>
      <div style={s.list}>
        {group.reportIds.map((r, i) => (
          <div key={r._id} style={s.item}>
            <strong>Report {i+1} — {r.reportType === "looking" ? "🔍 Looking" : "👁️ Found"}</strong>
            <p style={s.rt}>{r.descriptionText}</p>
            <p style={s.rm}>📍 {r.locationText || "No location"} | 🕐 {new Date(r.lastSeenAt).toLocaleString()} | 📞 {r.reporterName}</p>
            {r.isInjured && <span style={s.tag}>🩹 Injured</span>}
            {r.isUnconscious && <span style={s.tag}>😶 Unconscious</span>}
            {r.photoUrl && <img src={r.photoUrl} alt="person" style={s.rphoto}/>}
          </div>
        ))}
      </div>
      {!group.resolved && <button style={s.resolveBtn} onClick={() => onResolve(group._id)}>✅ Mark Resolved</button>}
    </div>
  );
}
const s = {
  card:{border:"1px solid #e2e8f0",borderRadius:10,padding:20,marginBottom:16,background:"#fff",boxShadow:"0 2px 8px rgba(0,0,0,0.07)"},
  header:{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:8},
  badge:{fontWeight:"bold",fontSize:15},
  emerBadge:{color:"white",fontSize:12,fontWeight:"bold",padding:"3px 10px",borderRadius:20},
  name:{fontSize:20,margin:"4px 0 8px"},
  conf:{color:"white",fontSize:11,fontWeight:"bold",padding:"2px 8px",borderRadius:4},
  reason:{color:"#4a5568",fontSize:14,fontStyle:"italic",margin:"8px 0 14px"},
  list:{borderTop:"1px solid #e2e8f0",paddingTop:12},
  item:{marginBottom:14,paddingBottom:14,borderBottom:"1px dashed #e2e8f0"},
  rt:{fontSize:14,color:"#4a5568",margin:"4px 0"},
  rm:{fontSize:12,color:"#718096"},
  tag:{display:"inline-block",background:"#fed7d7",color:"#9b2c2c",fontSize:12,padding:"2px 8px",borderRadius:4,marginRight:6,marginTop:4},
  rphoto:{width:100,height:100,objectFit:"cover",borderRadius:6,marginTop:8,border:"1px solid #ccc"},
  resolveBtn:{marginTop:12,padding:"8px 18px",background:"#276749",color:"white",border:"none",borderRadius:6,cursor:"pointer",fontSize:14,fontWeight:"bold"},
};
