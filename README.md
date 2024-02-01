# How to start the project

## Install terraform

### Linux

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" -y
sudo apt-get update && sudo apt-get install terraform -y
```

### MacOS

```bash
brew install terraform
```

## Init terraform

```bash
terraform init
```

## Create terraform plan

```bash
terraform plan
```

## Apply terraform plan

```bash
terraform apply
```

Note the host in the output

## Destroy terraform plan

```bash
terraform destroy
```

## Read clickhouse password

```bash
terraform output -json clickhouse_password 
```

# How to connect to clickhouse

Connection string: `jdbc:clickhouse://<clickhouse_host>:9000/default?password=<clickhouse_password>`
