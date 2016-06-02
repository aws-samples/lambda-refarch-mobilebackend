# Эталонная бессерверная архитектура: базовая система для мобильного приложения

## Введение

Эта эталонная архитектура ([схема](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf)) позволяет понять, как использовать [AWS Lambda](http://aws.amazon.com/lambda/) вместе с другими сервисами для создания бессерверной базовой системы для мобильного приложения. Пример приложения, предоставленный в этом репозитории, позволяет пользователям загружать фотографии и заметки с помощью Amazon Simple Storage Service (Amazon S3) и Amazon API Gateway соответственно. Заметки хранятся в Amazon DynamoDB и обрабатываются асинхронно с помощью потоков DynamoDB, а функция Lambda добавляет их в домен Amazon CloudSearch. Помимо исходного кода для функций Lambda, этот репозиторий также содержит прототип приложения для iOS с примерами взаимодействия с базовыми ресурсами, заданными в архитектуре, с помощью пакета AWS Mobile SDK для iOS.

## Запуск примера

Чтобы запустить пример приложения, сначала необходимо развернуть базовые ресурсы, а затем скомпилировать и запустить приложение для iOS.

### Развертывание базовой системы

Предоставленный шаблон AWS CloudFormation создает большинство необходимых базовых ресурсов, но вам по-прежнему потребуется создать домен Amazon CloudSearch, API REST для API Gateway и пул удостоверений Cognito за пределами AWS CloudFormation.

#### Шаг 1. Создание домена CloudSearch

1. С помощью [AWS CLI](https://aws.amazon.com/cli/) создайте домен CloudSearch с именем по вашему выбору.

    ```
    aws cloudsearch create-domain --domain-name [YOUR_DOMAIN_NAME]
    ```

1. Обратите внимание на ARN нового домена в полученном документе. Вы введете это значение при запуске стека CloudFormation.

1. Определите индексы для полей «headline» и «text».

    ```
    aws cloudsearch define-index-field --name headline --type text --domain-name [YOUR_DOMAIN_NAME]
    aws cloudsearch define-index-field --name text --type text --domain-name [YOUR_DOMAIN_NAME]
    ```

#### Шаг 2. Создание API REST для API Gateway

1. С помощью [AWS CLI](https://aws.amazon.com/cli/) создайте API с именем по вашему выбору.

    ```
    aws apigateway create-rest-api --name [YOUR_API_NAME]
    ```

1. Обратите внимание на API ID в полученном документе. Вы введете это значение при запуске стека CloudFormation.

#### Шаг 3. Создание пула удостоверений Amazon Cognito

1. С помощью [AWS CLI](https://aws.amazon.com/cli/) создайте пул удостоверений с именем по вашему выбору.

    ```
    aws cognito-identity create-identity-pool --allow-unauthenticated-identities --identity-pool-name [YOUR_POOL_NAME]
    ```

1. Обратите внимание на строку IdentityPoolId в полученном документе. Вы введете это значение в качестве параметра при запуске стека CloudFormation.

#### Шаг 4. Запуск шаблона CloudFormation

Вы можете развернуть весь пример в регионе us-east-1, используя предоставленный шаблон CloudFormation и корзину S3. Чтобы использовать другой регион, создайте корзину Amazon S3 в этом регионе и скопируйте в него шаблон и определения функций Lambda.

Выберите **Launch Stack**, чтобы запустить шаблон в регионе us-east-1 в вашем аккаунте:

[![Запуск базовой системы для мобильного приложения Lambda в Северной Вирджинии с помощью CloudFormation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=lambda-mobile-backend&amp;templateURL=https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobile-backend.template)

После появления запроса укажите домен CloudSearch, API REST для API Gateway и пул удостоверений Amazon Cognito, созданные ранее.

Сведения о ресурсах, созданных этим шаблоном, представлены в разделе «Ресурсы шаблона CloudFormation» этого документа.

#### Шаг 5. Обновление API REST для API Gateway

После создания стека CloudFormation вам необходимо обновить API, созданный ранее, чтобы воспользоваться новой функцией NotesApiFunction.

1. В [консоли Amazon API Gateway](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis) выберите ваш API.
1. Выберите **Create Resource**, чтобы создать дочерний ресурс в каталоге «/».
1. Укажите имя ресурса «notes» и путь «/notes».
1. Выберите **Create Resource**.
1. Выберите новый ресурс «/notes» и нажмите кнопку **Create Method**.
1. Выберите «POST» и установите флажок.
1. Выберите тип интеграции **Lambda Function**, а затем выберите регион, где вы запустили стек CloudFormation, в качестве региона Lambda.
1. В поле **Lambda Function** введите **NotesApiFunction**, а затем выберите функцию, созданную стеком CloudFormation.
1. Нажмите кнопку **Save** и предоставьте API Gateway разрешения для выполнения функции Lambda.
1. Выберите **Method Request**, чтобы изменить конфигурацию запроса.
1. Для параметра **Authorization type** выберите значение «AWS_IAM».
1. Для параметра **API Key Required** выберите значение «true».
1. Нажмите кнопку **Deploy API**.
1. Для параметра **Deployment stage** выберите значение **New Stage** и введите имя в поле **Stage name**.
1. Обратите внимание на адрес **Invoke URL** нового этапа. Вы будете использовать это значение при запуске примера приложения для iOS.

#### Шаг 6. Создание ключа API

1. В [консоли Amazon API Gateway](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis) выберите **APIs**, а затем выберите **API Keys**.
1. Нажмите кнопку **Create API Key**.
1. Введите имя ключа и выберите **Enabled**.
1. Нажмите кнопку **Save**.
1. В разделе **API Stage Association** выберите ваш API, а затем выберите этап, созданный ранее.
1. Нажмите кнопку **Add**.
1. Обратите внимание на значение **API key**. Оно будет использоваться при запуске мобильного приложения.

#### Шаг 7. Обновление пула удостоверений Amazon Cognito

1. В [консоли Amazon Cognito](https://console.aws.amazon.com/cognito/home?region=us-east-1) выберите ваш пул удостоверений.
1. Нажмите кнопку **Edit Identity Pool**.
1. Для параметров **Unauthenticated role** и **Authenticated role** выберите роль **MobileClientRole**, созданную стеком CloudFormation. В выходных данных стека указано полное значение ARN роли.
1. Нажмите кнопку **Save Changes**.


### Запуск примера приложения iOS

#### Необходимые условия

Для запуска примера приложения iOS необходима операционная система Mac OS X версии 10.10 (Yosemite) или более поздней. Рекомендуем установить последнюю версию [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) и [Cocoa Pods](https://cocoapods.org/).

#### Построение и запуск приложения

1. Извлеките или загрузите исходный код приложения **ios-sample** из этого репозитория.
1. Укажите в файле MobileBackendIOS/Constants.swift значения для вашего развертывания. Большинство из них можно найти в выходных данных стека CloudFormation. Ключ API Gateway и URL доступны в описании вашего API в консоли управления AWS.
1. Запустите Cocoa Pods из корневого каталога ios-sample.

    ```
    pod install
    ```

1. Откройте созданный файл MobileBackendIOS.xcworkspace в Xcode.

    ```
    open -a Xcode MobileBackendIOS.xcworkspace
    ```

1. Выполните построение проекта и запустите его в Xcode, нажав кнопку воспроизведения в верхней части окна.

## Тестирование приложения

Пример приложения предоставляет две возможности: загрузка изображения и публикация заметки.

### Загрузка изображения

1. Нажмите кнопку **Upload Image** в приложении.
1. Щелкните значок камеры, выберите изображение и нажмите кнопку **Choose**.
1. Нажмите кнопку **Upload**.

#### Проверка загрузки изображения

В журнале на панели выходных данных Xcode вы увидите запись о том, что изображение загружено в Amazon S3.

Вы также можете просмотреть корзину, созданную стеком CloudFormation, используя консоль управления AWS, чтобы убедиться, что изображение загружено без ошибок.

### Публикация заметки

1. Нажмите кнопку **Post a Note**.
1. Введите заголовок и текст.
1. Нажмите кнопку **Save Note**.

#### Проверка публикации заметки

В журнале на панели выходных данных Xcode вы увидите запись о том, что заметка успешно сохранена.

При загрузке заметки мобильное приложение вызывает функцию NotesApiFunction. Журналы выполнения этой функции можно просмотреть в Amazon CloudWatch.

После успешного выполнения функции в таблицу DynamoDB, созданную стеком CloudFormation, добавляется запись. Вы можете проверить, сохранена ли заметка, опубликованная в приложении, в созданной таблице.

Наконец, когда заметка сохраняется в таблице DynamoDB, в ее поток добавляется запись, которую обрабатывает функция DynamoStreamHandlerFunction. Вы можете просмотреть журналы ее выполнения в CloudWatch и убедиться, что в созданный домен CloudSearch добавлен новый документ.


## Очистка ресурсов приложения

Чтобы удалить все ресурсы, созданные этим примером, выполните следующие действия.

1. Удалите все объекты из корзины S3, созданной стеком CloudFormation.
1. Удалите стек CloudFormation.
1. Удалите пул удостоверений Amazon Cognito, API Gateway и домен CloudSearch.
1. Удалите группы журналов CloudWatch, связанные с каждой функцией Lambda, созданной стеком CloudFormation.

## Ресурсы шаблона CloudFormation

### Функции Lambda

- **NotesApiFunction** – функция для обработки заметок, публикуемых в мобильном приложении, с использованием API Gateway.

- **SearchApiFunction** – функция, использующая домен CloudSearch для поиска индексированных заметок по заданным условиям.

- **DynamoStreamHandlerFunction** – функция, которая добавляет индексированный документ в указанный домен CloudSearch на основе записей в потоке PhotoNotesTable.

### Роли AWS Identity and Access Management (IAM)

- **NotesApiRole** – роль для функции NotesApiFunction. Она предоставляет разрешения для ведения журнала и обработки элементов в таблице PhotoNotesTable.

- **SearchApiRole** – роль для функции SearchApiFunction. Она предоставляет разрешения для ведения журнала и поиска в заданном домене CloudSearch.

- **DynamoStreamHandlerRole** – роль для функции DynamoStreamHandlerFunction. Она предоставляет разрешения для ведения журнала и добавления документов в заданный домен CloudSearch.

- **MobileClientRole** – эту роль пул удостоверений Amazon Cognito применяет для пользователей, прошедших и не прошедших аутентификацию. Она предоставляет доступ к указанному API REST для API Gateway, а также разрешения на размещение объектов в MobileUploadsBucket.

### Другие ресурсы

- **MobileUploadsBucket** – корзина S3 для загруженных фотографий.

- **CloudFrontDistribution** – база раздачи CDN, где в качестве источника используется корзина MobileUploadsBucket.

- **PhotoNotesTable** – таблица DynamoDB, в которой хранятся заметки, опубликованные пользователями в мобильном приложении.

### Конфигурация

- **ConfigTable** – таблица DynamoDB для хранения значений конфигурации, которые используют различные функции Lambda. Имя этой таблицы, «MobileRefArchConfig», строго закодировано в каждой функции, его можно изменить, только обновив код.

- **ConfigHelperStack** – вложенный стек, создающий пользовательский ресурс для записи данных в таблицу ConfigTable. Этот стек создает функцию Lambda и роль выполнения, предоставляющую разрешение UpdateItem для таблицы ConfigTable.

- **NotesTableConfig** – запись конфигурации, которая определяет имя таблицы PhotoNotesTable.

- **SearchEndpointConfig** – запись конфигурации, которая определяет адрес поиска для домена CloudSearch, переданного в качестве параметра.

- **DocumentEndpointConfig** – запись конфигурации, которая определяет адрес документа для домена CloudSearch, переданного в качестве параметра.

## Лицензия

Данная эталонная архитектура лицензирована в соответствии с лицензией Apache 2.0.
