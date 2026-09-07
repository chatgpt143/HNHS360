(()=>{
const css=document.createElement('style');
css.textContent=`.teacher-class{cursor:pointer}.teacher-class:hover{border-color:#a8bfdc;background:#fbfdff}.teacher-student{padding:15px;border:1px solid #dce4ef;border-radius:15px;margin-top:10px}.teacher-student .field{margin:9px 0}.teacher-search{margin:12px 0}.backbtn{background:#eaf1fa;color:#0f3d75;width:100%;margin-bottom:10px}.teacher-summary{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin:12px 0}.teacher-summary>div{border:1px solid #dce4ef;border-radius:12px;padding:10px;text-align:center}.teacher-summary b{display:block;font-size:20px;color:#0f3d75}@media(max-width:520px){.teacher-summary{grid-template-columns:1fr 1fr 1fr}}`;
document.head.appendChild(css);

async function teacherAssignments(){
  return api('/rest/v1/term_subjects?teacher_user_id=eq.'+profile.user_id+'&is_active=eq.true&select=id,period_id,section_id,subject_id,slot_no&order=period_id.asc,section_id.asc,slot_no.asc');
}

renderTeacher=async function(){
  try{
    const ts=await teacherAssignments();
    if(!ts.length){
      $('dashboard').innerHTML='<div class="card"><h2>Subject Teacher Dashboard</h2><div class="muted">You can update only your assigned subject clearances.</div></div><div class="card"><div class="empty">No subject assignment yet.</div></div>';
      return;
    }
    const pids=[...new Set(ts.map(x=>x.period_id))],sids=[...new Set(ts.map(x=>x.section_id))],subids=[...new Set(ts.map(x=>x.subject_id))];
    const [periods,sections,subjects]=await Promise.all([
      api('/rest/v1/clearance_periods?id=in.('+pids.join(',')+')&select=id,term_no,school_year,name,is_active'),
      api('/rest/v1/sections?id=in.('+sids.join(',')+')&select=id,grade_level,section_name,school_year'),
      api('/rest/v1/subjects?id=in.('+subids.join(',')+')&select=id,subject_name,subject_code')
    ]);
    const pm=Object.fromEntries(periods.map(x=>[x.id,x])),sm=Object.fromEntries(sections.map(x=>[x.id,x])),subm=Object.fromEntries(subjects.map(x=>[x.id,x]));
    $('dashboard').innerHTML=`<div class="card"><h2>Subject Teacher Dashboard</h2><div class="muted">Open an assigned class to update learner clearance status and remarks.</div></div><div class="card"><h3>Assigned Classes</h3>${ts.map(x=>{const p=pm[x.period_id],s=sm[x.section_id],sub=subm[x.subject_id];return `<div class="module teacher-class" onclick="teacherOpenClass(${x.id})"><div class="row between"><div><div class="title">${esc(sub?.subject_name||'Subject')}</div><div class="muted">${s?`Grade ${s.grade_level} – ${esc(s.section_name)}`:'Section'} • Term ${p?.term_no||'?'} • Slot ${x.slot_no}</div></div><button class="smallbtn" onclick="event.stopPropagation();teacherOpenClass(${x.id})">Open</button></div></div>`}).join('')}</div>`;
  }catch(e){$('dashboard').innerHTML=`<div class="card"><h2>Subject Teacher Dashboard</h2><div class="msg error">${esc(e.message)}</div></div>`}
};

window.teacherOpenClass=async function(termSubjectId){
  try{
    const rows=await api('/rest/v1/term_subjects?id=eq.'+termSubjectId+'&teacher_user_id=eq.'+profile.user_id+'&select=id,period_id,section_id,subject_id,slot_no');
    if(!rows.length)throw new Error('This subject assignment is not available to your account.');
    const a=rows[0];
    const [periods,sections,subjects,students,records]=await Promise.all([
      api('/rest/v1/clearance_periods?id=eq.'+a.period_id+'&select=id,term_no,school_year,name'),
      api('/rest/v1/sections?id=eq.'+a.section_id+'&select=id,grade_level,section_name,school_year'),
      api('/rest/v1/subjects?id=eq.'+a.subject_id+'&select=id,subject_name,subject_code'),
      api('/rest/v1/students?section_id=eq.'+a.section_id+'&is_active=eq.true&select=id,lrn,full_name&order=full_name.asc'),
      api('/rest/v1/subject_clearance_records?term_subject_id=eq.'+termSubjectId+'&select=id,student_id,status,remarks,updated_at')
    ]);
    const p=periods[0],s=sections[0],sub=subjects[0],rm=Object.fromEntries(records.map(r=>[r.student_id,r]));
    const counts={pending:0,cleared:0,with_requirement:0};records.forEach(r=>{if(counts[r.status]!==undefined)counts[r.status]++});
    $('dashboard').innerHTML=`<button class="backbtn" onclick="renderTeacher()">← Back to Assigned Classes</button><div class="card"><h2>${esc(sub?.subject_name||'Subject')}</h2><div class="muted">Grade ${s?.grade_level||''} – ${esc(s?.section_name||'')} • Term ${p?.term_no||''} • SY ${esc(p?.school_year||'')}</div><div class="teacher-summary"><div><b>${counts.cleared}</b><span class="muted">Cleared</span></div><div><b>${counts.pending}</b><span class="muted">Pending</span></div><div><b>${counts.with_requirement}</b><span class="muted">Requirement</span></div></div><div class="field teacher-search"><label>Search Learner</label><input id="teacherSearch" placeholder="Type learner name or LRN" oninput="teacherFilterStudents()"></div></div><div class="card"><h3>Learners (${students.length})</h3>${students.length?students.map(st=>{const r=rm[st.id];if(!r)return `<div class="teacher-student" data-search="${esc((st.full_name+' '+st.lrn).toLowerCase())}"><div class="title">${esc(st.full_name)}</div><div class="muted">LRN ${esc(st.lrn)}</div><div class="msg error">Clearance record is not available. Please ask the Admin to re-save the subject assignment.</div></div>`;return `<div class="teacher-student" data-search="${esc((st.full_name+' '+st.lrn).toLowerCase())}"><div class="row between"><div><div class="title">${esc(st.full_name)}</div><div class="muted">LRN ${esc(st.lrn)}</div></div><span id="pill-${r.id}" class="pill ${r.status}">${esc(r.status.replaceAll('_',' '))}</span></div><div id="saveMsg-${r.id}"></div><div class="field"><label>Status</label><select id="status-${r.id}"><option value="pending" ${r.status==='pending'?'selected':''}>Pending</option><option value="cleared" ${r.status==='cleared'?'selected':''}>Cleared</option><option value="with_requirement" ${r.status==='with_requirement'?'selected':''}>With Requirement</option></select></div><div class="field"><label>Remarks</label><textarea id="remarks-${r.id}" placeholder="Example: Submit Performance Task 2">${esc(r.remarks||'')}</textarea></div><button class="primary" onclick="teacherSaveClearance(${r.id},${termSubjectId})">Save Clearance</button></div>`}).join(''):'<div class="empty">No active learners in this section.</div>'}</div>`;
  }catch(e){$('dashboard').innerHTML=`<button class="backbtn" onclick="renderTeacher()">← Back</button><div class="card"><div class="msg error">${esc(e.message)}</div></div>`}
};

window.teacherSaveClearance=async function(recordId,termSubjectId){
  showMsg('saveMsg-'+recordId,'');
  try{
    const status=$('status-'+recordId).value,remarks=$('remarks-'+recordId).value.trim();
    await api('/rest/v1/subject_clearance_records?id=eq.'+recordId,{method:'PATCH',headers:{'Content-Type':'application/json',Prefer:'return=minimal'},body:JSON.stringify({status,remarks:remarks||null,updated_by:profile.user_id,updated_at:new Date().toISOString()})});
    showMsg('saveMsg-'+recordId,'Saved successfully.','success');
    const pill=$('pill-'+recordId);if(pill){pill.className='pill '+status;pill.textContent=status.replaceAll('_',' ')}
    setTimeout(()=>teacherOpenClass(termSubjectId),550);
  }catch(e){showMsg('saveMsg-'+recordId,e.message)}
};

window.teacherFilterStudents=function(){
  const q=($('teacherSearch')?.value||'').trim().toLowerCase();
  document.querySelectorAll('.teacher-student').forEach(el=>{el.style.display=!q||String(el.dataset.search||'').includes(q)?'block':'none'});
};

if(typeof profile!=='undefined'&&profile?.role==='subject_teacher')renderTeacher().catch(()=>{});
})();