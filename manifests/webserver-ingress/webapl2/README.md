# コンテナのビルド方法

次のコマンドでコンテナイメージをビルドする

~~~
docker build -t maho/webapl3:0.1 .
~~~

Kubernetesクラスタで利用できるようにするため、コンテナレジストリへ登録する。

~~~
docker push maho/webapl3:0.1
~~~

