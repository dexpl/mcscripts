#!/usr/bin/perl -l

use strict;
use warnings;

my @rslt;

foreach (@ARGV) {
my @hms = split /:/;
map { s/,// } @hms;
my $seconds = ($#hms eq 2) ? $hms[0] * 60 * 60 + $hms[1] * 60 + $hms[2] : $hms[0] * 60 + $hms[1];
push @rslt, $seconds }

$" = ', ';
print "@rslt";