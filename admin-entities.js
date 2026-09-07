(()=>{
let sectionRows=[],subjectRows=[],assignmentRows=[],assignmentPeriods=[],assignmentSections=[],assignmentSubjects=[],assignmentTeachers=[];

async function patchEntity(table,id,data){
  return api(`/rest/v1/${table}?id=eq.${id}`,{method:'PATCH',headers:{'Content-Type':'application/json',Prefer:'return=minimal'},body:JSON.stringify(data)});
}
function confirmRemove(text){return window.confirm(text)}

adminSections=async function(){
  sectionRows=await api('/rest/v1/sections?select=id,grade_level,section_name,school_year,is_active&is_active=eq.true&order=grade_level.asc,section_name.asc');
  $('adminPanel').innerHTML=`<div id="sectionEditor"></div><div class="card"><h3>Add Section</h3><div id="sectionMsg"></div><div class="grid2"><div class="field"><label>Grade Level</label><select id="secGrade"><option value="11">Grade 11</option><option value="12">Grade 12</option></select></div><div class="field"><label>School Year</label><input id="secSY" value="2026-2027"></div></div><div class="field"><label>Section Name</label><input id="secName" placeholder="e.g. Mercury"></div><button class="primary" onclick="createSection()">Add Section</button></div><div class="card"><h3>Sections</h3>${sectionRows.length?sectionRows.map(s=>`<div class="listrow"><div class="title">Grade ${s.grade_level} – ${esc(s.section_name)}</div><div class="muted">SY ${esc(s.school_year)}</div><div class="actions"><button class="editbtn" onclick="adminEditSection(${s.id})">Edit</button><button class="removebtn" onclick="adminRemoveSection(${s.id})">Remove</button></div></div>`).join(''):'<div class="empty">No active sections yet.</div>'}</div>`;
};

window.adminEditSection=function(id){
  const s=sectionRows.find(x=>x.id===id);if(!s)return;
  const host=$('sectionEditor');
  host.innerHTML=`<div class="card manage-editor"><h3>Edit Section</h3><div id="sectionEditMsg"></div><div class="grid2"><div class="field"><label>Grade Level</label><select id="editSecGrade"><option value="11" ${s.grade_level===11?'selected':''}>Grade 11</option><option value="12" ${s.grade_level===12?'selected':''}>Grade 12</option></select></div><div class="field"><label>School Year</label><input id="editSecSY" value="${esc(s.school_year)}"></div></div><div class="field"><label>Section Name</label><input id="editSecName" value="${esc(s.section_name)}"></div><div class="actions"><button class="primary" style="width:auto;flex:1" onclick="adminSaveSection(${id})">Save Changes</button><button class="secondary" style="width:auto;flex:1;margin:0" onclick="$('sectionEditor').innerHTML=''">Cancel</button></div></div>`;
  host.scrollIntoView({behavior:'smooth',block:'start'});
};
window.adminSaveSection=async function(id){
  showMsg('sectionEditMsg','');
  try{
    const grade_level=Number($('editSecGrade').value),section_name=$('editSecName').value.trim(),school_year=$('editSecSY').value.trim();
    if(!section_name||!school_year)throw new Error('Section name and school year are required.');
    await patchEntity('sections',id,{grade_level,section_name,school_year});
    showMsg('sectionEditMsg','Section updated successfully.','success');setTimeout(()=>adminSections(),400);
  }catch(e){showMsg('sectionEditMsg',e.message.includes('duplicate')?'An active section with those details already exists.':e.message)}
};
window.adminRemoveSection=async function(id){
  const s=sectionRows.find(x=>x.id===id);if(!s)return;
  try{
    const [students,assignments]=await Promise.all([
      api(`/rest/v1/students?section_id=eq.${id}&is_active=eq.true&select=id&limit=1`),
      api(`/rest/v1/term_subjects?section_id=eq.${id}&is_active=eq.true&select=id&limit=1`)
    ]);
    if(students.length||assignments.length){alert('This section cannot be removed yet. Move or remove its active learners and active subject assignments first.');return;}
    if(!confirmRemove(`Remove Grade ${s.grade_level} – ${s.section_name} from the active section list?`))return;
    await patchEntity('sections',id,{is_active:false});await adminSections();
  }catch(e){alert(e.message)}
};

adminSubjects=async function(){
  subjectRows=await api('/rest/v1/subjects?select=id,subject_code,subject_name,is_active&is_active=eq.true&order=subject_name.asc');
  $('adminPanel').innerHTML=`<div id="subjectEditor"></div><div class="card"><h3>Add Subject</h3><div id="subjectMsg"></div><div class="field"><label>Subject Code (optional)</label><input id="subCode" placeholder="e.g. PR2"></div><div class="field"><label>Subject Name</label><input id="subName" placeholder="e.g. Practical Research II"></div><button class="primary" onclick="createSubject()">Add Subject</button></div><div class="card"><h3>Subjects</h3>${subjectRows.length?subjectRows.map(s=>`<div class="listrow"><div class="title">${esc(s.subject_name)}</div><div class="muted">${esc(s.subject_code||'No code')}</div><div class="actions"><button class="editbtn" onclick="adminEditSubject(${s.id})">Edit</button><button class="removebtn" onclick="adminRemoveSubject(${s.id})">Remove</button></div></div>`).join(''):'<div class="empty">No active subjects yet.</div>'}</div>`;
};
window.adminEditSubject=function(id){
  const s=subjectRows.find(x=>x.id===id);if(!s)return;
  const host=$('subjectEditor');
  host.innerHTML=`<div class="card manage-editor"><h3>Edit Subject</h3><div id="subjectEditMsg"></div><div class="field"><label>Subject Code (optional)</label><input id="editSubCode" value="${esc(s.subject_code||'')}"></div><div class="field"><label>Subject Name</label><input id="editSubName" value="${esc(s.subject_name)}"></div><div class="actions"><button class="primary" style="width:auto;flex:1" onclick="adminSaveSubject(${id})">Save Changes</button><button class="secondary" style="width:auto;flex:1;margin:0" onclick="$('subjectEditor').innerHTML=''">Cancel</button></div></div>`;
  host.scrollIntoView({behavior:'smooth',block:'start'});
};
window.adminSaveSubject=async function(id){
  showMsg('subjectEditMsg','');
  try{
    const subject_name=$('editSubName').value.trim(),subject_code=$('editSubCode').value.trim()||null;if(!subject_name)throw new Error('Subject name is required.');
    await patchEntity('subjects',id,{subject_name,subject_code});showMsg('subjectEditMsg','Subject updated successfully.','success');setTimeout(()=>adminSubjects(),400);
  }catch(e){showMsg('subjectEditMsg',e.message.includes('duplicate')?'An active subject with that name already exists.':e.message)}
};
window.adminRemoveSubject=async function(id){
  const s=subjectRows.find(x=>x.id===id);if(!s)return;
  try{
    const assignments=await api(`/rest/v1/term_subjects?subject_id=eq.${id}&is_active=eq.true&select=id&limit=1`);
    if(assignments.length){alert('This subject cannot be removed while it is used in an active term assignment. Remove or change the assignment first.');return;}
    if(!confirmRemove(`Remove ${s.subject_name} from the active subject list?`))return;
    await patchEntity('subjects',id,{is_active:false});await adminSubjects();
  }catch(e){alert(e.message)}
};

adminAssignments=async function(){
  [assignmentPeriods,assignmentSections,assignmentSubjects,assignmentTeachers,assignmentRows]=await Promise.all([
    api('/rest/v1/clearance_periods?select=id,term_no,name,school_year,is_active&order=term_no.asc'),
    api('/rest/v1/sections?select=id,grade_level,section_name,school_year&is_active=eq.true&order=grade_level.asc,section_name.asc'),
    api('/rest/v1/subjects?select=id,subject_name&is_active=eq.true&order=subject_name.asc'),
    api('/rest/v1/profiles?select=user_id,full_name,role,is_active&role=eq.subject_teacher&is_active=eq.true&order=full_name.asc'),
    api('/rest/v1/term_subjects?select=id,period_id,section_id,subject_id,teacher_user_id,slot_no,is_active&is_active=eq.true&order=period_id.asc,section_id.asc,slot_no.asc')
  ]);
  const pm=Object.fromEntries(assignmentPeriods.map(x=>[x.id,x])),sm=Object.fromEntries(assignmentSections.map(x=>[x.id,x])),subm=Object.fromEntries(assignmentSubjects.map(x=>[x.id,x])),tm=Object.fromEntries(assignmentTeachers.map(x=>[x.user_id,x]));
  $('adminPanel').innerHTML=`<div id="assignmentEditor"></div><div class="card"><h3>Assign Subject for a Term</h3><div class="muted">Maximum: 6 subject slots per section per term.</div><div id="termAssignMsg"></div><div class="grid2"><div class="field"><label>Term</label><select id="taPeriod">${assignmentPeriods.map(p=>`<option value="${p.id}">Term ${p.term_no} – SY ${esc(p.school_year)}</option>`).join('')}</select></div><div class="field"><label>Slot</label><select id="taSlot">${[1,2,3,4,5,6].map(n=>`<option value="${n}">Subject ${n}</option>`).join('')}</select></div></div><div class="field"><label>Section</label><select id="taSection"><option value="">Select Section</option>${assignmentSections.map(s=>`<option value="${s.id}">Grade ${s.grade_level} – ${esc(s.section_name)}</option>`).join('')}</select></div><div class="field"><label>Subject</label><select id="taSubject"><option value="">Select Subject</option>${assignmentSubjects.map(s=>`<option value="${s.id}">${esc(s.subject_name)}</option>`).join('')}</select></div><div class="field"><label>Subject Teacher</label><select id="taTeacher"><option value="">Select Teacher</option>${assignmentTeachers.map(t=>`<option value="${t.user_id}">${esc(t.full_name)}</option>`).join('')}</select></div><button class="primary" onclick="createTermAssignment()">Save Assignment</button></div><div class="card"><h3>Current Term Assignments</h3>${assignmentRows.length?assignmentRows.map(a=>{const p=pm[a.period_id],s=sm[a.section_id],sub=subm[a.subject_id],t=tm[a.teacher_user_id];return `<div class="listrow"><div class="title">Term ${p?.term_no||'?'} • Slot ${a.slot_no} • ${esc(sub?.subject_name||'Unknown Subject')}</div><div class="muted">${s?`Grade ${s.grade_level} – ${esc(s.section_name)}`:'Unknown Section'} • ${esc(t?.full_name||'No Teacher')}</div><div class="actions"><button class="editbtn" onclick="adminEditAssignment(${a.id})">Edit</button><button class="removebtn" onclick="adminRemoveAssignment(${a.id})">Remove</button></div></div>`}).join(''):'<div class="empty">No active subject assignments yet.</div>'}</div>`;
};
window.adminEditAssignment=function(id){
  const a=assignmentRows.find(x=>x.id===id);if(!a)return;
  const p=assignmentPeriods.find(x=>x.id===a.period_id),s=assignmentSections.find(x=>x.id===a.section_id),sub=assignmentSubjects.find(x=>x.id===a.subject_id);
  const host=$('assignmentEditor');
  host.innerHTML=`<div class="card manage-editor"><h3>Edit Assignment</h3><div class="manage-note">To preserve existing clearance history, Term, Section, and Subject stay fixed. You can change the Subject Teacher and slot. To replace the Term/Section/Subject itself, remove this assignment and create a new one.</div><div id="assignmentEditMsg"></div><div class="module"><div class="title">Term ${p?.term_no||'?'} • ${esc(sub?.subject_name||'Subject')}</div><div class="muted">${s?`Grade ${s.grade_level} – ${esc(s.section_name)}`:'Section'}</div></div><div class="grid2"><div class="field"><label>Subject Slot</label><select id="editAssignSlot">${[1,2,3,4,5,6].map(n=>`<option value="${n}" ${n===a.slot_no?'selected':''}>Subject ${n}</option>`).join('')}</select></div><div class="field"><label>Subject Teacher</label><select id="editAssignTeacher">${assignmentTeachers.map(t=>`<option value="${t.user_id}" ${t.user_id===a.teacher_user_id?'selected':''}>${esc(t.full_name)}</option>`).join('')}</select></div></div><div class="actions"><button class="primary" style="width:auto;flex:1" onclick="adminSaveAssignment(${id})">Save Changes</button><button class="secondary" style="width:auto;flex:1;margin:0" onclick="$('assignmentEditor').innerHTML=''">Cancel</button></div></div>`;
  host.scrollIntoView({behavior:'smooth',block:'start'});
};
window.adminSaveAssignment=async function(id){
  showMsg('assignmentEditMsg','');
  try{
    const slot_no=Number($('editAssignSlot').value),teacher_user_id=$('editAssignTeacher').value;if(!teacher_user_id)throw new Error('Select a Subject Teacher.');
    await patchEntity('term_subjects',id,{slot_no,teacher_user_id});showMsg('assignmentEditMsg','Assignment updated successfully.','success');setTimeout(()=>adminAssignments(),400);
  }catch(e){showMsg('assignmentEditMsg',e.message.includes('duplicate')?'That subject slot is already being used for this section and term.':e.message)}
};
window.adminRemoveAssignment=async function(id){
  const a=assignmentRows.find(x=>x.id===id);if(!a)return;
  if(!confirmRemove('Remove this active subject assignment? Existing clearance history will be preserved.'))return;
  try{await patchEntity('term_subjects',id,{is_active:false});await adminAssignments()}catch(e){alert(e.message)}
};

if(typeof profile!=='undefined'&&profile?.role==='admin')renderAdmin().catch(()=>{});
})();