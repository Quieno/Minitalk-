#!/bin/bash

# ─────────────────────────────────────────────
#  minitalk — test suite
# ─────────────────────────────────────────────

SERVER=./server
CLIENT=./client
SRV_OUT="/tmp/mt_srv.txt"
SRV_PID=""
SRV_PORT=""
PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── lifecycle ─────────────────────────────────

nuke_all() {
	pkill -9 -f '\./server$' 2>/dev/null
	pkill -9 -f '\./client ' 2>/dev/null
	sleep 0.15
}

start_server() {
	nuke_all
	> "$SRV_OUT"
	$SERVER >> "$SRV_OUT" 2>/dev/null &
	SRV_PID=$!
	sleep 0.3
	SRV_PORT=$(head -1 "$SRV_OUT" | tr -d '[:space:]\n')
}

stop_server() {
	kill -9 $SRV_PID 2>/dev/null
	wait $SRV_PID 2>/dev/null
	SRV_PID=""
	SRV_PORT=""
}

restart_server() { stop_server; start_server; }
cleanup_clients() { pkill -9 -f '\./client ' 2>/dev/null; sleep 0.1; }
srv_out()        { tail -n +2 "$SRV_OUT"; }

# ── reporting ─────────────────────────────────

pass_test() { echo -e "  ${GREEN}✓${RESET} $1"; PASS=$((PASS + 1)); }
fail_test()  { echo -e "  ${RED}✗${RESET} $1\n    ${RED}↳ $2${RESET}"; FAIL=$((FAIL + 1)); }
section()    { echo -e "\n${CYAN}${BOLD}── $1 ──${RESET}"; }

# ── tests ─────────────────────────────────────

test_basic_message() {
	restart_server
	$CLIENT $SRV_PORT "Here be dragons." > /dev/null 2>&1
	sleep 0.3
	local out; out=$(srv_out)
	[ "$out" = "Here be dragons." ] \
		&& pass_test "basic message" \
		|| fail_test "basic message" "got '${out}'"
}

test_empty_string() {
	restart_server
	$CLIENT $SRV_PORT "" > /dev/null 2>&1
	sleep 0.3
	local n; n=$(srv_out | wc -l)
	[ "$n" -ge 1 ] \
		&& pass_test "empty string — server prints newline" \
		|| fail_test "empty string" "no output"
}

test_special_chars() {
	local msg='!@#$%^&*()_+-={}|;:,.<>?`~'
	restart_server
	$CLIENT $SRV_PORT "$msg" > /dev/null 2>&1
	sleep 0.3
	local out; out=$(srv_out)
	[ "$out" = "$msg" ] \
		&& pass_test "special characters" \
		|| fail_test "special characters" "got '${out}'"
}

test_numbers() {
	restart_server
	$CLIENT $SRV_PORT "1234567890" > /dev/null 2>&1
	sleep 0.3
	local out; out=$(srv_out)
	[ "$out" = "1234567890" ] \
		&& pass_test "numbers only" \
		|| fail_test "numbers only" "got '${out}'"
}

test_long_lorem() {
	local msg="Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec consectetur placerat metus ut luctus. Nullam urna sapien, gravida nec mauris eu, interdum consequat leo. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam mattis, enim a egestas semper, metus massa iaculis nunc, ac dictum sem augue et orci. Mauris viverra quam in mi maximus, ac tincidunt tellus mattis. Morbi volutpat tellus a diam fermentum ornare. Cras malesuada enim tellus, quis tempus lacus tincidunt at. Sed tincidunt pharetra orci quis dignissim. Praesent faucibus scelerisque quam, in volutpat nulla finibus a. Morbi maximus ligula id urna ullamcorper, et ornare nunc pharetra. Aliquam tempus erat sit amet ante ultrices luctus. Integer porttitor mollis sollicitudin.

Proin efficitur quis sem et porttitor. Vivamus mollis nunc in viverra laoreet. Nam hendrerit vitae tortor eget dictum. Vivamus eleifend erat ut semper congue. Fusce sit amet ipsum non enim ullamcorper imperdiet. Aliquam ut varius mauris, id pharetra tellus. Praesent venenatis ante at diam convallis, eu semper odio sagittis.

Proin mattis elit orci, sit amet suscipit augue semper ut. Pellentesque elementum, orci in finibus tristique, eros diam semper tellus, commodo dolor nisi eu turpis. Sed interdum dolor velit, eu blandit mi venenatis eget. Integer eget eleifend nisl. Vestibulum mattis quis justo at eleifend. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Aliquam elit velit, tincidunt vel tellus ac, vulputate feugiat arcu. Aenean iaculis pharetra vestibulum. Suspendisse dapibus purus non purus ornare pretium.

Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nulla sit amet pulvinar erat. Vestibulum nec neque vulputate, malesuada velit eget, congue nulla. Suspendisse hendrerit ante justo, nec egestas elit semper non. Phasellus tempor urna ac orci egestas, ac consequat eros consequat. Praesent venenatis vulputate enim, quis malesuada lacus semper eu. Cras hendrerit faucibus hendrerit. Pellentesque semper ultrices risus, nec aliquet ligula varius sed. Aliquam nec consequat leo. Sed nulla metus, viverra id est quis, porttitor placerat neque. Suspendisse volutpat quis leo sit amet cursus. Phasellus sed ante dignissim venenatis eleifend. Nam placerat dolor vel nunc hendrerit lacinia. Nam et dictum dui. Maecenas maximus efficitur pellentesque. Duis sit amet lacinia mauris.

Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Pellentesque sed fringilla est, sed euismod leo. Curabitur ante tortor, lobortis non bibendum non, hendrerit id risus. Proin porttitor urna tempor mi ullamcorper faucibus. Quisque quis mollis felis. Nulla luctus euismod porttitor. Aliquam ac tincidunt magna.

Duis fringilla mi a est pharetra, eget bibendum ante volutpat. Curabitur in dignissim lectus. Phasellus luctus consectetur nunc sed lobortis. Vestibulum ac nisi dictum, fringilla ante eu, imperdiet felis. Ut cursus tortor felis, vel mattis velit ultrices a. Suspendisse eu dui sit amet ante tristique tempor. Etiam pulvinar tincidunt diam eu imperdiet.

Nullam tristique mi metus, in fermentum orci vulputate vitae. Donec sit amet arcu tortor. Donec maximus sit amet mauris at rutrum. Ut et metus mi. Vivamus egestas velit sed dignissim congue. Duis facilisis in ligula sed varius. Sed vel risus sit amet neque euismod placerat. Mauris in volutpat dolor. Fusce sodales, nisi at consectetur efficitur, mauris tortor pulvinar elit, id imperdiet mauris nisl eu risus. Donec id nisl nec enim malesuada rutrum. Vestibulum lorem tortor, sagittis vitae accumsan in, vehicula ac arcu. Sed in lorem, sagittis lectus vitae, porta ex.

Mauris aliquam diam id metus volutpat, vel vestibulum ante mollis. Fusce odio orci, gravida vel metus eget, convallis elementum sem. Nulla facilisi. Duis nec cursus sapien. Integer vel tellus sit amet sem porttitor finibus sed at metus. Quisque mattis magna dui. Nulla cursus consectetur lorem, in ullamcorper lorem fringilla sed. Etiam tincidunt auctor felis quis lobortis. Proin convallis, massa et condimentum sodales, tellus sem volutpat felis, in posuere tortor nibh in nisi. Praesent gravida, sem in convallis pulvinar, lorem orci pharetra odio, aliquam volutpat elit elit et magna. Aliquam elementum auctor sem, eget laoreet enim commodo quis.

Fusce consectetur enim imperdiet, lacinia metus ut, commodo dolor. Curabitur a justo sed nisl tincidunt imperdiet vel nec enim. Praesent arcu arcu, cursus ac lacus in, auctor venenatis tortor. Suspendisse et augue in nisl porttitor volutpat. Cras ac nulla nec enim rutrum volutpat. Curabitur orci metus, egestas eu tristique in, maximus vitae lacus. Aenean eu bibendum dui. Sed tincidunt at nunc at fringilla.
Integer auctor ultrices feugiat. Suspendisse vel lorem at diam vehicula pellentesque. Curabitur at lorem id eros euismod blandit. Nulla venenatis ante lectus, vitae bibendum nisi scelerisque sed. Mauris efficitur dolor euismod dolor dictum fringilla. In a lectus risus. Sed nulla augue, semper nec aliquam vel, rhoncus et ex.

Maecenas eget suscipit augue, ut pretium dui. Nunc ullamcorper laoreet interdum. Integer non aliquet eros, non sodales dui. Morbi elementum aliquam molestie. Donec pulvinar ultricies dolor a tristique. Nunc porttitor vel sapien ac tempor. Nam molestie quis enim vitae vestibulum. Mauris hendrerit sodales rutrum. Aenean semper sed magna eu sodales.

Interdum et malesuada fames ac ante ipsum primis in faucibus. Aliquam eget ultricies leo, sagittis malesuada. Mauris eu odio fringilla, convallis lectus quis, egestas libero. Mauris at elit magna. Phasellus eu magna semper, mollis eros vel, blandit tellus. Duis quis leo in dapibus fermentum nec ac leo. Aliquam id ultrices quam. Proin mollis massa purus, eu facilisis turpis hendrerit at. Morbi vel massa sit amet nibh mattis aliquam iaculis ac leo. Praesent eu semper ex.

Quisque neque odio, efficitur sit amet consequat sed, sagittis at eros. Pellentesque et nibh sit amet purus sollicitudin luctus quis vel augue. Donec auctor pulvinar ipsum ut lobortis. Morbi ac dignissim lectus, ut condimentum elit. Aliquam ac aliquam odio. Aliquam turpis sem, tincidunt vitae sollicitudin ut, convallis id ipsum. Sed fringilla magna tincidunt, maximus risus sit amet, volutpat justo. Maecenas a mauris dolor. Suspendisse porttitor ligula metus, et porta enim luctus a.

Nunc eu nibh sit amet lacus fringilla ultricies. Nullam consectetur non tortor facilisis rhoncus. Donec in turpis id urna tristique sagittis vitae ac nulla. Proin in nisl libero. Nunc non blandit dui. In ullamcorper nisi risus, sit amet iaculis purus dictum non. Sed est quam, malesuada et urna et, placerat posuere augue. Proin tristique nibh id arcu condimentum tincidunt. Morbi ultricies, leo interdum facilisis fringilla, lorem augue pharetra metus, at ultricies quam risus non ex. Nullam pharetra tempor erat, ut scelerisque tortor facilisis aliquet. Nunc urna ex, ultricies id aliquam nec, eleifend nec nunc.

Vestibulum pulvinar convallis cursus. Morbi mollis a orci in pretium. In imperdiet massa eu nunc efficitur condimentum. Nunc malesuada, lacus in porttitor lacinia, lectus eros lobortis sapien, at dignissim leo erat eget risus. Nulla facilisi. Pellentesque convallis vel lorem quis cursus. Proin efficitur erat sit amet mauris ultricies, non blandit massa facilisis. Nulla bibendum tristique diam ac aliquam. Donec sed ligula quis felis facilisis tristique nec faucibus ligula. Suspendisse lacus magna, porta sit amet nulla eget, blandit ex. Ut dapibus sit amet augue at mollis. Phasellus finibus maximus ligula quis porttitor. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Etiam purus nulla, pulvinar ut turpis vel, lobortis maximus augue.

Integer commodo faucibus maximus. Fusce auctor eleifend vehicula. Nulla pharetra velit eu neque rhoncus vestibulum. Vestibulum eleifend eleifend tortor, id pretium mauris posuere at. Proin eu enim et nibh mollis bibendum varius ut enim. Cras porta magna non vestibulum euismod. Aenean finibus est est, vel laoreet massa iaculis ut. Nunc posuere lectus eu enim fringilla viverra. Sed finibus eu sapien eget hendrerit. Ut consectetur ut ante a bibendum. Curabitur eget laoreet massa, eu tempor nibh.

Etiam in efficitur risus. Nullam maximus tristique turpis, quis faucibus purus scelerisque scelerisque. Maecenas in vehicula purus, quis efficitur tellus. Nam posuere venenatis semper. Vivamus est neque, congue et gravida vitae, ultricies vel libero. Integer aliquam, urna quis tincidunt ultricies, sapien augue cursus lacus, sit amet semper felis nisl sit amet purus. Maecenas et convallis arcu. Sed luctus ut lectus vitae vehicula. Donec libero dui, dictum sed turpis sed, pharetra venenatis velit.

Morbi cursus est metus, ut tincidunt augue gravida sit amet. Proin et imperdiet augue. Nullam sollicitudin sodales tortor in dictum. Proin auctor porta nibh nec convallis. Morbi nec elit eget odio ornare cursus. Praesent scelerisque sem vel venenatis porta. Etiam erat turpis, efficitur sit amet enim ac, ultrices dapibus turpis.

Mauris auctor porta ipsum. Phasellus laoreet, libero ut placerat tincidunt, mi turpis consectetur risus, sed placerat ex augue ac nisi. Quisque vehicula at augue id vulputate. Nam volutpat dapibus quam, a luctus dolor pellentesque eget. Phasellus aliquam vulputate ipsum ac ornare. Fusce pellentesque cursus ante mollis. Morbi sapien arcu, volutpat et augue et, facilisis tincidunt erat. Ut et lacinia ex, quis tincidunt tortor. Praesent posuere lobortis. Duis vestibulum nulla nec sem dignissim sagittis.

Phasellus ac ligula ultricies, interdum tellus in, posuere leo. Quisque luctus non massa quis mollis. Morbi pulvinar, mauris euismod feugiat fermentum, tortor leo pulvinar arcu, a posuere tellus dui interdum lorem. Praesent luctus urna porta ipsum tincidunt iaculis. Aliquam iaculis diam eros, quis congue sem convallis ut. Aenean consequat nunc et tortor imperdiet, a suscipit tortor ullamcorper. Proin efficitur sodales euismod. Fusce dignissim sapien ac nulla molestie, ut hendrerit libero posuere.

Sed tristique rutrum sem, tincidunt elementum nisl pharetra sit amet. In finibus felis et metus viverra fringilla. Integer convallis lectus ac tempus pulvinar. Vestibulum ante tellus, ullamcorper ac sagittis quis, auctor fringilla lectus. Pellentesque eget tellus ligula. Phasellus accumsan orci erat, et ultrices dolor fermentum mollis. Phasellus nulla ipsum, posuere sit amet porta at, feugiat eu nunc. Maecenas ultricies interdum ligula sed pulvinar. Duis in tortor elit.

Ut quis sem quis libero varius maximus. Sed vitae dignissim orci, nec laoreet urna. Sed lectus risus, molestie non tortor vitae, mattis pharetra ipsum. Proin eget neque eget velit scelerisque elementum. Cras porttitor eros sit amet nibh ornare, et commodo diam tempus. Suspendisse et justo interdum, mollis est vitae, accumsan purus. Etiam scelerisque ac odio eget vulputate. In hac habitasse platea dictumst. Morbi vulputate laoreet est, lacinia pellentesque nulla lobortis ac. Vivamus a lacinia massa, et facilisis arcu.

Nullam iaculis risus venenatis, hendrerit ipsum vel, ullamcorper nulla. Proin tristique vulputate lorem, laoreet ultrices eros malesuada sed. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur id maximus urna, non sollicitudin turpis. Ut accumsan tristique ante vel varius. Ut auctor tincidunt metus, vitae porta justo molestie quis. Maecenas at ex ornare, cursus sapien sed, sodales orci. Donec odio neque, sodales at sagittis sit amet, cursus a dolor. Ut diam urna, egestas et rutrum a, molestie vel ipsum. Condimentum est nec hendrerit auctor. Vestibulum nibh lacus, consectetur quis tempus vel, rutrum ac lacus. Vivamus quis metus id nunc eleifend sagittis ac id est. Vivamus sit amet eros nec lectus commodo scelerisque.

Mauris commodo lacinia pharetra. Nullam egestas rutrum consequat. Suspendisse id turpis lacus. Aliquam molestie accumsan viverra. Aenean volutpat viverra dui, non pretium ligula mattis at. Maecenas efficitur sed enim eu ultricies. Phasellus a tincidunt augue. Cras ligula metus, tincidunt sit amet turpis ac, rhoncus consectetur massa. Duis mollis mollis efficitur. Ut sed consequat arcu.

Ut in sapien sed dui fringilla eleifend. Phasellus sit amet blandit turpis. Aliquam iaculis eros vel turpis lacinia euismod. Maecenas molestie magna quis lorem lacinia, vel ultrices enim rhoncus. Nunc pharetra metus ac ullamcorper tincidunt. Mauris consectetur iaculis nisl nec porta. Praesent id augue et libero dignissim fermentum in quis nisl. Nunc maximus, massa vitae semper laoreet, arcu lectus finibus dolor, vitae consequat dui felis vel nisl. Nunc eget nisl at nibh convallis tincidunt. Pellentesque pretium leo in est lobortis hendrerit. In a urna sit amet ligula rhoncus aliquet. Praesent convallis finibus magna, eget consequat sem mollis quis. Aliquam ut sodales tellus. Duis dignissim, risus sed gravida iaculis, ante turpis suscipit lacus, at molestie ante nisl eget lorem. Etiam consectetur bibendum erat, nec ornare quam auctor sit amet. In suscipit sem vel purus rhoncus varius.

Vestibulum ut ornare odio, eget aliquet tellus. Fusce imperdiet imperdiet turpis, non condimentum lorem fermentum eget. Vivamus augue risus, venenatis at mi vitae, euismod mattis turpis. Nulla gravida lacus at odio iaculis, sed vehicula sapien faucibus. Nulla et mollis ipsum. Quisque id libero dapibus, molestie neque vitae, tincidunt eros. Suspendisse et metus quis metus laoreet ultrices ut pulvinar mi. Nulla facilisi. Duis euismod aliquet neque, a venenatis turpis maximus sit amet. Integer ac sapien nec urna iaculis dictum. Fusce ac odio quis urna sodales tristique et at erat. Integer tempor nibh orci, sit amet imperdiet erat tempus eu. Donec feugiat ut diam eu pretium. Duis in arcu eget turpis auctor rhoncus pretium at tellus. Morbi scelerisque mi at nulla tincidunt egestas at eget enim.

Proin eu condimentum turpis. Etiam pulvinar est metus, vitae interdum est ultricies ut. Nulla quis est commodo, vulputate felis ut, scelerisque nulla. Aenean vel nibh arcu. Duis sed viverra libero. Donec porta ac ipsum a faucibus. Phasellus sodales in elit non laoreet. Ut blandit nisi massa, tempus tincidunt dui faucibus eu. Nulla feugiat quam sed odio sagittis, ac bibendum dui mollis.

Proin et dignissim leo. Aliquam iaculis pellentesque purus, in tincidunt urna mollis a. Quisque semper massa tortor, quis accumsan nisi laoreet sed. Aenean sodales vitae erat vel ullamcorper. Nulla facilisi. Suspendisse eleifend, erat vel auctor lacinia, leo ante ultricies erat, id egestas diam dui eget risus. Fusce vel enim non libero tincidunt ornare. Duis eu lacinia erat, at pharetra turpis. Sed iaculis, ante sed iaculis auctor, sem tellus venenatis lacus, eget viverra justo dolor nec nisi. Donec rhoncus condimentum eros, sit amet eleifend elit posuere eget. Aenean vestibulum, ante nec sagittis ullamcorper, sapien metus ullamcorper velit, et pulvinar justo felis eu nibh. Aliquam sit amet porta nibh, pellentesque accumsan ligula. Vestibulum vel nulla aliquet tortor volutpat feugiat et in quam. Nunc eleifend mauris magna, eget tristique sem vulputate id. Sed varius finibus ex, sit amet gravida libero luctus ut. Suspendisse vulputate semper tellus sit amet dapibus.

Cras diam lorem, vehicula eget nisi quis, finibus pellentesque turpis. Fusce ac sodales nulla. Aliquam ipsum nisi, suscipit sit amet lacus ut, sollicitudin sagittis enim. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Etiam gravida ipsum vitae urna placerat, quis fringilla est eleifend. Aenean vehicula euismod sodales. Vestibulum et vulputate erat, vitae fermentum risus. Donec quis lectus at nisi aliquam accumsan. Maecenas pellentesque et pharetra maximus. Nulla id rhoncus felis.

Nam faucibus, libero at porta varius, nisl arcu bibendum ex, ac sodales lacus orci eget metus. Sed vel lectus at sapien imperdiet semper sollicitudin nec dui. Praesent ac arcu quis sapien bibendum varius. Phasellus sed lectus pharetra, sagittis nulla non, dapibus purus. Donec iaculis, lectus eu commodo congue, tellus erat malesuada leo, eu mollis nibh purus sodales mi. Aliquam venenatis magna vel nunc viverra, a luctus leo posuere. Cras ligula orci, fermentum ut venenatis ut, laoreet id ligula. Pellentesque posuere orci massa, in ultricies odio consectetur et. Vestibulum lectus felis, fringilla in erat eget, lacinia tempor lacus. Pellentesque eu sem augue. Praesent semper urna sit amet felis convallis, quis dignissim purus ultricies.

Suspendisse hendrerit auctor euismod. Nunc luctus mauris auctor blandit sodales. Fusce id maximus enim. Vivamus quis mollis tellus. Suspendisse potenti. Curabitur vestibulum dolor sit amet auctor lobortis. Praesent faucibus felis dui, vel egestas lorem fermentum ac. Phasellus placerat sodales mauris et eleifend. Donec auctor vel ipsum vel aliquet. Donec et purus et elit feugiat luctus ac in nisl. Aliquam sed ante quis felis venenatis efficitur. In posuere, arcu nec iaculis mattis, nunc dolor pretium tellus, vitae luctus dui risus a tortor. Nunc gravida tortor et elit ultrices imperdiet. Quisque feugiat lacus id justo egestas, non pretium diam ullamcorper.

Nullam a lectus nisl. Aenean sed quam tincidunt, placerat quam quis, congue orci. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas consequat odio non sapien rutrum, non mattis ex porta. Morbi vel interdum ex. Sed molestie felis bibendum justo lacinia sodales. Nulla posuere purus massa, eget mollis elit sagittis sit amet. Donec tempor, justo sed efficitur consequat, turpis quam congue justo, sed gravida nibh urna ac ante. Nullam congue justo mi, ut hendrerit massa pulvinar non. Donec sit amet convallis est. Suspendisse vitae nisl ut ante dignissim vehicula in nec ligula.

Nullam elit ligula, vehicula sit amet mollis faucibus, luctus quis velit. Duis vel efficitur orci. Phasellus facilisis nulla urna, vitae fermentum ipsum dignissim tempus. Etiam in justo luctus, bibendum nunc vel, convallis tortor. Duis blandit, ipsum ac vehicula auctor, nulla orci congue lectus, in posuere lacus velit malesuada ipsum. Donec ligula diam, dapibus eu ipsum eu, bibendum aliquam metus. Aliquam mattis dolor at elementum. Nam semper tellus velit, at molestie libero blandit ut. In et nulla ornare, aliquet nisl ut, tempor ex.

Quisque semper justo sed odio faucibus faucibus. Maecenas dapibus tellus a arcu sodales, id laoreet purus aliquet. Nunc tincidunt egestas viverra. Donec aliquam vitae arcu non blandit. Sed vel dolor efficitur, ultricies quam eget, tristique nisi. Vestibulum dictum purus enim, ut hendrerit risus iaculis at. Duis eget diam tortor. Donec eget laoreet lectus. Mauris non nisi dolor. Mauris congue sed purus eget semper. Fusce porttitor nibh ut purus pellentesque suscipit.

Praesent massa nulla, pellentesque eget tortor non, elementum varius sapien. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Morbi laoreet eleifend tortor a ultrices. Vivamus ut facilisis diam, sed aliquet lorem. Cras sed metus sit amet nibh commodo dapibus. Duis sed purus quis ante aliquet consequat accumsan vel velit. Sed tristique diam at lobortis iaculis. Integer imperdiet suscipit maximus. Vivamus nec risus placerat, semper ex sit amet, congue lectus. Etiam lacinia porttitor ullamcorper. Vestibulum aliquet vehicula metus et sodales. Nullam tincidunt leo ac justo placerat, sed rhoncus tellus tincidunt. Quisque finibus mauris a arcu iaculis, in eleifend lacus feugiat. Donec ultrices accumsan consectetur. Maecenas eu ipsum sed nisi porttitor sodales ac eu est.

Integer fringilla mattis urna a imperdiet. Mauris rhoncus purus sed eros tempus, id porta erat egestas. Aliquam finibus orci a ante pharetra efficitur. Quisque auctor id orci ac aliquet. Ut vestibulum nibh non ligula ornare tristique. Nunc hendrerit lorem efficitur, semper elit id, mollis justo. Curabitur imperdiet ac odio aliquet tincidunt.

Suspendisse fringilla ultricies sem ut feugiat. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Proin quis lectus sit amet neque mattis sagittis nec facilisis nulla. Fusce id pharetra lectus, ac blandit nulla. Proin mollis sit amet orci et cursus. Proin vehicula aliquet sapien et tincidunt. Cras dapibus et urna a venenatis. Nunc cursus magna iaculis gravida. Vivamus cursus nulla vel posuere gravida. Etiam facilisis nibh mi, posuere hendrerit enim auctor tincidunt. Donec aliquam sit amet leo ut lobortis. Curabitur lectus felis, dignissim eget augue auctor, elementum faucibus eros.

Donec auctor nunc sit amet faucibus bibendum. Phasellus tincidunt diam sed sem convallis semper. Sed turpis felis, maximus at dignissim nec, convallis aliquet sapien. Sed dignissim enim vulputate arcu mollis, ac vestibulum ipsum semper. Praesent tempor pellentesque turpis, nec efficitur lacus tempus at. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras ultrices dapibus molestie. Fusce luctus felis mauris, in auctor sapien porta ac.

Mauris porttitor ultrices sem, ac blandit est laoreet non. Proin ultrices cursus felis, et auctor leo consectetur ut. Aliquam turpis nunc, tempor ac ante ac, posuere ultricies dui. Suspendisse eget egestas est. Sed congue odio quis lectus hendrerit, sed ultricies nulla ornare. Vestibulum ut mauris sagittis, accumsan augue sed, condimentum neque. Pellentesque aliquet porta tortor ut semper. Duis id condimentum sem, eget condimentum felis. Phasellus facilisis ipsum rutrum facilisis pretium. Praesent fermentum urna vel luctus porta. Nulla accumsan ipsum eu purus dapibus, nec bibendum felis bibendum.

Sed tincidunt facilisis aliquam. Vivamus turpis tellus, tempor a elementum commodo, molestie et eros. Etiam tristique at urna et rutrum. Mauris elementum vestibulum felis, ac hendrerit erat ultricies ut. Fusce sodales consectetur leo non finibus. Fusce ultricies justo tortor, ac ultrices orci egestas et. Nulla sagittis risus rutrum bibendum suscipit. Praesent non semper neque. Nulla sem magna, condimentum vel rhoncus nec, aliquet vel massa. Nam pulvinar nunc quis magna interdum, vel feugiat felis suscipit. Suspendisse sed mauris accumsan, venenatis urna vel, convallis est. Nullam imperdiet blandit dolor, quis facilisis massa sollicitudin a. Vestibulum sed mauris et ipsum luctus accumsan. Donec auctor velit vitae finibus aliquam.

Maecenas quis turpis sit amet mauris euismod iaculis in sed orci. Praesent quis libero eget est rhoncus luctus. Etiam gravida aliquam velit, a tempus nisl eleifend in. Nunc vehicula non sem maximus fermentum. Duis quam neque, interdum non dignissim sed, laoreet eget enim. Vivamus vehicula nisi ut ante volutpat, ac efficitur lectus ornare. Donec et nibh in mi congue faucibus. Pellentesque sodales congue elit a blandit.

Praesent in velit nec enim rutrum mattis a eu massa. Praesent interdum, neque eu tincidunt facilisis, metus risus aliquam elit, non laoreet dui neque vitae dui. In pulvinar eu risus hendrerit pulvinar. Nam egestas imperdiet orci vel vestibulum. Vivamus pharetra fermentum ex, id efficitur ex venenatis ut. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. In hac habitasse platea dictumst. Vestibulum rhoncus mi id nunc placerat gravida. Nam ullamcorper consectetur tempor. Phasellus sed malesuada diam, vel tincidunt ipsum. Nunc laoreet, dolor ut iaculis semper, velit lorem vestibulum ligula, sit amet venenatis est libero eget justo. Interdum et malesuada fames ac ante ipsum primis in faucibus. Cras id rutrum nulla. Nunc pellentesque pretium sem ut pretium. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Quisque sit amet posuere tortor, in rutrum augue.

Curabitur egestas est vel venenatis lobortis. Ut vitae augue sollicitudin nisi sollicitudin rutrum vitae sed risus. Aliquam sed pharetra sapien. Pellentesque vel enim sed quam tristique sagittis. Nulla bibendum interdum sollicitudin. Vestibulum eleifend ipsum sodales massa volutpat, a maximus massa sollicitudin. Maecenas euismod tellus quis arcu euismod, non finibus leo fermentum. Integer dapibus turpis a ex ultrices blandit. Nulla consectetur massa sit amet scelerisque varius. Vestibulum dignissim, quam a mollis tincidunt, elit nisl accumsan dolor, sit amet mollis justo velit et leo. Phasellus sit amet consectetur orci, et eleifend tellus. Aliquam et ligula mauris. Pellentesque feugiat metus id libero maximus, nec eleifend augue dictum. Nam pulvinar augue quis facilisis commodo.

In suscipit diam justo, nec ornare felis luctus a. Nam ullamcorper felis ut vulputate rutrum. Curabitur fermentum nisl ac libero varius porttitor. Donec euismod, sem nec auctor posuere, ex lectus posuere purus, id facilisis justo turpis ac magna. Nam faucibus vulputate ullamcorper. Nam venenatis arcu ut posuere. Etiam quis tortor bibendum, tempus velit at, sagittis magna. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
Ut et elementum ex, vel elementum lorem. Proin semper vulputate est, sed blandit arcu dictum aliquet. Maecenas lorem metus, dapibus eu luctus ut, vestibulum ultrices augue. Phasellus sem nulla, semper eget aliquet ac, iaculis vel lectus. Duis ullamcorper purus ut metus vehicula posuere. Nam rhoncus tincidunt accumsan. Praesent ac ligula posuere, bibendum ante quis, dignissim lectus. Etiam mattis ullamcorper turpis nec euismod. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec imperdiet, eros vitae auctor blandit, est nibh laoreet nisi, et gravida libero elit in dolor. Aenean imperdiet pretium tellus, in cursus mi posuere in.

Suspendisse fringilla euismod ligula, in aliquet dui faucibus non. Praesent mi nunc, feugiat quis fermentum nec, convallis eget enim. Etiam at justo venenatis, volutpat ex sit amet, consectetur magna. Quisque sagittis, dui in sodales convallis, lorem tellus mattis tellus, et rhoncus augue ligula quis velit. Vestibulum in nibh sit amet metus tempus porta in laoreet nisi. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Donec et mollis metus, imperdiet convallis mi. Cras laoreet nisi tellus, nec fringilla tortor maximus eu. Cras nec urna vitae felis condimentum blandit. Suspendisse potenti. Ut fermentum consectetur felis.

Ut porta orci tortor, id maximus nibh efficitur viverra. Nullam id enim eu orci malesuada rutrum vitae at metus. Mauris dapibus justo at condimentum pretium. Cras suscipit dolor sapien, ac imperdiet arcu dapibus in. Ut rutrum nec turpis non varius. Fusce viverra ante, vitae faucibus metus fermentum non. Aenean eget lorem consequat, pretium leo nec, egestas augue. Aliquam a est velit. Integer pellentesque porta sapien, ut cursus purus dictum. Curabitur aliquam tortor a lobortis faucibus.

Sed accumsan velit id dignissim fermentum. Ut vitae congue diam. Aenean facilisis tempor neque non ornare. Sed tincidunt congue lorem, sed molestie velit sagittis non. Nullam ut enim sed dui scelerisque varius congue vitae dolor. Vivamus tempor, nisi quis vulputate finibus, ante eros feugiat nulla, interdum scelerisque odio est vel quam. Nunc quis libero ut eros bibendum lacinia sit amet eget ligula. Donec risus mauris, sodales in sem quis, consequat varius ante. Aenean posuere, dui a porta faucibus, nisl enim faucibus nisi, vitae vulputate eros orci in nulla. Duis pretium aliquet mi, eget malesuada tortor euismod nec. Nullam quis pharetra lacus. Aenean fringilla blandit tellus id cursus. Nam malesuada, est non dictum laoreet, ipsum nibh rutrum eros, eu cursus mi orci vitae orci. Nulla commodo tempus ante, vitae pretium dui. Fusce pellentesque commodo est non venenatis. Suspendisse fermentum purus sit amet euismod egestas.

Aliquam feugiat lorem vitae tortor suscipit, vel gravida odio auctor. Nullam non aliquam ligula. Nunc venenatis odio id est dictum, a egestas nunc gravida. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Mauris mollis turpis eu magna aliquet, non auctor mi gravida. Quisque ut odio scelerisque, gravida diam non, consequat lacus. Donec tristique ex dui, in auctor risus interdum ut. Fusce tristique condimentum faucibus. Ut tempus ligula dapibus pharetra auctor. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Sed eget massa vitae ante maximus facilisis et sit amet leo. Donec tempus in quam ut dignissim. Aenean at neque et lacus lacinia vehicula eget a felis. Curabitur lacinia, tellus commodo convallis scelerisque, dolor ipsum ultrices turpis, in imperdiet ante turpis a nisi.

Aliquam id ligula urna. Vivamus ut neque ipsum. Nam pharetra, sem volutpat maximus viverra, lorem eros consequat nisi, ut maximus eros nisl quis velit. Fusce magna ante, pharetra vel augue sed, tristique sagittis neque. Aliquam erat volutpat. Donec venenatis leo, eget ullamcorper neque vehicula ac. Phasellus luctus elit quis libero tristique, sed malesuada felis pulvinar. Integer et orci lectus. Quisque ornare enim eu mauris accumsan blandit. Ut massa dolor, faucibus eu diam tincidunt, tristique magna. Nulla purus dolor, volutpat non felis quis, aliquam auctor ante. Ut tristique at eros quis blandit.

Ut ultricies vel tellus id maximus. Proin hendrerit rhoncus massa at placerat. Nunc viverra tincidunt massa, non convallis justo viverra a. Nam elementum turpis at nibh ornare vulputate. Phasellus eu velit vehicula, consequat lectus non, feugiat dui. Nunc malesuada consequat ex, sed iaculis velit aliquam vitae. Curabitur mi est, viverra nec volutpat sed, scelerisque sit amet erat. Etiam maximus, orci ut molestie cursus, eros tortor commodo est, venenatis blandit urna dolor quis nulla.

Maecenas hendrerit efficitur magna in hendrerit. Proin dui orci, lacinia et scelerisque in, hendrerit gravida ante. Etiam quis augue eleifend, tempus lectus eu, hendrerit sapien. Donec non turpis auctor, iaculis ligula a, porta dolor. Quisque sit amet nisi ac enim auctor ornare sit amet et magna. Maecenas lorem odio, porta vel aliquam tristique, efficitur id quam. Donec varius id augue sagittis tempus. Aliquam erat volutpat.

Morbi dapibus augue in erat fermentum ornare. Ut tincidunt augue eget augue efficitur, in posuere ipsum vulputate. Maecenas molestie maximus enim, vitae ultricies leo. Vivamus facilisis suscipit sagittis. Proin at egestas nunc. Duis at arcu vitae sapien rutrum fringilla a in arcu. Aliquam erat volutpat. Integer quis nibh erat.

Curabitur consectetur arcu sed metus elementum varius. Morbi enim est, elementum vitae elit a, euismod tristique purus. In ultrices fermentum nunc, vel fringilla nisl. In ultricies, tellus ac laoreet rhoncus, dolor mauris gravida arcu, nec euismod lorem orci eu dui. Aenean pharetra hendrerit lacus sodales porta. Pellentesque tincidunt quis massa in volutpat. Cras ac luctus augue. Quisque nec diam sodales, efficitur turpis id, rhoncus purus. Pellentesque ut suscipit sem. Nulla sem turpis, euismod non leo et, interdum cursus orci. Duis pulvinar leo eu massa tincidunt malesuada a non magna. Integer eleifend augue nisi, in hendrerit odio porttitor vitae. Maecenas fermentum, eros pellentesque sagittis venenatis, nunc ligula laoreet nisl, nec consectetur lacus neque at lectus. Fusce et molestie velit, quis aliquet nisl. Proin luctus eros at mi dictum lacinia.

Nunc nisl tortor, scelerisque a congue feugiat, lacinia vitae nisl. Phasellus pharetra, erat vitae hendrerit egestas, erat arcu auctor nisl, in porta eros turpis nec purus. Aenean sapien erat, efficitur at risus in, tempor condimentum neque. Mauris sodales auctor augue, a volutpat libero molestie sed. Duis malesuada tortor lobortis eros posuere sodales. Phasellus placerat mattis rutrum. Phasellus euismod, nibh eu sodales bibendum, dui nisl efficitur felis, at gravida eros lectus non dui. Donec quam eros, pharetra in est sit amet, iaculis iaculis ligula. Etiam erat lacus, egestas ut placerat eget, malesuada at enim. Interdum et malesuada fames ac ante ipsum primis in faucibus. Integer quis ex tempor, tincidunt lorem at, rutrum risus. Mauris felis justo, ornare a euismod aliquet, tristique eget urna. Nulla risus arcu, molestie ut tellus in, tempus fringilla nulla.

Quisque hendrerit blandit scelerisque. Fusce at lacus egestas, pharetra nisi sit amet, sollicitudin massa. Donec lacinia egestas metus sit amet pharetra. Nulla blandit, nunc a suscipit mollis, nulla tellus blandit tortor, ut luctus lacus ipsum tempus mauris. Proin tempus, massa ac convallis sollicitudin, dolor urna dignissim velit, et efficitur odio eros vel nisl. Suspendisse at lorem augue. Suspendisse nisi urna, elementum metus eget, porta euismod orci. Pellentesque et fringilla augue. Suspendisse non orci nisi. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Sed porta elit et ipsum faucibus faucibus non ullamcorper turpis.

Mauris lacus nisi, semper a euismod eu, lobortis porttitor velit. Praesent suscipit nibh arcu, vel venenatis lorem elementum quis. Suspendisse potenti. Fusce lobortis libero sit amet eleifend laoreet. Praesent lacus dui, gravida vitae condimentum quis, suscipit non ante. Morbi magna dui, ornare ac venenatis non, condimentum id turpis. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Cras suscipit efficitur pretium. Nunc lobortis nisl vel libero posuere feugiat. Etiam ac sapien tincidunt, pellentesque tortor vel, ultricies neque. Donec aliquam ex in tempus iaculis. In nec enim pulvinar, hendrerit lectus eu, sollicitudin lorem. Nulla sit amet convallis sapien.

Nam porta quam ut eros maximus, a vehicula augue volutpat. Vestibulum ac lectus sed arcu tincidunt mollis. Cras ultrices tristique rutrum. Pellentesque sit amet lectus ac leo venenatis scelerisque in sit amet lorem. In tincidunt, tellus et porta tempus, mi justo varius eros, eu porta dui neque non turpis. Proin fringilla semper tortor, id fermentum felis auctor in. Nam pharetra, dolor eu condimentum pellentesque, arcu nulla interdum massa, ut tincidunt risus nulla quis nunc. Quisque vitae egestas libero. Vivamus in ex leo. Nam eu lacus odio. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Aenean tincidunt ante lectus, eget tempus odio venenatis vitae. Morbi luctus felis tristique odio venenatis, in auctor purus lobortis. Vivamus congue blandit purus, sit amet commodo dolor vestibulum ac. Phasellus viverra porta eleifend.

Vestibulum porta tortor quis ligula hendrerit lobortis. Cras sagittis non nisl sed aliquam. Etiam neque dui, elementum vel luctus non, condimentum non eros. Curabitur sed eleifend velit. Praesent volutpat blandit libero, blandit congue metus auctor eget. Interdum et malesuada fames ac ante ipsum primis in faucibus. Donec nec erat ornare, sollicitudin diam sed, accumsan nibh. Aliquam erat volutpat. Nullam bibendum sem sed felis posuere, eu iaculis orci iaculis. Maecenas eu nulla. Pellentesque metus nunc, lacinia at nisl ac, molestie feugiat turpis. Nam tellus nisl, blandit vel lorem et, ullamcorper sagittis erat. Aliquam porttitor, elit ut fringilla eleifend, lectus risus semper sem, eget vestibulum elit odio id dolor. Duis eu convallis mauris. Mauris ut arcu erat. Nam justo urna, fermentum vel eros ut, dignissim sagittis nunc.

Cras nec enim nibh. Mauris a nibh nec lacus porta bibendum. Integer pulvinar est purus, vel iaculis ligula pharetra vitae. Donec id iaculis augue, vel tempus nulla. Aliquam sed consectetur sem. Maecenas et sem erat. Praesent viverra est nec hendrerit varius. Maecenas iaculis congue tempus. Praesent vel mattis erat. Pellentesque porttitor magna at nibh dignissim, in sodales nisl aliquam. Pellentesque ac odio bibendum, tristique eros a, consequat ipsum.

Quisque iaculis sagittis lectus. Sed nisi dui, laoreet nec tellus vitae, sodales tincidunt nibh. Praesent sodales volutpat urna, vitae accumsan augue vulputate at. Nulla convallis, ex vel posuere feugiat, orci lorem ultrices orci, et accumsan felis turpis ac massa. Ut vitae turpis quis metus cursus dictum at nec orci. Vestibulum dignissim mollis auctor. Aliquam porttitor magna nisl, at condimentum mi pharetra quis. In eu nisl turpis. Cras pretium quam non commodo posuere. Nam at quam semper, tincidunt nisi id, rutrum velit. Aliquam erat volutpat. Aenean venenatis lectus eros, vitae viverra felis pulvinar sed. Morbi eget tellus pharetra, tincidunt dolor sed, sollicitudin metus. Praesent vel diam commodo, accumsan erat sit amet, dapibus dolor. Nulla elementum nisl nec porttitor malesuada. Fusce consequat quam mauris, ac egestas enim bibendum et.

Maecenas orci metus, elementum in convallis quis, luctus vel nisl. Cras enim erat, consequat a neque sed, tempor volutpat enim. Etiam eleifend condimentum ante, quis egestas turpis accumsan nec. Aliquam et diam semper, porta est quis, facilisis odio. Mauris diam nunc, ullamcorper feugiat felis iaculis, pharetra mauris. Donec semper venenatis suscipit. In id quam leo. Sed lacus lacus, tempor rhoncus tristique et, suscipit eu tellus. Morbi ac tellus sed ex dictum consequat. Donec aliquam elit pulvinar est malesuada pretium. Praesent in eros eleifend, ornare enim sed, lacinia diam.

Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Phasellus facilisis, quam quis mattis commodo, elit ex varius tortor, ut vestibulum elit urna non felis. Morbi tempus nulla eu ullamcorper porta. Nullam et risus in libero viverra gravida sed semper libero. Aliquam erat volutpat. Integer odio nibh, ultricies quis porta facilisis, posuere sed ex. Mauris purus augue, ornare id sagittis non, iaculis id eros. Sed mattis scelerisque orci, nec cursus dui euismod sed. Aenean egestas nibh id fermentum feugiat. Donec purus felis, scelerisque eget orci at, tempor egestas erat. Aenean in mauris nec orci lobortis iaculis quis vitae neque. Ut nec cursus lectus.

Maecenas malesuada elementum lorem, et malesuada felis iaculis et. Phasellus id nulla ac risus ultrices feugiat ac vitae nibh. Morbi at mi felis. Phasellus euismod, mauris at suscipit fringilla, nunc quam elementum orci, a consectetur turpis massa et elit. Donec volutpat egestas sagittis. Donec vel nulla at dolor auctor iaculis. Maecenas placerat mi sit amet nisl tincidunt, nec iaculis nisl aliquet. Nullam pretium dolor at dolor eleifend, eu euismod massa feugiat. Curabitur gravida nunc eu viverra ornare. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.

Sed volutpat tempus metus, at cursus nunc consequat quis. Donec eu ex urna. Pellentesque lacus lorem, mattis in dignissim at, fermentum et ligula. Quisque lacus turpis, consectetur nec cursus eget, fermentum quis sem. Sed finibus velit nec felis accumsan faucibus. Aliquam sit amet lobortis justo, in vehicula arcu. Nunc odio augue, mollis id volutpat in, rutrum et dolor. Nunc et scelerisque odio. Morbi tristique eleifend nunc et bibendum. Aliquam non mauris orci. Sed ante erat, scelerisque accumsan tincidunt id, hendrerit eget nunc. Integer iaculis ullamcorper luctus. Proin malesuada sem non enim aliquet sagittis. Mauris ac tortor ac dui condimentum malesuada ac eget mauris.

Etiam quis mattis tortor. Vivamus vel ante at mi iaculis aliquam. Cras id sem quam. Praesent congue massa tincidunt, feugiat purus sed, eleifend ex. Quisque sed vulputate neque. Pellentesque ac tristique mi. Mauris a vulputate ex, ac ultricies tellus. Praesent vitae purus non lorem placerat mattis in et nulla. Aliquam arcu eros, hendrerit eu enim eu, auctor laoreet eros. Cras id vulputate nisi, eu rhoncus quam. Fusce hendrerit ex in sapien elementum, in gravida odio pellentesque. Mauris dictum facilisis augue, ac dignissim felis vel. Maecenas nec enim in nisi imperdiet facilisis eget eget ipsum. Curabitur eu ullamcorper odio. Integer ullamcorper, felis nec sagittis finibus, odio neque auctor quam, sit amet viverra justo nulla quis ligula. Lorem ipsum dolor sit amet, consectetur adipiscing elit.

Maecenas in euismod eros, ac mattis ligula. Ut tempor suscipit porttitor. Quisque dapibus ipsum consectetur nisi congue, et volutpat nisi condimentum. Sed a finibus ante, iaculis pretium magna. Phasellus vel mi justo. Morbi ultricies malesuada justo, eget egestas ante sodales nec. Maecenas massa orci, malesuada eget luctus eu, egestas eget eros. Vivamus sollicitudin ultrices ligula, ut auctor justo volutpat at. Etiam dignissim ligula ac eros sollicitudin tristique. Nam in volutpat quam. Nam a nisi ut lorem suscipit condimentum. Fusce a eros id turpis faucibus ultricies hendrerit non purus. Praesent volutpat nulla urna. Sed molestie risus tellus, ac dictum mauris molestie ac. Pellentesque nunc justo, viverra non pellentesque vel, dictum ac orci.

Pellentesque accumsan sem tellus, at blandit lorem finibus vitae. Sed quis aliquam quam, ac eleifend justo. Morbi vehicula, metus ut vestibulum auctor, diam eros ultrices enim, non tempor metus lectus ut tortor. Suspendisse potenti. Praesent nec neque fermentum, dignissim magna eget, vulputate metus. Sed eget faucibus felis. Sed scelerisque dictum odio a vehicula.

Vestibulum sed ullamcorper felis. Maecenas purus tellus, consequat at lobortis non, eleifend sed libero. Maecenas eget egestas augue, nec finibus quam. Sed ornare porta nisl sed cursus. Aliquam dapibus velit sed odio condimentum porttitor. Fusce ante dui, pharetra eget lectus non, ornare eleifend mauris. Ut magna quam, euismod a risus vitae, volutpat laoreet ante. Quisque commodo neque eu diam consectetur, nec pulvinar purus imperdiet. Cras interdum, libero eget bibendum aliquam, magna ipsum lobortis arcu, sed feugiat arcu tortor et nunc. Curabitur sit amet posuere nulla. Quisque vestibulum diam non felis porta dapibus.

Nulla facilisi. Praesent vestibulum tincidunt aliquam. Curabitur turpis augue, tincidunt id gravida vitae, dapibus vel tortor. Integer a neque eu turpis gravida suscipit. Donec dictum metus in nisl luctus sagittis. Suspendisse hendrerit viverra lacinia. Praesent elit ligula, iaculis at sapien vel, lacinia varius arcu. Sed eleifend gravida lorem, sit amet vulputate urna molestie nec. Donec ac placerat arcu. Sed placerat ipsum, sed molestie diam sollicitudin sed. Mauris elit est, dapibus eu lacus eget, imperdiet egestas orci. Nullam fermentum tortor id urna vestibulum, vel aliquet quam mattis. Mauris rhoncus sed lectus sit amet viverra.

Cras pellentesque ornare ultricies. Suspendisse scelerisque placerat faucibus. Cras vitae nisl vehicula, hendrerit sem eu, scelerisque mi. Sed cursus quam cursus consectetur porta. Aliquam a magna elementum, consequat mi id, pulvinar orci. Maecenas gravida ligula vitae suscipit mattis. Nam sed turpis velit. Aenean ante felis, eleifend vel enim sit amet, ullamcorper efficitur lorem. Aenean interdum ante sit amet quam iaculis mattis. Nullam viverra ligula id mattis rutrum.

Maecenas nisi purus, pulvinar vitae risus commodo, pharetra dignissim erat. Donec imperdiet magna ut velit pretium, vel blandit nulla mattis. Praesent eu justo nunc. Aenean id mi eget augue congue placerat. Fusce ornare ante non lorem dignissim viverra. Quisque sit amet rhoncus ante. Sed lacinia arcu ut sollicitudin sagittis. Duis congue scelerisque diam, ut dapibus urna cursus in. Duis auctor in nulla sed ultricies. Aliquam et ullamcorper turpis, non dictum orci. In a tempor massa, non gravida lacus. Morbi ultricies, nisi eget ullamcorper fermentum, tortor est dignissim nibh, a consequat arcu risus efficitur felis.

Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Sed sed condimentum purus, non tincidunt risus. Maecenas ultrices ex vitae felis luctus, vel gravida arcu feugiat. Nulla quis nulla magna. Fusce et felis vel quam pretium pellentesque. Proin tristique gravida placerat. Aliquam dapibus, ligula id vestibulum tempus, massa mi maximus orci, ac fermentum orci velit eget nisi. Suspendisse eget lacinia est. Cras vulputate dignissim urna eu condimentum. Quisque feugiat lectus odio, vitae fringilla erat vehicula at. Etiam laoreet vel magna nec gravida. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Pellentesque cursus quam tortor, in aliquet lectus porttitor id. Nunc quis nunc nec massa tristique commodo non a velit. Integer aliquet quam sit diam mollis, non consectetur orci tempus. Curabitur finibus non leo quis viverra.

Cras scelerisque orci sit amet metus facilisis, non condimentum odio consequat. Nulla tempor mauris quis felis maximus, ac fermentum elit elementum. Ut consectetur eget augue a auctor. Donec blandit fringilla nunc, quis pulvinar est pellentesque ac. Quisque ac congue tortor. Sed nec lectus semper, luctus erat ut, vestibulum ante. Duis fermentum enim sed laoreet tempus. Proin placerat, orci eu convallis tincidunt, ipsum nisl suscipit risus, at pulvinar ligula enim eget dolor. Donec eget tincidunt enim.

Proin ultricies pellentesque elementum. Nam venenatis diam nulla, vitae suscipit nisl vulputate eget. Sed velit ante, sagittis vel ullamcorper a, varius sit amet urna. Nulla sollicitudin non eros ut pretium. Curabitur pulvinar efficitur posuere. Sed nec fermentum ante, et volutpat odio. Mauris porttitor ex non posuere lacinia. Proin vestibulum ante metus, ac placerat nunc egestas in. Sed hendrerit tempor tincidunt. Donec vel lectus pellentesque, finibus arcu in, auctor nisi. Sed aliquet ultrices ex. Nulla facilisi. Nam nibh libero, commodo nec lacus at, cursus pretium sem. Nulla vel sapien aliquam, tincidunt felis sit amet, placerat mauris. Praesent id accumsan ex, vitae volutpat tellus.

Nullam vestibulum sem eget arcu maximus sagittis. Suspendisse potenti. Sed et porttitor leo. In suscipit, elit eget dictum finibus, risus nunc feugiat nisl, porttitor condimentum lectus sem quis est. Nunc a lacus leo. Proin dapibus sem bibendum sem lobortis tempus. Etiam nec magna suscipit, molestie neque eget, dignissim justo. Curabitur risus mauris, maximus quis est placerat, faucibus aliquet arcu. Donec nec turpis volutpat, imperdiet quam sit amet, laoreet ligula. Pellentesque vitae euismod velit. Nam consectetur mauris non sem aliquam, eget posuere libero maximus.

Suspendisse consectetur lacus volutpat fringilla egestas. Pellentesque id est ac vulputate ullamcorper eget vel ante. Aenean ultrices elit sit amet enim volutpat, commodo porttitor elit posuere. In risus purus, semper in maximus vitae, laoreet commodo lacus. Nam mauris neque, euismod eget luctus a, faucibus quis sapien. Nullam ante sem, tincidunt non porttitor at, interdum vitae orci. Nulla gravida massa vitae sem scelerisque, maximus fermentum mauris elementum. Mauris faucibus aliquam tempor. Mauris at luctus ligula.

Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nunc euismod enim at euismod vehicula. Quisque molestie, mi ac congue finibus, lectus erat vehicula tellus, eu ultrices lacus sapien sit amet est. Interdum et malesuada fames ac ante ipsum primis in faucibus. Phasellus ullamcorper et turpis dictum feugiat. Cras elementum ipsum id volutpat iaculis. Donec facilisis nunc quis lacus posuere volutpat. Nunc ante dolor, pulvinar id congue et, vulputate ut sapien. Etiam non lorem vel odio tristique tincidunt.

Praesent mauris eros, bibendum ut purus et, malesuada euismod elit. Vivamus a enim dignissim, bibendum libero ac, pulvinar lorem. Fusce non pretium mauris, at pulvinar lorem. Aenean venenatis mattis eros, et mollis felis gravida non. Fusce a consectetur erat, ut venenatis erat. Quisque a lectus magna. Suspendisse placerat, neque id finibus pulvinar, tortor felis faucibus ligula, ut molestie eros purus vel sapien. Nunc eu turpis sit amet mauris venenatis imperdiet. Integer sed felis quis dolor egestas ullamcorper at nec nulla. Donec nec dui sollicitudin, pretium justo non, suscipit nulla. Quisque dictum mi ac felis posuere lobortis. Cras at ipsum massa. Sed dignissim dictum risus id venenatis. Aenean vel turpis venenatis, lacinia erat ut, sagittis leo. Nulla et scelerisque leo. Etiam iaculis vulputate libero semper bibendum.

Mauris commodo eros eros, at faucibus massa eleifend quis. Nullam tincidunt, dui sed aliquet elementum, nibh turpis faucibus justo, quis convallis turpis ipsum in ex. Ut eros metus, consectetur sit amet arcu at, faucibus vulputate mauris. Duis vitae lectus lacinia, imperdiet quam ac, dignissim sapien. Duis aliquet, enim et rhoncus vulputate, arcu magna vestibulum neque, sit amet egestas tortor orci et lectus. Aliquam maximus ex id quam hendrerit scelerisque. Vivamus tincidunt, nunc a sollicitudin auctor, nisl diam pellentesque nibh, a tempor lacus nibh id sem. In metus nulla, ullamcorper quis magna a, accumsan sodales nisl. Proin malesuada tortor tortor, placerat elementum arcu vulputate ac. Quisque maximus velit ut magna scelerisque condimentum.

Donec ante est, ultricies ac orci ac, egestas feugiat sem. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Donec sodales dictum quam vel semper. Phasellus in ligula lacinia, dictum magna vitae, cursus sem. Nullam ornare et neque quis gravida. Nullam ultrices dictum ante, id mollis tellus maximus malesuada. Aenean iaculis tellus eu accumsan elementum. Aenean mollis congue felis sit amet imperdiet. Vivamus rutrum condimentum vehicula. Integer nec mollis ipsum. Quisque id sapien porttitor tortor faucibus rutrum id vel.

Praesent quis ex in risus euismod bibendum. Integer porttitor diam nisl, sit amet porttitor eros tristique ac. Pellentesque condimentum sem sed eros mollis fermentum. Duis sit amet justo vel velit euismod varius et nec urna. Donec et est vitae lorem condimentum dapibus. Phasellus tincidunt tellus et eros commodo, quis ullamcorper velit euismod. Donec viverra interdum tincidunt. Morbi elementum placerat bibendum. Aliquam elementum ultrices tellus."
	restart_server
	$CLIENT $SRV_PORT "$msg" > /dev/null 2>&1
	sleep 0.5
	local out; out=$(srv_out)
	[ "$out" = "$msg" ] \
		&& pass_test "long lorem ipsum (${#msg} chars)" \
		|| fail_test "long lorem ipsum" "mismatch — got: '${out:0:50}...'"
}

test_unicode() {
	local msg="café résumé naïve"
	restart_server
	$CLIENT $SRV_PORT "$msg" > /dev/null 2>&1
	sleep 0.3
	local out; out=$(srv_out)
	[ "$out" = "$msg" ] \
		&& pass_test "unicode — accented latin" \
		|| fail_test "unicode" "expected '${msg}' got '${out}'"
}

test_sequential_messages() {
	restart_server
	$CLIENT $SRV_PORT "first"  > /dev/null 2>&1
	$CLIENT $SRV_PORT "second" > /dev/null 2>&1
	$CLIENT $SRV_PORT "third"  > /dev/null 2>&1
	sleep 0.3
	local l1 l2 l3
	l1=$(sed -n '2p' "$SRV_OUT")
	l2=$(sed -n '3p' "$SRV_OUT")
	l3=$(sed -n '4p' "$SRV_OUT")
	[ "$l1" = "first" ] && [ "$l2" = "second" ] && [ "$l3" = "third" ] \
		&& pass_test "sequential messages — correct order" \
		|| fail_test "sequential messages" "got '${l1}' '${l2}' '${l3}'"
}

test_concurrent_no_interleave() {
	restart_server
	$CLIENT $SRV_PORT "alpha" > /dev/null 2>&1 & C1=$!
	$CLIENT $SRV_PORT "beta"  > /dev/null 2>&1 & C2=$!
	$CLIENT $SRV_PORT "gamma" > /dev/null 2>&1 & C3=$!
	wait $C1 $C2 $C3
	sleep 0.2
	local a b g
	a=$(srv_out | grep -cx "alpha")
	b=$(srv_out | grep -cx "beta")
	g=$(srv_out | grep -cx "gamma")
	[ "$a" = "1" ] && [ "$b" = "1" ] && [ "$g" = "1" ] \
		&& pass_test "concurrent clients — no interleaving, all 3 complete" \
		|| fail_test "concurrent clients" "alpha:${a} beta:${b} gamma:${g} (want 1 each)"
}

test_repeated_same_message() {
	restart_server
	for i in $(seq 1 5); do $CLIENT $SRV_PORT "repeat" > /dev/null 2>&1; done
	sleep 0.3
	local n; n=$(srv_out | grep -cx "repeat")
	[ "$n" = "5" ] \
		&& pass_test "same message ×5 — all received" \
		|| fail_test "same message ×5" "got ${n}/5"
}

test_dead_client_server_continues() {
	restart_server
	local long; long=$(python3 -c 'print("x"*200, end="")')
	$CLIENT $SRV_PORT "$long" > /dev/null 2>&1 & DEAD=$!
	sleep 0.15
	kill -9 $DEAD 2>/dev/null
	wait $DEAD 2>/dev/null
	# server timeout is DEAD_TICKS × TICK_US = 20 × 100ms = 2s
	sleep 2.5
	$CLIENT $SRV_PORT "survivor" > /dev/null 2>&1
	sleep 0.3
	local got; got=$(srv_out | tail -1)
	[ "$got" = "survivor" ] \
		&& pass_test "dead client — server recovers, next message clean" \
		|| fail_test "dead client" "last server line: '${got}'"
}

test_queue_overflow_all_delivered() {
	restart_server
	local pids=()
	for i in $(seq 1 12); do
		$CLIENT $SRV_PORT "msg${i}" > /dev/null 2>&1 & pids+=($!)
	done
	wait "${pids[@]}"
	sleep 0.3
	local n; n=$(srv_out | wc -l)
	[ "$n" -eq 12 ] \
		&& pass_test "queue overflow — 12 clients (MAX_Q=10), all delivered" \
		|| fail_test "queue overflow" "${n}/12 delivered"
}

test_server_dead_before_connect() {
	restart_server
	local dead_port=$SRV_PORT
	stop_server
	sleep 0.1
	$CLIENT $dead_port "nope" > /dev/null 2>&1
	[ $? -ne 0 ] \
		&& pass_test "server dead before connect — client error exit" \
		|| fail_test "server dead before connect" "client exited 0"
}

test_server_dies_mid_transmission() {
	restart_server
	local long; long=$(python3 -c 'print("x"*3000, end="")')
	$CLIENT $SRV_PORT "$long" > /dev/null 2>&1 & C1=$!
	sleep 0.03
	stop_server
	wait $C1; local code=$?
	cleanup_clients
	[ $code -ne 0 ] \
		&& pass_test "server dies mid-transmission — client error exit" \
		|| fail_test "server dies mid-transmission" "client exited 0"
}

test_invalid_pid() {
	$CLIENT 99999999 "hello" > /dev/null 2>&1
	[ $? -ne 0 ] \
		&& pass_test "invalid PID — client error exit" \
		|| fail_test "invalid PID" "exited 0"
}

test_non_numeric_pid() {
	$CLIENT "notapid" "hello" > /dev/null 2>&1
	[ $? -ne 0 ] \
		&& pass_test "non-numeric PID — client error exit" \
		|| fail_test "non-numeric PID" "exited 0"
}

test_wrong_argc() {
	local ok=1
	$CLIENT > /dev/null 2>&1               && ok=0
	$CLIENT 123 > /dev/null 2>&1           && ok=0
	$CLIENT 123 "a" "x" > /dev/null 2>&1  && ok=0
	[ $ok -eq 1 ] \
		&& pass_test "wrong argument count (0/1/3 args) — all error exit" \
		|| fail_test "wrong argument count" "at least one case exited 0"
}

# ── main ──────────────────────────────────────

echo ""
echo -e "${BOLD}minitalk test suite${RESET}"
echo "────────────────────────────────────"

if ! make -s re 2>/tmp/mt_err.txt; then
	echo -e "${RED}compilation failed:${RESET}"; cat /tmp/mt_err.txt; exit 1
fi
echo -e "${GREEN}compilation: OK${RESET}"

section "correctness"
test_basic_message
test_empty_string
test_special_chars
test_numbers
test_long_lorem
test_unicode
test_sequential_messages

section "concurrency"
test_concurrent_no_interleave
test_repeated_same_message

section "robustness"
test_dead_client_server_continues
test_queue_overflow_all_delivered

section "server death"
test_server_dead_before_connect
test_server_dies_mid_transmission

section "bad input"
test_invalid_pid
test_non_numeric_pid
test_wrong_argc

nuke_all

echo ""
echo "────────────────────────────────────"
TOTAL=$((PASS + FAIL))
[ $FAIL -eq 0 ] \
	&& echo -e "${GREEN}${BOLD}all ${TOTAL} tests passed${RESET}" \
	|| echo -e "${RED}${BOLD}${FAIL}/${TOTAL} tests failed${RESET}"
echo ""
[ $FAIL -eq 0 ] && exit 0 || exit 1
