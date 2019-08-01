resource "aws_alb" "group1_alb" {
    name            = "group1-alb"
    internal        = false
    security_groups = ["${aws_default_security_group.dev_default.id}", "${aws_security_group.bastion.id}"]
  
    subnets         = [
        "${aws_subnet.subnet_1a.id}",
        "${aws_subnet.subnet_1c.id}"
    ]
    
    tags = {
        Name = "group1_alb"
    }
    
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_alb_target_group" "group1_alb_target" {
    name        = "group1-alb-target"
    port        = 80
    protocol    = "HTTP"
    vpc_id      = "${aws_vpc.dev.id}"
    tags = {
        Name = "group1_alb_target"
    }
}


resource "aws_autoscaling_attachment" "alb_autoscale" {
  alb_target_group_arn   = "${aws_alb_target_group.group1_alb_target.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.bastion_asg.id}"
}