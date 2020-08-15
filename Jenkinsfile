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
		script {
		    try {
			sh 'ls -al'
                        sh 'printenv'
		        sh 'pwd'	       
		        sh 'vagrant up'
                    } catch(Exception e) {		    
   	                sh './cleanup.sh'
			error '問題発生したので異常終了'
	            }
                    finally {
          	         echo '成功時も失敗時も実行されます'
	            }
	        }
	    }
        }
        stage('クラスタ状態チェック') {
            steps {
                sh 'vagrant status'
            }
        }
        stage('k8sクラスタ TEST-1') {
            steps {
                sh 'kubectl cluster-info --kubeconfig kubeconfig'	    
                sh 'kubectl get node -o wide --kubeconfig kubeconfig'
		sh 'kubectl get namespace -o wide --kubeconfig kubeconfig'
		sh 'kubectl get pod --all-namespaces -o wide --kubeconfig kubeconfig'		
            }
        }
        stage('k8sクラスタ TEST-2') {
            steps {
                sh 'sleep 300'	    	    
		sh 'kubectl get pod --all-namespaces -o wide --kubeconfig kubeconfig'
		sh 'kubectl describe pod --all-namespaces --kubeconfig kubeconfig'		
            }
        }
	
        stage('クリーンナップ') {
            steps {
                sh './cleanup.sh'
            }
        }
    }
}

