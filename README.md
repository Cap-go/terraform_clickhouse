# How to start the project

## Create your env file

```bash
cp terraform.tfvars.example terraform.tfvars
```

Then fill the `terraform.tfvars` file with your values


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
touch clickhouse.env && touch clickhouse.sql
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


## Fail2ban
Fail2ban has been setup to ban abusive IP addresses after 3 failed attempts to connect to the ClickHouse database server.

Most of the settings are constrained to just 2 files: `fail2ban-jail.local` and `fail2ban-clickhouse.conf`.

### `fail2ban-jail.local`
The ban blocks access to ALL ports on the server for 24hrs (86,400 seconds hence `bantime = 86400`). 

If you want to relax the ban rule to only block access to specific ClickHouse ports i.e. `8123,9000,9440`, then change `banaction = iptables-allports` to `banaction = iptables-multiport`.

### `fail2ban-clickhouse.conf`
The settings inside this file roughly approximate the 2 ways by which a malicious user may try to connect to the ClickHouse server.

Either scenario will lead to a ban after 3 attempts:
- use of a non-existent user and incorrect/empty password;
- use of a valid DB user like `default` but with an incorrect/empty password;

The next section will show examples of banning for both types of attempts.


## Testing bans
First SSH into the server for the ClickHouse database:
```bash
ssh ubuntu@clickhouse.example.com
```

List the jails that have been enabled by `fail2ban` using the `fail2ban-client`:
```bash
sudo fail2ban-client status

Status
|- Number of jail:	2
`- Jail list:	clickhouse, sshd
```

On a freshly setup server the ban list should be empty. Using the `fail2ban-client`, you can review the ban list for the `clickhouse` jail:
```bash
sudo fail2ban-client status clickhouse

Status for the jail: clickhouse
|- Filter
|  |- Currently failed:	0
|  |- Total failed:	0
|  `- File list:	/data/clickhouse-master-logs/clickhouse-server.log
`- Actions
   |- Currently banned:	0
   |- Total banned:	0
   `- Banned IP list:	
```

Now open a watch on the `fail2ban` log file for the two malicious attempts we are going to try next:
```bash
sudo tail -f /var/log/fail2ban.log
2024-02-09 08:08:11,228 fail2ban.jail           [19480]: INFO    Creating new jail 'clickhouse'
2024-02-09 08:08:11,228 fail2ban.jail           [19480]: INFO    Jail 'clickhouse' uses pyinotify {}
2024-02-09 08:08:11,230 fail2ban.jail           [19480]: INFO    Initiated 'pyinotify' backend
2024-02-09 08:08:11,232 fail2ban.filter         [19480]: INFO      maxRetry: 3
2024-02-09 08:08:11,232 fail2ban.filter         [19480]: INFO      findtime: 600
2024-02-09 08:08:11,232 fail2ban.actions        [19480]: INFO      banTime: 86400
2024-02-09 08:08:11,232 fail2ban.filter         [19480]: INFO      encoding: UTF-8
2024-02-09 08:08:11,233 fail2ban.filter         [19480]: INFO    Added logfile: '/data/clickhouse-master-logs/clickhouse-server.log' (pos = 181975635, hash = f6601fc4bfaf934f244c521adc24228909626b94)
2024-02-09 08:08:11,236 fail2ban.jail           [19480]: INFO    Jail 'sshd' started
2024-02-09 08:08:11,237 fail2ban.jail           [19480]: INFO    Jail 'clickhouse' started
```

### First fail2ban test
On your machine, please download the CLI client for ClickHouse:
```bash
cd /tmp && curl https://clickhouse.com/ | sh
```

Attempt to login on port `9000` as a non-existent user "test" with an invalid password "wrong-password":
```bash
# 1st try
./clickhouse client --host clickhouse.example.com --port 9000 --user test --password wrong-password
ClickHouse client version 24.2.1.469 (official build).
Connecting to clickhouse.example.com:9000 as user test.
Code: 516. DB::Exception: Received from clickhouse.example.com:9000. DB::Exception: test: Authentication failed: password is incorrect, or there is no user with such name.. (AUTHENTICATION_FAILED)

# 2nd try
./clickhouse client --host clickhouse.example.com --port 9000 --user test --password wrong-password
ClickHouse client version 24.2.1.469 (official build).
Connecting to clickhouse.example.com:9000 as user test.
Code: 516. DB::Exception: Received from clickhouse.example.com:9000. DB::Exception: test: Authentication failed: password is incorrect, or there is no user with such name.. (AUTHENTICATION_FAILED)

# 3rd try
./clickhouse client --host clickhouse.example.com --port 9000 --user test --password wrong-password
ClickHouse client version 24.2.1.469 (official build).
Connecting to clickhouse.example.com:9000 as user test.
Code: 516. DB::Exception: Received from clickhouse.example.com:9000. DB::Exception: test: Authentication failed: password is incorrect, or there is no user with such name.. (AUTHENTICATION_FAILED)

# 4th try
./clickhouse client --host clickhouse.example.com --port 9000 --user test --password wrong-password
ClickHouse client version 24.2.1.469 (official build).
Connecting to clickhouse.example.com:9000 as user test.
Code: 210. DB::NetException: Connection refused (clickhouse.example.com:9000). (NETWORK_ERROR)
```
As you can see, by the 4th try, the error message changed from `Authentication failed` to `Connection refused`. Your IP was automatically blocked with an `iptables` firewall rule by `fail2ban` after 3 failed attempts.


If you review the `fail2ban` log on the ClickHouse server, you'll see a notice about your IP that has just been banned:
```bash
sudo tail -f /var/log/fail2ban.log
...
2024-02-09 08:08:11,236 fail2ban.jail           [19480]: INFO    Jail 'sshd' started
2024-02-09 08:08:11,237 fail2ban.jail           [19480]: INFO    Jail 'clickhouse' started
2024-02-09 08:15:40,716 fail2ban.filter         [19559]: INFO    [clickhouse] Found 18.132.xx.xx - 2024-02-09 08:15:40
2024-02-09 08:15:45,414 fail2ban.filter         [19559]: INFO    [clickhouse] Found 18.132.xx.xx - 2024-02-09 08:15:45
2024-02-09 08:15:47,364 fail2ban.filter         [19559]: INFO    [clickhouse] Found 18.132.xx.xx - 2024-02-09 08:15:47
2024-02-09 08:15:47,793 fail2ban.actions        [19559]: NOTICE  [clickhouse] Ban 18.132.xx.xx   <<=== here ===
```

You can review the `iptables` rules that were updated to block your IP:
```bash
sudo iptables -S
-P INPUT ACCEPT
-P FORWARD DROP
-P OUTPUT ACCEPT
-N DOCKER
-N DOCKER-ISOLATION-STAGE-1
-N DOCKER-ISOLATION-STAGE-2
-N DOCKER-USER
-N f2b-clickhouse
-A FORWARD -j DOCKER-USER
-A FORWARD -j DOCKER-ISOLATION-STAGE-1
-A FORWARD -o br-dfe4bb4976f4 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -o br-dfe4bb4976f4 -j DOCKER
-A FORWARD -i br-dfe4bb4976f4 ! -o br-dfe4bb4976f4 -j ACCEPT
-A FORWARD -i br-dfe4bb4976f4 -o br-dfe4bb4976f4 -j ACCEPT
-A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -o docker0 -j DOCKER
-A FORWARD -i docker0 ! -o docker0 -j ACCEPT
-A FORWARD -i docker0 -o docker0 -j ACCEPT
-A DOCKER -d 172.22.0.2/32 ! -i br-dfe4bb4976f4 -o br-dfe4bb4976f4 -p tcp -m tcp --dport 443 -j ACCEPT
-A DOCKER -d 172.22.0.2/32 ! -i br-dfe4bb4976f4 -o br-dfe4bb4976f4 -p tcp -m tcp --dport 80 -j ACCEPT
-A DOCKER -d 172.22.0.3/32 ! -i br-dfe4bb4976f4 -o br-dfe4bb4976f4 -p tcp -m tcp --dport 9440 -j ACCEPT
-A DOCKER -d 172.22.0.3/32 ! -i br-dfe4bb4976f4 -o br-dfe4bb4976f4 -p tcp -m tcp --dport 9000 -j ACCEPT
-A DOCKER -d 172.22.0.3/32 ! -i br-dfe4bb4976f4 -o br-dfe4bb4976f4 -p tcp -m tcp --dport 8123 -j ACCEPT
-A DOCKER-ISOLATION-STAGE-1 -i br-dfe4bb4976f4 ! -o br-dfe4bb4976f4 -j DOCKER-ISOLATION-STAGE-2
-A DOCKER-ISOLATION-STAGE-1 -i docker0 ! -o docker0 -j DOCKER-ISOLATION-STAGE-2
-A DOCKER-ISOLATION-STAGE-1 -j RETURN
-A DOCKER-ISOLATION-STAGE-2 -o br-dfe4bb4976f4 -j DROP
-A DOCKER-ISOLATION-STAGE-2 -o docker0 -j DROP
-A DOCKER-ISOLATION-STAGE-2 -j RETURN
-A DOCKER-USER -p tcp -j f2b-clickhouse
-A DOCKER-USER -j RETURN
-A f2b-clickhouse -s 18.132.xx.xx/32 -j REJECT --reject-with icmp-port-unreachable  <<=== here ===
-A f2b-clickhouse -j RETURN
```

Instead of the `iptables` command, you can use the more convenient `fail2ban-client` command to review the IPs that have been banned:
```bash
sudo fail2ban-client status clickhouse

Status for the jail: clickhouse
|- Filter
|  |- Currently failed:	0
|  |- Total failed:	3
|  `- File list:	/data/clickhouse-master-logs/clickhouse-server.log
`- Actions
   |- Currently banned:	1
   |- Total banned:	1
   `- Banned IP list:	18.132.xx.xx
```

The `fail2ban-client` can also be used to unblock an IP address:
```bash
sudo fail2ban-client unban 18.132.xx.xx
```

### Second fail2ban test
Attempt to login on port `9000` as the default database user ("default") with an empty password:
```bash
./clickhouse client --host clickhouse.example.com --port 9000
ClickHouse client version 24.2.1.469 (official build).
Connecting to clickhouse.example.com:9000 as user default.
Password for user (default): 
Connecting to clickhouse.example.com:9000 as user default.
Code: 516. DB::Exception: Received from clickhouse.example.com:9000. DB::Exception: default: Authentication failed: password is incorrect, or there is no user with such name.

If you have installed ClickHouse and forgot password you can reset it in the configuration file.
The password for default user is typically located at /etc/clickhouse-server/users.d/default-password.xml
and deleting this file will reset the password.
See also /etc/clickhouse-server/users.xml on the server where ClickHouse is installed.

. (AUTHENTICATION_FAILED)

./clickhouse client --host clickhouse.example.com --port 9000
ClickHouse client version 24.2.1.469 (official build).
Connecting to clickhouse.example.com:9000 as user default.
Password for user (default): 
Connecting to clickhouse.example.com:9000 as user default.
Code: 210. DB::NetException: Connection refused (clickhouse.example.com:9000). (NETWORK_ERROR)
```
As before, after 3 failed attempts, on the 4th attempt the error message changed from `Authentication failed` to `Connection refused`.


Once the ban is in place, further attempts from the same IP to connect to a different port such as port 80 is also blocked:
```bash
curl clickhouse.example.com
curl: (7) Failed to connect to clickhouse.example.com port 80 after 77 ms: Connection refused
```

## Deployment
During testing, deployment of the ClickHouse server using `terraform apply` sometimes failed with the following error:
```bash
│ Error: Provider produced inconsistent final plan
│ 
│ When expanding the plan for null_resource.files_updates to include new values learned so far during apply, provider "registry.terraform.io/hashicorp/null" produced an invalid new value for .triggers["clickhouse_sql_hash"]: was
│ cty.StringVal("d41d8cd98f00b204e9800998ecf8427e"), but now cty.StringVal("07ef3f00cee6f9686d7bda6fc110de8f").
│ 
│ This is a bug in the provider, which should be reported in the provider's own issue tracker.
```

This is due to the [behaviour](https://github.com/hashicorp/terraform-provider-null/issues/45#issuecomment-1460885306) of the `filemd5()` function used in `main.tf` which generates the contents of two files dynamically (`clickhouse.env` and `clickhouse.sql`). As per the [`filemd5()` doc](https://developer.hashicorp.com/terraform/language/functions/file), it does not participate in the dependency graph when Terraform is generating a plan, hence the error. 

The fix is to simply re-run `terraform apply` again:
```bash
terraform apply -auto-approve
```
