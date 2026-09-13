{...}: {
  # ---------------------------------------------------------------------------
  # Memory resilience.
  #
  # See AGENTS.md "The 19-hour freeze" for the incident this exists to prevent:
  # 7.5 GiB of RAM, zero swap, ~4.8 GiB of long-lived services and a library
  # scan wedged every userspace process for 19 hours. The kernel stayed healthy
  # and the sockets stayed open, so nothing ever crashed and the OOM killer
  # never fired -- reclaim just evicted executable pages that were immediately
  # faulted back in, forever.
  # ---------------------------------------------------------------------------

  boot.kernel.sysctl = {
    # 1 = enable ALL sysrq functions. This was 16 (sync only) during the freeze,
    # so Alt+SysRq+W/M (diagnose) and +F/U/B (recover) all silently did nothing
    # and the box had to be power-cycled. Do NOT use the commonly cited "safe"
    # value 438: it omits bit 8 (debug dumps) and bit 64 (manual OOM kill),
    # which are precisely the two that would have helped.
    "kernel.sysrq" = 1;

    # Default 60. The freeze was reclaim evicting file-backed *executable* pages
    # and then immediately faulting them back in. Biasing reclaim toward pushing
    # anonymous pages out to zram instead is both cheaper and doesn't destroy
    # the code the running processes need in order to make progress.
    "vm.swappiness" = 100;
  };

  # Tier 1: compressed RAM swap, no disk I/O at all. ~3.7 GiB of device backed
  # by roughly 1.2 GiB of real RAM at zstd's usual ratio.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 5;
  };

  # Tier 2: genuine extra capacity on the NVMe, so cold pages can leave RAM
  # entirely and the OOM killer has room to act. Root is ext4, so a swapfile
  # needs no special handling (no NOCOW/ZFS complications) and NixOS creates it
  # at activation. Priority is below zram's, so zram is preferred.
  swapDevices = [
    {
      device = "/var/swapfile";
      size = 8192; # MiB
      priority = 1;
    }
  ];

  # systemd-oomd is enabled on this host but inert -- ManagedOOMMemoryPressure
  # and ManagedOOMSwap are both "auto" with a limit of 0, meaning "not managed
  # unless a slice opts in", and its swap-based policy is a no-op without swap.
  # It watched nothing while the box died. earlyoom is the better guard here: it
  # triggers on free-memory thresholds before the thrash equilibrium sets in,
  # and --avoid lets us explicitly protect remote access.
  services.earlyoom = {
    enable = true;
    # Both memory AND swap must be below their threshold before earlyoom acts.
    freeMemThreshold = 10;
    freeSwapThreshold = 10;
    reportInterval = 0; # log on action only, not hourly
    extraArgs = [
      # These regexes match /proc/<pid>/comm, which the kernel truncates to 15
      # characters -- hence "systemd-journal", not "systemd-journald". Every
      # name here was read off the running host rather than guessed.
      #
      # sshd-session is the critical entry: OpenSSH 9.8+ forks one per
      # connection, so that is the process whose death would cost us access.
      "--avoid"
      "^(sshd|sshd-session|systemd|systemd-journal|systemd-logind|dbus-broker|dbus-broker-lau|tailscaled|postgres|mariadbd)$"
      # Bias the victim toward the scanners that caused the outage rather than
      # a database. Note earlyoom's default victim selection is by oom_score,
      # not largest RSS, so this preference does real work.
      "--prefer"
      "^(jellyfin|ErsatzTV|ErsatzTV\\.Scanne|ollama)$"
    ];
  };

  # The journal simply stopped when the box wedged, so we had no record of what
  # memory was doing in the hours beforehand -- the single biggest gap in
  # diagnosing it. sar snapshots memory, swap, load and I/O every 10 minutes
  # into /var/log/sa/, which survives a hard power cut.
  services.sysstat.enable = true;
}
