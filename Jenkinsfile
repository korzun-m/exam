pipeline {
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }

    parameters {
        booleanParam(name: 'Сonfirmation', defaultValue: false)

    }

    agent  any
        options {
                timestamps ()
            }
    stages {
        stage('Git clone') {
            steps {
                sh  'rm -rf exam'
                sh  'git clone https://github.com/korzun-m/exam.git'
            }
        }

        stage('TF Init&Plan') {
            steps {
                sh 'cd exam/Terraform ; terraform init -input=false'
                sh 'cd exam/Terraform ; terraform workspace new terraform'
                sh 'cd exam/Terraform ; terraform workspace select terraform'
                sh 'cd exam/Terraform ; terraform plan -input=false -out flag'
                sh 'cd exam/Terraform ; terraform show -no-color flag > flag.txt'
            }
        }

        stage('Apply changes to AWS?') {
           when {
               not {
                   equals expected: true, actual: params.Сonfirmation
               }
           }

            steps {
                script {
                    def plan = readFile 'exam/Terraform/flag.txt'
                    input message: "Do you want to apply the plan?",
                    parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
               }
           }
        }

        stage('TF Apply') {
            steps {
                sh "cd exam/Terraform ; terraform apply -input=false flag"
            }
        }

        stage ('Waiting for ssh connection..') {
            steps {
                sh 'cd exam/Ansible'
                sh 'ansible-playbook exam/Ansible/wait_aws_infrastructure.yml -i exam/Terraform/inventory.yaml'
            }
        }


        stage('Ansible Deploy') {

            steps {
                sh 'cd exam/Ansible'
                sh 'ansible-playbook exam/Ansible/main.yml -i exam/Terraform/inventory.yaml'
            }
        }
    }

  }
