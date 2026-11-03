// Agent harness checks for Jenkins (declarative pipeline, multibranch job with
// pull request discovery).
//
// Copy the "parameters" block and the "Agent harness" stage into your Jenkinsfile.
// The checks need git history: in the branch source settings, turn off shallow
// clone, and discover pull requests by merging with the target branch so the
// target branch is fetched too.
//
// Approving an intended test change: re-run the pull request build with
// "Build with Parameters" and tick ALLOW_TEST_CHANGES.
pipeline {
  agent any

  parameters {
    booleanParam(name: 'ALLOW_TEST_CHANGES', defaultValue: false,
                 description: 'Reviewer approved deleting, skipping or weakening tests in this pull request')
  }

  stages {
    stage('Agent harness') {
      when { changeRequest() }
      steps {
        sh 'bash .harness/build-agents-md.sh --check'
        sh "ALLOW_TEST_CHANGES=${params.ALLOW_TEST_CHANGES} bash .harness/checks/protected-tests.sh"
      }
    }
  }
}
