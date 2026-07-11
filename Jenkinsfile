pipeline {
agent { label 'my-agent' }
parameters {
    choice(
        name: 'TF_ACTION',
        choices: ['APPLY', 'DESTROY'],
        description: 'Select Terraform action'
    )
}

environment {
    AWS_DEFAULT_REGION = 'ap-southeast-2'
}

stages {

    stage('Checkout') {
        steps {
            checkout scm
        }
    }

    stage('Terraform Format Check') {
        steps {
            sh 'terraform fmt -recursive'
        }
    }

    stage('Terraform Init') {
        steps {
            sh 'terraform init'
        }
    }

    stage('Terraform Validate') {
        steps {
            sh 'terraform validate'
        }
    }

    stage('Terraform Plan') {
        when {
            expression {
                params.TF_ACTION == 'APPLY'
            }
        }
        steps {
            sh 'terraform plan -out=tfplan'
        }
    }

    stage('Terraform Apply') {
        when {
            expression {
                params.TF_ACTION == 'APPLY'
            }
        }
        steps {
            sh 'terraform apply -auto-approve tfplan'
        }
    }

    stage('Get Terraform Outputs') {
        when {
            expression {
                params.TF_ACTION == 'APPLY'
            }
        }
        steps {
            script {
                env.ECR_REPO = sh(
                    script: 'terraform output -raw ecr_repository_url',
                    returnStdout: true
                ).trim()

                echo "ECR Repository: ${env.ECR_REPO}"
            }
        }
    }

    stage('Build Docker Image') {
        when {
            expression {
                params.TF_ACTION == 'APPLY'
            }
        }
        steps {
            sh """
                docker build -t nginx-app .
                docker tag nginx-app:latest ${ECR_REPO}:latest
            """
        }
    }

    stage('Login To ECR') {
        when {
            expression {
                params.TF_ACTION == 'APPLY'
            }
        }
        steps {
            sh """
                aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
            """
        }
    }

    stage('Push Docker Image') {
        when {
            expression {
                params.TF_ACTION == 'APPLY'
            }
        }
        steps {
            sh """
                docker push ${ECR_REPO}:latest
            """
        }
    }

    stage('Wait For EC2 Boot') {
        when {
            expression {
                params.TF_ACTION == 'APPLY'
            }
        }
        steps {
            echo 'Waiting for EC2 to boot...'
            sleep(time: 60, unit: 'SECONDS')
        }
    }

    stage('Install Docker Using Ansible') {
        when {
            expression {
                params.TF_ACTION == 'APPLY'
            }
        }
        steps {
            sshagent(['agent-access']) {
                sh 'ansible-playbook -i aws_ec2.yml install_docker.yml'
            }
        }
    }

    stage('Deploy Nginx Container') {
        when {
            expression {
                params.TF_ACTION == 'APPLY'
            }
        }
        steps {
            sshagent(['agent-access']) {
                sh """
                    ansible-playbook \
                    -i aws_ec2.yml \
                    deploy_nginx.yml \
                    -e ecr_repo=${ECR_REPO} \
                    -e aws_region=${AWS_DEFAULT_REGION}
                """
            }
        }
    }

    stage('Terraform Destroy') {
        when {
            expression {
                params.TF_ACTION == 'DESTROY'
            }
        }
        steps {
            sh 'terraform destroy -auto-approve'
        }
    }
}

post {
    success {
        echo 'Pipeline completed successfully.'
    }

    failure {
        echo 'Pipeline failed.'
    }

    always {
        cleanWs()
    }
}

}
