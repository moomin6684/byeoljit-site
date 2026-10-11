#!/bin/zsh
# 이 폴더(정적 안내 페이지)만 공개 저장소로 올리고 GitHub Pages 를 켠다. 별짓 앱 저장소(~/byeoljit)는 건드리지 않는다.
# 사용: GitHub 에 로그인한 뒤(gh auth login) 이 폴더에서  ./publish.sh
set -e
cd "${0:A:h}"
REPO="${1:-byeoljit-site}"
command -v gh >/dev/null || { print 'GitHub CLI(gh)가 없습니다. 먼저:  brew install gh'; exit 1; }
gh auth status >/dev/null 2>&1 || { print 'GitHub 에 로그인돼 있지 않습니다. 먼저:  gh auth login'; exit 1; }
USER_NAME="$(gh api user --jq .login)"
# 올라갈 파일을 확인한다: 정적 파일 외의 것이 있으면 멈춘다
BAD="$(git ls-files | grep -vE '^(index\.html|privacy\.html|style\.css|README\.md|\.nojekyll|publish\.sh|google[0-9a-f]+\.html)$' || true)"
[[ -z "$BAD" ]] || { print "공개용이 아닌 파일이 있어 멈춥니다:\n$BAD"; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { git add -A; git commit -qm '안내 페이지 갱신'; }
if gh repo view "$USER_NAME/$REPO" >/dev/null 2>&1; then
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$USER_NAME/$REPO.git"
  git push -u origin main
else
  gh repo create "$REPO" --public --source=. --remote=origin --push --description '별짓(Byeoljit) 안내 페이지 · 개인정보처리방침'
fi
# Pages: main 브랜치의 루트를 게시한다(이미 켜져 있으면 그대로 둔다)
gh api "repos/$USER_NAME/$REPO/pages" >/dev/null 2>&1 || gh api -X POST "repos/$USER_NAME/$REPO/pages" -f 'source[branch]=main' -f 'source[path]=/' >/dev/null
BASE="https://${USER_NAME:l}.github.io/$REPO"
print "\n게시를 요청했습니다. 처음에는 1~3분쯤 걸립니다. 열리는지 확인합니다…"
for i in {1..40}; do
  if [[ "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/")" == 200 && "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/privacy.html")" == 200 ]]; then OK=1; break; fi
  sleep 6
done
[[ -n "$OK" ]] && print '두 페이지가 로그인 없이 열립니다.' || print '아직 열리지 않습니다. 몇 분 뒤 아래 주소를 직접 열어 보세요.'
print "\nGoogle Cloud 에 입력할 값"
print "  홈페이지 URL          : $BASE/"
print "  개인정보처리방침 URL  : $BASE/privacy.html"
print "  승인된 도메인         : ${USER_NAME:l}.github.io"
