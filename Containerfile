FROM registry.redhat.io/rhel9/rhel-bootc:latest

# --- Install Packages ---
RUN dnf -y groupinstall "Server with GUI" "Virtualization Host" && \
    dnf -y install virt-install \
                   virt-viewer \
                   libvirt-client \
                   libvirt \
                   qemu-img \
                   qemu-kvm \
                   dconf \
                   gnome-shell-extension-desktop-icons && \
    dnf clean all
RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    dnf -y install 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled codeready-builder-for-rhel-9-x86_64-rpms && \
    dnf -y install wine && \
    dnf clean all


RUN systemctl enable virtqemud.socket libvirtd
RUN systemctl set-default graphical.target


# --- Windows VM Setup ---
COPY windows_server_2012_r2.qcow2 /var/lib/libvirt/images/windows_server_2012_r2.qcow2
RUN chown qemu:qemu /var/lib/libvirt/images/windows_server_2012_r2.qcow2 && \
    chmod 644 /var/lib/libvirt/images/windows_server_2012_r2.qcow2
    
COPY setup-windows-vm.sh /usr/local/bin/setup-windows-vm.sh
RUN chmod +x /usr/local/bin/setup-windows-vm.sh
COPY setup-windows-vm.service /etc/systemd/system/setup-windows-vm.service

RUN systemctl enable setup-windows-vm.service

RUN mkdir -p /root/Desktop
COPY files/Windows-VM.sh /root/Desktop/Windows-VM.sh
RUN chmod +x /root/Desktop/Windows-VM.sh

# --- Unlock Root Login ---
RUN sed -i 's/^auth.*pam_succeed_if.so.*user != root.*/#&/' /etc/pam.d/gdm-password

# --- Custom UI Settings (Background, Keyboard, Icons) ---

# A. Copy Background Image
RUN mkdir -p /usr/share/backgrounds/custom
COPY files/background.png /usr/share/backgrounds/custom/background.png

# B. Prepare dconf directories
RUN mkdir -p /etc/dconf/profile /etc/dconf/db/gdm.d /etc/dconf/db/local.d

# C. Define Profiles
#    This tells GDM to look at the 'gdm' db, and users to look at 'user' db
RUN echo -e "user-db:user\nsystem-db:gdm\nfile-db:/usr/share/gdm/greeter-dconf-defaults" > /etc/dconf/profile/gdm

# D. Login Screen Settings (The 'gdm' Database)
#    - Enable On-Screen Keyboard
RUN echo -e "\
[org/gnome/desktop/a11y/applications]\n\
screen-keyboard-enabled=true\n\
" > /etc/dconf/db/gdm.d/01-login-screen

# E. User Session Settings (The 'local' Database)
#    - Enable On-Screen Keyboard
#    - Enable Desktop Icons (Your specific UUID)
#    - Set Background Image
RUN echo -e "\
[org/gnome/desktop/a11y/applications]\n\
screen-keyboard-enabled=true\n\
\n\
[org/gnome/shell]\n\
enabled-extensions=['desktop-icons@gnome-shell-extensions.gcampax.github.com']\n\
\n\
[org/gnome/desktop/background]\n\
picture-uri='file:///usr/share/backgrounds/custom/background.png'\n\
picture-uri-dark='file:///usr/share/backgrounds/custom/background.png'\n\
" > /etc/dconf/db/local.d/01-user-settings

# F. Apply Settings
RUN dconf update

# ------ Perform checks on the final image. should always be the last line. ------
RUN bootc container lint
