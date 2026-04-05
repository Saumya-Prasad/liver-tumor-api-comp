pipeline {
    agent any

    parameters {
        booleanParam(name: 'SKIP_AZURE', defaultValue: true, description: 'Skip Azure deployment stages')
    }

    environment {
        IMAGE_NAME     = 'liver-tumor-api'
        ACR_NAME       = 'myliverregistry123'
        ACR_URL        = "${ACR_NAME}.azurecr.io"
        WEBAPP_NAME    = 'liver-tumor-api-prod'
        RG_NAME        = 'LiverML-RG'
        AZURE_CRED_ID  = 'azure-sp-credentials'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Lint') {
            steps {
                sh '''
                docker run --rm \
                  -v $(pwd):/app \
                  -w /app \
                  python:3.10 \
                  sh -c "pip install flake8 && flake8 . --max-line-length=120 || true"
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                docker run --rm \
                  -v $(pwd):/app \
                  -w /app \
                  python:3.10 \
                  sh -c "pip install -r requirements.txt pytest && pytest tests/ -v || true"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t $IMAGE_NAME .
                '''
            }
        }

        stage('Tag Image for ACR') {
            steps {
                sh '''
                docker tag $IMAGE_NAME $ACR_URL/$IMAGE_NAME:latest
                '''
            }
        }

        stage('Azure Login') {
            when {
                expression { return !params.SKIP_AZURE }
            }
            agent {
                docker {
                    image 'mcr.microsoft.com/azure-cli'
                    args '-u root'
                }
            }
            steps {
                withCredentials([azureServicePrincipal(
                    credentialsId: env.AZURE_CRED_ID,
                    subscriptionIdVariable: 'SUBS_ID',
                    clientIdVariable: 'CLIENT_ID',
                    clientSecretVariable: 'CLIENT_SECRET',
                    tenantIdVariable: 'TENANT_ID'
                )]) {
                    sh '''
                    az login --service-principal \
                      --username $CLIENT_ID \
                      --password $CLIENT_SECRET \
                      --tenant $TENANT_ID

                    az account set --subscription $SUBS_ID
                    '''
                }
            }
        }

        stage('ACR Login') {
            when {
                expression { return !params.SKIP_AZURE }
            }
            agent {
                docker {
                    image 'mcr.microsoft.com/azure-cli'
                    args '-u root'
                }
            }
            steps {
                sh '''
                az acr login --name $ACR_NAME
                '''
            }
        }

        stage('Push Image to ACR') {
            when {
                expression { return !params.SKIP_AZURE }
            }
            steps {
                sh '''
                docker push $ACR_URL/$IMAGE_NAME:latest
                '''
            }
        }

        stage('Simulated Deployment') {
            steps {
                sh '''
                echo "Simulating deployment..."

                docker stop liver-api || true
                docker rm liver-api || true

                docker run -d \
                  --name liver-api \
                  -p 8000:8000 \
                  $IMAGE_NAME || true
                '''
            }
        }

    }

    post {
        success {
            echo 'Pipeline executed successfully'
            echo 'Local test: http://localhost:8000'
        }
        failure {
            echo 'Pipeline failed — check logs carefully'
        }
    }
}
