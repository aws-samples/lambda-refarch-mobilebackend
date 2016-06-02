# Arquitetura de referência sem servidor: back-end móvel

## Introdução

A arquitetura de referência de back-end móvel ([diagrama](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf)) demonstra como usar o [AWS Lambda](http://aws.amazon.com/lambda/) juntamente com outros serviços para construir um back-end sem servidor para um aplicativo móvel. O aplicativo de exemplo específico fornecido neste repositório permite aos usuários fazer upload de fotos e notas usando o Amazon Simple Storage Service (Amazon S3) e o Amazon API Gateway, respectivamente. As notas são armazenadas no Amazon DynamoDB, e são processadas de forma assíncrona usando fluxos DynamoDB e uma função Lambda para adicioná-las a um domínio do Amazon CloudSearch. Além do código-fonte para as funções do Lambda, este repositório também contém um aplicativo iOS protótipo que fornece exemplos de como usar o AWS Mobile SDK para iOS para fazer a interface com os recursos de back-end definidos na arquitetura.

## Executando o exemplo

Para executar o aplicativo de exemplo completo, você deve primeiro implantar os recursos de back-end e, em seguida, compilar e executar o exemplo de aplicativo para iOS.

### Implementando o back-end

O modelo do AWS CloudFormation fornecido cria a maior parte dos recursos de back-end que você precisa para este exemplo, mas você ainda precisa criar o domínio do Amazon CloudSearch, a API REST do gateway de API e um pool de identidades do Cognito fora do AWS CloudFormation.

#### Etapa 1: criar um domínio do CloudSearch

1. Usando o [AWS CLI](https://aws.amazon.com/cli/), crie um novo domínio do CloudSearch fornecendo um nome de domínio a sua escolha.

    ```
    aws cloudsearch create-domain --domain-name [YOUR_DOMAIN_NAME]
    ```

1. Anote o ARN do novo domínio no documento de saída. Você vai usá-lo como uma entrada ao iniciar a pilha do CloudFormation.

1. Defina índices para os campos "headline" e "text".

    ```
    aws cloudsearch define-index-field --name headline --type text --domain-name [YOUR_DOMAIN_NAME]
    aws cloudsearch define-index-field --name text --type text --domain-name [YOUR_DOMAIN_NAME]
    ```

#### Etapa 2: criar uma API REST do gateway de API

1. Usando o [AWS CLI](https://aws.amazon.com/cli/), crie uma nova API fornecendo um nome de domínio a sua escolha.

    ```
    aws apigateway create-rest-api --name [YOUR_API_NAME]
    ```

1. Anote o "ID da API" fornecido no documento de saída. Você vai usá-lo como uma entrada ao iniciar a pilha do CloudFormation.

#### Etapa 3: criar um pool de identidades do Amazon Cognito

1. Usando o [AWS CLI](https://aws.amazon.com/cli/), crie um novo pool de identidades fornecendo um nome de domínio a sua escolha.

    ```
    aws cognito-identity create-identity-pool --allow-unauthenticated-identities --identity-pool-name [YOUR_POOL_NAME]
    ```

1. Anote o "IdentityPoolId" no documento de saída. Você vai usá-lo como um parâmetro ao iniciar a pilha do CloudFormation.

#### Etapa 4: iniciar o modelo do CloudFormation

Você pode implantar o exemplo inteiro na região us-east-1 usando o modelo do CloudFormation e bucket S3 fornecido. Se você quiser implantar o modelo em uma região diferente, você deve criar um bucket do Amazon S3 naquela região, e depois copiar as definições do modelo e função do Lambda nele.

Escolha **Launch Stack** para iniciar o modelo na região us-east-1 em sua conta:

[![Launch Lambda Mobile Backend into North Virginia with CloudFormation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=lambda-mobile-backend&amp;templateURL=https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobile-backend.template)

Quando solicitado, digite os valores dos parâmetros para o domínio dos recursos CloudSearch, REST API do gateway de API e pool de identidades do Amazon Cognito que você criou nas etapas anteriores.

Os detalhes sobre os recursos criados por este modelo são fornecidos na seção *Recursos do modelo do CloudFormation* deste documento.

#### Etapa 5: atualizar sua API REST do gateway de API

Depois de ter criado a pilha do CloudFormation, você precisa atualizar a API criada anteriormente para usar o recém-criado "NotesApiFunction".

1. No [Amazon API Gateway Console](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis), escolha a API.
1. Escolha **Create Resource** para criar um novo recurso dependente em /.
1. Digite "notes" como nome do recurso e "/notes" como caminho.
1. Escolha **Create Resource**.
1. Com o novo recurso "/notes" selecionado, escolha **Create Method**.
1. Escolha "POST" e marque a caixa de seleção.
1. Escolha **Lambda Function** como o tipo de integração e, em seguida, escolha a região onde iniciar a pilha do CloudFormation como também a região da função do Lambda.
1. Em **Lambda Function**, digite **`NotesApiFunction`** e, em seguida, selecione a função criada pela pilha do CloudFormation.
1. Escolha **Save** e dê permissão ao gateway de API para executar a função do Lambda.
1. Escolha **Method Request** para editar a configuração do pedido.
1. Em **Authorization type**, selecione "AWS_IAM".
1. Em **API Key Required**, selecione "true".
1. Escolha **Deploy API**.
1. Em **Deployment stage**, escolha "New Stage" e, em seguida, digite o nome em **Stage name**.
1. Anote o **Invoke URL** para o próximo estágio. Você vai usá-lo ao executar o aplicativo para iOS de amostra.

#### Etapa 6: criar uma chave de API

1. No [Amazon API Gateway Console](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis), escolha **APIs** e, em seguida, escolha **API Keys**.
1. Escolha **Create API Key**.
1. Digite um nome para as chaves e selecione **Enabled**.
1. Escolha **Save**
1. Na seção **API Stage Association**, escolha sua API e, em seguida, escolha o estágio que você criou no passo anterior.
1. Escolha **Add**.
1. Anote a **API key**. Você vai usá-la ao executar o aplicativo móvel.

#### Etapa 7: atualizar o pool de identidades do Amazon Cognito

1. No [Amazon Cognito Console](https://console.aws.amazon.com/cognito/home?region=us-east-1), selecione seu pool de identidades.
1. Escolha **Edit Identity Pool**.
1. Para **Unauthenticated role** e **Authenticated role**, selecione o **MobileClientRole** criado pela pilha do CloudFormation. O ARN completo para a função é fornecido nas saídas da pilha.
1. Escolha **Save Changes**.


### Executando a amostra do aplicativo para iOS

#### Pré-requisitos

Para executar a amostra do aplicativo para iOS fornecido, você deve estar executando o Mac OS X 10.10 (Yosemite) ou uma versão mais recente. Você também deve ter as versões mais recentes do [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) e do [Cocoa Pods](https://cocoapods.org/) instaladas.

#### Desenvolvendo e executando o aplicativo

1. Verifique ou faça o download do código-fonte do **ios-sample** neste repositório.
1. Atualize "MobileBackendIOS/Constants.swift" com os valores para a implementação do back-end. A maioria dos valores podem ser encontrados nas saídas da pilha do CloudFormation. Os valores de chave do gateway de API e URL de endpoint estão disponíveis em detalhes para sua API no AWS Management Console.
1. Execute Cocoa Pods a partir do diretório raiz "ios-sample".

    ```
    pod install
    ```

1. Abra o arquivo "MobileBackendIOS.xcworkspace" gerado no Xcode.

    ```
    abra -a Xcode MobileBackendIOS.xcworkspace
    ```

1. Desenvolva e execute o projeto do Xcode, clicando no botão de reprodução na parte superior da janela.

## Testando o aplicativo

O aplicativo de amostra fornece dois recursos: fazer upload de uma imagem e postar uma nota.

### Para fazer upload de uma imagem

1. Escolha **Upload Image** no aplicativo.
1. Escolha o ícone da câmera, selecione uma imagem no rolo da câmera e, em seguida, escolha **Choose**.
1. Escolha o botão **Upload**.

#### Validando a imagem que foi carregada

Você deverá ver uma entrada de registro que diz que a imagem foi carregada para o Amazon S3 no painel de saída do Xcode.

Você também pode procurar o bucket criado pela pilha CloudFormation usando o Console de Gerenciamento da AWS para verificar se a imagem foi corretamente carregada.

### Para postar uma nota

1. Escolha **Post a Note**.
1. Na nota, digite um título e o texto.
1. Escolha **Save Note**.

#### Validando a nota que foi postada

Você deverá ver uma entrada de registro de que a nota foi salva com sucesso para o Amazon S3 no painel de saída do Xcode.

Quando a nota é carregada, o "NotesApiFunction" é chamado pelo aplicativo móvel. É possível visualizar os registros para esta função no Amazon CloudWatch.

Quando a função é chamada com sucesso, ela adiciona uma entrada à tabela DynamoDB criada na pilha do CloudFormation. Você pode verificar se a nota que você postou no aplicativo se mantém na tabela criada.

Finalmente, quando a nota é mantida na tabela DynamoDB, um registro é adicionado ao fluxo da tabela, que por sua vez é processado por "DynamoStreamHandlerFunction". É possível visualizar os registros para esta função em CloudWatch e verificar se um novo documento foi adicionado ao domínio do CloudSearch que você criou.


## Limpando os recursos do aplicativo

Para remover todos os recursos criados por este exemplo, faça o seguinte:

1. Exclua todos os objetos do bucket S3 criados pela pilha do CloudFormation.
1. Exclua a pilha do CloudFormation.
1. Exclua o pool de identidades do Amazon Cognito, o gateway de API e o domínio do CloudSearch.
1. Exclua os grupos de registro do CloudWatch associados a cada função Lambda criada pela pilha CloudFormation.

## Recursos do modelo do CloudFormation

### Funções lambda

- **NotesApiFunction** - Uma função para lidar com notas postadas no aplicativo móvel através do gateway da API.

- **SearchApiFunction** - Uma função que usa o domínio do CloudSearch para encontrar notas indexadas com base em termos de pesquisa.

- **DynamoStreamHandlerFunction** - Uma função que adiciona um documento indexado ao domínio do CloudSearch fornecido com base em registros no fluxo "PhotoNotesTable".

### Funções AWS Identity and Access Management (IAM)

- **NotesApiRole** - Uma função para a "NotesApiFunction". Esta função concede a permissão para iniciar sessão e trabalhar com itens da "PhotoNotesTable".

- **SearchApiRole** - Uma função para a "SearchApiFunction". Esta função concede a permissão para iniciar sessão e pesquisar no domínio do CloudSearch fornecido.

- **DynamoStreamHandlerRole** - Uma função para a DynamoStreamHandlerFunction. Esta função concede a permissão para iniciar sessão e adicionar documentos ao domínio do CloudSearch fornecido.

- **MobileClientRole** - Uma função usada pelo pool de identidades Amazon Cognito para usuários autenticados ou não. Esta função fornece acesso à REST API do gateway de API fornecida, bem como permissões para adicionar objetos ao "MobileUploadsBucket".

### Outros recursos

- **MobileUploadsBucket** - Um bucket S3 para o upload de fotos de usuários.

- **CloudFrontDistribution** - Uma distribuição CDN com o "MobileUploadsBucket" configurado como uma origem.

- **PhotoNotesTable** - Uma tabela DynamoDB que armazena o upload de fotos feitas pelos usuários a partir do aplicativo móvel.

### Configuração

- **ConfigTable** - Uma tabela DynamoDB para armazenar valores de configuração lidos pelas várias funções Lambda. O nome desta tabela, "MobileRefArchConfig", é codificado em cada código da função e não pode ser modificado sem também atualizar o código.

- **ConfigHelperStack** - A subpilha que cria um recurso personalizado para escrever entradas à "ConfigTable". Esta pilha cria uma função e execução da função Lambda que concede a permissão ao UpdateItem na "ConfigTable".

- **NotesTableConfig** - Uma entrada de configuração que identifica o nome da "PhotoNotesTable".

- **SearchEndpointConfig** - Uma entrada de configuração que identifica o ponto de extremidade da busca do domínio do CloudSearch transmitido como um parâmetro.

- **DocumentEndpointConfig** - Uma entrada de configuração que identifica o ponto de extremidade dos documentos do domínio do CloudSearch transmitido como um parâmetro.

## Licença

Este exemplo de arquitetura de referência é licenciado sob a licença do Apache 2.0.
