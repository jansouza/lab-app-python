pipeline {
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: python
            image: python:3.8
            alwaysPullImage: true
            command: ["sleep", "infinity"]
          - name: kaniko
            image: gcr.io/kaniko-project/executor:debug
            alwaysPullImage: true
            command: ["sleep", "infinity"]
          - name: devops-tools
            image: jansouza/devops-tools:latest
            alwaysPullImage: true
            command: ["sleep", "infinity"]
      '''
      defaultContainer 'python'
    }
  }

  environment {
    APP_NAME = "lab-app-python"
    APP_BRANCH = "main"
    APP_REPO = "git@github.com:jansouza/lab-app-python.git"
    APP_REPO_CRED = "github-jansouza"

    SONAR_PROJECT_KEY = "${APP_NAME}"
    SONAR_URL = "http://sonarqube-service.devops-tools.svc:9000"
    SONAR_TOKEN = credentials('sonar-token')

    DEPLOY_ENV = "qas"
    DEPLOY_REGISTRY = "registry.docker-registry.svc:5001"
  }

  stages {

    stage('Checkout Source') {
      steps {
        container('python') {
          git branch: "$APP_BRANCH",
              credentialsId: "$APP_REPO_CRED",
              url: "$APP_REPO"
          
          script {
            APP_VERSION = sh(script:"python src/setup.py --version", returnStdout: true).trim()
            echo "${APP_VERSION}"
          }
        }
      }
    }

    stage('DevSecOps - gitleaks') {
      steps {
        container('devops-tools') {
          sh """
          gitleaks detect --source . -v -f sarif -r ${WORKSPACE}/gitleaks-report.sarif
          """
        }
      }
    }

    stage('Code Test') {
      steps {
        container('python') {
          sh """
          pip install --no-cache-dir -r src/requirements.txt

          pytest -v --junit-xml ${WORKSPACE}/pytest-report.xml src/ 
          """
        }
      }
    } //Code Test
  
    stage('SonarQube') {
      steps {
        container('devops-tools') {
          sh """
          sonar-scanner \
            -Dsonar.projectKey=$SONAR_PROJECT_KEY \
            -Dsonar.sources=src/ \
            -Dsonar.host.url=$SONAR_URL \
            -Dsonar.token=$SONAR_TOKEN \
            -Dsonar.qualitygate.wait=true
          """
        }
      }
    } //SonarQube

    stage('Build - Registry') {
      environment {
        PATH = "/busybox:/kaniko:$PATH"
        DEPLOY_IMAGE = "${DEPLOY_ENV}/${APP_NAME}:v${APP_VERSION}-${currentBuild.number}"
        DEPLOY_IMAGE_LATEST = "${DEPLOY_ENV}/${APP_NAME}:latest"
      }
      steps {
        container(name: 'kaniko', shell: '/busybox/sh') {
          sh """
          /kaniko/executor --context `pwd` --dockerfile Dockerfile \
          --label app_name=${APP_NAME} \
          --label app_version=${APP_VERSION} \
          --label app_build=${currentBuild.number} \
          --skip-tls-verify \
          --destination ${DEPLOY_REGISTRY}/${DEPLOY_IMAGE} \
          --destination ${DEPLOY_REGISTRY}/${DEPLOY_IMAGE_LATEST} \
          --verbosity info
          """
        }
      }
    } //Build - Registry

    stage('DevSecOps - Image') {
      environment {
        DEPLOY_IMAGE = "${DEPLOY_ENV}/${APP_NAME}:v${APP_VERSION}-${currentBuild.number}"
      }
      steps {
        container('devops-tools') {
          sh """
          trivy image --exit-code 1 --format sarif -o ${WORKSPACE}/trivy-scan-report.sarif --ignore-unfixed --severity CRITICAL --insecure ${DEPLOY_REGISTRY}/${DEPLOY_IMAGE}
          """
        }
      }
    } //SecOps

    stage('Deploy - K3s') {
      environment {
        DEPLOY_IMAGE = "${DEPLOY_ENV}/${APP_NAME}:v${APP_VERSION}-${currentBuild.number}"
      }
      steps {
        container('devops-tools') {
          withCredentials([file(credentialsId: 'k3s-kubeconfig', variable: 'KUBECONFIG')]) {
            sh """
            echo $KUBECONFIG > ~/.kube/config

            chmod +x /usr/local/bin/k8s-deploy.sh
            k8s-deploy.sh --app=${APP_NAME} --image=${DEPLOY_REGISTRY}/${DEPLOY_IMAGE} --path=deployments/${DEPLOY_ENV}
            """
          }
        }
      }
    } //Deploy - K3s

  } //stages

  post { 
    always { 
      archiveArtifacts artifacts: 'gitleaks-report.sarif'
      archiveArtifacts artifacts: 'pytest-report.xml'
      archiveArtifacts artifacts: 'trivy-scan-report.sarif'
    }
  }
} // pipeline
