#!/bin/bash

cd $(echo $0 | sed 's#/[^/]*$##')

touch twitter-api-rss.xml last.html
curl -s "https://dev.twitter.com/docs/recent" > recent.html

if ! diff last.html recent.html |
  grep "-v" 'type="hidden"' |
  grep "<" > /dev/null; then
    rm -f recent.html
    exit 0
fi

now=$(date -R)
date=""
title=""
link=""

echo "<?xml version=\"1.0\"?>
<rss version=\"2.0\">
 <channel>
  <title>Twitter API Recently Updated Documentation</title>
  <link>https://dev.twitter.com/docs/recent</link>
  <description>Twitter API Recently Updated Documentation</description>
  <pubDate>$now</pubDate>
  <generator>RouxRC</generator>" > twitter-api-rss.xml

cat recent.html |
  tr '\n' ' ' |
  sed 's/<\/\?t/\n<t/g' |
  sed 's/\s\+/ /g' |
  grep -v '"> Description' |
  grep "<caption\|views-field-body\|views-field-title.*<a" |
  sed 's#href="\([^"]\+\)"#>https://dev.twitter.com\1;<#' |
  sed 's/\s*<[^>]*>\s*//g' |
  while read line; do
    if echo $line | grep "[A-Z].* [0-9]\+, 20" > /dev/null; then
      day=$(echo $line | sed 's/^\(...\).* \([0-9\]\+\), 20\([0-9]\+\)/\1 \2 20\3/')
      date=$(date -R -d "$day")
    elif echo $line | grep "https://dev.twitter.com/.*;" > /dev/null; then
      title=$(echo $line | sed 's/^[^;]\+;//')
      link=$(echo $line | sed 's/;.*$//')
    else
      echo "  <item>
   <title>$title</title>
   <link>$link</link>
   <description><![CDATA[$line]]></description>
   <pubDate>$date</pubDate>
  </item>" >> twitter-api-rss.xml
    fi
  done

echo " </channel>
</rss>" >> twitter-api-rss.xml

mv -f recent.html last.html

git commit last.html twitter-api-rss.xml -m "update rss"
git push

