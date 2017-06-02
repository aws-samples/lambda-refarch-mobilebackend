# 서버 없는 레퍼런스 아키텍처: 모바일 백엔드

## 서론

모바일 백엔드 레퍼런스 아키텍처([diagram](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf))는 [AWS Lambda](http://aws.amazon.com/lambda/)와 다른 서비스를 사용하여 모바일 애플리케이션을 위한 서버 없는 백엔드를 구축하는 방법을 보여 줍니다. 본 리포지토리에 제공된 특정 예제 애플리케이션을 통해 사용자는 Amazon Simple Storage Service(Amazon S3)와 Amazon API Gateway를 각각 사용하여 사진과 노트를 업로드할 수 있습니다. 노트는 Amazon DynamoDB에 저장되며 DynamoDB 스트림과 Lambda 함수를 사용하여 비동기 방식으로 처리되어 Amazon CloudSearch 도메인에 추가됩니다. Lambda 함수의 소스 코드뿐 아니라 이 리포지토리 역시 iOS용 AWS Mobile SDK를 사용하여 아키텍처에 정의된 백엔드 리소스와 연결하는 방법에 대한 예제를 제공하는 프로토타입 iOS 애플리케이션을 포함하고 있습니다.

## 예제 실행

전체 예제 애플리케이션을 실행하려면 먼저 백엔드 리소스를 배포한 후 예제 iOS 애플리케이션을 컴파일 및 실행해야 합니다.

### 백엔드 배포

제공된 AWS CloudFormation 템플릿은 이 예제에 필요한 대부분의 백엔드 리소스를 만들지만 여전히 AWS CloudFormation 외부에 Amazon CloudSearch 도메인, API Gateway REST API 및 Cognito 자격 증명 풀을 만들어야 합니다.

### 1단계: CloudSearch 도메인 생성

1. [AWS CLI](https://aws.amazon.com/cli/)를 사용하여 CloudSearch 도메인을 만듭니다. 이때 원하는 도메인 이름을 지정합니다.

    ```
    aws cloudsearch create-domain --domain-name [YOUR_DOMAIN_NAME]
    ```

1. 출력 문서에서 새 도메인의 ARN을 확인합니다. 이 값을 CloudFormation 스택을 시작할 때 입력으로 사용합니다.

1. `headline` 및 `text` 필드에 대한 인덱스를 정의합니다.

    ```
    aws cloudsearch define-index-field --name headline --type text --domain-name [YOUR_DOMAIN_NAME]
    aws cloudsearch define-index-field --name note_text --type text --domain-name [YOUR_DOMAIN_NAME]
    ```

    ```
    aws cloudsearch index-documents --domain-name [YOUR_DOMAIN_NAME]
    ```
    
#### 2단계: API Gateway REST API 생성

1. [AWS CLI](https://aws.amazon.com/cli/)를 사용하여 API를 만듭니다. 이때 원하는 이름을 지정합니다.

    ```
    aws apigateway create-rest-api --name [YOUR_API_NAME]
    ```

1. 출력 문서에 제공된 `API ID`를 확인합니다. 이 값을 CloudFormation 스택을 시작할 때 입력으로 사용합니다.

#### 3단계: Amazon Cognito 자격 증명 풀 생성

1. [AWS CLI](https://aws.amazon.com/cli/)를 사용하여 새로운 자격 증명 풀을 만듭니다. 이때 원하는 이름을 지정합니다.

    ```
    aws cognito-identity create-identity-pool --allow-unauthenticated-identities --identity-pool-name [YOUR_POOL_NAME]
    ```

1. 출력 문서에서 `IdentityPoolId`를 확인합니다. 이 값을 CloudFormation 스택을 시작할 때 파라미터로 사용합니다.

#### 4단계: CloudFormation 템플릿 시작

제공된 CloudFormation 템플릿 및 S3 버킷을 사용하여 us-east-1 리전에 전체 예제를 배포할 수 있습니다. 다른 리전에 템플릿을 배포하려면 해당 리전에 Amazon S3 버킷을 생성하고 템플릿 및 Lambda 함수 정의를 복사합니다.

**Launch Stack**을 선택하여 계정의 us-east-1 리전에서 템플릿을 시작합니다.

[![Launch Lambda Mobile Backend into North Virginia with CloudFormation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=lambda-mobile-backend&templateURL=https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobile-backend.template)

확인 메시지가 표시되면 앞 단계에서 만든 CloudSearch 도메인, API Gateway REST API 및 Amazon Cognito 자격 증명 풀 리소스의 파라미터 값을 입력합니다.

이 템플릿을 통해 생성된 리소스에 대한 세부 정보는 본 문서의 *CloudFormation 템플릿 리소스* 단원에서 제공됩니다.

#### 5단계: API Gateway REST API 업데이트

CloudFormation 스택을 만든 후에는 새로 생성된 `NotesApiFunction`을 사용하기 위해 앞서 만든 API를 업데이트해야 합니다.

1. [Amazon API Gateway Console](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis)에서 API를 선택합니다.
1. **Create Resource**를 선택하여 / 아래에 하위 리소스를 만듭니다.
1. 리소스 이름으로 `notes`를 입력하고 리소스 경로로 `/notes`를 입력합니다.
1. **Create Resource**를 선택합니다.
1. 새 `/notes` 리소스를 선택한 상태에서 **Create Method**를 선택합니다.
1. `POST`를 선택하고 확인란을 선택합니다.
1. 통합 유형으로 **Lambda Function**을 선택한 후 CloudFormation 스택을 시작한 리전을 Lambda 리전으로 선택합니다.
1. **Lambda Function**에 **`NotesApiFunction`**을 입력한 후 CloudFormation 스택을 통해 생성된 함수를 선택합니다.
1. **Save**를 선택하여 API Gateway에 Lambda 함수를 실행할 권한을 부여합니다.
1. **Method Request**를 선택하여 요청 구성을 편집합니다.
1. **Authorization type**에서 `AWS_IAM`을 선택합니다.
1. **API Key Required**에서 `true`를 선택합니다.
1. **Deploy API**를 선택합니다.
1. **Deployment stage**에서 `New Stage`를 선택한 후 **Stage name**에 이름을 입력합니다.
1. 새 단계의 **Invoke URL**을 확인합니다. 샘플 iOS 애플리케이션을 실행할 때 이 값을 사용해야 합니다.

#### 6단계: API 키 생성

1. [Amazon API Gateway Console](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis)에서 **APIs**를 선택한 후 **API Keys**를 선택합니다.
1. **Create API Key**를 선택합니다.
1. 키의 이름을 입력한 후 **Enabled**를 선택합니다.
1. **Save**를 선택합니다.
1. **API Stage Association** 섹션에서 API를 선택한 후 앞 단계에서 만든 단계를 선택합니다.
1. **Add**를 선택합니다.
1. **API key**를 확인합니다. 모바일 애플리케이션을 실행할 때 이 값을 사용해야 합니다.

#### 7단계: Amazon Cognito 자격 증명 풀 업데이트

1. [Amazon Cognito Console](https://console.aws.amazon.com/cognito/home?region=us-east-1)에서 자격 증명 풀을 선택합니다.
1. **Edit Identity Pool**을 선택합니다.
1. **Unauthenticated role** 및 **Authenticated role**에 대해 CloudFormation 스택을 통해 생성된 **MobileClientRole**을 선택합니다. 이 역할의 전체 ARN이 스택 출력에 제공됩니다.
1. **Save Changes**를 선택합니다.


### 샘플 iOS 애플리케이션 실행

#### 사전 조건

제공된 iOS 샘플 애플리케이션을 실행하려면 Mac OS X 10.10(Yosemite) 또는 보다 최신 버전을 실행해야 합니다. 최신 버전의 [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) 및 [Cocoa Pods](https://cocoapods.org/)도 설치되어 있어야 합니다.

#### 애플리케이션 구축 및 실행

1. 이 리포지토리에서 **ios-sample**의 소스 코드를 확인하거나 다운로드합니다.
1. `MobileBackendIOS/Constants.swift`를 백엔드 배포 값으로 업데이트합니다. 대부분의 값은 CloudFormation 스택의 출력에서 찾을 수 있습니다. API Gateway 키 및 엔드포인트 URL 값은 AWS Management Console의 API 세부 정보에서 찾을 수 있습니다.
1. 루트 `ios-sample` 디렉터리에서 Cocoa Pods를 실행합니다.

    ```
    pod install
    ```

1. Xcode에서 생성된 `MobileBackendIOS.xcworkspace` 파일을 엽니다.

    ```
    open -a Xcode MobileBackendIOS.xcworkspace
    ```

1. 화면 상단에서 재생 버튼을 클릭하여 Xcode에서 프로젝트를 구축 및 실행합니다.

## 애플리케이션 테스트

샘플 애플리케이션은 이미지 업로드 및 노트 게시라는 두 기능을 제공합니다.

### 이미지 업로드 방법

1. 애플리케이션에서 **Upload Image**를 선택합니다.
1. 카메라 아이콘을 선택하고 카메라 역할에서 이미지를 선택한 후 **Choose**를 선택합니다.
1. **Upload** 버튼을 선택합니다.

#### 이미지 업로드 여부 확인 방법

Xcode의 출력 창에 이미지가 Amazon S3로 업로드되었음을 나타내는 로그 항목을 확인할 수 있습니다.

AWS Management Console을 사용하여 CloudFormation 스택을 통해 생성된 버킷을 탐색하여 이미지가 올바르게 업로드되었음을 확인할 수도 있습니다.

### 노트 게시 방법

1. **Post a Note**를 선택합니다.
1. 노트란에 헤드라인과 텍스트를 입력합니다.
1. **Save Note**를 선택합니다.

#### 노트 게시 여부 확인 방법

Xcode의 출력 창에 노트가 저장되었음을 나타내는 로그 항목을 확인할 수 있습니다.

노트가 업로드되면 `NotesApiFunction`이 모바일 애플리케이션에 의해 호출됩니다. Amazon CloudWatch에서 이 함수에 대한 로그를 볼 수 있습니다.

함수가 호출되면 CloudFormation 스택에 생성된 DynamoDB 테이블에 항목을 추가합니다. 생성된 테이블에 애플리케이션에 게시한 노트가 유지되고 있는지 확인할 수 있습니다.

마지막으로 노트가 DynamoDB 테이블에 유지되고 있으면 테이블의 스트림에 레코드가 추가되며 이 레코드는 `DynamoStreamHandlerFunction`에 의해 처리됩니다. CloudWatch에서 이 함수에 대한 로그를 보고 생성된 CloudSearch 도메인에 새 문서가 추가되었음을 확인할 수 있습니다.


## 애플리케이션 리소스 정리

이 예제에서 생성된 모든 리소스를 제거하려면 다음을 수행합니다.

1. CloudFormation 스택에서 생성된 S3 버킷에서 모든 객체를 삭제합니다.
1. CloudFormation 스택을 삭제합니다.
1. Amazon Cognito 자격 증명 풀, API Gateway 및 CloudSearch 도메인을 삭제합니다.
1. CloudFormation 스택을 통해 생성된 각 Lambda 함수와 연결된 CloudWatch 로그 그룹을 삭제합니다.

## CloudFormation 템플릿 리소스

### Lambda 함수

- **NotesApiFunction** - API Gateway를 통해 모바일 애플리케이션에서 게시된 노트를 처리하는 함수입니다.

- **SearchApiFunction** - CloudSearch 도메인을 사용하여 검색어를 기반으로 인덱싱된 노트를 찾는 함수입니다.

- **DynamoStreamHandlerFunction** - 제공된 CloudSearch 도메인에 `PhotoNotesTable` 스트림의 레코드를 기반으로 인덱싱된 문서를 추가하는 함수입니다.

### AWS IAM(Identity and Access Management) 역할

- **NotesApiRole** - `NotesApiFunction`의 역할입니다. 이 역할은 로그인 및 `PhotoNotesTable`의 항목 작업에 대한 권한을 부여합니다.

- **SearchApiRole** - `SearchApiFunction`의 역할입니다. 이 역할은 로그인 및 제공된 CloudSearch 도메인 검색에 대한 권한을 부여합니다.

- **DynamoStreamHandlerRole** - DynamoStreamHandlerFunction에 대한 역할입니다. 이 역할은 로그인 및 제공된 CloudSearch 도메인에 문서를 추가하는 권한을 부여합니다.

- **MobileClientRole** - 인증되지 않은 사용자 및 인증된 사용자에 대해 Amazon Cognito 자격 증명 풀에서 사용하는 역할입니다. 이 역할은 제공된 API Gateway REST API에 대한 액세스를 제공하고 객체를 `MobileUploadsBucket`에 추가하는 권한을 제공합니다.

### 기타 리소스

- **MobileUploadsBucket** - 사용자가 업로드한 사진의 S3 버킷입니다.

- **CloudFrontDistribution** - `MobileUploadsBucket`이 오리진으로 구성된 CDN 배포입니다.

- **PhotoNotesTable** - 모바일 애플리케이션을 통해 사용자가 업로드한 노트를 저장하는 DynamoDB 테이블입니다.

### 구성

- **ConfigTable** - 여러 Lambda 함수가 읽는 구성 값이 저장된 DynamoDB 테이블입니다. 이 테이블의 이름인 "MobileRefArchConfig"는 각 함수의 코드로 하드 코딩되며 코드까지 업데이트해야 수정이 가능합니다.

- **ConfigHelperStack** - `ConfigTable`에 항목을 쓰기 위한 사용자 지정 리소스를 만드는 하위 스택입니다. 이 스택은 Lambda 함수를 만들고 `ConfigTable`에서 UpdateItem 권한을 부여하는 실행 역할을 만듭니다.

- **NotesTableConfig** - `PhotoNotesTable` 이름을 식별하는 구성 항목입니다.

- **SearchEndpointConfig** - 파라미터로 전달된 CloudSearch 도메인의 검색 엔드포인트를 식별하는 구성 항목입니다.

- **DocumentEndpointConfig** - 파라미터로 전달된 CloudSearch 도메인의 문서 엔드포인트를 식별하는 구성 항목입니다.

## 라이선스

이 레퍼런스 아키텍처 샘플은 Apache 2.0에서 라이선스가 부여되었습니다.
