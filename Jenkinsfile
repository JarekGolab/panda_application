pipeline {
    agent {
  label 'dockerslave'
}

    environment {
        IMAGE = readMavenPom().getArtifactId()
        VERSION = readMavenPom().getVersion()
    }
    tools {
  maven 'M3'
}

    stages {
        stage('Clear running application') {
            steps {
                sh 'docker rm -f ${container_name} || true'
            }
        }
         stage('Get code') {
            steps {
                git branch: 'test_selenium', credentialsId: 'PandaGitHub', url: 'https://github.com/JarekGolab/panda_application.git'
            }
        }
        stage('Build and JUnit tests') {
            steps {
                // Get some code from a GitHub repository
                sh "mvn clean install"

                // Run Maven on a Unix agent.
                sh "mvn -Dmaven.test.failure.ignore=true clean package"

                // To run Maven on a Windows agent, use
                // bat "mvn -Dmaven.test.failure.ignore=true clean package"
            }
        }
         stage('Build docker image') {
            steps {
                sh "mvn package -Pdocker"
            }
        }
             stage('Run docker app') {
            steps {
                sh "docker run -d -p 0.0.0.0:8080:8080 --name ${container_name} ${IMAGE}:${VERSION}"
            }
        }
        stage('Selenium tests') {
            steps {
               
                sh "mvn test -Pselenium"

               
            }
        }
        stage('Run terraform'){
            steps {
                dir('infrastructure/terraform') {
                    sh 'terraform init && terraform apply -auto-approve'
                }
            }
        }
        stage('Copy Ansible role') {
            steps {
                sh 'cp -r infrastructure/ansible/panda/ /etc/ansible/roles'
            }
        }
        stage('Run Ansible') {
            steps {
                dir('infrastructure/ansible') {
                    sh 'chmod 600 ../panda-key.pem'
                    sh 'ansible-playbook -i ./inventory playbook.yml'
                }
            }
        }
        stage('Deploy to Artifactory') {
            steps {
               
             configFileProvider([configFile(fileId: '9d1ed313-ea70-4fa9-9934-7108c53eca75', variable: 'mvnSettings')]) {
                 sh "mvn -s $mvnSettings deploy"
                }

               
            }
        }
    }
    post {
        always {
            sh "docker stop ${container_name}"
            deleteDir()
        }
    }
}