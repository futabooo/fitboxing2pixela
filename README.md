# fitboxing2pixela

Fit Boxing 2のResult画面のスクショのURLを投稿するとPixelaに推定消費カロリーを記録するGoogle Cloud Functions（Cloud Run）です。

<img src="https://user-images.githubusercontent.com/944185/215278691-27660202-a961-4de7-96fe-b21729a697fe.png" width="640">

[dartfn](https://github.com/GoogleCloudPlatform/functions-framework-dart/tree/main/dartfn)というDartでGoogle Cloud Functionsを使う時に便利なツールを使ってプロジェクトを作成しています。


## ローカル環境での動作確認

Dockerを使用してローカル環境でFunctionをシミュレートすることができます。

### 環境変数の設定

`.env.sample`から`.env`を作成します。

```shell
$ cp .env.sample .env
```

`.env`を編集して環境変数を設定します。

`PIXELA_USER_TOKEN_KEY`はSecretManagerのkey名を想定しています。

```shell
GCP_PROJECT={your_gcp_project_id}
PIXELA_USER_TOKEN_KEY={your_pixela_user_token_key}
PIXELA_USER_NAME={your_pixela_id}
PIXELA_GRAPH_ID={your_pixela_graph_id}
```

### Dockerの実行

dockerでアプリケーションを実行します。

```shell
$ docker build -t fitboxing2pixela .
...

$ docker run -it -p 8080:8080 --name app fitboxing2pixela
Listening on :8080
```

### Pixelaグラフへの追加

他のターミナルからcurlを実行してみるとPixelaのグラフに追加されます。

```shell
curl http://localhost:8080?url=https://pbs.twimg.com/media/FmXCf54aAAEQdWQ?format=jpg&name=large&date=2023-01-15T13:06:48.000Z

```

