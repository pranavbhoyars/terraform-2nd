pipeline {
agent { label 'my-agent' }


parameters {
    choice(
        name: 'TF_ACTION',
        choices: ['APPLY', 'DESTROY'],
        description: 'Select Terraform Action'
    )
}

environment {
    AWS_DEFAULT_REGION = 'ap-southeast-2'
    TF_CREATED = 'false'
}

stages {

    stage('Checkout') {
        steps {
            checkout scm
        }
    }

    stage('Terraform Init') {
        when {
            expression { params.TF_ACTION == 'APPLY' }
        }
        steps {
            sh 'terraform init'
        }
    }

    stage('Terraform Validate') {
        when {
            expression { params.TF_ACTION == 'APPLY' }
        }
        steps {
            sh 'terraform validate'
        }
    }

    stage('Terraform Plan') {
        when {
            expression { params.TF_ACTION == 'APPLY' }
        }
        steps {
            sh 'terraform plan -out=tfplan'
        }
    }

    stage('Terraform Apply') {
        when {
            expression { params.TF_ACTION == 'APPLY' }
        }
        steps {
            sh 'terraform apply -auto-approve tfplan'

            script {
                env.TF_CREATED = 'true'
            }
        }
    }

    stage('Get Terraform Outputs') {
        when {
            expression { params.TF_ACTION == 'APPLY' }
        }
        steps {
            script {

                env.EC2_IP = sh(
                    script: 'terraform output -raw ec2_global_public_ip',
                    returnStdout: true
                ).trim()

                env.ECR_REPO = sh(
                    script: 'terraform output -raw ecr_repository_url',
                    returnStdout: true
                ).trim()

                echo "EC2 IP: ${env.EC2_IP}"
                echo "ECR Repo: ${env.ECR_REPO}"
            }
        }
    }

    stage('Create Inventory') {
        when {
            expression { params.TF_ACTION == 'APPLY' }
        }
        steps {
            script {

                writeFile(
                    file: 'inventory.ini',
                    text: """[web]
```

${env.EC2_IP} ansible_user=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no'
"""
)

```
                sh '''
                    echo "===== INVENTORY ====="
                    cat inventory.ini
                '''
            }
        }
    }

   
    stage('Install Docker') {
        when {
            expression { params.TF_ACTION == 'APPLY' }
        }
        steps {
            sshagent(['agent-access']) {
                sh '''
                    ansible-playbook \
                    -i inventory.ini \
                    install_docker.yml
                '''
            }
        }
    }

    stage('Build Docker Image') {
        when {
            expression { params.TF_ACTION == 'APPLY' }
        }
        steps {
            sh """
                docker build -t nginx-app .
                docker tag nginx-app:latest ${env.ECR_REPO}:latest
            """
        }
    }

    stage('Login To ECR') {
        when {
            expression { params.TF_ACTION == 'APPLY' }
        }
        steps {
            sh """
                aws ecr get-login-password \
                --region ${AWS_DEFAULT_REGION} \
                | docker login \
                --username AWS \
                --password-stdin ${env.ECR_REPO}
            """
        }
    }

    stage('Push Image To ECR') {
        when {
            expression { params.TF_ACTION == 'APPLY' }
        }
        steps {
            sh """
                docker push ${env.ECR_REPO}:latest
            """
        }
    }

    stage('Deploy Container') {
        when {
            expression { params.TF_ACTION == 'APPLY' }
        }
        steps {
            sshagent(['agent-access']) {
                sh """
                    ansible-playbook \
                    -i inventory.ini \
                    deploy_nginx.yml \
                    -e ecr_repo=${env.ECR_REPO} \
                    -e aws_region=${AWS_DEFAULT_REGION}
                """
            }
        }
    }

    stage('Terraform Destroy') {
        when {
            expression { params.TF_ACTION == 'DESTROY' }
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
        script {
            if (params.TF_ACTION == 'APPLY') {
                echo 'Pipeline failed. Destroying infrastructure...'

                sh '''
                    terraform destroy -auto-approve || true
                '''
            }
        }
    }

    always {
        echo 'Pipeline finished.'
    }
}


}
