from registry.redhat.io/rhel9/rhel-bootc:latest

#RUN dnf groupinstall -y "Server with GUI" "Virtualization Host"

#RUN systemctl set-default graphical.target
