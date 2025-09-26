pipeline {
  agent any       // Use created Jenkins container as the base agent. Then use temp node16 container for node related steps.                                   
  environment {   // Docker hub related variables
    REGISTRY = "docker.io"
    IMAGE    = "ronniedevcurtin/ronniedevcurtin"
    TAG      = "${env.BUILD_NUMBER}"
  }

  options {
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm    // Pull the source code from the repo configured in Jenkins job      
      }
    }

    stage('Install & Test (Node 16)'){
      steps {
        script {        // Run Node.js build and test inside the temp node16 container
          docker.image('node:16').inside('-u root') {
            sh 'node -v && npm -v'
            sh 'npm install --save'
            sh 'npm test'
          }
        }
      }
    }

    stage('Snyk dependency scan (fail on High/Critical)') {
      steps {
        script {        // Run Snyk in the temp container
          docker.image('node:16').inside('-u root') {
            sh 'npm install -g snyk'
            withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
              sh 'snyk auth "$SNYK_TOKEN"'
              sh 'snyk test --severity-threshold=high'
            }
          }
        }
      }
    }

    stage('Build Docker image') {
      steps {           // Build Docker image using Jenkins Docker CLI connected to DinD
        sh 'docker version'
        sh 'docker build -t $REGISTRY/$IMAGE:$TAG .'
        sh 'docker tag $REGISTRY/$IMAGE:$TAG $REGISTRY/$IMAGE:latest'
      }
    }

    stage('Push Docker image') {
      steps {           // Login Docker registry using Jenkins credentials, then push both unique build tag and latest
        withCredentials([usernamePassword(credentialsId: 'DOCKERHUB_CREDS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $REGISTRY'
        }
        sh 'docker push $REGISTRY/$IMAGE:$TAG'
        sh 'docker push $REGISTRY/$IMAGE:latest'
      }
    }
  }

  post {
    always {            // Print build status at the end
      echo "Build finished with status: ${currentBuild.currentResult}"
    }
  }
}
