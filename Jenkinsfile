pipeline {
  agent any       // Use created Jenkins container as the base agent. Then use temp node16 container for node related steps.                                   
  environment {   // Docker hub related variables
    REGISTRY = "docker.io"
    IMAGE    = "ronniedevcurtin/ronniedevcurtin"
    TAG      = "${env.BUILD_NUMBER}"
  }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '10'))  // Retention strategy
  }

  stages {
    stage('Checkout') {
      steps {
        echo '=== [CHECKOUT] Fetching source code from Github ==='
        checkout scm    // Pull the source code from the repo configured in Jenkins job      
      }
    }

    stage('Install dependencies (Node 16)'){
      steps {           // Run Node.js build inside the temp node16 container
        echo '=== [BUILD] Running npm install ==='
        script {
          docker.image('node:16').inside {
            sh 'npm install --save 2>&1 | tee build.log'
          }
        }
        archiveArtifacts artifacts: 'build.log', fingerprint: true
      }
    }

    stage('Run tests (Node 16)'){
      steps {           // Run tests inside the temp node16 container
        echo '=== [TEST] Running npm test ==='
        script {
          docker.image('node:16').inside {
            sh 'npm test 2>&1 | tee test.log'
          }
        }
        archiveArtifacts artifacts: 'test.log', fingerprint: true
      }
    }

    stage('Snyk dependency scan (fail on High/Critical)') {
      steps {           // Run Snyk in the temp container
        echo '=== [SECURITY SCAN] Running Snyk vulnerability test ==='
        script {
          docker.image('node:16').inside {
            withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
              sh '''
                npm install -g snyk
                bash -lc 'set -o pipefail; snyk auth "$SNYK_TOKEN"; snyk test --severity-threshold=high | tee snyk.log'
              ''' 
            }
          }
        }
        archiveArtifacts artifacts: 'snyk.log', fingerprint: true
      }
    }

    stage('Build Docker image') {
      steps {           // Build Docker image using Jenkins Docker CLI connected to DinD
        echo '=== [DOCKER BUILD] Building Docker image ==='        
        sh 'docker build -t $REGISTRY/$IMAGE:$TAG . 2>&1 | tee docker-build.log'
        archiveArtifacts artifacts: 'docker-build.log', fingerprint: true
      }
    }

    stage('Push Docker image') {
      steps {           // Login Docker registry using Jenkins credentials, then push both unique build tag and latest
        echo '=== [DOCKER PUSH] Pushing Docker image to Docker Hub ==='
        withCredentials([usernamePassword(credentialsId: 'DOCKERHUB_CREDS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $REGISTRY'
        }
        sh 'docker push $REGISTRY/$IMAGE:$TAG 2>&1 | tee docker-push.log'
        archiveArtifacts artifacts: 'docker-push.log', fingerprint: true
      }
    }
  }

  post {
    success {
      echo '=== Pipeline finished SUCCESSFULLY ==='
    }    
    failure {
      echo '=== Pipeline FAILED, check logs above! ==='
    }
    always {            // Print build status at the end
      echo "Build finished with status: ${currentBuild.currentResult}"
    }
  }
}
