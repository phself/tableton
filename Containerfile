FROM quay.io/rh-ee-sayash/tableton/rhel9-bootc:latest

RUN dnf groupinstall -y "Server with GUI" "Virtualization Host"

RUN systemctl set-default graphical.target
