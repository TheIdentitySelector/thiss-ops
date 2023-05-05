# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then

  if [ "x$SUNET_DEFAULT_PROMPT" = "x" ]; then
    # this variable is used in standard Ubuntu .bashrc
    force_color_prompt='yes'
    old_PS1=$PS1
  fi

  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi

  # put timestamps in the history
  HISTTIMEFORMAT='%F %T '

  if [ "x$SUNET_DEFAULT_PROMPT" = "x" ]; then
    # check if PS1 was changed, and if it was (meaning terminal is capable etc.)
    # update it again.
    if [ "x$old_PS1" != "x$PS1" ]; then
      #default in .bashrc: PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
      black='\[\033[00m\]'
      cyan='\[\033[00;36m\]'
      turqoise='\[\033[01;36m\]'
      orange='\[\033[00;38;5;208m\]'
      hostcolor=$orange
      dircolor=$cyan
      # Functions augmenting the prompt with useful information
      _git=''
      test -f /usr/lib/git-core/git-sh-prompt && _git='$(__git_ps1 " '$turqoise'(%s)'$black'")'
      _NOCOSMOS='$(test -f /etc/no-automatic-cosmos && echo "!COSMOS ")'
      _NOHAPROXY='$(test -d /var/haproxy-status && find /var/haproxy-status -type f -prune -empty | grep -q /var && echo "!HAPROXY ")'
      PS1=': \A ${debian_chroot:+($debian_chroot)}'${black}${_NOCOSMOS}${_NOHAPROXY}'\u''@'${hostcolor}'\h'${black}':'${_git}' '${dircolor}'\w'${black}' \$ '
      unset black cyan turqoise orange hostcolor dircolor _git _NOCOSMOS
    fi
    unset force_color_prompt old_PS1 SUNET_DEFAULT_PROMPT
  fi
fi

mesg n || true
