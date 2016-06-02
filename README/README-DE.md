# Serverlose Referenzarchitektur: Mobiles Backend

## Einführung

Die Referenzarchitektur für mobiles Backend ([Diagramm](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf)) zeigt, wie [AWS Lambda](http://aws.amazon.com/lambda/) gemeinsam mit anderen Services verwendet wird, um ein serverloses Backend für eine mobile Anwendung zu erstellen. Über die in diesem Repository bereitgestellte spezifische Beispielanwendung können Benutzer Fotos und Notizen mithilfe von Amazon Simple Storage Service (Amazon S3) bzw. Amazon API Gateway hochladen. Die Notizen werden in Amazon DynamoDB gespeichert und asynchron durch DynamoDB Streams und eine Lambda-Funktion verarbeitet, um sie einer Amazon CloudSearch-Domain hinzuzufügen. Zusätzlich zum Quellcode für die Lambda-Funktionen enthält dieses Repository eine iOS-Prototyp-Anwendung, die Beispiele zeigt, wie das AWS Mobile SDK für iOS mit den in der Architektur definierten Backend-Ressourcen verknüpft wird.

## Ausführen der Beispielanwendung

Um die vollständige Beispielanwendung auszuführen, müssen Sie zuerst die Backend-Ressourcen bereitstellen und dann die iOS-Beispielanwendung kompilieren und ausführen.

### Bereitstellen des Backends

Die bereitgestellte AWS CloudFormation-Vorlage erstellt die meisten Backend-Ressourcen, die Sie für dieses Beispiel benötigen. Sie müssen jedoch trotzdem die Amazon CloudSearch-Domain, die REST-API in API Gateway und den Identitäts-Pool für Cognito außerhalb der AWS CloudFormation erstellen.

#### Schritt 1: Erstellen einer CloudSearch-Domain

1. Erstellen Sie mithilfe der [AWS CLI](https://aws.amazon.com/cli/) eine neue CloudSearch-Domain mit einem Domain-Namen Ihrer Wahl.

    ```
    aws cloudsearch create-domain --domain-name [YOUR_DOMAIN_NAME]
    ```

1. Notieren Sie den ARN der neuen Domain aus dem Ausgabedokument. Sie müssen ihn beim Starten des CloudFormation-Stapels eingeben.

1. Definieren Sie Indizes für die Felder "headline" und "text".

    ```
    aws cloudsearch define-index-field --name headline --type text --domain-name [YOUR_DOMAIN_NAME]
    aws cloudsearch define-index-field --name text --type text --domain-name [YOUR_DOMAIN_NAME]
    ```

#### Schritt 2: Erstellen einer REST-API in API Gateway

1. Erstellen Sie mithilfe der [AWS CLI](https://aws.amazon.com/cli/) eine neue API mit einem Namen Ihrer Wahl.

    ```
    aws apigateway create-rest-api --name [YOUR_API_NAME]
    ```

1. Notieren Sie die "API ID" der neuen Domain aus dem Ausgabedokument. Sie müssen sie beim Starten des CloudFormation-Stapels eingeben.

#### Schritt 3: Erstellen eines Identitäts-Pools für Amazon Cognito

1. Erstellen Sie mithilfe der [AWS CLI](https://aws.amazon.com/cli/) einen neuen Identitäts-Pool mit einem Namen Ihrer Wahl.

    ```
    aws cognito-identity create-identity-pool --allow-unauthenticated-identities --identity-pool-name [YOUR_POOL_NAME]
    ```

1. Notieren Sie die "IdentityPoolId" aus dem Ausgabedokument. Sie müssen sie beim Starten des CloudFormation-Stapels als Parameter eingeben.

#### Schritt 4: Starten der CloudFormation-Vorlage

Sie können das gesamte Beispiel mithilfe der CloudFormation-Vorlage und dem S3-Bucket für die Region "us-east-1" bereitstellen. Wenn Sie die Vorlage für eine andere Region bereitstellen möchten, müssen Sie einen Amazon S3-Bucket für diese Region erstellen und dann die Vorlage und die Lambda-Funktionsdefinitionen in die Region kopieren.

Wählen Sie **Launch Stack**, um die Vorlage für die Region "us-east-1" in Ihrem Konto zu starten:

[![Starten des mobilen Lambda-Backends mit CloudFormation in Nord-Virginia](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=lambda-mobile-backend&amp;templateURL=https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobile-backend.template)

Geben Sie nach Aufforderung die Parameterwerte für die CloudSearch-Domain, die REST-API in API Gateway und die Ressourcen des Identitäts-Pools für Amazon Cognito ein, die Sie in den vorherigen Schritten erstellt haben.

Details über die mithilfe dieser Vorlage erstellen Ressourcen finden Sie im Abschnitt *Ressourcen der CloudFormation-Vorlage* in diesem Dokument.

#### Schritt 5: Aktualisieren Ihrer REST-API in API Gateway

Nachdem Sie den CloudFormation-Stapel erstellt haben, müssen Sie die zuvor erstellte API aktualisieren, damit diese die neu erstellte "NotesApiFunction" verwendet.

1. Wählen Sie Ihre API in der [Amazon API Gateway-Konsole](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis) aus.
1. Wählen Sie **Create Resource** aus, um eine neue, untergeordnete Ressource unter "/" zu erstellen.
1. Geben Sie "notes" als Ressourcenname und "/notes" als Ressourcenpfad ein.
1. Wählen Sie **Create Resource** aus.
1. Wählen Sie die neue Ressource "/notes" und dann **Create Method** aus.
1. Wählen Sie "POST" aus und aktivieren Sie das Kontrollkästchen.
1. Wählen Sie als Integrationstyp **Lambda Function** und dann die Region aus, in der Sie den CloudFormation-Stapel als Lambda-Region gestartet haben.
1. Geben Sie in **Lambda Function** die Zeichenfolge **NotesApiFunction** ein und wählen Sie die vom CloudFormation-Stapel erstellte Funktion aus.
1. Klicken Sie auf **Save** und erteilen Sie API Gateway die Berechtigung zur Ausführung der Lambda-Funktion.
1. Klicken Sie auf **Method Request**, um die Anforderungskonfiguration zu bearbeiten.
1. Wählen Sie als **Authorization type** den Typ "AWS_IAM" aus.
1. Wählen Sie bei **API Key Required** die Option "true" aus.
1. Klicken Sie auf **Deploy API**.
1. Wählen Sie unter **Deployment stage** die Option "New Stage" aus und geben Sie dann bei **Stage name** einen Namen ein.
1. Notieren Sie die **Invoke URL** für die neue Stufe. Sie benötigen diesen Wert, wenn Sie die iOS-Beispielanwendung ausführen.

#### Schritt 6: Erstellen eines API-Schlüssels

1. Wählen Sie in der [Amazon API Gateway-Konsole](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis) **APIs** und dann **API Keys** aus.
1. Klicken Sie auf **Create API Key**.
1. Geben Sie einen Namen für den Schlüssel ein und wählen Sie dann **Enabled** aus.
1. Klicken Sie auf **Save**.
1. Wählen Sie im Abschnitt **API Stage Association** Ihre API und dann die Stufe aus, die Sie im vorherigen Schritt erstellt haben.
1. Klicken Sie auf **Add**.
1. Notieren Sie den **API key**. Sie benötigen ihn, wenn Sie die mobile Anwendung ausführen.

#### Schritt 7: Aktualisieren Ihres Identitäts-Pools für Amazon Cognito

1. Wählen Sie in der [Amazon Cognito-Konsole](https://console.aws.amazon.com/cognito/home?region=us-east-1) Ihren Identitäts-Pool aus.
1. Klicken Sie auf **Edit Identity Pool**.
1. Wählen Sie die vom CloudFormation-Stapel erstellte **MobileClientRole** sowohl für die **Unauthenticated role** als auch für die **Authenticated role** aus. In den Ausgaben des Stapels wird der vollständige ARN für die Rolle bereitgestellt.
1. Klicken Sie auf **Save Changes**.


### Ausführen der iOS-Beispielanwendung

#### Voraussetzungen

Um die bereitgestellte iOS-Beispielanwendung auszuführen, ist Mac OS X 10.10 (Yosemite) oder eine neuere Version erforderlich. Es müssen ebenfalls die neuesten Versionen von [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) und [Cocoa Pods](https://cocoapods.org/) installiert sein.

#### Erstellen und Ausführen der Anwendung

1. Sehen Sie sich den Quellcode für das **ios-sample** in diesem Repository an oder laden Sie ihn herunter.
1. Aktualisieren Sie "MobileBackendIOS/Constants.swift" dahingehend, dass die Werte für Ihre Backend-Bereitstellung enthalten sind. Sie finden die meisten der Werte in den Ausgaben des CloudFormation-Stapels. Der API Gateway-Schlüssel und die Werte der Endpunkt-URL stehen in der AWS Management Console in den Details Ihrer API zur Verfügung.
1. Führen Sie Cocoa Pods vom Stammverzeichnis "ios-sample" aus.

    ```
    pod install
    ```

1. Öffnen Sie die generierte Datei "MobileBackendIOS.xcworkspace" in Xcode.

    ```
    open -a Xcode MobileBackendIOS.xcworkspace
    ```

1. Erstellen Sie das Projekt in Xcode, indem Sie auf die Wiedergabe-Schaltfläche oben im Fenster klicken.

## Testen der Anwendung

Die Beispielanwendung bietet zwei Funktionen: Hochladen eines Bildes und Posten einer Notiz.

### Hochladen eines Bildes

1. Wählen Sie in der Anwendung **Upload Image** aus.
1. Wählen Sie das Kamerasymbol und ein Bild aus den eigenen Aufnahmen aus und klicken Sie dann auf **Choose**.
1. Klicken Sie auf die Schaltfläche **Upload**.

#### Überprüfen, ob das Bild hochgeladen wurde

Im Ausgabebereich von Xcode sollten Sie einen Protokolleintrag sehen, der angibt, dass das Bild zu Amazon S3 hochgeladen wurde.

Sie können ebenfalls den vom CloudFormation-Stapel erstellten Bucket mithilfe der AWS Management Console durchsuchen, um zu überprüfen, ob das Bild ordnungsgemäß hochgeladen wurde.

### Posten einer Notiz

1. Wählen Sie **Post a Note** aus.
1. Geben Sie eine Überschrift und Text in die Notiz ein.
1. Klicken Sie auf **Save Note**.

#### Überprüfen, ob die Notiz gepostet wurde

Im Ausgabebereich von Xcode sollten Sie einen Protokolleintrag sehen, der angibt, dass die Notiz erfolgreich gespeichert wurde.

Beim Hochladen der Notiz wird die "NotesApiFunction" von der mobilen Anwendung aufgerufen. Sie können die Protokolle für diese Funktion in Amazon CloudWatch anzeigen.

Wenn die Funktion erfolgreich aufgerufen wurde, fügt sie der im CloudFormation-Stapel erstellten DynamoDB-Tabelle einen Eintrag hinzu. Sie können überprüfen, ob die Notiz, die Sie in der Anwendung gepostet haben, in der erstellten Tabelle vorhanden ist.

Wenn die Notiz in der DynamoDB-Tabelle vorhanden ist, wird dem Stream der Tabelle abschließend ein Datensatz hinzugefügt, der wiederum von der "DynamoStreamHandlerFunction" verarbeitet wird. Sie können die Protokolle für diese Funktion in CloudWatch aufrufen und überprüfen, ob der von Ihnen erstellten CloudSearch-Domain ein neues Dokument hinzugefügt wurde.


## Bereinigen der Anwendungsressourcen

Gehen Sie wie folgt vor, um alle in diesem Beispiel erstellten Ressourcen zu entfernen:

1. Löschen Sie alle Objekte aus dem vom CloudFormation-Stapel erstellten S3-Bucket.
1. Löschen Sie den CloudFormation-Stapel.
1. Löschen Sie den Identitäts-Pool für Amazon Cognito, das API Gateway und die CloudSearch-Domain.
1. Löschen Sie die CloudWatch-Protokollgruppen, die mit den einzelnen vom CloudFormation-Stapel erstellten Lambda-Funktionen verknüpft sind.

## Ressourcen der CloudFormation-Vorlage

### Lambda-Funktionen

- **NotesApiFunction** – eine Funktion, die von der mobilen Anwendung gepostete Notizen über das API Gateway verarbeitet.

- **SearchApiFunction** – eine Funktion, die die CloudSearch-Domain verwendet, um indizierte Notizen basierend auf Suchbegriffen zu finden.

- **DynamoStreamHandlerFunction** – eine Funktion, die der bereitgestellten CloudSearch-Domain ein indiziertes Dokument basierend auf den Datensätzen im "PhotoNotesTable"-Stream hinzufügt.

### Identity and Access Management (IAM)-Rollen

- **NotesApiRole** – eine Rolle für die "NotesApiFunction". Mit dieser Rolle wird die Berechtigung zur Protokollerstellung und zur Bearbeitung von Elementen im "PhotoNotesTable" erteilt.

- **SearchApiRole** – eine Rolle für die "SearchApiFunction". Mit dieser Rolle werden Berechtigungen für die Protokollerstellung und die Suche in der bereitgestellten CloudSearch-Domain erteilt.

- **DynamoStreamHandlerRole** – eine Rolle für die "DynamoStreamHandlerFunction". Mit dieser Rolle werden Berechtigungen für die Protokollerstellung und zum Hinzufügen von Dokumenten in der bereitgestellten CloudSearch-Domain erteilt.

- **MobileClientRole** – eine Rolle, die von Ihrem Identitäts-Pool für Amazon Cognito sowohl für nicht authentifizierte als auch für authentifizierte Benutzer verwendet wird. Diese Rolle bietet Zugriff auf die bereitgestellte REST-API in API Gateway und erteilt Berechtigungen zum Ablegen von Objekten im "MobileUploadsBucket".

### Sonstige Ressourcen

- **MobileUploadsBucket** – ein S3-Bucket für von Benutzern hochgeladene Fotos.

- **CloudFrontDistribution** – eine CDN-Verteilung, in der "MobileUploadsBucket" als ein Ausgangspunkt konfiguriert ist.

- **PhotoNotesTable** – eine DynamoDB-Tabelle, die von Benutzern über die mobile Anwendung hochgeladene Notizen speichert.

### Konfiguration

- **ConfigTable** – eine DynamoDB-Tabelle, die von den verschiedenen Lambda-Funktionen ausgelesene Konfigurationswerte enthält. Der Name dieser Tabelle, "MobileRefArchConfig", ist im Code jeder einzelnen Funktion hardcodiert und kann nicht ohne Aktualisierung des Codes geändert werden.

- **ConfigHelperStack** – ein untergeordneter Stapel, der eine benutzerdefinierte Ressource zum Schreiben von Einträgen in "ConfigTable" erstellt. Dieser Stapel erstellt eine Lambda-Funktion und eine Ausführungsrolle, die "UpdateItem" eine Berechtigung für "ConfigTable" erteilt.

- **NotesTableConfig** – ein Konfigurationseintrag, der den Namen "PhotoNotesTable" bezeichnet.

- **SearchEndpointConfig** – ein Konfigurationseintrag, der den Suchendpunkt der als Parameter übergebenen CloudSearch-Domain bezeichnet.

- **DocumentEndpointConfig** – ein Konfigurationseintrag, der den Dokumentendpunkt der als Parameter übergebenen CloudSearch-Domain bezeichnet.

## Lizensierung

Dieses Beispiel einer Referenzarchitektur ist unter Apache 2.0 lizensiert.
