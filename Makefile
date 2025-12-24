#
#
# How-To:
#  1) create backup remotes in rclone
#  2) create symlinks in `./symlinks/` directory to folders which you want to backup
#  3) `make backup-all` to upload backup

# backup uploads remotes names in rclone's config
BACKUP_REMOTES=mailruEncrypted backblazeEncrypted

# sync command
SYNC_CMD=rclone sync --progress
SYNC_CMD+=--modify-window 2s # mailru has 1s resolution
# SYNC_CMD+=--dry-run
# SYNC_CMD+=--interactive

# default target: backup everything to all BACKUP_REMOTES
backup-all: $(BACKUP_REMOTES)

# backup everything to one remote (remote's name = target name)
$(BACKUP_REMOTES):
	echo "Syncing $@..."
	$(SYNC_CMD) --copy-links ./symlinks/ $@:symlinks

.PHONY: backup-all $(BACKUP_REMOTES)

-include Makefile.local
