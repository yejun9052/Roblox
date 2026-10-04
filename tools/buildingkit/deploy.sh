#!/bin/sh
# 키트 소스를 합쳐 로컬 수신기 inbox 로 복사: kit.luau + kit_types2.luau + "return Kit"
# 사용: sh tools/buildingkit/deploy.sh <inbox 디렉터리>
set -e
D="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:?inbox dir}"
{ cat "$D/kit.luau"; [ -f "$D/kit_types2.luau" ] && cat "$D/kit_types2.luau"; [ -f "$D/kit_nature.luau" ] && cat "$D/kit_nature.luau"; [ -f "$D/kit_apoc.luau" ] && cat "$D/kit_apoc.luau"; [ -f "$D/kit_seoul.luau" ] && cat "$D/kit_seoul.luau"; [ -f "$D/kit_signs.luau" ] && cat "$D/kit_signs.luau"; [ -f "$D/kit_tex_v3.luau" ] && cat "$D/kit_tex_v3.luau"; [ -f "$D/kit_street.luau" ] && cat "$D/kit_street.luau"; printf '\nreturn Kit\n'; } > "$OUT/kit.luau"
echo "deployed $(wc -l < "$OUT/kit.luau") lines"
