# サーバーレスリファレンスアーキテクチャ: モバイルバックエンド

## はじめに

モバイルバックエンドリファレンスアーキテクチャ ([図](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf)) は、[AWS Lambda](http://aws.amazon.com/lambda/) をその他のサービスとともに使用してモバイルアプリケーション用のサーバーレスバックエンドを構築する方法を示します。このレポジトリに用意されているサンプルアプリケーションにより、Amazon Simple Storage Service (Amazon S3) および Amazon API Gateway を使用して、それぞれ写真とメモをアップロードすることができます。メモは Amazon DynamoDB に保存され、DynamoDB ストリームおよび Lambda 関数を使用して非同期に処理されて Amazon CloudSearch ドメインに追加されます。このレポジトリには、Lambda 関数のソースコードに加えて、AWS Mobile SDK for iOS を使用して、アーキテクチャで定義されたバックエンドリソースを操作する方法の例を示すプロトタイプ iOS アプリケーションも含まれています。

## 例の実行

完全なサンプルアプリケーションを実行するには、最初にバックエンドリソースをデプロイしてから、iOS サンプルアプリケーションをコンパイルおよび実行する必要があります。

### バックエンドのデプロイ

用意された AWS CloudFormation テンプレートでは、この例に必要なバックエンドリソースのほとんどが作成されますが、AWS CloudFormation 外部に Amazon CloudSearch ドメイン、API Gateway REST API、および Cognito ID プールを作成する必要があります。

#### ステップ 1: CloudSearch ドメインを作成する

1.[AWS CLI](https://aws.amazon.com/cli/) を使用して、任意のドメイン名を提供する新しい CloudSearch ドメインを作成します。

    ```
    aws cloudsearch create-domain --domain-name [ドメイン名]
    ```

1.出力ドキュメントの新しいドメインの ARN をメモしておきます。CloudFormation スタックを起動するときに、これを入力として使用します。

1.`headline` および `note_text` フィールドのインデックスを定義します。

    ```
    aws cloudsearch define-index-field --name headline --type text --domain-name [ドメイン名]
    aws cloudsearch define-index-field --name note_text --type text --domain-name [ドメイン名]
    ```

    ```
    aws cloudsearch index-documents --domain-name [YOUR_DOMAIN_NAME]
    ```

#### ステップ 2: API Gateway REST API を作成する

1.[AWS CLI](https://aws.amazon.com/cli/) を使用し、任意の名前を指定して新しい API を作成します。

    ```
    aws apigateway create-rest-api --name [API 名]
    ```

1.出力ドキュメントの `API ID` をメモしておきます。CloudFormation スタックを起動するときに、これを入力として使用します。

#### ステップ 3: Amazon Cognito ID プールを作成する

1.[AWS CLI](https://aws.amazon.com/cli/) を使用し、任意の名前を指定して新しい ID プールを作成します。

    ```
    aws cognito-identity create-identity-pool --allow-unauthenticated-identities --identity-pool-name [プール名]
    ```

1.出力ドキュメントの `IdentityPoolId` をメモしておきます。CloudFormation スタックを起動するときに、これをパラメーターとして使用します。

#### ステップ 4: CloudFormation テンプレートを起動する

用意された CloudFormation テンプレートおよび S3 バケットを使用して、例全体を us-east-1 リージョンにデプロイできます。テンプレートを別のリージョンにデプロイする場合は、そのリージョンで Amazon S3 バケットを作成し、テンプレートおよび Lambda 関数の定義をそこにコピーする必要があります。

[**Launch Stack**] を選択して、アカウントで us-east-1 リージョンにテンプレートを起動します。

[![CloudFormation を使用して Lambda モバイルバックエンドを北バージニアに起動する](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=lambda-mobile-backend&amp;templateURL=https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobile-backend.template)

プロンプトが表示されたら、前のステップで作成した CloudSearch ドメイン、API Gateway REST API、および Amazon Cognito ID プールリソースのパラメーター値を入力します。

このテンプレートで作成されるリソースの詳細は、このドキュメントの「*CloudFormation テンプレートのリソース*」セクションで説明しています。

#### ステップ 5: API Gateway REST API を更新する

CloudFormation スタックを作成した後で、新しく作成された `NotesApiFunction` を使用するには、前に作成した API を更新する必要があります。

1.[Amazon API Gateway Console](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis) で、API を選択します。
1.[**Create Resource**] を選択し、/ 以下に新しい子リソースを作成します。
1.リソース名として「notes」、リソースパスとして「/notes」と入力します。
1.[**Create Resource**] を選択します。
1.新しい `/notes` リソースを選択して、[**Create Method**] を選択します。
1.[`POST`] を選択し、チェックボックスをオンにします。
1.統合タイプとして [**Lambda Function**] を選択し、Lambda リージョンとして CloudFormation スタックを起動したリージョンを選択します。
1.[**Lambda Function**] に「**`NotesApiFunction`**」と入力し、CloudFormation スタックで作成した関数を選択します。
1.[**Save**] を選択し、Lambda 関数を実行するための API Gateway アクセス権限を付与します。
1.[**Method Request**] を選択してリクエスト設定を編集します。
1.[**Authorization type**] で、[`AWS_IAM`] を選択します。
1.[ **API Key Required**] で、[`true`] を選択します。
1.[**Deploy API**] を選択します。
1.[ **Deployment stage**] で、[`New Stage`] を選択し、[**Stage name**] に名前を入力します。
1.新しいステージの [**Invoke URL**] をメモしておきます。iOS サンプルアプリを実行するときに、この値を使用します。

#### ステップ 6: API キーを作成する

1.[Amazon API Gateway Console](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis) で、[**APIs**] を選択し、[**API Keys**] を選択します。
1.[**Create API Key**] を選択します。
1.キーの名前を入力し、[**Enabled**] を選択します。
1.[**Save**] を選択します。
1.[**API Stage Association**] セクションで API を選択し、前のステップで作成したステージを選択します。
1.[**Add**] を選択します。
1.[**API key**] をメモしておきます。モバイルアプリケーションを実行するときに、これを使用します。

#### ステップ 7: Amazon Cognito ID プールを更新する

1.[Amazon Cognito コンソール](https://console.aws.amazon.com/cognito/home?region=us-east-1) で、ID プールを選択します。
1.[**Edit Identity Pool**] を選択します。
1.[**Unauthenticated role**] および [**Authenticated role**] の両方について、CloudFormation スタックで作成された [**MobileClientRole**] を選択します。ロールの完全な ARN は、スタックの出力に含まれます。
1.[**Save Changes**] を選択します。


### iOS サンプルアプリケーションの実行

#### 前提条件

用意された iOS サンプルアプリケーションを実行するには、Mac OS X 10.10 (Yosemite) 以降のバージョンを実行している必要があります。また、最新バージョンの [Xcode](https://itunes.apple.com/us/app/xcode/id497799835)  および [Cocoa Pods](https://cocoapods.org/) がインストールされている必要があります。

#### アプリケーションの構築と実行

1.このレポジトリの **ios-sample** のソースコードをチェックアウトまたはダウンロードします。
1.バックエンドデプロイの値で `MobileBackendIOS/Constants.swift` を更新します。ほとんどの値は、CloudFormation スタックの出力に含まれています。API Gateway キーおよびエンドポイント URL の値は、AWS マネジメントコンソールの API の詳細で確認できます。
1.ルートの `ios-sample` ディレクトリから Cocoa Pods を実行します。

    ```
    pod install
    ```

1.Xcode で、生成された `MobileBackendIOS.xcworkspace` ファイルを開きます。

    ```
    Xcode MobileBackendIOS.xcworkspace を開きます。
    ```

1.ウィンドウの上部にある再生ボタンをクリックして、Xcode からプロジェクトを構築および実行します。

## アプリケーションのテスト

サンプルアプリケーションは、画像のアップロードとメモの投稿という 2 つの機能を備えています。

### 画像をアップロードするには

1.アプリケーションの [**Upload Image**] を選択します。
1.カメラアイコンを選択し、カメラロールから画像を選択して、[**Choose**] を選択します。
1.[**Upload**] ボタンを選択します。

#### 画像がアップロードされたことの確認

画像が Amazon S3 にアップロードされたというログエントリが、Xcode の出力ペインに表示されます。

AWS マネジメントコンソールを使用して CloudFormation スタックで作成されたバケットを参照して、画像が正しくアップロードされたことを確認することもできます。

### メモを投稿するには

1.[**Post a Note**] を選択します。
1.メモに見出しとテキストを入力します。
1.[**Save Note**] を選択します。

#### メモが投稿されたことの確認

メモが正常に保存されたというログエントリが、Xcode の出力ペインに表示されます。

メモがアップロードされると、モバイルアプリケーションによって `NotesApiFunction` が呼び出されます。この関数のログは、Amazon CloudWatch で表示できます。

関数を正しく呼び出すと、CloudFormation スタックで作成された DynamoDB テーブルにエントリが追加されます。作成されたテーブルで、アプリケーションで投稿したメモが保持されていることを確認できます。

最後に、メモが DynamoDB テーブルに保持されていると、レコードがテーブルのストリームに追加され、`DynamoStreamHandlerFunction` によって処理されます。この関数のログは CloudWatch で表示でき、作成した CloudSearch ドメインに新しいドキュメントが追加されたことを確認できます。


## アプリケーションリソースのクリーンアップ

この例で作成されたすべてのリソースを削除するには、次の操作を行います。

1.CloudFormation スタックによって作成された S3 バケットからすべてのオブジェクトを削除します。
1.CloudFormation スタックを削除します。
1.Amazon Cognito ID プール、API Gateway、および CloudSearch ドメインを削除します。
1.CloudFormation スタックによって作成された各 Lambda 関数と関連付けられた CloudWatch ロググループを削除します。

## CloudFormation テンプレートのリソース

### Lambda 関数

- **NotesApiFunction** - API Gateway を通じてモバイルアプリケーションから投稿されたメモを処理する関数。

- **SearchApiFunction** - CloudSearch ドメインを使用し、インデックスが作成されたメモを検索用語に基づいて検索する関数。

- **DynamoStreamHandlerFunction** - `PhotoNotesTable` ストリームのレコードに基づいて、インデックスが作成されたドキュメントを、指定された CloudSearch ドメインに追加する関数。

### AWS Identity and Access Management (IAM) ロール

- **NotesApiRole** - `NotesApiFunction` のロール。このロールは、`PhotoNotesTable` の項目のログを記録し、操作するためのアクセス権限を付与します。

- **SearchApiRole** - `SearchApiFunction` のロール。このロールは、指定された CloudSearch ドメインのログを記録し、検索するためのアクセス権限を付与します。

- **DynamoStreamHandlerRole** - DynamoStreamHandlerFunction のロール。このロールは、指定された CloudSearch ドメインのログを記録し、ドキュメントを追加するためのアクセス権限を付与します。

- **MobileClientRole** - 認証されていないユーザーおよび認証されたユーザーの両方に対して Amazon Cognito ID プールによって使用されるロール。このロールは、指定された API Gateway REST API へのアクセス権および `MobileUploadsBucket` にオブジェクトを配置する権限を提供します。

### その他のリソース

- **MobileUploadsBucket** - ユーザーがアップロードした写真用の S3 バケット。

- **CloudFrontDistribution** - `MobileUploadsBucket` がオリジンとして設定された CDN ディストリビューション。

- **PhotoNotesTable** - モバイルアプリケーションからユーザーによってアップロードされたメモを保存する DynamoDB テーブル。

### 設定

- **ConfigTable** - さまざまな Lambda 関数によって読み込まれた設定値を保持する DynamoDB テーブル。このテーブルの名前 "MobileRefArchConfig" は各関数のコードにハードコーディングされ、コードを更新しないと変更することはできません。

- **ConfigHelperStack** - エントリを `ConfigTable` に書き込むためにカスタムリソースを作成するサブスタック。このスタックは、`ConfigTable` で UpdateItem アクセス権限を付与する Lambda 関数と実行ロールを作成します。

- **NotesTableConfig** - `PhotoNotesTable` 名を識別する設定エントリ。

- **SearchEndpointConfig** - パラメーターとして渡された CloudSearch ドメインの検索エンドポイントを識別する設定エントリ。

- **DocumentEndpointConfig** - パラメーターとして渡された CloudSearch ドメインのドキュメントエンドポイントを識別する設定エントリ。

## ライセンス

このリファレンスアーキテクチャサンプルは Apache 2.0 でライセンスされています。
