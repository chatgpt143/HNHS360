(()=>{
const css=document.createElement('style');
css.textContent=`
.acct-filters{display:grid;grid-template-columns:1fr 1fr;gap:10px}.acct-search{margin-top:8px}.acct-badge{display:inline-flex;padding:5px 8px;border-radius:999px;font-size:10px;font-weight:800;text-transform:uppercase}.acct-active{background:#dff5e8;color:#17673f}.acct-inactive{background:#fde4e4;color:#962d2d}.acct-role{background:#e8f0fb;color:#285784}.acct-card{padding:13px 0;border-bottom:1px solid #edf0f4}.acct-card:last-child{border-bottom:0}.acct-top{display:flex;justify-content:space-between;gap:10px;align-items:flex-start}.acct-meta{display:flex;gap:6px;flex-wrap:wrap;margin-top:6px}.acct-actions{display:flex;gap:7px;flex-wrap:wrap;margin-top:10px}.acct-actions button{padding:9px 11px}.reactivatebtn{background:#e2f4e9;color:#16643f}.resetbtn{background:#eaf1fa;color:#0f3d75}.acct-count{font-size:12px;color:#6b778c;margin-top:8px}.acct-editor{border:2px solid #c8d8ec}.acct-note{background:#f4f7fb;border-radius:12px;padding:10px 12px;font-size:12px;color:#5e6f85;margin:10px 0}@media(max-width:620px){.acct-filters{grid-template-columns:1fr}}
`;
document.head.appendChild(css);

let acctState={role:'all',status:'active',search:''};
let adviserUtilitiesActive=false;
const baseAdminRenderAcct=renderAdmin;
const baseAdminPanelAcct=renderAdminPanel;
const baseAdvRenderAcct=renderAdviser;
const baseAdvSetTabAcct=window.setAdv360Tab;

async function acctCall(payload){return api('/functions/v1/account-utilities',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)})}
function acctRoleLabel(r){return r==='subject_teacher'?'Subject Teacher':r==='student'?'Learner':r==='adviser'?'Adviser':roleLabel(r)}
function acctMatchesStatus(active){return acctState.status==='all'||(acctState.status==='active'&&active)||(acctState.status==='inactive'&&!active)}
function acctSearchText(a){return [a.full_name,a.role,a.lrn,a.section_name,a.grade_level].filter(Boolean).join(' ').toLowerCase()}
function acctFiltersHtml(role,roles){return `<div class="card"><h3>Account Filters</h3><div class="acct-filters"><div class="field"><label>Account Type</label><select id="acctRole"><option value="all" ${acctState.role==='all'?'selected':''}>All Account Types</option>${roles.map(r=>`<option value="${r}" ${acctState.role===r?'selected':''}>${acctRoleLabel(r)}</option>`).join('')}</select></div><div class="field"><label>Account Status</label><select id="acctStatus"><option value="active" ${acctState.status==='active'?'selected':''}>Active</option><option value="inactive" ${acctState.status==='inactive'?'selected':''}>Inactive / Removed</option><option value="all" ${acctState.status==='all'?'selected':''}>All</option></select></div></div><div class="field acct-search"><label>Search</label><input id="acctSearch" value="${esc(acctState.search)}" placeholder="Search name, LRN, role, or section" onkeydown="if(event.key==='Enter')applyAccountUtilityFilters()"></div><div class="actions"><button class="primary" style="width:auto;flex:1" onclick="applyAccountUtilityFilters()">Apply Filters</button><button class="secondary" style="width:auto;flex:1;margin:0" onclick="resetAccountUtilityFilters()">Reset</button></div><div class="acct-note">Password reset changes the user's password immediately. Reactivate restores sign-in access while keeping all previous clearance history.</div></div>`}
function acctRowHtml(a,mode){const active=!!a.is_active;return `<div class="acct-card"><div class="acct-top"><div><div class="title">${esc(a.full_name)}</div><div class="muted">${a.role==='student'?`LRN ${esc(a.lrn||'')}${a.section_name?` • Grade ${a.grade_level} – ${esc(a.section_name)}`:''}`:esc(a.section_names||acctRoleLabel(a.role))}</div><div class="acct-meta"><span class="acct-badge acct-role">${acctRoleLabel(a.role)}</span><span class="acct-badge ${active?'acct-active':'acct-inactive'}">${active?'Active':'Inactive'}</span></div></div></div><div class="acct-actions"><button class="resetbtn" onclick="openAccountPasswordReset('${a.user_id}','${esc(a.full_name).replace(/'/g,"&#39;")}','${mode}')">Reset Password</button>${!active?`<button class="reactivatebtn" onclick="reactivateAccount('${a.user_id}','${esc(a.full_name).replace(/'/g,"&#39;")}','${mode}')">Reactivate</button>`:''}</div></div>`}

async function adminUtilityAccounts(){
  const [profiles,students,sections,assignments]=await Promise.all([
    api('/rest/v1/profiles?role=in.(adviser,subject_teacher,student)&select=user_id,full_name,role,is_active&order=full_name.asc'),
    api('/rest/v1/students?select=user_id,lrn,full_name,section_id,is_active'),
    api('/rest/v1/sections?select=id,grade_level,section_name,school_year'),
    api('/rest/v1/term_subjects?select=teacher_user_id,section_id&is_active=eq.true')
  ]);
  const sm=Object.fromEntries(sections.map(s=>[s.id,s]));
  const studentMap=Object.fromEntries(students.map(s=>[s.user_id,s]));
  return profiles.map(p=>{
    const st=studentMap[p.user_id];
    if(p.role==='student'){const sec=st?sm[st.section_id]:null;return {...p,lrn:st?.lrn||'',section_name:sec?.section_name||'',grade_level:sec?.grade_level||'',is_active:!!p.is_active&&!!st?.is_active}}
    const sids=[...new Set(assignments.filter(x=>x.teacher_user_id===p.user_id).map(x=>x.section_id))];
    const section_names=sids.map(id=>sm[id]).filter(Boolean).map(s=>`Grade ${s.grade_level} – ${s.section_name}`).join(', ');
    return {...p,section_names};
  });
}

async function adviserUtilityAccounts(){
  const asa=await api('/rest/v1/adviser_section_assignments?adviser_user_id=eq.'+profile.user_id+'&select=section_id');
  const ids=[...new Set(asa.map(x=>x.section_id))];if(!ids.length)return [];
  const [sections,students,assignments]=await Promise.all([
    api('/rest/v1/sections?id=in.('+ids.join(',')+')&select=id,grade_level,section_name,school_year'),
    api('/rest/v1/students?section_id=in.('+ids.join(',')+')&select=user_id,lrn,full_name,section_id,is_active&order=full_name.asc'),
    api('/rest/v1/term_subjects?section_id=in.('+ids.join(',')+')&is_active=eq.true&select=teacher_user_id,section_id')
  ]);
  const sm=Object.fromEntries(sections.map(s=>[s.id,s]));
  const learnerAccounts=students.map(st=>{const sec=sm[st.section_id];return {user_id:st.user_id,full_name:st.full_name,role:'student',is_active:!!st.is_active,lrn:st.lrn,section_name:sec?.section_name||'',grade_level:sec?.grade_level||''}});
  const tids=[...new Set(assignments.map(a=>a.teacher_user_id).filter(Boolean))];let profiles=[];
  if(tids.length)profiles=await api('/rest/v1/profiles?user_id=in.('+tids.join(',')+')&role=eq.subject_teacher&select=user_id,full_name,role,is_active&order=full_name.asc');
  const teachers=profiles.map(p=>{const sids=[...new Set(assignments.filter(x=>x.teacher_user_id===p.user_id).map(x=>x.section_id))];return {...p,section_names:sids.map(id=>sm[id]).filter(Boolean).map(s=>`Grade ${s.grade_level} – ${s.section_name}`).join(', ')}});
  return [...teachers,...learnerAccounts].sort((a,b)=>String(a.full_name).localeCompare(String(b.full_name)));
}

async function renderAccountUtilities(hostId,mode){
  const host=$(hostId);if(!host)return;
  host.innerHTML='<div class="card"><div class="empty">Loading accounts...</div></div>';
  try{
    const roles=mode==='admin'?['adviser','subject_teacher','student']:['subject_teacher','student'];
    const all=mode==='admin'?await adminUtilityAccounts():await adviserUtilityAccounts();
    let rows=all.filter(a=>(acctState.role==='all'||a.role===acctState.role)&&acctMatchesStatus(!!a.is_active));
    const q=acctState.search.trim().toLowerCase();if(q)rows=rows.filter(a=>acctSearchText(a).includes(q));
    const activeCount=all.filter(a=>a.is_active).length,inactiveCount=all.length-activeCount;
    host.innerHTML=`<div id="acctUtilEditor"></div>${acctFiltersHtml(mode,roles)}<div class="card"><div class="row between"><h3>${mode==='admin'?'Managed Accounts':'My Section Accounts'}</h3><div class="muted">${rows.length} shown</div></div><div class="acct-count">${activeCount} active • ${inactiveCount} inactive</div>${rows.length?rows.map(a=>acctRowHtml(a,mode)).join(''):'<div class="empty">No accounts match the selected filters.</div>'}</div>`;
  }catch(e){host.innerHTML=`<div class="card"><div class="msg error">${esc(e.message)}</div></div>`}
}

window.applyAccountUtilityFilters=async function(){acctState.role=$('acctRole')?.value||'all';acctState.status=$('acctStatus')?.value||'active';acctState.search=$('acctSearch')?.value.trim()||'';await renderAccountUtilities(profile.role==='admin'?'adminPanel':'advAcctUtilPanel',profile.role==='admin'?'admin':'adviser')};
window.resetAccountUtilityFilters=async function(){acctState={role:'all',status:'active',search:''};await renderAccountUtilities(profile.role==='admin'?'adminPanel':'advAcctUtilPanel',profile.role==='admin'?'admin':'adviser')};

window.openAccountPasswordReset=function(userId,name,mode){
  const host=$('acctUtilEditor');if(!host)return;
  host.innerHTML=`<div class="card acct-editor"><h3>Reset Password</h3><div class="muted">${esc(name)}</div><div id="acctResetMsg"></div><div class="field"><label>New Password</label><input id="acctNewPassword" type="password" placeholder="At least 8 characters"></div><div class="field"><label>Confirm New Password</label><input id="acctConfirmPassword" type="password" placeholder="Retype new password"></div><div class="actions"><button class="primary" style="width:auto;flex:1" onclick="saveAccountPasswordReset('${userId}','${mode}')">Reset Password</button><button class="secondary" style="width:auto;flex:1;margin:0" onclick="$('acctUtilEditor').innerHTML=''">Cancel</button></div></div>`;
  host.scrollIntoView({behavior:'smooth',block:'start'});
};
window.saveAccountPasswordReset=async function(userId,mode){showMsg('acctResetMsg','');try{const p=$('acctNewPassword').value,c=$('acctConfirmPassword').value;if(p.length<8)throw new Error('New password must be at least 8 characters.');if(p!==c)throw new Error('The two passwords do not match.');const d=await acctCall({action:'reset_password',user_id:userId,password:p});showMsg('acctResetMsg',d.message||'Password reset successfully.','success');$('acctNewPassword').value='';$('acctConfirmPassword').value=''}catch(e){showMsg('acctResetMsg',e.message)}};
window.reactivateAccount=async function(userId,name,mode){if(!confirm(`Reactivate ${name} and restore HNHS360 sign-in access?`))return;try{const d=await acctCall({action:'reactivate',user_id:userId});alert(d.message||'Account reactivated successfully.');await renderAccountUtilities(mode==='admin'?'adminPanel':'advAcctUtilPanel',mode)}catch(e){alert(e.message)}};

renderAdmin=async function(){
  $('dashboard').innerHTML=`<div class="card"><h2>Admin Dashboard</h2><div class="muted">Manage HNHS360 Subject Clearances.</div><div class="navtabs">${['overview','terms','reports','utilities','sections','accounts','students','subjects','assignments'].map(t=>`<button class="navtab ${adminTab===t?'active':''}" onclick="setAdminTab('${t}')">${t==='utilities'?'Account Utilities':t[0].toUpperCase()+t.slice(1)}</button>`).join('')}</div></div><div id="adminPanel"></div>`;
  await renderAdminPanel();
};
renderAdminPanel=async function(){if(adminTab==='utilities')return renderAccountUtilities('adminPanel','admin');return baseAdminPanelAcct()};

window.setAdv360Tab=async function(t){if(t==='utilities'){adviserUtilitiesActive=true;return renderAdviser()}adviserUtilitiesActive=false;return baseAdvSetTabAcct(t)};
renderAdviser=async function(){
  if(!adviserUtilitiesActive)return baseAdvRenderAcct();
  $('dashboard').innerHTML=`<div class="card"><h2>Adviser Dashboard</h2><div class="muted">Manage your assigned section(s), subject assignments, and clearance progress.</div><div class="adv360-tabs">${[['overview','Overview'],['assignments','Subject Assignments'],['clearance','Clearance Overview'],['reports','Reports'],['utilities','Account Utilities'],['teachers','Subject Teachers'],['learners','Learners']].map(x=>`<button class="${x[0]==='utilities'?'active':''}" onclick="setAdv360Tab('${x[0]}')">${x[1]}</button>`).join('')}</div></div><div id="advAcctUtilPanel"></div>`;
  await renderAccountUtilities('advAcctUtilPanel','adviser');
};

if(typeof profile!=='undefined'&&profile?.role==='admin'&&adminTab==='utilities')renderAccountUtilities('adminPanel','admin').catch(()=>{});
})();