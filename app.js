const workouts = [
  {title:'Réveil du corps',desc:'On remet le corps en mouvement, tranquillement.',min:12,tag:'DOUX'},
  {title:'Cardio sans pression',desc:'Du rythme, sans chercher la performance.',min:15,tag:'CARDIO'},
  {title:'Corps entier',desc:'Renforce les jambes, le centre et les bras.',min:18,tag:'RENFO'},
  {title:'Énergie douce',desc:'Une séance fluide pour retrouver ton souffle.',min:16,tag:'DOUX'},
  {title:'Jambes solides',desc:'Construis une base stable et tonique.',min:20,tag:'RENFO'},
  {title:'Cardio progressif',desc:'Un peu plus long, toujours à ton rythme.',min:20,tag:'CARDIO'},
  {title:'Mobilité active',desc:'Bouge mieux et relâche les tensions.',min:18,tag:'MOBILITÉ'},
  {title:'Circuit complet',desc:'Enchaîne des mouvements simples et efficaces.',min:22,tag:'CIRCUIT'},
  {title:'Endurance douce',desc:'Tiens l’effort sans te mettre dans le rouge.',min:24,tag:'CARDIO'},
  {title:'Force du quotidien',desc:'Des mouvements utiles pour tout le corps.',min:22,tag:'RENFO'},
  {title:'Mon meilleur rythme',desc:'Trouve ton intensité idéale.',min:25,tag:'CIRCUIT'},
  {title:'Finale LibreForme',desc:'Célèbre quatre semaines de régularité.',min:28,tag:'COMPLET'}
];
const baseExercises = [
  {name:'Marche sur place',emoji:'🚶',sec:30,text:'Tiens-toi droit et monte doucement les genoux.'},
  {name:'Squats sur chaise',emoji:'🪑',sec:30,text:'Pousse les hanches en arrière et effleure la chaise.'},
  {name:'Pompes au mur',emoji:'🙌',sec:30,text:'Corps gainé, rapproche la poitrine du mur puis repousse.'},
  {name:'Pas latéraux',emoji:'↔️',sec:30,text:'Fais deux pas de chaque côté, genoux souples.'},
  {name:'Genou vers coude',emoji:'🧍',sec:30,text:'Rapproche un genou du coude opposé, sans tirer sur la nuque.'},
  {name:'Retour au calme',emoji:'🌿',sec:40,text:'Respire profondément et relâche les épaules.'}
];
const jumpExercise={name:'Jumping jacks',emoji:'⭐',sec:30,text:'Écarte bras et jambes en rythme. Reste léger sur les appuis.'};
let state=JSON.parse(localStorage.getItem('libreforme')||'{"done":[],"minutes":0,"dates":[]}');
let session={workout:0,index:0,left:0,timer:null,paused:false,exercises:[]};
const $=s=>document.querySelector(s), $$=s=>document.querySelectorAll(s);
function save(){localStorage.setItem('libreforme',JSON.stringify(state))}
function streak(){const unique=[...new Set(state.dates)].sort().reverse();if(!unique.length)return 0;let n=0,d=new Date();d.setHours(0,0,0,0);const first=new Date(unique[0]);if((d-first)/86400000>1)return 0;if((d-first)/86400000===1)d=first;for(const x of unique){const q=new Date(x);if(q.toDateString()===d.toDateString()){n++;d.setDate(d.getDate()-1)}else break}return n}
function refresh(){
  $('#doneCount').textContent=state.done.length;$('#minutesCount').textContent=state.minutes;$('#streakCount').textContent=streak();
  const next=Math.min(state.done.length,11),w=workouts[next];$('#nextTitle').textContent=w.title;$('#nextDesc').textContent=w.desc;$('#nextMeta').textContent=`${w.min} MIN · ${w.tag}`;$('#weekBadge').textContent=`Semaine ${Math.floor(next/3)+1}`;$('#startNext').dataset.start=next;
  renderWeeks();
}
function renderWeeks(){const root=$('#weekList');root.innerHTML='';for(let week=0;week<4;week++){const box=document.createElement('section');box.className='week';box.innerHTML=`<div class="week-title"><h2>Semaine ${week+1}</h2><span>${week===0?'PRENDRE SES MARQUES':week===1?'TROUVER SON RYTHME':week===2?'GAGNER EN AISANCE':'SE SENTIR PLUS FORT'}</span></div>`;for(let d=0;d<3;d++){const i=week*3+d,w=workouts[i],done=state.done.includes(i);const row=document.createElement('article');row.className='day-card'+(done?' done':'');row.innerHTML=`<div class="day-num">${String(i+1).padStart(2,'0')}</div><div><h3>${w.title}</h3><p>${w.min} min · ${w.tag.toLowerCase()}</p></div><button>${done?'✓ Fait':'Démarrer'}</button>`;row.onclick=()=>startSession(i);box.appendChild(row)}root.appendChild(box)}}
function show(id){$$('.view').forEach(v=>v.classList.toggle('active',v.id===id));$$('.bottom-nav button').forEach(b=>b.classList.toggle('nav-active',b.dataset.go===id));document.body.classList.toggle('in-session',id==='seance'||id==='bravo');scrollTo(0,0)}
function exercises(){const low=$('#lowImpact').checked,level=$('#levelSelect').value;let list=[...baseExercises];if(!low)list.splice(4,0,jumpExercise);if(level==='intermediaire')list=list.map(x=>({...x,sec:x.name==='Retour au calme'?40:45}));return list}
function startSession(i){session.workout=Number(i);session.exercises=exercises();session.index=0;loadExercise();show('seance');runTimer()}
function loadExercise(){clearInterval(session.timer);const x=session.exercises[session.index];session.left=x.sec;session.paused=false;$('#exerciseName').textContent=x.name;$('#exerciseEmoji').textContent=x.emoji;$('#instruction').textContent=x.text;$('#sessionStep').textContent=`Exercice ${session.index+1} / ${session.exercises.length}`;$('#sessionProgress').style.width=`${session.index/session.exercises.length*100}%`;$('#phaseLabel').textContent=session.index===session.exercises.length-1?'RÉCUPÉRATION':'À FAIRE';$('#pauseBtn').textContent='Pause';paintTimer()}
function paintTimer(){const m=Math.floor(session.left/60),s=session.left%60;$('#timer').textContent=`${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`}
function runTimer(){clearInterval(session.timer);session.timer=setInterval(()=>{if(session.paused)return;session.left--;paintTimer();if(session.left<=0)next()},1000)}
function next(){if(session.index<session.exercises.length-1){session.index++;loadExercise();runTimer()}else finish()}
function prev(){if(session.index>0){session.index--;loadExercise();runTimer()}}
function finish(){clearInterval(session.timer);const i=session.workout;if(!state.done.includes(i)){state.done.push(i);state.minutes+=workouts[i]?.min||7;state.dates.push(new Date().toISOString().slice(0,10));save()}$('#finishMinutes').textContent=workouts[i]?.min||7;refresh();show('bravo')}
$$('[data-go]').forEach(b=>b.onclick=()=>show(b.dataset.go));document.addEventListener('click',e=>{const s=e.target.closest('[data-start]');if(s)startSession(s.dataset.start==='express'?0:s.dataset.start)});$('#startNext').onclick=()=>startSession($('#startNext').dataset.start);$('#nextExercise').onclick=next;$('#prevExercise').onclick=prev;$('#pauseBtn').onclick=()=>{session.paused=!session.paused;$('#pauseBtn').textContent=session.paused?'Reprendre':'Pause'};$('#closeSession').onclick=()=>{clearInterval(session.timer);show('accueil')};$('#soundBtn').onclick=e=>{e.currentTarget.classList.toggle('muted');e.currentTarget.textContent=e.currentTarget.classList.contains('muted')?'×':'♪'};$('#resetBtn').onclick=()=>{if(confirm('Effacer toute ta progression ?')){state={done:[],minutes:0,dates:[]};save();refresh()}};$('#levelSelect').onchange=save;$('#lowImpact').onchange=save;
refresh();
if('serviceWorker'in navigator)navigator.serviceWorker.register('sw.js').catch(()=>{});

