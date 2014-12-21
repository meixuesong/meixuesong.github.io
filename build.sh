rake generate
echo "生成RSS"
cd /Users/mxs/Develop/projects/rss2epub/OctopressRSS/bin/
java -classpath ./:/Users/mxs/Develop/projects/rss2epub/OctopressRSS/jsoup-1.8.1.jar com.ubone.octopress.rss.GenerateOctopressRss /Users/mxs/Documents/blog/public/blog/archives/index.html /Users/mxs/Documents/blog/public/rss.xml http://blog.ubone.com
cd /Users/mxs/Documents/blog
rake deploy
git add .
git commit -m '写博客'
git push origin source
echo "发布结束"
#cd _deploy
#echo "=============发布到Gitcafe============="
#git remote add gitcafe git@gitcafe.com:meixuesong/meixuesong.git >> /dev/null 2>&1
#git push -u gitcafe master:gitcafe-pages