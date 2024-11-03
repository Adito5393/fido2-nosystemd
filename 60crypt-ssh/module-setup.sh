#!/bin/bash
# Original source: https://github.com/dracut-crypt-ssh/dracut-crypt-ssh
# vim: softtabstop=2 shiftwidth=2 expandtab

# called by dracut
check() {
  #check for dropbear
  require_binaries dropbear || return 1
  # Return 255 to only include the module, if another module requires it.
  return 255
}

depends() {
  echo network-legacy
  return 0
}

install() {
  #some initialization
  [[ -z "${dropbear_port}" ]] && dropbear_port=222
  [[ -z "${dropbear_acl}" ]] && dropbear_acl=/root/.ssh/authorized_keys
  local tmpDir=$(mktemp -d --tmpdir dracut-crypt-ssh.XXXX)
  local genConf="${tmpDir}/crypt-ssh.conf"
  local installConf="/etc/crypt-ssh.conf"

  # Make sure dropbear_keytypes has a value and everything is lowercase
  if [[ -z "${dropbear_keytypes}" ]]; then
    dropbear_keytypes="rsa ecdsa ed25519"
  else
    dropbear_keytypes="$(echo "${dropbear_keytypes}" | tr '[:upper:]' '[:lower:]')"
  fi

  #start writing the conf for initramfs include
  echo -e "#!/bin/bash\n\n" > $genConf
  echo "keyTypes='${dropbear_keytypes}'" >> $genConf
  echo "dropbear_port='${dropbear_port}'" >> $genConf

  #go over different encryption key types
  for keyType in $dropbear_keytypes; do
    keyType=$(echo "$keyType" | tr '[:upper:]' '[:lower:]')
    eval state=\$dropbear_${keyType}_key
    local msgKeyType=$(echo "$keyType" | tr '[:lower:]' '[:upper:]')

    [[ -z "$state" ]] && state=GENERATE

    local osshKey="${tmpDir}/${keyType}.ossh"
    local dropbearKey="${tmpDir}/${keyType}.dropbear"
    local installKey="/etc/dropbear/dropbear_${keyType}_host_key"
    
    case ${state} in
      GENERATE )
        ssh-keygen -t $keyType -f $osshKey -q -N "" -m PEM || {
          derror "SSH ${msgKeyType} key creation failed"
          rm -rf "$tmpDir"
          return 1
        }
        
        ;;
      SYSTEM )
        local sysKey=/etc/ssh/ssh_host_${keyType}_key
        [[ -f ${sysKey} ]] || {
          derror "Cannot locate a system SSH ${msgKeyType} host key in ${sysKey}"
          derror "Start OpenSSH for the first time or use ssh-keygen to generate one"
          return 1
        }

        cp $sysKey $osshKey
        cp ${sysKey}.pub ${osshKey}.pub
        
        ;;
      * )
        [[ -f ${state} ]] || {
          derror "Cannot locate a system SSH ${msgKeyType} host key in ${state}"
          derror "Please use ssh-keygen to generate this key"
          return 1
        }
        
        cp $state $osshKey
        cp ${state}.pub ${osshKey}.pub
        ;;
    esac
    
    #convert the keys from openssh to dropbear format
    dropbearconvert openssh dropbear $osshKey $dropbearKey > /dev/null 2>&1 || {
      derror "dropbearconvert for ${msgKeyType} key failed"
      rm -rf "$tmpDir"
      return 1
    }

    #install and show some information
    local keyFingerprint=$(ssh-keygen -l -f "${osshKey}")
    local keyBubble=$(ssh-keygen -B -f "${osshKey}")
    dinfo "Boot SSH ${msgKeyType} key parameters: "
    dinfo "  fingerprint: ${keyFingerprint}"
    dinfo "  bubblebabble: ${keyBubble}"
    inst $dropbearKey $installKey

    echo "dropbear_${keyType}_fingerprint='$keyFingerprint'" >> $genConf
    echo "dropbear_${keyType}_bubble='$keyBubble'" >> $genConf

  done

  inst_rules "$moddir/50-udev-pty.rules"

  inst $genConf $installConf

  inst_hook pre-udev 99 "$moddir/dropbear-start.sh"
  inst_hook pre-pivot 05 "$moddir/dropbear-stop.sh"

  inst "${dropbear_acl}" /root/.ssh/authorized_keys
  chown root:root /root/.ssh/authorized_keys

  #cleanup
  rm -rf $tmpDir
  
  #install the required binaries
  dracut_install pkill setterm
  inst_libdir_file "libnss_files*"

  #dropbear should always be in /sbin so the start script works
  local dropbear
  if dropbear="$(command -v dropbear 2>/dev/null)"; then
    inst "${dropbear}" /usr/sbin/dropbear
  else
    derror "Unable to locate dropbear executable"
    return 1
  fi

  ## Add dropbear welcome message
  inst "$moddir/banner.txt" /etc/banner.txt
}
