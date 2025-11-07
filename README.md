## TF deployment of reverse proxying a hosted api
```
├── app-files
│   └── web-app
│       └── app.py
├── backend.tf
├── main.tf
├── modules
│   ├── compute
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── load_balancing
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
└── variables.tf
```
<img width="818" height="535" alt="image" src="https://github.com/user-attachments/assets/29c9756b-fef4-4313-a21c-625e02ee5e1e" />

### For backend of tfstate
```
aws s3api create-bucket --bucket <your-unique-bucket-name> --region <your-region>
```
then refer in backend block

### Flow and using workspace
```
terraform init

terraform workspace new dev

terraform workspace show

terraform plan

terraform apply

terraform destroy
```
<img width="472" height="104" alt="image" src="https://github.com/user-attachments/assets/3ef370c3-72ed-45af-9c29-873207546cd6" />


### proxy config
```
server {
    listen 80;
    server_name _;
    resolver 10.0.0.2 valid=30s;
    set $backend_server "http://${var.internal_alb_dns}";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    location / {
        proxy_pass $backend_server;
    }
}
```

### Screenshots
<img width="714" height="311" alt="image" src="https://github.com/user-attachments/assets/5bc03bfa-0714-44c4-86c5-d6c7703b90e1" />
<img width="932" height="302" alt="image" src="https://github.com/user-attachments/assets/8d7a289f-d732-4acf-8e40-f6107c9ce156" />
