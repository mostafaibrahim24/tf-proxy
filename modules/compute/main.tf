resource "aws_security_group" "proxy_sg" {
  vpc_id = var.vpc_id
  ingress { 
            from_port = 22
            to_port = 22
            protocol = "tcp"
            cidr_blocks = var.ingress_cidrs
          }
  ingress { 
            from_port = 80
            to_port = 80
            protocol = "tcp"
            security_groups = [var.public_alb_sg_id]
          }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "Proxy-SG" }
}

resource "aws_security_group" "backend_sg" {
  vpc_id = var.vpc_id
  ingress { 
            from_port = 22
            to_port = 22
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress { 
            from_port = 5000
            to_port = 5000
            protocol = "tcp"
            security_groups = [var.internal_alb_sg_id] 
            }
  egress { 
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
            }
  tags = { Name = "Backend-SG" }
}

resource "aws_instance" "proxy" {
  count                       = length(var.public_subnets)
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnets[count.index]
  vpc_security_group_ids      = [aws_security_group.proxy_sg.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              # Nginx install is handled by remote-exec, but ensure basic setup is fine
              echo "Starting EC2 setup"
              EOF

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep $((RANDOM % 30))",

      "export DEBIAN_FRONTEND=noninteractive",
      "sudo systemctl stop apt-daily.service apt-daily.timer || true",
      "sudo pkill -f apt || true",

      "until sudo apt-get update -o Acquire::ForceIPv4=true -y; do echo 'Waiting for apt lock or network...' && sleep 5; done",
      "until sudo apt-get install -y -o Acquire::ForceIPv4=true --fix-missing nginx; do echo 'Waiting for apt lock or network...' && sleep 5; done",

      "sudo mkdir -p /etc/nginx/conf.d",
      "sudo systemctl stop nginx || true",

      "sudo sh -c 'cat <<EOF > /etc/nginx/conf.d/proxy.conf",
      "server {",
      "    listen 80;",
      "    server_name _;",
      "    resolver 10.0.0.2 valid=30s;",
      "    set \\$backend_server \"http://${var.internal_alb_dns}\";",
      "    proxy_set_header Host \\$host;",
      "    proxy_set_header X-Real-IP \\$remote_addr;",
      "    proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;",
      "    proxy_set_header X-Forwarded-Proto \\$scheme;",
      "    location / {",
      "        proxy_pass \\$backend_server;",
      "    }",
      "}",
      "EOF'",

      "sudo rm -f /etc/nginx/nginx.conf || true",
      "sudo systemctl enable --now nginx || sudo systemctl start nginx || true",
      "echo 'Nginx configured and started, proxying to ${var.internal_alb_dns}'"
    ]
  }

  provisioner "local-exec" {
    command = "echo \"public-ip-${count.index + 1} ${self.public_ip}\" >> all-ips.txt"
  }

  tags = { Name = "Nginx-Proxy-${count.index + 1}" }
}

resource "aws_instance" "backend" {
  count                       = length(var.private_subnets)
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = var.private_subnets[count.index]
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = false # Private instance

  connection {
    type        = "ssh"
    user        = "ubuntu"                 
    private_key = file(var.private_key_path)
    host        = self.private_ip
    bastion_host        = aws_instance.proxy[0].public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = file(var.private_key_path)
    timeout     = "10m"
  }

  provisioner "file" {
    source      = "./app-files/web-app/app.py"
    destination = "/home/ubuntu/app.py"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep $((RANDOM % 30))",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo systemctl stop apt-daily.service apt-daily.timer || true",
      "sudo pkill -f apt || true",
      "until sudo apt-get update -o Acquire::ForceIPv4=true -y; do echo 'Waiting for apt lock or network...' && sleep 5; done",
      "sudo apt-get install -y -o Acquire::ForceIPv4=true python3 python3-pip --fix-missing",
      "mkdir -p /home/ubuntu/app",
      "sudo mv /home/ubuntu/app.py /home/ubuntu/app/app.py || echo 'Failed to move app.py!'",
      "pip3 install --user flask || sudo pip3 install flask",
      "nohup python3 /home/ubuntu/app/app.py > /dev/null 2>&1 &",
    ]
  }

  provisioner "local-exec" {
    command = "echo \"private-ip-${count.index + 1} ${self.private_ip}\" >> all-ips.txt"
  }

  tags = { Name = "Flask-Backend-${count.index + 1}" }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

