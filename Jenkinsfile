pipeline {
    agent any

    triggers {
        cron('H 0,3,6,9,12,15,18,21 * * *')
    }

    options {
        skipDefaultCheckout(true)
    }

    environment {
        BACKEND_ENV = credentials('Env-NG-Backend')
        TESTING_ENV = credentials('Env-NG-Testing')
        // Store repository information
        BACKEND_BRANCH = 'dev'
        TESTING_BRANCH = 'dev'
        BACKEND_REPO = 'embetter/NG-001-Backend'
        TESTING_REPO = 'embetter/NG-Testing'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout') {
            steps {
                script {
                    def checkoutDetails = [:]
                    parallel(
                        'Backend Repo': {
                            dir('ng-001-backend') {
                                checkout([$class: 'GitSCM',
                                    branches: [[name: "*/${env.BACKEND_BRANCH}"]],
                                    userRemoteConfigs: [[
                                        url: "git@github.com:${env.BACKEND_REPO}.git",
                                        credentialsId: 'NG-Backend'
                                    ]]
                                ])
                                // Capture git details
                                env.BACKEND_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                                env.BACKEND_TAG = sh(script: 'git describe --tags || echo "no-tags"', returnStdout: true).trim()
                            }
                        },
                        'Testing Repo': {
                            dir('ng-testing') {
                                checkout([$class: 'GitSCM',
                                    branches: [[name: "*/${env.TESTING_BRANCH}"]],
                                    userRemoteConfigs: [[
                                        url: "git@github.com:${env.TESTING_REPO}.git",
                                        credentialsId: 'NG-Testing'
                                    ]]
                                ])
                                // Capture git details
                                env.TESTING_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                                env.TESTING_TAG = sh(script: 'git describe --tags || echo "no-tags"', returnStdout: true).trim()
                            }
                        }
                    )
                }
            }
        }

        stage('Setup Backend') {
            steps {
                script {
                    dir('ng-001-backend') {
                        withCredentials([file(credentialsId: 'Env-NG-Backend', variable: 'ENV_FILE')]) {
                            sh 'cp "$ENV_FILE" .env'
                        }
                        sh 'make purge || true && make restart'
                        sh '''
                            docker ps | grep -q netgala-api || (echo "Backend API not running" && exit 1)
                            docker ps | grep -q netgala-db || (echo "Database container not running" && exit 1)
                        '''
                    }
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    dir('ng-testing') {
                        withCredentials([file(credentialsId: 'Env-NG-Testing', variable: 'ENV_FILE')]) {
                            sh 'cp "$ENV_FILE" .env'
                        }
                        sh 'mkdir -p test-results'
                        sh '''#!/bin/bash
                            make docker-test-api 2>&1 | tee test-results/stdout.txt
                            exit ${PIPESTATUS[0]}
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                dir('ng-001-backend') { sh 'make purge || true' }
                dir('ng-testing') { sh 'make purge || true' }
                archiveArtifacts artifacts: '**/test-results/**/*', allowEmptyArchive: true

                // Get trigger cause
                def causes = currentBuild.getBuildCauses()
                def triggerCause = causes.find { cause -> cause.shortDescription }?.shortDescription ?: 'Manual trigger'

                // Email configuration with improved formatting and git information
                emailext(
                    // to: 'shivam@embetter.in, gsingh@embetter.in, mithesh@embetter.in',
                    to: 'shivam@embetter.in',
                    subject: "[${currentBuild.result}] ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                    body: """
                        <!DOCTYPE html>
                        <html>
                        <head>
                            <style>
                                body { font-family: Arial, sans-serif; }
                                .header { background-color: #f8f9fa; padding: 20px; margin-bottom: 20px; }
                                .section { margin-bottom: 20px; }
                                .details { margin-left: 20px; }
                                table { border-collapse: collapse; width: 100%; }
                                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                                th { background-color: #f8f9fa; }
                                .status-success { color: green; }
                                .status-failure { color: red; }
                                .status-unstable { color: orange; }
                            </style>
                        </head>
                        <body>
                            <div class="header">
                                <h2>Build Status: <span class="status-${currentBuild.result.toLowerCase()}">${currentBuild.result}</span></h2>
                            </div>

                            <div class="section">
                                <h3>Build Information</h3>
                                <div class="details">
                                    <table>
                                        <tr><th>Job Name</th><td>${env.JOB_NAME}</td></tr>
                                        <tr><th>Build Number</th><td>${env.BUILD_NUMBER}</td></tr>
                                        <tr><th>Trigger</th><td>${triggerCause}</td></tr>
                                        <tr><th>Build URL</th><td><a href="${env.BUILD_URL}">${env.BUILD_URL}</a></td></tr>
                                        <tr><th>Console Output</th><td><a href="${env.BUILD_URL}console">${env.BUILD_URL}console</a></td></tr>
                                    </table>
                                </div>
                            </div>

                            <div class="section">
                                <h3>Repository Information</h3>
                                <div class="details">
                                    <h4>Backend Repository (${env.BACKEND_REPO})</h4>
                                    <table>
                                        <tr><th>Branch</th><td>${env.BACKEND_BRANCH}</td></tr>
                                        <tr><th>Commit</th><td>${env.BACKEND_COMMIT}</td></tr>
                                        <tr><th>Tag</th><td>${env.BACKEND_TAG}</td></tr>
                                        <tr><th>GitHub URL</th><td><a href="https://github.com/${env.BACKEND_REPO}/commit/${env.BACKEND_COMMIT}">View Commit</a></td></tr>
                                    </table>

                                    <h4>Testing Repository (${env.TESTING_REPO})</h4>
                                    <table>
                                        <tr><th>Branch</th><td>${env.TESTING_BRANCH}</td></tr>
                                        <tr><th>Commit</th><td>${env.TESTING_COMMIT}</td></tr>
                                        <tr><th>Tag</th><td>${env.TESTING_TAG}</td></tr>
                                        <tr><th>GitHub URL</th><td><a href="https://github.com/${env.TESTING_REPO}/commit/${env.TESTING_COMMIT}">View Commit</a></td></tr>
                                    </table>
                                </div>
                            </div>

                            <div class="section">
                                <p>Please check the attached test output file (stdout.txt) for detailed test results.</p>
                            </div>
                        </body>
                        </html>
                    """,
                    from: 'ng-jenkins@embetter.in',
                    attachmentsPattern: '**/test-results/stdout.txt',
                    attachLog: false,
                    mimeType: 'text/html'
                )
            }
        }
        failure { echo 'Pipeline failed. Check logs for details.' }
        unstable { echo 'Pipeline unstable. Tests or notifications may have failed.' }
    }
}
