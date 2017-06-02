# 無伺服器參考架構：行動後端

## 簡介

行動後端參考架構 ([示意圖](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf)) 展示如何使用 [AWS Lambda](http://aws.amazon.com/lambda/) 及其他服務，為行動應用程式建立無需伺服器的後端。此儲存庫提供的具體範例應用程式可讓使用者分別使用 Amazon Simple Storage Service (Amazon S3) 與 Amazon API Gateway 上傳照片與筆記。這些筆記存放於 Amazon DynamoDB，並利用 DynamoDB streams 與 Lambda 功能以非同步方式處理，將它們新增至 Amazon CloudSearch 網域。除了 Lambda 功能的原始碼之外，此儲存庫還包含可提供範例，並說明如何使用 iOS 的 AWS Mobile SDK 連接架構中定義的後端資源的原型 iOS 應用程式。

## 執行範例

若要執行完整的範例應用程式，您必須先部署後端資源，然後編譯並執行範例 iOS 應用程式。

### 部署後端

系統提供的 AWS CloudFormation 範本將建立此範例所需的大多數後端資源，但您仍需建立 Amazon CloudSearch 網域、API Gateway REST API，以及 AWS CloudFormation 外部的 Cognito Identity Pool。

#### 步驟 1：建立 CloudSearch 網域

1.使用 [AWS CLI](https://aws.amazon.com/cli/) 建立新的 CloudSearch 網域並提供您選擇的網域名稱。

    ```
    aws cloudsearch create-domain --domain-name [YOUR_DOMAIN_NAME]
    ```

1.請記下輸出文件中的新網域的 ARN，您將在啟動 CloudFormation 堆疊時使用它做為輸入。

1.定義「headline」與「note_text」欄位的索引。

    ```
    aws cloudsearch define-index-field --name headline --type text --domain-name [YOUR_DOMAIN_NAME]
    aws cloudsearch define-index-field --name note_text --type text --domain-name [YOUR_DOMAIN_NAME]
    ```

    ```
    aws cloudsearch index-documents --domain-name [YOUR_DOMAIN_NAME]
    ```

#### 步驟 2：建立 API Gateway REST API

1.使用 [AWS CLI](https://aws.amazon.com/cli/) 建立新的 API 並提供您選擇的名稱。

    ```
    aws apigateway create-rest-api --name [YOUR_API_NAME]
    ```

1.請記下輸出文件中提供的「API ID」，您將在啟動 CloudFormation 堆疊時使用它做為輸入。

#### 步驟 3：建立 Amazon Cognito Identity Pool

1.使用 [AWS CLI](https://aws.amazon.com/cli/) 建立新的 Identity Pool 並提供您選擇的名稱。

    ```
    aws cognito-identity create-identity-pool --allow-unauthenticated-identities --identity-pool-name [YOUR_POOL_NAME]
    ```

1.請記下輸出文件中提供的「IdentityPoolId」，您將在啟動 CloudFormation 堆疊時使用它做為參數。

#### 步驟 4：啟動 CloudFormation 範本

您可以使用系統提供的 CloudFormation 範本與 S3 儲存貯體，在 us-east-1 區域部署整個範例。如果您想在不同的區域部署此範例，您必須在該區域建立 Amazon S3 儲存貯體，然後將範本與 Lambda 功能定義複製至該儲存貯體。

選擇 **Launch Stack** 以啟動您帳戶的 us-east-1 區域中的範本。

[![Launch Lambda Mobile Backend into North Virginia with CloudFormation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=lambda-mobile-backend&amp;templateURL=https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobile-backend.template)

收到提示時，輸入您在先前步驟建立的 CloudSearch 網域、API Gateway REST API 及 Amazon Cognito Identity Pool 等資源的參數值。

本文件的 *CloudFormation 範本資源* 章節中有提供關於此範例所建立資源的詳細資訊。

#### 步驟 5：更新您的 API Gateway REST API

在您建立 CloudFormation 堆疊之後，您必須更新先前建立的 API，才能使用新建立的「NotesApiFunction」。

1.在 [Amazon API Gateway Console](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis) 中選擇您的 API。
1.選擇 **Create Resource** 在 / 之下建立新的子資源。
1.輸入「notes」做為此資源的名稱，輸入「/notes」做為此資源的路徑。
1.選擇 **Create Resource**。
1.在已選取新的「/notes」資源的情況下，選擇 **建立方法**。
1.選擇「POST」，然後選擇該核取方塊。
1.選擇 **Lambda 功能** 做為整合類型，然後選擇您啟動 CloudFormation 堆疊的區域做為 Lambda 區域。
1.在 **Lambda 功能** 中輸入 **`NotesApiFunction`**，然後選擇 CloudFormation 堆疊建立的功能。
1.選擇 **儲存** 並授與 API Gateway 執行 Lambda 功能的許可。
1.選擇 **方法請求** 以編輯請求組態。
1.在 **授權類型** 項目中選擇「AWS_IAM」。
1.在 **需要 API 金鑰** 項目中選擇「true」。
1.選擇 **部署 API**。
1.在 **部署階段** 項目中選擇「新階段」，然後在 **階段名稱** 中輸入一個名稱。
1.請記下新階段的 **呼叫 URL**，您將在執行範例 iOS 應用程式時使用此數值。

#### 步驟 6：建立 API 金鑰

1.在 [Amazon API Gateway Console](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis) 中選擇 **APIs**，然後選擇 **API 金鑰**。
1.選擇 **建立 API 金鑰**。
1.輸入金鑰的名稱，然後選擇 **已啟用**。
1.選擇 **儲存**
1.在 **API 階段關聯** 區段中，選擇您的 API，然後選擇您在先前的步驟中建立的階段。
1.選擇 **新增**。
1.請記下 **API 金鑰**，您將在執行行動應用程式時使用它。

#### 步驟 7：更新您的 Amazon Cognito Identity Pool

1.在 [Amazon Cognito Console](https://console.aws.amazon.com/cognito/home?region=us-east-1) 中選擇您的 Identity Pool。
1.選擇 **編輯 Identity Pool**。
1.在 **未授權的角色** 與 **已授權的角色** 項目中選擇由 CloudFormation 堆疊建立的 **MobileClientRole**。堆疊的輸出中有提供該角色的完整 ARN。
1.選擇 **儲存變更**。


### 執行範例 iOS 應用程式

#### 必要條件

若要執行系統提供的 iOS 範例應用程式，您必須執行 Mac OS X 10.10 (Yosemite) 或更新的版本。您還必須安裝最新版的 [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) 與 [Cocoa Pods](https://cocoapods.org/)。

#### 建立與執行應用程式

1.查看或下載儲存庫中的 **ios-sample** 的原始碼。
1.使用您的後端部署的數值更新「MobileBackendIOS/Constants.swift」。大多數的數值皆可在 CloudFormation 堆疊的輸出中找到。在 AWS 管理主控台中的您的 API 詳細資訊中，可找到 API Gateway 金鑰與終端節點 URL 數值。
1.從「ios-sample」根目錄執行 Cocoa Pods。

    ```
    pod install
    ```

1.在 Xcode 中開啟所產生的「MobileBackendIOS.xcworkspace」檔案。

    ```
    open -a Xcode MobileBackendIOS.xcworkspace
    ```

1.按一下 Xcode 視窗最上方的播放按鈕以建立並執行專案。

## 測試應用程式

此範例應用程式提供兩個功能：上傳圖片與張貼筆記。

### 上傳圖片

1.在應用程式中選擇 **上傳圖片**。
1.選擇相機圖示，從相簿中選擇一張圖片後選擇 **選擇**。
1.選擇 **上傳** 按鈕。

#### 驗證圖片是否已經上傳

您應該會在 Xcode 的輸出窗格中看到一筆有關圖片已上傳至 Amazon S3 的記錄項目。

您也可以使用 AWS 管理主控台瀏覽 CloudFormation 堆疊建立的儲存貯體，以確認圖片已正確上傳。

### 張貼筆記

1.選擇 **張貼筆記**。
1.在筆記中輸入標題與文字。
1.選擇 **儲存筆記**。

#### 驗證筆記是否已經張貼

您應該會在 Xcode 的輸出窗格中看到一筆有關筆記已成功儲存的記錄項目。

當筆記上傳時，行動應用程式將會呼叫「NotesApiFunction」。您可以在 Amazon CloudWatch 中檢視此功能的記錄。

當成功呼叫此功能時，它會在 CloudFormation 堆疊建立的 DynamoDB 資料表中新增一筆資料項目。您可以確認您在應用程式中張貼的筆記已持續存在所建立的資料表中。

最後，當筆記持續存在於 DynamoDB 資料表時，將有一筆記錄新增至該資料表的 Stream 中，然後由「DynamoStreamHandlerFunction」進行處理。您可以在 CloudWatch 中檢視此功能的這筆記錄，然後確認新的文件是否已新增至您建立的 CloudSearch 網域。


## 清除應用程式資源

若要移除此範例建立的所有資源，請執行以下動作：

1.刪除 CloudFormation 堆疊建立的 S3 儲存貯體中的所有物件。
1.刪除 CloudFormation 堆疊。
1.刪除 Amazon Cognito Identity Pool、API Gateway 及 CloudSearch 網域。
1.刪除與 CloudFormation 堆疊所建立的 Lambda 功能相關聯的 CloudWatch 記錄群組。

## CloudFormation 範本資源

### Lambda 功能

- **NotesApiFunction** - 處理從行動應用程式透過 API Gateway 所張貼筆記的功能。

- **SearchApiFunction** - 利用 CloudSearch 網域依據搜尋詞彙搜尋已索引的筆記的功能。

- **DynamoStreamHandlerFunction** - 依據「PhotoNotesTable」Stream 中的記錄，將已索引的文件新增至系統提供的 CloudSearch 網域的功能。

### AWS Identity and Access Management (IAM) 角色

- **NotesApiRole** - 用於「NotesApiFunction」的角色。此角色授與許可以記錄與使用「PhotoNotesTable」中的項目。

- **SearchApiRole** - 用於「SearchApiFunction」的角色。此角色授與許可以記錄及搜尋所提供的 CloudSearch 網域。

- **DynamoStreamHandlerRole** - 用於 DynamoStreamHandlerFunction 的角色。此角色授與許可以記錄及新增文件至所提供的 CloudSearch 網域。

- **MobileClientRole** - 由 Amazon Cognito Identity Pool 用於未授權與已授權使用者的角色。此角色提供存取所提供 API Gateway REST API，以及授與許可將物件放入「MobileUploadsBucket」。

### 其他資源

- **MobileUploadsBucket** - 用於存放使用者上傳的照片的 S3 儲存貯體。

- **CloudFrontDistribution** -「MobileUploadsBucket」設定為原始的 CDN 分發。

- **PhotoNotesTable** - 存放使用者從行動應用程式上傳的筆記的 DynamoDB 資料表。

### 組態

- **ConfigTable** - 存放可供各種 Lambda 功能讀取的組態值的 DynamoDB 資料表。此資料表的名稱「MobileRefArchConfig」已硬編碼至各個功能的程式碼，若未更新該程式碼，將無法修改。

- **ConfigHelperStack** - 建立自訂資源以將資料項目寫入至「ConfigTable」的子堆疊。此堆疊會建立 Lambda 功能與執行角色以授與「ConfigTable」的 UpdateItem 許可。

- **NotesTableConfig** - 識別「PhotoNotesTable」名稱的組態項目。

- **SearchEndpointConfig** - 識別 CloudSearch 網域搜尋端點的組態項目，以參數傳遞。

- **DocumentEndpointConfig** - 識別 CloudSearch 網域的文件終端節點的組態項目，以參數傳遞。

## 授權

此參考架構範例依據 Apache 2.0 授權。
