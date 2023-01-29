pipeline {
    agent { docker { image "puchuu/test-compression_x86_64-pc-linux-gnu:latest" } }
    stages {
        stage("ci_test") {
            steps {
                sh "scripts/test-images/ci_test.sh"
            }
        }
    }
}
