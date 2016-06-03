# (C) Viktor Söderqvist 2016
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#---------------------------------------------------------------------

# User variables
# --------------

ORIG_DIR=..
LARGE_SIZE=1280x800
SMALL_SIZE=300x300

REMOTE_HOST=localhost
REMOTE_USER=viktor
REMOTE_DIR=/home/viktor/foo

#---------------------------------------------------------------------

# How it works:
#
# 1. Rescale pictures
# 2. Upload to server (rsync)
# 3. Generate HTML file on server (ssh)

#---------------------------------------------------------------------

.PHONY: all scale upload

ORIG_PICS:=$(shell ls -t $(ORIG_DIR) | grep -i '\.jpg')
LARGE_PICS:=$(foreach p,$(ORIG_PICS),$(LARGE_SIZE).$(p))
SMALL_PICS:=$(foreach p,$(ORIG_PICS),$(SMALL_SIZE).$(p))
SCALED_PICS:=$(foreach p,$(ORIG_PICS),$(LARGE_SIZE).$(p) $(SMALL_PICS).$(p))

all: scale
	@$(MAKE) --no-print-directory upload

scale: $(SCALED_PICS)

upload: RSYNC_EXCLUDE=--exclude='.*' --exclude=Makefile --exclude=README.md --exclude='*.html'
upload:
	@echo Uploading...
	@rsync -tvr $(RSYNC_EXCLUDE) ./ '$(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)'
	@echo Generating album on server...
	@ssh $(REMOTE_USER)@$(REMOTE_HOST) "cd '$(REMOTE_DIR)'; perl album.pl"

$(LARGE_SIZE).%: $(ORIG_DIR)/%
	@convert $< -resize $(LARGE_SIZE) $@
	@touch --reference=$< $@

$(SMALL_SIZE).%: $(ORIG_DIR)/%
	@convert $< -resize $(SMALL_SIZE) $@
	@touch --reference=$< $@

