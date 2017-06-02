# Architecture de référence sans serveur : Backend mobile

## Introduction

L'architecture de référence de backend mobile ([diagramme](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf)) montre comment utiliser [AWS Lambda](http://aws.amazon.com/lambda/) avec d'autres services pour créer un backend sans serveur pour une application mobile. L'exemple d'application spécifique fourni dans ce référentiel permet aux utilisateurs de charger des photos et des notes à l'aide d'Amazon Simple Storage Service (Amazon S3) et Amazon API Gateway respectivement. Les notes sont stockées dans Amazon DynamoDB, et sont traitées en mode asynchrone à l'aide de flux DynamoDB et d'une fonction Lambda pour les ajouter dans un domaine Amazon CloudSearch. En plus du code source pour les fonctions Lambda, ce référentiel contient un prototype d'application iOS qui fournit des exemples montrant comment utiliser l'AWS Mobile SDK pour iOS afin de servir d'interface avec les ressources backend définies dans l'architecture.

## Exécution de l'exemple

Pour exécuter l'exemple d'application complet, vous devez d'abord déployer les ressources de backend, puis compiler et lancer l'exemple d'application iOS.

### Déploiement du backend

Le template AWS CloudFormation fourni crée la plupart des ressources backend dont vous avez besoin dans cet exemple, mais vous devrez encore créer le domaine Amazon CloudSearch, l'API Gateway REST API et le pool d'identités Cognito en dehors d'AWS CloudFormation.

#### Étape 1 : Créer un domaine CloudSearch

1. À l'aide de [AWS CLI](https://aws.amazon.com/cli/), créez un domaine CloudSearch en fournissant le nom de domaine de votre choix.

    ```
    aws cloudsearch create-domain --domain-name [YOUR_DOMAIN_NAME]
    ```

1. Notez l'ARN du nouveau domaine dans le document de sortie. Vous l'utiliserez comme entrée lors du lancement de la stack CloudFormation.

1. Définissez des index pour les champs `headline` et `note_text`.

    ```
    aws cloudsearch define-index-field --name headline --type text --domain-name [YOUR_DOMAIN_NAME]
    aws cloudsearch define-index-field --name note_text --type text --domain-name [YOUR_DOMAIN_NAME]
    ```

    ```
    aws cloudsearch index-documents --domain-name [YOUR_DOMAIN_NAME]
    ```
    
#### Étape 2 : Créer une API Gateway REST API

1. À l'aide de [AWS CLI](https://aws.amazon.com/cli/), créez une API en fournissant le nom de votre choix.

    ```
    aws apigateway create-rest-api --name [YOUR_API_NAME]
    ```

1. Notez l'`API ID` fourni dans le document de sortie. Vous l'utiliserez comme entrée lors du lancement de la stack CloudFormation.

#### Étape 3 : Créer un pool d'identités Amazon Cognito

1. À l'aide de [AWS CLI](https://aws.amazon.com/cli/), créez un pool d'identités en fournissant le nom de votre choix.

    ```
    aws cognito-identity create-identity-pool --allow-unauthenticated-identities --identity-pool-name [YOUR_POOL_NAME]
    ```

1. Notez la valeur de `IdentityPoolId` dans le document de sortie. Vous l'utiliserez comme paramètre lors du lancement de la stack CloudFormation.

#### Étape 4 : Lancer le template CloudFormation

Vous pouvez déployer la totalité de l'exemple dans la région us-east-1 à l'aide du template CloudFormation fourni et du bucket (compartiment) S3. Si vous souhaitez déployer le template dans une autre région, vous devez créer un bucket (compartiment) Amazon S3 dans cette région, puis copier le template et les définitions de fonction Lambda dans celui-ci.

Sélectionnez **Launch Stack** pour lancer le template dans la région us-east-1 dans votre compte :

[![Lancement de fonction Lambda Backend mobile en Virginie du Nord) avec CloudFormation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=lambda-mobile-backend&amp;templateURL=https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobile-backend.template)

À l'invite, entrez les valeurs de paramètre pour les ressources de domaine CloudSearch, d'API Gateway REST API et de pool d'identités Amazon Cognito que vous avez créées dans les étapes précédentes.

Vous trouverez des détails sur les ressources créées par ce template dans la section *Ressources de template CloudFormation* de ce document.

#### Étape 5 : Mettre à jour votre API Gateway REST API

Une fois que vous avez créé la stack CloudFormation, vous devez mettre à jour l'API que vous avez créée précédemment pour utiliser la `NotesApiFunction` nouvellement créée.

1. Sur la [console Amazon API Gateway](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis), sélectionnez votre API.
1. Sélectionnez **Create Resource** pour créer une ressource enfant sous /.
1. Tapez `notes` comme nom de ressource et `/notes` comme chemin de ressource.
1. Sélectionnez **Create Resource**.
1. Avec la nouvelle ressource `/notes` sélectionnée, choisissez **Create Method**.
1. Sélectionnez `POST` et cochez la case.
1. Sélectionnez **Lambda Function** comme type d'intégration et choisissez la région dans laquelle vous avez lancé la stack CloudFormation comme région Lambda.
1. dans **Lambda Function**, tapez **`NotesApiFunction`** et sélectionnez la fonction créée par la stack CloudFormation.
1. Sélectionnez **Save** et accordez les permissions API Gateway pour exécuter la fonction Lambda.
1. Sélectionnez **Method Request** pour modifier la configuration de demande.
1. Pour **Authorization type**, sélectionnez `AWS_IAM`.
1. Pour **API Key Required**, sélectionnez `true`.
1. Sélectionnez **Deploy API**.
1. Pour **Deployment stage**, sélectionnez `New Stage` et tapez un nom dans **Stage name**.
1. Notez la valeur de **Invoke URL** pour la nouvelle étape. Vous utiliserez cette valeur lors de l'exécution de l'exemple d'application iOS.

#### Étape 6 : Créer une clé API

1. Dans la [console Amazon API Gateway](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis), sélectionnez **APIs**, puis **API Keys**.
1. Sélectionnez **Create API Key**.
1. Entrez un nom pour la clé, puis sélectionnez **Enabled**.
1. Sélectionnez **Save**
1. Dans la section **API Stage Association**, sélectionnez votre API, puis l'étape que vous avez créée dans l'étape précédente.
1. Sélectionnez **Add**.
1. Notez la valeur de **API key**. Vous l'utiliserez lors de l'exécution de l'application mobile.

#### Étape 7 : Mettre à jour votre pool d'identités Amazon Cognito

1. Sur la [console Amazon Cognito](https://console.aws.amazon.com/cognito/home?region=us-east-1), sélectionnez votre pool d'identités.
1. Sélectionnez **Edit Identity Pool**.
1. Pour **Unauthenticated role** et **Authenticated role**, sélectionnez le rôle **MobileClientRole** créé par la stack CloudFormation. L'ARN complet pour le rôle est fourni dans les sorties de la stack.
1. Sélectionnez **Save Changes**.


### Exécution de l'exemple d'application iOS

#### Prérequis

Pour exécuter l'exemple d'application iOS fourni, vous devez utiliser Mac OS X 10.10 (Yosemite) ou une version plus récente. La dernière version de [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) et [Cocoa Pods](https://cocoapods.org/) doit également être installée.

### Création et exécution de l'application

1. Consultez ou téléchargez le code source pour l'exemple **ios-sample** dans ce référentiel.
1. Mettez à jour `MobileBackendIOS/Constants.swift` avec les valeurs pour votre déploiement de backend. La plupart des valeurs peuvent être trouvées dans les sorties de la stack CloudFormation. Les valeurs de clé d'API Gateway et d'URL d'Endpoint sont disponibles dans les détails de votre API dans AWS Management Console.
1. Exécutez Cocoa Pods à partir de la racine du répertoire `ios-sample`.

    ```
    pod install
    ```

1. Ouvrez le fichier `MobileBackendIOS.xcworkspace` généré dans Xcode.

    ```
    open -a Xcode MobileBackendIOS.xcworkspace
    ```

1. Créez et exécutez le projet depuis Xcode en cliquant sur le bouton de lecture en haut de la fenêtre.

## Test de l'application

L'exemple d'application fournit deux fonctions : chargement d'une image et publication d'une note.

### Pour charger une image

1. Sélectionnez **Upload Image** dans l'application.
1. Sélectionnez l'icône de caméra, choisissez une image dans la pellicule, puis sélectionnez **Choose**.
1. Sélectionnez le bouton **Upload**.

#### Confirmation que l'image a été chargée

Vous devez voir une entrée de journal indiquant que l'image a été chargée dans Amazon S3 dans le volet de sortie de Xcode.

Vous pouvez également parcourir le bucket (compartiment) créé par la stack CloudFormation à l'aide d'AWS Management Console pour vérifier que l'image a été chargée correctement.

### Pour publier une note

1. Sélectionnez **Post a Note**.
1. Dans la note, tapez un titre et un texte.
1. Sélectionnez **Save Note**.

#### Confirmation que la note a été publiée

Vous devez voir une entrée de journal indiquant que la note a été enregistrée avec succès dans le volet de sortie de Xcode.

Lorsque la note est chargée, la fonction `NotesApiFunction` est appelée par l'application mobile. Vous pouvez afficher les journaux pour cette fonction dans Amazon CloudWatch.

Lorsque la fonction est appelée avec succès, elle ajoute une entrée dans la table DynamoDB créée dans la stack CloudFormation. Vous pouvez vérifier que la note que vous avez publiée dans l'application a été conservée dans la table créée.

Enfin, lorsque la note est conservée dans la table DynamoDB, un enregistrement est ajouté au flux de la table qui sera à son tour traité par la fonction `DynamoStreamHandlerFunction`. Vous pouvez afficher les journaux pour cette fonction dans CloudWatch et vérifier qu'un nouveau document a été ajouté dans le domaine CloudSearch que vous avez créé.


## Nettoyage des ressources de l'application

Pour supprimer toutes les ressources créées par cet exemple, procédez comme suit :

1. Supprimez tous les objets du bucket (compartiment) S3 créé par la stack CloudFormation.
1. Supprimez la stack CloudFormation.
1. Supprimez le pool d'identités Amazon Cognito, l'API Gateway et le domaine CloudSearch.
1. Supprimez les groupes de journaux CloudWatch associés à la fonction Lambda créée par la stack CloudFormation.

## Ressources du template CloudFormation

### Fonctions Lambda

- **NotesApiFunction** - Une fonction qui traite les notes publiées à partir de l'application mobile via API Gateway.

- **SearchApiFunction** - Une fonction qui utilise le domaine CloudSearch pour trouver des notes indexées en fonction de termes de recherche.

- **DynamoStreamHandlerFunction** - Une fonction qui ajoute un document indexé au domaine CloudSearch fourni en fonction d'enregistrements dans le flux `PhotoNotesTable`.

### Rôles AWS Identity and Access Management (IAM)

- **NotesApiRole** - Un rôle pour la fonction `NotesApiFunction`. Ce rôle accorde la permission permettant de se connecter et d'utiliser des éléments de la table `PhotoNotesTable`.

- **SearchApiRole** - Un rôle pour la fonction `SearchApiFunction`. Ce rôle accorde des permissions pour se connecter et faire des recherches dans le domaine CloudSearch fourni.

- **DynamoStreamHandlerRole** - Un rôle pour la fonction DynamoStreamHandlerFunction. Ce rôle accorde des permissions pour se connecter et ajouter des documents dans le domaine CloudSearch fourni.

- **MobileClientRole** - Un rôle utilisé par votre pool d'identités Amazon Cognito pour les utilisateurs non authentifiés et authentifiés. Ce rôle donne accès à l'API Gateway REST API fournis et accorde des permissions pour placer des objets dans le bucket (compartiment) `MobileUploadsBucket`.

### Autres ressources

- **MobileUploadsBucket** - Un bucket (compartiment) S3 pour les photos chargées des utilisateurs.

- **CloudFrontDistribution** - Une distribution CDN avec le bucket (compartiment) `MobileUploadsBucket` configuré comme origine.

- **PhotoNotesTable** - Une table DynamoDB qui stocke les notes chargées par les utilisateurs à partir de l'application mobile.

### Configuration

- **ConfigTable** - Une table DynamoDB qui stocke les valeurs de configuration lues par les différentes fonctions Lambda. Le nom de cette table, « MobileRefArchConfig », est codé de manière irréversible dans le code de chaque fonction et ne peut pas être modifié sans mettre également à jour le code.

- **ConfigHelperStack** - Une sous-stack qui crée une ressource personnalisée pour écrire des entrées dans la table `ConfigTable`. Cette stack crée une fonction Lambda et un rôle d'exécution qui accorde la permission UpdateItem sur la table `ConfigTable`.

- **NotesTableConfig** - Une entrée de configuration qui identifie le nom de `PhotoNotesTable`.

- **SearchEndpointConfig** - Une entrée de configuration qui identifie l'endpoint de la recherche (Search) du domaine CloudSearch transmis comme paramètre.

- **DocumentEndpointConfig** - Une entrée de configuration qui identifie l'Endpoint de document du domaine CloudSearch transmis comme paramètre.

## Licence

Cet exemple d'architecture de référence est fourni sous licence sous Apache 2.0.
