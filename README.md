Photo album generation for weak home servers
============================================

Do you have a home server which is not powerful enough to rescale your
photos, but it is capable of hosting them and serving them by HTTP.

Then this Makefile and Perl script are for you.

This is how it works:

1. It rescales photos locally using ImageMagick `convert`;
2. uploads to server, adding to existing photos, using `rsync`;
3. generates HTML photo album on the server using `ssh`.

How to use it
-------------

1. Create a directory on the server for the photo album and configure a web
   server to serve files in this directory. Set up authentication if you want.
2. Clone this repository or put the files `Makefile` and `album.pl` in an
   empty directory on you local computer.
3. Edit the variables in the top section of each of these files.
4. Run `make` whenever you have new photos.

Prerequisites on the server:

* Perl 5
* SSH server
* A web server

Prerequisites locally:

* GNU Make
* ImageMagick convert
* SSH client
* Rsync

Variables to edit in the Makefile:

* ORIG_DIR: The directory of the original photos.
* LARGE_SIZE, SMALL_SIZE: The maximum width and height of full screen photos
  and the thumbnails, respectively, on the form WIDTHxHEIGHT
* REMOTE_HOST, REMOTE_USER, REMOTE_DIR: Where to upload the photos and
  generate the album.

Variables to edit in `album.pl`:

* The title of the photo album and the strings for "previous" and "next".

Copying
-------

Copying, etc. is allowed under an all-permissive license (GNU
All-Permissive License). See the source code of Makefile and album.pl.
