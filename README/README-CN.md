# 无服务器参考架构：移动后端

## 简介

移动后端参考架构 ([示意图](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf)) 演示了如何使用 [AWS Lambda](http://aws.amazon.com/lambda/) 以及其他服务来构建移动应用程序的无服务器后端。此存储库中提供的特定示例应用程序支持用户相应地使用 Amazon Simple Storage Service (Amazon S3) 和 Amazon API Gateway 上传照片和备注。备注存储在 Amazon DynamoDB 中，并使用 DynamoDB 流异步处理，使用 Lambda 函数添加到 Amazon CloudSearch 域中。除 Lambda 函数的源代码外，此存储库还包含原型 iOS 应用程序，该应用程序提供了示例来说明如何使用适用于 iOS 的 AWS Mobile SDK 与架构中定义的后端资源交互。

## 运行示例

要运行完整的示例应用程序，您必须先部署后端资源，然后编译并运行示例 iOS 应用程序。

### 部署后端

使用提供的 AWS CloudFormation 模板可以创建此示例需要的大多数后端资源，但您仍然需要在 AWS CloudFormation 之外创建 Amazon CloudSearch 域、API Gateway REST API 和 Cognito 身份池。

#### 步骤 1：创建 CloudSearch 域

1.使用 [AWS CLI](https://aws.amazon.com/cli/) 创建新 CloudSearch 域，自己选择一个域名。

    ```
    aws cloudsearch create-domain --domain-name [YOUR_DOMAIN_NAME]
    ```

1.记下输出文档中新域的 ARN。启动 CloudFormation 堆栈时，您将使用此信息作为输入。

1.定义 `headline` 和 `text` 字段的索引。

    ```
    aws cloudsearch define-index-field --name headline --type text --domain-name [YOUR_DOMAIN_NAME]
    aws cloudsearch define-index-field --name text --type text --domain-name [YOUR_DOMAIN_NAME]
    ```

#### 步骤 2：创建 API Gateway REST API

1.使用 [AWS CLI](https://aws.amazon.com/cli/) 创建新 API，自己选择一个名称。

    ```
    aws apigateway create-rest-api --name [YOUR_API_NAME]
    ```

1.记下输出文档中提供的 `API ID`。启动 CloudFormation 堆栈时，您将使用此信息作为输入。

#### 步骤 3：创建 Amazon Cognito 身份池

1.使用 [AWS CLI](https://aws.amazon.com/cli/) 创建新身份池，自己选择一个名称。

    ```
    aws cognito-identity create-identity-pool --allow-unauthenticated-identities --identity-pool-name [YOUR_POOL_NAME]
    ```

1.记下输出文档中的 `IdentityPoolId`。启动 CloudFormation 堆栈时，您将使用此信息作为参数。

#### 步骤 4：启动 CloudFormation 模板

您可以使用提供的 CloudFormation 模板和 S3 存储桶在 us-east-1 区域中部署整个示例。如果您希望将模板部署到不同区域，必须在该区域中创建 Amazon S3 存储桶，然后将模板和 Lambda 函数定义复制到其中。

选择 **Launch Stack** 以在您账户的 us-east-1 区域中启动模板：

[![使用 CloudFormation 在北弗吉尼亚区域中启动 Lambda 移动后端](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=lambda-mobile-backend&amp;templateURL=https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobile-backend.template)

在系统提示时，输入您在前面步骤中创建的 CloudSearch 域、API Gateway REST API 和 Amazon Cognito 身份池资源的参数值。

在本文档的 *CloudFormation 模板资源* 部分中提供了有关通过该模板创建的资源的详细信息。

#### 步骤 5：更新您的 API Gateway REST API

创建 CloudFormation 堆栈后，您需要更新先前创建的 API 以使用新创建的 `NotesApiFunction`。

1.在 [Amazon API Gateway 控制台](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis) 中选择您的 API。
1.选择 **Create Resource** 以在 / 下面创建新的子资源。
1.键入 `notes` 作为资源名称，并键入 `/notes` 作为资源路径。
1.选择 **Create Resource**。
1.选中 `/notes` 资源后，选择 **Create Method**。
1.选择 `POST` 并选中复选框。
1.选择 **Lambda Function** 作为集成类型，然后选择启动 CloudFormation 堆栈时所在的区域作为 Lambda 区域。
1.在 **Lambda Function** 中，键入 **`NotesApiFunction`**，然后选择 CloudFormation 堆栈创建的函数。
1.选择 **Save**，并授予 API Gateway 权限以执行 Lambda 函数。
1.选择 **Method Request** 以编辑请求配置。
1.对于 **Authorization type**，选择 `AWS_IAM`。
1.对于 **API Key Required**，选择 `true`。
1.选择 **Deploy API**。
1.对于 **Deployment stage**，选择 `New Stage`，然后在 **Stage name** 中键入名称。
1.记下新阶段的 **Invoke URL**。运行示例 iOS 应用程序时，您将使用此值。

#### 步骤 6：创建 API 密钥

1.在 [Amazon API Gateway 控制台](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis) 中选择 **APIs**，然后选择 **API Keys**。
1.选择 **Create API Key**。
1.为密钥键入名称，然后选择 **Enabled**。
1.选择 **Save**
1.在 **API Stage Association** 部分中，选择您的 API，然后选择您在上一步中创建的阶段。
1.选择 **Add**。
1.记下 **API key**。运行移动应用程序时，您将使用此信息。

#### 步骤 7：更新您的 Amazon Cognito 身份池

1.在 [Amazon Cognito 控制台](https://console.aws.amazon.com/cognito/home?region=us-east-1) 中，选择您的身份池。
1.选择 **Edit Identity Pool**。
1.对于 **Unauthenticated role** 和 **Authenticated role**，选择 CloudFormation 堆栈创建的 **MobileClientRole**。堆栈输出中提供角色的完整 ARN。
1.选择 **Save Changes**。


### 运行示例 iOS 应用程序

#### 先决条件

要运行提供的 iOS 示例应用程序，必须运行 Mac OS X 10.10 (Yosemite) 或更新版本。您还必须安装最新版本的 [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) 和 [Cocoa Pods](https://cocoapods.org/)。

#### 构建和运行应用程序

1.签出或下载此存储库中的 **ios-sample** 源代码。
1.使用后端部署的值更新 `MobileBackendIOS/Constants.swift`。在 CloudFormation 堆栈输出中可以找到大多数值。在 AWS 管理控制台中，可以在 API 详细信息中找到 API Gateway 密钥和终端节点 URL 值。
1.从 `ios-sample` 根目录运行 Cocoa Pods。

    ```
    pod install
    ```

1.在 Xcode 中打开生成的 `MobileBackendIOS.xcworkspace` 文件。

    ```
    open -a Xcode MobileBackendIOS.xcworkspace
    ```

1.通过单击窗口顶部的播放按钮，从 Xcode 构建并运行项目。

## 测试应用程序

示例应用程序提供了两项功能：上传图像和发布备注。

### 上传图像

1.在应用程序中，选择 **Upload Image**。
1.选择相机图标，从相册中选择图像，然后选择 **Choose**。
1.选择 **Upload** 按钮。

#### 验证是否已上传图像

您应该会在 Xcode 输出窗格中看到一个日志条目，指出图像已上传到 Amazon S3。

您还可以使用 AWS 管理控制台浏览 CloudFormation 堆栈创建的存储桶，以验证是否已正确上传图像。

### 发布备注

1.选择 **Post a Note**。
1.在备注中键入标题和文本。
1.选择 **Save Note**。

#### 验证是否已发布备注

您应该会在 Xcode 输出窗格中看到一个日志条目，指出备注已成功保存。

上传备注之后，移动应用程序会调用 `NotesApiFunction`。您可以在 Amazon CloudWatch 中查看此函数的日志。

成功调用该函数后，它会将一个条目添加到 CloudFormation 堆栈创建的 DynamoDB 表中。您可以验证应用程序中发布的备注是否已保存在创建的表中。

最后，当在 DynamoDB 表中保存备注时，会将一个记录添加到该表的流中，而该流又会由 `DynamoStreamHandlerFunction` 处理。您可以在 CloudWatch 中查看此函数的日志，并验证新文档是否已添加到您创建的 CloudSearch 域中。


## 清理应用程序资源

要删除此示例创建的所有资源，请执行以下操作：

1.删除 CloudFormation 堆栈创建的 S3 存储桶中的所有对象。
1.删除 CloudFormation 堆栈。
1.删除 Amazon Cognito 身份池、API Gateway 和 CloudSearch 域。
1.删除与 CloudFormation 堆栈创建的每个 Lambda 函数关联的 CloudWatch 日志组。

## CloudFormation 模板资源

### Lambda 函数

- **NotesApiFunction** - 一个函数，用于通过 API Gateway 处理移动应用程序中发布的备注。

- **SearchApiFunction** - 一个函数，该函数使用 CloudSearch 域根据搜索词来查找已建立索引的备注。

- **DynamoStreamHandlerFunction** - 一个函数，该函数根据 `PhotoNotesTable` 流中的记录将已建立索引的文档添加到提供的 CloudSearch 域。

### AWS Identity and Access Management (IAM) 角色

- **NotesApiRole** - `NotesApiFunction` 的角色。此角色授予在 `PhotoNotesTable` 中记录项以及使用其中项的权限。

- **SearchApiRole** - `SearchApiFunction` 的角色。此角色授予记录和搜索提供的 CloudSearch 域的权限。

- **DynamoStreamHandlerRole** - DynamoStreamHandlerFunction 的角色。此角色授予记录文档并将文档添加到提供的 CloudSearch 域的权限。

- **MobileClientRole** - 一个角色，该角色由您的 Amazon Cognito 身份池用于未经身份验证和已进行身份验证的用户。此角色授予对所提供 API Gateway REST API 的访问权限，并提供将对象放入 `MobileUploadsBucket` 的权限。

### 其他资源

- **MobileUploadsBucket** - 用于保存用户上传的照片的 S3 存储桶。

- **CloudFrontDistribution** - 将 `MobileUploadsBucket` 配置为源的 CDN 分配。

- **PhotoNotesTable** - 存储用户从移动应用程序上传的备注的 DynamoDB 表。

### 配置

- **ConfigTable** - 存放各个 Lambda 函数读取的配置值的 DynamoDB 表。此表的名称 "MobileRefArchConfig" 已硬编码到每个函数的代码中；在不更新代码的情况下无法修改。

- **ConfigHelperStack** - 创建自定义资源以便向 `ConfigTable` 写入条目的子堆栈。此堆栈创建 Lambda 函数和执行角色，该执行角色可授予对 `ConfigTable` 的 UpdateItem 权限。

- **NotesTableConfig** - 标识 `PhotoNotesTable` 名称的配置条目。

- **SearchEndpointConfig** - 一个配置条目，用于标识以参数形式传递的 CloudSearch 域的搜索终端节点。

- **DocumentEndpointConfig** - 一个配置条目，用于标识以参数形式传递的 CloudSearch 域的文档终端节点。

## 许可证

此示例参考架构已获得 Apache 2.0 许可。
