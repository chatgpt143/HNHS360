(()=>{
const css=document.createElement('style');
css.textContent=`
.termctl-card{border:1px solid #dce4ef;border-radius:16px;padding:15px;margin-top:10px}.termctl-head{display:flex;justify-content:space-between;align-items:flex-start;gap:10px}.termctl-badges{display:flex;gap:6px;flex-wrap:wrap;justify-content:flex-end}.termctl-badge{display:inline-flex;padding:5px 8px;border-radius:999px;font-size:10px;font-weight:800;text-transform:uppercase}.termctl-current{background:#dfeaff;color:#174d92}.termctl-open{background:#dff5e8;color:#17673f}.termctl-locked{background:#fde4e4;color:#962d2d}.termctl-actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}.termctl-actions button{flex:1;min-width:130px}.termctl-note{background:#f4f7fb;border-radius:12px;padding:11px 12px;font-size:12px;color:#5e6f85;margin-top:12px}.termctl-warning{background:#fff6dd;color:#7d5700;border-radius:12px;padding:11px 12px;font-size:12px;margin-top:10px}`;
document.head.appendChild(css);

const baseAdminPanel=renderAdminPanel;
const baseAdminSections=adminSections;
const baseAdvAdd=window.adv360AddAssignment;
const baseAdvSave=window.adv360SaveAssignment;
const baseAdvRemove=window.adv360RemoveAssignment;

async function tcPatch(path,row){return api('/rest/v1/'+path,{method:'PATCH',headers:{'Content-Type':'application/json',Prefer:'return=minimal'},body:JSON.stringify(row)})}
async function tcPeriod(id){const r=await api('/rest/v1/clearance_periods?id=eq.'+id+'&select=id,term_no,is_open,is_active,school_year');return r[0]||null}
function tcFmt(v){if(!v)return'';try{return new Intl.DateTimeFormat('en-PH',{year:'numeric',month:'short',day:'numeric',hour:'numeric',minute:'2-digit'}).format(new Date(v))}catch{return''}}

renderAdmin=async function(){
  $('dashboard').innerHTML=`<div class="card"><h2>Admin Dashboard</h2><div class="muted">Manage HNHS360 Subject Clearances.</div><div class="navtabs">${['overview','terms','sections','accounts','students','subjects','assignments'].map(t=>`<button class="navtab ${adminTab===t?'active':''}" onclick="setAdminTab('${t}')">${t[0].toUpperCase()+t.slice(1)}</button>`).join('')}</div></div><div id="adminPanel"></div>`;
  await renderAdminPanel();
};

renderAdminPanel=async function(){if(adminTab==='terms')return adminTermControl();return baseAdminPanel()};

adminSections=async function(){
  await baseAdminSections();
  try{const c=await api('/rest/v1/app_config?config_key=eq.current_school_year&select=config_value');if($('secSY')&&c[0]?.config_value)$('secSY').value=c[0].config_value}catch{}
};

window.adminTermControl=async function(){
  try{
    const [periods,cfg]=await Promise.all([
      api('/rest/v1/clearance_periods?select=id,term_no,name,school_year,is_active,is_open,opens_at,closes_at&order=term_no.asc'),
      api('/rest/v1/app_config?config_key=eq.current_school_year&select=config_value')
    ]);
    const sy=cfg[0]?.config_value||periods.find(p=>p.is_active)?.school_year||'';
    $('adminPanel').innerHTML=`<div class="card"><h3>School Year</h3><div id="termSyMsg"></div><div class="field"><label>Current School Year</label><input id="termSchoolYear" value="${esc(sy)}" placeholder="2026-2027"></div><button class="primary" onclick="saveCurrentSchoolYear()">Save School Year</button><div class="termctl-note">This updates the school year used by Term 1, Term 2, and Term 3. Existing section records keep their own school-year value.</div></div><div class="card"><h3>Term Control</h3><div id="termControlMsg"></div><div class="muted">Set the current term and control whether clearance editing is open or locked.</div>${periods.map(p=>`<div class="termctl-card"><div class="termctl-head"><div><div class="title">Term ${p.term_no}</div><div class="muted">${esc(p.name)} • SY ${esc(p.school_year)}</div>${p.opens_at?`<div class="hint">Opened: ${esc(tcFmt(p.opens_at))}</div>`:''}${p.closes_at?`<div class="hint">Last closed: ${esc(tcFmt(p.closes_at))}</div>`:''}</div><div class="termctl-badges">${p.is_active?'<span class="termctl-badge termctl-current">Current</span>':''}<span class="termctl-badge ${p.is_open?'termctl-open':'termctl-locked'}">${p.is_open?'Open':'Locked'}</span></div></div><div class="termctl-actions"><button class="smallbtn" ${p.is_active?'disabled':''} onclick="setCurrentClearanceTerm(${p.id},${p.term_no})">${p.is_active?'Current Term':'Set as Current'}</button><button class="${p.is_open?'removebtn':'editbtn'}" onclick="toggleClearanceTerm(${p.id},${p.term_no},${p.is_open})">${p.is_open?'Close & Lock':'Open Term'}</button></div></div>`).join('')}<div class="termctl-warning"><b>When a term is locked:</b> Subject Teachers cannot change clearance status or remarks, and Advisers cannot add/edit/remove subject assignments for that term. Students can still view their results.</div></div>`;
  }catch(e){$('adminPanel').innerHTML=`<div class="card"><h3>Term Control</h3><div class="msg error">${esc(e.message)}</div></div>`}
};

window.setCurrentClearanceTerm=async function(id,termNo){
  if(!confirm(`Set Term ${termNo} as the current HNHS360 term?`))return;
  showMsg('termControlMsg','');
  try{
    await tcPatch('clearance_periods?is_active=eq.true',{is_active:false});
    await tcPatch('clearance_periods?id=eq.'+id,{is_active:true});
    showMsg('termControlMsg',`Term ${termNo} is now the current term.`,'success');
    await adminTermControl();
  }catch(e){showMsg('termControlMsg',e.message)}
};

window.toggleClearanceTerm=async function(id,termNo,isOpen){
  const action=isOpen?'close and lock':'open';
  if(!confirm(`${action[0].toUpperCase()+action.slice(1)} Term ${termNo}?`))return;
  showMsg('termControlMsg','');
  try{
    const now=new Date().toISOString();
    await tcPatch('clearance_periods?id=eq.'+id,isOpen?{is_open:false,closes_at:now}:{is_open:true,opens_at:now,closes_at:null});
    await adminTermControl();
  }catch(e){showMsg('termControlMsg',e.message)}
};

window.saveCurrentSchoolYear=async function(){
  showMsg('termSyMsg','');
  try{
    const sy=($('termSchoolYear')?.value||'').trim();
    const m=sy.match(/^(\d{4})-(\d{4})$/);if(!m||Number(m[2])!==Number(m[1])+1)throw new Error('Use school year format YYYY-YYYY, for example 2026-2027.');
    if(!confirm(`Change the HNHS360 current school year to ${sy}?`))return;
    await tcPatch('app_config?config_key=eq.current_school_year',{config_value:sy,updated_at:new Date().toISOString()});
    await tcPatch('clearance_periods?id=gt.0',{school_year:sy});
    showMsg('termSyMsg','School year updated successfully.','success');
    setTimeout(()=>adminTermControl(),350);
  }catch(e){showMsg('termSyMsg',e.message)}
};

async function tcEnsureOpenForAssignment(termSubjectId){
  const a=await api('/rest/v1/term_subjects?id=eq.'+termSubjectId+'&select=period_id');if(!a.length)return true;
  const p=await tcPeriod(a[0].period_id);if(p&&!p.is_open){alert(`Term ${p.term_no} is locked. Ask the Admin to open the term before changing subject assignments.`);return false}return true;
}
if(baseAdvAdd)window.adv360AddAssignment=async function(){const id=Number($('advAssignTerm')?.value);if(id){const p=await tcPeriod(id);if(p&&!p.is_open){alert(`Term ${p.term_no} is locked. Ask the Admin to open it first.`);return}}return baseAdvAdd()};
if(baseAdvSave)window.adv360SaveAssignment=async function(id){if(!(await tcEnsureOpenForAssignment(id)))return;return baseAdvSave(id)};
if(baseAdvRemove)window.adv360RemoveAssignment=async function(id,name){if(!(await tcEnsureOpenForAssignment(id)))return;return baseAdvRemove(id,name)};

if(typeof profile!=='undefined'&&profile?.role==='admin'&&adminTab==='terms')adminTermControl().catch(()=>{});
})();