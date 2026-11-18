const SB='https://aelrfxcqzwncxpaeopjc.supabase.co',KEY='sb_publishable_F2tau5k6arz1WN4BucXS0g_E0hpAuJa',TZ='Africa/Johannesburg';
const $=s=>document.querySelector(s),esc=t=>String(t??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
async function api(path,body){
 const r=await fetch(SB+'/rest/v1/'+path,{method:body?'POST':'GET',headers:{apikey:KEY,'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined});
 const j=await r.json().catch(()=>null);
 if(!r.ok)throw Object.assign(new Error('api'),{code:j&&j.message});
 return j;
}
const S={services:[],svc:null,date:null,slot:null,slots:null,step:1,error:'',email:''};
const money=p=>Number(p)>0?'R'+Number(p):'Free';
const hhmm=d=>new Date(d).toLocaleTimeString('en-GB',{hour:'2-digit',minute:'2-digit',hour12:false,timeZone:TZ});
const longDate=ymd=>new Date(ymd+'T12:00:00Z').toLocaleDateString('en-ZA',{weekday:'long',day:'numeric',month:'long',year:'numeric',timeZone:'UTC'});
const todayYmd=()=>new Date().toLocaleDateString('en-CA',{timeZone:TZ});
function days(){const[y,m,d]=todayYmd().split('-').map(Number);return Array.from({length:14},(_,i)=>{const t=new Date(Date.UTC(y,m-1,d+i));return{ymd:t.toISOString().slice(0,10),dow:t.getUTCDay(),wd:t.toLocaleDateString('en-ZA',{weekday:'short',timeZone:'UTC'}).toUpperCase(),n:t.getUTCDate()}})}

/* routing */
function route(){
 const id=(location.hash||'#home').slice(1);const v=document.getElementById(id)&&document.getElementById(id).classList.contains('v')?id:'home';
 document.querySelectorAll('section.v').forEach(s=>s.classList.toggle('on',s.id===v));
 $('#nav').classList.remove('open');scrollTo(0,0);
 if(v==='book')renderBook();
}
addEventListener('hashchange',route);
$('#menu').onclick=()=>$('#nav').classList.toggle('open');
document.addEventListener('click',e=>{
 const b=e.target.closest('[data-book]');if(b){S.step=1;S.slot=null;S.slots=null;S.error='';S.svc=null;S.date=null}
 const pick=e.target.closest('[data-svc]');
 if(pick){S.svc=S.services.find(s=>s.id===pick.dataset.svc);S.step=2;S.date=null;S.slot=null;S.slots=null;S.error='';location.hash='#book'}
});

/* services */
function svcCards(){
 const html=S.services.map((s,i)=>`<div class="card"><div class="eyebrow" style="margin:0">0${i+1}</div><h3>${esc(s.name)}</h3><p class="small">${esc(s.description)}</p>
 <div class="meta"><span class="small">${s.duration_minutes} min</span><span class="price">${money(s.price)}</span></div><button class="btn sec" data-svc="${s.id}">Book this ↗</button></div>`).join('');
 document.querySelectorAll('.svc-list').forEach(e=>e.innerHTML=html||'<p class="small">Services are unavailable right now.</p>');
}
async function loadServices(){
 try{S.services=await api('services?select=*&active=eq.true&order=duration_minutes.asc')}catch(e){S.services=[]}
 svcCards();if(location.hash==='#book')renderBook();
}

/* booking */
function renderBook(){
 const L=['Service','Date & time','Your details','Confirmation'];
 $('#stepper').innerHTML=L.map((l,i)=>`<div class="${i+1<S.step?'done':i+1===S.step?'cur':''}">${i+1<S.step?'✓ ':(i+1)+' '}<span class="lb">${l}</span></div>`).join('');
 const g=S.svc?`<h3 style="color:var(--primary)">${esc(S.svc.name)}</h3><p class="small">${S.svc.duration_minutes} minutes · Online · ${money(S.svc.price)}</p>${S.date&&S.slot?`<p class="small">${longDate(S.date)}<br>${hhmm(S.slot.slot_start)}–${hhmm(S.slot.slot_end)} SAST</p>`:'<p class="small">Choose a date and time to continue.</p>'}`:'<p class="small">Choose a service to begin.</p>';
 $('#glance').innerHTML=g;
 const bk=$('#bk');
 if(S.step===1){
  bk.innerHTML=`<h3>Choose your service</h3><p class="small" style="margin-bottom:16px">Choose the conversation that fits your idea.</p>`+
  (S.services.length?S.services.map(s=>`<button class="opt ${S.svc&&S.svc.id===s.id?'sel':''}" data-pick="${s.id}"><span class="t"><span>${esc(s.name)} ${S.svc&&S.svc.id===s.id?'✓':'○'}</span></span><span class="small">${esc(s.description)}</span><span class="small" style="display:block;margin-top:4px">${s.duration_minutes} min · ${money(s.price)}</span></button>`).join(''):'<div class="alert">We couldn’t load services. Please refresh.</div>')+
  `<div class="row"><span class="small">${S.svc?'':'Select a service to continue.'}</span><button class="btn" id="go" ${S.svc?'':'disabled'}>Continue →</button></div>`;
  bk.querySelectorAll('[data-pick]').forEach(b=>b.onclick=()=>{S.svc=S.services.find(s=>s.id===b.dataset.pick);S.date=null;S.slot=null;S.slots=null;renderBook()});
  $('#go').onclick=()=>{S.step=2;renderBook()};
 }
 if(S.step===2){
  const D=days();if(!S.date)S.date=(D.find(d=>d.dow!==0)||D[0]).ymd;
  bk.innerHTML=`<h3>Find your moment</h3><div class="row" style="margin:8px 0 0"><span class="small" style="color:var(--primary);font-weight:600">${esc(S.svc.name)} · ${S.svc.duration_minutes} min · ${money(S.svc.price)}</span><button class="link" id="chg">Change</button></div>
  <div class="dates">${D.map(d=>`<button class="dc ${d.ymd===S.date?'sel':''}" data-d="${d.ymd}" ${d.dow===0?'disabled':''}>${d.wd}<small>${d.n}</small></button>`).join('')}</div>
  <h3 style="font-size:16px">${longDate(S.date)}</h3>${S.error?`<div class="alert">${S.error}</div>`:''}<div id="slots" style="margin-top:12px"></div>
  <p class="small" style="margin-top:12px">Times shown in South Africa time (SAST, UTC+2).</p>
  <div class="row"><button class="link" id="back">← Back</button><button class="btn" id="go" ${S.slot?'':'disabled'}>Continue →</button></div>`;
  $('#chg').onclick=$('#back').onclick=()=>{S.step=1;S.error='';renderBook()};
  bk.querySelectorAll('[data-d]').forEach(b=>b.onclick=()=>{S.date=b.dataset.d;S.slot=null;S.slots=null;S.error='';renderBook()});
  $('#go').onclick=()=>{S.step=3;S.error='';renderBook()};
  drawSlots();
 }
 if(S.step===3){
  bk.innerHTML=`<h3>A few details, then you’re set.</h3>
  <label for="n">Full name</label><input id="n" autocomplete="name" placeholder="Your full name"><div class="err" id="en"></div>
  <label for="e">Email address</label><input id="e" type="email" autocomplete="email" placeholder="you@example.com"><div class="err" id="ee"></div>
  <label for="p">Phone number (optional)</label><input id="p" type="tel" placeholder="+27">
  <label for="m">Notes (optional)</label><input id="m" placeholder="Anything you’d like me to know?">
  <p class="small" style="margin-top:12px">I’ll only use these details to arrange your session.</p>${S.error?`<div class="alert">${S.error}</div>`:''}
  <div class="row"><button class="link" id="back">← Back</button><button class="btn" id="ok">Confirm booking ↗</button></div>`;
  $('#back').onclick=()=>{S.step=2;S.error='';renderBook()};
  $('#ok').onclick=confirmBooking;
 }
 if(S.step===4){
  bk.innerHTML=`<span class="ok">✓ Confirmed</span><h2 style="margin:16px 0 8px">You’re booked. Let’s make progress.</h2>
  <p class="lead" style="margin:0 0 16px">Your ${esc(S.svc.name.toLowerCase())} is confirmed. We’ll use <b>${esc(S.email)}</b> to send the details.</p>
  <div class="note"><b>${esc(S.svc.name)}</b><br>${longDate(S.date)}<br>${hhmm(S.slot.slot_start)}–${hhmm(S.slot.slot_end)} · SAST (UTC+2)<br>Online session · ${money(S.svc.price)}</div>
  <h3 style="margin-top:24px">What happens next</h3><p class="small">1. Check your inbox for confirmation details.<br>2. Bring your idea and any questions.<br>3. Payment, if any, is arranged after booking.</p>
  <p style="margin-top:24px"><a class="btn" href="#home">Back to home ↗</a></p>`;
 }
}
async function drawSlots(){
 const box=$('#slots');if(!box)return;
 if(!S.slots){
  box.innerHTML='<div class="slots">'+'<div class="skel"></div>'.repeat(6)+'</div><p class="small" style="margin-top:8px">Loading available times…</p>';
  const key=S.svc.id+S.date;
  try{const r=await api('rpc/get_available_slots',{p_service_id:S.svc.id,p_date:S.date});if(key!==S.svc.id+S.date)return;S.slots=r}
  catch(e){box.innerHTML='<div class="alert">We couldn’t load available times. Please try again.<br><br><button class="btn sm" id="retry">Try again ↻</button></div>';$('#retry').onclick=()=>drawSlots();return}
 }
 if(!S.slots.length){box.innerHTML='<div class="note">No times available on this date. Try another day.</div>';return}
 box.innerHTML='<div class="slots">'+S.slots.map((s,i)=>`<button class="slot ${S.slot&&S.slot.slot_start===s.slot_start?'sel':''}" data-i="${i}">${hhmm(s.slot_start)}</button>`).join('')+'</div>';
 box.querySelectorAll('.slot').forEach(b=>b.onclick=()=>{S.slot=S.slots[b.dataset.i];renderBook()});
}
async function confirmBooking(){
 const n=$('#n').value.trim(),e=$('#e').value.trim();let bad=false;
 $('#en').textContent=$('#ee').textContent='';
 if(n.length<2){$('#en').textContent='Please enter your name.';bad=true}
 if(!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(e)){$('#ee').textContent='Enter a valid email address.';bad=true}
 if(bad)return;
 const btn=$('#ok');btn.disabled=true;btn.textContent='Confirming…';
 try{
  await api('rpc/create_booking',{p_service_id:S.svc.id,p_start_time:S.slot.slot_start,p_full_name:n,p_email:e,p_phone:$('#p').value.trim()||null,p_notes:$('#m').value.trim()||null});
  S.email=e;S.step=4;S.error='';renderBook();
 }catch(x){
  if(x.code==='slot_unavailable'){S.step=2;S.slot=null;S.slots=null;S.error='Sorry, that time was just booked. Please pick another time.'}
  else if(x.code==='invalid_email'){S.error='Enter a valid email address.'}
  else if(x.code==='invalid_name'){S.error='Please enter your name.'}
  else{S.error='Something went wrong. Please try again.'}
  renderBook();
 }
}

/* contact (opens the visitor's email app) */
$('#send').onclick=()=>{
 const n=$('#cn').value.trim(),e=$('#ce').value.trim(),m=$('#cm').value.trim();
 location.href='mailto:hello@sldigitalworks.example?subject='+encodeURIComponent('Enquiry from '+(n||'website'))+'&body='+encodeURIComponent(m+'\n\n'+n+'\n'+e);
};

route();loadServices();
