# Architettura di riferimento senza server: backend per dispositivi mobili

## Introduzione

L'architettura di riferimento per backend per dispositivi mobili ([diagramma](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf)) mostra come utilizzare [AWS Lambda](http://aws.amazon.com/lambda/) insieme ad altri servizi per creare un backend senza server per un'applicazione per dispositivi mobili. La specifica applicazione fornita come esempio in questo repository consente agli utenti di caricare foto e appunti utilizzando rispettivamente Amazon Simple Storage Service (Amazon S3) e Amazon API Gateway. Gli appunti vengono archiviati in Amazon DynamoDB ed elaborati in modo asincrono tramite i flussi di DynamoDB e una funzione di Lambda che consente di aggiungerli a un dominio di Amazon CloudSearch. Oltre al codice sorgente per le funzioni di Lambda, questo repository contiene anche un'applicazione iOS modello che fornisce esempi di come utilizzare AWS Mobile SDK per iOS per interfacciarsi con le risorse di backend definite nell'architettura.

## Esecuzione dell'esempio

Per eseguire l'intera applicazione esempio, è necessario per prima cosa distribuire le risorse di backend e successivamente compilare ed eseguire l'applicazione iOS esempio.

### Distribuzione del backend

Il modello di AWS CloudFormation fornito crea la maggior parte delle risorse di backend necessaria per questo esempio; tuttavia è necessario creare il dominio di Amazon CloudSearch, l'API REST di API Gateway e il pool di identità di Cognito al di fuori di AWS CloudFormation.

#### Passaggio 1: creare un dominio di CloudSearch

1. Tramite [AWS CLI](https://aws.amazon.com/cli/), creare un nuovo dominio di CloudSearch e assegnargli un nome a scelta.

    ```
    aws cloudsearch create-domain --domain-name [YOUR_DOMAIN_NAME]
    ```

1. Prendere nota dell'ARN del nuovo dominio nel documento di output. L'ARN verrà utilizzato come input per avviare lo stack di CloudFormation.

1. Definire gli indici per i campi "headline" e "note_text".

    ```
    aws cloudsearch define-index-field --name headline --type text --domain-name [YOUR_DOMAIN_NAME]
    aws cloudsearch define-index-field --name note_text --type text --domain-name [YOUR_DOMAIN_NAME]
    ```

    ```
    aws cloudsearch index-documents --domain-name [YOUR_DOMAIN_NAME]
    ```

#### Passaggio 2: creare un'API REST di API Gateway

1. Tramite [AWS CLI](https://aws.amazon.com/cli/), creare una nuova API e assegnarle un nome a scelta.

    ```
    aws apigateway create-rest-api --name [YOUR_API_NAME]
    ```

1. Prendere nota dell'"API ID" fornito nel documento di output. Questo valore verrà utilizzato come input per avviare lo stack di CloudFormation.

#### Passaggio 3: creare un pool di identità di Amazon Cognito

1. Tramite [AWS CLI](https://aws.amazon.com/cli/), creare un nuovo pool di identità e assegnargli un nome a scelta.

    ```
    aws cognito-identity create-identity-pool --allow-unauthenticated-identities --identity-pool-name [YOUR_POOL_NAME]
    ```

1. Prendere nota dell'"IdentityPoolId" nel documento di output. Questo valore verrà utilizzato come parametro per avviare lo stack di CloudFormation.

#### Passaggio 4: avviare il modello di CloudFormation

È possibile distribuire l'intero esempio nella regione Stati Uniti orientali 1 utilizzando il modello di CloudFormation e il bucket S3 forniti. Se si desidera distribuire il modello in un'altra regione, è necessario creare un bucket Amazon S3 in quella regione, quindi copiarvi il modello e le definizioni delle funzioni di Lambda.

Selezionare **Launch Stack** per avviare il modello nella regione Stati Uniti orientali 1 nell'account personale:

[![Launch Lambda Mobile Backend into North Virginia with CloudFormation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=lambda-mobile-backend&amp;templateURL=https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobile-backend.template)

Quando richiesto, inserire i parametri per il dominio di CloudSearch, l'API REST di API Gateway e le risorse del pool di identità di Amazon Cognito creati nei passaggi precedenti.

I dettagli sulle risorse create da questo modello sono disponibili nella sezione *CloudFormation Template Resources* di questo documento.

#### Passaggio 5: aggiornare l'API REST di API Gateway

Dopo aver creato lo stack di CloudFormation, è necessario aggiornare l'API creata in precedenza, per utilizzare la nuova "NotesApiFunction".

1. Selezionare l'API nella [Amazon API Gateway Console](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis).
1. Selezionare **Create Resource** per creare una nuova risorsa secondaria in /.
1. Digitare "notes" come nome della risorsa e "/notes" come percorso della risorsa.
1. Selezionare **Create Resource**.
1. Dopo aver selezionato la nuova risorsa "/notes", selezionare **Create Method**.
1. Selezionare "POST" e spuntare la casella.
1. Selezionare **Lambda Function** come tipo di integrazione, quindi selezionare la regione in cui è stato avviato lo stack di CloudFormation come regione per Lambda.
1. In **Lambda Function**, digitare **"NotesApiFunction"** e selezionare la funzione creata dallo stack di CloudFormation.
1. Selezionare **Save** e assegnare ad API Gateway le autorizzazioni per eseguire la funzione di Lambda.
1. Selezionare **Method Request** per modificare la configurazione della richiesta.
1. Per **Authorization type**, selezionare "AWS_IAM".
1. Per **API Key Required**, selezionare "true".
1. Selezionare **Deploy API**.
1. Per **Deployment stage**, selezionare "New Stage", quindi digitare un nome in **Stage name**.
1. Prendere nota del valore **Invoke URL** per la nuova fase. Questo valore verrà utilizzato durante l'esecuzione dell'app iOS esempio.

#### Passaggio 6: creare una chiave API

1. Nella [Amazon API Gateway Console](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis), selezionare **APIs**, quindi **API Keys**.
1. Selezionare **Create API Key**.
1. Digitare un nome per la chiave, quindi selezionare **Enabled**.
1. Selezionare **Save**.
1. Nella sezione **API Stage Association**, selezionare l'API e la fase creata nel passaggio precedente.
1. Selezionare **Add**.
1. Prendere nota del valore **API key**. Questo valore verrà utilizzato durante l'esecuzione dell'applicazione per dispositivi mobili.

#### Passaggio 7: aggiornare il pool di identità di Amazon Cognito

1. Selezionare il pool di identità nella [Amazon Cognito Console](https://console.aws.amazon.com/cognito/home?region=us-east-1).
1. Selezionare **Edit Identity Pool**.
1. Per **Unauthenticated role** e per **Authenticated role**, selezionare **MobileClientRole** creato dallo stack di CloudFormation. L'ARN completo per il ruolo viene fornito negli output dello stack.
1. Selezionare **Save Changes**.


### Esecuzione dell'applicazione iOS esempio

#### Prerequisiti

Per eseguire l'applicazione iOS esempio fornita, è necessario disporre di Mac OS X 10.10 (Yosemite) o versione più recente. Inoltre, deve essere installata la versione più recente di [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) e [Cocoa Pods](https://cocoapods.org/).

#### Creazione ed esecuzione dell'applicazione

1. Controllare o scaricare il codice sorgente per **ios-sample** in questo repository.
1. Aggiornare "MobileBackendIOS/Constants.swift" con i valori per la distribuzione del backend. La maggior parte dei valori è disponibile negli output dello stack di CloudFormation. I valori dell'URL degli endpoint e della chiave di API Gateway sono disponibili nei dettagli per l'API personale nella console di gestione AWS.
1. Eseguire Cocoa Pods dalla directory "ios-sample" radice.

    ```
    pod install
    ```

1. Aprire il file "MobileBackendIOS.xcworkspace" creato in Xcode.

    ```
    open -a Xcode MobileBackendIOS.xcworkspace
    ```

1. Creare ed eseguire il progetto da Xcode facendo clic sul pulsante di riproduzione nella parte superiore della finestra.

## Test dell'applicazione

L'applicazione esempio fornisce due caratteristiche: il caricamento di un'immagine e la pubblicazione di appunti.

### Per caricare un'immagine

1. Selezionare **Upload Image** nell'applicazione.
1. Selezionare l'icona della fotocamera, un'immagine dal rullino della fotocamera, quindi **Choose**.
1. Selezionare il pulsante **Upload**.

#### Verifica del caricamento dell'immagine

Nel pannello di output di Xcode, viene visualizzata una voce di registro che indica che l'immagine è stata caricata su Amazon S3.

Per verificare il corretto caricamento dell'immagine, è inoltre possibile sfogliare il bucket creato dallo stack di CloudFormation utilizzando la console di gestione AWS.

### Per pubblicare appunti

1. Selezionare **Post a Note**.
1. Negli appunti, digitare l'intestazione e il testo.
1. Selezionare **Save Note**.

#### Verifica della pubblicazione degli appunti

Nel pannello di output di Xcode, viene visualizzata una voce di registro che indica che gli appunti sono stati salvati correttamente.

Dopo il caricamento degli appunti, la "NotesApiFunction" viene richiamata dall'applicazione per dispositivi mobili. È possibile visualizzare i registri per questa funzione in Amazon CloudWatch.

Dopo il richiamo della funzione, viene aggiunta uno voce alla tabella DynamoDB creata nello stack di CloudFormation. È possibile verificare che gli appunti pubblicati nell'applicazione siano stati conservati nella tabella creata.

Infine, quando gli appunti vengono conservati nella tabella DynamoDB, viene aggiunto un record al flusso della tabella che viene a sua volta elaborato da "DynamoStreamHandlerFunction". È possibile visualizzare i registri di questa funzione in CloudWatch e verificare che un documento nuovo sia stato aggiunto al dominio di CloudSearch creato.


## Eliminazione delle risorse dell'applicazione

Per eliminare tutte le risorse create da questo esempio, effettuare i seguenti passaggi:

1. Eliminare tutti gli oggetti dal bucket S3 creato dallo stack di CloudFormation.
1. Eliminare lo stack di CloudFormation.
1. Eliminare il pool di identità di Amazon Cognito, API Gateway e il dominio di CloudSearch.
1. Eliminare i gruppi di registri di CloudWatch associati a ciascuna funzione di Lambda creata dallo stack di CloudFormation.

## Risorse dei modelli di CloudFormation

### Funzioni di Lambda

- **NotesApiFunction**: funzione per la gestione degli appunti pubblicati dall'applicazione per dispositivi mobili tramite API Gateway.

- **SearchApiFunction**: funzione che utilizza il dominio di CloudSearch per trovare gli appunti indicizzati in base a termini di ricerca.

- **DynamoStreamHandlerFunction**: funzione che aggiunge un documento indicizzato al dominio di CloudSearch fornito in base ai record nel flusso "PhotoNotesTable".

### Ruoli di AWS Identity and Access Management (IAM)

- **NotesApiRole**: ruolo per "NotesApiFunction". Questo ruolo assegna l'autorizzazione per l'accesso agli elementi della "PhotoNotesTable" e il loro utilizzo.

- **SearchApiRole**: ruolo per "SearchApiFunction". Questo ruolo assegna le autorizzazioni per l'accesso e la ricerca nel dominio CloudSearch fornito.

- **DynamoStreamHandlerRole**: ruolo per "DynamoStreamHandlerFunction". Questo ruolo assegna le autorizzazioni per l'accesso e l'aggiunta di documenti al dominio CloudSearch fornito.

- **MobileClientRole**: ruolo utilizzato dal pool di identità di Amazon Cognito per gli utenti autenticati e non autenticati. Questo ruolo fornisce accesso all'API REST di API Gateway fornita e assegna le autorizzazioni per il posizionamento di oggetti in "MobileUploadsBucket".

### Altre risorse

- **MobileUploadsBucket**: bucket S3 per le foto caricate dagli utenti.

- **CloudFrontDistribution**: distribuzione CDN con "MobileUploadsBucket" configurato come origine.

- **PhotoNotesTable**: tabella di DynamoDB che archivia gli appunti caricati dagli utenti dall'applicazione per dispositivi mobili.

### Configurazione

- **ConfigTable**: tabella di DynamoDB che contiene i valori della configurazione letti dalle varie funzioni di Lambda. Il nome di questa tabella, "MobileRefArchConfig", è hardcoded nel codice di ciascuna funzione e può essere modificato solo se viene aggiornato anche il codice.

- **ConfigHelperStack**: sub-stack che crea una risorsa personalizzata per la scrittura delle voci in "ConfigTable". Questo stack crea una funzione di Lambda e un ruolo di esecuzione che assegna l'autorizzazione "UpdateItem" su "ConfigTable".

- **NotesTableConfig**: voce di configurazione che identifica il nome di "PhotoNotesTable".

- **SearchEndpointConfig**: voce di configurazione che identifica il search endpoint del dominio di CloudSearch come parametro.

- **DocumentEndpointConfig**: voce di configurazione che identifica l'endpoint dei documenti del dominio di CloudSearch come parametro.

## Licenza

La licenza di questo esempio di architettura di riferimento è fornita con Apache 2.0.
