# SchedulerEnvironmentBootstrap

Helper for setting up scheduler environment.

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
