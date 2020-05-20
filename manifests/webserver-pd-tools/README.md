# ポッドのPDツール

このマニフェストでデプロイされるポッドには、dns, ss, nslookup, ping, netstat, ps, curl などのコマンドが入っています。
少々大きなサイズのコンテナですが、問題判別のために役立てることごができます。


このデイレクトリ上で、以下でDocker Hubへ登録しています。

~~~
$ docker build -t maho/pdtools:1.0 .

$ docker login

$ docker push maho/pdtools:1.0
~~~

