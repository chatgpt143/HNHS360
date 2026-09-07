(()=>{
const css=document.createElement('style');
css.textContent=`
.student-id{display:grid;grid-template-columns:1fr auto;gap:12px;align-items:center}.student-meta{display:flex;gap:8px;flex-wrap:wrap;margin-top:8px}.student-chip{display:inline-flex;padding:6px 9px;border-radius:999px;background:#eef3f9;color:#36506f;font-size:12px;font-weight:700}.student-progress{height:11px;background:#edf2f7;border-radius:999px;overflow:hidden;margin:10px 0}.student-progress>span{display:block;height:100%;background:#1e8e5a;border-radius:999px}.student-stats{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:12px}.student-stat{border:1px solid #dce4ef;border-radius:13px;padding:10px;text-align:center}.student-stat b{display:block;font-size:20px;color:#0f3d75}.student-subject{border:1px solid #dce4ef;border-radius:16px;padding:14px;margin-top:10px}.student-subject-head{display:flex;justify-content:space-between;align-items:flex-start;gap:10px}.student-subject-name{font-size:15px;font-weight:800}.student-teacher{font-size:12px;color:#6b778c;margin-top:4px}.student-remarks{margin-top:10px;padding:10px 12px;border-radius:12px;background:#f5f8fc;font-size:13px;color:#3e4f66}.student-remarks.requirement{background:#fff0f0;color:#812828}.student-updated{font-size:11px;color:#8a96a8;margin-top:8px}.student-current{font-size:10px;font-weight:800;text-transform:uppercase;padding:4px 7px;border-radius:999px;background:#dff5e8;color:#17673f;margin-left:5px}.student-term-note{font-size:12px;color:#6b778c;margin-top:-4px;margin-bottom:10px}.student-term-state{display:inline-flex;padding:5px 8px;border-radius:999px;font-size:10px;font-weight:800;text-transform:uppercase;margin-left:5px}.student-term-open{background:#dff5e8;color:#17673f}.student-term-locked{background:#fde4e4;color:#962d2d}@media(max-width:520px){.student-id{grid-template-columns:1fr}.student-stats{grid-template-columns:repeat(3,1fr)}}`;
document.head.appendChild(css);
let studentTermInitialized=false;
function statusText(s){return s==='with_requirement'?'With Requirement':s==='cleared'?'Cleared':'Pending'}
function fmtDate(v){if(!v)return'';try{return new Intl.DateTimeFormat('en-PH',{year:'numeric',month:'short',day:'numeric',hour:'numeric',minute:'2-digit'}).format(new Date(v))}catch{return''}}

renderStudent=async function(){
  try{
    const rows=await api('/rest/v1/students?user_id=eq.'+profile.user_id+'&is_active=eq.true&select=id,lrn,full_name,section_id');
    if(!rows.length){$('dashboard').innerHTML='<div class="card"><h2>Student Dashboard</h2><div class="empty">Your student record has not yet been linked.</div></div>';return}
    const st=rows[0];
    const [sections,periods]=await Promise.all([
      api('/rest/v1/sections?id=eq.'+st.section_id+'&select=id,grade_level,section_name,school_year,is_active'),
      api('/rest/v1/clearance_periods?select=id,term_no,name,school_year,is_active,is_open,opens_at,closes_at&order=term_no.asc')
    ]);
    const sec=sections[0];
    if(!studentTermInitialized){const current=periods.find(p=>p.is_active);if(current)activeTerm=current.term_no;else if(periods.length)activeTerm=periods[0].term_no;studentTermInitialized=true}
    if(!periods.some(p=>Number(p.term_no)===Number(activeTerm))&&periods.length)activeTerm=periods[0].term_no;
    const period=periods.find(p=>Number(p.term_no)===Number(activeTerm));
    const tabs=periods.map(p=>`<button class="term ${Number(p.term_no)===Number(activeTerm)?'active':''}" onclick="changeTerm(${p.term_no})">Term ${p.term_no}${p.is_active?'<span class="student-current">Current</span>':''}</button>`).join('');
    let assignments=[],subjects=[],teachers=[],records=[];
    if(period){
      assignments=await api(`/rest/v1/term_subjects?period_id=eq.${period.id}&section_id=eq.${st.section_id}&is_active=eq.true&select=id,subject_id,teacher_user_id,slot_no&order=slot_no.asc`);
      if(assignments.length){
        const subIds=[...new Set(assignments.map(a=>a.subject_id))];
        const teacherIds=[...new Set(assignments.map(a=>a.teacher_user_id).filter(Boolean))];
        const reqs=[
          api('/rest/v1/subjects?id=in.('+subIds.join(',')+')&select=id,subject_code,subject_name'),
          api('/rest/v1/subject_clearance_records?student_id=eq.'+st.id+'&term_subject_id=in.('+assignments.map(a=>a.id).join(',')+')&select=id,term_subject_id,status,remarks,updated_by,updated_at')
        ];
        if(teacherIds.length)reqs.push(api('/rest/v1/profiles?user_id=in.('+teacherIds.join(',')+')&role=eq.subject_teacher&is_active=eq.true&select=user_id,full_name'));
        const data=await Promise.all(reqs);subjects=data[0]||[];records=data[1]||[];teachers=data[2]||[];
      }
    }
    const sm=Object.fromEntries(subjects.map(s=>[s.id,s])),tm=Object.fromEntries(teachers.map(t=>[t.user_id,t])),rm=Object.fromEntries(records.map(r=>[r.term_subject_id,r]));
    const details=assignments.map(a=>({a,sub:sm[a.subject_id],teacher:tm[a.teacher_user_id],r:rm[a.id]||{status:'pending',remarks:null,updated_by:null,updated_at:null}}));
    const total=details.length,cleared=details.filter(x=>x.r.status==='cleared').length,pending=details.filter(x=>x.r.status==='pending').length,req=details.filter(x=>x.r.status==='with_requirement').length,pct=total?Math.round((cleared/total)*100):0;
    const fully=total>0&&cleared===total;
    $('dashboard').innerHTML=`
      <div class="card"><div class="student-id"><div><h2>Student Dashboard</h2><div class="muted">Subject Clearance</div><div class="student-meta"><span class="student-chip">LRN ${esc(st.lrn)}</span>${sec?`<span class="student-chip">Grade ${sec.grade_level} – ${esc(sec.section_name)}</span><span class="student-chip">SY ${esc(sec.school_year)}</span>`:''}</div></div></div></div>
      <div class="card"><h3>My Subject Clearances</h3><div class="term-tabs">${tabs}</div>${period?`<div class="student-term-note">Term ${period.term_no} • SY ${esc(period.school_year)}${period.is_active?' • Current term':''}<span class="student-term-state ${period.is_open?'student-term-open':'student-term-locked'}">${period.is_open?'Open':'Locked'}</span></div>`:''}
        <div class="row between"><div><b>${fully?'Term Clearance Complete':`${cleared} of ${total} subject${total===1?'':'s'} cleared`}</b><div class="muted">${total?pct+'% complete':'No subject assignments yet'}</div></div><div class="count">${pct}%</div></div>
        <div class="student-progress"><span style="width:${pct}%"></span></div>
        <div class="student-stats"><div class="student-stat"><b>${cleared}</b><span class="muted">Cleared</span></div><div class="student-stat"><b>${pending}</b><span class="muted">Pending</span></div><div class="student-stat"><b>${req}</b><span class="muted">Requirement</span></div></div>
      </div>
      <div class="card"><h3>Subjects</h3>${details.length?details.map(x=>`<div class="student-subject"><div class="student-subject-head"><div><div class="student-subject-name">${esc(x.sub?.subject_name||('Subject '+x.a.slot_no))}</div><div class="student-teacher">Slot ${x.a.slot_no}${x.sub?.subject_code?' • '+esc(x.sub.subject_code):''} • ${esc(x.teacher?.full_name||'Subject Teacher')}</div></div><span class="pill ${x.r.status}">${statusText(x.r.status)}</span></div>${x.r.remarks?`<div class="student-remarks ${x.r.status==='with_requirement'?'requirement':''}"><b>Teacher Remarks:</b> ${esc(x.r.remarks)}</div>`:''}${x.r.updated_by&&x.r.updated_at?`<div class="student-updated">Last updated ${esc(fmtDate(x.r.updated_at))}</div>`:''}</div>`).join(''):'<div class="empty">No subjects have been assigned for this term yet.</div>'}</div>`;
  }catch(e){$('dashboard').innerHTML=`<div class="card"><h2>Student Dashboard</h2><div class="msg error">${esc(e.message)}</div></div>`}
};
window.changeTerm=async function(n){activeTerm=Number(n);studentTermInitialized=true;await renderStudent()};
if(typeof profile!=='undefined'&&profile?.role==='student')renderStudent().catch(()=>{});
})();