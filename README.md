# SchedulerEnvironmentBootstrap

Helper for setting up environment. This system uses vagrant to automate provisioning multiple local VMs. This cluster is responsible for interacting with networked hardware in a fault tolerant manner. Kubernetes is used as the orchestrator and various pieces of infrastructure inclusing messaging(RabbitMQ), observability(Prometheus), and distrubuted persistence(CockroachDB) are provisioned on that cluster.

## Installation

Clone the repo
```
git clone git@github.com:stephen-mehi/SchedulerEnvironmentBootstrap.git
```

## Usage

### Setup Vagrant
* MacOS
    ```
    cd SchedulerEnvironmentBootstrap
    sh VagrantInstallHomebrew.sh
    ```
* Linux
    ```
    cd SchedulerEnvironmentBootstrap
    sh VagrantInstall.sh
    ```
* Microsoft Windows
    ```
    cd SchedulerEnvironmentBootstrap
    VagrantInstall.bat
    ```
### Running Vagrant
#### For Local Environment Testing Setup
```
cd SchedulerEnvironmentBootstrap/Tools/TestEnv
vagrant up
```

#### For Scheduler Setup
* Setup Controller
    ```
    cd SchedulerEnvironmentBoostrap/Controller
    vagrant up
    ```
* Setup Node
    ```
    cd SchedulerEnvironmentBoostrap/Node
    vagrant up
    ```
