# Arquitectura de referencia sin servidor: Back-end móvil

## Introducción

La arquitectura de referencia Back-end móvil ([diagrama](https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/lambda-refarch-mobilebackend.pdf)) muestra cómo usar [AWS Lambda](http://aws.amazon.com/lambda/) junto con otros servicios para crear un backend sin servidor para una aplicación móvil. La aplicación de ejemplo concreta proporcionada en este repositorio permite a los usuarios cargar fotos y notas mediante Amazon Simple Storage Service (Amazon S3) y Amazon API Gateway, respectivamente. Las notas se almacenan en Amazon DynamoDB y se procesan de forma asincrónica mediante flujos de DynamoDB y una función Lambda para añadirlas a un dominio de Amazon CloudSearch. Además del código fuente de las funciones Lambda, este repositorio contiene también una aplicación iOS modelo que proporciona ejemplos de cómo usar el SDK de AWS Mobile para iOS para interactuar con los recursos del back-end definidos en la arquitectura.

## Ejecución del ejemplo

Para ejecutar la aplicación de ejemplo completa, primero debe implementar los recursos del back-end y, a continuación, compilar y ejecutar la aplicación iOS de ejemplo.

### Implementación del back-end

La plantilla de AWS CloudFormation proporcionada crea la mayoría de los recursos del backend que necesita para este ejemplo, pero tendrá que crear el dominio de Amazon CloudSearch, la API REST de API Gateway y el grupo de identidades de Cognito fuera de AWS CloudFormation.

#### Paso 1: Crear un dominio de CloudSearch

1. Mediante [AWS CLI](https://aws.amazon.com/cli/), cree un nuevo dominio de CloudSearch proporcionando el nombre de dominio que desee.

    ```
    aws cloudsearch create-domain --domain-name [YOUR_DOMAIN_NAME]
    ```

1. Anote el ARN del nuevo dominio en el documento de salida. Lo usará como dato de entrada cuando lance la pila de CloudFormation.

1. Defina índices para los campos `headline` y `text`.

    ```
    aws cloudsearch define-index-field --name headline --type text --domain-name [YOUR_DOMAIN_NAME]
    aws cloudsearch define-index-field --name text --type text --domain-name [YOUR_DOMAIN_NAME]
    ```

#### Paso 2: Crear una API REST de API Gateway

1. Mediante [AWS CLI](https://aws.amazon.com/cli/), cree una nueva API proporcionando el nombre que desee.

    ```
    aws apigateway create-rest-api --name [YOUR_API_NAME]
    ```

1. Anote el `API ID` proporcionado en el documento de salida. Lo usará como dato de entrada cuando lance la pila de CloudFormation.

#### Paso 3: Crear un grupo de identidades de Amazon Cognito

1. Mediante [AWS CLI](https://aws.amazon.com/cli/), cree un nuevo grupo de identidades proporcionando el nombre que desee.

    ```
    aws cognito-identity create-identity-pool --allow-unauthenticated-identities --identity-pool-name [YOUR_POOL_NAME]
    ```

1. Anote el `IdentityPoolId` del documento de salida. Lo usará como un parámetro cuando lance la pila de CloudFormation.

#### Paso 4: Lanzar la plantilla de CloudFormation

Puede implementar todo el ejemplo en la región us-east-1 mediante la plantilla de CloudFormation y el bucket de S3 proporcionados. Si desea implementar la plantilla en otra región, debe crear un bucket de Amazon S3 en esa región y después copiar en él la plantilla y las definiciones de funciones Lambda.

Elija **Launch Stack** para lanzar la plantilla en la región us-east-1 de su cuenta:

[![Launch Lambda Mobile Backend into North Virginia with CloudFormation](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=lambda-mobile-backend&amp;templateURL=https://s3.amazonaws.com/awslambda-reference-architectures/mobile-backend/mobile-backend.template)

Cuando se le pida, escriba los valores de parámetro de los recursos de dominio de CloudSearch, API REST de API Gateway y grupo de identidades de Amazon Cognito que creó en los pasos anteriores.

En la sección *Recursos de la plantilla de CloudFormation* de este documento encontrará información detallada sobre los recursos creados por esta plantilla.

#### Paso 5: Actualizar la API REST de API Gateway

Una vez creada la pila de CloudFormation, necesita actualizar la API que creó previamente para que use la función `NotesApiFunction` recién creada.

1. En la [consola de Amazon API Gateway](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis), elija su API.
1. Elija **Create Resource** para crear un recurso secundario bajo /.
1. Escriba `notes` como el nombre del recurso y `/notes` como la ruta del recurso.
1. Elija **Create Resource**.
1. Con el nuevo recurso `/notes` seleccionado, elija **Create Method**.
1. Elija `POST` y active la casilla de verificación.
1. Elija **Lambda Function** como tipo de integración y después elija la región donde lanzó la pila de CloudFormation como la región Lambda.
1. en **Lambda Function**, escriba **`NotesApiFunction`** y seleccione la función creada por la pila de CloudFormation.
1. Elija **Save** y otorgue permisos a API Gateway para ejecutar la función Lambda.
1. Elija **Method Request** para editar la configuración de la solicitud.
1. Para **Authorization type**, seleccione `AWS_IAM`.
1. Para **API Key Required**, seleccione `true`.
1. Elija **Deploy API**.
1. Para **Deployment stage**, elija `New Stage` y después escriba un nombre en **Stage name**.
1. Anote el valor de **Invoke URL** para la nueva etapa. Usará este valor cuando ejecute la aplicación iOS de ejemplo.

#### Paso 6: Crear una clave API

1. En la [consola de Amazon API Gateway](https://console.aws.amazon.com/apigateway/home?region=us-east-1#/apis), elija **APIs** y después **API Keys**.
1. Elija **Create API Key**.
1. Escriba un nombre para la clave y seleccione **Enabled**.
1. Elija **Save**
1. En la sección **API Stage Association**, elija su API y después elija la etapa que creó en el paso anterior.
1. Elija **Add**.
1. Anote el valor de **API key**. Usará este valor cuando ejecute la aplicación móvil.

#### Paso 7: Actualizar el grupo de identidades de Amazon Cognito

1. En la [consola de Amazon Cognito](https://console.aws.amazon.com/cognito/home?region=us-east-1), seleccione el grupo de identidades.
1. Elija **Edit Identity Pool**.
1. Para **Unauthenticated role** y **Authenticated role**, seleccione el **MobileClientRole** creado por la pila de CloudFormation. El ARN completo del rol se proporciona en los resultados de la pila.
1. Elija **Save Changes**.


### Ejecución de la aplicación iOS de ejemplo

#### Requisitos previos

Para ejecutar la aplicación iOS de ejemplo proporcionada, debe ejecutar Mac OS X 10.10 (Yosemite) o una versión más reciente. También debe tener la última versión de [Xcode](https://itunes.apple.com/us/app/xcode/id497799835) y [Cocoa Pods](https://cocoapods.org/) instalada.

#### Compilación y ejecución de la aplicación

1. Revise o descargue el código fuente de **ios-sample** de este repositorio.
1. Actualice `MobileBackendIOS/Constants.swift` con los valores de su implementación del back-end. La mayoría de los valores se encuentran en los resultados de la pila de CloudFormation. Los valores de URL de punto de enlace y clave de API Gateway están disponibles para su API en la consola de administración de AWS.
1. Ejecute Cocoa Pods desde el directorio raíz `ios-sample`.

    ```
    pod install
    ```

1. Abra el archivo `MobileBackendIOS.xcworkspace` generado en Xcode.

    ```
    open -a Xcode MobileBackendIOS.xcworkspace
    ```

1. Compile y ejecute el proyecto en Xcode haciendo clic en el botón de reproducción situado en la parte superior de la ventana.

## Probar la aplicación

La aplicación de ejemplo proporciona dos funcionalidades: cargar una imagen y publicar una nota.

### Para cargar una imagen

1. Elija **Upload Image** en la aplicación.
1. Elija el icono de cámara, seleccione una imagen del álbum de la cámara y después elija **Choose**.
1. Elija el botón **Upload**.

#### Comprobar que la imagen se ha cargado

Debería ver una entrada de log en la que se indica que la imagen se ha cargado en Amazon S3 en el panel de resultados de Xcode.

También puede examinar el bucket creado por la pila de CloudFormation mediante la consola de administración de AWS para comprobar que la imagen se ha cargado correctamente.

### Para publicar una nota

1. Elija **Post a Note**.
1. En la nota, escriba un título y el texto.
1. Elija **Save Note**.

#### Comprobar que la nota se ha publicado

Debería ver una entrada de log en la que se indica que la nota se ha guardado correctamente en el panel de resultados de Xcode.

Cuando se carga la nota, la aplicación móvil llama a `NotesApiFunction`. Puede ver los logs de esta función en Amazon CloudWatch.

Cuando la función se invoca correctamente, añade una entrada a la tabla de DynamoDB creada en la pila de CloudFormation. Puede verificar que la nota publicada en la aplicación permanece en la tabla creada.

Por último, si la nota permanece en la tabla DynamoDB, se añade un registro al flujo de la tabla que, a su vez, procesa la función `DynamoStreamHandlerFunction`. Puede ver los logs de esta función en CloudWatch y verificar que se ha añadido un nuevo documento al dominio de CloudSearch que ha creado.


## Borrado de los recursos de la aplicación

Para eliminar todos los recursos creados por este ejemplo, proceda del modo siguiente:

1. Elimine todos los objetos del bucket de S3 creados por la pila de CloudFormation.
1. Elimine la pila de CloudFormation.
1. Elimine el grupo de identidades de Amazon Cognito, API Gateway y el dominio de CloudSearch.
1. Elimine los grupos de logs de CloudWatch asociados a cada función Lambda creada por la pila de CloudFormation.

## Recursos de la plantilla de CloudFormation

### Funciones Lambda

- **NotesApiFunction**: una función para gestionar la notas publicadas desde la aplicación móvil a través de API Gateway.

- **SearchApiFunction**: una función que usa el dominio de CloudSearch para buscar notas indexadas a partir de términos de búsqueda.

- **DynamoStreamHandlerFunction**: una función que añade un documento indexado al dominio de CloudSearch proporcionado en función de los registros del flujo de `PhotoNotesTable`.

### Roles de AWS Identity and Access Management (IAM)

- **NotesApiRole**: un rol para la función `NotesApiFunction`. Este rol otorga permiso para registrar y trabajar con los elementos de `PhotoNotesTable`.

- **SearchApiRole**: un rol para la función `SearchApiFunction`. Este rol otorga permisos para registrar y buscar el dominio de CloudSearch proporcionado.

- **DynamoStreamHandlerRole**: un rol para la función DynamoStreamHandlerFunction. Este rol otorga permisos para registrar y añadir documentos al dominio de CloudSearch proporcionado.

- **MobileClientRole**: un rol usado por su grupo de identidades de Amazon Cognito para los usuarios autenticados y no autenticados. Este rol proporciona acceso a la API REST de API Gateway, además de permisos para colocar objetos en `MobileUploadsBucket`.

### Otros recursos

- **MobileUploadsBucket**: un bucket de S3 para las fotos cargadas por los usuarios.

- **CloudFrontDistribution**: una distribución de CDN con `MobileUploadsBucket` configurado como origen.

- **PhotoNotesTable**: una tabla de DynamoDB que almacena las notas cargadas por los usuarios desde la aplicación móvil.

### Configuración

- **ConfigTable**: una tabla de DynamoDB para almacenar los valores de configuración leídos por las distintas funciones Lambda. El nombre de esta tabla, "MobileRefArchConfig", está codificado de forma rígida en el código de cada función y no se puede modificar sin actualizar también el código.

- **ConfigHelperStack**: una pila secundaria que crea un recurso personalizado para escribir entradas en `ConfigTable`. Esta pila crea una función Lambda y un rol de ejecución que otorga permiso a UpdateItem en `ConfigTable`.

- **NotesTableConfig**: una entrada de configuración que identifica el nombre `PhotoNotesTable`.

- **SearchEndpointConfig**: una entrada de configuración que identifica el punto de enlace de búsqueda del dominio de CloudSearch pasado como parámetro.

- **DocumentEndpointConfig**: una entrada de configuración que identifica el punto de enlace de documento del dominio de CloudSearch pasado como parámetro.

## Licencia

Este ejemplo de arquitectura de referencia tiene licencia de Apache 2.0.
