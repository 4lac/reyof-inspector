/* Reyof · github.com/4lac */
const $ = (id) => document.getElementById(id);
const esc = (t) => String(t ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

let DATA = [], filter = 'all', scanning = false;
const ICON = { ok: '✓', warn: '!', fail: '✕' };
const RING = 415;

function render(){
  const list = $('list');
  const rows = DATA.filter((it)=> filter==='all' || it.level===filter);
  if (!rows.length){ list.innerHTML = `<div class="empty">${scanning?'Scanning…':'Nothing here.'}</div>`; return; }
  list.innerHTML = rows.map((it)=>`
    <div class="row ${it.level}">
      <div class="ic">${ICON[it.level]||'•'}</div>
      <div class="body">
        <div class="sec">${esc(it.section)}</div>
        <div class="msg">${esc(it.msg)}</div>
        ${it.fix && it.level!=='ok' ? `<div class="fix">${esc(it.fix)}</div>` : ''}
      </div>
    </div>`).join('');
}

function applyReport(items, counts){
  DATA = items || [];
  DATA.sort((a,b)=>({fail:0,warn:1,ok:2}[a.level]-{fail:0,warn:1,ok:2}[b.level]));
  const ok=counts.ok||0, warn=counts.warn||0, fail=counts.fail||0, total=ok+warn+fail||1;
  $('cOk').textContent=ok; $('cWarn').textContent=warn; $('cFail').textContent=fail;
  $('cRes').textContent=(DATA.find(x=>x.section==='Summary')?.msg||'').match(/\d+/)?.[0]||'—';
  $('pFail').style.width=(fail/total*100)+'%';
  $('pWarn').style.width=(warn/total*100)+'%';
  $('pOk').style.width=(ok/total*100)+'%';

  const score=Math.max(0,Math.round(100-(fail*14)-(warn*4)));
  const cls=score>=85?'good':score>=55?'mid':'bad';
  const sv=$('scoreV'); sv.textContent=score; sv.className='score-v '+cls;
  $('ringFill').style.strokeDashoffset=RING-(RING*score/100);
  $('ringFill').style.stroke=cls==='good'?'var(--ok)':cls==='mid'?'var(--warn)':'var(--fail)';
  const vd=$('verdict'); vd.className='verdict '+cls;
  vd.textContent = fail>0?'ISSUES FOUND':warn>0?'NEEDS REVIEW':'HEALTHY';
  $('heroSub').textContent = fail>0?`${fail} error(s) and ${warn} warning(s) to fix`
    : warn>0?`${warn} warning(s) — worth a look` : 'Everything looks good';
  render();
}

const STEPS=['Reading resources…','Detecting core…','Checking dependencies…','Scanning for conflicts…','Testing database…','Compiling report…'];
function runScanAnimation(items,counts){
  scanning=true; $('run').classList.add('busy'); $('scanTag').classList.add('on');
  $('verdict').textContent='SCANNING'; $('verdict').className='verdict';
  $('heroSub').textContent='Inspecting the server…';
  $('list').innerHTML='<div class="empty">Scanning…</div>';
  let step=0;
  const t=setInterval(()=>{
    $('ringFill').style.strokeDashoffset=RING-(RING*(step+1)/STEPS.length);
    $('heroSub').textContent=STEPS[step];
    step++;
    if(step>=STEPS.length){
      clearInterval(t);
      setTimeout(()=>{ scanning=false; $('run').classList.remove('busy'); $('scanTag').classList.remove('on'); applyReport(items,counts); },300);
    }
  },240);
}

document.querySelectorAll('.f').forEach((b)=>b.addEventListener('click',()=>{
  document.querySelectorAll('.f').forEach(x=>x.classList.remove('active'));
  b.classList.add('active'); filter=b.dataset.f; render();
}));
$('run').addEventListener('click',()=>{ if(!scanning) post('rerun'); });
$('xClose').addEventListener('click',()=>{ hide(); post('close'); });

function hide(){ $('scene').classList.add('hidden'); }
function post(name,body){ fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body||{})}).catch(()=>{}); }

window.addEventListener('message',({data:d})=>{
  if(d.action==='show'){ $('scene').classList.remove('hidden'); runScanAnimation(d.items,d.counts); }
  else if(d.action==='hide') hide();
});
