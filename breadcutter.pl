#!/usr/bin/perl -l

use strict;
use warnings;

my @timestamps;
my %jobdescs;
my $seconds_in_a_year = 60 * 60 * 24 * 365;
my $vftemplate        = "select='%s', setpts=N/FRAME_RATE/TB";
my $aftemplate        = "aselect='%s', asetpts=N/SR/TB";

sub ts2seconds {
    map {
        my @hms = split /:/;
            $#hms > 2  ? warn "Strange timestamp: @hms"
          : $#hms eq 2 ? $hms[0] * 60 * 60 + $hms[1] * 60 + $hms[2]
          : $#hms eq 1 ? $hms[0] * 60 + $hms[1]
          :              $hms[0];
    } @_;
}

foreach my $jobdesc (@ARGV) {
    open my $fh, '<', $jobdesc or die "Cannot read $jobdesc: $!";
    my $mediafile;
    while (<$fh>) {
        chomp;
        if ( $. == 1 ) {
            unless (-r) {
                warn "Cannot open $_, skipping $jobdesc";
                last;
            }
            $mediafile = $_;
        } else {
            next if /^\s*(?:#|$)/;
            s/[^\d: \n]//g;
            s/^\s+//;
            my @seconds = ts2seconds split /\s+/;
            if ( exists $jobdescs{$mediafile} ) {
                push @{ $jobdescs{$mediafile} }, @seconds;
            } else {
                $jobdescs{$mediafile} = [@seconds];
            }
        }
    }
    close($fh);
    foreach my $mfile ( keys %jobdescs ) {
        my @cmdline;
        for ( my $cnt = 0 ; $cnt < $#{ $jobdescs{$mfile} } ; $cnt += 2 ) {
            push @cmdline, sprintf 'not(between(t\, %d\, %d))',
              $jobdescs{$mfile}[$cnt],
              $jobdescs{$mfile}[ $cnt + 1 ] // $seconds_in_a_year;
        }
        my $filter  = join '+', @cmdline;
        my $vf      = sprintf $vftemplate, $filter;
        my $af      = sprintf $aftemplate, $filter;
        my @mfile   = split /\./, $mfile;
        my $newname = pop @mfile;
        $newname = join ".", ( @mfile, "out", $newname );
        qx(ffmpeg -i $mfile -vf "$vf" -af "$af" $newname);
    }
}

=pod
Read a file consisting of a path to mediafile to be processed and timestamps of intervals to cut off.
For example,

movie.mpg
0 10:55
1:0:0 1:0:10
1:30:0

means "cut off movie.mpg from the beginning up to 10:55, then from 1:0:0 to 1:0:10, then from 1:30:0 to the end"
