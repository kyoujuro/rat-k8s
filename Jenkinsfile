pipeline  {
    agent {
        node {
            label('hibiki')
        }
    }
    environment {
        work_dir='/home/tkr/work'
    }    
    stages {
        stage('Clone sources') {
            steps {
	         git url: 'https://github.com/takara9/rat-k8s',
                     branch: 'master',
                     credentialsId: 'github-takara9'
            }
        }
        stage('cluster config') {
            steps {
                  sh 'ls -al'
                  sh './setup.rb -f cluster-config/minimal.yaml'
	    }
        }
        stage('クラスタ起動') {
            steps {
                   sh 'ls -al'
		   sh 'printenv'
                   sh 'pwd'	       
                   sh 'vagrant up'
                   sh './cleanup.sh'
           }
        }
        stage('クラスタ状態') {
            steps {
                sh 'vagrant status'
            }
        }
        stage('クリーンナップ') {
            steps {
                sh './cleanup.sh'
            }
        }
    }
}

