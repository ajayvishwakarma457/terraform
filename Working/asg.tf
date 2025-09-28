resource "aws_launch_template" "app" {
  name_prefix   = "${var.project}-${var.environment}-app-"
  image_id      = "ami-02d26659fd82cf299" # Ubuntu 22.04 LTS (check latest for your region)
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project}-${var.environment}-app"
    }
  }
}


resource "aws_autoscaling_group" "app" {
  name                      = "${var.project}-${var.environment}-asg"
  desired_capacity          = 2
  max_size                  = 4
  min_size                  = 2
  vpc_zone_identifier       = aws_subnet.private[*].id
  health_check_type         = "EC2"
  force_delete              = true

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app.arn]

  tag {
    key                 = "Name"
    value               = "${var.project}-${var.environment}-app"
    propagate_at_launch = true
  }
}


resource "aws_autoscaling_policy" "cpu_scale_up" {
  name                   = "${var.project}-${var.environment}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "cpu_scale_down" {
  name                   = "${var.project}-${var.environment}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}
