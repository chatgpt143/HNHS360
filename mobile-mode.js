(()=>{
const isMobileApp=new URLSearchParams(location.search).get('mobile')==='1'||navigator.userAgent.includes('HNHS360Android');
if(!isMobileApp)return;

const allowedRoles=new Set(['student','subject_teacher']);
const baseRenderDashboard=renderDashboard;

function revealMobile(){document.documentElement.classList.remove('mobile-shell')}
function mobileBlocked(){
  if(!$('dashboard'))return;
  $('dashboard').innerHTML=`<div class="card"><h2>Web Portal Required</h2><div class="muted">The HNHS360 Android app is for Subject Teachers and Learners.</div><div class="msg error" style="margin-top:14px">${esc(roleLabel(profile?.role||'This'))} accounts must use the HNHS360 web portal.</div><button class="primary" onclick="logout()">Log Out</button></div>`;
}

renderDashboard=async function(){
  if(profile&&!allowedRoles.has(profile.role)){mobileBlocked();return}
  return baseRenderDashboard();
};

try{
  const h=$('loginView')?.querySelector('h2');if(h)h.textContent='HNHS360 Mobile';
  const m=$('loginView')?.querySelector('.muted');if(m)m.textContent='For Subject Teachers and Learners';
  document.title='HNHS360';
}catch{}

if(profile){Promise.resolve(renderDashboard()).finally(revealMobile)}else revealMobile();
})();