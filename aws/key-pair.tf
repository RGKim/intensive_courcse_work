resource "aws_key_pair" "ssh-key" {
    key_name = "group1_key"
    public_key = "${file("~/.ssh/id_rsa.pub")}"
}

