#!/usr/bin/env perl

# (C) Viktor Söderqvist 2016
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

use strict;

# How to tell large images from their thumbnails
my $MIN_W = 600;
my $MIN_H = 600;

my $ALBUM_TITLE = "Fotoalbum";
my @MONTH_NAMES = qw(Januari Februari Mars April Maj Juni Juli
                     Augusti September Oktober November December);
my $NEXT_STR = "Nästa";
my $PREV_STR = "Föregående";
my $ALL_STR  = $ALBUM_TITLE; # "Alla"
my $FULLSCREEN = "Fullskärm";

my $data = get_file_data();

write_monthly_and_single_pages($data);
write_index_file($data);

# Returns a structure on the form
# {
#    "2016-02" => [
#       {
#          "small" => "200x300.file1.jpg",
#          "large" => "1024x800.file1.jpg",
#          "month" => "2016-02",
#          "orig" => "file1.jpg"
#       }
#    ]
# }
sub get_file_data {

	# By orig name
	# "file.jpg" => {"small" => "x.jpg", "large" => "y.jpg",
	#                "month" => "2016-02", "orig" => "file.jpg"}
	my $info_per_file = {};

	my $files_per_month = {}; # "yyyy-mm" => [info-per-file, ...]

	for (`ls -tn --time-style=+\%Y-\%m`) {
		next if !/\.jpe?g$/i;
		chomp $_;
		# permissions owner group size YYYY-MM name
		# ^\S*\s+\d+\s+\d+\s+\d+\s+
		next if !/(\d+-\d+)\s+((\d+)x(\d+)\.(.*))$/;
		my ($month, $name, $width, $height, $basename) = ($1, $2, $3, $4, $5);
		if ($width >= $MIN_W or $height >= $MIN_H) {
			# it's a large image
			my $ts_stuff = `exiv2 $name | grep '^Image tim'`;
			if ($ts_stuff =~ /^Image timestamp\s*:\s*(\d+):(\d+):/) {
				$month = "$1-$2";
			}
			$info_per_file->{$basename}{"large"} = $name;
			$info_per_file->{$basename}{"month"} = $month;
			$info_per_file->{$basename}{"orig"} = $basename;
			push @{$files_per_month->{$month}}, $info_per_file->{$basename}
		} else {
			# it's a thumbnail
			$info_per_file->{$basename}{"small"} = $name;
		}
	}
	return $files_per_month;
}

# Generate page for each large picture for a list of infos
sub write_single_pic_pages {
	my ($fileinfos, $prev_month_info, $next_month_info) = @_;
	for (my $i = 0; $i < @$fileinfos; $i++) {
		my $info = $fileinfos->[$i];
		my %info_deref = %$info;
		my ($img, $orig, $month) = @info_deref{"large", "orig", "month"};
		open(my $f, ">", "$orig.html~") or die "Can't create file $orig.html~: $!";
		fheader($f, $orig);

		my $prev_info = $i > 0            ? $fileinfos->[$i - 1]
		                                  : $prev_month_info;
		my $next_info = $i < $#$fileinfos ? $fileinfos->[$i + 1]
		                                  : $next_month_info;
		my $img_link = $next_info ? $next_info->{"orig"} . ".html"
		                          : "$month.html";

		# The image itself
		print $f "<main><a href=\"$img_link\"><img src=\"$img\"></a></main>\n";

		# Navigation
		print $f "<nav><ol>\n";
		if ($prev_info) {
			# Link to prev img
			my $orig = $prev_info->{"orig"};
			my $large = $prev_info->{"large"};
			print $f "<li><a href='$orig.html'>" .
			         "<img alt='preload' src='$large' width='15' height='15'>" .
			         " $PREV_STR</a></li>\n";
		}

		if ($next_info) {
			# Link to next img
			my $orig = $next_info->{"orig"};
			my $large = $next_info->{"large"};
			print $f "<li><a href='$orig.html'>" .
			         "<img alt='preload' src='$large' width='15' height='15'>" .
			         " $NEXT_STR</a></li>\n";
		}

		# Link to month overview and index
		print $f "<li><a href=\"$month.html\">&uarr; $month</a></li>\n";
		print $f "<li><a href=\"index.html\">&uarr;&uarr; $ALL_STR</a></li>\n";

		fullsceen_link($f);

		print $f "</ol></nav>\n";

		print $f "</body></html>\n";
		close $f;
		rename "$orig.html~", "$orig.html";
	}
}

# Generate month pages with thumbnails and single pic pages
sub write_monthly_and_single_pages {
	my ($filedata) = @_;
	my @months = keys %$filedata;
	for (my $i = 0; $i < @months; $i++) {
		my $prev = $i > 0        ? $months[$i - 1] : undef;
		my $next = $i < $#months ? $months[$i + 1] : undef;
		my $current = $months[$i];
		write_month_page($current, $filedata->{$current}, $prev, $next);

		my $prev_info;
		if ($prev) {
			my $prev_infos = $filedata->{$prev};
			$prev_info = $prev_infos->[$#$prev_infos];
		} else {
			$prev_info = undef;
		}
		my $next_info = $next ? $filedata->{$prev}[0] : undef;
		write_single_pic_pages($filedata->{$current}, $prev_info, $next_info);
	}
}

# Generate month pages with thumbnails
sub write_month_page {
	my ($yyyymm, $infos, $prev_month, $next_month) = @_;
	my $title = $yyyymm;
	open(my $f, ">", "$yyyymm.html~") or die "Can't create file $yyyymm.html~: $!";
	fheader($f, $title);

	# Navigation
	print $f "<nav><ol>\n";
	if ($prev_month) {
		# Link to prev month
		print $f "<li><a href=\"$prev_month.html\">&larr; $prev_month</a></li>\n";
	}

	if ($next_month) {
		# Link to next month
		print $f "<li><a href=\"$next_month.html\">&rarr; $next_month</a></li>\n";
	}

	# Link to index
	print $f "<li><a href=\"index.html\">&uarr; $ALL_STR</a></li>\n";

	print $f "</ol></nav>\n";

	# Main heading
	print $f "<main>";
	print $f "<h1>$yyyymm</h1>\n";

	print $f "<ul>\n";
	for my $info (@$infos) {
		my $small = $info->{"small"};
		my $orig = $info->{"orig"};
		my $li = "<li><a href=\"$orig.html\"><img src=\"$small\"></a></li>";
		print $f $li;
	}
	print $f "</ul>\n";
	print $f "</main></body></html>\n";
	close $f;
	rename "$yyyymm.html~", "$yyyymm.html";
}

# Generate index.html
sub write_index_file {
	my ($filedata) = @_;
	my @months = sort {$b cmp $a} keys %$filedata;

	open(my $f, ">", "index.html~") or die("Can open index.html~: $!\n");
	fheader($f, $ALBUM_TITLE);
	print $f "<h1>$ALBUM_TITLE</h1>\n";
	my $last_year = 0;
	for (@months) {
		my $thismonth = $filedata->{$_};
		my $n = @$thismonth;
		next if $n == 0;
		/^(\d+)-(\d+)$/ or die("Failed to identify year and month for $n files.\n");
		my $year = $1;
		my $month = $2;
		if ($year != $last_year) {
			print $f "</ul>" unless $last_year == 0;
			print $f "<h2>$year</h2>\n<ul>\n";
		}
		my $month_name = $MONTH_NAMES[$month - 1];
		print $f "<li><a href=\"$year-$month.html\">$month_name</a> ($n)</li>\n";
		$last_year = $year;
	}
	print $f "</ul>\n";
	print $f "</body>\n</html>\n";
	close $f;
	rename "index.html~", "index.html";
}

sub fheader {
	my ($f, $title) = @_;
	print $f <<END;
<!DOCTYPE html>
<html>
 <head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>$title</title>
  <style type="text/css">
   body { background-color: black; color: #666 }
   a:link, a:visited { color: #66f; text-decoration: none }
   a:hover { text-decoration: underline }
   main { text-align: center }
   nav ol, main ul { list-style-type: none; margin:0; padding: 0; }
   nav ol li { display: inline-block; margin:1em; padding: 0; }
   main ul li { display: inline-block; margin:0.5ex; padding: 0; }
   img { border: none }
  </style>
 </head>
 <body>
END
}

sub fullsceen_link {
	my ($f) = @_;
	# Fullsceen stops when a link is clicked. We need to load next pic using JS.
	# http://stackoverflow.com/questions/824349/modify-the-url-without-reloading-the-page
	print $f <<END;
<script type="text/javascript">
var el = document.documentElement,
    rfs =  el.requestFullScreen || el.webkitRequestFullScreen
        || el.mozRequestFullScreen || el.msRequestFullscreen;
if (typeof rfs != "undefined" && rfs) {
  document.writeln(
    "<li><a href='javascript:void(0)' onclick='rfs.call(el);return false;'>$FULLSCREEN</a></li>"
  );
}
</script>
END
}
