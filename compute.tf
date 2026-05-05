# Sourcing Latest AMI image
data "aws_ami" "latest_amazon_linux_2023" {
    most_recent = true
    owners      = ["amazon"]
   
    filter {
        name   = "name"
        values = ["al2023-ami-*-x86_64"]
    }
}

# Defining Launch Template
resource "aws_launch_template" "web_server_launch_template" {
  name = "app_server_launch_template"

  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  credit_specification {
    cpu_credits = "standard"
  }
  
  ebs_optimized = true

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  image_id = data.aws_ami.latest_amazon_linux_2023.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.micro"

  monitoring {
    enabled = true
  }

  network_interfaces {
    security_groups = [aws_security_group.app_sg.id]
  }

  user_data = base64encode(<<-EOF
        #!/bin/bash
        # Version 10
        yum update -y
        yum install python3 -y
        yum install python3-pip -y
        yum install mysql-devel -y
        yum install gcc -y
        mkdir -p /var/www/api
        chmod -R 755 /var/www/api
        python3 -m venv /var/www/api/venv
        /var/www/api/venv/bin/pip install flask gunicorn boto3 pymysql requests
        aws s3 cp s3://${aws_s3_bucket.secure_bucket.id}/app/app.py /var/www/api/app.py
        cd /var/www/api
        /var/www/api/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app &
      EOF
   )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "app_server"
    }
  }
}

resource "aws_autoscaling_group" "web_server_group" {
  name                      = "web_server_group"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  vpc_zone_identifier       = aws_subnet.private_ec2[*].id
  target_group_arns         = [aws_lb_target_group.web_server_target_alb_group.arn]
  depends_on                = [aws_db_instance.default]

  launch_template {
    id      = aws_launch_template.web_server_launch_template.id
    version = "$Latest"
  }

  instance_refresh {
      strategy = "Rolling"
      triggers = ["launch_template"] 
        preferences {
          min_healthy_percentage = 50 
        }
   }

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

  tag {
    key                 = "lorem"
    value               = "ipsum"
    propagate_at_launch = true
  }
}