# Github Action 基础使用

## Github Action 是做什么的？
* Github Action 是一个基于repo的Push或Pull Request触发的事件驱动的workflow，在当前项目的.git/workflow/路径下的以 .yml 后缀的文件中定义工作流。
* 一个工作流中，可以包含有一个或多个job，每个job可以有一个或多个Step。
* Runners是运行workflow的环境，可以使用Github自带的runner(windows,ubuntu,mac, 预装了特定的软件环境)，也可以使用自己的runner环境(只要具备联网能力的机器都可以)。
* Github Action 使用的github host的runner，预装了aws cli，azure cli等各种工具，在通过Github Action做CD的时候，可以将 secrets 放在Github的 repository secret中，然后通过 ${{SECRET_NAME}} 的方式调用

有关Github Action的介绍，参考：https://docs.github.com/en/actions/learn-github-actions/introduction-to-github-actions

## 一个Github Action的示例

* 示例：获取Azure VM的list。有关在workflow中配置azure creds的方法，参考[这里](!https://github.com/Azure/login)

```
# This is a basic workflow to help you get started with Actions

name: GitHubActionDemo01

# Controls when the workflow will run
on:
  # Triggers the workflow on push or pull request events but only for the master branch
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  # This workflow contains a single job called "build"
  build:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest

    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
      # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
      - uses: actions/checkout@v2

      # Runs a single command using the runners shell
      - name: Run a one-line script
        run: echo Hello, world!

      # Runs a set of commands using the runners shell
      - name: Run a multi-line script
        run: |
          echo Add other actions to build,
          echo test, and deploy your project.
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{secrets.AZURE_CREDENTIALS}}
          environment: 'AzureCloud'
      - name: Azure CLI Script
        uses: azure/CLI@v1
        with:
          inclineScript: |
            az vm list
```

