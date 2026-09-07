(()=>{
const style=document.createElement('style');
style.textContent=`.actions{display:flex;gap:7px;flex-wrap:wrap;margin-top:9px}.editbtn{background:#eaf1fa;color:#0f3d75;padding:8px 11px}.removebtn{background:#fdeaea;color:#9b2929;padding:8px 11px}.manage-editor{border:2px solid #c8d8ec}.manage-note{background:#f4f7fb;border-radius:12px;padding:10px 12px;font-size:12px;color:#5e6f85;margin:10px 0}.adviser-tabs{display:flex;gap:7px;margin:12px 0;overflow-x:auto}.adviser-tabs button{background:#eef3f9;color:#36506f;white-space:nowrap}.adviser-tabs button.active{background:#0f3d75;color:#fff}`;
document.head.appendChild(style);
let adviserTab='overview';

async function managedUser(payload){return api('/functions/v1/manage-hnhs360-user',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)})}
function safeConfirm(text){return window.confirm(text)}

window.adminEditStaff=async function(userId,role,name){
  const host=$('accountEditor');if(!host)return;
  host.innerHTML=`<div class="card manage-editor"><h3>Edit ${esc(roleLabel(role))}</h3><div id="staffEditMsg"></div><div class="field"><label>Full Name</label><input id="editStaffName" value="${esc(name)}"></div><div class="field"><label>New Email (optional)</label><input id="editStaffEmail" type="email" placeholder="Leave blank to keep current email"></div><div class="field"><label>New Password (optional)</label><input id="editStaffPass" type="password" placeholder="Leave blank to keep current password"></div><div class="actions"><button class="primary" style="width:auto;flex:1" onclick="adminSaveStaff('${userId}')">Save Changes</button><button class="secondary" style="width:auto;flex:1;margin:0" onclick="$('accountEditor').innerHTML=''">Cancel</button></div></div>`;
  host.scrollIntoView({behavior:'smooth',block:'start'});
};
window.adminSaveStaff=async function(userId){showMsg('staffEditMsg','');try{const d=await managedUser({action:'update',user_id:userId,full_name:$('editStaffName').value.trim(),email:$('editStaffEmail').value.trim(),password:$('editStaffPass').value});showMsg('staffEditMsg',d.message||'Updated.','success');setTimeout(()=>adminAccounts(),500)}catch(e){showMsg('staffEditMsg',e.message)}};
window.adminRemoveStaff=async function(userId,name){if(!safeConfirm(`Remove ${name} from active HNHS360 access? Historical records will be preserved.`))return;try{await managedUser({action:'remove',user_id:userId});await adminAccounts()}catch(e){alert(e.message)}};

adminAccounts=async function(){
  const [profiles,sections,asa]=await Promise.all([
    api('/rest/v1/profiles?select=user_id,full_name,role,is_active&is_active=eq.true&order=full_name.asc'),
    api('/rest/v1/sections?select=id,grade_level,section_name,school_year&is_active=eq.true&order=grade_level.asc,section_name.asc'),
    api('/rest/v1/adviser_section_assignments?select=adviser_user_id,section_id')
  ]);
  const advisers=profiles.filter(p=>p.role==='adviser'),teachers=profiles.filter(p=>p.role==='subject_teacher');
  const secMap=Object.fromEntries(sections.map(s=>[s.id,s]));
  $('adminPanel').innerHTML=`<div id="accountEditor"></div><div class="card"><h3>Create Staff Account</h3><div id="accountMsg"></div><div class="field"><label>Role</label><select id="accRole"><option value="adviser">Adviser</option><option value="subject_teacher">Subject Teacher</option></select></div><div class="field"><label>Full Name</label><input id="accName" placeholder="Teacher full name"></div><div class="field"><label>Email</label><input id="accEmail" type="email" placeholder="teacher@example.com"></div><div class="field"><label>Temporary Password</label><input id="accPass" type="password" placeholder="At least 8 characters"></div><button class="primary" onclick="createStaffAccount()">Create Account</button></div><div class="card"><h3>Assign Adviser to Section</h3><div id="adviserAssignMsg"></div><div class="field"><label>Adviser</label><select id="adviserUser"><option value="">Select Adviser</option>${advisers.map(a=>`<option value="${a.user_id}">${esc(a.full_name)}</option>`).join('')}</select></div><div class="field"><label>Section</label><select id="adviserSection"><option value="">Select Section</option>${sections.map(s=>`<option value="${s.id}">Grade ${s.grade_level} – ${esc(s.section_name)}</option>`).join('')}</select></div><button class="primary" onclick="assignAdviser()">Assign Adviser</button>${asa.length?`<div class="divider"></div>${asa.map(x=>{const a=advisers.find(v=>v.user_id===x.adviser_user_id),s=secMap[x.section_id];return a&&s?`<div class="listrow"><div class="title">${esc(a.full_name)}</div><div class="muted">Grade ${s.grade_level} – ${esc(s.section_name)}</div></div>`:''}).join('')}`:''}</div><div class="card"><h3>Staff Accounts</h3>${[...advisers,...teachers].length?[...advisers,...teachers].map(p=>`<div class="listrow"><div class="title">${esc(p.full_name)}</div><div class="muted">${roleLabel(p.role)}</div><div class="actions"><button class="editbtn" onclick="adminEditStaff('${p.user_id}','${p.role}','${esc(p.full_name).replace(/'/g,"&#39;")}')">Edit</button><button class="removebtn" onclick="adminRemoveStaff('${p.user_id}','${esc(p.full_name).replace(/'/g,"&#39;")}')">Remove</button></div></div>`).join(''):'<div class="empty">No Adviser or Subject Teacher accounts yet.</div>'}</div>`;
};

window.editLearnerAccount=async function(userId,name,lrn,sectionId,mode='admin'){
  const sections=mode==='adviser'?await getAdviserSections():await api('/rest/v1/sections?select=id,grade_level,section_name&is_active=eq.true&order=grade_level.asc,section_name.asc');
  const host=$(mode==='adviser'?'adviserEditor':'studentEditor');if(!host)return;
  host.innerHTML=`<div class="card manage-editor"><h3>Edit Learner</h3><div id="learnerEditMsg"></div><div class="field"><label>Full Name</label><input id="editLearnerName" value="${esc(name)}"></div><div class="field"><label>LRN</label><input id="editLearnerLrn" maxlength="12" inputmode="numeric" value="${esc(lrn)}"></div><div class="field"><label>Section</label><select id="editLearnerSection">${sections.map(s=>`<option value="${s.id}" ${Number(s.id)===Number(sectionId)?'selected':''}>Grade ${s.grade_level} – ${esc(s.section_name)}</option>`).join('')}</select></div><div class="field"><label>New Password (optional)</label><input id="editLearnerPass" type="password" placeholder="Leave blank to keep current password"></div><div class="actions"><button class="primary" style="width:auto;flex:1" onclick="saveLearnerEdit('${userId}','${mode}')">Save Changes</button><button class="secondary" style="width:auto;flex:1;margin:0" onclick="$('${mode==='adviser'?'adviserEditor':'studentEditor'}').innerHTML=''">Cancel</button></div></div>`;
  host.scrollIntoView({behavior:'smooth',block:'start'});
};
window.saveLearnerEdit=async function(userId,mode){showMsg('learnerEditMsg','');try{const d=await managedUser({action:'update',user_id:userId,full_name:$('editLearnerName').value.trim(),lrn:$('editLearnerLrn').value.trim(),section_id:Number($('editLearnerSection').value),password:$('editLearnerPass').value});showMsg('learnerEditMsg',d.message||'Updated.','success');setTimeout(()=>mode==='adviser'?renderAdviser():adminStudents(),500)}catch(e){showMsg('learnerEditMsg',e.message)}};
window.removeLearnerAccount=async function(userId,name,mode='admin'){if(!safeConfirm(`Remove ${name} from active HNHS360 access? Historical records will be preserved.`))return;try{await managedUser({action:'remove',user_id:userId});mode==='adviser'?await renderAdviser():await adminStudents()}catch(e){alert(e.message)}};

adminStudents=async function(){
  const [sections,students]=await Promise.all([
    api('/rest/v1/sections?select=id,grade_level,section_name,school_year&is_active=eq.true&order=grade_level.asc,section_name.asc'),
    api('/rest/v1/students?select=id,user_id,lrn,full_name,section_id,is_active&is_active=eq.true&order=full_name.asc')
  ]);
  const secMap=Object.fromEntries(sections.map(s=>[s.id,s]));
  $('adminPanel').innerHTML=`<div id="studentEditor"></div><div class="card"><h3>Add Student</h3><div class="muted">Students sign in using their 12-digit LRN and the password you create here.</div><div id="studentMsg"></div><div class="field"><label>Full Name</label><input id="stuName" placeholder="Learner full name"></div><div class="field"><label>LRN</label><input id="stuLrn" inputmode="numeric" maxlength="12" placeholder="12-digit LRN"></div><div class="field"><label>Section</label><select id="stuSection"><option value="">Select Section</option>${sections.map(s=>`<option value="${s.id}">Grade ${s.grade_level} – ${esc(s.section_name)}</option>`).join('')}</select></div><div class="field"><label>Initial Password</label><input id="stuPass" type="password" placeholder="At least 8 characters"></div><button class="primary" onclick="createStudent()">Create Student Account</button></div><div class="card"><h3>Learners</h3>${students.length?students.map(s=>{const sec=secMap[s.section_id];return `<div class="listrow"><div class="title">${esc(s.full_name)}</div><div class="muted">LRN ${esc(s.lrn)}${sec?` • Grade ${sec.grade_level} – ${esc(sec.section_name)}`:''}</div><div class="actions"><button class="editbtn" onclick="editLearnerAccount('${s.user_id}','${esc(s.full_name).replace(/'/g,"&#39;")}','${s.lrn}',${s.section_id},'admin')">Edit</button><button class="removebtn" onclick="removeLearnerAccount('${s.user_id}','${esc(s.full_name).replace(/'/g,"&#39;")}','admin')">Remove</button></div></div>`}).join(''):'<div class="empty">No active learners yet.</div>'}</div>`;
};

async function getAdviserSections(){
  const a=await api('/rest/v1/adviser_section_assignments?adviser_user_id=eq.'+profile.user_id+'&select=section_id');
  const ids=a.map(x=>x.section_id);if(!ids.length)return [];
  return api('/rest/v1/sections?id=in.('+ids.join(',')+')&select=id,grade_level,section_name,school_year&is_active=eq.true&order=grade_level.asc,section_name.asc');
}
window.setAdviserTab=async t=>{adviserTab=t;await renderAdviser()};
window.adviserEditTeacher=function(userId,name){const host=$('adviserEditor');host.innerHTML=`<div class="card manage-editor"><h3>Edit Subject Teacher</h3><div class="manage-note">If this teacher is also assigned to another Adviser's section, only the Admin can edit the account.</div><div id="teacherEditMsg"></div><div class="field"><label>Full Name</label><input id="advTeacherName" value="${esc(name)}"></div><div class="field"><label>New Password (optional)</label><input id="advTeacherPass" type="password" placeholder="Leave blank to keep current password"></div><div class="actions"><button class="primary" style="width:auto;flex:1" onclick="adviserSaveTeacher('${userId}')">Save Changes</button><button class="secondary" style="width:auto;flex:1;margin:0" onclick="$('adviserEditor').innerHTML=''">Cancel</button></div></div>`;host.scrollIntoView({behavior:'smooth',block:'start'})};
window.adviserSaveTeacher=async function(userId){showMsg('teacherEditMsg','');try{const d=await managedUser({action:'update',user_id:userId,full_name:$('advTeacherName').value.trim(),password:$('advTeacherPass').value});showMsg('teacherEditMsg',d.message||'Updated.','success');setTimeout(()=>renderAdviser(),500)}catch(e){showMsg('teacherEditMsg',e.message)}};
window.adviserRemoveTeacher=async function(userId,name){if(!safeConfirm(`Remove ${name} from active HNHS360 access?`))return;try{await managedUser({action:'remove',user_id:userId});await renderAdviser()}catch(e){alert(e.message)}};

renderAdviser=async function(){
  try{
    const sections=await getAdviserSections();const ids=sections.map(s=>s.id);
    let students=[],assignments=[],teachers=[];
    if(ids.length){
      [students,assignments]=await Promise.all([
        api('/rest/v1/students?section_id=in.('+ids.join(',')+')&is_active=eq.true&select=id,user_id,lrn,full_name,section_id&order=full_name.asc'),
        api('/rest/v1/term_subjects?section_id=in.('+ids.join(',')+')&is_active=eq.true&select=id,section_id,teacher_user_id,subject_id,period_id')
      ]);
      const tids=[...new Set(assignments.map(x=>x.teacher_user_id).filter(Boolean))];
      if(tids.length)teachers=await api('/rest/v1/profiles?user_id=in.('+tids.join(',')+')&role=eq.subject_teacher&is_active=eq.true&select=user_id,full_name,role');
    }
    const sm=Object.fromEntries(sections.map(s=>[s.id,s]));
    $('dashboard').innerHTML=`<div class="card"><h2>Adviser Dashboard</h2><div class="muted">Manage Subject Teachers and Learners only for your assigned section(s).</div><div class="adviser-tabs"><button class="${adviserTab==='overview'?'active':''}" onclick="setAdviserTab('overview')">Overview</button><button class="${adviserTab==='teachers'?'active':''}" onclick="setAdviserTab('teachers')">Subject Teachers</button><button class="${adviserTab==='learners'?'active':''}" onclick="setAdviserTab('learners')">Learners</button></div></div><div id="adviserEditor"></div><div id="adviserPanel"></div>`;
    const panel=$('adviserPanel');
    if(adviserTab==='teachers'){
      panel.innerHTML=`<div class="card"><h3>Subject Teachers</h3><div class="manage-note">You can manage teachers assigned to your section(s). If a teacher also handles another Adviser's section, Admin management is required.</div>${teachers.length?teachers.map(t=>{const own=assignments.filter(a=>a.teacher_user_id===t.user_id);const secNames=[...new Set(own.map(a=>sm[a.section_id]).filter(Boolean).map(s=>`Grade ${s.grade_level} – ${s.section_name}`))].join(', ');return `<div class="listrow"><div class="title">${esc(t.full_name)}</div><div class="muted">${esc(secNames||'Assigned Subject Teacher')}</div><div class="actions"><button class="editbtn" onclick="adviserEditTeacher('${t.user_id}','${esc(t.full_name).replace(/'/g,"&#39;")}')">Edit</button><button class="removebtn" onclick="adviserRemoveTeacher('${t.user_id}','${esc(t.full_name).replace(/'/g,"&#39;")}')">Remove</button></div></div>`}).join(''):'<div class="empty">No Subject Teachers are assigned to your section(s).</div>'}</div>`;
    }else if(adviserTab==='learners'){
      panel.innerHTML=`<div class="card"><h3>Learners</h3>${students.length?students.map(s=>{const sec=sm[s.section_id];return `<div class="listrow"><div class="title">${esc(s.full_name)}</div><div class="muted">LRN ${esc(s.lrn)}${sec?` • Grade ${sec.grade_level} – ${esc(sec.section_name)}`:''}</div><div class="actions"><button class="editbtn" onclick="editLearnerAccount('${s.user_id}','${esc(s.full_name).replace(/'/g,"&#39;")}','${s.lrn}',${s.section_id},'adviser')">Edit</button><button class="removebtn" onclick="removeLearnerAccount('${s.user_id}','${esc(s.full_name).replace(/'/g,"&#39;")}','adviser')">Remove</button></div></div>`}).join(''):'<div class="empty">No active learners in your section(s).</div>'}</div>`;
    }else{
      panel.innerHTML=`<div class="card"><h3>Assigned Sections</h3>${sections.length?sections.map(s=>`<div class="module"><div class="title">Grade ${s.grade_level} – ${esc(s.section_name)}</div><div class="muted">SY ${esc(s.school_year)}</div></div>`).join(''):'<div class="empty">No section has been assigned yet.</div>'}</div><div class="card"><div class="stats"><div class="stat"><div class="count">${students.length}</div><div class="muted">Learners</div></div><div class="stat"><div class="count">${teachers.length}</div><div class="muted">Subject Teachers</div></div><div class="stat"><div class="count">${assignments.length}</div><div class="muted">Subject Assignments</div></div></div></div>`;
    }
  }catch(e){$('dashboard').innerHTML=`<div class="card"><h2>Adviser Dashboard</h2><div class="msg error">${esc(e.message)}</div></div>`}
};

// Re-render the current role after this enhancement script loads.
if(typeof profile!=='undefined'&&profile){
  if(profile.role==='admin')renderAdmin().catch(()=>{});
  if(profile.role==='adviser')renderAdviser().catch(()=>{});
}
})();