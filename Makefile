#
#
# How-To:
#  1) create googlePhotos remote + backup remotes in rclone
#  2) create symlinks in `./symlinks/` directory to additional folders which you want to backup
#  3) `make download-gphotos` to update local google-photos
#  4) `make dedup-gphotos | sh` to deduplicate photos (with hardlinks), optional: need only to save your local diskspace
#  4) `make backup-all` to upload backup

# "type = google photos" remote name from rclone's config
GPHOTOS_REMOTE=googlePhotos

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
$(BACKUP_REMOTES): gphotos-unique-files.txt
	echo "Syncing $@..."
	$(SYNC_CMD) --files-from $< $(CURDIR)/google-photos/ $@:google-photos
	$(SYNC_CMD) --copy-links ./symlinks/ $@:symlinks



# download media from google-photos to local directory
download-gphotos:
	touch --no-create ./google-photos # change dir mtime
	$(SYNC_CMD) $(GPHOTOS_REMOTE):album ./google-photos/albums
	$(SYNC_CMD) $(GPHOTOS_REMOTE):media/by-month ./google-photos/by-month

# md5sum for each google-photos item
gphotos-md5sum.txt: google-photos
	find $< -type f -print0 | xargs -0 -n4 -P8 md5sum | sort > $@

# list of google-photo's files for backup:
# always upload file if it's in album + files which not in any albums
gphotos-unique-files.txt: gphotos-md5sum.txt
	# sort "albums" < "by-month", so we print "by-month" path only if there are 0 album's files with same hash
	perl -lne 'my ($$hash, $$path, $$type) = /^(.*?)\s+google-photos\/((.*?)\/.*)$$/; print $$path if ($$prev_hash ne $$hash || $$type eq "albums"); $$prev_hash=$$hash;' $< > $@

# dedup google-photos by hash with hardlinks
dedup-gphotos: gphotos-md5sum.txt
	perl -lne 'my ($$hash, $$path) = /^(.*?)\s+(.*)$$/; print "ln -f \"$$path\" \"$$prev_path\"" if ($$prev_hash eq $$hash); ($$prev_hash, $$prev_path)=($$hash, $$path);' $<

.PHONY: download-gphotos upload-gphotos backup-all $(BACKUP_REMOTES)
