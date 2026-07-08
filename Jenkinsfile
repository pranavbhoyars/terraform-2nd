pipeline {
    // Target your specific Jenkins agent
    agent { label 'my-agent' }
    
    parameters {
        choice(
            name: 'TF_ACTION', 
            choices: ['APPLY', 'DESTROY'], 
            description: 'Select the action to perform on the infrastructure.'
        )
    }

    environment {
        // Explicitly setting the default region since credentials aren't passed
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
                sh 'terraform fmt'
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
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Terraform Execution') {
            steps {
                script {
                    if (params.TF_ACTION == 'APPLY') {
                        echo "Executing Terraform Apply..."
                        sh 'terraform apply -auto-approve tfplan'
                    } else if (params.TF_ACTION == 'DESTROY') {
                        echo "Executing Terraform Destroy..."
                        sh 'terraform destroy -auto-approve'
                    }
                }
            }
        }

        stage('Ansible Configuration') {
            when {
                expression { params.TF_ACTION == 'APPLY' }
            }
            steps {
                // Use the private key credential required to SSH into the *new* EC2 instance
                sshagent(['my-ssh-key-id']) { 
                    echo "Waiting for the new EC2 instance to boot..."
                    sleep 30 
                    
                    echo "Running Ansible Playbook to install Java..."
                    sh 'ansible-playbook -i aws_ec2.yml install_java.yml'
                }
            }
        }
    }
}
