#!/bin/bash 

INVENTORY_FILE="inventory"
PLAYBOOK="artifactory-install-configure.yml"

is_ansible_installed() {
    type -p ansible-playbook > /dev/null
}

log_success() {
    if [ $# -eq 0 ]; then
        cat
    else
        echo "$*"
    fi
}


log_error() {
    echo -n "[error] "
    if [ $# -eq 0 ]; then
        cat
    else
        echo "$*"
    fi
}

distribution_id() {
    RETVAL=""
    if [ -z "${RETVAL}" -a -e "/etc/system-release" ] || [ -z "${RETVAL}" -a -e "/etc/rhel-release" ]; then
        RELEASE_OUT=$(head -n1 /etc/system-release) || $(head -n1 /etc/rhelm-release)
        case "${RELEASE_OUT}" in
            Red\ Hat\ Enterprise\ Linux*)
                RETVAL="rhel"
                ;;
            CentOS*)
                RETVAL="centos"
                ;;
            Fedora*)
                RETVAL="fedora"
                ;;
            Amazon\ Linux\ release*)
                RETVAL="ami"
                ;;
        esac
       echo $RETVAL
    fi
} 

distribution_id

distribution_major_version() {
    for RELEASE_FILE in /etc/system-release \
                        /etc/centos-release \
                        /etc/fedora-release \
                        /etc/redhat-release \
                        /etc/rhelm-release
    do
        if [ -e "${RELEASE_FILE}" ]; then
            RELEASE_VERSION=$(head -n1 ${RELEASE_FILE})
            break
        fi
    done
    echo ${RELEASE_VERSION} | sed -e 's|\(.\+\) release \([0-9]\+\)\([0-9.]*\).*|\2|'
}

distribution_major_version

is_ansible_installed
if [ $? -ne 0 ]; then
    SKIP_ANSIBLE_CHECK=0
    case $(distribution_id) in

    rhel|centos|ol|ami)
            DISTRIBUTION_MAJOR_VERSION=$(distribution_major_version)
                case ${DISTRIBUTION_MAJOR_VERSION} in
                    6)
                        yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
                        ;;
                    7)
                        yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                        ;;
                     2) yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                         ;;
                esac
                yum install -y ansible
    esac
# Check whether ansible was successfully installed
    if [ ${SKIP_ANSIBLE_CHECK} -ne 1 ]; then
        is_ansible_installed
        if [ $? -ne 0 ]; then
            log_error "Unable to install ansible."
        fi
    fi
fi

#Run the playbook
ansible-playbook -i "${INVENTORY_FILE}" $PLAYBOOK 2>&1 

# Save the exit code and output accordingly.
RC=$?
if [ ${RC} -ne 0 ]; then
    log_error "Oops!  An error occured while running setup."
else
    log_success "The setup process completed successfully."
fi



