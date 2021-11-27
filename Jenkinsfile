pipeline {
    agent {
  label 'dockerslave'
}

    environment {
        IMAGE = readMavenPom().getArtifactId()
        VERSION = readMavenPom().getVersion()
        ANSIBLE = tool name: 'Ansible', type: 'com.cloudbees.jenkins.plugins.customtools.CustomTool'
    }
    tools {
  maven 'M3'
  terraform 'Terraform'
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
                
                sh "mvn clean install"

                
                sh "mvn -Dmaven.test.failure.ignore=true clean package"

                
            }
        }
         stage('Build docker image') {
            steps {
                sh "mvn package -Pdocker -Dmaven.test.skip=true"
            }
        }
             stage('Run docker app') {
            steps {
                sh "docker run -d -p 0.0.0.0:8080:8080 --name ${container_name} ${IMAGE}:${VERSION}"
            }
        }
      /*  stage('Selenium tests') {
            steps {
               
                sh "mvn test -Pselenium"

               
            }
        }*/
        stage('Run terraform'){
            steps {
                dir('infrastructure/terraform') {
                    withCredentials([file(credentialsId: 'panda-key', variable: 'pandakey')]) {
                        sh "cp \$pandakey ../panda-key.pem"
                        }
                     withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                        sh 'terraform init && terraform apply -auto-approve -var-file panda.tfvars'
                     }
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
                    sh 'ansible-playbook -i ./inventory playbook.yml -e ansible_python_interpreter=/usr/bin/python3'
                }
            }
        }
        stage('Deploy to Artifactory') {
            steps {
               
             configFileProvider([configFile(fileId: '9d1ed313-ea70-4fa9-9934-7108c53eca75', variable: 'mvnSettings')]) {
                 sh "mvn -s $mvnSettings deploy -Dmaven.test.skip=true -e"
                }        
            }
        }
        stage('Remove environment') {
            steps {
                input 'Remove environment'
                dir('infrastructure/terraform') { 
                     withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh 'terraform destroy -auto-approve -var-file panda.tfvars'
                     }
                }
            }
        }
    }
    post {
        always {
            sh "docker stop ${container_name}"
          //  deleteDir()
        }
    }
}
