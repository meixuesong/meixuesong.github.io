rake generate
rake deploy
git add .
git commit -m '写博客'
git push origin source
echo "发布结束"
#cd _deploy
#echo "=============发布到Gitcafe============="
#git remote add gitcafe git@gitcafe.com:meixuesong/meixuesong.git >> /dev/null 2>&1
#git push -u gitcafe master:gitcafe-pages