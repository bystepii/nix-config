#!/usr/bin/env bash

search_cmd=(grep -E)
if command -v rg >/dev/null 2>&1; then
	search_cmd=(rg)
fi

os=$(uname -s)
if [ "$os" == "Darwin" ]; then
	sops_running=$(launchctl list | "${search_cmd[@]}" sops)
	if [[ -z $sops_running ]]; then
		echo "ERROR: sops-nix is not running"
		exit 1
	fi
else # If the sops-nix service wasn't started at all, we don't need to check if it failed
	sops_running=$(journalctl --no-pager --no-hostname --since "10 minutes ago" | "${search_cmd[@]}" "Starting sops-nix activation")
	if [ -z "$sops_running" ]; then
		exit 0
	fi

	# Also this is HM specific atm, need a way to test the NixOS version too
	sops_result=$(journalctl --no-pager --no-hostname --since "10 minutes ago" |
		tac |
		awk '!flag; /Starting sops-nix activation/{flag = 1};' |
		tac |
		"${search_cmd[@]}" sops)

	# If we don't have "Finished sops-nix activation." in the logs, then we failed
	if [[ ! $sops_result =~ "Finished sops-nix activation" ]]; then
		echo "ERROR: sops-nix failed to activate"
		echo "ERROR: $sops_result"
		exit 1
	fi
fi

exit 0
