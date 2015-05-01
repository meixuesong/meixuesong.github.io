rake generate
echo "生成RSS"
cd /Users/meixuesong/Develop/projects/OctopressRSS/bin/
java -classpath ./:/Users/meixuesong/Develop/projects/OctopressRSS/jsoup-1.8.1.jar com.ubone.octopress.rss.GenerateOctopressRss /Users/meixuesong/Documents/blog/public/blog/archives/index.html /Users/meixuesong/Documents/blog/public/rss.xml http://blog.ubone.com
cd /Users/meixuesong/Documents/blog
rake deploy
git add .
git commit -m '写博客'
git push origin source
echo "发布结束"
#cd _deploy
#echo "=============发布到Gitcafe============="
#git remote add gitcafe git@gitcafe.com:meixuesong/meixuesong.git >> /dev/null 2>&1
#git push -u gitcafe master:gitcafe-pages