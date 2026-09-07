(()=>{
const css=document.createElement('style');
css.textContent=`
.report-filters{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}.report-actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}.report-actions button{flex:1;min-width:140px}.report-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:9px;margin:12px 0}.report-stat{border:1px solid #dce4ef;border-radius:13px;padding:11px;text-align:center}.report-stat b{display:block;font-size:22px;color:#0f3d75}.report-table-wrap{overflow:auto;margin-top:10px}.report-table{width:100%;border-collapse:collapse;font-size:12px}.report-table th,.report-table td{border-bottom:1px solid #e7edf5;padding:9px 7px;text-align:left;vertical-align:top}.report-table th{background:#f5f8fc;color:#42516a;font-size:11px;white-space:nowrap}.report-table .num{text-align:center;white-space:nowrap}.report-title{text-align:center;margin-bottom:14px}.report-title h2{margin-bottom:3px}.report-badge{display:inline-flex;padding:4px 7px;border-radius:999px;font-size:10px;font-weight:800}.report-full{background:#dff5e8;color:#17673f}.report-pending{background:#fff1cc;color:#8c5c00}.report-req{background:#fde4e4;color:#962d2d}.report-none{background:#edf1f6;color:#64748b}.report-subject-row{display:grid;grid-template-columns:minmax(150px,2fr) repeat(4,minmax(70px,1fr));gap:8px;align-items:center;padding:9px 0;border-bottom:1px solid #edf0f4;font-size:12px}.report-subject-row:last-child{border-bottom:0}.report-subject-row.head{font-weight:800;color:#42516a;font-size:11px}.report-subject-row>div:not(:first-child){text-align:center}.report-note{font-size:11px;color:#7b8798;margin-top:8px}.report-search{margin-top:10px}@media(max-width:620px){.report-filters{grid-template-columns:1fr}.report-grid{grid-template-columns:1fr 1fr}.report-subject-row{grid-template-columns:minmax(130px,2fr) repeat(4,minmax(58px,1fr));font-size:11px}}
@media print{
 body *{visibility:hidden!important}
 #reportPrint,#reportPrint *{visibility:visible!important}
 #reportPrint{position:absolute;left:0;top:0;width:100%;background:#fff!important}
 #reportPrint .card{box-shadow:none!important;border:0!important;margin:0 0 12px!important;padding:8px!important}
 .report-no-print{display:none!important}
 .report-table-wrap{overflow:visible!important}
 .report-table{font-size:10px!important}
 .report-table th,.report-table td{padding:5px 4px!important}
 .report-subject-row{font-size:10px!important}
 @page{size:A4 landscape;margin:10mm}
}
`;
document.head.appendChild(css);

let reportState={term:null,section:'all',status:'all',search:''};
let reportRole='admin';
let adviserReportsActive=false;
const baseAdminRenderForReports=renderAdmin;
const baseAdminPanelForReports=renderAdminPanel;
const baseAdvRenderForReports=renderAdviser;
const baseAdvSetTabForReports=window.setAdv360Tab;

function reportStatusLabel(row){
  if(!row.total)return ['No Assignments','report-none'];
  if(row.cleared===row.total)return ['Fully Cleared','report-full'];
  if(row.requirement>0)return ['With Requirement','report-req'];
  return ['Has Pending','report-pending'];
}
function reportPct(a,b){return b?Math.round((a/b)*100):0}
function reportDate(){try{return new Intl.DateTimeFormat('en-PH',{year:'numeric',month:'long',day:'numeric',hour:'numeric',minute:'2-digit'}).format(new Date())}catch{return new Date().toLocaleString()}}
async function reportSections(role){
  if(role==='admin')return api('/rest/v1/sections?is_active=eq.true&select=id,grade_level,section_name,school_year&order=grade_level.asc,section_name.asc');
  const a=await api('/rest/v1/adviser_section_assignments?adviser_user_id=eq.'+profile.user_id+'&select=section_id');
  const ids=[...new Set((a||[]).map(x=>x.section_id))];
  if(!ids.length)return [];
  return api('/rest/v1/sections?id=in.('+ids.join(',')+')&is_active=eq.true&select=id,grade_level,section_name,school_year&order=grade_level.asc,section_name.asc');
}
async function buildReportData(role){
  const [periods,sections]=await Promise.all([
    api('/rest/v1/clearance_periods?select=id,term_no,name,school_year,is_active,is_open&order=term_no.asc'),
    reportSections(role)
  ]);
  if(!periods.length)return {periods,sections,period:null,selectedSections:[],rows:[],allRows:[],subjectStats:[]};
  if(!reportState.term||!periods.some(p=>Number(p.id)===Number(reportState.term))){const cur=periods.find(p=>p.is_active)||periods[0];reportState.term=cur.id}
  if(reportState.section!=='all'&&!sections.some(s=>Number(s.id)===Number(reportState.section)))reportState.section='all';
  const period=periods.find(p=>Number(p.id)===Number(reportState.term));
  const selectedSections=reportState.section==='all'?sections:sections.filter(s=>Number(s.id)===Number(reportState.section));
  if(!selectedSections.length)return {periods,sections,period,selectedSections,rows:[],allRows:[],subjectStats:[]};
  const sids=selectedSections.map(s=>s.id);
  const [students,assignments]=await Promise.all([
    api('/rest/v1/students?section_id=in.('+sids.join(',')+')&is_active=eq.true&select=id,lrn,full_name,section_id&order=full_name.asc'),
    api('/rest/v1/term_subjects?period_id=eq.'+period.id+'&section_id=in.('+sids.join(',')+')&is_active=eq.true&select=id,section_id,subject_id,slot_no&order=section_id.asc,slot_no.asc')
  ]);
  let records=[],subjects=[];
  if(assignments.length){
    records=await api('/rest/v1/subject_clearance_records?term_subject_id=in.('+assignments.map(a=>a.id).join(',')+')&select=student_id,term_subject_id,status,remarks');
    const subids=[...new Set(assignments.map(a=>a.subject_id))];
    if(subids.length)subjects=await api('/rest/v1/subjects?id=in.('+subids.join(',')+')&select=id,subject_code,subject_name');
  }
  const sectionMap=Object.fromEntries(sections.map(s=>[s.id,s]));
  const subjectMap=Object.fromEntries(subjects.map(s=>[s.id,s]));
  const recordMap={};records.forEach(r=>{recordMap[r.student_id+'-'+r.term_subject_id]=r});
  const allRows=students.map(st=>{
    const a=assignments.filter(x=>Number(x.section_id)===Number(st.section_id));
    let cleared=0,pending=0,requirement=0;
    a.forEach(x=>{const r=recordMap[st.id+'-'+x.id];const status=r?.status||'pending';if(status==='cleared')cleared++;else if(status==='with_requirement')requirement++;else pending++});
    return {id:st.id,lrn:st.lrn,full_name:st.full_name,section_id:st.section_id,section:sectionMap[st.section_id],total:a.length,cleared,pending,requirement};
  });
  let rows=allRows.slice();
  if(reportState.status==='fully_cleared')rows=rows.filter(r=>r.total>0&&r.cleared===r.total);
  if(reportState.status==='pending')rows=rows.filter(r=>r.pending>0||r.total===0);
  if(reportState.status==='requirement')rows=rows.filter(r=>r.requirement>0);
  const q=(reportState.search||'').trim().toLowerCase();if(q)rows=rows.filter(r=>(r.full_name+' '+r.lrn+' '+(r.section?.section_name||'')).toLowerCase().includes(q));
  const grouped={};
  assignments.forEach(a=>{
    if(!grouped[a.subject_id])grouped[a.subject_id]={subject:subjectMap[a.subject_id],classes:0,cleared:0,pending:0,requirement:0,total:0};
    const g=grouped[a.subject_id];g.classes++;
    const studs=students.filter(st=>Number(st.section_id)===Number(a.section_id));
    studs.forEach(st=>{const status=recordMap[st.id+'-'+a.id]?.status||'pending';g.total++;if(status==='cleared')g.cleared++;else if(status==='with_requirement')g.requirement++;else g.pending++});
  });
  const subjectStats=Object.values(grouped).sort((a,b)=>String(a.subject?.subject_name||'').localeCompare(String(b.subject?.subject_name||'')));
  return {periods,sections,period,selectedSections,rows,allRows,subjectStats};
}

async function renderClearanceReport(hostId,role){
  reportRole=role;
  const host=$(hostId);if(!host)return;
  host.innerHTML='<div class="card"><div class="empty">Loading report...</div></div>';
  try{
    const d=await buildReportData(role);
    if(!d.sections.length){host.innerHTML='<div class="card"><div class="empty">No section is available for this report.</div></div>';return}
    const totalLearners=d.allRows.length;
    const fully=d.allRows.filter(r=>r.total>0&&r.cleared===r.total).length;
    const pending=d.allRows.filter(r=>r.total===0||r.pending>0).length;
    const requirement=d.allRows.filter(r=>r.requirement>0).length;
    const expected=d.allRows.reduce((n,r)=>n+r.total,0),clearedRows=d.allRows.reduce((n,r)=>n+r.cleared,0);
    const overallPct=reportPct(clearedRows,expected);
    const sectionLabel=reportState.section==='all'?(role==='admin'?'All Active Sections':'All My Sections'):(d.selectedSections[0]?`Grade ${d.selectedSections[0].grade_level} – ${d.selectedSections[0].section_name}`:'Section');
    host.innerHTML=`
      <div class="card report-no-print"><h3>Report Filters</h3><div class="report-filters"><div class="field"><label>Term</label><select id="reportTerm">${d.periods.map(p=>`<option value="${p.id}" ${Number(p.id)===Number(reportState.term)?'selected':''}>Term ${p.term_no} • SY ${esc(p.school_year)}</option>`).join('')}</select></div><div class="field"><label>Section</label><select id="reportSection"><option value="all" ${reportState.section==='all'?'selected':''}>${role==='admin'?'All Active Sections':'All My Sections'}</option>${d.sections.map(s=>`<option value="${s.id}" ${Number(s.id)===Number(reportState.section)?'selected':''}>Grade ${s.grade_level} – ${esc(s.section_name)}</option>`).join('')}</select></div><div class="field"><label>Learner Status</label><select id="reportStatus"><option value="all" ${reportState.status==='all'?'selected':''}>All Learners</option><option value="fully_cleared" ${reportState.status==='fully_cleared'?'selected':''}>Fully Cleared</option><option value="pending" ${reportState.status==='pending'?'selected':''}>Has Pending</option><option value="requirement" ${reportState.status==='requirement'?'selected':''}>With Requirement</option></select></div></div><div class="field report-search"><label>Search Learner</label><input id="reportSearch" value="${esc(reportState.search)}" placeholder="Type learner name or LRN"></div><div class="report-actions"><button class="primary" onclick="applyClearanceReportFilters()">Apply Filters</button><button class="secondary" style="margin:0" onclick="resetClearanceReportFilters()">Reset</button><button class="smallbtn" onclick="printClearanceReport()">Print / Save as PDF</button></div></div>
      <div id="reportPrint">
        <div class="card"><div class="report-title"><h2>HNHS360 Subject Clearance Report</h2><div class="muted">Halapitan National High School</div><div class="muted">${d.period?`Term ${d.period.term_no} • SY ${esc(d.period.school_year)}`:''} • ${esc(sectionLabel)}</div><div class="report-note">Generated ${esc(reportDate())}</div></div><div class="report-grid"><div class="report-stat"><b>${totalLearners}</b><span class="muted">Learners</span></div><div class="report-stat"><b>${fully}</b><span class="muted">Fully Cleared</span></div><div class="report-stat"><b>${pending}</b><span class="muted">Has Pending</span></div><div class="report-stat"><b>${requirement}</b><span class="muted">Requirement</span></div></div><div class="row between"><div><b>Overall subject clearances</b><div class="muted">${clearedRows} of ${expected} clearance records cleared</div></div><div class="count">${overallPct}%</div></div><div class="student-progress"><span style="width:${overallPct}%"></span></div></div>
        <div class="card"><h3>Subject-by-Subject Summary</h3>${d.subjectStats.length?`<div class="report-subject-row head"><div>Subject</div><div>Classes</div><div>Cleared</div><div>Pending</div><div>Requirement</div></div>${d.subjectStats.map(g=>`<div class="report-subject-row"><div><b>${esc(g.subject?.subject_name||'Subject')}</b>${g.subject?.subject_code?`<div class="muted">${esc(g.subject.subject_code)} • ${reportPct(g.cleared,g.total)}% cleared</div>`:''}</div><div>${g.classes}</div><div>${g.cleared}</div><div>${g.pending}</div><div>${g.requirement}</div></div>`).join('')}`:'<div class="empty">No subjects are assigned for this term.</div>'}</div>
        <div class="card"><div class="row between"><h3>Learner Clearance Status</h3><div class="muted">Showing ${d.rows.length} of ${totalLearners}</div></div><div class="report-table-wrap"><table class="report-table"><thead><tr><th>Learner</th><th>LRN</th><th>Section</th><th class="num">Cleared</th><th class="num">Pending</th><th class="num">Requirement</th><th>Overall</th></tr></thead><tbody>${d.rows.length?d.rows.map(r=>{const sl=reportStatusLabel(r);return `<tr><td><b>${esc(r.full_name)}</b></td><td>${esc(r.lrn)}</td><td>${r.section?`Grade ${r.section.grade_level} – ${esc(r.section.section_name)}`:''}</td><td class="num">${r.cleared}/${r.total}</td><td class="num">${r.pending}</td><td class="num">${r.requirement}</td><td><span class="report-badge ${sl[1]}">${sl[0]}</span></td></tr>`}).join(''):'<tr><td colspan="7" class="empty">No learners match the selected filters.</td></tr>'}</tbody></table></div></div>
      </div>`;
  }catch(e){host.innerHTML=`<div class="card"><div class="msg error">${esc(e.message)}</div></div>`}
}

window.applyClearanceReportFilters=async function(){reportState.term=Number($('reportTerm').value);reportState.section=$('reportSection').value==='all'?'all':Number($('reportSection').value);reportState.status=$('reportStatus').value;reportState.search=$('reportSearch').value.trim();await renderClearanceReport(profile.role==='admin'?'adminPanel':'advReportPanel',profile.role==='admin'?'admin':'adviser')};
window.resetClearanceReportFilters=async function(){reportState={term:null,section:'all',status:'all',search:''};await renderClearanceReport(profile.role==='admin'?'adminPanel':'advReportPanel',profile.role==='admin'?'admin':'adviser')};
window.printClearanceReport=function(){window.print()};

renderAdmin=async function(){
  $('dashboard').innerHTML=`<div class="card"><h2>Admin Dashboard</h2><div class="muted">Manage HNHS360 Subject Clearances.</div><div class="navtabs">${['overview','terms','reports','sections','accounts','students','subjects','assignments'].map(t=>`<button class="navtab ${adminTab===t?'active':''}" onclick="setAdminTab('${t}')">${t[0].toUpperCase()+t.slice(1)}</button>`).join('')}</div></div><div id="adminPanel"></div>`;
  await renderAdminPanel();
};
renderAdminPanel=async function(){if(adminTab==='reports')return renderClearanceReport('adminPanel','admin');return baseAdminPanelForReports()};

window.setAdv360Tab=async function(t){
  if(t==='reports'){adviserReportsActive=true;return renderAdviser()}
  adviserReportsActive=false;return baseAdvSetTabForReports(t);
};
renderAdviser=async function(){
  if(!adviserReportsActive)return baseAdvRenderForReports();
  $('dashboard').innerHTML=`<div class="card"><h2>Adviser Dashboard</h2><div class="muted">Manage your assigned section(s), subject assignments, and clearance progress.</div><div class="adv360-tabs">${[['overview','Overview'],['assignments','Subject Assignments'],['clearance','Clearance Overview'],['reports','Reports'],['teachers','Subject Teachers'],['learners','Learners']].map(x=>`<button class="${x[0]==='reports'?'active':''}" onclick="setAdv360Tab('${x[0]}')">${x[1]}</button>`).join('')}</div></div><div id="advReportPanel"></div>`;
  await renderClearanceReport('advReportPanel','adviser');
};

if(typeof profile!=='undefined'&&profile?.role==='admin'&&adminTab==='reports')renderClearanceReport('adminPanel','admin').catch(()=>{});
})();