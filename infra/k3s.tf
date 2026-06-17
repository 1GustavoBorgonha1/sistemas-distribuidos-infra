data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  mongo_manifest = templatefile("${path.module}/manifests/mongo.yaml.tpl", {
    namespace    = var.k8s_namespace
    image        = var.mongo_image
    storage_size = var.mongo_storage_size
  })

  redis_manifest = templatefile("${path.module}/manifests/redis.yaml.tpl", {
    namespace = var.k8s_namespace
    image     = var.redis_image
  })

  # Manifests da aplicação renderizados com imagem/porta e as envs (Mongo/Redis/SQS).
  app_manifest = templatefile("${path.module}/manifests/app.yaml.tpl", {
    namespace         = var.k8s_namespace
    app_name          = var.project_name
    image             = local.backend_image_ref
    replicas          = var.backend_replicas
    container_port    = var.backend_container_port
    node_port         = var.backend_node_port
    health_check_path = var.health_check_path
    aws_region        = var.aws_region
    mongo_uri         = "mongodb://mongo:27017/${var.mongo_db_name}"
    redis_url         = "redis://redis:6379"
    sqs_queue_url     = aws_sqs_queue.loan_events.url
  })
}

# --- Elastic IP do Master ---
resource "aws_eip" "k3s_master" {
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-eip-k3s-master" })
}

# --- K3s Master ---
resource "aws_instance" "k3s_master" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.master_instance_type
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.k3s.id]
  key_name               = var.ec2_key_name != "" ? var.ec2_key_name : null
  iam_instance_profile   = aws_iam_instance_profile.k3s.name

  user_data = base64encode(templatefile("${path.module}/scripts/k3s-master.sh.tpl", {
    workspace      = local.env
    region         = var.aws_region
    namespace      = var.k8s_namespace
    mongo_manifest = local.mongo_manifest
    redis_manifest = local.redis_manifest
    app_manifest   = local.app_manifest
  }))

  # JWT secret precisa existir antes do master criar o Secret do K8s.
  depends_on = [aws_ssm_parameter.jwt_secret]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # Recria o master (re-deploy) quando a imagem ou os manifests mudam.
  user_data_replace_on_change = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-k3s-master"
    Role = "master"
  })
}

resource "aws_eip_association" "k3s_master" {
  instance_id   = aws_instance.k3s_master.id
  allocation_id = aws_eip.k3s_master.id
}

# --- K3s Workers (ASG) ---
resource "aws_launch_template" "k3s_worker" {
  name_prefix   = "${local.name_prefix}-k3s-worker-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.worker_instance_type
  key_name      = var.ec2_key_name != "" ? var.ec2_key_name : null

  vpc_security_group_ids = [aws_security_group.k3s.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.k3s.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
  }

  user_data = base64encode(templatefile("${path.module}/scripts/k3s-worker.sh.tpl", {
    workspace         = local.env
    region            = var.aws_region
    master_private_ip = aws_instance.k3s_master.private_ip
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-k3s-worker"
      Role = "worker"
    })
  }
}

resource "aws_autoscaling_group" "k3s_workers" {
  name                = "${local.name_prefix}-k3s-workers"
  desired_capacity    = var.worker_count
  min_size            = var.worker_min_count
  max_size            = var.worker_max_count
  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  target_group_arns = [aws_lb_target_group.backend.arn]

  launch_template {
    id      = aws_launch_template.k3s_worker.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences { min_healthy_percentage = 50 }
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-k3s-worker"
    propagate_at_launch = true
  }
}
