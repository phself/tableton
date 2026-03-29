FROM registry.redhat.io/rhel9/rhel-bootc:latest

# --- Install Packages ---
# 1. Install the core GUI base
RUN dnf -y groupinstall "Server with GUI" && dnf clean all

# 2. Install the Virtualization components
RUN dnf -y groupinstall "Virtualization Host" && dnf clean all

# 3. Install the specific tools
RUN dnf -y install \
    virt-install \
    virt-viewer \
    virt-manager \
    libvirt-client \
    libvirt \
    qemu-img \
    qemu-kvm \
    dconf \
    e2fsprogs \
    gnome-shell-extension-desktop-icons && \
    dnf clean all

RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    dnf -y install 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled codeready-builder-for-rhel-9-x86_64-rpms && \
    dnf -y install wine && \
    dnf clean all


RUN systemctl enable virtqemud.socket libvirtd libvirtd.socket
RUN systemctl set-default graphical.target

# --- Install Google Chrome ---
RUN printf "[google-chrome]\n\
name=google-chrome\n\
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://dl.google.com/linux/linux_signing_key.pub" > /etc/yum.repos.d/google-chrome.repo && \
    dnf -y install google-chrome-stable && \
    dnf clean all

# Patch Chrome to allow root login and suppress warnings
RUN sed -i 's|Exec=/usr/bin/google-chrome-stable %U|Exec=/usr/bin/google-chrome-stable %U --no-sandbox --test-type|g' /usr/share/applications/google-chrome.desktop

# ---  Desktop Icons (Root + Global Skeleton) ---
RUN mkdir -p /root/Desktop /etc/skel/Desktop

# Copy Chrome and Virt-Manager to both Root and New Users
RUN cp /usr/share/applications/google-chrome.desktop /root/Desktop/ && \
    cp /usr/share/applications/virt-manager.desktop /root/Desktop/ && \
    cp /usr/share/applications/google-chrome.desktop /etc/skel/Desktop/ && \
    cp /usr/share/applications/virt-manager.desktop /etc/skel/Desktop/ && \
    chmod +x /root/Desktop/*.desktop /etc/skel/Desktop/*.desktop

# Create a startup script that marks desktop icons as trusted on first login
RUN echo '#!/bin/bash' > /etc/profile.d/trust-desktop-icons.sh && \
    echo 'if [ -d ~/Desktop ]; then' >> /etc/profile.d/trust-desktop-icons.sh && \
    echo '  for file in ~/Desktop/*.desktop; do' >> /etc/profile.d/trust-desktop-icons.sh && \
    echo '    gio set "$file" metadata::trusted true 2>/dev/null' >> /etc/profile.d/trust-desktop-icons.sh && \
    echo '  done' >> /etc/profile.d/trust-desktop-icons.sh && \
    echo 'fi' >> /etc/profile.d/trust-desktop-icons.sh && \
    chmod +x /etc/profile.d/trust-desktop-icons.sh

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
