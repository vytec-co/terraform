resource "aws_instance" "jenkins_master" {
    # Use an Ubuntu image in eu-west-1
    ami = "ami-f95ef58a"

    instance_type = "t2.small"

    tags {
        Name = "jenkins-master"
    }

    # We're assuming the subnet and security group have been defined earlier on

    subnet_id = "${aws_subnet.jenkins.id}"
    security_group_ids = ["${aws_security_group.jenkins_master.id}"]
    associate_public_ip_address = true

    # We're assuming there's a key with this name already
    key_name = "deployer-key"

    # This is where we configure the instance with ansible-playbook
    provisioner "local-exec" {
        command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ./deployer.pem -i '${aws_instance.jenkins_master.public_ip},' master.yml"
    }
}


---
master.yml

- hosts: all
  become: true

  tasks:
    - name: ensure the jenkins apt repository key is installed
      apt_key: url=https://pkg.jenkins.io/debian-stable/jenkins.io.key state=present

    - name: ensure the repository is configured
      apt_repository: repo='deb https://pkg.jenkins.io/debian-stable binary/' state=present

    - name: ensure jenkins is installed
      apt: name=jenkins update_cache=yes

    - name: ensure jenkins is running
      service: name=jenkins state=started
